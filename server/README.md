# server

Python back end for Coco. Takes the chat history from the app, adds Coco's personality prompt
(`prompt.py`), asks the OpenAI API and returns the reply. The API key lives only here, in `.env` (never committed).

## Setup (once)
```
cd server
python3.12 -m venv .venv
.venv/bin/pip install -r requirements.txt
cp .env.example .env      # then put your OpenAI key in .env
```

## Run
```
.venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```
`--host 0.0.0.0` makes it reachable from the iPhone on the same Wi-Fi.

## Endpoints
- `GET /health` → `{"ok": true, "model": "..."}`
- `POST /chat` with `{"messages": [{"role": "user", "content": "Hi"}]}` → `{"reply": "..."}`
