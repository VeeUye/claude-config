---
name: monday-ticket
description: Create a ticket on the AFS Sprint Board in Monday.com from the current context (a BE ask, a bug, a task). Use when the user wants to raise, create, or file a Monday ticket / Sprint Board item, or turn the current work into a ticket.
argument-hint: Optional — a title or short description of the ticket to create.
---

Create a ticket on the AFS 🏃‍♀️ Sprint Board via the local script. Follow in order.

## The script

`/Users/veeuye/projects/scripts/monday_ticket_create.py` — builds the ticket and (optionally) populates its "Ticket details" doc from a markdown file.

- Auth: reads `MONDAY_API_TOKEN` from the environment. Claude's non-interactive Bash does **not** read `~/.zshrc`, so every invocation must be prefixed with `source ~/.zshrc &&`.
- Board defaults (do not override unless asked): group ✨ Unassigned Tasks, status 🔍 Not Ready to Work On.
- Priority choices (exact strings): `Low`, `Medium`, `High`, `Critical ⚠️️`, `Stretch Goal`.

Usage:
```sh
source ~/.zshrc && python3 /Users/veeuye/projects/scripts/monday_ticket_create.py "<title>" \
  --description "<short plain-text summary>" \
  --priority <Low|Medium|High|...> \
  --due-date YYYY-MM-DD \
  --details <path-to-html-file>
```
All flags except the title are optional. `--details` points at an **HTML** file whose contents are posted as an **update** (comment) on the ticket — the team's normal way of attaching detail. Use it for anything longer than one line (acceptance criteria, a BE vm schema, repro steps).

**Monday updates render HTML, not markdown.** Write the details as HTML and stick to the supported tags: `<h2>`/`<h3>`, `<p>`, `<b>`, `<a href>`, `<ul>`/`<li>`, and `<pre>`. Monday **drops** `<table>` and `<code>` — never use a table. Passing markdown here shows literal `#` and `|` characters in the update.

**For a schema / view-model shape, use a `<pre>` JSON block, not a `<ul>`.** Monday keeps `<pre>` (monospace) but collapses leading spaces, so indent with `&nbsp;` (two per level) and use real newlines. Show each field's type as its value and mark optional keys with a `?` suffix, e.g. `"verified?": "boolean"`. Keep any per-field semantic notes in a `<ul>` below the block.

## Steps

1. **Gather the ticket content from context.** Derive the title, a one-line description, and (for anything non-trivial) a details-doc markdown body from the current conversation. If the user passed an argument, treat it as the title or seed.
2. **Pick a priority** if the context implies one; otherwise leave it unset rather than guessing.
3. **Write the details as HTML** to a file in the scratchpad directory (not the repo). Keep it structured: what's being asked, why, acceptance criteria, and any schema/fields — rendered as a `<pre>` JSON block (see above), never an HTML table (Monday drops tables).
4. **Show the user the drafted title, description, priority, and details body, and get confirmation before running.** Creating a ticket is outward-facing and not easily reversible.
5. **Run the script** with `source ~/.zshrc &&` prefixed. If `MONDAY_API_TOKEN` is missing, tell the user to `source ~/.zshrc` in their shell and stop.
6. **Report the returned ticket id and URL verbatim.** With `--details`, the script prints "Ticket details posted as an update." — confirm that appeared before claiming the detail was attached.

## Notes

- Do not hardcode or echo the token. The script sends it in an in-process request header (via `urllib`), so it never reaches a command line or the process table.
- Overriding `--group`/`--status` needs the raw Monday ids/labels; only do so when the user gives them.
