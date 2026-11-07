# /chat: conversation in, Coco's reply out.

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from .prompt import SYSTEM_PROMPT
from .settings import MODEL, client

router = APIRouter()


# shape of the data going in and out
class Message(BaseModel):
    role: str  # "user" or "assistant"
    content: str


class ChatRequest(BaseModel):
    messages: list[Message]


class ChatReply(BaseModel):
    reply: str


@router.post("/chat", response_model=ChatReply)
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
        # friendly message for the app, real error in the terminal
        print("OpenAI error:", e)
        raise HTTPException(502, "Coco can't think right now, try again in a moment.")

    return ChatReply(reply=resp.choices[0].message.content)
