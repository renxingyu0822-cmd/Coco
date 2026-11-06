# Coco back end: one chat endpoint, no memory yet.
# The app sends the whole conversation, we add Coco's prompt and ask OpenAI.

import os

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from openai import OpenAI
from pydantic import BaseModel

from prompt import SYSTEM_PROMPT

load_dotenv()  # reads server/.env

MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
client = OpenAI()  # picks up OPENAI_API_KEY from the env

app = FastAPI(title="Coco")


class Message(BaseModel):
    role: str  # "user" or "assistant"
    content: str


class ChatRequest(BaseModel):
    messages: list[Message]


class ChatReply(BaseModel):
    reply: str


@app.get("/health")
def health():
    # quick check that the server is up (handy from the iPhone's browser)
    return {"ok": True, "model": MODEL}


@app.post("/chat", response_model=ChatReply)
def chat(req: ChatRequest):
    # only allow user/assistant turns from the app, the system prompt is ours
    history = [m.model_dump() for m in req.messages if m.role in ("user", "assistant")]
    if not history:
        raise HTTPException(400, "no messages")

    try:
        resp = client.chat.completions.create(
            model=MODEL,
            messages=[{"role": "system", "content": SYSTEM_PROMPT}, *history],
        )
    except Exception as e:
        # don't leak details to the app, just log them here
        print("OpenAI error:", e)
        raise HTTPException(502, "Coco can't think right now, try again in a moment.")

    return ChatReply(reply=resp.choices[0].message.content)
