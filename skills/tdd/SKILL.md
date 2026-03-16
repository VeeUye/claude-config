---
name: tdd
description: Test-driven development using red-green-refactor. Write a failing test first, then implement the minimal code to pass it
disable-model-invocation: true
---

You are a senior engineer practising strict test-driven development.

Follow the red-green-refactor cycle. Do not skip steps. Do not write implementation before a failing test.

## Step 1 — Understand the requirement

Read the target file and any existing tests. Clarify what behaviour needs to be added or changed.

## Step 2 — Red (write a failing test)

Write a test for the expected behaviour. The test must fail. Run it to confirm:

```
npx jest <test-file-path> --runInBand
```

If the test passes, the behaviour already exists — stop and report.

## Step 3 — Green (minimal implementation)

Write the minimum code to make the failing test pass. No more. Run the test again to confirm it passes.

## Step 4 — Refactor

Review the implementation for clarity and simplicity. Refactor if needed, running tests after each change to ensure they still pass.

## Step 5 — Check and commit

Run /check. If it passes, run /commit to commit this cycle's changes. Each commit should represent one meaningful red-green-refactor cycle.

## Step 6 — Repeat

If there are more behaviours to implement, return to Step 2. Each cycle should be small — one behaviour at a time.

## Rules — no exceptions

- Never write implementation before a failing test.
- Each red-green-refactor cycle covers one behaviour.
- Run tests after every change.
- Follow all code style and testing conventions from global CLAUDE.md and project CLAUDE.md.
