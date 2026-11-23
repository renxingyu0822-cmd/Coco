# ─────────────────────────────────────────────────────────────
# tools/clock.py — what time is it?
#
# Two parts:
#   now_line(tz)       -> "It is now Tuesday 24 November 2026, 14:05 ..." for the system prompt.
#                         The model has no clock, so we tell it with EVERY message (no extra round trip).
#                         tz = the phone's time zone ("Europe/Berlin"), sent by the app.
#   get_time("Beijing") -> the time somewhere else (tool). Reuses the weather tool's place lookup
#                         (Open-Meteo knows each town's time zone).
# ─────────────────────────────────────────────────────────────

from datetime import datetime
from zoneinfo import ZoneInfo

from .weather import _find_place   # same place lookup as the weather (Springfield -> ask)

SCHEMA = {
    "type": "function",
    "function": {
        "name": "get_time",
        "description": "Get the current local time and date in another town or city "
                       "(e.g. where a family member lives). Not needed for the person's own time, "
                       "you already know that.",
        "parameters": {
            "type": "object",
            "properties": {
                "place": {"type": "string",
                          "description": "Town or city in English, optionally with region or country."},
            },
            "required": ["place"],
        },
    },
}


def _zone(tz: str | None) -> ZoneInfo | None:
    try:
        return ZoneInfo(tz) if tz else None
    except Exception:          # nonsense / unknown time zone name
        return None


def _say(t: datetime) -> dict:
    return {
        "weekday": t.strftime("%A"),
        "date": t.strftime("%-d %B %Y"),
        "time_24h": t.strftime("%H:%M"),
        "time_12h": t.strftime("%-I:%M %p").lower(),
    }


def now_line(tz: str | None) -> str:
    """one line for the system prompt. Unknown time zone -> say so, so the model doesn't pretend"""
    zone = _zone(tz)
    if zone is None:
        return ("\n\nThe current time: unknown (the app didn't send the time zone). "
                "If someone asks the time or date, say you can't see it right now.")
    t = datetime.now(zone)
    return (f"\n\nRight now it is {t.strftime('%A %-d %B %Y, %H:%M')} "
            f"(the local time of the person you look after, time zone {tz}).")


def get_time(place: str) -> dict:
    try:
        where = _find_place(place)
    except Exception as e:
        print("clock tool error:", e)
        return {"error": "I can't look up that place right now."}
    if "error" in where:
        return where
    if "ambiguous" in where:
        return {"error": "There are several places with that name. Ask which one is meant.",
                "options": where["ambiguous"]}
    zone = _zone(where.get("timezone"))
    if zone is None:
        return {"error": f"I don't know the time zone of {place}."}
    return {"place": ", ".join(x for x in (where["name"], where.get("admin1"), where.get("country")) if x),
            "time_zone": where["timezone"], **_say(datetime.now(zone))}
