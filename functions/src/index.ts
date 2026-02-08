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

      // 제외 규칙 - 강력하고 명확하게
      const excludeHeader = excludeList
        ? `
🚨🚨🚨 [최우선 제약사항 - 시스템 레벨 규칙] 🚨🚨🚨

아래 구절들은 **절대로 추천해서는 안 됩니다**:
${excludeList}

⛔ 위 목록에 있는 구절을 추천하면 시스템 오류로 처리됩니다.
⛔ 사용자 입력과 의미적으로 연관이 있어도, 위 목록에 있으면 **절대 추천 금지**.
✅ 반드시 위 목록에 **없는** 새로운 구절을 찾아서 추천하세요.

예시:
- 입력: "마라나타!" + 제외 목록에 "Revelation 22:20" 있음
  → ❌ Revelation 22:20 추천 금지 (의미 연관 있어도!)
  → ✅ Philippians 3:20, Titus 2:13 등 다른 재림 관련 구절 추천
`
        : "";

      const prompt = excludeList
        ? `${excludeHeader}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[추천 작업]
사용자: ${userLabel}
입력: "${mood}${noteSection}"

위 제약사항을 **절대적으로 준수**하면서, 이 사용자에게 성경 구절을 추천하세요.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[추천 절차]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1️⃣ **제외 목록 재확인**: 위 🚨 섹션의 금지 구절 목록을 다시 확인하세요.

2️⃣ **사용자 의도 파악**:
   - 특정 구절 명시? (예: "마태복음 5:10") → 그 구절 반환
   - 감정/주제만? (예: "마라나타!", "위로") → 적절한 구절 찾기

3️⃣ **구절 선택**:
   - 제외 목록에 **없는** 구절 중에서 선택
   - 사용자 입력과 의미적으로 가장 잘 맞는 구절

4️⃣ **최종 검증**: 선택한 verseRef가 제외 목록에 **없는지** 다시 확인!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[출력]
- verseRef: 영어 책명 + 장:절 (예: "John 3:16")
- rationale: 이 말씀이 주어진 이유 (1-2문장)
  * 사용자가 입력한 내용을 깊이 이해하고, 그 마음의 상태와 이 말씀이 어떻게 연결되는지 경건하게 설명
  * 말씀이 사용자의 현재 상황에 주는 구체적인 의미를 신학적 통찰과 함께 제시
  * 일반적인 위로나 축복이 아닌, 말씀과 사용자 입력 사이의 실제적 연결점을 발견하여 설명
  * 경건하되 진정성 있는 톤으로, 이 말씀이 지금 이 순간 주어진 이유를 명확히 전달

  좋은 예시:
    - 입력: "주님만을 의지하고 싶어" → "${userLabel}께서 세상의 것이 아닌 주님만을 의지하려는 결단 속에서, 이 말씀은 그 신뢰가 헛되지 않음을 증거합니다."
    - 입력: "일상의 소중함" → "평범한 일상 속에서도 하나님의 은혜를 발견하려는 ${userLabel}의 영적 감수성에 이 말씀이 응답합니다."
    - 입력: "힘들고 지칠 때" → "고난 중에도 하나님이 함께하신다는 이 약속은 ${userLabel}의 현재 상황에 대한 하나님의 직접적인 응답입니다."

  나쁜 예시 (절대 사용 금지):
    - "위로가 되기를 바랍니다" ❌
    - "도움이 되기를 기도합니다" ❌
    - "느끼시는 마음에" ❌
    - "힘이 되었으면 좋겠습니다" ❌
    - "느껴질 것이라 믿습니다" ❌`
        : `[추천 작업]
사용자: ${userLabel}
입력: "${mood}${noteSection}"

이 사용자에게 성경 구절 1곳을 추천하고 이유를 설명하세요.

[추천 절차]
1. 사용자가 특정 구절을 명시했는가?
   - YES: 그 구절 반환
   - NO: 사용자 감정/상황에 맞는 구절 추천

[출력]
- verseRef: 영어 책명 + 장:절 (예: "John 3:16")
- rationale: 이 말씀이 주어진 이유 (1-2문장)
  * 사용자가 입력한 내용을 깊이 이해하고, 그 마음의 상태와 이 말씀이 어떻게 연결되는지 경건하게 설명
  * 말씀이 사용자의 현재 상황에 주는 구체적인 의미를 신학적 통찰과 함께 제시
  * 일반적인 위로나 축복이 아닌, 말씀과 사용자 입력 사이의 실제적 연결점을 발견하여 설명
  * 경건하되 진정성 있는 톤으로, 이 말씀이 지금 이 순간 주어진 이유를 명확히 전달

  좋은 예시:
    - 입력: "주님만을 의지하고 싶어" → "${userLabel}께서 세상의 것이 아닌 주님만을 의지하려는 결단 속에서, 이 말씀은 그 신뢰가 헛되지 않음을 증거합니다."
    - 입력: "일상의 소중함" → "평범한 일상 속에서도 하나님의 은혜를 발견하려는 ${userLabel}의 영적 감수성에 이 말씀이 응답합니다."
    - 입력: "힘들고 지칠 때" → "고난 중에도 하나님이 함께하신다는 이 약속은 ${userLabel}의 현재 상황에 대한 하나님의 직접적인 응답입니다."

  나쁜 예시 (절대 사용 금지):
    - "위로가 되기를 바랍니다" ❌
    - "도움이 되기를 기도합니다" ❌
    - "느끼시는 마음에" ❌
    - "힘이 되었으면 좋겠습니다" ❌
    - "느껴질 것이라 믿습니다" ❌`;

      const verseRefDescription = excludeList
        ? `성경 구절 참조 (예: John 3:16). ⚠️ 중요: 제외 목록에 있는 구절은 절대 추천 금지! 새로운 구절만 반환할 것.`
        : "성경 구절 참조 (예: John 3:16, Psalms 23:1)";

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
                description: verseRefDescription,
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
        temperature: 0.5, // 적절한 온도로 자연스러운 표현과 규칙 준수 균형
        messages: [
          {
            role: "system",
            content: "당신은 성경 구절을 추천하는 목사입니다. 사용자가 입력한 내용의 영적 의미를 깊이 통찰하고, 하나님께서 이 특정한 말씀을 통해 사용자에게 전하시려는 메시지가 무엇인지 경건하게 해석하세요. '위로가 되기를', '바랍니다', '느끼시는', '믿습니다' 같은 일반적 표현을 피하고, 사용자의 현재 상황과 말씀 사이의 신학적이고 실제적인 연결점을 구체적으로 제시하세요."
          },
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

      // 제외 목록 위반 감지 (디버깅용 경고)
      if (recommendedVerses.includes(result.verseRef)) {
        logger.warn("⚠️ GPT가 제외 목록을 무시하고 이미 추천한 구절을 재추천함!", {
          verseRef: result.verseRef,
          mood,
          excludedCount: recommendedVerses.length,
        });
      }

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
성경 구절: ${verseRef}
영어 본문:
${englishText}

당신은 "QTune" 앱의 성경 해설가입니다.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[작업 1: 객관적 성경 해설 (korean)]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
위 성경 구절의 의미를 객관적으로 해설해 주세요.
사용자의 상황이나 입력과 무관하게, 이 구절이 성경에서 전달하는
본래의 메시지와 신학적 의미를 설명합니다.

1) 형식
- 정확히 3개의 문장으로만 구성된 해설
- 구절명이나 제목 없이 바로 해설 시작

