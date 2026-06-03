---
name: check
description: Run a Spec axis plus simplify and review on current code, committing any fixes separately
---

Run the post-commit check pipeline. Follow these steps exactly in order. Do not skip steps.

The pipeline has two independent axes, kept separate so neither masks the other:

- **Spec** — does the diff do what was asked, and only that?
- **Code quality** — `@simplify` (reuse/quality) + `@review` (bugs/issues).

## Step 1 — Resolve the Spec source

Determine the intent the diff is meant to satisfy. Resolve in order, first match wins:

1. **Explicit argument** — text or a path passed to `/check` (e.g. `/check "add property alerts link only"`). This always overrides.
2. **The current `in_progress` task** from the live task list, subject to the sync rules below.
3. **Conversation-derived brief** — write a short slice-sized intent statement from the conversation. **Always show it to the user and get a one-line confirm/edit before spawning the Spec agent.**

If none can be derived, note "no spec available", skip the Spec agent, and run the code-quality axis only. Never block the quality pipeline on a missing spec.

### Task-list sync rules (when using source 2)

- **Ambiguity fallback:** if 0 or more than 1 tasks are `in_progress`, or the diff spans multiple tasks, do **not** guess. Fall back to source 3 and state why (e.g. "2 in-progress tasks, can't map to the diff — derived intent from conversation, confirm?").
- **Drift guard (always on):** show the user the task description you are about to hand the Spec agent and let them confirm it still matches the work before spawning. This catches task text that drifted to match the code.
- Note for the user once per session if relevant: tasks should stay `in_progress` through `/check`/`/commit` and be marked `completed` only after the commit lands; if scope changes mid-slice, add a new task rather than rewriting the current one.

The intent brief is **slice-sized** — "this commit should do X and only X" — not epic-sized.

## Step 2 — Spawn all axes in parallel

Send a single message spawning three concurrent agents. Wait for all to return before proceeding.

- `@simplify` — current changed code.
- `@review` — current changed code.
- **Spec agent** (`general-purpose`) — given the resolved intent brief and the diff. Brief: "Here is the intended scope: <brief>. Here is the diff. Report three things, each quoting the relevant line of the intent: (a) asked-for but missing or partial; (b) in the diff but NOT asked for — scope creep; (c) asked-for but implemented wrong. Under 400 words. Do not comment on code style or bugs — that is handled separately."

Skip the Spec agent only if Step 1 found no spec.

## Step 3 — Report

Present two sections, not merged:

- `## Spec` — the Spec agent's findings, lightly cleaned, each quoting the intent line. If skipped, state "no spec available — Spec axis skipped".
- `## Code quality` — synthesise `@simplify` + `@review` yourself: dedupe findings appearing in both, sort by severity (**errors** → **warnings** → **suggestions**), present one prioritised list tagging each item with its source (`simplify` / `review`). Show the full finding for each item — do not truncate or summarise.

## Step 4 — Act on findings

Ask the user: **"Which findings should I fix? (all / list numbers / none)"**

- **Spec scope-creep findings (b):** always list them but flag as *needs your call* — never bundle into auto-fix. Removing code is riskier than a refactor.
- **Spec missing/wrong findings (a, c):** apply only if the user approves.
- **Code-quality errors:** apply if approved. Warnings and suggestions are informational — act only on explicit approval.

For each approved fix:

- Apply the fix
- Run @dod to verify tests and types still pass
- Stage only the changed files and commit as `refactor:` or `fix:` as appropriate

## Step 5 — Summary

Output a single line: findings count per axis (Spec / quality), any commits made, and the worst single issue if any.