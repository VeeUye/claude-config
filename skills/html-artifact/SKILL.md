---
name: html-artifact
description: Generate a polished, self-contained single-file HTML artifact — a data-flow diagram, architecture / mental-model map, sequence or state diagram, dashboard, timeline, or option comparison — matching the established "Anthropic docs" house aesthetic. Use when the user wants to visualize a codebase's data flow or architecture, build a mental model of a system, or create any ad-hoc HTML view to skim or share. Works in any repo: explores the real code when pointed at one, renders offline-safe inline-SVG diagrams, writes the artifact into the Obsidian vault (not the working repo) and opens it in the browser.
---

# HTML artifact (ad hoc)

Emit **one self-contained HTML file** that *views* something — a codebase's data flow, a system's mental model, a comparison, a timeline — in the house aesthetic. Claude is unreasonably good at a single inline HTML file; this skill makes that file consistent and offline-safe wherever you run it.

> **One rule above all:** the artifact is a **derived, read-only snapshot** — never a source of truth. Don't put anything in it that lives nowhere else. It must regenerate from the code/notes/description it views.

## When to use

- "Show me the data flow / request lifecycle in this repo"
- "Give me a mental model / architecture map of `<subsystem>`"
- "Draw the state machine for `<thing>`"
- "Make me a dashboard / timeline / side-by-side comparison of `<…>`"

For a quick inline diagram inside Markdown, prefer a **Mermaid** block instead — it renders natively in most Markdown viewers. Reach for this skill when you want the *polished, interactive, browser-grade* version.

## Workflow

1. **Pin the subject and scope.** What is being visualized, and what kind of artifact (diagram / map / dashboard / timeline / comparison)? If it's vague — "visualize the repo" — ask 1–2 quick questions (which subsystem? what's the question you're trying to answer?) before exploring. Don't boil the ocean.

2. **Get the facts — don't invent.**
   - **Pointed at a code repo:** trace the *real* structure. Find entry points, follow imports/calls/routes, identify the modules and how data moves between them. Read actual files; never guess at architecture. For a large repo, scope to the named subsystem and say what you skipped. (For broad fan-out, an `Explore` subagent can map it first.)
   - **A concept or the user's description:** work from what they give you; ask rather than fabricate specifics.

3. **Pick the layout**, then **generate from the bundled starter shell.** Read `starter-shell.html` in this skill folder and start from it — it carries the whole design system (tokens, serif `h1`, mono labels, layered surfaces, soft shadows, motion, dark mode, print, a11y). For any flowchart / sequence / state / architecture diagram, read `diagrams.md` and hand-author the diagram as **inline `<svg>`**. Bake parsed data into one `const DATA = {…}` near the bottom and render in one pass; hand-author SVG separately.

4. **Write the file — into the Obsidian vault, never the working repo.** Save to `/Users/veeuye/Documents/vee-obsidian-main/_artifacts/<descriptive-name>.html`. That folder is the vault's disposable-view bin: already git-ignored and synced via Obsidian Sync. Do **not** write into the code repo you're exploring or touch its `.gitignore` — keep it clean. (If that vault path ever doesn't exist, ask where the vault is rather than falling back to the cwd.)

5. **Open and report.** `open "<path>"` on macOS (`xdg-open` on Linux). Report the one-line path and offer to open it if you didn't.

## Non-negotiables

1. **Self-contained** — one `.html`. All CSS in `<style>`, all JS in `<script>`, all data as a JS literal. No second file, no assets folder.
2. **Offline, zero network** — no CDN links, no web-font `<link>`, no `fetch()`, no analytics, no external `<img>`. System font stack; inline any SVG/data-URI. The file must render forever, anywhere.
3. **Vanilla everything** — no React, no build step, no npm. Charts and **diagrams are inline `<svg>`** (or `<canvas>`) — never a charting or diagram library. Mermaid's renderer is a CDN dependency, so hand-author SVG (see `diagrams.md`).
4. **Snapshot, stamped** — a footer with provenance: what it was generated from, the date, and that it's a snapshot (not live). Resolve today's date.
5. **Read-only** — no forms that write back, no "save" buttons, no checkboxes implying persistence. Interaction is for viewing (filter, sort, tab, expand).
6. **No secrets** — never bake an API key/token/password into the artifact. If you encounter one in the source, leave it out and flag it.

## Aesthetic

Read `starter-shell.html` and build on it — don't hand-roll a flatter baseline. The family look: ivory paper with white cards, a clay/coral accent (`#d97757`), warm neutral borders; a **serif display `h1`**, **system sans body**, and **monospace for eyebrow/section labels and all diagram text** (that mono-label tell is the "Anthropic docs" feel); depth from layered surface tokens + soft shadows, not heavy borders; olive `--positive` / rust `--negative` used sparingly for status; subtle, purposeful motion wrapped in `prefers-reduced-motion`; light **and** dark via `prefers-color-scheme`; a `@media print` block.

## Gotchas (learned the hard way)

- **Progress-bar / meter fills must be `display:block`.** An inline `<span>` ignores `width`, so the fill renders empty. Give thin slivers a `min-width`.
- **SVG `<marker>` `fill` must be a literal colour**, not `var(--…)` — `var()` in a marker fill is unreliable. Define one marker per colour you need.
- **`[hidden]` loses to an explicit `display`.** If a filtered item is `display:flex/grid`, add an explicit `*[hidden]{display:none}` rule (and unhide it under `@media print`).
- **Prefer a vertical layout for state machines** (states stacked, forward flow down the spine, returns arcing up the side) — it reads cleaner than horizontal once there are return edges.
- **Never embed rich HTML into a Markdown/Obsidian note** — reading views break HTML at blank lines and strip `<style>`/`<script>`. This artifact is opened in a browser.
