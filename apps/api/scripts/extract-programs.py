#!/usr/bin/env python3
"""Regenerate packages/programs/*.json from the source PDFs."""

import json
import re
import sys
from pathlib import Path

try:
    import fitz
except ImportError:
    print("Install pymupdf: pip install pymupdf", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "packages" / "programs"
CALI_PDF = Path.home() / "Desktop/marathon/12_week_weighted_calisthenics_program_fixed.pdf"
RUN_PDF = Path.home() / "Desktop/marathon/dual_goal_52_week_running_plan.pdf"

WEEKDAY_MAP_CALI = {1: "MONDAY", 2: "TUESDAY", 3: "THURSDAY", 4: "SATURDAY"}
WEEKDAY_MAP_ENDURANCE = {
    1: "TUESDAY",
    2: "THURSDAY",
    3: "SATURDAY",
    4: "SUNDAY",
    5: "MONDAY",
}


def extract_all(path: Path) -> str:
    doc = fitz.open(path)
    return "\n".join(page.get_text() for page in doc)


def build_calisthenics(text: str) -> dict:
    week_blocks = re.split(r"WEEK\s+(\d+)\s*\|\s*TRAINING", text)
    weeks = []
    for i in range(1, len(week_blocks), 2):
        week_num = int(week_blocks[i])
        content = week_blocks[i + 1]
        day_splits = re.split(
            r"DAY\s+(\d+)\s*-\s*(MONDAY|TUESDAY|WEDNESDAY|THURSDAY|FRIDAY|SATURDAY|SUNDAY)\s*\|\s*([^\n]+)",
            content,
        )
        sessions = []
        for j in range(1, len(day_splits), 4):
            day_num = int(day_splits[j])
            weekday = day_splits[j + 1].upper()
            label = day_splits[j + 2].strip()
            body = day_splits[j + 3]
            lines = []
            for ln in body.splitlines():
                s = ln.strip()
                if not s:
                    continue
                if s.startswith(
                    (
                        "12-Week",
                        "Page ",
                        "WEEK ",
                        "Planned loads",
                        "Use lighter",
                        "Testing week",
                        "Testing is",
                        "DAY ",
                    )
                ):
                    continue
                if s in ("Exercise", "Added weight", "Sets x reps", "Rest"):
                    continue
                lines.append(s)
            exercises = []
            idx = 0
            while idx + 3 < len(lines):
                name, weight, sets_reps, rest = lines[idx : idx + 4]
                looks_sets = bool(
                    re.search(r"\d+\s*x\s*\d+|1 each|\d+\s*/\s*\d+", sets_reps, re.I)
                )
                looks_rest = bool(re.search(r"min|sec", rest, re.I))
                if looks_sets and looks_rest:
                    exercises.append(
                        {
                            "name": name,
                            "targetWeight": weight,
                            "setsReps": sets_reps,
                            "rest": rest,
                            "prescription": f"{name} — {weight} — {sets_reps} — rest {rest}",
                            "metrics": ["WEIGHT", "REPS", "SETS"],
                        }
                    )
                    idx += 4
                else:
                    idx += 1
            sessions.append(
                {
                    "dayNumber": day_num,
                    "defaultWeekday": weekday,
                    "sessionLabel": label,
                    "exercises": exercises,
                }
            )
        weeks.append({"weekNumber": week_num, "sessions": sessions})
    return {
        "programType": "CALISTHENICS",
        "title": "12-Week Weighted Calisthenics",
        "totalWeeks": 12,
        "defaultWeekdayByDayNumber": {str(k): v for k, v in WEEKDAY_MAP_CALI.items()},
        "weeks": weeks,
    }


def build_endurance(text: str) -> dict:
    parts = re.split(r"\nWeek\s+(\d+)\n(?=Day\s+1:)", text)
    weeks = []
    for i in range(1, len(parts), 2):
        week_num = int(parts[i])
        content = parts[i + 1]
        content = re.split(
            r"\n(DURABILITY|3-RUN|5K FOUNDATION|5K DEVELOPMENT|5K RACE|MARATHON BASE|MARATHON-SPECIFIC|TAPER|STRENGTH|TABLE|Milestones|Important:)",
            content,
        )[0]
        day_matches = list(
            re.finditer(r"Day\s+(\d+):\s*(.+?)(?=\nDay\s+\d+:|\Z)", content, re.S)
        )
        sessions = []
        for m in day_matches:
            day_num = int(m.group(1))
            prescription = re.sub(r"\s+", " ", m.group(2)).strip()
            prescription = re.sub(r"DUAL-GOAL.*$", "", prescription).strip()
            prescription = re.sub(r"Page\s+\d+.*$", "", prescription).strip()
            weekday = WEEKDAY_MAP_ENDURANCE.get(day_num, "MONDAY")
            metrics = (
                ["DURATION", "NOTES"]
                if re.search(r"bike|cycling", prescription, re.I)
                else ["DISTANCE", "PACE", "DURATION", "NOTES"]
            )
            short = prescription[:100] + ("…" if len(prescription) > 100 else "")
            sessions.append(
                {
                    "dayNumber": day_num,
                    "defaultWeekday": weekday,
                    "sessionLabel": f"Day {day_num}",
                    "exercises": [
                        {
                            "name": short,
                            "prescription": prescription,
                            "targetWeight": None,
                            "setsReps": None,
                            "rest": None,
                            "metrics": metrics,
                        }
                    ],
                }
            )
        if sessions:
            weeks.append({"weekNumber": week_num, "sessions": sessions})
    return {
        "programType": "ENDURANCE",
        "title": "52-Week Dual-Goal Running",
        "totalWeeks": 52,
        "defaultWeekdayByDayNumber": {
            str(k): v for k, v in WEEKDAY_MAP_ENDURANCE.items()
        },
        "weeks": weeks,
    }


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    cali = build_calisthenics(extract_all(CALI_PDF))
    endu = build_endurance(extract_all(RUN_PDF))
    (OUT / "calisthenics.json").write_text(json.dumps(cali, indent=2))
    (OUT / "endurance.json").write_text(json.dumps(endu, indent=2))
    print(f"Wrote {OUT / 'calisthenics.json'} ({len(cali['weeks'])} weeks)")
    print(f"Wrote {OUT / 'endurance.json'} ({len(endu['weeks'])} weeks)")


if __name__ == "__main__":
    main()
