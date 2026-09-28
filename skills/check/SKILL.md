---
name: check
description: Run simplify and review on current code, committing any fixes separately
---

Run the post-commit check pipeline. Follow these steps exactly in order. Do not skip steps.

The pipeline runs two code-quality agents, kept separate so neither masks the other:

- `@simplify` — reuse/quality.
- `@review` — bugs/issues.

## Step 1 — Spawn both agents in parallel

Send a single message spawning both agents concurrently. Wait for both to return before proceeding.

- `@simplify` — current changed code.
- `@review` — current changed code.

In the same message, also run the personal SonarJS pass on the changed lines — it is a fast Bash command, not an agent, so run it directly rather than spawning one:

`node ~/tools/sonar-lint/sonar-lint.mjs` from the repo root (advisory — always exits 0, never blocks; scoped to lines you changed).

<!-- personal-only: this sonar-lint step is local to Vee. Do NOT propagate it to the shared claude-workflow repo — colleagues must not be made to run sonar-lint. Strip this step and this comment before syncing check/SKILL.md there. See memory reference_local_sonar_lint. -->

## Step 2 — Report

Synthesise `@simplify` + `@review` + the sonar-lint output yourself: dedupe findings appearing in more than one source, sort by severity (**errors** → **warnings** → **suggestions**), and present one prioritised list tagging each item with its source (`simplify` / `review` / `sonar`). Sonar-lint findings are advisory and never block — rank them as suggestions unless a matching `simplify`/`review` finding raises the severity. Show the full finding for each item — do not truncate or summarise.

## Step 3 — Act on findings

Ask the user: **"Which findings should I fix? (all / list numbers / none)"**

- **Errors:** apply if approved. Warnings and suggestions are informational — act only on explicit approval.
- **Sonar-lint findings:** advisory only — list them but never auto-fix; apply only the ones the user explicitly picks.

For each approved fix:

- Apply the fix
- Run @dod to verify tests and types still pass
- Stage only the changed files and commit as `refactor:` or `fix:` as appropriate

## Step 4 — Summary

Output a single line: the findings count, any commits made, and the worst single issue if any.
