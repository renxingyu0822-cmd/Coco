# server

**Quick chat:** type `coco` in any terminal. It starts the server if needed (log in `server.log`)
and opens a terminal chat (`chat_cli.py`). Alias lives in `~/.zshrc` → `server/coco.sh`.

Python back end for Coco. Talks to the OpenAI API, holds the API key (in `.env`, never committed).

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
- `POST /chat` with `{"messages": [{"role": "user", "content": "Hi"}]}` → `{"reply": "..."}`
