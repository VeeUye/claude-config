---
name: figma-to-code
description: "Translates a Figma design into the accommodationforstudents.com website-front-end repo's actual conventions — CSS Modules/SCSS (not Tailwind), gutter()/font() design tokens, cap-height/baseline spacing corrections (the designer measures gaps to letter caps, not line boxes), atomic component structure, SVG sprite icons, Hygen scaffolding. Use ALONGSIDE the official figma-design-to-code skill whenever implementing, building, or porting a Figma design, screen, or component, and whenever text-adjacent spacing doesn't match the design. Trigger phrases: 'implement this Figma design', 'build this from Figma', 'turn this Figma into code', 'code up this screen/component'. Scoped to the website-front-end repo only — see Step 0."
disable-model-invocation: false
---

# Figma → website-front-end

The official `figma-design-to-code` skill (mandatory prerequisite for `get_design_context`) governs *how to call the Figma MCP tools*. This skill governs *what to do with the output*, but only for one specific repo: `website-front-end` (accommodationforstudents.com). It exists because that repo's stack (CSS Modules/SCSS, no Tailwind, sprite-based icons, atomic component hierarchy) has almost nothing in common with the MCP server's default reference output (React + Tailwind).

**Load both skills together.** This one does not replace `figma-design-to-code`'s tool-call workflow or `figma-code-connect`'s `.figma.tsx` mapping workflow — reach for those too when applicable.

## Step 0 — confirm this is the right repo (do this first, every time)

This skill's instructions are hardcoded to one codebase. Before applying anything below, check that the current working directory is actually that repo: read `package.json` and confirm `"name": "website-front-end"` (or check for `generatedFiles/spriteMap.ts` as a secondary signal).

- **Match:** proceed with Steps 1–7 below.
- **No match:** stop applying this skill's repo-specific rules. Fall back to `figma-design-to-code` alone, and ask the user for *this* project's actual conventions (styling approach, token system, component structure, icon handling) rather than assuming website-front-end's — applying these rules to the wrong repo will produce Tailwind-shaped or sprite-shaped code that doesn't fit.

## When to use

- Implementing, porting, or matching a Figma frame/component as real code in `website-front-end`.
- NOT for pushing code back into Figma (`figma-generate-design`) or building a Figma design system from code (`figma-generate-library`).

## Instructions

### 1. Get design context
Follow `figma-design-to-code`: call `get_design_context` on the exact node first. For a large/ambiguous frame, use `get_metadata` to scope down to the right node before fetching context, per that skill's guidance.

Before writing any code, extract a **spacing spec** from the context/metadata you already fetched (don't re-fetch later): every gap and padding you'll implement — its value, the two edges it separates, whether either side is a text node, and for each text node whether it's cap-trimmed (Step 5's detection rule). Working from this table makes the cap-height correction systematic instead of something remembered per-gap.

**Mobile + desktop frame pairs:** when the design ships as two frames, fetch both and build a spacing spec per frame, then diff them — differences hide in heading steps and spacing values, not just layout. Implement mobile-first and put each difference behind `above()`. The switch point usually isn't derivable from the frame widths themselves: copy the breakpoint the surrounding template/sibling components already use, and flag it if there's no precedent. Never implement from one frame and assume the other matches.

### 2. Check for reuse before writing anything new
Before translating the reference output into a new component:
- Check for an existing Code Connect mapping first (`get_code_connect_map`) — it's the cheapest check and definitive: if one exists, use the mapped component directly and stop; don't re-derive it.
- Search `components/atoms/`, `components/molecules/`, `components/organisms/`, `components/templates/` for an existing match.
- Check the sibling `@afs/components` library (resolves from `node_modules`, not the `../component-library` sibling checkout) for a design-system equivalent.
- If nothing exists yet for a component that clearly should have one, flag it — optionally use `/figma-code-connect` afterwards so future syncs are 1:1 instead of re-translated by hand each time.

If the design is a close variant of an existing component, prefer adding a variant/prop over creating a near-duplicate. Ask before duplicating.

### 3. Discard the Tailwind/React reference styling entirely
This repo has no Tailwind. Rebuild the visual layer as `styles.module.scss` (CSS Modules) following the repo's own `.claude/skills/styling/SKILL.md` in full (class naming, banner/section-comment convention, nesting limits, `classnames` for conditionals, etc.) — don't reinvent those rules here.

