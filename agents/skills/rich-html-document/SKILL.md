---
name: rich-html-document
description: Produce a self-contained, rich HTML artifact instead of a Markdown file when the output is meant to be read or shared by humans. Use when generating research reports, company profiles, implementation plans, design specs, exploration documents, status reports, code/PR explainers, or any artifact that will exceed ~100 lines and benefit from diagrams, tables, persona cards, timelines, or visual hierarchy. Trigger phrases include "make an HTML file", "rich document", "spec", "report", "company profile", "design brief", "exploration", "implementation plan", "explainer". Pair with the company-research skill for client profiles.
---

# Rich HTML Documents

Generate HTML artifacts that are easier to read, easier to share, and richer than Markdown for non-trivial outputs.

## Why HTML over Markdown

- **Information density** — tables, SVG diagrams, interactive elements, color coding, expandable sections — none of which Markdown supports well.
- **Readability past 100 lines** — Markdown files >100 lines rarely get read in full. HTML with anchored TOC, sticky sidebar, and visual hierarchy stays usable at 1000 lines.
- **Shareability** — upload to S3 / open locally in a browser. Recipients don't need a Markdown viewer.
- **Spec → review cycle** — colleagues actually read HTML specs. Markdown specs sit in PRs and get skimmed.

## When to use this skill

- Research reports (company profiles, technology deep-dives, competitive analysis)
- Implementation plans with diagrams, data flows, mockups
- Design explorations (multiple options side-by-side)
- PR writeups / code review artifacts
- Status reports, incident post-mortems, weekly summaries
- Concept/feature explainers
- Anything the user wants to share with non-technical stakeholders

## When NOT to use

- Conversation answers (short factual responses)
- Code files (write actual code)
- README files in a code repository (Markdown is the convention; GitHub renders it)
- Throwaway notes the user won't look at again
- The user explicitly asked for Markdown

## Design vocabulary

A consistent palette and type system inspired by Anthropic's research-document style. Use these tokens unless the user has a brand system to match.

```css
:root {
  --ivory:   #FAF9F5;  /* page background */
  --slate:   #141413;  /* headings, strong text */
  --clay:    #D97757;  /* primary accent (highlights, current-state markers) */
  --oat:     #E3DACC;  /* warm soft fill */
  --olive:   #788C5D;  /* secondary accent (success, confirmed) */
  --sky:     #6A8CAF;  /* tertiary accent (info, neutral signal) */
  --rust:    #B04A3F;  /* warning, controversial */
  --gray-100:#F5F4ED;
  --gray-150:#F0EEE6;
  --gray-300:#D1CFC5;
  --gray-500:#87867F;
  --gray-700:#3D3D3A;  /* body text */
  --serif: ui-serif, Georgia, "Times New Roman", serif;
  --sans:  system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
  --mono:  ui-monospace, "SF Mono", Menlo, Consolas, monospace;
}
```

**Typography**
- `h1` — serif, 500, ~44px, letter-spacing -0.015em
- `h2` — serif, 500, ~28px, margin-top 56px (clear section breaks)
- `h3` — serif, 500, ~19px
- `h4` — sans, 600, 13px, uppercase, letter-spacing 0.06em — used for in-card labels
- Body — sans, 15px, line-height 1.65, color `var(--gray-700)`
- Eyebrow / metadata — mono, 10-11px, uppercase, letter-spacing 0.08-0.1em, color `var(--gray-500)`
- Lead paragraph — serif italicized or regular, 18px, max-width 720px

**Layout**
- Body padding `56px 24px 120px`
- `.page` grid: `minmax(0, 1fr) 260px`, gap 56px, max-width 1200px
- Aside is sticky (`position: sticky; top: 32px`)
- Mobile (≤980px) collapses to single column, aside becomes static below main

## Component library

Reuse these for every rich HTML doc. Don't reinvent.

### Stats strip
Grid of small panels showing key numbers (revenue, employees, founded year). Use it once near the top to give readers the gist in seconds.

```html
<div class="stats">
  <div class="stat"><div class="num">1991</div><div class="lbl">Founded</div></div>
  <!-- more stats -->
</div>
```

### Panel
The base card. White background, 1.5px gray border, 14px radius, 22-24px padding. Variants: `.soft` (gray-100 bg), `.tint-clay`, `.tint-olive`, `.tint-sky`.

### Chips
Inline metadata badges. Variants: default, `.clay`, `.olive`, `.sky`, `.rust`, `.solid` (inverted).

### Persona / opportunity card
Used in research outputs. Structure: eyebrow tag, name (serif 18px), owner line (gray-500), then a `dl` of label/value pairs with mono uppercase `dt`s.

### Eyebrow + h2 pattern
Every major section starts with an eyebrow (numbered) above a serif h2. Numbering (`01 · Snapshot`) signals progression and is anchorable for the sidebar TOC.

