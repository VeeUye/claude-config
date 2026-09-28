---
name: tdd
description: >
  Use when implementing any feature, bugfix, or behavior change — before writing implementation code.
  Triggers: writing new code, fixing bugs, refactoring behavior, adding features, changing interfaces.
  Also use when you notice yourself writing implementation before a failing test exists, or when
  planning how to structure tests. Consult this skill even for "simple" changes — the workflow applies
  to everything except throwaway prototypes, configuration files, and pure styling changes.
---

# Test-Driven Development

## Philosophy

Tests verify behavior through the interface a consumer actually uses. For a component that is what the user perceives (text, roles, accessible names) and what the parent receives (callback props, the network requests it makes). For a hook, a viewModelBuilder, or a pure function it is the return value. A good test reads like a specification: "shows the declined card message when payment fails" tells you exactly what capability exists. These tests survive refactors because they don't care about internal structure — which state variable, which child component, which helper.

Code written without a failing test is exploration. Don't retrofit tests around it — set it aside, write the test, implement fresh from the test. The test needs to fail first so you know it actually catches the absence of the behavior.

See [tests.md](tests.md) for examples of good and bad tests.
See [mocking.md](mocking.md) for when and how to mock.

## Core Rules

1. **No production code without a failing test first.** If the test doesn't fail, you don't know it tests the right thing.
2. **One test at a time (vertical slices).** Write one test, make it pass, repeat. Never write all tests then all implementation — that produces tests coupled to imagined behavior instead of actual behavior.
3. **One entry or one branch per cycle.** Wide surfaces — context values, reducer action unions, option objects, prop interfaces, barrel exports — tempt you to add the neighbouring entries "while you're in the file". Only the entry the failing test drives gets written. Adding a type field and its implementation together is one thing; adding a second field is not.
4. **Tests describe WHAT, not HOW.** Test observable behavior through the public interface. If a test breaks when you refactor internals but behavior hasn't changed, the test was wrong.
5. **Mock at boundaries only.** Mock the network, the router, time, browser APIs jsdom lacks, and third-party SDKs. Don't mock your own components, hooks, or contexts. See [mocking.md](mocking.md).

## Workflow

### 1. Plan

Before writing any code:

- Confirm with the user what interface changes are needed — new props, a changed ViewModel variant, a new hook return shape
- Confirm which behaviors to test and their priority — you can't test everything, so focus on critical paths and complex logic
- Decide which layer owns the behavior: data shaping belongs in the viewModelBuilder or a pure function, rendering in the presenter, interaction state in the component or a hook
- Get user approval on the plan

Ask: "What should the props / ViewModel look like? Which behaviors matter most to test?"

See [interface-design.md](interface-design.md) for interface patterns.
See [deep-modules.md](deep-modules.md) for module design.

### 2. Red-Green Loop

Repeat this loop for each behavior. The first test is a tracer bullet: it confirms one thing and proves the path works end to end, from render or call to assertion.

**RED — Write one failing test**

- One behavior per test
- Verb-led name that describes the behavior, not the prop or state field behind it
- Uses the public interface only — render through `setup()`, query by role/text/label
- Uses real code, not mocks (unless hitting a system boundary)
- Can be passed with a small, high-priority transformation. If passing it would need a jump several rungs down the list (straight to a loop, a lookup, or new state), write a smaller test first. The exception is behavior that is inherently a collection or interaction state — a list, a toggle, a selection. There, one test that needs the `.map` or the `useState` is the right size. See [transformation-priority.md](transformation-priority.md).

Run the test. Confirm:
- It **fails**, not errors. `Unable to find an accessible element with the role "alert"` is a failure. A render crash or a missing provider is an error — the setup is broken, fix that first.
- Jest does not type-check here (`next/jest` compiles with SWC). A type error because the prop, variant, or export doesn't exist yet is the expected RED — add it in GREEN. A type error from a typo or a wrongly shaped fixture is a broken setup.
- The failure message matches what you expect
- It fails because the feature is missing, not because of a typo

When the behavior is "X appears after Y", assert that X is **absent before** Y as well. Otherwise the test passes when X is always shown.

**GREEN — Minimal code to pass**

Write the simplest code that makes the test pass — usually a one-or-two-line delta. Don't add features, don't refactor, don't anticipate future tests. Don't pre-wire wrappers, providers, or overlays until a test demands them: if the test only asserts "renders the room name", minimal green is `<p>{room.roomName}</p>`.

