#!/usr/bin/env node
// Generates Sapientia/Resources/Liturgy/little-hours.json from the two sources
// of record, so no liturgical text is ever retyped by hand:
//
//   scripts/liturgy/offices-data.js  — openings, hymns, psalms, chapters, collects
//   scripts/liturgy/devotions.json   — the Angelus and Regina Coeli
//
// Run after editing either source:
//   node scripts/liturgy/build-little-hours.mjs
//
// scripts/diff-office-text.py verifies the committed JSON still matches the
// JS source, so drift between them fails CI rather than shipping silently.

import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(here, "..", "..");

const { GLORIA, OFFICES, COLLECT_INTRO_LAY, CONCLUSION, FAITHFUL_DEPARTED } =
  await import(join(here, "offices-data.js"));

const devotions = JSON.parse(readFileSync(join(here, "devotions.json"), "utf8"));

/** `{ v, t }` in the source becomes `{ speaker, text }` in the bundle. */
const versicles = (list) => list.map(({ v, t }) => ({ speaker: v, text: t }));

/** Chapter keys stay strings so Swift can decode `[String: Chapter]`. */
const chapters = (source) =>
  Object.fromEntries(
    Object.entries(source).map(([index, chapter]) => [
      String(index),
      {
        reference: chapter.ref,
        text: chapter.text,
        versicle: chapter.versicle,
        response: chapter.response,
      },
    ])
  );

const office = (source) => {
  const built = {
    key: source.key,
    latin: source.latin,
    name: source.name,
    hour: source.hour,
    defaultTime: source.defaultTime,
    opening: versicles(source.opening),
    hymn: {
      latin: source.hymn.latin,
      note: source.hymn.note,
      verses: source.hymn.verses,
    },
    psalms: source.psalms.map((psalm) => ({
      number: psalm.num,
      latin: psalm.latin,
      verses: psalm.verses,
    })),
    chapters: chapters(source.chapters),
    collects: source.collects.map(({ title, text }) => ({ title, text })),
  };

  // Only Sext is preceded by a devotion, and only Sext carries the rubric
  // saying so. Keying off the rubric rather than the office name keeps the
  // two in step if the source ever changes.
  if (source.angelusNote) {
    built.angelusNote = source.angelusNote;
    built.angelus = devotions.angelus;
    built.reginaCoeli = devotions.reginaCoeli;
  }

  return built;
};

/**
 * The Gloria Patri is said as a responsory — the officiant begins, the people
 * answer — so the office renders it as two speaking parts rather than one
 * block of prose.
 *
 * Derived from GLORIA rather than retyped: its two lines are already the two
 * halves, and the `*` marks are pointing for chant, not punctuation. Stripping
 * them yields exactly the said form. `gloria` itself stays in the bundle
 * verbatim so scripts/diff-office-text.py can still verify it against source.
 */
const gloriaVersicles = GLORIA.split("\n").map((line, index) => ({
  speaker: index === 0 ? "Officiant" : "People",
  text: line.replace(/\s*\*\s*/g, " ").trim(),
}));

const bundle = {
  gloria: GLORIA,
  gloriaVersicles,
  collectIntroLay: versicles(COLLECT_INTRO_LAY),
  conclusion: versicles(CONCLUSION),
  faithfulDeparted: FAITHFUL_DEPARTED,
  offices: Object.fromEntries(
    Object.entries(OFFICES).map(([key, source]) => [key, office(source)])
  ),
};

const target = join(repoRoot, "Sapientia", "Resources", "Liturgy", "little-hours.json");
writeFileSync(target, JSON.stringify(bundle, null, 2) + "\n", "utf8");

const offices = Object.keys(bundle.offices).length;
const psalms = Object.values(bundle.offices).reduce((n, o) => n + o.psalms.length, 0);
console.log(`wrote ${target}`);
console.log(`  ${offices} offices, ${psalms} psalms`);
