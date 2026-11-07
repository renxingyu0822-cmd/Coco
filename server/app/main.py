# Coco back end: the "menu". Creates the server and plugs in the parts.
# The real work lives in chat.py (talking) and voice.py (speaking/listening).

from fastapi import FastAPI

from . import chat, voice
from .settings import MODEL

app = FastAPI(title="Coco")

app.include_router(chat.router)   # /chat
app.include_router(voice.router)  # /speak


# "are you alive?" check
@app.get("/health")
def health():
    return {"ok": True, "model": MODEL}
