# When and How to Mock

## When to Mock

Mock at system boundaries only:
- The network — `fetch` / the HTTP client
- The router — `next/router` (already mocked globally in `test/setup.ts`)
- Time and randomness — `jest.useFakeTimers()`, `jest.setSystemTime()`
- Browser APIs jsdom lacks — `matchMedia`, `IntersectionObserver`, `scrollTo` (patch with `Object.defineProperty`, see CLAUDE.md)
- Third-party SDKs — Stripe, Mapbox, Google Maps, Sentry, analytics

Check `test/setup.ts` before adding a mock — many of these are already global.

## When NOT to Mock

- Your own components — render the real child
- Your own hooks — don't mock them. Test a standalone hook with `renderHook`, or a hook specific to one component through that component
- Your own contexts — wrap the test in the real provider
- Anything else you control

If a test only works when your own code is mocked, the component does too much. Move data fetching and shaping out of it (into the viewModelBuilder or a function that takes its inputs as arguments) instead of mocking around the coupling.

## Callback props are not mocks of your code

A `jest.fn()` passed as a callback prop stands in for the **parent**, not for the component under test. It is how the test observes the component's output, so asserting on it is testing behavior:

```tsx
const onClose = jest.fn()
setup({ onClose })

fireEvent.click(screen.getByRole('button', { name: 'Close' }))

expect(onClose).toHaveBeenCalled()
```

The same goes for boundary mocks whose calls *are* the behavior: the request body sent to `fetch`, or `Sentry.captureException` being called on failure.

## Choosing the boundary

Mock at the lowest level that isolates the external part while keeping the behavior the test needs.

```tsx
// Keep the real API module and mock fetch when the test asserts the request payload
beforeEach(() => {
  globalThis.fetch = jest.fn().mockResolvedValue({
    ok: true,
    status: 200,
    headers: { get: () => 'application/json' },
    json: () => Promise.resolve({})
  })
})

it('sends the guarantor name', async () => {
  setup()
  // ...fill and submit
  const body = JSON.parse((globalThis.fetch as jest.Mock).mock.calls[0][1].body)
  expect(body.guarantor.firstName).toBe(stubbedGuarantor.firstName)
})
```

Include the `content-type` header. `api/httpClient.ts` only calls `json()` when the header says `application/json`; without it the response body silently comes back as `undefined`, and any assertion on what the component shows from the response fails for the wrong reason.

`test/setup.ts` also enables `jest-fetch-mock` globally. Reassigning `globalThis.fetch` as above, as `BookingFormNew` does, replaces it for that test file only. Use the reassignment pattern so the mock's shape is visible in the test.

`jest.mock('<api module>')` is acceptable when the test only cares about the result the component shows, not what was sent. Before mocking a module, ask:
1. What side effects does the real code have?
2. Does this test depend on any of them?
3. If yes — mock lower down (at `fetch`) so those side effects still happen

`jest.spyOn` on a named export of a compiled module can throw `Cannot redefine property` — the export is a non-configurable getter. Use `jest.mock` or mock at `fetch` instead.

## Fixtures and `Partial` in `setup()`

The base fixture is a **complete** object typed as the real type. `setup()` takes `Partial<Props>` so each test overrides only what it cares about, and the override is merged onto that complete base:

```ts
// test-data.ts — complete, typed as the real props
export const stubbedRoomCardProps: RoomCardProps = {
  room: stubbedRoom,
  isSelected: false,
  onSelect: () => {}
}

// index.test.tsx — Partial overrides merged onto the complete base
const setup = (props: Partial<RoomCardProps> = {}) => {
  const initialProps: RoomCardProps = { ...stubbedRoomCardProps }
  const combinedProps: RoomCardProps = { ...initialProps, ...props }
  return render(<RoomCard {...combinedProps} />)
}
```

That is safe because the compiler still checks `combinedProps` against the full type. What is **not** safe is faking completeness with a cast:

```ts
// BAD: the cast hides every missing field — downstream code reads undefined and fails silently
export const stubbedResponse = { status: 'success' } as any
export const stubbedRoom = { id: '1', name: 'Room 1' } as Room

// GOOD: typed, so the compiler lists what's missing
export const stubbedRoom: Room = {
  id: '1',
  name: 'Room 1',
  price: 180,
  availableFrom: '2026-09-01'
}
```

Put named variants (`declinedPaymentResult`, `archivedProperty`) in `test-data.ts` or `test/data/` rather than building big inline overrides in each test. `test-data.ts` holds plain data only — it never calls `jest.*`.

## Warning Signs

- Mock setup is longer than the test logic
- You're mocking your own components or hooks to make the test pass
- A fixture needs `as any` or `as SomeType` to compile
- Test breaks when you change the mock
- You can't explain why a specific mock is needed
- You're mocking "just to be safe"

When mocks get complex, render more of the real tree — it's often simpler.
