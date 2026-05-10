#!/usr/bin/env node
/**
 * Bible ingest — bolls.life (WEB / KJV / KRV)
 *
 * 사용법:
 *   node ingest.js [--translations WEB,KJV,KRV] [--resume]
 *
 * 결과: ./bible.sqlite
 *
 * 재시도 / 스로틀 / 디스크 캐시 지원.
 */

const fs = require("fs");
const path = require("path");
const Database = require("better-sqlite3");
const BOOKS = require("./books");

const DB_PATH = path.join(__dirname, "bible.sqlite");
const CACHE_DIR = path.join(__dirname, ".cache");
fs.mkdirSync(CACHE_DIR, { recursive: true });

const args = process.argv.slice(2);
const resume = args.includes("--resume");
const trArgIndex = args.indexOf("--translations");
const TRANSLATIONS = trArgIndex >= 0
  ? args[trArgIndex + 1].split(",")
  : ["WEB", "KJV", "KRV"];

const REQUEST_DELAY_MS = 200;
const MAX_RETRIES = 5;

function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }

function cacheKey(translation, bookId, chapter) {
  return path.join(CACHE_DIR, `${translation}_${bookId}_${chapter}.json`);
}

function readCache(translation, bookId, chapter) {
  const p = cacheKey(translation, bookId, chapter);
  if (fs.existsSync(p)) {
    try { return JSON.parse(fs.readFileSync(p, "utf8")); } catch { return null; }
  }
  return null;
}

function writeCache(translation, bookId, chapter, data) {
  fs.writeFileSync(cacheKey(translation, bookId, chapter), JSON.stringify(data));
}

async function fetchWithRetry(url) {
  for (let i = 0; i < MAX_RETRIES; i++) {
    try {
      const res = await fetch(url, {
        headers: { "User-Agent": "QTune-BibleIngest/1.0" },
        signal: AbortSignal.timeout(25000),
      });
      if (res.status === 429 || res.status >= 500) {
        const wait = Math.min(30000, 1000 * Math.pow(2, i));
        console.warn(`  ⚠️  ${res.status} ${url} — retry in ${wait}ms`);
        await sleep(wait);
        continue;
      }
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return await res.json();
    } catch (e) {
      if (i === MAX_RETRIES - 1) throw e;
      const wait = Math.min(30000, 1000 * Math.pow(2, i));
      console.warn(`  ⚠️  ${e.message} — retry in ${wait}ms`);
      await sleep(wait);
    }
  }
}

// Strong's 태그 제거 + 공백 정리
function cleanText(t) {
  return (t || "")
    .replace(/<S>\d+<\/S>/g, "")
    .replace(/<br\/?>/g, " ")
    .replace(/<[^>]+>/g, "")  // 기타 HTML 태그 제거
    .replace(/\s+/g, " ")
    .trim();
}

async function fetchChapter(book, chapter, translation) {
  const cached = readCache(translation, book.id, chapter);
  if (cached) return cached;

  const url = `https://bolls.life/get-text/${translation}/${book.bolls}/${chapter}/`;
  const data = await fetchWithRetry(url);
  if (!Array.isArray(data)) {
    throw new Error(`malformed response for ${translation} ${book.en} ${chapter}`);
  }
  const verses = data
    .map((v) => ({ verse: v.verse, text: cleanText(v.text) }))
    .filter((v) => v.text.length > 0);

  writeCache(translation, book.id, chapter, verses);
  await sleep(REQUEST_DELAY_MS);
  return verses;
}

function initDatabase() {
  if (fs.existsSync(DB_PATH) && !resume) {
    fs.unlinkSync(DB_PATH);
  }
  const db = new Database(DB_PATH);
  db.pragma("journal_mode = WAL");
  db.pragma("synchronous = NORMAL");
  db.exec(`
    CREATE TABLE IF NOT EXISTS books (
      book_id INTEGER PRIMARY KEY,
      english_name TEXT NOT NULL,
      korean_name TEXT NOT NULL,
      chapter_count INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS verses (
      book_id INTEGER NOT NULL,
      chapter INTEGER NOT NULL,
      verse INTEGER NOT NULL,
      translation TEXT NOT NULL,
      text TEXT NOT NULL,
      PRIMARY KEY (book_id, chapter, verse, translation)
    ) WITHOUT ROWID;
    CREATE INDEX IF NOT EXISTS idx_verses_lookup
      ON verses(translation, book_id, chapter, verse);
  `);
  const upsertBook = db.prepare(
    "INSERT OR REPLACE INTO books (book_id, english_name, korean_name, chapter_count) VALUES (?, ?, ?, ?)"
  );
  const insertMany = db.transaction(() => {
    for (const b of BOOKS) upsertBook.run(b.id, b.en, b.ko, b.chapters);
  });
  insertMany();
  return db;
}

async function main() {
  console.log(`📘 Translations: ${TRANSLATIONS.join(", ")}`);
  console.log(`📂 Output: ${DB_PATH}`);
  console.log(`🔁 Resume: ${resume}`);

  const db = initDatabase();
  const insertVerse = db.prepare(
    "INSERT OR REPLACE INTO verses (book_id, chapter, verse, translation, text) VALUES (?, ?, ?, ?, ?)"
  );

  const totalChapters = BOOKS.reduce((s, b) => s + b.chapters, 0);
  console.log(`📊 Chapters per translation: ${totalChapters}`);

  const startTime = Date.now();
  for (const translation of TRANSLATIONS) {
    console.log(`\n=== ${translation} ===`);
    let idx = 0;
    for (const book of BOOKS) {
      for (let ch = 1; ch <= book.chapters; ch++) {
        idx++;
        try {
          const verses = await fetchChapter(book, ch, translation);
          const tx = db.transaction((rows) => {
            for (const row of rows) {
              insertVerse.run(book.id, ch, row.verse, translation, row.text);
            }
          });
          tx(verses);
          if (idx % 50 === 0 || idx === totalChapters) {
            const elapsed = ((Date.now() - startTime) / 1000).toFixed(0);
            console.log(`  [${translation}] ${idx}/${totalChapters} ${book.en} ${ch} (${verses.length}v) — ${elapsed}s`);
          }
        } catch (e) {
          console.error(`  🔴 ${translation} ${book.en} ${ch}: ${e.message}`);
          throw e;
        }
      }
    }
  }

  const summary = db.prepare(`
    SELECT translation, COUNT(*) as cnt FROM verses GROUP BY translation ORDER BY translation
  `).all();
  console.log("\n📈 Row counts:");
  for (const row of summary) {
    console.log(`  ${row.translation}: ${row.cnt}`);
  }

  // 번들 리소스로 쓸거라 WAL 모드 해제 (사이드카 -wal/-shm 없이 immutable open 가능하게).
  db.pragma("journal_mode = DELETE");
  db.exec("VACUUM;");
  db.close();

  const size = fs.statSync(DB_PATH).size;
  console.log(`\n📦 DB size: ${(size / 1024 / 1024).toFixed(2)} MB`);
  console.log(`✅ done: ${DB_PATH}`);
}

main().catch((e) => {
  console.error("FATAL:", e);
  process.exit(1);
});
