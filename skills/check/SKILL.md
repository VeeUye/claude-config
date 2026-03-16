---
name: check
description: Run simplify, review, and DoD checks on current changes without committing
---

Run the full post-development check pipeline. Follow these steps exactly in order. Do not skip steps.

## Step 1 — Simplify

Run the /simplify skill on the current changes. Apply any improvements it suggests.

## Step 2 — Review

Run the @review agent. If any errors are reported, stop and report them. Warnings and suggestions are informational — continue to the next step.

## Step 3 — Definition of Done

Run the @dod agent. Report pass/fail for tests and type checking.

## Step 4 — Summary

Output a single summary of all results from steps 1–3.
