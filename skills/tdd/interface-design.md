# Interface Design for Testability

Good interfaces make testing natural. In this codebase the interfaces are props, ViewModels, and function signatures.

## 1. Take inputs as props or arguments, don't reach for them

```tsx
// Testable — the data arrives as a prop, the test controls it
const RoomList = ({ rooms }: RoomListProps) => (
  <ul>
    {rooms.map((room) => (
      <li key={room.id}>{room.name}</li>
    ))}
  </ul>
)

// Hard to test — the component fetches its own data, so every test needs a network mock
const RoomList = () => {
  const [rooms, setRooms] = useState<Room[]>([])

  useEffect(() => {
    getRooms().then((result) => {
      if (result.success) setRooms(result.data)
    })
  }, [])

  return (
    <ul>
      {rooms.map((room) => (
        <li key={room.id}>{room.name}</li>
      ))}
    </ul>
  )
}
```

Server-side data belongs in the viewModelBuilder; the presenter receives the ViewModel as props. Client-side interactions that must call an API (a save, a payment) are fine inside the component — mock them at `fetch`.

## 2. Return values, don't produce side effects

```ts
// Testable — assert on the return value
const toRoomOptions = (rooms: Room[]): RoomOption[] =>
  rooms.map((room) => ({ label: room.name, value: room.id }))

// Hard to test — mutates its input, nothing to assert on
const addRoomOptions = (form: FormState, rooms: Room[]): void => {
  form.options = rooms.map((room) => ({ label: room.name, value: room.id }))
}
```

## 3. Separate decisions from effects

When a handler both decides what to do and does it, testing the decision means driving the whole effect. Split them: a pure function decides (returns a value), and the handler or effect executes it. The viewModelBuilder / presenter split is this rule applied to a whole page — the builder decides which variant to return, the presenter renders it.

```ts
type ErrorState = 'none' | 'invalidField' | 'transientError'

// Decides — a pure function, trivial to test
const toErrorState = (result: ApiVoidResult): ErrorState => {
  if (result.success) return 'none'
  return result.status === 409 ? 'invalidField' : 'transientError'
}

// Executes — thin, tested through the component's rendered output
const handleSubmit = async () => {
  const result = await submitBooking(formState)
  setErrorState(toErrorState(result))
}
```

Only test the pure function directly when it is a genuinely standalone utility (date maths, parsing). If a component test would catch a regression in it, the direct test is redundant.

## 4. Make impossible states unrepresentable

```ts
// Hard to test — eight combinations of flags and data, most of which make no sense
interface Props {
  isLoading: boolean
  isError: boolean
  data?: Room[]
}

// Testable — one test per variant, no impossible combinations to guard against
type ViewModel =
  | { type: 'loading' }
  | { type: 'error'; message: string }
  | { type: 'success'; rooms: Room[] }
```

## 5. Small surface area

- Fewer props = fewer tests needed and simpler fixtures
- Ask: can the component take one object instead of five loose props? Can a prop be derived instead of passed?
- A hook that returns one value or a small object is easier to consume and test than one returning ten setters
