import re
from typing import Dict


CATEGORY_KEYWORDS = {
    "Electrical": ["light", "bulb", "switch", "socket", "power", "electric", "fan", "tube light", "wiring", "circuit"],
    "Plumbing": ["water", "pipe", "leak", "tap", "drain", "toilet", "plumbing", "sink", "sewer"],
    "Wi-Fi": ["wifi", "wi-fi", "internet", "network", "router", "connectivity", "signal"],
    "Classroom": ["classroom", "chair", "bench", "table", "blackboard", "whiteboard", "room"],
    "Laboratory": ["lab", "experiment", "equipment", "microscope", "computer lab", "laboratory"],
    "Computer": ["computer", "monitor", "keyboard", "mouse", "pc", "laptop", "desktop", "system"],
    "Sanitation": ["clean", "dirty", "washroom", "toilet", "garbage", "sanitation", "bathroom", "restroom"],
    "Infrastructure": ["floor", "wall", "gate", "window", "roof", "door", "building", "parking", "structure"],
}

PRIORITY_KEYWORDS = {
    "Emergency": ["fire", "gas", "electric shock", "flood", "urgent", "emergency"],
    "High": ["leak", "not working", "broken", "danger", "no internet", "drainage", "water", "power outage"],
    "Medium": ["fault", "issue", "some", "not responding", "poor", "slow"],
    "Low": ["minor", "small", "cleaning", "light", "chair", "dust"],
}


def normalize_text(text: str) -> str:
    return re.sub(r"\s+", " ", text.lower()).strip()


def classify_category(description: str) -> str:
    text = normalize_text(description)
    scores = {category: 0 for category in CATEGORY_KEYWORDS}

    for category, keywords in CATEGORY_KEYWORDS.items():
        for kw in keywords:
            if kw in text:
                scores[category] += 2

    if not any(scores.values()):
        return "Other"

    best_category = max(scores, key=scores.get)
    return best_category


def classify_priority(description: str) -> str:
    text = normalize_text(description)
    scores = {level: 0 for level in PRIORITY_KEYWORDS}

    for level, keywords in PRIORITY_KEYWORDS.items():
        for kw in keywords:
            if kw in text:
                scores[level] += 2

    if not any(scores.values()):
        return "Medium"

    best_priority = max(scores, key=scores.get)
    return best_priority


def analyze_complaint(description: str) -> Dict[str, object]:
    category = classify_category(description)
    priority = classify_priority(description)
    confidence = 0.88 if category != "Other" else 0.55

    return {
        "category": category,
        "priority": priority,
        "confidence": round(confidence, 2),
    }
