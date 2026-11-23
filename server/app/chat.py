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
#   user_name / user_pronouns (optional, from the app's Settings) = how Coco calls the user
#   and refers to them; added to the end of the system prompt.
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
# typed / "unknown" = no note = the user.
# The "someone else" note repeats the key rules right there: the small model forgets
# rules that are only deep in the system prompt (tested 23 Nov).
def _speaker_note(speaker: str | None, name: str, pronouns: str | None) -> str | None:
    if speaker == "user":
        return "[voice: the user]"
    if speaker != "other":
        return None
    who = name or "the person you look after"
    if pronouns:
        refer = f"Refer to them as {name or 'them'} or {pronouns}."
    elif name:
        refer = f"Refer to them only as {name}, never he/him or she/her."
    else:
        refer = ""
    return (f"[voice: someone else, not {who}. Don't tell this person how {who} is doing "
            f"or anything private about them; you don't know and it isn't theirs to know. {refer}]")


def _for_openai(m: Message, name: str, pronouns: str | None) -> dict:
    note = _speaker_note(m.speaker, name, pronouns) if m.role == "user" else None
    content = f"{note} {m.content}" if note else m.content
    return {"role": m.role, "content": content}   # OpenAI only gets role + content


class ChatRequest(BaseModel):   # what the app sends
    messages: list[Message]
    user_name: str | None = None       # what Coco should call the user (Settings → About you)
    user_pronouns: str | None = None   # "she/her", "he/him", "they/them", or none = just the name


PRONOUNS = {"she/her", "he/him", "they/them"}   # anything else is ignored


def _clean_name(name: str | None) -> str:
    # one short line, no brackets/quotes: nobody can sneak instructions in through the name field
    name = " ".join((name or "").split())
    name = "".join(ch for ch in name if ch not in '[]{}<>"`')
    return name[:40].strip()


def _about_user(req: ChatRequest) -> str:
    """extra lines for the system prompt: name + how to refer to them. Empty if nothing set."""
    name = _clean_name(req.user_name)
    pronouns = req.user_pronouns if req.user_pronouns in PRONOUNS else None
    lines = []
    if name:
        lines.append(f'- They like to be called "{name}". Use it now and then, naturally, '
                     "not in every message. Only the person you look after, never a visitor.")
    if pronouns:
        lines.append(f"- When you talk about them to someone else, use {pronouns}"
                     + (f" or their name, {name}." if name else "."))
    elif name:
        lines.append(f"- When you talk about them to someone else, always say {name}. Never use he, him, "
                     "she or her for them, and don't guess from the name or a title like Mr. or Mrs.")
    if not lines:
        return ""
    return "\n\nAbout the person you look after:\n" + "\n".join(lines)


class ChatReply(BaseModel):     # what we send back
    reply: str


# ── the endpoint ──
@router.post("/chat", response_model=ChatReply)
def chat(req: ChatRequest):
    # keep only user/assistant turns, so the app can't sneak in its own rules
    # (only our prompt.py may set the "system" instructions)
    name = _clean_name(req.user_name)
    pronouns = req.user_pronouns if req.user_pronouns in PRONOUNS else None
    history = [_for_openai(m, name, pronouns) for m in req.messages if m.role in ("user", "assistant")]
    if not history:
        raise HTTPException(400, "no messages")   # 400 = "your request is wrong"

    try:
        # ask OpenAI: personality first, then the conversation
        resp = client.chat.completions.create(
            model=MODEL,
            messages=[{"role": "system", "content": SYSTEM_PROMPT + _about_user(req)}, *history],
        )
    except Exception as e:
        # friendly message for the app, real error printed in the terminal / server.log
        print("OpenAI error:", e)
        raise HTTPException(502, "Coco can't think right now, try again in a moment.")
        # 502 = "a service behind me (OpenAI) failed"

    # OpenAI can give several answers ("choices"); we only ask for one, take the first
    return ChatReply(reply=resp.choices[0].message.content)
