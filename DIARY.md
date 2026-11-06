# Coco — working diary

Newest entry on top. Short entries: what we did, what we found, decisions, corrections, next.
Public repo: no personal data here.

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
