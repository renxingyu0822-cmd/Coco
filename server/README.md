# server

**Quick chat:** type `coco` in any terminal. It starts the server if needed (log in `server.log`)
and opens a terminal chat (`chat_cli.py`). Alias lives in `~/.zshrc` → `server/coco.sh`.

Python back end for Coco. Talks to the OpenAI API, holds the API key (in `.env`, never committed).

## Files
Server code is in `app/`:
- `app/main.py` — the "menu": creates the server, plugs in the parts, `/health`
- `app/settings.py` — reads `.env`, model names, shared OpenAI connection
- `app/chat.py` — `/chat`
- `app/voice.py` — `/speak` + `/transcribe`
- `app/prompt.py` — Coco's personality + how her voice should sound

Outside `app/` (not part of the server):
- `chat_cli.py`, `coco.sh` — terminal chat for testing
- `requirements.txt`, `.env.example`, `.env` (your key, git-ignored)

## Setup (once)
```
cd server
python3.12 -m venv .venv
.venv/bin/pip install -r requirements.txt
cp .env.example .env      # then put your OpenAI key in .env
```

## Run the server by hand
```
cd server
.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
`--host 0.0.0.0` makes it reachable from the iPhone on the same Wi-Fi. Test page: http://localhost:8000/docs

## Endpoints
- `GET /health` → `{"ok": true, "model": "..."}`
- `POST /speak` with `{"text": "Hello"}` → mp3 audio
- `POST /transcribe` with an audio file upload (field `audio`, e.g. m4a) → `{"text": "..."}`
- `POST /chat` with `{"messages": [{"role": "user", "content": "Hi"}]}` → `{"reply": "..."}`
