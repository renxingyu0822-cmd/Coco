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
#
# Started by: uvicorn app.main:app  (see coco.sh / README)
#   "app.main" = this file, ":app" = the `app` variable below.
# ─────────────────────────────────────────────────────────────

from fastapi import FastAPI

from . import chat, voice          # the "." means: from this same folder (app/)
from .settings import MODEL

# the server itself
app = FastAPI(title="Coco")

# plug in the endpoints that live in other files
app.include_router(chat.router)   # adds /chat
app.include_router(voice.router)  # adds /speak


# "are you alive?" check. Cheap: no OpenAI call, costs nothing.
# Used by coco.sh to see if the server runs, and handy in a browser.
@app.get("/health")
def health():
    return {"ok": True, "model": MODEL}
