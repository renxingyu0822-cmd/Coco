# Coco — working diary

Newest entry on top. Short entries: what we did, what we found, decisions, corrections, next.
Public repo: no personal data here.

---

## 2026-11-06
**Did:** repo frame (`ios/`, `server/`, `docs/`, `.gitignore`), git init, pushed to GitHub (public, renamed `coco` → `Coco`).
Added this diary.
**Found:** git doesn't track empty folders. The proposal PDF contains name + student ID → `docs/` is git-ignored (local only).
Claude Code sessions are saved per project folder in `~/.claude/projects/` and can be resumed or searched later.
**Decided:** CLAUDE.md overrides the proposal where they disagree (e.g. evaluation not part of the 13 Nov demo).
**Corrections:** Claude's `sed` edit with a `#` inside broke on macOS and created a junk file that got pushed;
removed in the next commit. Lesson: use exact file edits, not sed, for text with special characters.
(Xcode project was moved into `ios/` by hand before Claude did it.)
**Next:** back end, basic chat endpoint (FastAPI + OpenAI) — waiting for OK + API key.
