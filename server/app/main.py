# ─────────────────────────────────────────────────────────────
# main.py — the server's "menu"
#
# What it does:
#   Creates the server and plugs in all the parts. It holds no real
#   logic itself, it just says which address goes to which file.
#
#   GET  /health  -> here       ("are you alive?")
#   POST /chat    -> chat.py    (text in, Coco's reply out)
#   POST /speak   -> voice.py   (text in, Coco's voice out)
#   POST /transcribe -> voice.py (your voice in, text out)
#
# Started by: uvicorn app.main:app  (see coco.sh / README)
#   "app.main" = this file, ":app" = the `app` variable below.
# ─────────────────────────────────────────────────────────────

from fastapi import Depends, FastAPI

from . import chat, voice          # the "." means: from this same folder (app/)
from .auth import check_password
from .settings import MODEL

# the server itself
app = FastAPI(title="Coco")

# plug in the endpoints that live in other files.
# Depends(check_password) = run the password check (auth.py) before each of them
locked = [Depends(check_password)]
app.include_router(chat.router, dependencies=locked)   # adds /chat
app.include_router(voice.router, dependencies=locked)  # adds /speak + /transcribe


# "are you alive?" check. Cheap: no OpenAI call, costs nothing.
# Used by coco.sh to see if the server runs, and handy in a browser.
@app.get("/health")
def health():
    return {"ok": True, "model": MODEL}
