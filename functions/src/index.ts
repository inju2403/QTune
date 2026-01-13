/**
 * QTune Firebase Functions - OpenAI Proxy (v2 + Secret Manager)
 *
 * iOS 앱은 Firebase Functions를 통해서만 OpenAI를 호출한다.
 * OPENAI_API_KEY는 Firebase Secret Manager에서 안전하게 관리한다.
 *
 * 배포 전 필수 작업:
 * firebase functions:secrets:set OPENAI_API_KEY
 */

import * as functions from "firebase-functions";
import { onCall } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

// Firebase Admin 초기화
admin.initializeApp();

// Secret Manager에서 OpenAI API 키 정의
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

// 하루 최대 호출 횟수
const DAILY_LIMIT = 10;

// 추천 이력 최대 보관 개수 (최근 N개, 전부 프롬프트에 포함)
const MAX_HISTORY_SIZE = 100;

// =========================================
// OpenAI 클라이언트 생성 헬퍼 (Secret Manager 키 사용)
// =========================================
async function getOpenAIClient(apiKey: string) {
  if (!apiKey) {
    logger.error("OPENAI_API_KEY is not set");
    throw new functions.https.HttpsError(
      "internal",
      "OPENAI_API_KEY is not set"
    );
  }

  // ESM 전용 패키지는 dynamic import로 불러오기
  const { default: OpenAI } = await import("openai");
  return new OpenAI({ apiKey });
}

// =========================================
// 호출자 식별 (Firebase Auth UID 필수)
// =========================================
function getCallerId(request: any): string {
  // Firebase Auth UID 사용 (Anonymous Auth 포함)
  // iOS 앱은 반드시 signInAnonymously()를 먼저 호출해야 함
  if (request.auth?.uid) {
    return request.auth.uid;
  }

  // Auth가 없으면 에러
  throw new functions.https.HttpsError(
    "unauthenticated",
    "Firebase Authentication required. Please sign in anonymously first."
  );
}

