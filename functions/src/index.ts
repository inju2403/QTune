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
// 환경 구분 (Sandbox vs Production)
// =========================================
function isSandboxEnvironment(request: any): boolean {
  // 앱 체크 토큰이나 커스텀 클레임으로 구분
  // 또는 앱 ID로 구분 (com.inju.qtune.sandbox)
  const token = request.auth?.token;
  const appId = token?.firebase?.sign_in_provider;

  // Bundle ID나 커스텀 헤더로 구분
  // iOS에서 보낸 헤더나 토큰 정보로 판단
  return request.data?.isSandbox === true ||
         request.rawRequest?.headers?.["x-app-environment"] === "sandbox";
}

// =========================================
// 환경별 컬렉션 이름 가져오기
// =========================================
function getCollectionName(baseName: string, request: any): string {
  const prefix = isSandboxEnvironment(request) ? "dev_" : "";
  return `${prefix}${baseName}`;
}

// =========================================
// 하루 10회 제한 체크 (Firestore 기반)
// =========================================
async function checkDailyQuota(callerId: string, request: any): Promise<void> {
  const db = admin.firestore();

  // 오늘 날짜 (한국시간 기준, YYYY-MM-DD)
  // UTC+9 (KST) 기준으로 날짜를 계산하여 한국시간 00:00에 초기화
  const now = new Date();
  const kstOffset = 9 * 60 * 60 * 1000; // 9시간을 밀리초로
  const kstDate = new Date(now.getTime() + kstOffset);
  const today = kstDate.toISOString().split("T")[0];
  const docId = `${callerId}_${today}`;

  // 환경에 따라 컬렉션 이름 결정 (usage vs dev_usage)
  const collectionName = getCollectionName("usage", request);
  const docRef = db.collection(collectionName).doc(docId);

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
async function getRecommendedVerses(callerId: string, request: any): Promise<string[]> {
  const db = admin.firestore();
  const collectionName = getCollectionName("verse_history", request);
  const docRef = db.collection(collectionName).doc(callerId);

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
  verseRef: string,
  request: any
): Promise<void> {
  const db = admin.firestore();
  const collectionName = getCollectionName("verse_history", request);
  const docRef = db.collection(collectionName).doc(callerId);

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
      await checkDailyQuota(callerId, request);

      // 이미 추천한 구절 목록 조회
      const recommendedVerses = await getRecommendedVerses(callerId, request);

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
- rationale: 추천 이유 (1-2문장)
  * 사용자의 마음/상황을 파악하여 공감적으로 표현
  * 직접 인용 대신 "~한 마음을 느끼시는 것 같아" 같은 부드러운 표현
  * 이 구절이 왜 지금 필요한지 자연스럽게 연결`
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
- rationale: 추천 이유 (1-2문장)
  * 사용자의 마음/상황을 파악하여 공감적으로 표현
  * 직접 인용 대신 "~한 마음을 느끼시는 것 같아" 같은 부드러운 표현
  * 이 구절이 왜 지금 필요한지 자연스럽게 연결`;

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
      await saveRecommendedVerse(callerId, result.verseRef, request);

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

당신은 "QTune" 앱의 성경 해설가입니다.
이 말씀이 담고 있는 의미를 경건하게 해설해 주세요.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[출력 형식]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- korean: "{해설 3문장}"
- rationale: 이 말씀이 주어진 이유 (1~2문장)
  * 사용자의 마음/상황을 이해하고 공감하는 톤
  * 직접 인용보다는 마음의 상태를 파악하여 표현
  * 예: "${userLabel}께서 지금 느끼시는 마음에 이 말씀이 위로가 되기를 바랍니다."
  * 예: "승주 형제님의 일상에 이 약속의 말씀이 함께하기를 기도합니다."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[해설 작성 규칙]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1) 형식
- 정확히 3개의 문장으로만 구성된 해설
- 구절명이나 제목 없이 바로 해설 시작

2) 해설 내용 (반드시 3문장)
- 1문장: 이 구절이 말하는 핵심 메시지
- 2문장: 그 메시지의 신학적/영적 의미
- 3문장: 오늘날 우리에게 주는 교훈이나 적용

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

5) rationale 작성 규칙 (중요)
- 사용자의 마음을 이해하고 공감하는 방식으로 시작
- 사용자가 구절 입력 시: "주님만을 의지하고자 하는 마음에..."
- 사용자가 감정 입력 시: "지금의 상황에서 필요한 위로가..."
- 따뜻하고 개인적인 연결점 제시

6) 예시
korean: "하나님은 세상을 극진히 사랑하셔서 독생자를 내어주셨습니다. 이는 인류를 향한 하나님의 무조건적인 사랑과 구원 계획을 보여줍니다. 믿는 자마다 영생을 얻는다는 이 약속은 오늘 우리에게도 변함없는 소망입니다."
rationale: "${userLabel}께서 오늘 나누신 마음에 이 말씀이 위로가 되기를 바랍니다. 이 구절이 더욱 큰 소망을 주었으면 좋겠습니다."

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

      // 사용자가 직접 지정한 구절도 이력에 저장 (동기화)
      await saveRecommendedVerse(callerId, verseRef, request);

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
