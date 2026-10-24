#!/usr/bin/env python3
"""Rewrite packages/programs/endurance.json into structured multi-exercise sessions."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PATH = ROOT / "packages" / "programs" / "endurance.json"


def clean(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip(" .;")


def split_segments(prescription: str) -> list[str]:
    text = clean(prescription)
    parts = re.split(r";\s*(?:then\s+)?", text, flags=re.I)
    return [clean(p) for p in parts if clean(p)]


def extract_distance(text: str) -> str | None:
    m = re.search(r"(\d+(?:\.\d+)?\s*km(?:\s*total)?)", text, re.I)
    return m.group(1).replace("  ", " ") if m else None


def extract_duration(text: str) -> str | None:
    m = re.search(r"(\d+(?:\s*-\s*\d+)?\s*min)", text, re.I)
    return re.sub(r"\s+", " ", m.group(1)) if m else None


def extract_pace(text: str) -> str | None:
    m = re.search(
        r"(?:typically|approx(?:imately)?|target|at)?\s*"
        r"(\d{1,2}:\d{2}\s*(?:-\s*\d{1,2}:\d{2})?\s*/\s*km)",
        text,
        re.I,
    )
    if m:
        return re.sub(r"\s+", "", m.group(1).replace(" ", ""))
    if re.search(r"conversational", text, re.I):
        return "conversational"
    if re.search(r"easy effort|easy pace", text, re.I):
        return "easy"
    if re.search(r"current 5[Kk] effort", text, re.I):
        return "5K effort"
    if re.search(r"threshold|comfortably hard", text, re.I):
        return "threshold"
    if re.search(r"marathon effort", text, re.I):
        return "marathon effort"
    return None


def extract_intervals(text: str) -> tuple[str | None, str | None, str | None]:
    """Return (intervals label, setsReps, recovery/rest)."""
    m = re.search(
        r"(\d+)\s*x\s*(\d+(?:\.\d+)?)\s*(min|sec|km|m)\b"
        r"(.*?)(?:with|,\s*)(\d+(?:\s*-\s*\d+)?\s*min(?:\s+\w+)*)",
        text,
        re.I,
    )
    if m:
        count, amount, unit, mid, recovery = m.groups()
        sets = f"{count} x {amount} {unit}"
        pace = extract_pace(mid) or extract_pace(text)
        label = sets if not pace else f"{sets} @ {pace}"
        return label, sets, clean(recovery)

    m2 = re.search(r"(\d+)\s*x\s*(\d+(?:\.\d+)?)\s*(min|sec|km|m)\b", text, re.I)
    if m2:
        sets = f"{m2.group(1)} x {m2.group(2)} {m2.group(3)}"
        pace = extract_pace(text)
        label = sets if not pace else f"{sets} @ {pace}"
        rec = re.search(r"(\d+(?:\s*-\s*\d+)?\s*min(?:\s+(?:easy|jog|recovery)\w*)*)", text, re.I)
        return label, sets, clean(rec.group(1)) if rec else None

    if re.search(r"strides?", text, re.I):
        m3 = re.search(r"(\d+)\s*x\s*(\d+)\s*sec", text, re.I)
        if m3:
            sets = f"{m3.group(1)} x {m3.group(2)} sec"
            return f"strides {sets}", sets, None
        return "strides", None, None
    return None, None, None


def parse_segment(segment: str) -> dict:
    lower = segment.lower()

    if re.search(r"\bmobility\b", lower):
        return {
            "name": "Mobility",
            "prescription": segment,
            "distance": None,
            "pace": None,
            "duration": extract_duration(segment) or "5-10 min",
            "intervals": None,
            "targetWeight": None,
            "setsReps": None,
            "rest": None,
            "metrics": ["DURATION", "NOTES"],
        }

    if re.search(r"strength\s*a\b", lower):
        return {
            "name": "Strength A",
            "prescription": segment,
            "distance": None,
            "pace": None,
            "duration": None,
            "intervals": None,
            "targetWeight": None,
            "setsReps": None,
            "rest": None,
            "metrics": ["NOTES"],
        }

    if re.search(r"strength\s*b\b", lower):
        return {
            "name": "Strength B",
            "prescription": segment,
            "distance": None,
            "pace": None,
            "duration": None,
            "intervals": None,
            "targetWeight": None,
            "setsReps": None,
            "rest": None,
            "metrics": ["NOTES"],
        }

    if re.search(r"\b(bike|cycling|ride)\b", lower):
        return {
            "name": "Easy bike" if "easy" in lower or "optional" in lower else "Bike",
            "prescription": segment,
            "distance": None,
            "pace": None,
            "duration": extract_duration(segment),
            "intervals": None,
            "targetWeight": None,
            "setsReps": None,
            "rest": None,
            "metrics": ["DURATION", "NOTES"],
        }

    if re.search(r"\brest\b", lower) and not re.search(r"\brun\b", lower):
        return {
            "name": "Rest / mobility",
            "prescription": segment,
            "distance": None,
            "pace": None,
            "duration": extract_duration(segment),
            "intervals": None,
            "targetWeight": None,
            "setsReps": None,
            "rest": None,
            "metrics": ["NOTES"],
        }

    intervals, sets_reps, recovery = extract_intervals(segment)
    is_quality = bool(
        intervals
        or re.search(
            r"controlled fast|5k effort|threshold|marathon effort|time trial|strides?",
            lower,
        )
    )
    is_long = bool(re.search(r"long run", lower))
    distance = extract_distance(segment)
    pace = extract_pace(segment)
    duration = extract_duration(segment) if not distance else None

    if is_quality:
        name = "Quality run"
    elif is_long:
        name = "Long run"
    elif re.search(r"easy run|conversational", lower):
        name = "Easy run"
    elif re.search(r"\brun\b|\bjog\b", lower):
        name = "Run"
    else:
        name = segment[:40] + ("…" if len(segment) > 40 else "")

    metrics = []
    if distance:
        metrics.append("DISTANCE")
    if pace or name in ("Easy run", "Long run", "Quality run", "Run"):
        metrics.append("PACE")
    if duration or intervals:
        metrics.append("DURATION")
    if intervals or sets_reps:
        metrics.append("SETS")
    metrics.append("NOTES")

    return {
        "name": name,
        "prescription": segment,
        "distance": distance,
        "pace": pace,
        "duration": duration,
        "intervals": intervals,
        "targetWeight": None,
        "setsReps": sets_reps,
        "rest": recovery,
        "metrics": metrics,
    }


def structure_session(session: dict) -> dict:
    original = session["exercises"][0]["prescription"] if session.get("exercises") else ""
    segments = split_segments(original)
    exercises = [parse_segment(seg) for seg in segments] or [
        parse_segment(original or session.get("sessionLabel", "Session"))
    ]
    primary = next(
        (e for e in exercises if e["name"] not in ("Mobility", "Strength A", "Strength B")),
        exercises[0],
    )
    return {
        **session,
        "sessionLabel": primary["name"],
        "exercises": exercises,
    }


def main() -> None:
    data = json.loads(PATH.read_text())
    for week in data["weeks"]:
        week["sessions"] = [structure_session(s) for s in week["sessions"]]
    PATH.write_text(json.dumps(data, indent=2) + "\n")
    sample = data["weeks"][0]["sessions"][2]["exercises"]
    print(f"Wrote {PATH}")
    print("Week1 Day3 sample:")
    print(json.dumps(sample, indent=2))


if __name__ == "__main__":
    main()
