# Refactor Candidates

After the TDD cycle gets you to GREEN, look for these improvements:

- **Duplication** → Extract a component, a hook, or a pure function
- **Long component** → Split into child components (keep tests on the parent's rendered output)
- **Logic in JSX** → Move conditionals and formatting into a pure function or the viewModelBuilder
- **Boolean flag combinations** → A discriminated union with a `type` field
- **`if`/`switch` chains mapping values to values** → A `Record` lookup
- **State derived from other state or props** → Compute it during render instead of syncing it with `useEffect`
- **Prop drilling through several layers** → Composition (pass children) first; context only if that isn't enough
- **Existing code the new code reveals as problematic** → Raise it with the user while you have context

New abstractions — a hook, a context, a shared component — are proposals. Describe the change and ask before introducing one; don't create them unasked during refactor.

## Rules During Refactor

- Never refactor while RED — get to GREEN first
- Run tests after each refactor step
- Don't add behavior during refactor — if you need new behavior, go back to RED
- Keep the public interface stable — refactoring changes internals, not props or return shapes
