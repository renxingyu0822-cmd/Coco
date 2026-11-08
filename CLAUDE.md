# Coco — project context for Claude Code

Read this first in every session. Update it when decisions change.

**Working diary:** `DIARY.md` (newest on top). At session start read only the latest ~3 entries;
grep it for older details. Add a short entry after each finished step or at session end
(Did / Found / Decided / Corrections). Only add a "Next" line when I say what's next, never decide it yourself.

## What Coco is
Coco is a digital everyday-assistance service for older adults, staffed by AI agents.
It's my semester project for the course **Frontier Systems** (L3S, Leibniz Universität Hannover, winter 2026/27).
Course theme: "AI for Good" — build an AI-driven startup with coding agents.

- **Users:** older adults living on their own.
- **Paying customers:** their adult children (family plan).
- **Front-office agents** (talk to the older person), in priority order:
  1. Companion with long-term memory
  2. Basic tools: reminders (medication, appointments, "pot on the stove"), calendar, weather, music (Apple Music)
  3. Voice version (done early, Nov)
  4. Advanced, January (need skills): scam guard, Mail helper, and the **country-specific pairs**:
     messaging (WeChat / WhatsApp), video (Bilibili / YouTube), maps (Baidu Maps / Google Maps)
  5. Later, if time: info helper (web search), Family liaison
  (Changed 8 Nov: scam guard moved from core to January because it's harder to build.)
- **Tool rule (decided 8 Nov):** tools built this year must work the same in **China and Germany**
  (calendar, reminders, Apple Music are built into the iPhone; weather via a service that covers both).
  Country-specific tools come in January, as pairs (China / Germany).
- **Back-office agents** (run the company): engineer, code-review, QA, scam analyst, later research/marketing and support.
- **Boundaries:** users always know they talk to an AI; emergencies ("I fell") go to family / 112;
  the agent never enters passwords or makes payments; health info is only used for reminders, never for advice.

The full proposal (two-pager) and the instructors' feedback are in `docs/` (local only, git-ignored: contains personal data).
Where the proposal and this file disagree, **this file wins** (it's newer).

## Current goal (first presentation: Fri 13 Nov 2026)
A working demo: **chat with Coco in the app on my iPhone.**
Done means:
1. Repo frame: `ios/`, `server/`, `CLAUDE.md`, pushed to GitHub
2. Back end: small Python server on my Mac -> OpenAI API with Coco's personality prompt -> reply
3. App: simple SwiftUI chat screen that talks to the server
4. Runs on my iPhone over home Wi-Fi (simulator as backup for the presentation)

NOT in scope for this demo: memory, tools, evaluation. They come after.
**Voice brought forward (decided 7 Nov):** OpenAI speech via the server (`/transcribe` + `/speak`),
not Apple's on-device speech. Added after the 4 demo steps were done.

## Development plan (decided 8 Nov; marketing/business plan is separate, see "Open points")
| When | What |
|---|---|
| by 15 Nov | Basic question-answering agent (text + voice chat — mostly done) |
| rest of Nov + Dec | Basic tools that work in both China and Germany (calendar, weather, Apple Music, reminders) + long-term memory |
| mid Dec + Christmas break | Design + run tasks: **base** (do the tools work?), **long-term memory** (does memory work?), **hallucination** (as "broken twins" of base tasks, e.g. weather tool down; plus no-tool ones like medical advice). Improve the score by reading the conversation logs. |
| January (if memory works) | Advanced features that need skills: scam detection, email, and the China/Germany pairs (WeChat/WhatsApp, Bilibili/YouTube, Baidu/Google Maps). Then their tasks, improve the score again. |

## Decisions so far
- **Language / market:** English first, Germany as first market. (Instructors flagged that few older adults in Germany
  will use an English app — keep a German output mode in mind for later.)
- **LLM:** OpenAI / OpenAI-compatible API, model chosen after early tests.
- **Architecture:** thin iPhone app + Python back end. The API key lives ONLY in the back end, never in the app.
- **Back end runs on my Mac for now**; moves to an EU-hosted cloud server later (GDPR, health data).
- **Memory (Nov/Dec):** try open-source GBrain first, custom memory module as fallback.
  Four memory types: personal profile, recent events, health info (separate + protected), short-term reminders.
  Memory is **always on** (no switch to turn it off).
- **Evaluation (Dec):** adapted from CAR-bench (the student version is at
  github.com/renxingyu0822-cmd/Car_Bench_Jet2Holiday): simulated older user + Coco + evaluator, rule-based + LLM-judge
  checks, each task run k=3 times (Pass^3 / Pass@3). Task types: base, long-term memory, hallucination.
  **No no-memory baseline:** the first run of the tasks is the baseline; improve from there using the conversation logs.
  Metrics include task success, memory recall, hallucination rate, cost per task.

## Repo structure
```
Coco/
├── CLAUDE.md
├── DIARY.md     # working diary, newest on top
├── docs/        # proposal, feedback, notes (local only, not in git)
├── ios/         # Xcode project (SwiftUI app "Coco")
└── server/      # Python back end (agent core, later tools, memory, eval)
```

## Dev environment
- Intel MacBook. VS Code + Claude Code extension for everything.
- Xcode only to build/run the iOS app. (Xcode's own Claude Agent doesn't work on Intel Macs — don't rely on it.)
- Test device: my iPhone. iOS app target: iPhone first, Apple Watch later for reminders.

## How I want to work
- **Step by step, under my supervision.** Explain the plan for each step briefly before writing code,
  and wait for my OK before big changes or new dependencies.
- Keep things small and runnable — one step at a time, test it, then move on.
- Code comments: short, informal English, casual is fine. No long formal docstrings.
- Explanations: concise, plain English.
- Never commit secrets. `.env` goes in `.gitignore`.
- Commit locally after each finished step (small commits, clear messages).
  **Only push to GitHub when I ask for it.**

## Open points from the instructors' feedback (marketing/business plan — separate, still thinking, no dates yet)
1. Choose a first market and meet real older users: 5 conversations each with older adults and their children.
2. Resolve the trust conflict: define exactly what the paying children see (conversations are private),
   and what happens when the service fails (missed "I fell", missed medication reminder).
3. Price: derive a lower limit from cost per task in the evaluation.
4. How to avoid a lonely person depending too much on the Companion.

## Status
- [x] Xcode project `Coco` created (SwiftUI)
- [x] Repo frame + GitHub (public: https://github.com/renxingyu0822-cmd/Coco)
- [x] Back end: basic chat endpoint (`server/`, FastAPI + gpt-4o-mini, run cmd in `server/README.md`)
- [x] iOS chat screen, connected to the server (tested in Xcode Preview; Simulator renders blank on this Mac)
- [x] Running on iPhone over home Wi-Fi (server address: `http://dafeideMacBook-Pro.local:8000`,
      bundle ID `com.renxingyu0822.Coco`, free Apple ID → reinstall from Xcode every 7 days)
- [x] Voice: hands-free voice chat (OpenAI speech), panda design, English only
