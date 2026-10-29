# Repository Working Rules

## Modification History

1. Every change to a Git-tracked file in this repository must update `.codex/代码修改记录.md` in the same task.
2. Append new entries in chronological order. Never rewrite or delete previous history; record corrections as new entries.
3. Each entry must include the date/time, purpose, files changed, actual changes, reason, verification, commit or Actions run when available, and remaining risks.
4. If a task has multiple uncommitted edits, keep updating the latest uncommitted entry. Once the work is committed, subsequent edits require a new entry.
5. Updating the history document does not replace required tests or hardware validation.
6. Do not commit `.workbuddy/` or `boards/p224/p224-aio-v1/extras/`, and never flash the donor bootloader file under `extras/`.