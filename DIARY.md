# Coco — working diary

Newest entry on top. Short entries: what we did, what we found, decisions, corrections, next.
Public repo: no personal data here.

## Development plan (decided 2026-11-08, details in CLAUDE.md)

| When | What | Status |
|---|---|---|
| by 15 Nov | Basic question-answering agent (text + voice chat) | ✅ done |
| Nov – Dec | Voiceprint (added 16 Nov, before memory) ✅ + long-term memory + basic tools for China and Germany: calendar, reminders, weather ✅ (23 Nov), clock/time ✅ (24 Nov), Apple Music, web search | 🟡 in progress |
| mid Dec + Christmas | Tasks: base (tools work?), long-term memory (memory works?), hallucination ("broken twins" of base tasks). First run = baseline, improve via conversation logs. | ⬜ |
| January | Advanced: scam detection, email, Family liaison, China/Germany pairs (WeChat/WhatsApp, Bilibili/YouTube, Baidu/Google Maps). Then their tasks. | ⬜ |

Marketing/business plan (first market, interviews, trust model): separate, not planned yet.

---

## 2026-11-24 (slides for the second presentation)
**Did:**
- Second presentation (**Fri 27 Nov 2026**): `docs/slides/presentation_2/coco.tex` (+ PDF), same style as the first,
  11 slides: recap, language (English demo now, Chinese models for real users), which Chinese models, voiceprint
  (how / safe / test chart incl. *The Office* / what Coco can do), how tools work (diagram), weather + clock,
  GBrain research + decision, next two weeks.
- Research for the language slide: chat = Qwen (Alibaba) or DeepSeek (both OpenAI-compatible → settings change);
  speech→text = Qwen3-ASR / Doubao Seed-ASR 2.0 (dialects), open source Paraformer/SenseVoice (FunASR);
  text→speech = CosyVoice (open source), Qwen3-TTS, Doubao Seed-TTS 2.0. China needs CAC-filed models (no foreign
  model filed as of 2025); OpenAI API reportedly blocked in mainland China (second-hand). Speech needs an adapter.

**Found:**
- Accuracy claims are mostly vendor-reported, none about older speakers. iFlytek not checked.
- `\note` is taken in Beamer, `step` in TikZ (again!). PDF pages can be checked as PNG with a small PDFKit script.
- Not in the slides: instructors' priorities "meet real older users" and "trust model" (still open).

---

## 2026-11-24 (long-term memory: GBrain research + decisions)
**Did:**
- Looked into **GBrain** (github.com/garrytan/gbrain, by Garry Tan / Y Combinator, April 2026). Only from its
  README + articles, **not tried yet**.

**Found — what GBrain is:**
- Open source, **MIT licence** (free, also commercially; keep the licence notice if we copy code).
- A memory store for AI agents: memories are **Markdown pages** (one per person / company / project) with
  **links** between them (a small wiki / knowledge graph). Markdown is the source; a database is the index:
  PGLite (Postgres in WASM, default, no server, up to ~50K pages) or Postgres + pgvector.
- **Writing:** the agent "remembers" by writing/updating pages; optional automatic capture of facts/names from
  conversations; **nightly clean-up ("dream cycle")**: merge duplicate people pages, fix citations, find
  contradictions.
- **Reading:** hybrid search = **keyword + vector (by meaning) + reranker**, plus **graph** walks along links for
  relationship questions; `think` = summary with sources + what it *doesn't* know. Keyword works without API key;
  vector search needs an embeddings provider (OpenAI, Voyage, … also Alibaba/Zhipu for China).
- **Access:** command line or MCP (`gbrain serve`). No Python library / REST API mentioned.
- **Stack:** TypeScript on **Bun** (not on npm; the npm "gbrain" is unrelated). Always-on setup described with
  8 GB+ RAM (our server: 4 GB). New releases **many times a day** → pin a version.
- **Users:** personal brain by default; "company brain" mode for 10–50 people; README: access control is
  "not a universal no-leak guarantee". Text goes to the configured cloud providers.

**Found — fit for Coco:**
- Good: people pages + links = "my son lives in Beijing" (→ "too early to call my son?"); nightly clean-up suits
  older users who repeat themselves; "say what you don't know".
- Hard: built for one person, not many separate users; no "health info separate + protected"; second program
  next to our Python server; server RAM; fast-changing; our rules (voiceprint: only the real user's words,
  visitors) must be enforced by us before anything reaches the memory.
