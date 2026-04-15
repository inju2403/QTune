/**
 * QTune Firebase Functions - OpenAI Proxy (v2 + Secret Manager)
 *
 * iOS 앱은 Firebase Functions를 통해서만 OpenAI를 호출한다.
 * OPENAI_API_KEY는 Firebase Secret Manager에서 안전하게 관리한다.
 *
 * 배포 전 필수 작업:
 * firebase functions:secrets:set OPENAI_API_KEY
 */

import * as functions from "firebase-functions/v1";
import { onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

// Secret Manager에서 OpenAI API 키 정의
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

// Firebase Admin 초기화
if (!admin.apps.length) {
  admin.initializeApp();
  logger.info("Admin SDK initialized");
}

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
async function checkDailyQuota(
  callerId: string,
  nickname?: string,
  gender?: string,
  collectionName: string = "usage"
): Promise<void> {
  const db = admin.firestore();

  // 오늘 날짜 (한국시간 기준, YYYY-MM-DD)
  // UTC+9 (KST) 기준으로 날짜를 계산하여 한국시간 00:00에 초기화
  const now = new Date();
  const kstOffset = 9 * 60 * 60 * 1000; // 9시간을 밀리초로
  const kstDate = new Date(now.getTime() + kstOffset);
  const today = kstDate.toISOString().split("T")[0];
  const docId = `${callerId}_${today}`;
  const docRef = db.collection(collectionName).doc(docId);

  await db.runTransaction(async (transaction) => {
    const doc = await transaction.get(docRef);

    if (!doc.exists) {
      // 첫 호출 - nickname과 gender 포함하여 저장
      const usageData: any = {
        count: 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // 프로필 정보 추가 (있으면)
      if (nickname) {
        usageData.nickname = nickname;
      }
      if (gender) {
        usageData.gender = gender;
      }

      transaction.set(docRef, usageData);
      logger.info(`[checkDailyQuota] First call today: ${callerId} (nickname: ${nickname || "N/A"}, gender: ${gender || "N/A"})`);
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

    // 카운트 증가 및 프로필 정보 업데이트
    const updateData: any = {
      count: currentCount + 1,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // 프로필 정보 업데이트 (있으면)
    if (nickname) {
      updateData.nickname = nickname;
    }
    if (gender) {
      updateData.gender = gender;
    }

    transaction.update(docRef, updateData);
    logger.info(
      `[checkDailyQuota] Count updated: ${callerId} (${currentCount + 1}/${DAILY_LIMIT}, nickname: ${nickname || "N/A"}, gender: ${gender || "N/A"})`
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
  verseRef: string,
  nickname?: string,
  gender?: string
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

      const updateData: any = {
        verses,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // 프로필 정보 추가 (있으면)
      if (nickname) {
        updateData.nickname = nickname;
      }
      if (gender) {
        updateData.gender = gender;
      }

      transaction.set(docRef, updateData, { merge: true });

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
// 한국어 성경 책명 → 영어 매핑
// =========================================
const KOREAN_BOOK_MAP: Record<string, string> = {
  // 구약
  "창세기": "Genesis", "창": "Genesis",
  "출애굽기": "Exodus", "출": "Exodus",
  "레위기": "Leviticus", "레": "Leviticus",
  "민수기": "Numbers", "민": "Numbers",
  "신명기": "Deuteronomy", "신": "Deuteronomy",
  "여호수아": "Joshua", "수": "Joshua",
  "사사기": "Judges", "삿": "Judges",
  "룻기": "Ruth", "룻": "Ruth",
  "사무엘상": "1 Samuel", "삼상": "1 Samuel",
  "사무엘하": "2 Samuel", "삼하": "2 Samuel",
  "열왕기상": "1 Kings", "왕상": "1 Kings",
  "열왕기하": "2 Kings", "왕하": "2 Kings",
  "역대상": "1 Chronicles", "대상": "1 Chronicles",
  "역대하": "2 Chronicles", "대하": "2 Chronicles",
  "에스라": "Ezra", "스": "Ezra",
  "느헤미야": "Nehemiah", "느": "Nehemiah",
  "에스더": "Esther", "에": "Esther",
  "욥기": "Job", "욥": "Job",
  "시편": "Psalms", "시": "Psalms",
  "잠언": "Proverbs", "잠": "Proverbs",
  "전도서": "Ecclesiastes", "전": "Ecclesiastes",
  "아가": "Song of Solomon", "아": "Song of Solomon",
  "이사야": "Isaiah", "사": "Isaiah",
  "예레미야": "Jeremiah", "렘": "Jeremiah",
  "예레미야애가": "Lamentations", "애": "Lamentations",
  "에스겔": "Ezekiel", "겔": "Ezekiel",
  "다니엘": "Daniel", "단": "Daniel",
  "호세아": "Hosea", "호": "Hosea",
  "요엘": "Joel", "욜": "Joel",
  "아모스": "Amos", "암": "Amos",
  "오바댜": "Obadiah", "옵": "Obadiah",
  "요나": "Jonah", "욘": "Jonah",
  "미가": "Micah", "미": "Micah",
  "나훔": "Nahum", "나": "Nahum",
  "하박국": "Habakkuk", "합": "Habakkuk",
  "스바냐": "Zephaniah", "습": "Zephaniah",
  "학개": "Haggai", "학": "Haggai",
  "스가랴": "Zechariah", "슥": "Zechariah",
  "말라기": "Malachi", "말": "Malachi",
  // 신약
  "마태복음": "Matthew", "마": "Matthew",
  "마가복음": "Mark", "막": "Mark",
  "누가복음": "Luke", "눅": "Luke",
  "요한복음": "John", "요": "John",
  "사도행전": "Acts", "행": "Acts",
  "로마서": "Romans", "롬": "Romans",
  "고린도전서": "1 Corinthians", "고전": "1 Corinthians",
  "고린도후서": "2 Corinthians", "고후": "2 Corinthians",
  "갈라디아서": "Galatians", "갈": "Galatians",
  "에베소서": "Ephesians", "엡": "Ephesians",
  "빌립보서": "Philippians", "빌": "Philippians",
  "골로새서": "Colossians", "골": "Colossians",
  "데살로니가전서": "1 Thessalonians", "살전": "1 Thessalonians",
  "데살로니가후서": "2 Thessalonians", "살후": "2 Thessalonians",
  "디모데전서": "1 Timothy", "딤전": "1 Timothy",
  "디모데후서": "2 Timothy", "딤후": "2 Timothy",
  "디도서": "Titus", "딛": "Titus",
  "빌레몬서": "Philemon", "몬": "Philemon",
  "히브리서": "Hebrews", "히": "Hebrews",
  "야고보서": "James", "약": "James",
  "베드로전서": "1 Peter", "벧전": "1 Peter",
  "베드로후서": "2 Peter", "벧후": "2 Peter",
  "요한1서": "1 John", "요일": "1 John",
  "요한2서": "2 John", "요이": "2 John",
  "요한3서": "3 John", "요삼": "3 John",
  "유다서": "Jude", "유": "Jude",
  "요한계시록": "Revelation", "계": "Revelation",
};

// 한국어 책명 목록 (긴 것 우선 정렬 → 약어 오매칭 방지)
const KOREAN_BOOK_NAMES = Object.keys(KOREAN_BOOK_MAP).sort((a, b) => b.length - a.length);

/**
 * 사용자 입력에서 구절 참조를 추출합니다.
 * 반환값: 영어 verseRef (예: "Psalms 37:5", "Psalms 37:5-6") 또는 null
 */
function detectDirectVerseRef(input: string): string | null {
  // 1) 한국어 책명 + 장:절 패턴 (범위 포함)
  //    예: "시편 37:5", "시편 37:5-6", "시 37:5", "시 37:5-6"
  for (const korName of KOREAN_BOOK_NAMES) {
    // 콜론(:) 형식: "시편 37:5" or "시편 37:5-6"
    const colonPattern = new RegExp(
      `${korName}\\s*(\\d+):(\\d+)(?:-(\\d+))?`,
      "u"
    );
    const colonMatch = input.match(colonPattern);
    if (colonMatch) {
      const engName = KOREAN_BOOK_MAP[korName];
      const chapter = colonMatch[1];
      const startVerse = colonMatch[2];
      const endVerse = colonMatch[3];
      return endVerse
        ? `${engName} ${chapter}:${startVerse}-${endVerse}`
        : `${engName} ${chapter}:${startVerse}`;
    }

    // 장절 표현: "시편 37장 5절" or "시편 37장 5-6절"
    const jangjeolPattern = new RegExp(
      `${korName}\\s*(\\d+)장\\s*(\\d+)(?:-(\\d+))?절`,
      "u"
    );
    const jangjeolMatch = input.match(jangjeolPattern);
    if (jangjeolMatch) {
      const engName = KOREAN_BOOK_MAP[korName];
      const chapter = jangjeolMatch[1];
      const startVerse = jangjeolMatch[2];
      const endVerse = jangjeolMatch[3];
      return endVerse
        ? `${engName} ${chapter}:${startVerse}-${endVerse}`
        : `${engName} ${chapter}:${startVerse}`;
    }

    // 자연어 범위 표현 (콜론 형식): "시편 37:5절에서 9절까지" or "시편 37:5절부터 9절까지"
    const colonRangePattern = new RegExp(
      `${korName}\\s*(\\d+):(\\d+)절(?:에서|부터)\\s*(\\d+)절까지`,
      "u"
    );
    const colonRangeMatch = input.match(colonRangePattern);
    if (colonRangeMatch) {
      const engName = KOREAN_BOOK_MAP[korName];
      const chapter = colonRangeMatch[1];
      const startVerse = colonRangeMatch[2];
      const endVerse = colonRangeMatch[3];
      return `${engName} ${chapter}:${startVerse}-${endVerse}`;
    }

    // 자연어 범위 표현 (장절 형식): "시편 37장 5절에서 9절까지" or "시편 37장 5절부터 9절까지"
    const jangjeolRangePattern = new RegExp(
      `${korName}\\s*(\\d+)장\\s*(\\d+)절(?:에서|부터)\\s*(\\d+)절까지`,
      "u"
    );
    const jangjeolRangeMatch = input.match(jangjeolRangePattern);
    if (jangjeolRangeMatch) {
      const engName = KOREAN_BOOK_MAP[korName];
      const chapter = jangjeolRangeMatch[1];
      const startVerse = jangjeolRangeMatch[2];
      const endVerse = jangjeolRangeMatch[3];
      return `${engName} ${chapter}:${startVerse}-${endVerse}`;
    }
  }

  // 2) 영어 책명 패턴 (이미 영어로 입력한 경우)
  //    예: "John 3:16", "Psalms 37:5-6", "1 Corinthians 13:4"
  const engPattern = /\b([1-3]?\s*[A-Za-z]+(?:\s+[A-Za-z]+)?)\s+(\d+):(\d+)(?:-(\d+))?\b/;
  const engMatch = input.match(engPattern);
  if (engMatch) {
    const bookName = engMatch[1].trim();
    const chapter = engMatch[2];
    const startVerse = engMatch[3];
    const endVerse = engMatch[4];
    return endVerse
      ? `${bookName} ${chapter}:${startVerse}-${endVerse}`
      : `${bookName} ${chapter}:${startVerse}`;
  }

  return null;
}

// 최대 허용 구절 범위 (초과 시 시작 절~시작+MAX-1로 clamp)
const MAX_VERSE_RANGE = 20;

/**
 * verseRef의 범위가 MAX_VERSE_RANGE를 초과하면 clamp합니다.
 * 예: "Genesis 1:1-50" → "Genesis 1:1-20"
 */
function clampVerseRef(verseRef: string): string {
  const rangeMatch = verseRef.match(/^(.+)\s+(\d+):(\d+)-(\d+)$/);
  if (!rangeMatch) return verseRef; // 단일 절이면 그대로

  const [, book, chapter, startStr, endStr] = rangeMatch;
  const start = parseInt(startStr, 10);
  const end = parseInt(endStr, 10);
  const range = end - start + 1;

  if (range > MAX_VERSE_RANGE) {
    const clampedEnd = start + MAX_VERSE_RANGE - 1;
    logger.warn(`[clampVerseRef] Range ${range} exceeds max ${MAX_VERSE_RANGE}, clamping: ${verseRef} → ${book} ${chapter}:${start}-${clampedEnd}`);
    return `${book} ${chapter}:${start}-${clampedEnd}`;
  }

  return verseRef;
}

/**
 * 사용자 입력이 "유사한 구절 추천" 의도인지 확인합니다.
 * 구절 패턴이 있어도 유사 키워드가 있으면 GPT 자유 추천으로 처리합니다.
 */
function hasSimilarityIntent(input: string): boolean {
  const SIMILARITY_KEYWORDS = [
    "같은", "같은 주제", "비슷한", "유사한", "처럼",
    "관련된", "관련", "주제로", "주제의", "주제에", "관한", "관해",
    "이와 같은", "이런", "이러한", "이런 류", "이런 종류",
    "다른", "또 다른", "말고", "이외에", "외에", "이 외에",
    "아닌", "말고 다른", "외의", "이외의",
  ];
  return SIMILARITY_KEYWORDS.some((kw) => input.includes(kw));
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
      await checkDailyQuota(callerId, nickname, gender);

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

      // =========================================
      // 의도 분류: 직접 구절 요청 vs 유사 추천 vs 자유 추천
      // =========================================
      const rawVerseRef = detectDirectVerseRef(mood);
      const detectedVerseRef = rawVerseRef ? clampVerseRef(rawVerseRef) : null;
      const isSimilarityRequest = hasSimilarityIntent(mood);
      const isDirectVerseRequest = detectedVerseRef !== null && !isSimilarityRequest;

      logger.info("recommendVerse intent classification", {
        mood,
        detectedVerseRef,
        isSimilarityRequest,
        isDirectVerseRequest,
      });

      const openai = await getOpenAIClient(OPENAI_API_KEY.value());

      let result: { verseRef: string; rationale: string };

      if (isDirectVerseRequest) {
        // =========================================
        // [직접 구절 요청] verseRef는 서버에서 결정, GPT는 rationale만 생성
        // =========================================
        const fixedVerseRef = detectedVerseRef!;
        logger.info("Direct verse request detected", { fixedVerseRef });

        const rationalePrompt = `사용자: ${userLabel}
입력: "${mood}${noteSection}"
말씀: ${fixedVerseRef}

사용자가 직접 요청한 이 말씀이 사용자의 입력과 어떻게 연결되는지 경건하게 설명하세요. (1-2문장)

규칙:
- 사용자가 입력한 내용의 영적 의미를 깊이 통찰하여 설명
- 일반적인 위로나 축복 표현 금지 ("위로가 되기를", "바랍니다", "느끼시는", "믿습니다" 등)
- 사용자의 상황과 이 말씀 사이의 신학적 연결점을 구체적으로 제시`;

        const rationaleCompletion = await openai.chat.completions.create({
          model: "gpt-4o-mini",
          temperature: 0.5,
          messages: [
            {
              role: "system",
              content: "당신은 성경 구절을 해설하는 목사입니다.",
            },
            {
              role: "user",
              content: rationalePrompt,
            },
          ],
          response_format: {
            type: "json_schema" as const,
            json_schema: {
              name: "RationaleOnly",
              strict: true,
              schema: {
                type: "object",
                properties: {
                  rationale: { type: "string", description: "말씀이 주어진 이유 (1-2문장)" },
                },
                required: ["rationale"],
                additionalProperties: false,
              },
            },
          },
        });

        const rationaleContent = rationaleCompletion.choices[0]?.message?.content;
        if (!rationaleContent) {
          throw new functions.https.HttpsError("internal", "Empty response from OpenAI");
        }

        const rationaleResult = JSON.parse(rationaleContent);
        result = { verseRef: fixedVerseRef, rationale: rationaleResult.rationale };

      } else {
        // =========================================
        // [유사 추천 / 자유 추천] 기존 GPT 추천 흐름
        // =========================================
        // 후보 3개 방식: 30개 exclude list + GPT 각각 검증 + 서버 필터링
        const recentVerses = recommendedVerses.slice(-30); // 마지막 30개
        const excludeList = recentVerses.length > 0
          ? recentVerses.map((v) => `- ${v}`).join("\n")
          : "";

        // System message: 역할 정의 + exclude list 제약 (절대 규칙)
        const systemMessage = excludeList
          ? `당신은 성경 구절을 추천하는 목사입니다.

🚨 [절대 규칙 - 시스템 레벨 제약] 🚨
다음 구절들은 **절대로 추천할 수 없습니다**:
${excludeList}

⛔ 위 목록에 있는 구절을 추천하면 시스템 오류가 발생합니다.
⛔ 사용자 입력과 의미적으로 연관이 있어도, 위 목록에 있으면 **절대 추천 금지**.
✅ 반드시 위 목록에 **없는** 새로운 구절을 찾아서 추천하세요.

[추천 스타일]
사용자가 입력한 내용의 영적 의미를 깊이 통찰하고, 하나님께서 이 특정한 말씀을 통해 사용자에게 전하시려는 메시지가 무엇인지 경건하게 해석하세요. '위로가 되기를', '바랍니다', '느끼시는', '믿습니다' 같은 일반적 표현을 피하고, 사용자의 현재 상황과 말씀 사이의 신학적이고 실제적인 연결점을 구체적으로 제시하세요.`
          : `당신은 성경 구절을 추천하는 목사입니다. 사용자가 입력한 내용의 영적 의미를 깊이 통찰하고, 하나님께서 이 특정한 말씀을 통해 사용자에게 전하시려는 메시지가 무엇인지 경건하게 해석하세요. '위로가 되기를', '바랍니다', '느끼시는', '믿습니다' 같은 일반적 표현을 피하고, 사용자의 현재 상황과 말씀 사이의 신학적이고 실제적인 연결점을 구체적으로 제시하세요.`;

        // User message: 사용자 정보 + 출력 형식 (요청 내용)
        const userMessage = `사용자: ${userLabel}
입력: "${mood}${noteSection}"

위 사용자에게 적합한 성경 구절 후보 2개를 추천하세요.
각 후보는 반드시 제외 목록에 **없는** 구절이어야 합니다.

[출력 형식]
2개의 후보를 배열로 반환:
- verseRef: 영어 책명 + 장:절 (예: "John 3:16", 범위: "Psalms 37:5-6")
- isInExcludeList: 제외 목록에 있는가? (반드시 false)
- rationale: 이 말씀이 주어진 이유 (1-2문장)
  * 사용자 입력의 영적 의미를 통찰하여, 말씀과의 실제적 연결점을 경건하게 설명
  * "위로가 되기를", "바랍니다", "느끼시는" 등 일반적 표현 금지

🚨 모든 후보는 isInExcludeList: false여야 합니다!`;

        const responseFormat = {
          type: "json_schema" as const,
          json_schema: {
            name: "VerseRecommendationCandidates",
            strict: true,
            schema: {
              type: "object",
              properties: {
                candidates: {
                  type: "array",
                  description: "2개의 구절 후보",
                  items: {
                    type: "object",
                    properties: {
                      verseRef: {
                        type: "string",
                        description: "성경 구절 참조 (예: John 3:16, Psalms 37:5-6)",
                      },
                      isInExcludeList: {
                        type: "boolean",
                        description: "제외 목록에 있는가? (반드시 false)",
                      },
                      rationale: {
                        type: "string",
                        description: "추천 이유 (1-2문장)",
                      },
                    },
                    required: ["verseRef", "isInExcludeList", "rationale"],
                    additionalProperties: false,
                  },
                  minItems: 2,
                  maxItems: 2,
                },
              },
              required: ["candidates"],
              additionalProperties: false,
            },
          },
        };

        // 디버깅: System message 로깅
        logger.info("[DEBUG] GPT Request", {
          totalHistoryCount: recommendedVerses.length,
          recentExcludeCount: recentVerses.length,
          excludeListSample: recentVerses.slice(-5), // 마지막 5개만
          systemMessageLength: systemMessage.length,
          hasExcludeList: excludeList.length > 0,
        });

        const completion = await openai.chat.completions.create({
          model: "gpt-4o-mini",
          temperature: 0.5,
          messages: [
            {
              role: "system",
              content: systemMessage,
            },
            {
              role: "user",
              content: userMessage,
            },
          ],
          response_format: responseFormat,
        });

        const content = completion.choices[0]?.message?.content;
        if (!content) {
          throw new functions.https.HttpsError("internal", "Empty response from OpenAI");
        }

        const parsedResponse = JSON.parse(content);
        const candidates = parsedResponse.candidates;

        if (!candidates || candidates.length < 1) {
          throw new functions.https.HttpsError("internal", "Invalid GPT response: no candidates");
        }

        // 로깅: 후보 정보
        logger.info("[DEBUG] GPT Candidates", {
          candidates: candidates.map((c: any) => ({ verseRef: c.verseRef, isInExcludeList: c.isInExcludeList })),
        });

        // 1차 필터: GPT가 isInExcludeList: false라고 표시한 것들
        const gptSafeCandidates = candidates.filter((c: any) => c.isInExcludeList === false);

        // 2차 필터: 서버에서 실제로 exclude list에 없는지 재검증
        const validCandidate = gptSafeCandidates.find((c: any) => !recentVerses.includes(c.verseRef));

        if (validCandidate) {
          // 성공: 유효한 후보 발견
          result = {
            verseRef: validCandidate.verseRef,
            rationale: validCandidate.rationale,
          };
          logger.info("✅ 유효한 후보 선택됨", {
            verseRef: result.verseRef,
          });
        } else {
          // 모든 후보가 exclude list에 있음 → 첫 번째 후보 선택 (fallback)
          result = {
            verseRef: candidates[0].verseRef,
            rationale: candidates[0].rationale,
          };
          logger.warn("⚠️ 모든 후보가 exclude list에 있어서 첫 번째 선택 (fallback)", {
            verseRef: result.verseRef,
            allCandidates: candidates.map((c: any) => c.verseRef),
          });
        }
      }

      logger.info("recommendVerse success", { verseRef: result.verseRef });

      // 추천 결과를 이력에 저장 (동기화하여 다음 요청에서 바로 반영되도록)
      await saveRecommendedVerse(callerId, result.verseRef, nickname, gender);

      // 말씀 추천 요청 기록 (푸시 알림 타겟팅용)
      const todayKST = new Date().toLocaleDateString('en-CA', {
        timeZone: 'Asia/Seoul'  // YYYY-MM-DD 형식
      });

      try {
        const requestData: any = {
          lastRequestDate: todayKST,
          lastRequestTime: admin.firestore.FieldValue.serverTimestamp(),
          requestCount: admin.firestore.FieldValue.increment(1)
        };

        // 프로필 정보 추가 (있으면)
        if (nickname) {
          requestData.nickname = nickname;
        }
        if (gender) {
          requestData.gender = gender;
        }

        await admin.firestore()
          .collection('verse_requests')
          .doc(callerId)
          .set(requestData, { merge: true });
        logger.info("Verse request recorded for push notification targeting");
      } catch (error) {
        logger.warn("Failed to record verse request", error);
        // 실패해도 메인 기능에 영향 없도록 계속 진행
      }

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

[작업 1: 객관적 성경 해설 (korean)]
위 구절의 의미를 객관적으로 해설하세요. 사용자 상황과 무관하게, 본래의 메시지와 신학적 의미를 설명합니다.

규칙:
- 정확히 3문장: ① 핵심 메시지 ② 신학적/영적 의미 ③ 오늘날 보편적 교훈
- 쉼표 최소화, 마침표 종결, 경건하되 딱딱하지 않은 톤
- 금지: 개역개정 직접 인용, 설교체, 영어 단어, 특정 개인 상황 언급

[작업 2: 사용자 맞춤 적용 (rationale)]
사용자: ${userLabel}
입력: "${mood}${noteSection}"

이 말씀이 사용자에게 주어진 이유를 1-2문장으로 설명하세요.
- 사용자 입력의 영적 의미를 통찰하여, 말씀과의 신학적 연결점을 제시
- "위로가 되기를", "바랍니다", "느끼시는" 등 일반적 표현 금지
- 예시: "주님만을 의지하고 싶어" → "${userLabel}께서 주님만을 의지하려는 결단 속에서, 이 말씀은 그 신뢰가 헛되지 않음을 증거합니다."

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
                description: "한국어 해석 (3문장)",
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

// =========================================
// 구절 해설: 직접 입력한 구절에 대한 객관적 성경 해설 생성
// (recommendVerse 없이 직접 구절 검색 후 사용)
// =========================================
interface GetVerseExplanationRequest {
  englishText: string;
  verseRef: string;
  nickname?: string;
  gender?: string;
}

export const getVerseExplanation = onCall(
  { secrets: [OPENAI_API_KEY] },
  async (request) => {
    try {
      const data = request.data as GetVerseExplanationRequest;
      const { englishText, verseRef, nickname, gender } = data;

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

      const callerId = getCallerId(request);

      // 하루 10회 제한 (verse 추천과 별도 카운터)
      await checkDailyQuota(callerId, nickname, gender, "usage_explanation");

      logger.info("getVerseExplanation called", {
        verseRef,
        callerId,
      });

      const prompt = `
성경 구절: ${verseRef}
영어 본문:
${englishText}

당신은 "QTune" 앱의 성경 해설가입니다.
위 성경 구절의 의미를 객관적으로 해설해 주세요.

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

반드시 JSON Schema에 맞춰 응답해 주세요.
`;

      const responseFormat = {
        type: "json_schema" as const,
        json_schema: {
          name: "VerseExplanation",
          strict: true,
          schema: {
            type: "object",
            properties: {
              explanation: {
                type: "string",
                description: "객관적인 성경 해설 3문장",
              },
            },
            required: ["explanation"],
            additionalProperties: false,
          },
        },
      };

      const openai = await getOpenAIClient(OPENAI_API_KEY.value());

      const completion = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        temperature: 0.3,
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
      logger.info("getVerseExplanation success", { verseRef });

      return result;
    } catch (error: any) {
      logger.error("getVerseExplanation error", {
        message: error?.message,
        name: error?.name,
        code: (error as any)?.code,
        stack: error?.stack,
      });

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        error?.message ?? "Unknown error"
      );
    }
  }
);

// =========================================
// 추천 기도문 생성 함수 (generateSuggestedPrayer)
// generateKoreanExplanation에서 분리 → 병렬 호출 가능, 필요할 때만 호출
// =========================================
interface GenerateSuggestedPrayerRequest {
  englishText: string;
  verseRef: string;
  nickname?: string;
  gender?: string;
}

export const generateSuggestedPrayer = onCall(
  { secrets: [OPENAI_API_KEY] },
  async (request) => {
    try {
      const data = request.data as GenerateSuggestedPrayerRequest;
      const { englishText, verseRef, nickname, gender } = data;

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

      const callerId = getCallerId(request);

      // 기도문 전용 카운터 (하루 10회)
      await checkDailyQuota(callerId, nickname, gender, "usage_prayer");

      logger.info("generateSuggestedPrayer called", {
        verseRef,
        callerId,
      });

      // 프로필 정보로 userLabel 생성
      const userLabel = (nickname && gender)
        ? `${nickname} ${gender}님`
        : `${gender || "형제"}님`;

      const prompt = `성경 구절: ${verseRef}
영어 본문:
${englishText}

사용자: ${userLabel}

위 말씀을 바탕으로 기도문을 작성하세요.

규칙:
- 4-5문장, 마지막은 "예수님의 이름으로 기도합니다. 아멘."
- 말씀의 핵심 메시지를 기도에 자연스럽게 녹여낼 것
- 사용자를 1인칭("저")으로 표현
- 경건하되 딱딱하지 않은 톤
- 금지: 개역개정 직접 인용, 영어 단어`;

      const responseFormat = {
        type: "json_schema" as const,
        json_schema: {
          name: "SuggestedPrayer",
          strict: true,
          schema: {
            type: "object",
            properties: {
              suggestedPrayer: {
                type: "string",
                description: "추천 기도문 (4-5문장)",
              },
            },
            required: ["suggestedPrayer"],
            additionalProperties: false,
          },
        },
      };

      const openai = await getOpenAIClient(OPENAI_API_KEY.value());

      const completion = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        temperature: 0.4,
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
      logger.info("generateSuggestedPrayer success", { verseRef });

      return result;
    } catch (error: any) {
      logger.error("generateSuggestedPrayer error", {
        message: error?.message,
        name: error?.name,
        code: (error as any)?.code,
        stack: error?.stack,
      });

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        error?.message ?? "Unknown error"
      );
    }
  }
);

// =========================================
// 푸시 알림: 매분마다 실행하여 사용자별 알림 시간 체크
// v2 Scheduler로 변경 (더 나은 IAM 통합)
// =========================================
export const sendCustomNotification = onSchedule(
  {
    schedule: "* * * * *", // 매분마다 실행
    timeZone: "Asia/Seoul",
  },
  async (event) => {
    logger.info("[sendCustomNotification] Checking user notification settings");

    const db = admin.firestore();
    const messaging = admin.messaging();

    // 현재 시간과 날짜 (KST 기준)
    const now = new Date();
    const kstOffset = 9 * 60 * 60 * 1000;
    const kstDate = new Date(now.getTime() + kstOffset);
    const currentHour = kstDate.getHours();
    const currentMinute = kstDate.getMinutes();
    const todayKST = kstDate.toISOString().split("T")[0];

    logger.info("[sendCustomNotification] Current time", {
      hour: currentHour,
      minute: currentMinute,
      date: todayKST,
    });

    try {
      // 1. 현재 시간에 알림을 받아야 할 사용자 조회
      // 알림이 활성화되어 있고, 시간이 일치하며, FCM 토큰이 있는 사용자
      const usersQuery = await db
        .collection("users")
        .where("isNotificationEnabled", "==", true)
        .where("notificationHour", "==", currentHour)
        .where("notificationMinute", "==", currentMinute)
        .where("fcmToken", "!=", null)
        .get();

      if (usersQuery.empty) {
        logger.info("[sendCustomNotification] No users scheduled for this time");
        return;
      }

      logger.info("[sendCustomNotification] Stats", {
        scheduledUsers: usersQuery.size,
      });

      // 2. 토큰별로 개별 전송 (admin.messaging() 사용)
      let successCount = 0;
      let failureCount = 0;

      for (const doc of usersQuery.docs) {
        const uid = doc.id;
        const token = doc.data().fcmToken as string;

        try {
          const message = {
            token: token,
            notification: {
              title: "오늘의 QT",
              body: "오늘 하루도 말씀과 함께하세요",
            },
            apns: {
              headers: {
                "apns-priority": "10",
              },
              payload: {
                aps: {
                  alert: {
                    title: "오늘의 QT",
                    body: "오늘 하루도 말씀과 함께하세요",
                  },
                  sound: "default",
                  badge: 1,
                },
              },
            },
            data: {
              type: "daily_reminder",
              date: todayKST,
            },
          };

          const response = await messaging.send(message);
          successCount++;
          logger.info("[sendCustomNotification] Message sent successfully", {
            uid,
            messageId: response,
          });
        } catch (err: any) {
          failureCount++;
          logger.error("[sendCustomNotification] Send error", {
            uid,
            error: err?.message,
            code: err?.code,
            stack: err?.stack,
            errorDetails: err?.errorInfo,
          });

          // 유효하지 않은 토큰 제거
          if (
            err?.code === "messaging/registration-token-not-registered" ||
            err?.code === "messaging/invalid-registration-token"
          ) {
            await db.collection("users").doc(uid).update({
              fcmToken: admin.firestore.FieldValue.delete(),
            });
            logger.info("[sendCustomNotification] Removed invalid token", {
              uid,
            });
          }
        }
      }

      logger.info("[sendCustomNotification] Completed", {
        targetCount: usersQuery.size,
        successCount,
        failureCount,
      });
    } catch (error) {
      logger.error("[sendCustomNotification] Error", error);
      throw error;
    }
  }
);

// =========================================
// 테스트용 수동 푸시 알림 함수
// =========================================
export const testPushNotification = onCall(
  {
    cors: true,
  },
  async (request) => {
    try {
      const callerId = getCallerId(request);
      const { targetUid } = request.data;

      logger.info("[testPushNotification] Manual push test", {
        callerId,
        targetUid: targetUid || "self",
      });

      const db = admin.firestore();
      const messaging = admin.messaging();

      // 대상 사용자 결정 (targetUid가 없으면 호출자 자신)
      const uid = targetUid || callerId;

      // FCM 토큰 조회
      const userDoc = await db.collection("users").doc(uid).get();

      if (!userDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "User not found"
        );
      }

      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "User has no FCM token"
        );
      }

      // 푸시 알림 전송
      const message = {
        token: fcmToken,
        notification: {
          title: "🔔 테스트 알림",
          body: "푸시 알림이 정상적으로 작동합니다!",
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
        data: {
          type: "test",
          timestamp: new Date().toISOString(),
        },
      };

      const response = await messaging.send(message);

      logger.info("[testPushNotification] Success", {
        uid,
        messageId: response,
      });

      return {
        success: true,
        messageId: response,
        targetUid: uid,
        timestamp: new Date().toISOString(),
      };
    } catch (error: any) {
      logger.error("[testPushNotification] Error", {
        message: error?.message,
        code: error?.code,
      });

      // 에러 다시 던지기
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        error?.message || "Failed to send test notification"
      );
    }
  }
);
