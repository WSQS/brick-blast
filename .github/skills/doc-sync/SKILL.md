---
name: doc-sync
description: Use when the user asks to sync, update, or reconcile documentation with the actual codebase — after refactoring, feature changes, or before a release. Triggers on mentions of docs being stale, out of date, or needing to match reality.
---

Sync every project document against the actual codebase. The agent walks each doc, checks it against source, and fixes discrepancies — no doc left unverified.

## Steps

1. **Inventory the docs.** List every `.md` file at project root and in `docs/`. The canonical set: `README.md`, `CHANGELOG.md`, `copilot-instructions.md`, `docs/decisions.md`, `docs/roadmap.md`, `docs/formal-elements-analysis.md`. Add any other `.md` found. **Completion**: every `.md` file in the repo is on the list.

2. **Read current code state.** Read all files in `script/`, `scene/` node structure (from `.tscn` files), `project.godot` (version, main_scene), and `test/unit/` (count tests, list test files). **Completion**: the agent knows every public function name, every constant, every signal, the test count, and the project version.

3. **Check each doc against reality, fix discrepancies.** Walk the inventory top to bottom. For each doc, the check is specific to what that doc claims:

   - **README.md** — Does every referenced file exist? Are the controls accurate? Is the test count correct? Are the project structure and test command current?
   - **CHANGELOG.md** — Does `[Unreleased]` reflect changes since last tag? Are removed/renamed functions accounted for? Are bug descriptions accurate to the current fix?
   - **copilot-instructions.md** — Are the listed gotchas still true? Do referenced function names still exist? Are conventions up to date?
   - **docs/decisions.md** — Is every "pending" decision still pending? Are "resolved" decisions reflected in code? Do referenced function/variable names match?
   - **docs/roadmap.md** — Are completed items marked done? Are pending items still accurate? Do file references point to existing paths?
   - **docs/formal-elements-analysis.md** — Do status markers (✅/⚠️/❌) match reality? Are "gap" items still gaps?

   Fix in-place with `replace_string_in_file` or `insert_edit_into_file`. **Completion**: every doc has been read and either confirmed accurate or fixed. No doc skipped.

4. **Report.** List what was changed and what was already accurate. **Completion**: a summary of every doc, stating "accurate" or listing fixes applied.
