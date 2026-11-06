#!/bin/zsh
# "coco" shortcut: start the server if it's not running, then open the terminal chat.

DIR="/Users/dafei/Desktop/Coco/server"
cd "$DIR" || exit 1

if ! curl -s localhost:8000/health > /dev/null; then
  echo "Starting Coco's server... (log: server/server.log)"
  nohup .venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --reload > server.log 2>&1 &

  # wait up to ~10s for it to wake up
  for i in {1..20}; do
    curl -s localhost:8000/health > /dev/null && break
    sleep 0.5
  done
fi

.venv/bin/python chat_cli.py
