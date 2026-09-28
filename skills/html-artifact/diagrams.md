# Diagrams — hand-authored inline SVG

Flowcharts, sequence, state, and architecture diagrams are drawn as **inline `<svg>`** so the artifact stays self-contained and offline. Never use Mermaid or a diagram library in the artifact — their renderers are CDN dependencies. If a source note has a Mermaid block, **reuse it verbatim as the spec** (node names, edge labels, direction) and redraw it as SVG.

## The recipe

- **Wrap the SVG in a white "canvas" card** — `border: 1.5px solid var(--border-strong); border-radius: 14px; background: var(--surface); padding: 28px; overflow-x: auto`. Use `viewBox` + `width: 100%; height: auto` so it scales and prints.
- **Style the SVG with the theme tokens.** Inline SVG inherits CSS custom properties: `fill="var(--surface)"`, `stroke="var(--border-strong)"`, label `fill="var(--fg)"`. Drive node/edge styling through CSS classes in the main `<style>`, not per-element attributes — then it flips light/dark automatically, no second copy.
- **Nodes:** rounded `rect` (`rx: 8`, white fill, `1.5px` border). Terminal / start-end nodes are pills (`rx: 22`, `--surface-2` fill). Decision/gate nodes are diamonds drawn as a `<path>`. Status-tinted nodes use `--positive-soft` / `--negative-soft` fills with the matching border. Node label text is **monospace ~12px**; a secondary sub-label is **~10px `--faint`**.
- **Edges:** `<path fill="none" stroke="var(--faint)" stroke-width="1.5">` (or `<line>`) with a small arrow `<marker>` (`markerWidth/Height: ~7`, `refX` near the tip, `orient="auto-start-reverse"`, triangle `M0,0 L6,3 L0,6 z`). Define **one marker per colour** (default `--faint`, plus `--positive` / `--negative` variants). **A marker's `fill` must be a literal colour, not a `var()`** — `var()` in a marker fill is unreliable. Positive/commit branches go olive (solid), negative/discard branches rust (`stroke-dasharray: 4 4`). Curve branches with a cubic bezier (`C …`); keep the main spine straight; route through gutters to avoid spaghetti.
- **Edge labels:** small **mono ~10px** text at the edge midpoint, coloured to match its edge. If it crosses a line, put it on a `fill="var(--bg)"` backing `rect` so the line doesn't read through it.
- **Hover:** give nodes a `:hover { transform: translateY(-1px) }` lift and `cursor` affordance where interactive.
- **Legend:** add a small legend below the canvas (chips mirroring the node/edge styles) so shapes and colours are self-explaining.
- Keep diagram-specific colours in tokens too (e.g. `--server` / `--client` / `--shared` swimlane accents) so they theme correctly.

## Layout notes by diagram type

- **Flowchart / architecture map:** lay out in **swimlanes** when there are distinct layers (e.g. server / client / shared) — a faint rounded `rect` lane background per column with a mono lane header, nodes stacked inside. Keep cross-lane edges to **adjacent lanes** where possible; long edges crossing a middle lane read as spaghetti — annotate instead.
- **Sequence diagram:** vertical dashed **lifelines** from labelled participant headers; **phase bands** (faint `rect`) group related messages; solid arrows for calls, dashed for returns; self-actions as small inline note `rect`s beside the lifeline.
- **State machine:** prefer a **vertical layout** — states stacked top-to-bottom, forward transitions flowing straight down the centre spine (labels on `--bg` backing rects sitting over the line), and **return/back edges arcing up one side** at staggered depths so they don't tangle. Colour-code by meaning (commit = olive, discard = rust dashed). A self-loop is a small bump on the opposite side.

## Common gotchas

- **Marker `fill` literal**, never `var()` (above).
- Give text `text-anchor="middle"` and position by the node centre, not its origin.
- For diagrams that get exported to PDF, the canvas card already avoids mid-element breaks via the shell's `@media print` `break-inside: avoid`.
