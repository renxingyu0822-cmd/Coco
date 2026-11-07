# ─────────────────────────────────────────────────────────────
# settings.py — shared settings for the whole server
#
# What it does:
#   1. Reads server/.env (your secret key + model names)
#   2. Makes ONE connection to OpenAI (`client`) that all other
#      files share, so we don't connect separately everywhere.
#
# Used by: chat.py, voice.py, main.py
# To change a model or voice: edit server/.env, no code change needed.
# ─────────────────────────────────────────────────────────────

import os

from dotenv import load_dotenv
from openai import OpenAI

# .env sits one folder up, in server/ (this file is in server/app/)
load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))

# os.getenv("NAME", "default") = take it from .env, or use the default if missing
MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")              # for chatting
TTS_MODEL = os.getenv("OPENAI_TTS_MODEL", "gpt-4o-mini-tts")  # TTS = text-to-speech
TTS_VOICE = os.getenv("OPENAI_TTS_VOICE", "coral")            # which voice Coco has

# the shared OpenAI connection. It finds OPENAI_API_KEY from .env by itself.
client = OpenAI()
