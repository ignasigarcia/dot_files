---
name: company-research
description: Conduct deep online research on a company to build foundational context for a client engagement. Use when starting work on a new tenant/client, when asked to research/profile/investigate a company, or when building a strategic account plan. Trigger phrases include "research [Company]", "deep research on [Company]", "company profile for [Client]", "build context for [Client]", "what do we know about [Company]", "investigate [Company]", "due diligence on [Company]".
---

# Company Research

Build foundational context on a company so future work with that client/tenant is well-informed. The output is a source-cited research artifact saved to the repo.

## When to use

- New client kickoff — before any agent design, build a profile.
- New product/agent inside an existing client — refresh the profile if >6 months stale.
- The user mentions a new company name without context.
- Anyone asks "what do we know about X" where X is an org.

## When NOT to use

- The user asked a narrow factual question ("what's their HQ city") — just search and answer.
- Internal company work (you already have the codebase and its instructions).
- The company is already deeply documented in memory and the user isn't asking for a refresh.

## The 10 dimensions to cover

A complete profile covers all of these. If a section comes up empty, write "Not found via public sources" — never fabricate.

1. **Company overview & history** — legal name(s) and DBAs, founding year/founder/location, HQ + other offices, employee count, revenue (estimates if private — D&B, ZoomInfo, RocketReach), NAICS/SIC, milestones, acquisitions, rebrandings.
2. **Business segments & services** — every distinct service line, industries served, notable projects/clients, geographic footprint.
3. **Ownership & financial structure** — private/public, PE backers, funding rounds, M&A, recapitalizations, debt issuances.
4. **Leadership & key personnel** — every executive and department head with name, title, tenure, prior background. **This is critical for persona modeling.** Especially: CEO, COO, CFO, CTO/CIO, VPs of Sales/Marketing/Ops/Engineering, GMs, IT leaders, marketing leaders, sales-ops owners.
5. **Persona / stakeholder map** — 6-10 archetypes built from the leadership found. Each persona: role, what they care about, what they fear, success metric, systems they own, AI features that would resonate.
6. **Technology footprint** — known systems (ERP, CRM, marketing, HR, comms), job-posting tech signals, digital transformation announcements.
7. **Competitive landscape** — direct competitors verified by region/service, market position, public differentiators.
8. **Recent news** — press releases, acquisitions, leadership changes, awards, controversies, project announcements from the last 2-3 years.
9. **Cultural signals & strategic priorities** — values, mission, ESG, stated priorities, Glassdoor temperature, digital appetite signals, certifications (ISO, safety like TRIR/OSHA VPP).
10. **Why an AI transformation makes sense for them** — synthesized 4-7 concrete opportunities tied to a specific business function, system, and persona, and ideally laddered up to the company's stated strategic priorities or PE value-creation thesis.

## Source playbook

Always consult, in roughly this order. Cite every non-trivial claim with `[anchor text](url)`.

- **Company website** — `/about`, `/leadership`, `/locations`, `/news`, `/press`, `/careers`, industry/service pages, case studies.
- **Wikipedia** — only as a starting point; verify everything via the primary cite.
- **LinkedIn** — leadership profiles, employee count, recent hires/departures, exec posts revealing strategy.
- **Press releases** — PRNewswire, BusinessWire, company news page. Investor exits/entries usually announce here.
- **Trade publications** — for industrial: Crane & Rigging Hot Line, ENR, Breakbulk, Heavy Lift PFI. For other sectors find the equivalent trade press.
- **Aggregators** — D&B, ZoomInfo, RocketReach, Owler, PitchBook, CB Insights, Growjo, Clodura.AI (tech-stack signals).
- **Regulatory** — FMCSA SAFER for trucking, EDGAR for public, OSHA for safety, state SOS for entity records.
- **Glassdoor / Indeed** — culture, recent reviews, management response patterns.
- **Podcasts and conference talks** — leadership-voice signals on strategy/values; revealing for persona work.
- **PE/VC portfolio pages** — the current owner's thesis page often states value-creation strategy explicitly.

## How to execute

For a real research pass, **delegate to a research subagent**. A single deep agent with a comprehensive brief outperforms 20 sequential searches in the main thread:

```
Agent({
  description: "Deep research [Company]",
  subagent_type: "general-purpose",
  run_in_background: true,
  prompt: <comprehensive brief covering all 10 dimensions, with explicit instruction
          to cite every claim and write "Not found via public sources" where empty>
})
```

While that runs, in parallel:
- Read existing memory files for any prior context on the company.
- Fetch reference design assets if producing rich HTML output.
- Set up the output folder: `docs/<company-slug>/`.

After the agent returns, synthesize into the output format below. Do not just paste the agent's report — restructure for the audience and add cross-references to existing project context.

## Output format — produce BOTH markdown and HTML

For any full profile, produce **two files in the same folder**:

1. **`company-profile.md`** — the source of truth. Roughly 3× more token-efficient than HTML when re-loaded in a future session. Easier to diff, easier to update incrementally, lives well in git history.
2. **`company-profile.html`** — the presentation layer for humans and stakeholders. See the `rich-html-document` skill for design vocabulary.

**Process:** write the markdown first (it's the canonical content), then derive the HTML from it. When the profile needs an update later, update the markdown first, then regenerate the HTML.

Save to `docs/<company-slug>/`. Use the existing folder if one exists. If not, create it. For tiny refreshes (a single fact correction), updating just the markdown is fine.

Required structure regardless of format:
1. Hero with eyebrow, title, lead paragraph, key-stat strip
2. Snapshot table (legal entity, HQ, footprint, fleet/scale, NAICS, owner, CEO)
3. Timeline of history & ownership transitions (SVG for HTML)
4. Corporate structure (parent + subsidiaries diagram for HTML)
5. Services & industries
6. Ownership & financial table
7. Leadership tables (C-suite, VPs, Directors)
8. **Persona map** — 6-10 cards
9. Technology footprint with confirmed/internal/inferred distinction
10. Competitive landscape
11. Recent news table
12. Cultural signals
13. **AI opportunities** — each tied to persona × system × business lever
14. Open items / questions for the client
15. All sources, deduplicated, in a collapsible section

## Anti-patterns to avoid

- **Fabricated facts.** Every non-trivial claim must have a source URL. If you can't find it, write "Not found via public sources."
- **Stale claims.** When a memory or aggregator says "current owner is X" but a recent press release shows a recap, trust the press release.
- **Generic personas.** Don't write "Bob the Builder cares about getting jobs done." Tie each persona to a *real named leader* and their *real systems*.
- **Decoupled opportunities.** Every AI opportunity must reference a specific persona, a specific system, and a specific business lever the company is already pursuing.
- **Missing the strategic context.** If the company is PE-owned, find the current owner's portfolio page and read their value-creation thesis. Every opportunity should ladder up to that thesis.
- **Skipping the open-items section.** Some facts can't be public. List them as questions for the client.

## Reference output

The private project notes (`~/.config/agent-skills/projects.md`, section "Company research examples") point to a finished client profile: a canonical Markdown file plus a rich HTML version covering all 10 dimensions, personas and AI opportunities, with every source cited and open items flagged. Use it as a structural template when it is available.

## Memory & follow-up

After producing the profile:
- If your tool keeps a memory, save a `project_<company>_<topic>.md` entry summarizing the most actionable surprises — the open items the client should answer, the PE thesis, the IT contact's reporting line, etc. Don't duplicate the doc — point to it.
- If you discovered something that should change other memory entries (e.g., the user said "their owner is X" but a recap shows it's actually Y), update those entries.