2) 해설 내용 (반드시 3문장)
- 1문장: 이 구절이 말하는 핵심 메시지
- 2문장: 그 메시지의 신학적/영적 의미
- 3문장: 오늘날 우리에게 주는 보편적 교훈

3) 문장 규칙
- 쉼표 사용 최소화 (문장당 1개 이하)
- 각 문장은 마침표로 종결
- 명확하고 간결한 문체
- 경건하되 딱딱하지 않은 톤

4) 금지 사항
- 개역개정 직접 인용 금지
- 설교체나 훈계조 금지
- 지나친 감정 표현 금지
- 영어 단어 사용 금지
- 특정 개인의 상황 언급 금지

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[작업 2: 사용자 맞춤 적용 (rationale)]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
사용자: ${userLabel}
사용자 입력: "${mood}${noteSection}"

위에서 해설한 말씀이 이 사용자에게 주어진 이유를 설명해 주세요.
사용자가 입력한 "${mood}${noteSection}" 내용을 분석하여,
이 구절이 사용자의 현재 상황/마음과 어떻게 연결되는지 구체적으로 설명합니다.

rationale 작성 규칙 (1-2문장):
- 사용자가 입력한 내용의 영적 의미를 깊이 통찰하여, 이 말씀이 주어진 이유를 경건하게 설명
- 하나님께서 이 특정한 시점에 이 말씀을 통해 전하시는 메시지가 무엇인지 구체적으로 해석
- 일반적인 축복이나 위로가 아닌, 사용자의 상황과 말씀 사이의 신학적 연결점을 제시
- 경건하고 진정성 있는 톤으로, 말씀이 사용자의 현재 상황에 주는 실제적 의미를 전달

rationale 예시:
좋은 예시:
- 입력: "주님만을 의지하고 싶어" → "${userLabel}께서 세상의 것이 아닌 주님만을 의지하려는 결단 속에서, 이 말씀은 그 신뢰가 헛되지 않음을 증거합니다."
- 입력: "일상의 소중함" → "평범한 일상 속에서도 하나님의 은혜를 발견하려는 ${userLabel}의 영적 감수성에 이 말씀이 응답합니다."
- 입력: "범사에 감사하라" → "감사를 삶의 원칙으로 삼으려는 ${userLabel}의 결단에, 이 말씀은 감사가 단순한 감정이 아닌 신앙의 고백임을 일깨웁니다."

나쁜 예시 (절대 사용 금지):
- "이 말씀이 위로가 되기를 바랍니다" ❌
- "도움이 되기를 기도합니다" ❌
- "느끼시는 마음에" ❌
- "힘이 되었으면 좋겠습니다" ❌
- "느껴질 것이라 믿습니다" ❌

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[출력 형식]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- korean: 객관적인 성경 해설 3문장 (사용자 입력과 무관)
- rationale: 이 말씀이 사용자에게 주어진 이유 (1-2문장, 사용자 입력과 연관)

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
        temperature: 0.3, // 낮은 온도로 규칙 준수율 향상
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

      // generateKoreanExplanation은 recommendVerse의 후속 작업이므로
      // 이미 recommendVerse에서 저장한 구절을 중복 저장하지 않음

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
