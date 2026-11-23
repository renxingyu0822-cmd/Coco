# ─────────────────────────────────────────────────────────────
# tools/weather.py — Coco's first tool: the weather
#
# get_weather("Hannover", "tomorrow") -> short facts in plain words, e.g.
#   {"place": "Hanover, Lower Saxony, Germany", "day": "tomorrow, Tuesday 24 November",
#    "weather": "overcast", "low_c": -1.0, "high_c": 2.9, "chance_of_rain_percent": 0, ...}
#
# Data: Open-Meteo (open-meteo.com), free for non-commercial use, no key needed.
#   Licence CC-BY 4.0 -> we must credit "Weather data by Open-Meteo.com" (README + app).
#   Works the same for China and Germany (our tool rule).
# Two steps: 1. place name -> coordinates (geocoding)  2. coordinates -> forecast
#
# Never raises: if something goes wrong it returns {"error": "..."} and Coco must say
# she can't check the weather (not guess!). WEATHER_TOOL_DOWN=1 in .env fakes an outage
# (for testing / the "broken twin" evaluation tasks).
# ─────────────────────────────────────────────────────────────

import json
import os
import ssl
import urllib.parse
import urllib.request
from datetime import date, timedelta

GEOCODE_URL = "https://geocoding-api.open-meteo.com/v1/search"
FORECAST_URL = "https://api.open-meteo.com/v1/forecast"
TIMEOUT = 8  # seconds; Coco shouldn't hang on a slow weather service

# Open-Meteo sends a number (WMO weather code) instead of words
WEATHER_WORDS = {
    0: "clear sky", 1: "mainly clear", 2: "partly cloudy", 3: "overcast",
    45: "fog", 48: "icy fog",
    51: "light drizzle", 53: "drizzle", 55: "heavy drizzle",
    56: "freezing drizzle", 57: "heavy freezing drizzle",
    61: "light rain", 63: "rain", 65: "heavy rain",
    66: "freezing rain", 67: "heavy freezing rain",
    71: "light snow", 73: "snow", 75: "heavy snow", 77: "snow grains",
    80: "light rain showers", 81: "rain showers", 82: "heavy rain showers",
    85: "light snow showers", 86: "heavy snow showers",
    95: "thunderstorm", 96: "thunderstorm with hail", 99: "thunderstorm with heavy hail",
}
WEEKDAYS = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

# what the model sees: when to use the tool and what to fill in
SCHEMA = {
    "type": "function",
    "function": {
        "name": "get_weather",
        "description": "Get the weather forecast for a town or city (today up to 6 days ahead). "
                       "Use it whenever the person asks about the weather, rain, temperature, "
                       "or what to wear outside.",
        "parameters": {
            "type": "object",
            "properties": {
                "place": {
                    "type": "string",
                    "description": "Town or city in English, optionally with region or country, "
                                   "e.g. 'Hannover', 'Beijing', 'Springfield, Illinois'.",
                },
                "day": {
                    "type": "string",
                    "description": "'today', 'tomorrow', a weekday like 'friday', or a date 'YYYY-MM-DD'. "
                                   "Default 'today'.",
                },
            },
            "required": ["place"],
        },
    },
}


# use the computer's own list of trusted certificates (the Mac's Python can't find one by itself
# -> "CERTIFICATE_VERIFY_FAILED"). truststore comes with the openai package, on Mac and server
try:
    import truststore
    _SSL = truststore.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
except ImportError:
    _SSL = None   # default, fine on Linux


def _get(url: str, params: dict) -> dict:
    with urllib.request.urlopen(f"{url}?{urllib.parse.urlencode(params)}", timeout=TIMEOUT, context=_SSL) as r:
        return json.load(r)