"Simplest" has an order. Prefer the highest-priority transformation that passes: a constant, then a variable or prop, then a conditional, then an array, then a lookup, then recursion or a loop, then a function or algorithm, and reassignment or state last. See [transformation-priority.md](transformation-priority.md).

Run the test. Confirm:
- The new test passes
- All existing tests still pass
- Output is clean — no warnings, no errors, no `act(...)` warnings, no React key warnings

If the new test fails, fix the code, not the test. If other tests broke, fix them now.

### 3. Refactor

After all tests pass, look for improvements:

- Extract duplication into a component, hook, or pure function
- Improve names
- Move logic out of JSX into a pure function, or out of the presenter into the viewModelBuilder
- Replace boolean flag combinations with a discriminated union
- Consider what the new code reveals about existing code

Propose new abstractions (a new hook, context, or shared component) to the user rather than introducing them unasked. Run tests after each refactor step. Never refactor while RED — get to GREEN first.

See [refactoring.md](refactoring.md) for refactor candidates.

### 4. Commit

A behavior is one verb-led `it()` that survives REFACTOR; triangulation tests don't count. Commit with `/commit` when a behavior is complete:
- The code is general — no constant or special case that the next test will replace, and no unused input
- REFACTOR is done
- Scaffolding tests are folded away

Several one-line behaviors on the same component can share a commit if a single subject line still describes them.

Also commit before a refactor you would propose to the user (a new hook, component, or module), so the behavior and the restructure land as separate commits.

Never commit a hardcoded constant standing in for general code. ESLint flags the unused argument at that step; don't silence it with an `_` prefix to get the commit through. If the diff tripwire fires partway through a behavior, the behavior is too big: write the smaller test that closes off part of it, reach a green that meets the conditions above, then commit.

### 5. Repeat

Next failing test for next behavior. Each test responds to what you learned from the previous cycle.

## Checklist Per Cycle

```
[ ] Test describes behavior, not implementation
[ ] Test uses the public interface only (rendered output, callback props, return values)
[ ] Test would survive an internal refactor
[ ] Watched the test fail before implementing
[ ] Failure was for the expected reason (missing feature, not a typo or broken setup)
[ ] Code is minimal for this test — one entry, one branch
[ ] Used the highest-priority transformation that passes
[ ] All tests pass after implementation
[ ] Output is clean (no errors, warnings, act() warnings)
[ ] Committed if the behavior is complete
```

## When Stuck

| Problem | Response |
|---|---|
| Don't know how to test it | Write the assertion first — what should the user see, or what should the parent receive? Then build the test around it. Ask the user. |
| No simple change passes the test | Either the test is too big (write a smaller one) or the code needs the next transformation down the list, such as turning an `if` into a `while` or an array into a lookup. See [transformation-priority.md](transformation-priority.md). |
| Test is too complicated | The design is too complicated. Simplify the props or move the logic into a pure function. |
| Must mock everything | The component does too much. Move data fetching and shaping into the viewModelBuilder or a function that takes its inputs as arguments. |
| Test setup is huge | Extract named fixture variants into `test-data.ts` or `test/data/`. Still complex? Simplify the design. |
| Can't reach the state in jsdom | Check whether the state is real — does the backend ever send it? If not, raise it as a design question instead of inventing a fixture. |
| Bug found in production | Write a failing test that reproduces it, then follow the RED-GREEN cycle. Never fix bugs without a test. |
| The change is purely visual (spacing, colour, layout) | Skip TDD — jsdom can't assert layout. Make the change and still run the related tests. Different **content** per breakpoint (a mobile-only menu, a collapsed section) is behavior: test it with `resizeWindow()` from `test/helpers/resizeWindow.ts`. |

## Reference Documents

Load these as needed:

- **[tests.md](tests.md)** — Examples of good and bad tests, red flags to watch for
- **[mocking.md](mocking.md)** — What counts as a boundary, callback props, fixtures and `Partial` in `setup()`
- **[interface-design.md](interface-design.md)** — Props, ViewModels, and separating decisions from effects
- **[deep-modules.md](deep-modules.md)** — Deep vs shallow hooks and components
- **[transformation-priority.md](transformation-priority.md)** — Which change to make in GREEN, and which test to write next
- **[refactoring.md](refactoring.md)** — What to look for in the refactor phase
- **[anti-patterns.md](anti-patterns.md)** — Common testing anti-patterns and how to avoid them
