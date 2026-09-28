# Good and Bad Tests

## Good Tests

Test through what the consumer uses: the rendered output and callback props for a component, the return value for a function.

```tsx
// Component: the failure is reached through the network boundary, not a prop
const mockFailedSave = () => {
  globalThis.fetch = jest.fn().mockResolvedValue({
    ok: false,
    status: 500,
    headers: { get: () => 'application/json' },
    json: () => Promise.resolve({})
  })
}

it('shows the error message when the save fails', async () => {
  mockFailedSave()
  setup()

  fireEvent.click(screen.getByRole('button', { name: 'Save' }))

  expect(await screen.findByRole('alert')).toHaveTextContent(
    'We couldn’t save your room'
  )
})
```

The component calls its API function internally and the test controls `fetch`. Don't add a `saveRoom` or `confirmPayment` prop just so a test can swap it — function props are for genuine parent callbacks like `onSubmit` and `onClose`. Third-party SDKs follow the same rule: `PaymentForm` calls `stripe.confirmPayment` itself, and its test uses the Stripe mock in `test/__mocks__/`.

```tsx
// Component: a callback prop is the component's output — asserting on it is testing behavior
it('submits the selected room', () => {
  const onSubmit = jest.fn()
  setup({ onSubmit })

  fireEvent.click(screen.getByRole('radio', { name: stubbedRooms[0].name }))
  fireEvent.click(screen.getByRole('button', { name: 'Continue' }))

  expect(onSubmit).toHaveBeenCalledWith(stubbedRooms[0].id)
})
```

```ts
// Pure function / viewModelBuilder: assert on the returned value
it('returns the notFound variant when the property is archived', async () => {
  const viewModel = await buildViewModel({ ...propertyResponse, isArchived: true })

  expect(viewModel.type).toBe('notFound')
})
```

Characteristics:
- Tests behavior the user or the parent cares about
- Uses the public interface only
- Survives internal refactors — renaming state, splitting into child components, extracting a hook
- Describes WHAT, not HOW
- One behavior per test — several assertions are fine when they describe the same behavior (a heading and its copy on one screen)
- Verb-led name that reads like a specification

## Bad Tests

Implementation-detail tests are coupled to internal structure.

```tsx
// BAD: asserts on a mock of your own child component
jest.mock('../RoomCard', () => () => <div data-testid="room-card-mock" />)

it('renders room cards', () => {
  setup()
  expect(screen.getAllByTestId('room-card-mock')).toHaveLength(3)
})

// GOOD: render the real child and assert what the user sees
it('lists each available room', () => {
  setup()
  expect(screen.getAllByRole('radio')).toHaveLength(stubbedRooms.length)
})
```

```tsx
// BAD: asserts on styling — breaks on a CSS refactor, says nothing about behavior
it('highlights the selected room', () => {
  setup()
  fireEvent.click(screen.getByText(stubbedRooms[0].name))
  expect(screen.getByText(stubbedRooms[0].name)).toHaveClass('selected')
})

// GOOD: assert the accessible state
it('marks the clicked room as selected', () => {
  setup()
  fireEvent.click(screen.getByRole('radio', { name: stubbedRooms[0].name }))
  expect(screen.getByRole('radio', { name: stubbedRooms[0].name })).toBeChecked()
})
```

```tsx
// BAD: only checks the message after the click — passes if it is always shown
it('shows the error after a failed save', async () => {
  mockFailedSave()
  setup()
  fireEvent.click(screen.getByRole('button', { name: 'Save' }))
  expect(await screen.findByRole('alert')).toBeVisible()
})

// GOOD: asserts absence before the trigger
it('shows the error after a failed save', async () => {
  mockFailedSave()
  setup()
  expect(screen.queryByRole('alert')).not.toBeInTheDocument()

  fireEvent.click(screen.getByRole('button', { name: 'Save' }))

  expect(await screen.findByRole('alert')).toBeVisible()
})
```

```tsx
// BAD: rebuilds the expected value with the helper the component uses — circular
expect(screen.getByText(toPricePerWeekLabel(room.price))).toBeVisible()

// GOOD: assert the expected text directly
expect(screen.getByText(`£${room.price} pw`)).toBeVisible()
```

## `fireEvent` or `userEvent`

Use whichever fits the interaction under test. The codebase uses both.

- **`userEvent`** when the component reacts to the sequence a real user produces: typing into an input (per-keystroke handlers, masks, validation on blur), `tab` order and focus, `clear`, hover, `selectOptions`. It fires the full browser sequence — pointer, mouse, focus and click events for a click; keydown, input and keyup for each character typed. Version 14 is async, so always `await` it: `await userEvent.type(input, 'Ada')`. With fake timers, create the instance with `userEvent.setup({ advanceTimers: jest.advanceTimersByTime })` or it will hang.
- **`fireEvent`** when a single event is the whole interaction and the surrounding sequence adds nothing — clicking a button, checking a radio, submitting a form — or for events `userEvent` doesn't simulate, such as `scroll`.

Don't switch a file from one to the other as part of an unrelated change. Match the file unless the interaction needs the other.

## Red Flags

- Mocking your own components, hooks, or contexts
- Exporting a private helper so a test can call it
- Asserting on `className`, inline styles, or snapshots
- Asserting on a mock of your own code — call counts on a callback prop or a boundary are fine
- Reaching into state (hook internals, context values, a child's props) instead of the rendered output
- `getByTestId` where `getByRole`, `getByLabelText`, or `getByText` would work
- Test breaks when refactoring without behavior change
- Test name names a prop, state field, or key instead of the behavior
- Test passes immediately when first written (you never saw it fail)
- "and" in the test name — split it into separate tests
