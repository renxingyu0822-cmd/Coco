# server

**Quick chat:** type `coco` in any terminal. It starts the server if needed (log in `server.log`)
and opens a terminal chat (`chat_cli.py`). Alias lives in `~/.zshrc` → `server/coco.sh`.

Python back end for Coco. Talks to the OpenAI API, holds the API key (in `.env`, never committed).

## Files
Server code is in `app/`:
- `app/main.py` — the "menu": creates the server, plugs in the parts, `/health`
- `app/settings.py` — reads `.env`, model names, shared OpenAI connection
- `app/chat.py` — `/chat` (+ who's talking, what Coco calls the user)
- `app/voice.py` — `/speak` + `/transcribe`
- `app/voiceprint.py` — `/voiceprint` (is it the user's voice?)
- `app/prompt.py` — Coco's personality + how her voice should sound

Outside `app/` (not part of the server):
- `chat_cli.py`, `coco.sh` — terminal chat for testing
- `requirements.txt`, `.env.example`, `.env` (your key, git-ignored)
- `requirements-voiceprint-mac.txt` / `-server.txt` — extra packages for voice recognition (big, ~1 GB)
- `deploy/` — setup files for the online server (systemd service, Caddy for HTTPS)
- `data/` — the voice fingerprint (git-ignored, biometric data), `voiceprint_model/` — the downloaded model (git-ignored)

## Setup (once)
```
cd server
python3.12 -m venv .venv
.venv/bin/pip install -r requirements.txt
cp .env.example .env      # then put your OpenAI key in .env
# voice recognition (optional; without it those endpoints answer 503):
.venv/bin/pip install -r requirements-voiceprint-mac.txt     # Intel Mac
# on the Linux server: requirements-voiceprint-server.txt
```
The voice model (85 MB) downloads by itself on first use, then loads offline.

## Run the server by hand
```
cd server
.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
`--host 0.0.0.0` makes it reachable from the iPhone on the same Wi-Fi. Test page: http://localhost:8000/docs

## Endpoints
- `GET /health` → `{"ok": true, "model": "..."}`
- `POST /speak` with `{"text": "Hello"}` → mp3 audio
- `POST /transcribe` with an audio file upload (field `audio`, wav) →
  `{"text": "...", "speaker": "user" | "other" | "unknown", "score": 0.82}`
  (speech-to-text by OpenAI and the voice check run at the same time; "unknown" = no fingerprint, clip under 1 s, …)
- `POST /chat` with `{"messages": [{"role": "user", "content": "Hi", "speaker": "user"}], "user_name": "Margaret", "user_pronouns": "she/her"}`
  → `{"reply": "..."}`. `speaker`, `user_name`, `user_pronouns` are optional.
  "other" messages get a hidden note so Coco treats them as a visitor (rules in `prompt.py`).
- Voiceprint (`app/voiceprint.py`, wav clips): `GET /voiceprint` → `{"enrolled": true}`,
  `POST /voiceprint/enroll` (field `clips`, 2+ files), `POST /voiceprint/check` (field `clip`) →
  `{"score": 0.74, "is_you": true, "threshold": 0.35}`, `DELETE /voiceprint`.
  Needs extra packages: `requirements-voiceprint-mac.txt` (Intel Mac) or `requirements-voiceprint-server.txt` (Linux).

On the online server every endpoint except `/health` needs the app password (header `X-Coco-Key`, see `app/auth.py`).