Scaffold new components with `npm run new` (Hygen) rather than hand-authoring the file layout, so naming, exports, and the `test-data.ts`/story stub already match convention. Then fill in the generated files with the translated markup/styles.

### 4. Map every value to a token — match by resolved VALUE, not Figma's name
Figma's token names diverge from this codebase's, so match by resolved value (hex / px) and use the Figma name only as a tiebreaker.

| Design property | Figma output | This repo |
|---|---|---|
| Colour | hex (e.g. `#3c3a4a`) | `$colour-*` from `@afs/styles` — match by grepping the hex in `node_modules/@afs/styles/settings/settings.palette.scss`, e.g. `#3c3a4a` → `$colour-cool-grey-800`; don't match from memory |
| Spacing | raw px | `gutter(n)`, 8px grid, `gutter(1)` = 8px (fractional OK: `gutter(1.5)` = 12px). Negatives: `gutter(-2)` directly. **Exceptions (leave raw px):** font-size, and any value where the 8-multiple would exceed 100 (`max-width: 800px`) |
| Typography | a size step (Figma often uses Tailwind-ish `sm`/`md`/`lg`) | `@include font('<step>', $responsive-font-size: false)` — non-responsive is this repo's default. Figma's step names do **not** line up 1:1 with this repo's single-letter steps (`s`/`m`/`l`/`xl`…) — confirm against the resolved `font-size` in the frame, don't assume by name. Headings resolve through the separate `@include heading(h1–h6)` tokens (`settings.headings.scss`, responsive min→max size pairs) — match heading sizes there, not in `$font` |
| Breakpoints | frame width | nearest named breakpoint — `xxsmall` 375 / `xsmall` 480 / `small` 660 / `medium` 768 / `large` 960 / `xlarge` 1024 / `xxlarge` 1280 — implemented via `above()`/`below()`/`between()`, never raw `@media` |
| Shadows / timing | effect styles | `shadow()` function; `map-get($core-interactions, 'timing'|'easing'|'transition')` |

If a value doesn't cleanly match any token (a non-8-multiple spacing gap, an off-palette hex), **stop and flag it** rather than silently rounding or inventing a new token. **Exception:** cap-corrected text spacing from Step 5 is intentionally off-grid — keep the computed value; don't flag it and don't round it to a gutter.

### 5. Spacing next to text — measured to the caps/baseline, not the line box
Our designer measures text-adjacent spacing to the **glyph edges** — top of the capital letters, bottom at the **baseline** (descenders intentionally hang into the gap). CSS `gap`/`margin` measures to the **line box**, which extends above the caps and below the baseline, so a Figma value copied raw into CSS renders looser than the design. Never resolve this by nudging pixels against screenshots — screenshot rulers (especially at 2× DPR) are too noisy and have produced bad calibrations. Compute the correction, then verify numerically (Step 7).

