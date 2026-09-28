# Deep Modules

From "A Philosophy of Software Design":

A deep module has a small interface and a rich implementation. It hides complexity behind a simple contract.

```
┌─────────────────────┐
│   Small Interface   │  ← Few props, simple return shape
├─────────────────────┤
│                     │
│  Deep Implementation│  ← Complex logic hidden inside
│                     │
└─────────────────────┘
```

A shallow module has a large interface and thin implementation — it exposes complexity instead of absorbing it.

```
┌─────────────────────────────────┐
│       Large Interface           │  ← Many props, many setters
├─────────────────────────────────┤
│  Thin Implementation            │  ← Just passes through
└─────────────────────────────────┘
```

## Design Questions

When designing or refactoring an interface:
- Can I reduce the number of props, or the size of what a hook returns?
- Can I simplify the parameters?
- Can I hide more complexity inside?
- Is this module absorbing complexity or just passing it through?

In React, a deep module is usually a hook or a component that owns its complexity: a `useBasket()` that returns `{ items, add, remove }` and hides the persistence, or a form component that takes one `onSubmit` and manages its own field state. A shallow one forwards a dozen props straight to a child, or returns every internal setter.

## Relationship to TDD

Deep modules emerge during the REFACTOR phase, not during GREEN. During GREEN, write the minimal code to pass the test. During REFACTOR, spot where complexity could sit behind a simpler interface — then propose it to the user rather than introducing a new hook or component unasked. If the public interface is clean and the tests all pass through it, the internals can be restructured freely.
