#!/usr/bin/env python3
"""Verify the bundled Little Hours text still matches its source of record.

`Sapientia/Resources/Liturgy/little-hours.json` is generated from
`scripts/liturgy/offices-data.js`. This script re-reads the JS source
independently (via node) and compares every text field against the committed
JSON, so an edit to one without the other fails here instead of shipping.

    python3 scripts/diff-office-text.py

Exits 0 when they agree, 1 on any mismatch, printing each difference.

Not covered: the Angelus and Regina Coeli. Those are not in offices-data.js —
it carries only the rubric naming them — so they have no machine-readable
original. `LittleHoursDatasetTests` asserts them verbatim instead, including
the cross in the Angelus collect. This script reports them as unchecked rather
than silently implying they were verified.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
BUNDLE = REPO / "Sapientia" / "Resources" / "Liturgy" / "little-hours.json"
SOURCE_DIR = REPO / "scripts" / "liturgy"

# Read the ES module through node rather than parsing JS by hand: the source
# has comments, unquoted keys and apostrophes inside double-quoted strings,
# none of which a JSON or regex reader survives.
DUMP = """
import { GLORIA, OFFICES, COLLECT_INTRO_LAY, CONCLUSION, FAITHFUL_DEPARTED }
  from './offices-data.js';
process.stdout.write(JSON.stringify(
  { GLORIA, OFFICES, COLLECT_INTRO_LAY, CONCLUSION, FAITHFUL_DEPARTED }));
"""


def load_source() -> dict:
    dump = SOURCE_DIR / ".dump-offices.mjs"
    dump.write_text(DUMP, encoding="utf-8")
    try:
        result = subprocess.run(
            ["node", str(dump)],
            capture_output=True,
            text=True,
            cwd=SOURCE_DIR,
            check=True,
        )
    except FileNotFoundError:
        sys.exit("node is required to read offices-data.js, but was not found on PATH")
    except subprocess.CalledProcessError as error:
        sys.exit(f"could not evaluate offices-data.js:\n{error.stderr}")
    finally:
        dump.unlink(missing_ok=True)
    return json.loads(result.stdout)


def compare(where: str, expected, actual, failures: list[str]) -> None:
    if expected != actual:
        failures.append(f"{where}\n    source: {expected!r}\n    bundle: {actual!r}")


def main() -> int:
    if not BUNDLE.exists():
        sys.exit(f"missing {BUNDLE.relative_to(REPO)} — run build-little-hours.mjs")

    source = load_source()
    bundle = json.loads(BUNDLE.read_text(encoding="utf-8"))
    failures: list[str] = []
    checked = 0

    compare("gloria", source["GLORIA"], bundle["gloria"], failures)
    compare("faithfulDeparted", source["FAITHFUL_DEPARTED"], bundle["faithfulDeparted"], failures)
    checked += 2

    for name, key in (("collectIntroLay", "COLLECT_INTRO_LAY"), ("conclusion", "CONCLUSION")):
        expected = [{"speaker": v["v"], "text": v["t"]} for v in source[key]]
        compare(name, expected, bundle[name], failures)
        checked += len(expected)

    source_offices = source["OFFICES"]
    if sorted(source_offices) != sorted(bundle["offices"]):
        failures.append(
            f"office keys differ\n    source: {sorted(source_offices)}"
            f"\n    bundle: {sorted(bundle['offices'])}"
        )
        print_report(failures, checked)
        return 1

    for key, src in source_offices.items():
        got = bundle["offices"][key]

        for field in ("key", "latin", "name", "hour", "defaultTime"):
            compare(f"{key}.{field}", src[field], got[field], failures)
            checked += 1

        expected_opening = [{"speaker": v["v"], "text": v["t"]} for v in src["opening"]]
        compare(f"{key}.opening", expected_opening, got["opening"], failures)
        checked += len(expected_opening)

        compare(f"{key}.hymn.latin", src["hymn"]["latin"], got["hymn"]["latin"], failures)
        compare(f"{key}.hymn.note", src["hymn"]["note"], got["hymn"]["note"], failures)
        for i, verse in enumerate(src["hymn"]["verses"]):
            compare(f"{key}.hymn.verses[{i}]", verse, got["hymn"]["verses"][i], failures)
            checked += 1

        for i, psalm in enumerate(src["psalms"]):
            compare(f"{key}.psalms[{i}].number", psalm["num"], got["psalms"][i]["number"], failures)
            compare(f"{key}.psalms[{i}].latin", psalm["latin"], got["psalms"][i]["latin"], failures)
            for j, verse in enumerate(psalm["verses"]):
                compare(
                    f"{key}.psalms[{i}].verses[{j}]",
                    verse,
                    got["psalms"][i]["verses"][j],
                    failures,
                )
                checked += 1

        for index, chapter in src["chapters"].items():
            got_chapter = got["chapters"].get(str(index))
            if got_chapter is None:
                failures.append(f"{key}.chapters[{index}] missing from bundle")
                continue
            compare(f"{key}.chapters[{index}].reference", chapter["ref"], got_chapter["reference"], failures)
            compare(f"{key}.chapters[{index}].text", chapter["text"], got_chapter["text"], failures)
            compare(f"{key}.chapters[{index}].versicle", chapter["versicle"], got_chapter["versicle"], failures)
            compare(f"{key}.chapters[{index}].response", chapter["response"], got_chapter["response"], failures)
            checked += 4

        for i, collect in enumerate(src["collects"]):
            compare(f"{key}.collects[{i}].title", collect["title"], got["collects"][i]["title"], failures)
            compare(f"{key}.collects[{i}].text", collect["text"], got["collects"][i]["text"], failures)
            checked += 2

        if "angelusNote" in src:
            compare(f"{key}.angelusNote", src["angelusNote"], got.get("angelusNote"), failures)
            checked += 1

    print_report(failures, checked)
    return 1 if failures else 0


def print_report(failures: list[str], checked: int) -> None:
    if failures:
        print(f"{len(failures)} mismatch(es) between offices-data.js and the bundle:\n")
        for failure in failures:
            print(f"  {failure}\n")
    else:
        print(f"{checked} text fields match offices-data.js exactly.")
    print("  not checked here: the Angelus and Regina Coeli (no source in offices-data.js);")
    print("  LittleHoursDatasetTests asserts those verbatim.")


if __name__ == "__main__":
    raise SystemExit(main())