// =========================================
// 하루 10회 제한 체크 (Firestore 기반)
// =========================================
async function checkDailyQuota(callerId: string): Promise<void> {
  const db = admin.firestore();

  // 오늘 날짜 (한국시간 기준, YYYY-MM-DD)
  // UTC+9 (KST) 기준으로 날짜를 계산하여 한국시간 00:00에 초기화
  const now = new Date();
  const kstOffset = 9 * 60 * 60 * 1000; // 9시간을 밀리초로
  const kstDate = new Date(now.getTime() + kstOffset);
  const today = kstDate.toISOString().split("T")[0];
  const docId = `${callerId}_${today}`;
  const docRef = db.collection("usage").doc(docId);

  await db.runTransaction(async (transaction) => {
    const doc = await transaction.get(docRef);

    if (!doc.exists) {
      // 첫 호출
      transaction.set(docRef, {
        count: 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      logger.info(`[checkDailyQuota] First call today: ${callerId}`);
      return;
    }

    const currentCount = doc.data()?.count ?? 0;

    if (currentCount >= DAILY_LIMIT) {
      // 하루 10회 초과
      logger.warn(
        `[checkDailyQuota] Daily limit exceeded: ${callerId} (${currentCount}/${DAILY_LIMIT})`
      );
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "일일 사용 가능한 횟수를 모두 사용했습니다."
      );
    }

    // 카운트 증가
    transaction.update(docRef, {
      count: currentCount + 1,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    logger.info(
      `[checkDailyQuota] Count updated: ${callerId} (${currentCount + 1}/${DAILY_LIMIT})`
    );
  });
}

// =========================================
// 추천 이력 조회 (Firestore 기반)
// =========================================
async function getRecommendedVerses(callerId: string): Promise<string[]> {
  const db = admin.firestore();
  const docRef = db.collection("verse_history").doc(callerId);

  try {
    const doc = await docRef.get();
    if (!doc.exists) {
      return [];
    }

    const data = doc.data();
    return (data?.verses ?? []) as string[];
  } catch (error) {
    logger.error("[getRecommendedVerses] Error fetching history", {
      callerId,
      error,
    });
    return [];
  }
}

// =========================================
// 추천 이력 저장 (Firestore 기반)
// =========================================
async function saveRecommendedVerse(
  callerId: string,
  verseRef: string
): Promise<void> {
  const db = admin.firestore();
  const docRef = db.collection("verse_history").doc(callerId);

  try {
    await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(docRef);

      let verses: string[] = [];
      if (doc.exists) {
        verses = (doc.data()?.verses ?? []) as string[];
      }

      // 중복 제거하고 최신 항목을 앞에 추가
      verses = verses.filter((v) => v !== verseRef);
      verses.unshift(verseRef);

      // 최대 개수 제한
      if (verses.length > MAX_HISTORY_SIZE) {
        verses = verses.slice(0, MAX_HISTORY_SIZE);
      }

      transaction.set(
        docRef,
        {
          verses,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      logger.info("[saveRecommendedVerse] History updated", {
        callerId,
        verseRef,
        totalCount: verses.length,
      });
    });
  } catch (error) {
    logger.error("[saveRecommendedVerse] Error saving history", {
      callerId,
      verseRef,
      error,
    });
    // 이력 저장 실패는 치명적이지 않으므로 에러를 throw하지 않음
  }
}

// =========================================
// 타입 정의 (콜러블 함수 입력 형태)
// =========================================
type RecommendVerseRequest = {
  locale?: string;
  mood: string;
  note?: string;
  nickname?: string;
  gender?: string;
  // installId는 더 이상 사용하지 않음 (Firebase Auth UID 사용)
};

type GenerateKoreanExplanationRequest = {
  englishText: string;
  verseRef: string;
  mood: string;
  note?: string;
  nickname?: string;
  gender?: string;
  // installId는 더 이상 사용하지 않음 (Firebase Auth UID 사용)
};

// =========================================
// 말씀 추천 함수 (recommendVerse)
// =========================================
export const recommendVerse = onCall(
  { secrets: [OPENAI_API_KEY] },
  async (request) => {
    try {
      const data = request.data as RecommendVerseRequest;
      const { locale, mood, note, nickname, gender } = data;

      if (!mood || typeof mood !== "string") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "mood is required"
        );
      }

      // 호출자 식별 및 하루 10회 제한 체크
      const callerId = getCallerId(request);
      await checkDailyQuota(callerId);

      // 이미 추천한 구절 목록 조회
      const recommendedVerses = await getRecommendedVerses(callerId);

      logger.info("recommendVerse called", {
        locale,
        mood,
        note,
        nickname,
        gender,
        callerId,
        historyCount: recommendedVerses.length,
      });

      const noteSection = note ? ` (${note})` : "";

      // 프로필 정보로 userLabel 생성
      const userLabel = (nickname && gender)
        ? `${nickname} ${gender}님`
        : `${gender || "형제"}님`;

      // 제외할 구절 목록 섹션 생성
      let excludeSection = "";
      if (recommendedVerses.length > 0) {
        const verseList = recommendedVerses
          .map((v) => `- ${v}`)
          .join("\n");
        excludeSection = `\n[이미 추천한 구절들 - 절대 추천하지 말 것]\n${verseList}\n`;
      }

      const prompt = `${userLabel}이 "${mood}${noteSection}"라고 말했어.

${userLabel}에게 딱 맞는 성경 구절 1곳을 추천하고, 왜 이 구절을 추천했는지 1-2문장으로 설명해줘.
${excludeSection}
[출력 형식 - 모든 필드 필수]
- verseRef: "책명 장:절" 형식 (예: "John 3:16", "Psalms 23:1", "Romans 8:28")
  * 영어 책명 사용 (예: John, Psalms, Romans, Matthew, Genesis 등)
- rationale: 추천 이유 (1-2문장)
  * "${userLabel}이" 형식으로 시작 (예: "${userLabel}이 힘든 하루를 보내셔서...")

[규칙]
- 너무 긴 본문은 피하고 구절 하나만 추천
- verseRef는 반드시 영어 책명으로 (예: "요한복음" ❌ "John" ✅)
- 위에 나열된 "이미 추천한 구절들"은 절대 추천하지 말 것 (다른 구절을 찾아줘)
- rationale은 반드시 "${userLabel}이"로 시작
- 반드시 JSON Schema에 맞춰 모든 필드를 포함하여 응답

반드시 JSON Schema에 맞춰 응답해줘.`;

      const responseFormat = {
        type: "json_schema" as const,
        json_schema: {
          name: "VerseRecommendation",
          strict: true,
          schema: {
            type: "object",
            properties: {
              verseRef: {
                type: "string",
                description: "성경 구절 참조 (예: John 3:16, Psalms 23:1)",
              },
              rationale: {
                type: "string",
                description: "추천 이유 (1-2문장)",
              },
            },
            required: ["verseRef", "rationale"],
            additionalProperties: false,
          },
        },
      };

      const openai = await getOpenAIClient(OPENAI_API_KEY.value());

      const completion = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "user",
            content: prompt,
          },
        ],
        response_format: responseFormat,
      });

      const content = completion.choices[0]?.message?.content;
      if (!content) {
        throw new functions.https.HttpsError(
          "internal",
          "Empty response from OpenAI"
        );
      }

      const result = JSON.parse(content);
      logger.info("recommendVerse success", { verseRef: result.verseRef });

      // 추천 결과를 이력에 저장 (비동기, 실패해도 응답에 영향 없음)
      saveRecommendedVerse(callerId, result.verseRef);

      return result;
    } catch (error: any) {
      logger.error("recommendVerse error", {
        message: error?.message,
        name: error?.name,
        code: (error as any)?.code,
        status: (error as any)?.status,
        stack: error?.stack,
        raw: error,
      });

      // HttpsError는 그대로 re-throw (resource-exhausted, unauthenticated 등)
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      // 기타 에러는 internal로 wrapping
      throw new functions.https.HttpsError(
        "internal",
        error?.message ?? "Unknown error"
      );
    }
  }
);