**Detect per text node — designers mix both kinds in one frame.** Compare the text node's height (from `get_metadata`/`get_design_context`) to `lines × line-height-px`:
- height = `lines × L` → **untrimmed**: gaps to this node are box-measured. Use the Figma value raw, no correction.
- height smaller (single trimmed line ≈ `0.715 × font-size`) → **vertical-trim on**: gaps to this node are cap/baseline-measured. Correct as below.
- Hand-annotated redline numbers with no node to check: assume cap/baseline-measured (the designer's stated convention).

**Preferred fix: mirror Figma's box structure.** When the design wraps trimmed text in a fixed-height container with centred content (e.g. a 32px-tall text "button"), reproduce that container in CSS (`min-height` + flex centring) instead of compensating the gap. Apax's cap-to-baseline span sits near-centred in its line box (top/bottom offsets differ ≤ 0.6px even at 40px), so centring lands within ~0.5px of the trimmed layout automatically — and preserves the intended tap-target size.

**Otherwise: subtract the per-side offsets.** Apax metrics are identical across regular/medium/bold (from `public/fonts/apax-*.woff`: unitsPerEm 2048, ascent 1772, descent 276, capHeight 1464, so ascent+descent = exactly 1em — re-extract with `woff-metrics.py` in this skill's folder if the brand font ever changes):

- line-box top → cap top: `L/2 − 0.3496 × F`
- baseline → line-box bottom: `L/2 − 0.3652 × F`

(`F` = font-size in px, `L` = line-height in px. Windows vs macOS font-metric differences shift these < 0.2px — ignore.) Precomputed for the `$font` steps at fixed size, default line-height; use the formulas for other variants and for `settings.headings.scss` tokens:

| step | F | L | above caps | below baseline |
|---|---|---|---|---|
| 2xs | 12 | 18 | 4.8 | 4.6 |
| xs | 14 | 21 | 5.6 | 5.4 |
| s | 16 | 24 | 6.4 | 6.2 |
| s · loose | 16 | 25.6 | 7.2 | 7.0 |
| m | 18 | 27 | 7.2 | 6.9 |
| m · loose | 18 | 28.8 | 8.1 | 7.8 |
| l | 20 | 26 | 6.0 | 5.7 |
| xl | 24 | 30 | 6.6 | 6.2 |
| 2xl | 28 | 35 | 7.7 | 7.3 |
| 3xl | 32 | 40 | 8.8 | 8.3 |
| 4xl | 40 | 48 | 10.0 | 9.4 |

Application:
- Text **below** the gap (measured to its caps): `css = figma − aboveCaps(that text)`
- Text **above** the gap (measured from its baseline): `css = figma − belowBaseline(that text)`
- Text on **both** sides (baseline → caps): subtract both
- Responsive font-size makes `F` fluid, so an offset is exact at only one viewport — prefer `$responsive-font-size: false` for cap-critical text; otherwise compute `F` at the Figma frame's width and accept ±1px drift elsewhere.

Worked example: design shows 26px from a button's bottom edge to the caps of an `xs` (14px/21px) support line → `gap: 20.4px` (26 − 5.6). Fractional px is fine (browsers do subpixel layout; paint rounds to the nearest device pixel, ≤ ~0.5px) and the result will usually be off the 8px grid — that's expected; keep the computed value rather than rounding back to a gutter, and record the derivation in the commit message, not as an SCSS comment.

### 6. Icons — override the official skill's asset guidance
`figma-design-to-code` normally says to download-and-commit exported SVG bytes for icons. **In this repo, don't** — icons are rendered through a shared sprite system, and a loose downloaded SVG or hand-written inline `<svg>` bypasses it:

- First check `generatedFiles/spriteIds.ts` (`ICON_IDS_BY_TYPE`) for a matching id. If found, render it with the shared `<Svg type="..." name="..." />` atom (`components/atoms/Svg`) — never author a new one-off icon component.
- If the icon doesn't exist yet: add a `<symbol id="...">` (using the exported path data) to the relevant sheet in `public/media/svg-sprites/<type>.svg`, then run `npm run hash:sprites` to regenerate `spriteMap.ts`/`spriteIds.ts` before referencing it.
- This override is icons only — non-icon imagery (photos, illustrations) follows the official skill's normal download/CDN/props guidance unchanged.

### 7. Validate
- **Spacing: verify numerically, never by measuring screenshots.** In the running app/Storybook, use DevTools `getBoundingClientRect()` on the two elements and confirm the box-to-box distance equals the corrected CSS value from Step 5 — the glyph positions inside those boxes are then guaranteed by the font math. Screenshot rulers (2× DPR, anti-aliasing) have produced provably wrong calibrations; treat any "measured from a screenshot" spacing number as noise.
- **Overall fidelity:** compare the render against the Figma screenshot (official skill's validation step) for colour, hierarchy, and alignment — not for px-level gaps.
- **DoD** on every changed file: `prettier --write`, `stylelint --fix`, `jest --findRelatedTests --forceExit`, `npm run check-types`, and check `mcp__ide__getDiagnostics` for warnings/errors.

## Common edge cases

- **Frame width doesn't land exactly on a named breakpoint** — pick the nearest and state the assumption; don't invent a bespoke breakpoint value.
- **A component looks close to an existing one but isn't identical** — prefer a variant over a near-duplicate; ask before duplicating.
- **No Code Connect mapping for a reused component** — note it and offer to wire one up with `/figma-code-connect` rather than re-deriving the same mapping by hand on every future sync.
- **A design token has no obvious codebase counterpart** — surface both the resolved value and the Figma name, and ask rather than guessing a new token into existence.
