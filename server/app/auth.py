# ─────────────────────────────────────────────────────────────
# auth.py — the password between the app and the server
#
# What it does:
#   Every request to /chat, /speak, /transcribe must carry the header
#     X-Coco-Key: <password>
#   Wrong or missing -> 401 ("who are you?"), OpenAI is never called.
#   So strangers who find the server's address can't use Coco
#   (= can't spend our OpenAI money).
#
# Where the password lives:
#   server: COCO_APP_PASSWORD in server/.env
#   app:    ios/Coco/Secrets.swift (git-ignored)
#
# No COCO_APP_PASSWORD in .env (= the Mac while coding) -> no check,
# everything works like before.
#
# /health has no check on purpose: it's cheap and tells nothing secret.
# ─────────────────────────────────────────────────────────────

import secrets

from fastapi import Header, HTTPException

from .settings import APP_PASSWORD


def check_password(x_coco_key: str = Header(default="")):
    # FastAPI fills x_coco_key from the "X-Coco-Key" header by itself
    if not APP_PASSWORD:
        return  # no password set -> local dev, let it through
    # compare_digest = safe compare (takes the same time whether it's almost right or totally wrong)
    if not secrets.compare_digest(x_coco_key, APP_PASSWORD):
        raise HTTPException(401, "wrong or missing app password")
