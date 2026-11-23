# ─────────────────────────────────────────────────────────────
# chat.py — Coco's "brain": the /chat endpoint
#
# What it does:
#   The app sends the whole conversation so far. We put Coco's
#   personality (prompt.py) in front, ask OpenAI, and send back
#   Coco's reply as text.
#
#   app sends:  {"messages": [{"role": "user", "content": "Hi", "speaker": "user"}]}
#   app gets:   {"reply": "Hello! How are you today?"}
#   speaker (optional, voice messages only) = who said it, from the voiceprint.
#   We turn it into a short note in front of the text, so Coco can tell
#   the user apart from visitors / the TV (rules: "Who is talking" in prompt.py).
#
# No memory yet: the server forgets everything after each answer,
# that's why the app always sends the full conversation.
# ─────────────────────────────────────────────────────────────

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from .prompt import SYSTEM_PROMPT
from .settings import MODEL, client

# a "router" = a small group of endpoints; main.py plugs it into the server
router = APIRouter()


# ── data shapes ──
# FastAPI checks every request against these. Wrong shape -> rejected
# automatically before our code runs. (Also shown on /docs under "Schemas".)

class Message(BaseModel):
    role: str      # "user" (the older person) or "assistant" (Coco)
    content: str   # the text of the message
    speaker: str | None = None   # voice messages: "user" / "other" / "unknown" (voiceprint). Typed: none


# hidden note in front of voice messages, so Coco knows who's talking (rules in prompt.py).
# typed / "unknown" = no note = the user
SPEAKER_NOTES = {
    "user": "[voice: the user]",
    "other": "[voice: someone else, not the user]",
}


def _for_openai(m: Message) -> dict:
    note = SPEAKER_NOTES.get(m.speaker) if m.role == "user" else None
    content = f"{note} {m.content}" if note else m.content
    return {"role": m.role, "content": content}   # OpenAI only gets role + content


class ChatRequest(BaseModel):   # what the app sends
    messages: list[Message]


class ChatReply(BaseModel):     # what we send back
    reply: str


# ── the endpoint ──
@router.post("/chat", response_model=ChatReply)
def chat(req: ChatRequest):
    # keep only user/assistant turns, so the app can't sneak in its own rules
    # (only our prompt.py may set the "system" instructions)
    history = [_for_openai(m) for m in req.messages if m.role in ("user", "assistant")]
    if not history:
        raise HTTPException(400, "no messages")   # 400 = "your request is wrong"

    try:
        # ask OpenAI: personality first, then the conversation
        resp = client.chat.completions.create(
            model=MODEL,
            messages=[{"role": "system", "content": SYSTEM_PROMPT}, *history],
        )
    except Exception as e:
        # friendly message for the app, real error printed in the terminal / server.log
        print("OpenAI error:", e)
        raise HTTPException(502, "Coco can't think right now, try again in a moment.")
        # 502 = "a service behind me (OpenAI) failed"

    # OpenAI can give several answers ("choices"); we only ask for one, take the first
    return ChatReply(reply=resp.choices[0].message.content)
