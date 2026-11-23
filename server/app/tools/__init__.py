# ─────────────────────────────────────────────────────────────
# tools/ — things Coco can DO or LOOK UP (not just talk)
#
# The model never runs a tool itself. It asks "please call get_weather(place=...)",
# chat.py runs our function here and gives the model the result.
# A tool can only do what we programmed. New tool = new file + add it below.
# ─────────────────────────────────────────────────────────────

import json

from . import weather

# what the model sees (name, what it's for, inputs)
SCHEMAS = [weather.SCHEMA]

# name -> our Python function
FUNCTIONS = {
    "get_weather": weather.get_weather,
}


def run(name: str, arguments: str) -> dict:
    """run one tool call from the model, always returns a dict (errors as {"error": ...})"""
    try:
        args = json.loads(arguments or "{}")
        result = FUNCTIONS[name](**args)
    except Exception as e:   # unknown tool, wrong inputs, ...
        result = {"error": f"Tool {name} failed: {e}"}
    print(f"tool: {name}({arguments}) -> {json.dumps(result)[:300]}")  # handy in server.log
    return result


def card(name: str, result: dict) -> dict | None:
    """a picture for the app (e.g. the weather card), built from the REAL tool result,
    never from the model's words. None = no card (errors, tools without a card)"""
    if name == "get_weather" and "error" not in result:
        return {"type": "weather", **result}
    return None
