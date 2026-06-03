# Global Instructions

## General Rules

- Keep changes minimal and scoped to what was requested. Do not refactor, restyle, or modify files beyond the specific ask. If a file wasn't mentioned, don't touch it.

## Scope Discipline
- When asked to fix or modify a specific page/file, do NOT explore all usages of shared components unless explicitly requested.
- Confirm the target file/scope before making changes to shared components.
- If a change could affect multiple consumers, ask first.

## Investigation Before Action
- For bug reports, investigate the actual root cause before proposing fixes. Avoid speculative guesses (cache clearing, file recreation, invalid characters).
- If unsure, run diagnostic commands (npm install status, file existence checks, URL inspection) before edits.
- Don't read 5+ files exploring when the user has given a concrete bug report — form a hypothesis quickly and verify it.

## Skills & Workflows
- Do NOT auto-invoke TDD or revise-claude-md skills unless the user explicitly requests them.
- When the user asks for a 'report', 'analysis', 'plan', or 'spec', deliver written output — do not start a TDD cycle.
- Trunk-based development with frequent commits is intentional; quality checks live in the DoD.

## Code Style

- No semicolons
- No trailing commas
- No abbreviations in variable names, parameters, or callbacks. Use short descriptive words: `(number)` not `(n)`, `(item)` not `(i)`, `(event)` not `(e)`
- Import ordering (each group separated by a blank line):
  1. Third-party packages (`react`, `next/*`, `classnames`, `@afs/components/*`)
  2. Project-level non-component imports (config, local data, contexts)
  3. Components — ordered by atomic level (atoms → molecules → organisms → templates)
  4. Constants
  5. Sibling/local imports (same directory)
  6. Types
  7. Assets (SVGs, images)
  8. Styles (`styles.module.scss` always last)
- Groups 2–5 form one contiguous block with no blank lines between them
- Blank line after the last import
- Blank line between interface/type definitions and code
- Blank line between groups of related state declarations
- Blank line between each function/handler definition
- Blank line between logical sections within JSX
- No multiple consecutive blank lines

## Pre-Commit

- Always run Prettier and Stylelint before committing. Never commit without formatting checks. Use `npx prettier --write <files>` and `npx stylelint --fix <files>` on changed files.

## Git Workflow

- For git commits: use single-line commit messages (no body) following Conventional Commits format without scope. Do not run lint during commit unless explicitly asked.

## CSS / Styling Conventions

- When fixing CSS issues, investigate the actual cause before applying fixes. Do not assume margin/padding is the problem — check alignment, parent containers, and layout context first. Avoid changing parent component styles unless explicitly asked.
- Use the className pattern for component styling with parent-owned breakpoints. Use CSS custom properties for responsive values. Never use SCSS interpolation for custom property names.

## Testing

- Follow TDD workflow: write failing tests first, then implement minimal code to pass. Do not skip the red-green-refactor cycle. When user says TDD, always start with tests.
- When patching `HTMLElement.prototype` or `Element.prototype` properties in tests, use `Object.defineProperty` with `writable: true` in `beforeAll` and restore to `undefined` with `writable: false` in `afterAll`. Do not use direct assignment (`prototype.x = jest.fn()`).

```ts
beforeAll(() => {
  Object.defineProperty(window.HTMLElement.prototype, 'scrollTo', {
    value: jest.fn(),
    writable: true,
  })
})

afterAll(() => {
  Object.defineProperty(window.HTMLElement.prototype, 'scrollTo', {
    value: undefined,
    writable: false,
  })
})
```

## Development Workflow

When working on features or fixes, follow this order:

1. **Develop** — write code, or use `/tdd` for test-driven development
2. **Check** — run `/check` (simplify → review → dod) or `/commit` which includes checks automatically

Available skills and agents:
- `/tdd` — red-green-refactor development cycle
- `/check` — run simplify + review + dod without committing
- `/commit` — run /check then commit if it passes
- `@review` — code review only
- `@dod` — tests + type checking only
- `@write-test` — generate tests for a file
- `@debugger` — diagnose errors and failures

When in plan mode, ensure the plan includes `/check` or `/commit` as a final step.

## Headless Mode

Batch-fix lint errors or run pre-push validation automatically:
```
claude -p "Fix all TypeScript type errors in src/ — only fix types, don't change logic" --allowedTools "Read,Edit,Bash,Grep"
```

## Agent Memory

Update your agent memory as you discover codepaths, patterns, library locations, and key architectural decisions. This builds up institutional knowledge across conversations. Write concise notes about what you found and where.