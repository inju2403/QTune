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
// 타입 정의 (콜러블 함수 입력 형태)
// =========================================
type RecommendVerseRequest = {
  locale?: string;
  mood: string;
  note?: string;
  // installId는 더 이상 사용하지 않음 (Firebase Auth UID 사용)
};

type GenerateKoreanExplanationRequest = {
  englishText: string;
  verseRef: string;
  mood: string;
  note?: string;
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
      const { locale, mood, note } = data;

      if (!mood || typeof mood !== "string") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "mood is required"
        );
      }

      // 호출자 식별 및 하루 10회 제한 체크
      const callerId = getCallerId(request);
      await checkDailyQuota(callerId);

      logger.info("recommendVerse called", { locale, mood, note, callerId });

      const noteSection = note ? ` (${note})` : "";

      const prompt = `큐튠(QTune) 사용자가 "${mood}${noteSection}"라고 말했어.

이 사용자에게 딱 맞는 성경 구절 1곳을 추천하고, 왜 이 구절을 추천했는지 1-2문장으로 설명해줘.

[출력 형식 - 모든 필드 필수]
- verseRef: "책명 장:절" 형식 (예: "John 3:16", "Psalms 23:1", "Romans 8:28")
  * 영어 책명 사용 (예: John, Psalms, Romans, Matthew, Genesis 등)
- rationale: 추천 이유 (1-2문장)

[규칙]
- 너무 긴 본문은 피하고 구절 하나만 추천
- verseRef는 반드시 영어 책명으로 (예: "요한복음" ❌ "John" ✅)
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
      const { englishText, verseRef, mood, note } = data;

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
        callerId,
      });

      const noteSection = note ? ` (${note})` : "";

      const prompt = `사용자: "${mood}${noteSection}"

성경 구절: ${verseRef}
영어 본문:
${englishText}

[출력 형식]
- korean: "{한글 성경 구절명}\\n{자연스럽고 은혜로운 의역문}"
- rationale: 추천 이유 (1-2문장, 한국어)

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

3. **어휘 (자연스러운 현대어)**:
   - 고어체 금지: "~하사", "~하심이라", "멸망치 않고" 등
   - 자연스러운 표현: "~하셔서", "~하시려는 것입니다", "멸망하지 않고"
   - 종결형: "~입니다", "~하십니다" 사용

4. **감정톤**:
   - 따뜻하고 위로적인 어조
   - 설교체 금지, 시적 과장 금지
   - 묵상에 적합한 명료한 문체

5. **길이**: 영문 본문의 80~130% 범위

6. **절대 금지**:
   - 개역개정 문장 구조 모방
   - "오늘 당신은...", "~위로하십니다" 등 설교체
   - 영어 단어 삽입

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
