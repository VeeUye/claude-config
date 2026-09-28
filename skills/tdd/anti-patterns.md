# Testing Anti-Patterns

Load this when: writing or changing tests, adding mocks, or tempted to add test-only code to production components.

## Anti-Pattern 1: Horizontal Slicing

Writing all tests first, then all implementation.

```
WRONG:
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT:
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
```

Tests written in bulk test imagined behavior, not actual behavior. You end up testing the shape of things (prop names, return shapes) rather than user-facing behavior. Each test should respond to what you learned from the previous cycle.

## Anti-Pattern 2: Adjacent Entries

One test drives one new entry in a context value, reducer, or option object — and the edit adds two or three neighbouring entries too. Only the first had a failing test; the rest are untested code that happened to be nearby.

One `it()` → RED → implement exactly one entry or one branch → GREEN. Proving the extra entries afterwards (break the code, watch a test fail, restore) is a repair, not a substitute — if you keep needing it, the batching has already happened.

## Anti-Pattern 3: Testing Mock Behavior

```tsx
// BAD: Testing that the mock exists
it('renders the sidebar', () => {
  setup()
  expect(screen.getByTestId('sidebar-mock')).toBeInTheDocument()
})
```

You're verifying the mock works, not that the component works. Render the real child or don't assert on it.

See [mocking.md](mocking.md) for detailed mocking guidance.

## Anti-Pattern 4: Test-Only Code in Production

```tsx
// BAD: exported only so the test can call it
export const formatAvailability = (date: string) =>
  `Available from ${new Date(date).toLocaleDateString('en-GB')}`

// BAD: a prop that exists only so the test can force a state
interface Props {
  forceErrorForTesting?: boolean
}
```

Where the helper lives decides how it is tested:
- **A formatter or parser in its own module** (`models/`, `utils/`) is a public interface. Other code imports it, so TDD it directly.
- **A helper co-located in a component file** is private. Drive it through the component and don't export it.

Reach a state through the inputs that really produce it — a fixture variant, a failing `fetch` — not through a prop added for the test. Before adding an export or a prop, ask: "Is this only used by tests?" If yes, don't add it.

`data-testid` attributes are the exception — they are stripped from production builds — but prefer role, label, and text queries anyway.

## Anti-Pattern 5: Mocking Without Understanding

```tsx
// BAD: the module mock replaces the real save, so fetch is never called
jest.mock('../../api/softBookingApi')

it('sends the guarantor name', async () => {
  setup()
  fireEvent.click(screen.getByRole('button', { name: 'Continue' }))

  await waitFor(() => expect(globalThis.fetch).toHaveBeenCalled()) // times out
})
```

Before mocking a module: understand what side effects the real code has, and whether the test depends on any of them. Mock at the lowest level that isolates the external part while preserving the behavior the test needs.

## Anti-Pattern 6: Casting Fixtures Complete

```ts
// BAD
export const stubbedRoom = { id: '1' } as Room
```

A cast hides the fields downstream code reads, and those failures are silent. Type base fixtures as the real type so the compiler lists what's missing. `Partial<Props>` in `setup()` is fine — it's merged onto a complete base. See [mocking.md](mocking.md).

## Anti-Pattern 7: Impossible Fixtures

Inventing a fixture to cover a branch — often one a reviewer flagged — when the backend never produces that state. A test for an impossible state is worse than no test: it documents behavior that can't happen and pins code that should be deleted. Check the state is real; if it isn't, raise it as a design or backend question.

## Anti-Pattern 8: Tests as Afterthought

Implementation complete, no tests written, "ready for testing." Testing is part of implementation. The TDD cycle ensures this by making tests the entry point.

## Anti-Pattern 9: Retrofitting Tests Around Existing Code

Writing tests after the code to "verify it works." Tests written after code pass immediately, and passing immediately proves nothing — the test might verify the wrong thing, test implementation instead of behavior, or miss edge cases. The failing step is what proves the test catches real problems.

## Red Flags

- Asserting on `*-mock` test IDs
- Exports or props only used by test files
- `as any` or `as SomeType` in `test-data.ts`
- Mock setup is more than half the test
- Can't explain why a mock is needed
- "and" in the test name
- Test passes immediately when first written
- Test breaks on refactor but behavior hasn't changed
