# server

**Quick chat:** type `coco` in any terminal. It starts the server if needed (log in `server.log`)
and opens a terminal chat (`chat_cli.py`). Alias lives in `~/.zshrc` → `server/coco.sh`.

Python back end for Coco. Talks to the OpenAI API, holds the API key (in `.env`, never committed).

## Files
- `main.py` — the "menu": creates the server, plugs in the parts, `/health`
- `settings.py` — reads `.env`, model names, shared OpenAI connection
- `chat.py` — `/chat`
- `voice.py` — `/speak` (and `/transcribe` next)
- `prompt.py` — Coco's personality + how her voice should sound
- `chat_cli.py`, `coco.sh` — terminal chat for testing (not part of the server)

## Setup (once)
```
cd server
python3.12 -m venv .venv
.venv/bin/pip install -r requirements.txt
cp .env.example .env      # then put your OpenAI key in .env
```

## Run the server by hand
```
.venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```
`--host 0.0.0.0` makes it reachable from the iPhone on the same Wi-Fi. Test page: http://localhost:8000/docs

## Endpoints
- `GET /health` → `{"ok": true, "model": "..."}`
- `POST /speak` with `{"text": "Hello"}` → mp3 audio
- `POST /chat` with `{"messages": [{"role": "user", "content": "Hi"}]}` → `{"reply": "..."}`