// =========================================
// 한글 해설 생성 함수 (generateKoreanExplanation)
// =========================================
export const generateKoreanExplanation = onCall(
  { secrets: [OPENAI_API_KEY] },
  async (request) => {
    try {
      const data = request.data as GenerateKoreanExplanationRequest;
      const { englishText, verseRef, mood, note, nickname, gender } = data;

      if (!englishText || typeof englishText !== "string") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "englishText is required"
        );
      }
      if (!verseRef || typeof verseRef !== "string") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "verseRef is required"
        );
      }
      if (!mood || typeof mood !== "string") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "mood is required"
        );
      }

      // 한글 해설 생성은 recommendVerse의 후속 작업이므로 별도 카운트 안 함
      // recommendVerse에서 이미 checkDailyQuota()를 호출했음
      const callerId = getCallerId(request);

      logger.info("generateKoreanExplanation called", {
        verseRef,
        mood,
        nickname,
        gender,
        callerId,
      });

      const noteSection = note ? ` (${note})` : "";

      // 프로필 정보로 userLabel 생성
      const userLabel = (nickname && gender)
        ? `${nickname} ${gender}님`
        : `${gender || "형제"}님`;

      const prompt = `${userLabel}: "${mood}${noteSection}"

성경 구절: ${verseRef}
영어 본문:
${englishText}

[출력 형식]
- korean: "{한글 성경 구절명}\\n{자연스럽고 은혜로운 의역문}"
- rationale: 추천 이유 (1-2문장, 한국어)
  * "${userLabel}이" 형식으로 시작 (예: "${userLabel}이 힘든 하루를 보내셔서...")

[규칙 - 매우 중요]
1. **korean 형식**: 한글 구절명 + 개행(\\n) + 의역문
   - 예: "빌립보서 4:13\\n그리스도께서 저에게 힘을 주시기에, 저는 모든 것을 해낼 수 있습니다."
   - 구절명 뒤에 마침표(.) 붙이지 말 것!
   - 한글 책명: John → 요한복음, Philippians → 빌립보서, Psalms → 시편, 1 John → 요한일서

2. **문장 구조 (자연스러운 의역)**:
   - 1~2문장으로 구성
   - 자연스러운 한국어 어순으로 의역
   - 직역 금지, 의미 중심으로 재구성
   - 개역개정/개역한글과 문장 구조 70% 이상 유사하면 안 됨

3. **어휘 (자연스러운 현대어 + 경건한 느낌)**:
   - 고어체 금지: "~하사", "~하심이라", "멸망치 않고" 등
   - 자연스러운 표현: "~하셔서", "~하시려는 것입니다", "멸망하지 않고"
   - 종결형 기본: "~입니다", "~하십니다" 사용
   - **하나님/예수님의 직접 화법**: 하나님, 예수님이 직접 말씀하시는 구절은 반말 종결("~것이다", "~한다", "~이다")로 번역하여 경건함과 권위를 표현
     * 예: "내가 주는 물을 마시는 사람은 영원히 목마르지 않을 것이다" (⭕)
     * 예: "내가 주는 물을 마시는 사람은 영원히 목마르지 않을 것입니다" (❌)
   - **경건한 어조**: 하나님, 주님, 그리스도 등 존칭을 자연스럽게 사용하며 경외감이 느껴지는 표현

4. **감정톤 (AI 번역 느낌 제거)**:
   - 따뜻하고 위로적인 어조
   - 설교체 금지, 시적 과장 금지
   - 묵상에 적합한 명료한 문체
   - **기계적 번역체 금지**: 직역투, 어색한 조사 사용, 부자연스러운 문장 연결 피하기
   - **자연스러운 구어체**: 한국어 모어 화자가 성경을 읽듯이 자연스럽게

5. **길이**: 영문 본문의 80~130% 범위

6. **절대 금지**:
   - 개역개정 문장 구조 모방
   - "오늘 당신은...", "~위로하십니다" 등 설교체
   - 영어 단어 삽입
   - AI 번역기 특유의 어색한 표현

반드시 JSON Schema에 맞춰 응답.`;

      const responseFormat = {
        type: "json_schema" as const,
        json_schema: {
          name: "KoreanExplanation",
          strict: true,
          schema: {
            type: "object",
            properties: {
              korean: {
                type: "string",
                description: "한국어 해석 (영문 길이의 80~130%, 의역)",
              },
              rationale: {
                type: "string",
                description: "추천 이유 (1-2문장)",
              },
            },
            required: ["korean", "rationale"],
            additionalProperties: false,
          },
        },
      };

      const openai = await getOpenAIClient(OPENAI_API_KEY.value());

      const completion = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "user",
            content: prompt,
          },
        ],
        response_format: responseFormat,
      });

      const content = completion.choices[0]?.message?.content;
      if (!content) {
        throw new functions.https.HttpsError(
          "internal",
          "Empty response from OpenAI"
        );
      }

      const result = JSON.parse(content);
      logger.info("generateKoreanExplanation success");

      return result;
    } catch (error: any) {
      logger.error("generateKoreanExplanation error", {
        message: error?.message,
        name: error?.name,
        code: (error as any)?.code,
        status: (error as any)?.status,
        stack: error?.stack,
        raw: error,
      });

      // HttpsError는 그대로 re-throw (resource-exhausted, unauthenticated 등)
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      // 기타 에러는 internal로 wrapping
      throw new functions.https.HttpsError(
        "internal",
        error?.message ?? "Unknown error"
      );
    }
  }
);