- Memory on the **phone** discussed: GBrain can't run on an iPhone. Coco's own memory could (privacy, users
  apart), but: OpenAI still sees memories in use, phone lost = memory gone (iCloud backup), no nightly jobs,
  evaluation runs on the server, family can't reach it. Middle way (phone stores, server decides) noted.

**Decided:**
- **Later, for real users: B = one separate store per user on the server** (own folder per user, health info as
  its own, encryptable file; "delete me" = delete the folder). Needs a **user ID** first (app creates ID + secret
  on first launch; today all phones share one app password and there's one voiceprint for everybody).
- **For now (we're building a sample): set multi-user aside, build ONE GBrain on the online server**
  (single user). Still to check in practice: install Bun + GBrain, speed per lookup, RAM next to the voice model,
  how Python talks to it (CLI or MCP).

**Next (my call):** slides for the second presentation. Memory work pauses until then.

---

## 2026-11-24 (clock: Coco knows the time)
**Did:**
- **Coco knows the date and time.** The app sends the phone's time zone (`user_timezone`, e.g. Europe/Berlin)
  with every `/chat`; the server adds "Right now it is Tuesday 24 November 2026, 00:08 …" to the system prompt
  (`tools/clock.py` `now_line()`), so no extra round trip. No/unknown time zone → Coco says she can't see the time.
- **Tool `get_time(place)`** for the time elsewhere ("too early to call my son in Beijing?"); reuses the weather
  tool's place lookup (Open-Meteo knows each town's time zone).
- Prompt "Time and date": never guess, use it for today/tomorrow/weekend, say times the friendly way.
- Tested (Mac curl + iPhone): "What time is it?" → "a quarter past midnight"; "Is tomorrow Monday?" →
  "No, tomorrow is Wednesday"; Beijing → "about seven in the morning, a bit early"; "rain this Saturday?" works.

- Screenshot: `docs/app-pictures/clock.jpg` ("What time is it?" / "Is tomorrow Monday?"), in README.

**Found:**
- Before this, Coco didn't know the date at all (the model has no clock) → would have guessed.
- gpt-4o-mini sometimes still adds digits ("00:08"); "Is it Sunday already?" → "not Sunday yet" (odd but day correct).
- Online test "Is it too early to call my son in Beijing?" ×11: 9× looked up Beijing, 1× offered to check first,
  1× asked me for the time instead of using `get_time`; one answer said "a bit late there" and then 7 am.

**Decided:**
- Not fixing the tool description for now: the real case ("Is it too early to call my son?" without a place)
  is a **long-term memory** question (Coco must remember where the son lives). Keep it as a memory test case.
- Clock is live on the online server too.
- Clock = A (time/date) now; B (timers/alarms, "pot on the stove") = the first phone tool, later.

---

## 2026-11-24 (weather card fixes)
**Did:**
- Weather card: clouds were white on the light grey card (Apple's multicolor style) → almost invisible.
  Now our own colours per symbol layer (`.palette`): clouds grey, sun orange, rain blue, snow cyan, moon indigo,
  stars/bolt yellow. Heading was cut off ("Today, Mon 23 N…") → city on its own line (big), day below without
  the month ("Today, Tue 24"). App-only change, works with both servers. Tested on the iPhone.
- `docs/app-pictures/weather-card.jpg` replaced with the fixed card (README).

---

## 2026-11-23 — where we stand (end of session 16–23 Nov)
**Working now (Mac + online server, tested on the iPhone):**
- Text + hands-free voice chat; ⚙️ Settings: About you (name, she/he/they, town), server switch Online / My Mac.
- **Voiceprint:** set up + "Is it me?" in Settings; every voice message tagged user / someone else (cut-off 0.35);
  Coco treats visitors/TV differently and keeps the user's private things private; honest if asked.
- **Weather tool** (Open-Meteo) with weather card; admits when the service is down (`WEATHER_TOOL_DOWN=1`).
- Keyboard like WhatsApp. Everything pushed; online server up to date.

**Open points (not decided yet):**
- Grey speaker labels in the chat still visible (my choice for now; hide later: `Bubble.showSpeakerLabel`).
- Typed messages always count as the user → a visitor could type to get private info.
- "Just my name" + a title (Mr./Mrs.) → Coco sometimes still says he/she.
- Every conversation's content goes through OpenAI (voice + text); only the fingerprint stays on our server.
- Mac server stops when the Mac sleeps/restarts → `coco` before using "My Mac".
- First request after a server restart is slow (voice model loads, ~6 s online, ~25 s Mac).
- `ios/Coco.xcodeproj/xcshareddata/` (Xcode scheme, probably the logging setting) not in git yet.
- No diary entry about the 13 Nov presentation (how it went, feedback).
- Still to do from the plan: long-term memory, reminders, calendar, Apple Music, web search.

---

## 2026-11-23 ("Your town")
**Did:**
- Settings → **About you**: name, "When Coco talks about you", and new **Your town**. Saved on the phone, sent
  as `user_town` with each `/chat` (cleaned like the name, max 60 chars). Coco uses it for weather questions
  without a place; if the user says they're somewhere else, she uses that place.
- Tested (Mac curl + iPhone): town used for "umbrella tomorrow?", Beijing when travelling, asks when no town set.
  Pushed + live on the online server.

**Found:**
- Data flow: the town goes to OpenAI (chat text) and Open-Meteo (place lookup). Town name only, no address.

---

## 2026-11-23 (weather card + online)
**Did:**
- **Weather card in the app** (`ios/Coco/WeatherCard.swift`): under Coco's answer, in text and voice chat.
  Apple weather symbol (colour, moon at night), city + day, big temperature (now for today + "feels like",
  else the day's high), low/high, rain chance, wind, credit "Weather data: Open-Meteo.com".
- Server: `/chat` answers `{"reply", "cards": [{"type": "weather", ...}]}`. Cards are built from the **real tool
  result** (`tools.card()`), never from the model's words. Errors → no card. Older app versions ignore cards.
- Prompt: for today say the temperature right now first, then the high (Beijing mix-up fixed); keep words short
  because the card shows the details.
- Tested on the iPhone (My Mac): works. Then pushed + **weather tool and card live on the online server**.
- Screenshots: `docs/app-pictures/weather-card.jpg` ("Is it cold outside?" → Hannover from "Your town", in README)
  and `weather-card-now.jpg`.

---

## 2026-11-23 (first tool: weather)
**Did:**
- **Weather tool** (server tool), data from **Open-Meteo** (free for non-commercial use, no key, worldwide,
  credit "Weather data by Open-Meteo.com" → README Credits).
  - `server/app/tools/weather.py`: place → coordinates (Open-Meteo geocoding) → forecast (7 days, place's local
    time) → plain words (weather codes → "overcast", "light rain", …). Days: today / tomorrow / weekday / date.
    Several towns of similar size (Springfield) → "ask which one". Never raises: errors come back as text.
    `WEATHER_TOOL_DOWN=1` fakes an outage (broken twin for the evaluation).
  - `server/app/tools/__init__.py`: list of tools + `run()`; `chat.py`: **tool loop** (model asks for a tool →
    we run it → model answers; max 3 rounds). Tool calls logged as `tool: get_weather(...) -> ...`.
  - `prompt.py` "Tools": never guess the weather, ask which town, admit errors, simple words + a practical tip.
- Tested on the Mac (curl): Hannover tomorrow, Beijing "what to wear", no town → asks, Springfield → asks,
  no-weather question → no tool, **service down → "I can't check the weather right now"** (no guessing).
  ~2–4 s per weather answer (one extra OpenAI round).

**Found:**
- Mac's Python couldn't check HTTPS certificates (`CERTIFICATE_VERIFY_FAILED`) → use `truststore`
  (already installed with openai, also on the server).
- Open-Meteo lookup finds Chinese names (北京) only with `language=zh`; Coco is English-only for now.
- Why not the iPhone's Weather app: apps can't read it; its data (WeatherKit) needs the paid Apple Developer
  Program. Possible later; only the fetching part of the tool would change.

**Decided:**
- Open-Meteo for now (vs. QWeather / WeatherKit). "Your town" setting comes next, so Coco knows where "here" is.

---

## 2026-11-23 (where the data goes)
**Did:**
- Voiceprint model loads **offline** once downloaded (`HF_HUB_OFFLINE=1` set in `voiceprint.py` before the
  import): no more "is my copy current?" check with Hugging Face at each start. Fresh server still downloads once.
- Pushed everything + updated the online server (voiceprint in chat, visitor rules, name + pronouns, offline).

**Found — where the data goes** (for the presentation / privacy slide):

| What | Where it goes |
|---|---|
| Voice recording | **OpenAI** (speech → text) + **our server** (voiceprint) |
| Voice fingerprint (192 numbers) | **only our server** (Mac / Helsinki), never the audio |
| Chat text | **OpenAI** (Coco's replies) |
| Speaker note, name, pronouns | **OpenAI**, as part of the chat text |
| Coco's spoken reply | made by **OpenAI** |

- SpeechBrain is open-source software, not a service: the model runs on our machine, no audio goes to
  SpeechBrain or Hugging Face.
- The voiceprint is private, but **every conversation's content still passes through OpenAI** (chosen on purpose
  for now). Later options: OpenAI's EU data options, or a local speech-to-text model.

---

## 2026-11-23 (what Coco calls you)
**Did:**
- **Settings → "What should Coco call you?"**: name + "When Coco talks about you" (Just my name / she / he / they).
  Saved on the phone, sent with each `/chat` (`user_name`, `user_pronouns`); `chat.py` adds an
  "About the person you look after" part to the system prompt. Name cleaned (max 40 chars, no brackets/quotes/
  line breaks). Tested on the Mac (curl) + iPhone with My Mac: works.
- The "someone else" note now repeats the key rules itself (don't say how the user is / nothing private,
  how to refer to them).

**Found:**
- gpt-4o-mini ignored rules that were only deep in the system prompt: told a visitor "Dafei is doing well"
  (made up + private). Repeating the rule in the per-message note fixed it.
- "Just my name" + a title ("Mr. Schmidt") → still sometimes "he". Picking a pronoun avoids it.

---

## 2026-11-23 (Coco knows who's talking)
**Did:**
- **Coco now gets the voiceprint result.** App sends `speaker` with each voice message to `/chat`;
  `chat.py` turns it into a hidden note in front of the text ("[voice: the user]" /
  "[voice: someone else, not the user]"); typed / "unknown" = no note = the user.
- Rules in `prompt.py` ("Who is talking"): someone else → friendly, may ask once who's there, general help ok,
  **never shares the user's private things** (health, medication, reminders, appointments, family);
  TV/radio → says lightly it sounded like the TV, carries on with the user; emergencies count from anyone (112);
  if asked, explains the voice check honestly (not perfect).
- Tested on the Mac with curl (TV line, visitor asking about medicine, visitor small talk, visitor reports a fall,
  user asks "do you know my voice?") and on the iPhone with **My Mac**: works.

**Found:**
- First version of the prompt said "never mention a voice check" → Coco *denied* having one when asked.
  Changed: honest if asked. (Boundary: users always know what's going on.)
- White screen after installing = Xcode's debugger still attached (not a crash). Stop / quit Xcode,
  open Coco from the home screen. Xcode's "logging system timed out" message is harmless.
- Typed messages always count as the user (no voice to check) → a visitor could type. Open for later.

**Decided:**
- Speaker labels stay visible in the chat for now.

---

## 2026-11-23 (voiceprint in voice chat)
**Did:**
- **Voiceprint connected to voice chat.** `/transcribe` now also checks who's talking, at the same time as
  OpenAI's transcription (no extra wait): answer `{"text", "speaker": "user"|"other"|"unknown", "score"}`.
  "unknown" = no fingerprint / no model / clip under 1 s / not wav; transcription never fails because of it.
  Coco still answers everyone; the tag is for the memory later + logged (`voiceprint: chat message from …`).
- App: voice chat records **WAV** now (was m4a). Grey label under voice bubbles: "🎙 you · 0.72" /
  "🎙 someone else · 0.20" / "🎙 not checked". Switch: `Bubble.showSpeakerLabel` — **hide after testing**.

**Online server tested too (works, me + Pam).** **Test (voice chat, Mac server, cut-off 0.35):** me 0.72, 0.70 → you; Pam (TV) 0.20, 0.12 → someone else.
Short "Yes." (computer voice) → not checked.
Screenshots for the presentation: `docs/app-pictures/voiceprint-you.jpg` (me, "you · 0.70") and
`voiceprint-someone-else.jpg` (Pam from *The Office* on TV, "someone else · 0.20").

---

## 2026-11-23 (voiceprint online)
**Did:**
- **Voiceprint deployed on the online server.** Pushed to GitHub, `git pull` on the server, installed the
  voiceprint packages (CPU-only PyTorch, +1.5 GB disk, 33 GB left), restarted Coco.
  Tested over the internet with the `say` clips + app password: same scores as on the Mac
  (me 0.90 / 0.84, others 0.04 / 0.39 / 0.00), ~1 s per check, no password → 401, chat still works.
  Test fingerprint deleted afterwards.
- Package lists split: `requirements-voiceprint-mac.txt` (old pins, Intel Mac) and
  `requirements-voiceprint-server.txt` (current versions, Linux). README + CLAUDE.md updated.

**Found:**
- Server can use current versions: torch 2.15 (CPU), speechbrain 1.1.2, huggingface_hub 2.4 → no pin juggling.
  Model loads in ~6 s there (Mac ~25 s); after each restart the first voiceprint request is slower.
- Each server keeps its own fingerprint (`server/data/voiceprint.json`) → set up the voice again with "Online".
- Scratchpad clips were gone after a Mac restart; remade them with `say`.

**Test results online** (fresh setup with my normal voice on the online server, cut-off 0.33). **For the next presentation.**

| Who | Online (23 Nov) | Mac (23 Nov, earlier) |
|---|---|---|
| Me, normal | 0.88 ✓ | 0.74, 0.76 |
| Me, weird / fake | 0.54 ✓ | 0.42, 0.53 |
| Me, singing | 0.37 ✓ | 0.52 |
| Michael | 0.07 | 0.03 |
| Jim | 0.08 | 0.09 |
| Pam | 0.31 | 0.25 |
| Toby | 0.13 | 0.03 |
| Angela | 0.28 | 0.21 |

- All 8 right at 0.33. Normal voice very safe (0.88). Edges close: my singing 0.37 vs Pam 0.31.
- Pam and Angela are the closest to my voice both times (realistic risk: TV running in the room).
- OK for Coco's purpose: users talk normally; a mis-tagged odd message only means it isn't remembered.
- **Decided:** cut-off **0.33 → 0.35** (a bit more room above Pam 0.31; my singing 0.37 still just passes).
  Briefly set to 0.4 (also deployed online), then changed my mind to 0.35.

---

## 2026-11-23 (voiceprint in the app)
**Did:**
- **Voiceprint, step 2–3: server + app** (works on the iPhone, **Mac server only**).
  - Server `server/app/voiceprint.py`: `GET /voiceprint` (set up?), `POST /voiceprint/enroll` (3 wav clips →
    fingerprint = average of 3), `POST /voiceprint/check` (1 clip → score + yes/no), `DELETE /voiceprint`.
    Score = cosine similarity (1 = same, ~0 = unrelated). Cut-off `VOICEPRINT_THRESHOLD`, default 0.25.
    Only the 192 numbers are kept (`server/data/voiceprint.json`, git-ignored), never the audio.
    One fingerprint for now (no user accounts). Model loads on first use (~25 s on the Mac); without
    torch/speechbrain the endpoints answer 503 instead of crashing (online server doesn't have them yet).
    Extra packages listed in `server/requirements-voiceprint.txt` (Mac pins), not in `requirements.txt`.
  - App: ⚙️ Settings → Voice → **Voice fingerprint** (`VoiceprintView.swift`): set up (read 3 sentences,
    stops by itself at a pause), "Is it me?" (shows result + score), delete (with confirmation), privacy note.
    Records WAV 16 kHz mono (`VoiceRecorder(wav: true)`).

**Test results** (enrolled once with my normal voice, 3 sentences; cut-off 0.25). **For the next presentation.**

| Who | Score |
|---|---|
| Mac `say` voices (test before the app): same voice, new sentences | 0.84, 0.90 |
| Mac `say` voices: other voices | 0.01, 0.04, **0.39** (similar female voice → wrongly "me") |
| Me, normal voice | 0.74, 0.76 |
| Me, singing | 0.52 |
| Me, fake / weird voice | 0.42, 0.53 |
| Friend | 0.09, 0.18 |
| TV, *The Office*: Michael / Jim / Pam / Toby / Angela | 0.03 / 0.09 / **0.25** / 0.03 / 0.21 |
| First round, not sure who (maybe me) | 0.49, 0.31, 0.21 |

**Found:**
- Real people separate well: others ≤ 0.25, me ≥ 0.42 (even disguised), normal voice ~0.75.
  Changing my voice lowers the score but it still recognises me.
- Pam (0.249) only just missed the 0.25 cut-off → 0.25 is too tight.
- Computer voices are less reliable than real ones (one at 0.39).
- Small test: 2 real people + 5 TV voices, ~17 tries. Keep tuning with more data.
- The Mac server stops when the Mac sleeps / the terminal session ends → restart with `coco` before tests.

**Decided:**
- Cut-off raised from 0.25 to **0.33** (middle of the gap between 0.25 and 0.42).

---

## 2026-11-23
**Did:**
- **Text box + keyboard, like WhatsApp** (tested on the iPhone, works):
  - Box empties after sending: clear `input`, and once more 0.1 s later (the keyboard can write the text back
    right after we clear it).
  - Tap the chat or drag it down → keyboard goes away (`scrollDismissesKeyboard` + tap → `@FocusState` off).
  - Tap the text box → chat scrolls to the newest message above the keyboard (after ~0.3 s).
- Server switch (19 Nov) tested on the iPhone too.

**Corrections:**
- The 22 Nov fix (swap in a fresh text box via `.id`) made the keyboard drop and pop back after each send.
  Replaced by the "clear twice" fix above.

---

## 2026-11-22
**Did:**
- App reinstalled (7-day limit had run out → "not trusted").
- "Can't reach my Mac": the Mac server had stopped (Mac asleep/restarted). Started again; reminder: type `coco`
  on the Mac before using "My Mac". Mac was on a 10.2.x.x network (maybe not home Wi-Fi; shared networks can
  block phone ↔ Mac).
- **Bug fix:** typed message stayed in the text box after sending (whole message). Known iOS bug with multi-line
  text boxes ignoring `input = ""`. Fix: after sending, swap in a fresh empty box (`.id`) and keep the keyboard
  on it (`@FocusState`). Compiles; **not yet tested on the iPhone**.

---

## 2026-11-19
**Did:**
- **Server switch in the app:** ⚙️ button top right (next to 🔊) opens Settings (`ios/Coco/SettingsView.swift`).
  Server: **Online / My Mac**, saved on the phone (replaces the `useOnlineServer` line in `ChatService.swift`),
  with a live "Connected / Can't reach it" check (`/health`). First launch defaults to **My Mac** (voiceprint tests).
  Compiles; **not yet tested on the iPhone**. Settings will also hold the voice fingerprint.

**Found:**
- Two Xcodes on this Mac: `~/Downloads/Xcode.app` (26.3, the real one) and `/Applications/Xcode.app` (13.4,
  old, "project is damaged"). Terminal builds need `DEVELOPER_DIR=~/Downloads/Xcode.app/Contents/Developer`.

**Decided:**
- Voiceprint will be tested in the app (Settings → Voice fingerprint: record 3 sentences, "Is it me?" test,
  delete), against the Mac server first. Fingerprint screen records WAV (no ffmpeg on the Mac for m4a).

---

## 2026-11-16
**Did:**
- **Voiceprint, step 1 (install, Mac only):** speaker recognition model installed in `server/.venv` and tested.
  Model: SpeechBrain ECAPA (`speechbrain/spkrec-ecapa-voxceleb`, free, ~85 MB, runs offline on our side,
  no audio goes to OpenAI). Smoke test: 3 s of audio → voiceprint of 192 numbers in ~0.45 s on the Mac.
  Model files live in the Hugging Face cache; `server/voiceprint_model/` (links to them) is git-ignored.
  Not in `requirements.txt` yet and not on the server.

**Found:**
- Intel Mac version puzzle (PyTorch stops at 2.2.2). Working set:
  `torch==2.2.2 torchaudio==2.2.2 numpy<2 (1.26.4) scipy==1.17.1 speechbrain==1.0.3 huggingface_hub<1 (0.36.2)
  sentencepiece==0.2.2`.
  - speechbrain 1.1.x needs a newer PyTorch (`torch.amp.custom_fwd` missing) → 1.0.3.
  - speechbrain 1.0.3 + huggingface_hub 2.x → `use_auth_token` error → huggingface_hub < 1.
  - newest sentencepiece has no Intel Mac build → 0.2.2; newest scipy needs numpy 2 → 1.17.1.
  - The Linux server can use current versions; pins there may differ.

**Decided:**
- Voiceprint comes **before** long-term memory and tools.
- Purpose: **only remember the real user.** Coco still answers everyone; each voice message gets a speaker tag
  (`user` / `other` + score); later the memory only saves `user` messages. Typed text counts as the user.
  Before enrollment everything counts as the user.
- Test on the Mac first (enroll ~3 sentences, compare clips of me vs. another voice, pick the threshold),
  then build it into the server + app.

---

## 2026-11-10
**Did:**
- **Online server, step 1–2 (in progress).** Plan: rent server → log in + lock down → Python env + code from
  GitHub + `.env` by hand → keep Coco running (service) → HTTPS → password between app and server → app points
  to the server (Mac address kept as backup).
  - Hetzner Cloud account (2FA on, recovery key stored outside the repo). €25 prepayment to verify the account
    (should show up as credit).
  - SSH key made on the Mac (`~/.ssh/id_ed25519`, with passphrase), public half added to Hetzner as `dafei-mac`.
  - Server `coco`: CX23 (2 vCPU, 4 GB RAM, 40 GB, x86), Ubuntu 26.04, Helsinki, IPv4 + IPv6, €7.13/month.
  - Logged in via SSH as root; installed updates (`apt update && apt upgrade -y`), rebooted for the new kernel.
  - Firewall (`ufw`): only SSH allowed in for now (80/443 come with the HTTPS step). Check: `ufw status`.
  - Password logins off (`/etc/ssh/sshd_config.d/00-coco.conf`: `PasswordAuthentication no`); root only with
    the key (`prohibit-password`). Tested login from a second window. **Step 2 done.**
  - Step 3: `python3-venv` + `git` installed; own limited user `coco` (no login, home `/opt/coco`);
    repo cloned to `/opt/coco/Coco`; `.venv` + requirements (same versions as the Mac, on Python 3.14);
    `.env` with a **separate key `coco-server`** (expires never), file readable only by `coco`.
    Test: `/health` + `/chat` answered on the server (only from inside, firewall still closed). **Step 3 done.**
  - Step 4: systemd service (`server/deploy/coco.service` → `/etc/systemd/system/coco.service`), runs as `coco`,
    only on 127.0.0.1:8000, no `--reload`. Tested: killed on purpose → back in seconds; server reboot → starts
    by herself. Commands: `systemctl status|restart coco`, `journalctl -u coco -f`. **Step 4 done.**
  - Step 5: HTTPS with Caddy (`server/deploy/Caddyfile` → `/etc/caddy/Caddyfile`), address
    `https://65-108-248-13.sslip.io` (free sslip.io name, Let's Encrypt certificate, renews by itself).
    Firewall: 80 + 443 open. **For now only `/health` gets through**; `/chat`, `/speak`, `/transcribe` answer 403
    until the app↔server password (step 6) exists. http → https redirect works. **Step 5 done.**
  - Step 6: app password. Server checks header `X-Coco-Key` on `/chat`, `/speak`, `/transcribe`
    (`server/app/auth.py`, password = `COCO_APP_PASSWORD` in the server's `.env`; not set on the Mac = no check).
    App sends it from `ios/Coco/Secrets.swift` (git-ignored; new checkout → create it, see `ChatService.swift`).
    Server updated via `git pull` + `systemctl restart coco`; Caddy now lets everything through.
    Tested over the internet: no password → 401, with password → chat + speak work. **Step 6 done.**
  - Step 7: app switched to the online server (`useOnlineServer = true` in `ChatService.swift`; `false` = back
    to the Mac). Tested on the iPhone **with Wi-Fi off (mobile data)**: text + voice chat work.
    **Step 7 done → Coco runs online, the Mac can be off.**

**How the server gets new code** (not automatic; Claude does it when asked):
1. Change + test the code on the Mac, commit.
2. Push to GitHub, **only after my OK**.
3. Claude logs in over SSH (`ssh coco`, works because the key's passphrase is in the Mac's Keychain) and runs
   `cd /opt/coco/Coco && sudo -u coco git pull && systemctl restart coco`, then checks `/health` and a test chat.
- The server's `.env` (API key, app password) is never in git; changes to it are made on the server by hand.
- New Python packages → also `sudo -u coco .venv/bin/pip install -r requirements.txt` on the server.

**Hiccup after going online (open):** for a few minutes the app hung on "Coco is thinking…", then showed
"can't reach my brain". The server was fine: those requests never arrived (server log), and the Mac's
first test also timed out once, then everything worked again. Likely a short network or name-lookup
(sslip.io) problem between phone and server. If it happens again: note the time + Wi-Fi or mobile data,
check `journalctl -u coco`. Possible fixes: app retries by itself, shorter wait, own domain instead of sslip.io.
- Bots already knock on the server (`GET /` → 404 in the log): normal for any public server, they can't use
  Coco without the app password.
- `/docs` (FastAPI's test page) is public too; it shows the addresses but can't be used without the password.
  Could be hidden later.

**Found (front end):** the app doesn't need deploying to a server; it runs on the phone. Xcode + cable for now
(7 days). TestFlight / App Store (Apple Developer Program, €99/year) later, when other people should try Coco.
  - Mac: `~/.ssh/config` → shortcut `ssh coco`; passphrase stored in the macOS Keychain
    (`ssh-add --apple-use-keychain`), so Claude can run server commands too.

**How to log in to the server** (from the Mac's terminal):
```
ssh root@65.108.248.13
```
- Works only from a computer with the private key `~/.ssh/id_ed25519` (Hetzner name: `dafei-mac`).
  It asks for the key's passphrase. Passphrase, 2FA recovery key and API key are never written here.
- `root@coco:~#` = you're on the server. `exit` = back to the Mac.
- Lose the key → no way in by SSH; then use the Hetzner Console (web) → server → "Console", or rebuild.
- Hetzner Console: console.hetzner.com, project "Coco", server `coco`.

**Found:**
- Hetzner's create page preselects an expensive type (CPX22 Regular Performance, ~€20/month). Pick it by hand.
- Cost-Optimized servers had run out in Nuremberg and Falkenstein; Helsinki had CX23. Reloading the page resets
  the location.
- Voiceprint ("speaker verification") is possible with open-source models (SpeechBrain ECAPA, Resemblyzer,
  pyannote, 3D-Speaker). Apple doesn't give apps its own speaker recognition, but our own model is allowed.
- PyTorch has no new versions for Intel Macs after 2.2.2 (works with our Python 3.12); on the Linux server
  the newest version works.

**Decided:**
- Deploy now, not wait. The Friday demo still runs from the Mac until the online server fully works.
- Helsinki instead of Germany: still EU (GDPR), and cheap types were available there.
- Voiceprint idea: if we build it, on the server (next to `/transcribe`), not on the iPhone. What Coco should
  do with it (only save memories from the real user? ignore TV/visitors? scam guard?) is still open.
  Voiceprints are biometric data (GDPR / PIPL) → needs consent.

---

## 2026-11-09
**Did:**
- Slides for the first presentation (Fri 13 Nov, due to Dren Thu 4 pm): LaTeX Beamer in
  `docs/slides/presentation_1/coco.tex`. 8 slides: title, problem (Germany + China numbers), Coco as a service
  company (front office / back office hubs, from the proposal), design (architecture + workflow), evaluation
  (user simulator / Coco / judge triangle + three task types), development plan, status (iPhone screenshots),
  what's next (+ GitHub link). Black and white like the app, grey cards, left bar on headlines, panda.
  "Agents as employees" slide hidden for now (`<0>`).
- VS Code: LaTeX Workshop builds on save with pdflatex (settings in `.vscode/`, not in git).
- App screenshots moved from `screenshots/` to `docs/app-pictures/` (README + slides updated).

**Found:**
- TikZ: `step` and `name` are reserved keys, don't use them as style names.
- Building from the terminal doesn't refresh VS Code's PDF tab: close and reopen it.

**Decided:**
- `docs/` (proposal, feedback, slides) is now in the public repo. LaTeX build leftovers stay ignored.
- Cartoon people (Twemoji) instead of photos on the problem slide.

- What's next (until 27 Nov): try GBrain and start building our own LTM system; first simple tools, e.g. reminders.

**Still open:** CLAUDE.md still says "GBrain first, custom module as fallback" (slides now say build our own
alongside); who pays (users/customers) is no longer on any slide since slide 4 is hidden; slides due Thu 4 pm.

**Decided (earlier today):**
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
