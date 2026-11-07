# Coco — working diary

Newest entry on top. Short entries: what we did, what we found, decisions, corrections, next.
Public repo: no personal data here.

---

## 2026-11-07
**Did:**
- iOS chat screen (`ContentView.swift`): title, bubbles (Coco left, user right), big text field + send button,
  large text, auto-scroll to newest message, Coco greets first.
- Connected the app to the server: `ChatService.swift` packs the conversation as JSON → `POST /chat` → reads the reply.
  "Coco is thinking…" bubble, send button off while waiting, friendly error message if the server can't be reached.
  `Coco-Info.plist` allows plain http on the local network only (internet stays https).
- Tested in Xcode's live Preview: real replies from Coco, she remembers the conversation.
- **Coco runs on the iPhone** (iOS 26.6.1) over home Wi-Fi, installed from Xcode by cable.
  Setup done once: trust computer, Developer Mode, trust developer app in VPN & Device Management, allow local network.

**Big picture (how one message travels):**
```
You type "Hi"
   ↓
ContentView: shows your bubble + "Coco is thinking…"
   ↓
ChatService: packs the conversation as JSON, sends it to http://localhost:8000/chat
   ↓
Server (main.py): adds Coco's personality (prompt.py), asks OpenAI
   ↓
ChatService: unpacks {"reply": "..."} and hands back the text
   ↓
ContentView: removes "thinking", shows Coco's bubble
```
Same thing `chat_cli.py` does in the terminal, just in Swift with a screen.

**Found:**
- Two Xcodes: the one in use is 26.3 in `~/Downloads`; `/Applications` has an old 13.4.1 that the terminal points to.
  Terminal builds work by pointing at the new one (`DEVELOPER_DIR`), no system change.
- The Simulator app renders blank on this Intel Mac (even Apple's Settings app) → use Xcode's Preview instead.
  Simulator as presentation backup is still open.
- A stray copy of `Coco.xcodeproj` showed up in the repo root (13:06, not from Claude); moved to Trash.
  Always open `ios/Coco.xcodeproj`.
- `Coco-Info.plist` sits in `ios/`, not `ios/Coco/`: Xcode auto-includes everything in `Coco/`, which would clash
  with the Info.plist Xcode generates.
- What's sent to the server: the conversation from the first user message on, without the on-screen greeting and
  without error notes (so Coco never "remembers" saying sorry).
- iPhone can't use `localhost` (that's the phone itself) → app uses the Mac's network name
  `dafeideMacBook-Pro.local`, which stays the same when the IP changes.
- Bundle ID `com.renxingyu.Coco` was already taken by another Apple account → changed to `com.renxingyu0822.Coco`.
- Free Apple ID: the app stops opening after 7 days → reinstall from Xcode shortly before a demo.
- University Wi-Fi (eduroam) usually blocks device-to-device traffic → iPhone hotspot with the Mac on it is the
  likely fix for presentations. Not tested yet.

**Open for the presentation (Fri 13 Nov):**
- Test the iPhone-hotspot setup (Mac on the iPhone's hotspot) in case university Wi-Fi blocks the connection.
- Reinstall the app from Xcode shortly before Friday (7-day limit).
- Decide on a backup, since the Simulator doesn't work on this Mac.

**Corrections:**
- First Simulator screenshots were taken too early / blank; checked with Settings app to confirm it's the Simulator,
  not our code.

---

## 2026-11-06
**Did:**
- Repo frame (`ios/`, `server/`, `docs/`, `.gitignore`), git init, GitHub (public, renamed `coco` → `Coco`).
  Added this diary and a public `README.md` (based on the proposal, no personal data).
- Back end, step by step: venv + pinned requirements, `.env` (key checked, never printed), `prompt.py`
  (Coco's personality), `main.py` with `GET /health` + `POST /chat`. First reply: "Hello! How are you today?"
- `chat_cli.py`: terminal chat with Coco. `coco` shortcut (`~/.zshrc` → `server/coco.sh`): starts the server
  if it's off, then opens the chat. Tested both cases.

**Found:**
- git doesn't track empty folders. The proposal PDF has name + student ID → `docs/` is git-ignored.
- Claude Code sessions are saved per project folder in `~/.claude/projects/`, can be resumed or searched later.
- How the server works: `uvicorn main:app` loads `main.py` once at start; the `@app.get/post` lines build the
  "menu" of endpoints; clients only use the URL (`localhost:8000/health`). `/docs` = FastAPI's auto test page.
  From the iPhone, `localhost` won't work → need the Mac's Wi-Fi IP.

**Decided:**
- CLAUDE.md overrides the proposal where they disagree (e.g. evaluation not part of the 13 Nov demo).
- Coco's tone: warm, cheerful young helper, fond of the person, never babyish. NOT "like their real child"
  (blurs the AI boundary, raises the dependency risk from instructor question 4). Coco nudges toward real family.
- Model: `gpt-4o-mini` for now (cheap), changeable in `.env`.
- Commit locally after each step, push only when asked.

**Corrections:**
- Claude built the whole back end in one go instead of step by step → reverted and rebuilt together.
  Lesson: one small step at a time, explain first, wait for OK.
- Claude's `sed` edit with a `#` inside created a junk file that got pushed; removed. Lesson: exact edits, not sed.
- A failed `git revert -q` + `--amend` mislabelled a commit locally; fixed before pushing.
- Server README lost its run instructions in the revert; noticed and restored.
- Claude wrote a "Next" step into the diary on its own; removed. Next steps are only written when the user says them.
