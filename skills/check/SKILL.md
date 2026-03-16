---
name: check
description: Run simplify and review on current code, committing any fixes separately
---

Run the post-commit check pipeline. Follow these steps exactly in order. Do not skip steps.

## Step 1 — Simplify

Run the /simplify skill on the current code. Apply any improvements it suggests.

If simplify made changes, stage only the files it modified and commit as `refactor:` with a descriptive message. Run @dod to verify tests and types still pass before committing.

## Step 2 — Review

Run the @review agent. If any errors are reported, fix them. Stage only the files you fixed and commit as `refactor:` or `fix:` as appropriate. Run @dod to verify tests and types still pass before committing.

Warnings and suggestions are informational — do not act on them.

## Step 3 — Summary

Output a single summary of all results and any commits made.