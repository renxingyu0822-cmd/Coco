# Coco — working diary

Newest entry on top. Short entries: what we did, what we found, decisions, corrections, next.
Public repo: no personal data here.

## Development plan (decided 2026-11-08, details in CLAUDE.md)

| When | What | Status |
|---|---|---|
| by 15 Nov | Basic question-answering agent (text + voice chat) | ✅ mostly done |
| Nov – Dec | Long-term memory + basic tools for China and Germany: calendar, reminders, weather, Apple Music, web search | ⬜ |
| mid Dec + Christmas | Tasks: base (tools work?), long-term memory (memory works?), hallucination ("broken twins" of base tasks). First run = baseline, improve via conversation logs. | ⬜ |
| January | Advanced: scam detection, email, Family liaison, China/Germany pairs (WeChat/WhatsApp, Bilibili/YouTube, Baidu/Google Maps). Then their tasks. | ⬜ |

Marketing/business plan (first market, interviews, trust model): separate, not planned yet.

---

## 2026-11-09
**Decided:**
- Web search is now a basic tool (Nov/Dec); it must work in both China and Germany, like the other basic tools.
- Family liaison moved to January.

**Found:**
- Typing in the app works. The listening screenshot on GitHub has updated by itself.

---

## 2026-11-08
**Did:**
- Voice tested on the iPhone: Coco speaks, mic works (after the crash fix below).
- **Hands-free voice chat** (like ChatGPT voice mode, simple version): the app notices when you stop talking
  (1.5 s of quiet after speech), sends by itself, Coco answers out loud, then listens again. Ends via
  "Stop voice chat" or after 10 s of silence. Mic is off while Coco speaks, so she can't hear herself.
  Tuning knobs at the top of `VoiceRecorder.swift` (`speechLevel`, `pauseToFinish`, `giveUpAfter`).
- **New look, from hand-drawn sketches:**
  - Text mode: header "Coco" + speaker button; big start card (green phone icon + "Call Coco" panda,
    "Tap Coco to start voice chat"); bubbles; text field + send.
  - Voice mode: "Stop voice chat" on top, bubbles, big panda + status text below.
  - Panda pictures (hand-drawn, transparent PNGs in Assets): `panda-idle` (Call Coco), `panda-listening`,
    `panda-thinking`, `panda-talking` (keeps its "Talking…" lettering). Each moves a little per state.
  - Colours: black and white (accent = black in light mode, white in dark mode).
  - App icon: the "Call Coco" panda on white.
- **English only for the demo:** transcription language fixed to `en` (`OPENAI_STT_LANGUAGE`), and
  Coco always replies in English.

**Found:**
- iOS kills an app instantly (`__abort_with_payload`) if it touches the mic without a permission text.
- Xcode can overwrite the project file with its own older copy → our mic permission text vanished.
  Fix: such settings go into `Coco-Info.plist`, which Xcode doesn't rewrite. When Xcode asks about
  changed files: always "Read from disk", never "Keep Xcode version".
- "Killed for too much memory" after locking the phone = iOS closing a background app, not a bug.
- "attach… already being debugged" = Xcode's debugger stuck on an old run; the app itself is installed.
  Stop, close Coco on the phone, run again (or restart iPhone / Xcode).
- Transcription guessed the language and sometimes picked Chinese → fixing the language solves it.
- The drawing PNG has a transparent background → no white boxes, works in dark mode.

**Decided:**
- Hands-free with on-device silence detection now (option A); OpenAI Realtime API (interruptions,
  lower delay) later, fits the January voice milestone.
- Mascot: panda (polar bear / grizzly maybe later as options). Panda drawn by hand, not in code
  (the code-drawn one looked creepy).
- Thinking and speaking have their own pictures now; more emotions later (needs a mood from the server).
- Left out for now: the "+" upload button and the person icon from the sketch (no function yet).
- No coral, no hexagon frame: black and white, panda only.
- **New development plan** (details in CLAUDE.md): basic QA agent by 15 Nov → basic tools (calendar, weather,
  music, reminders) + long-term memory in Nov/Dec → base, memory and hallucination tasks mid-Dec/Christmas →
  advanced features (videos, scam detection, Maps, email) in January.
- Scam detection moved from core to January (harder to build).
- No no-memory baseline: memory always on, the first task run is the baseline, improve via conversation logs.
- Hallucination tasks kept, written as "broken twins" of base tasks (like CAR-bench).
- Development plan and marketing/business plan kept separate; business questions still open.
- Tool rule: tools built this year must work in both China and Germany (calendar, reminders, weather,
  Apple Music). Country-specific pairs in January: WeChat/WhatsApp, Bilibili/YouTube, Baidu/Google Maps.

**Corrections:**
- Claude edited the project file while Xcode was open; Xcode overwrote it → crash. Now in `Coco-Info.plist`.
- Diary edit put 2026-11-07 decisions into the 2026-11-06 entry by mistake; moved back.
- Cutting the pandas: first used a wrong file path, and the first tool turned transparency black. Both fixed.

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
- **Voice mode** (brought forward from January), OpenAI speech through the server:
  - Server: `/speak` (gpt-4o-mini-tts, voice "coral", tone in `VOICE_INSTRUCTIONS`) and `/transcribe`
    (gpt-4o-mini-transcribe, m4a upload). Both tested from the terminal. New dependency: `python-multipart`.
  - Server split into `server/app/` (main = menu, settings, chat, voice, prompt), with notes in every file.
  - App: Coco reads replies aloud (speaker on/off button), mic button (tap to talk, tap to send).
    Built without errors, **not yet tested on the iPhone**.

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

**Decided:**
- Voice: OpenAI (option B) over Apple's on-device speech: more natural voice, better recognition. Costs per use.
  Same API key. Tap-to-talk instead of hold-to-talk (easier for older hands).
- Server code lives in `server/app/`; start command is now `uvicorn app.main:app`.

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
