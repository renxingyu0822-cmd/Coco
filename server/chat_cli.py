# Tiny terminal chat with Coco, for testing. Talks to the running server like the app will.
# Run: .venv/bin/python chat_cli.py      (server must be running)

import json
import urllib.request

URL = "http://localhost:8000/chat"
messages = []  # the whole conversation, sent every time (server has no memory yet)

print("Chat with Coco. Type 'quit' to stop.\n")

while True:
    text = input("You:  ").strip()
    if text.lower() in ("quit", "exit"):
        break
    if not text:
        continue

    messages.append({"role": "user", "content": text})
    req = urllib.request.Request(
        URL,
        data=json.dumps({"messages": messages}).encode(),
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req) as resp:
            reply = json.load(resp)["reply"]
    except Exception as e:
        print("(couldn't reach Coco:", e, ")\n")
        messages.pop()  # drop the message that failed, so you can just retry
        continue

    messages.append({"role": "assistant", "content": reply})
    print("Coco:", reply, "\n")
