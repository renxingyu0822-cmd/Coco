# ─────────────────────────────────────────────────────────────
# voice.py — Coco's "mouth" (and soon "ears")
#
# What it does:
#   POST /speak       text in -> Coco's voice out (an mp3 file)
#   POST /transcribe  your voice in (an audio file) -> text out
#
#   /speak       app sends {"text": "Hello!"}       -> gets mp3 audio, plays it
#   /transcribe  app uploads the recording (m4a)    -> gets {"text": "Hi Coco..."}
#
# How Coco should sound (warm, calm, a bit slow) is set in prompt.py
# (VOICE_INSTRUCTIONS). Which voice: OPENAI_TTS_VOICE in .env.
# ─────────────────────────────────────────────────────────────

from fastapi import APIRouter, File, HTTPException, Response, UploadFile
from pydantic import BaseModel

from .prompt import VOICE_INSTRUCTIONS
from .settings import STT_LANGUAGE, STT_MODEL, TTS_MODEL, TTS_VOICE, client

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


# ── /transcribe: your voice -> text ──
# The app uploads the recording as a file (that's what python-multipart is for).
@router.post("/transcribe")
async def transcribe(audio: UploadFile = File(...)):
    data = await audio.read()
    if not data:
        raise HTTPException(400, "empty recording")

    try:
        result = client.audio.transcriptions.create(
            model=STT_MODEL,
            # OpenAI wants (filename, bytes, type); the name's ending tells it the format (.m4a)
            file=(audio.filename or "recording.m4a", data, audio.content_type or "audio/m4a"),
            language=STT_LANGUAGE,  # "en": don't guess the language (see settings.py)
        )
    except Exception as e:
        print("OpenAI transcribe error:", e)
        raise HTTPException(502, "Coco couldn't understand the recording.")

    return {"text": result.text.strip()}
