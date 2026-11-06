# Coco — working diary

Newest entry on top. Short entries: what we did, what we found, decisions, corrections, next.
Public repo: no personal data here.

---

## 2026-11-06
**Did:** repo frame (`ios/`, `server/`, `docs/`, `.gitignore`), git init, pushed to GitHub (public, renamed `coco` → `Coco`).
Added this diary. Added public `README.md` (based on the proposal, no personal data).
**Found:** git doesn't track empty folders. The proposal PDF contains name + student ID → `docs/` is git-ignored (local only).
Claude Code sessions are saved per project folder in `~/.claude/projects/` and can be resumed or searched later.
**Decided:** CLAUDE.md overrides the proposal where they disagree (e.g. evaluation not part of the 13 Nov demo).
**Corrections:** Claude's `sed` edit with a `#` inside broke on macOS and created a junk file that got pushed;
removed in the next commit. Lesson: use exact file edits, not sed, for text with special characters.
(Xcode project was moved into `ios/` by hand before Claude did it.)
Claude built the whole back end in one go instead of step by step (against CLAUDE.md) → reverted, rebuilding
it together. Lesson: one small step at a time, explain first, wait for OK.
While reverting, a failed `git revert -q` + `--amend` mislabelled a commit locally; fixed before pushing.
Rebuilt the back end step by step: venv + pinned requirements, `.env` (key checked, never printed),
`prompt.py`, `main.py` with `/health` + `/chat`. First reply: "Hello! How are you today?"
**Decided (later):** Coco's tone = warm, cheerful young helper, fond of the person, never babyish.
NOT "like their real child": would blur the AI boundary and raise the dependency risk (instructor question 4).
Coco nudges toward real family instead. Commit locally after each step, push only when asked.
**Next:** behaviour tests (emergency, scam, medical, "are you human?"), then the iOS chat screen.
