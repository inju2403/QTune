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

      // 중복 제거하고 최신 항목을 뒤에 추가 (enqueue)
      verses = verses.filter((v) => v !== verseRef);
      verses.push(verseRef);

      // 최대 개수 초과 시 맨 앞(오래된 것)부터 제거 (dequeue)
      while (verses.length > MAX_HISTORY_SIZE) {
        verses.shift();
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

      // 제외할 구절 목록 생성
      const excludeList = recommendedVerses.length > 0
        ? recommendedVerses.map((v) => `- ${v}`).join("\n")
        : "";

      const prompt = `[추천 작업]
사용자: ${userLabel}
입력: "${mood}${noteSection}"

이 사용자에게 적절한 성경 구절 1곳을 추천하고 이유를 설명하세요.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[추천 규칙 - 반드시 순서대로 적용]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔹 1단계: 사용자 입력 분석
사용자 입력에 특정 성경 구절이 명확히 명시되어 있는가?

예시:
✅ "마태복음 5장 10절", "요한복음 3:16", "Matthew 5:10", "시편 23편"
✅ "마태복음 5장 10절 보고싶어", "요한복음 3:16이 궁금해"
❌ "사랑에 관한 구절", "위로받고 싶어", "힘이 필요해"

🔹 2단계: 추천 방식 결정

▶ 구절이 명시된 경우 (1단계에서 YES):
  → **사용자가 명시한 그 구절을 verseRef로 반환**
  → 아래 3단계 제외 목록은 **완전히 무시**

▶ 구절이 명시되지 않은 경우 (1단계에서 NO):
  → 사용자 감정/상황에 맞는 구절 추천
  → 3단계 제외 목록 규칙 적용

🔹 3단계: 제외 목록 (구절 명시되지 않은 경우에만 적용)
${excludeList ? `아래 구절들은 이미 추천했으므로 절대 추천하지 말 것:\n${excludeList}` : "(제외 목록 없음)"}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[출력 형식]
- verseRef: 영어 책명 + 장:절 (예: "John 3:16", "Matthew 5:10", "Psalms 23:1")
- rationale: "${userLabel}이" 로 시작하는 추천 이유 (1-2문장)

반드시 JSON Schema에 맞춰 응답하세요.`;

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

      // 추천 결과를 이력에 저장 (동기화하여 다음 요청에서 바로 반영되도록)
      await saveRecommendedVerse(callerId, result.verseRef);

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

      const prompt = `
사용자: ${userLabel}
사용자 입력: "${mood}${noteSection}"

성경 구절: ${verseRef}
영어 본문:
${englishText}

당신은 "QTune" 앱의 성경 의역 번역가입니다.
목표는 한국어 모어 화자가 읽었을 때 어색하지 않고, 경건하면서도 현대적인 문장으로 의역하는 것입니다.
또한 개역개정/기존 한글 성경 번역 문장과 겹치지 않도록 완전히 새로운 문장으로 작성해 주세요.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[출력 형식]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- korean: "{한글 구절명}\\n{의역문(1~2문장)}"
- rationale: "${userLabel}님"으로 시작하는 추천 이유 (1~2문장)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[규칙 - 매우 중요]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1) korean 형식
- 반드시: 한글 구절명 + 개행(\\n) + 의역문
- 구절명 뒤에 마침표(.)는 붙이지 말아 주세요.
- 한글 책명 변환 예시:
  John → 요한복음 / Matthew → 마태복음 / Psalms → 시편 / Philippians → 빌립보서 / 1 John → 요한일서

2) 의역의 퀄리티
- 1~2문장으로 자연스럽고 완결된 한국어로 작성해 주세요.
- 직역이 아니라 의미 중심으로 재구성해 주세요.
- 원문의 핵심 의미/뉘앙스는 누락하지 말아 주세요.
- 기존 번역(개역개정 등)과 문장 구조/표현이 70% 이상 유사하면 실패입니다.

3) 말투 규칙 (가장 중요)
- "여러분"이라는 단어는 절대 사용하지 말아 주세요.
- 2인칭은 상황에 맞게 너 / 너희만 사용해 주세요. (혼용 금지)

A. 하나님/예수님의 직접 말씀(명령/초청/약속/선언 톤)인 경우
- 출력 문장은 반드시 "경건한 반말(권위 있는 문장)"로 작성해 주세요.
  ✅ 허용: "~한다", "~하겠다", "~해라", "~줄 것이다", "~주겠다", "~일 것이다"
  ❌ 금지: "~입니다/~합니다"
  ❌ 금지: "주리라", "오라", "하사", "~노라" 같은 고어체
  ❌ 금지: "~거야", "~해줄게", "~하지?" 같은 지나친 구어체

B. 사도/저자/해설 서술(바울, 요한, 다윗 등)인 경우
- 존댓말 또는 담담한 문어체 중 자연스러운 톤으로 작성해 주세요.
  ✅ "~했습니다/~합니다" 또는 "~했다/~한다" 모두 가능합니다.
- 다만 번역투 문장, 어색한 조사/어순은 피해주세요.

C. 사람이 하나님께 드리는 고백/기도 톤(시편 등)인 경우
- 공손한 존댓말로 경건하게 작성해 주세요.
- 과한 고어체(하옵소서, 원하나이다 등)는 피하고 현대적인 공손함을 유지해 주세요.

4) 어휘 선택
- 고어체 금지: "하사, ~치, ~노라, 주리라, 오라" 등
- 현대어 권장: "지친, 무거운 짐, 쉬게 하다, 붙들다, 인도하다, 회복" 등
- 신성 호칭은 자연스럽게 사용해 주세요: "주님", "하나님", "그리스도"

5) 톤
- 따뜻하고 차분한 위로 톤으로 작성해 주세요.
- 설교체/훈계체 과장은 피해주세요.
- 과도한 감정 과잉 표현은 피해주세요.

6) 길이
- 영어 본문의 80~130% 분량으로 맞춰 주세요.

7) 100% 한국어
- 영어 단어는 포함하지 말아 주세요.

반드시 JSON Schema에 맞춰 응답해 주세요.
`;

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

      // 사용자가 직접 지정한 구절도 이력에 저장 (동기화)
      await saveRecommendedVerse(callerId, verseRef);

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
