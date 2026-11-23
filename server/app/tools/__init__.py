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


def run(name: str, arguments: str) -> str:
    """run one tool call from the model, always return text (JSON) for the model"""
    try:
        args = json.loads(arguments or "{}")
        result = FUNCTIONS[name](**args)
    except Exception as e:   # unknown tool, wrong inputs, ...
        result = {"error": f"Tool {name} failed: {e}"}
    print(f"tool: {name}({arguments}) -> {json.dumps(result)[:300]}")  # handy in server.log
    return json.dumps(result)
