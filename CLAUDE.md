# Global Instructions

## Code Style

- No semicolons
- No trailing commas
- No abbreviations in variable names, parameters, or callbacks. Use short descriptive words: `(number)` not `(n)`, `(item)` not `(i)`, `(event)` not `(e)`
- Blank line between import groups (third-party, then local)
- Blank line after the last import
- Blank line between interface/type definitions and code
- Blank line between groups of related state declarations
- Blank line between each function/handler definition
- Blank line between logical sections within JSX
- No multiple consecutive blank lines

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

## Agent Memory

Update your agent memory as you discover codepaths, patterns, library locations, and key architectural decisions. This builds up institutional knowledge across conversations. Write concise notes about what you found and where.