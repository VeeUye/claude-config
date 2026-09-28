# Transformation Priority Premise

Refactorings change structure without changing behavior. **Transformations** are the opposite: small changes that make code more general so that a new test passes. The Transformation Priority Premise ranks them from simplest to most complex. Two rules follow from it:

1. **In GREEN, use the highest-priority transformation that makes the test pass.** Changing a constant into a variable is simpler than adding an `if`, and an `if` is simpler than a loop.
2. **When choosing the next test, pick one that can be passed with a high-priority transformation.** A test that forces a jump several rungs down the list is too big a step. Find a smaller test first.

Source, with a worked Roman numerals kata: https://www.codurance.com/publications/2015/05/18/applying-transformation-priority-premise-to-roman-numerals-kata

## The transformations, in priority order

Each transformation is a change from one form of code to a more general one, and every earlier test must still pass after it. The examples show the code before and after.

| # | Transformation | Before → after (TS / React) |
|---|---|---|
| 1 | `{}` → nil — no code at all → code that employs nil | no component → `const RoomList = () => null` |
| 2 | nil → constant | `return null` → `return <p>No rooms available</p>` |
| 3 | constant → constant+ — a simple constant to a more complex constant | `<p>Sold out</p>` → `<p>Sold out <a href="/alerts">Get alerts</a></p>`, when a new test asks for the link |
| 4 | constant → scalar — replacing a constant with a variable or an argument | `<p>Room 1</p>` → `<p>{room.name}</p>`, `'£180 pw'` → `` `£${price} pw` `` |
| 5 | statement → statements — adding more unconditional statements | `onSelect(room.id)` → `onSelect(room.id)` followed by `trackRoomSelected(room.id)` in the same handler |
| 6 | unconditional → if — splitting the execution path | `` `£${price} pw` `` → `` price === null ? 'Price on request' : `£${price} pw` ``, `<Alert />` → `{hasError && <Alert />}` |
| 7 | scalar → array | `const label = 'Single room'` → `const labels = ['Single room', 'Twin room', 'Triple room']` read as `labels[occupancy - 1]`, when a third occupancy would need a second `if` — collapse both branches into the array |
| 8 | array → container | `labels[occupancy - 1]` → `labelsByOccupancy[occupancy]`, where `labelsByOccupancy` is a `Record<number, string>` with keys 1, 2, 3 and 6, when a test needs a six-person flat that the array can't index without padding |
| 9 | statement → recursion | a `<MenuItems>` that renders one level of links → the same component also rendering `<MenuItems items={item.children} />` inside each item, when a test needs nested links |
| 10 | if → while | an `if (remaining >= 10)` block that appends `'X'` and subtracts 10 → the same block as a `while`, when a test needs more than one `X` |
| 11 | expression → function — replacing an expression with a function or algorithm | `` `£${price} pw` `` → `` `${new Intl.NumberFormat('en-GB', { style: 'currency', currency: 'GBP', trailingZeroDisplay: 'stripIfInteger' }).format(price)} pw` ``, when a test needs `£1,250.50 pw` and `£180 pw` must still pass |
| 12 | variable → assignment — replacing the value of a variable | `const total = basePrice` → `let total = basePrice` then `total += bookingFee`; in React, a value fixed for the render → state that changes on a user event, such as `const [selectedRoomId, setSelectedRoomId] = useState<string \| null>(null)` driven by a click test |

The React examples are an adaptation for this codebase. They are not part of the original list. Two of the mappings are judgment calls:
- **`useState` counts as assignment (#12)**, because setting state replaces the value of a variable over time.
- **Rendering a list usually combines two transformations.** Going from `room: Room` to `rooms: Room[]` is scalar → array (#7), and the `.map` that renders it is iteration, which sits with if → while (#10). That is still one test's worth of change when the test is "lists each room". Don't unroll `rooms[0]`, `rooms[1]` to avoid the `.map`, and don't write a "renders the first room" test first to make the step smaller.

Moving an existing expression into a named helper, such as extracting `toPricePerWeekLabel()`, is a refactoring rather than a transformation. It changes structure without making the code more general, so it belongs in the REFACTOR step.

## What the ordering implies in React

- **State is the lowest-priority transformation.** Before adding `useState` (#12), check whether a prop (#4), a conditional (#6), or a value computed during render would pass the test. This is the same rule as "derive, don't sync with `useEffect`".
- **Conditional rendering comes before collections.** If a test can be passed with one `&&` (#6), don't introduce an array (#7) or a lookup (#8) of variants yet. Wait until a later test needs it.
- **Reach for a library call or algorithm (#11) late.** A template string passes most formatting tests. Switch to `Intl.NumberFormat`, date-fns, or sorting when a test needs the more general behavior.

## Constants and fixture-derived assertions

The strictest reading says the first test is passed with a hardcoded constant (#2), and a second test forces constant → scalar (#4). That works well for pure logic: formatters, date maths, viewModelBuilder branching.

For a component that renders a prop as-is, the constant step is usually skipped. Tests here assert against the fixture (`stubbedRoom.name`). A hardcoded `<p>Room 1</p>` would pass only by coincidence, and the only thing that would catch it is a second test whose sole purpose is triangulation. Go straight to `<p>{room.name}</p>`. Use the full ladder when the code **computes** something from its inputs.

## Worked example — a price label

Each block is the whole function after that cycle's GREEN.

Test 1, `it('formats a weekly price')`, expects `toPriceLabel(180)` to return `'£180 pw'`. The transformation is nil → constant, and the argument is not used yet. ESLint will flag the unused `price` until test 2 — that is expected at this step, not something to fix:

```ts
const toPriceLabel = (price: number) => '£180 pw'
```

Test 2, `it('formats a different weekly price')`, expects `toPriceLabel(95)` to return `'£95 pw'`. The transformation is constant → scalar:

```ts
const toPriceLabel = (price: number) => `£${price} pw`
```

Test 2 exists only to force the constant into a variable. Once the general code exists it duplicates test 1, so at REFACTOR fold the two into one `it.each` or delete one of them. Triangulation tests are scaffolding.

Test 3, `it('shows price on request when there is no price')`, expects `toPriceLabel(null)` to return `'Price on request'`. The transformation is unconditional → if:

```ts
const toPriceLabel = (price: number | null) =>
  price === null ? 'Price on request' : `£${price} pw`
```

Adding a `Record` of formats, or a currency lookup, at test 3 would be a lower-priority transformation than the test needs. Leave it until a test demands it.

## When stuck

If no simple change passes the test, either:
- **The test is too big.** Back it out and write a smaller test that a higher-priority transformation can pass.
- **The code needs the next transformation down the list.** Getting stuck often means exactly this: apply the next rung, such as turning an `if` into a `while` or an array into a lookup, rather than piling on more special cases.

A pile of special-case `if`s that each handle one test is the sign that a lower transformation (a loop, a lookup, recursion) has been skipped for too long.
