# Voice: /speak (text -> Coco's voice). /transcribe (voice -> text) comes next.

from fastapi import APIRouter, HTTPException, Response
from pydantic import BaseModel

from .prompt import VOICE_INSTRUCTIONS
from .settings import TTS_MODEL, TTS_VOICE, client

router = APIRouter()


class SpeakRequest(BaseModel):
    text: str
    voice: str | None = None  # optional, to try other voices; default from .env


@router.post("/speak")
def speak(req: SpeakRequest):
    if not req.text.strip():
        raise HTTPException(400, "no text")
    try:
        audio = client.audio.speech.create(
            model=TTS_MODEL,
            voice=req.voice or TTS_VOICE,
            input=req.text,
            instructions=VOICE_INSTRUCTIONS,
            response_format="mp3",
        )
    except Exception as e:
        print("OpenAI TTS error:", e)
        raise HTTPException(502, "Coco can't speak right now.")
    return Response(content=audio.content, media_type="audio/mpeg")