### Sticky sidebar TOC
A `<aside>` with a `tocbox` containing an ordered list using `counter-increment` for `01`-style numbering and a `keybox` for at-a-glance key facts. Sticky positioned.

### Callouts
`.callout-info` (sky left border, soft sky bg) and `.callout-warn` (rust left border, soft rust bg) for asides that interrupt the main flow.

### Tables
Mono uppercase 10px column headers with gray-100 background, 1px gray-300 row dividers, 13.5px body, 10-12px cell padding. Use `td.good` (olive) and `td.bad` (rust) for status cells.

### Sources block
A `<details>` element with `<summary>` styled as mono uppercase. Inside, a 2-column list of `[Title](url)` links. Always at the bottom; always open by default for research docs.

## SVG diagram patterns

Diagrams should be inline SVG so the file stays self-contained (no external assets, no broken images when shared).

### Timeline
- Horizontal spine at y=180, x=40 → 960 (or your width)
- Era backgrounds as `<rect>` with tinted fills (olive/sky/clay/rust at 6-10% alpha)
- Era labels as mono 10px in the top of each era band
- Event markers: `<circle>` sized 4-7px based on importance, colored by era
- Above each marker: mono 10px date
- Below: serif/sans 11px event description (1-2 lines)

### Org chart / corporate structure
- Top-down hierarchy with `<line>` connectors
- Parent box: filled slate with ivory text
- Subsidiaries: white panels with gray-300 border, 10px radius
- Each box has a mono eyebrow tag at top (e.g., "ACQUIRED 2024")

### Architecture diagram (system map)
- Layer labels (CHANNELS / OPERATIONS / FINANCE / ANALYTICS) at left, mono 9px gray-500
- Nodes are rounded rects with three style variants signalling confidence:
  - **Confirmed** (publicly verified) — olive border + olive 6% fill
  - **Internal** (verified via internal docs / client conversations) — clay border + clay 6% fill
  - **Inferred** (best guess from signals) — gray border, dashed, gray-100 fill
- Edges: 1px gray-500. Use `stroke-dasharray="4 3"` for uncertain connections.
- Legend at top showing the three style variants.

## Page structure (the template)

```html
<!doctype html>
<html lang="en"><head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>...</title>
  <style>/* tokens + components from above */</style>
</head><body>
<div class="page">
  <main>
    <!-- HERO: eyebrow + h1 + lead + meta-row of chips + stats strip -->
    <!-- SECTIONS: each starts with <h2 id="..."> "## · Title" -->
    <!-- SOURCES: <details class="source-block" open> at the bottom -->
    <!-- FOOTER: mono 12px gray-500 with date, author, prep notes -->
  </main>
  <aside>
    <div class="tocbox">
      <div class="label">Contents</div>
      <ol><li><a href="#...">...</a></li></ol>
    </div>
    <dl class="keybox">
      <dt>Key fact</dt><dd>Value</dd>
    </dl>
  </aside>
</div>
</body></html>
```

## Anti-patterns

- **External CSS or images.** Defeats shareability. Inline everything. SVG over `<img>`.
- **JavaScript-heavy interactivity for read-only docs.** A research report doesn't need a build step. If the user needs interactivity (sliders, drag-drop, prompt-tuner), add minimal vanilla JS — no frameworks, no bundlers.
- **Walls of text.** If a section is >5 paragraphs, break it into a panel, a table, or a card grid.
- **Hidden information density.** Don't bury the lead — stats strip near the top, key facts in `keybox`, lead paragraph one-glance summary.
- **Skipping sources.** Research docs without `[claim](url)` inline citations are not trustworthy. Always include the `<details class="source-block">` at the bottom.
- **Vertical overflow on mobile.** Test that `.grid-3` / `.grid-4` collapse to 1-column ≤760px.
- **Default `serif: serif` or `sans: sans-serif`.** Use the explicit `ui-serif, Georgia, ...` / `system-ui, -apple-system, ...` stacks to render well on macOS, Windows, and Linux without webfonts.
- **Markdown-in-disguise.** If your "HTML" is just `<p>` tags and `<h2>` headings with no panels, no SVG, no tables, no cards — you might as well have written Markdown. Use the components.

## Output location

Default to the same folder as related artifacts:
- Client research → `docs/<company-slug>/company-profile.html`
- Implementation plans → `docs/plans/<plan-slug>.html`
- Specs → `docs/specs/<spec-slug>.html`

After writing, tell the user the file path with a clickable markdown link. If you have a preview surface available, the file will show up there automatically.

## Reference output

A complete worked example that uses every component above except the editor and prototyping ones is listed in the private project notes (`~/.config/agent-skills/projects.md`, section "Company research examples"). Copy from it when it is available.

## Inspiration

The design vocabulary is adapted from Thariq's HTML-effectiveness collection: https://thariqs.github.io/html-effectiveness/ — 20 worked examples covering specs, code review, design systems, explainers, status reports, editors, prototypes. When in doubt about what an HTML doc should look like for a given use case, glance at the closest example there.
