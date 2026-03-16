---
name: commit
description: Commit current work, then run checks and commit any cleanup separately
---

Create a git commit for the current changes, then run post-commit checks. Follow these steps exactly in order. Do not skip steps.

## Step 1 — Run tests and types

Run the @dod agent. If tests or type checking fail, stop and report the failures. Do not commit.

## Step 2 — Stage files

Run `git status` (without -uall) and `git diff` (staged + unstaged) in parallel to understand the changes.

Stage all relevant changed files using specific file paths. Do not use `git add -A` or `git add .`. Do not stage files that contain secrets (.env, credentials, etc.).

## Step 3 — Write the commit message

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

## Step 4 — Verify commit

Run `git status` after committing to verify success.

## Step 5 — Post-commit checks

Run /check. Any changes made by simplify or review get their own separate commits as `refactor:` or `fix:`.
