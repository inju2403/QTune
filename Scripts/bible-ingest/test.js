#!/usr/bin/env node
/**
 * Smoke test: Obadiah(31) + Jude(65) 2권만 3역본 다 받아서 검증
 */
const path = require("path");
const BOOKS = require("./books");

// 임시로 books를 2권으로 줄인 모듈 경로 대체를 사용하지 않고,
// 그냥 ingest.js의 로직 일부를 복사해서 빠르게 검증.

const fs = require("fs");
const Database = require("better-sqlite3");

const DB_PATH = path.join(__dirname, "bible-test.sqlite");

const TEST_BOOKS = BOOKS.filter((b) => b.id === 31 || b.id === 65);

async function fetchWithRetry(url) {
  for (let i = 0; i < 3; i++) {
    try {
      const res = await fetch(url, { signal: AbortSignal.timeout(20000) });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return await res.json();
    } catch (e) {
      if (i === 2) throw e;
      await new Promise((r) => setTimeout(r, 1000 * Math.pow(2, i)));
    }
  }
}

async function main() {
  if (fs.existsSync(DB_PATH)) fs.unlinkSync(DB_PATH);
  const db = new Database(DB_PATH);
  db.exec(`
    CREATE TABLE verses (
      book_id INTEGER, chapter INTEGER, verse INTEGER,
      translation TEXT, text TEXT,
      PRIMARY KEY (book_id, chapter, verse, translation)
    );
  `);
  const ins = db.prepare("INSERT INTO verses VALUES (?,?,?,?,?)");

  for (const book of TEST_BOOKS) {
    for (let ch = 1; ch <= book.chapters; ch++) {
      for (const tr of ["WEB", "KJV", "KRV"]) {
        let verses;
        if (tr === "KRV") {
          const data = await fetchWithRetry(`https://bolls.life/get-text/KRV/${book.bolls}/${ch}/`);
          verses = data.map((v) => ({ verse: v.verse, text: v.text }));
        } else {
          const param = book.en.toLowerCase().replace(/ /g, "+");
          const data = await fetchWithRetry(`https://bible-api.com/${param}+${ch}?translation=${tr.toLowerCase()}`);
          verses = data.verses.map((v) => ({ verse: v.verse, text: v.text.trim() }));
        }
        for (const v of verses) ins.run(book.id, ch, v.verse, tr, v.text);
        console.log(`  ${tr} ${book.en} ${ch}: ${verses.length} verses`);
        await new Promise((r) => setTimeout(r, 250));
      }
    }
  }

  // sample
  const sample = db.prepare(`
    SELECT * FROM verses WHERE book_id=65 AND chapter=1 AND verse=1 ORDER BY translation
  `).all();
  console.log("\nJude 1:1 samples:");
  for (const s of sample) console.log(`  [${s.translation}] ${s.text}`);

  const total = db.prepare("SELECT COUNT(*) as c FROM verses").get().c;
  console.log(`\nTotal rows: ${total}`);

  const size = fs.statSync(DB_PATH).size;
  console.log(`DB size: ${(size / 1024).toFixed(1)} KB`);
  db.close();
}

main().catch((e) => { console.error(e); process.exit(1); });
