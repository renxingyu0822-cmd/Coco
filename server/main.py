# Coco back end: one chat endpoint, no memory yet.
# The app sends the whole conversation, we put Coco's prompt in front and ask OpenAI.

import os

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from openai import OpenAI
from pydantic import BaseModel

from prompt import SYSTEM_PROMPT

# 1) settings from server/.env
load_dotenv()
MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
client = OpenAI()  # picks up OPENAI_API_KEY by itself

app = FastAPI(title="Coco")


# shape of the data going in and out
class Message(BaseModel):
    role: str  # "user" or "assistant"
    content: str


class ChatRequest(BaseModel):
    messages: list[Message]


class ChatReply(BaseModel):
    reply: str


# 2) "are you alive?" check
@app.get("/health")
def health():
    return {"ok": True, "model": MODEL}


# 3) the main thing: conversation in, Coco's reply out
@app.post("/chat", response_model=ChatReply)
def chat(req: ChatRequest):
    # keep only user/assistant turns, so the app can't sneak in its own rules
    history = [m.model_dump() for m in req.messages if m.role in ("user", "assistant")]
    if not history:
        raise HTTPException(400, "no messages")

    try:
        resp = client.chat.completions.create(
            model=MODEL,
            messages=[{"role": "system", "content": SYSTEM_PROMPT}, *history],
        )
    except Exception as e:
        # 4) friendly message for the app, real error in the terminal
        print("OpenAI error:", e)
        raise HTTPException(502, "Coco can't think right now, try again in a moment.")

    return ChatReply(reply=resp.choices[0].message.content)
