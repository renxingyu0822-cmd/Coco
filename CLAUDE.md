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
  2. Reminder assistant (medication, appointments, short-term like "pot on the stove")
  3. Scam guard
  4. Info helper (web search, plain-language answers with sources)
  5. Video helper (YouTube / saved TikTok links via embedded players)
  6. Voice version
  7. Later, if time: Navigator (Google Maps), Mail helper (Gmail), Family liaison
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

NOT in scope for this demo: memory, tools, voice, evaluation. They come after.

## Decisions so far
- **Language / market:** English first, Germany as first market. (Instructors flagged that few older adults in Germany
  will use an English app — keep a German output mode in mind for later.)
- **LLM:** OpenAI / OpenAI-compatible API, model chosen after early tests.
- **Architecture:** thin iPhone app + Python back end. The API key lives ONLY in the back end, never in the app.
- **Back end runs on my Mac for now**; moves to an EU-hosted cloud server later (GDPR, health data).
- **Memory (later, M2):** try open-source GBrain first, custom memory module as fallback.
  Four memory types: personal profile, recent events, health info (separate + protected), short-term reminders.
- **Evaluation (later):** simulated environment adapted from CAR-bench — three LLMs (assistant, simulated older user,
  evaluator) + rule-based checks. Task types: base, long-term memory, hallucination. Compare against a no-memory baseline.
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

## Open points from the instructors' feedback (for later updates)
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