def _find_place(place: str) -> dict:
    """'Springfield, Illinois' -> best match, or {"ambiguous": [...]} / {"error": ...}"""
    name, _, hint = place.partition(",")      # "Springfield", "Illinois"
    name, hint = name.strip(), hint.strip().lower()
    results = _get(GEOCODE_URL, {"name": name, "count": 10, "language": "en", "format": "json"}).get("results") or []

    if hint:  # keep only matches in that region / country
        results = [r for r in results
                   if hint in (r.get("admin1") or "").lower()
                   or hint in (r.get("country") or "").lower()
                   or hint == (r.get("country_code") or "").lower()]
    if not results:
        return {"error": f"I couldn't find a place called '{place}'."}

    # several real towns of similar size with that name (Springfield!) -> ask, don't guess.
    # small villages (no population) don't count against a big city (Hannover, Germany wins)
    first, second = results[0], (results[1] if len(results) > 1 else None)
    if not hint and second and (second.get("population") or 0) >= 0.3 * (first.get("population") or 1):
        options = [", ".join(x for x in (r["name"], r.get("admin1"), r.get("country")) if x) for r in results[:4]]
        return {"ambiguous": options}
    return first


def _pick_day(day: str, local_today: date) -> date | None:
    day = (day or "today").strip().lower()
    if day == "today":
        return local_today
    if day == "tomorrow":
        return local_today + timedelta(days=1)
    if day in WEEKDAYS:  # the next one (today counts)
        return local_today + timedelta(days=(WEEKDAYS.index(day) - local_today.weekday()) % 7)
    try:
        return date.fromisoformat(day)
    except ValueError:
        return None


def get_weather(place: str, day: str = "today") -> dict:
    if os.getenv("WEATHER_TOOL_DOWN") == "1":
        return {"error": "The weather service isn't answering right now."}
    try:
        where = _find_place(place)
        if "error" in where:
            return where
        if "ambiguous" in where:
            return {"error": "There are several places with that name. Ask which one is meant.",
                    "options": where["ambiguous"]}

        d = _get(FORECAST_URL, {
            "latitude": where["latitude"], "longitude": where["longitude"],
            "timezone": "auto", "forecast_days": 7,   # auto = the place's own local time
            "current": "temperature_2m,apparent_temperature,weather_code,wind_speed_10m,is_day",
            "daily": "weather_code,temperature_2m_max,temperature_2m_min,"
                     "precipitation_probability_max,precipitation_sum,wind_speed_10m_max",
        })
        local_now = d["current"]["time"]                    # "2026-11-23T23:15", the place's local time
        today = date.fromisoformat(local_now[:10])
        wanted = _pick_day(day, today)
        days = d["daily"]["time"]
        if wanted is None or wanted.isoformat() not in days:
            return {"error": f"I only have the forecast from {days[0]} to {days[-1]}."}
        i = days.index(wanted.isoformat())
        daily = d["daily"]

        label = wanted.strftime("%A %-d %B")
        if wanted == today:
            label = "today, " + label
        elif wanted == today + timedelta(days=1):
            label = "tomorrow, " + label

        result = {
            "place": ", ".join(x for x in (where["name"], where.get("admin1"), where.get("country")) if x),
            "city": where["name"], "country": where.get("country", ""),   # short, for the app's card
            "local_time_there": local_now.replace("T", " "),
            "day": label,
            "weather": WEATHER_WORDS.get(daily["weather_code"][i], "unknown"),
            "code": daily["weather_code"][i],   # the app picks the picture from it
            "low_c": daily["temperature_2m_min"][i],
            "high_c": daily["temperature_2m_max"][i],
            "chance_of_rain_percent": daily["precipitation_probability_max"][i],
            "rain_mm": daily["precipitation_sum"][i],
            "max_wind_kmh": daily["wind_speed_10m_max"][i],
        }
        if wanted == today:  # right now, too
            c = d["current"]
            result["now"] = {"temperature_c": c["temperature_2m"], "feels_like_c": c["apparent_temperature"],
                             "weather": WEATHER_WORDS.get(c["weather_code"], "unknown"),
                             "wind_kmh": c["wind_speed_10m"],
                             "code": c["weather_code"], "is_day": c["is_day"] == 1}
        return result
    except Exception as e:
        print("weather tool error:", e)
        return {"error": "The weather service isn't answering right now."}
