# ─────────────────────────────────────────────────────────────
# voice.py — Coco's "mouth" (and soon "ears")
#
# What it does:
#   POST /speak       text in -> Coco's voice out (an mp3 file)
#   POST /transcribe  (coming next) your voice in -> text out
#
#   app sends:  {"text": "Hello! How are you?"}
#   app gets:   mp3 audio, the app plays it
#
# How Coco should sound (warm, calm, a bit slow) is set in prompt.py
# (VOICE_INSTRUCTIONS). Which voice: OPENAI_TTS_VOICE in .env.
# ─────────────────────────────────────────────────────────────

from fastapi import APIRouter, HTTPException, Response
from pydantic import BaseModel

from .prompt import VOICE_INSTRUCTIONS
from .settings import TTS_MODEL, TTS_VOICE, client

# a "router" = a small group of endpoints; main.py plugs it into the server
router = APIRouter()


# what the app sends to /speak
class SpeakRequest(BaseModel):
    text: str                 # what Coco should say
    voice: str | None = None  # optional: try another voice ("sage", ...). Empty = default from .env


@router.post("/speak")
def speak(req: SpeakRequest):
    if not req.text.strip():
        raise HTTPException(400, "no text")   # nothing to say

    try:
        # ask OpenAI to turn the text into speech
        audio = client.audio.speech.create(
            model=TTS_MODEL,
            voice=req.voice or TTS_VOICE,     # "or" = use the default if none was given
            input=req.text,
            instructions=VOICE_INSTRUCTIONS,  # tone of voice, from prompt.py
            response_format="mp3",
        )
    except Exception as e:
        print("OpenAI TTS error:", e)         # details for us in server.log
        raise HTTPException(502, "Coco can't speak right now.")

    # send the raw audio back. "audio/mpeg" tells the app: this is an mp3
    return Response(content=audio.content, media_type="audio/mpeg")
