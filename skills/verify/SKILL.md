---
name: verify
description: >
  Use before claiming work is complete, fixed, or passing. Use before committing,
  creating PRs, or moving to the next task. Triggers: about to say "done", "fixed",
  "all tests pass", or any variation of completion. Also use after delegating to agents —
  verify their output independently.
---

# Verification Before Completion

## Principle

Evidence before claims, always. If you haven't run the verification command and read its output, you don't know the state of the work. Saying "tests pass" without running them isn't a shortcut — it's a guess.

## The Gate

Before claiming any status about the work:

1. **Identify** — What command proves this claim?
2. **Check environment** — Are files saved? Correct branch? No stale build artifacts?
3. **Run** — Execute the full command, fresh, in this message
4. **Read** — Full output. Check exit code. Count failures. Read error messages.
5. **Report** — State what actually happened, with evidence

If the output doesn't support the claim, report what it does show. Accurate status — even "3 tests still failing" — is more valuable than a premature "done."

## Verification Order

Run checks from fastest to slowest. Stop and fix at the first level that fails — no point running the full test suite if the type checker shows errors.

1. **Type checker** — `npm run check-types`
2. **Related tests** — `npx jest --findRelatedTests <changed-files> --forceExit`
3. **Full build** — `npm run build` (only for cross-cutting changes or dependency updates)

Formatting (prettier, stylelint) is handled by filewatchers — don't run these as part of verification unless committing.

## Verification by Claim Type

**Tests pass:**
Run the test command. Look for the summary line. Zero failures means you can say tests pass.

**Build succeeds:**
Run the build command. Check exit code is 0 and output contains no errors. A passing type checker doesn't verify the build — run the actual build.

**Bug is fixed:**
Run the test that reproduces the original symptom. It should pass. If you wrote a regression test, verify the red-green cycle: the test fails without the fix, passes with it.

**Requirements are met:**
Re-read the plan or spec. Walk through each requirement. Verify each one has evidence — a passing test, a visible behavior, a checked output. Report any gaps.

**Agent completed the work:**
Don't trust the agent's success report. Check the actual diff. Run verification yourself. Report what you found, not what the agent claimed.

## Scope of Verification

Match verification depth to the scope of change:

| Scope | Verification |
|---|---|
| Single function fix | Related test file, plus tests covering callers |
| Interface change | Full test suite — interface changes break downstream consumers |
| Cross-cutting refactor | Full test suite, type check, build |
| Dependency update | Full test suite and build |

When in doubt, run more rather than less.

## When Verification Fails

This is normal and expected — it's why you verify.

1. Read the failure carefully. What specifically failed? Is it related to your change or pre-existing?
2. Fix the issue. Don't explain it away or defer it.
3. Re-run verification from the beginning. A fix in one place can break something elsewhere.
4. Report the actual state. "Fixed the type error, all tests pass now" (with evidence) is the right pattern.

Don't report partial progress as completion. "3 of 4 issues fixed, one remaining" is honest and useful. "Should be good now" after fixing 3 of 4 is not.

## Watch For

These phrases in your own output are signals to stop and verify:

- "Should work now" — run the verification
- "Looks correct" — run the verification
- "I'm confident this fixes it" — confidence isn't evidence; run the verification
- "Done!" / "All set!" / "Fixed!" — only after you've seen the passing output
- "The agent reports success" — check the diff and run verification yourself

## The Bottom Line

Run the command. Read the output. Then report what happened. Every time, for every claim, regardless of confidence level.
