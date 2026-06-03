---
name: simple-commit
description: Run DoD checks (prettier, stylelint, tests, types, diagnostics) then stage and commit. No simplify/review agents.
---

Create a git commit for the current changes after running DoD checks. Follow these steps exactly in order. Do not skip steps.

## Step 1 — Identify changed files

Run `git status` (without -uall) and `git diff HEAD` in parallel to identify all changed files.

## Step 2 — Run prettier and stylelint

For each changed `.js`, `.ts`, `.tsx`, or `.json` file, run:
```
node_modules/.bin/prettier --write <file>
```

For each changed `.scss` file, run from the file's directory:
```
node_modules/.bin/stylelint <file> --fix
```

Run all formatting commands in parallel. If any fail, stop and report.

## Step 3 — Run tests and type checking

Run the @dod agent. If tests or type checking fail, stop and report the failures. Do not commit.

## Step 4 — Run diagnostics

Run `mcp__ide__getDiagnostics` on each changed file. Report any `Warning` or `Error` severity findings to the user. Stop and report if there are errors. Do not auto-fix.

## Step 5 — Stage files

Run `git status` (without -uall) again to capture any files modified by formatting.

Stage all relevant changed files using specific file paths. Do not use `git add -A` or `git add .`. Do not stage files that contain secrets (.env, credentials, etc.).

## Step 6 — Write the commit message

Run `git log --oneline -10` to see recent commits for style reference.

Write a single-line commit message following Conventional Commits format:

```
<type>: <short description>
```

### Types

- **feat**: A new feature
- **fix**: A bug fix
- **style**: CSS/SCSS styling changes
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **test**: Adding or updating tests
- **docs**: Documentation only changes
- **chore**: Build process, dependencies, or auxiliary tool changes
- **perf**: Performance improvement
- **ci**: CI/CD configuration changes

### Rules

- Lowercase, imperative mood, no period, under 72 characters
- Single-line only — no body unless the user explicitly requests one
- Do NOT include any `Co-Authored-By` lines
- Do NOT reference Claude, AI, or any AI tool
- Pass the message via HEREDOC

## Step 7 — Verify commit

Run `git status` after committing to verify success.
