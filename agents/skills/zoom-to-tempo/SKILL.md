---
name: zoom-to-tempo
description: Reconcile the user's Zoom calls with their Tempo worklogs for a date range, round each call up to 15-minute blocks, and add or correct missing meeting time. Use for "log my meetings from yesterday", "check my calls are in Tempo this week" or "add Monday's Zoom calls". Builds on the tempo skill.
---

# Zoom to Tempo

Find every work call the user attended in a date range, compare it with Tempo, and log what is missing.

**Read the `tempo` skill first.** It owns the credentials, the helper script, ticket and account routing, the date and time-zone rules, and how to save and verify. This skill adds only the Zoom side.

## Sources

- **Zoom is the source of truth.** Use the connected Zoom tools. Codex has them through its Zoom app; Claude Code needs a Zoom connector. Before anything else, check the tools are available. If they aren't, say so and offer two fallbacks: Zoom's web reports in the user's browser (Helium), or calendar events the user pastes.
- Read [references/zoom-access.md](references/zoom-access.md) for the validated search and retrieval steps.
- Always reconcile **both**: meeting history (calls the user hosted) **and** My Notes for the whole range (this includes colleague-hosted calls). Check shared summaries where available. A hosted-meeting report alone is never a complete list of calls.
- Notion Calendar can help find a missing meeting. Verify it against Zoom, because an invitation is not proof of attendance.
- **Pasted calendar events:** treat them as a candidate list. Parse each event's title, start and end, match titles against the routing file, and confirm attendance in Zoom when you can.

## Build the call inventory before writing anything

For each call, record:

- the date and the actual start and end;
- the participants and a brief topic;
- the rounded attendance duration;
- any matching Tempo entry, plus the issue and account it should go to.

Rules:

- A note's listed timestamps may be modified times. Open each relevant note and use its meeting date and time.
- Decide the project from the notes, transcript and participants, never from a generic room name like "Personal Meeting Room". Keep different calls with the same room name separate.
- A long room session may continue after the user left. Don't bill the whole room window when attendance is unclear or overlaps another call. Use the duration the user confirms, or ask.
- If there is a genuine gap in the sources, disclose it rather than declaring the inventory complete.

## Round each call up to 15-minute blocks

The formula is `15 * ceil(minutes / 15)`; exact multiples stay as they are. For example, 19 minutes becomes 30, 26 becomes 30, 60 stays 60, and 79 becomes 90. Use the actual elapsed time when available, falling back to Zoom's reported duration. Never use total participant minutes. Skip solo or test sessions unless the user asks to count them.

## Reconcile and write

- Compare each call against existing worklogs for the same dates and descriptions. Correct a matching entry rather than duplicating it, and leave unrelated worklogs alone.
- Pick the ticket and account from the routing file, and verify them as the `tempo` skill describes. On the security account versus the non-billable account, check the description and account as well as the issue key, because both can share one ticket.
- Ask only about genuinely ambiguous project attribution, or about personal versus work calls. Continue with independent entries while you wait. Counting one mixed personal and technical call once does not make it a rule for future calls.
- A request to add hours authorizes saving the supported worklogs; no extra approval step is needed. Keep actual start times when known. Don't submit the timesheet unless asked.
- **Saving through the Tempo web page instead of the API:** cards and totals can look saved before they are. The save is complete only when the dialog closes and the worklog is still there after a reload. Watch for the required-account check. If the UI lags, read the current state before acting, and never repeat a save whose outcome is unclear.

## Report

Every inventoried work call must end up as one of these: saved, already logged, or explicitly skipped or unresolved with a reason. Finding a colleague-hosted call without logging it does not complete an add-hours request, and a call detected in Zoom is not the same as a call logged in Tempo.

List each saved entry with its date, the call, logged duration, issue, and account (including any sub-project). Then give totals and anything unresolved. Keep the report short.
