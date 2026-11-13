---
name: tempo
description: Log, check or correct the user's Tempo worklogs on Jira tickets. Use for requests like "log 45 minutes on GAI-123", "register 1h on the client calls ticket for yesterday", "what did I log on Monday?" or "move that worklog to Friday". It is also the shared read/write path that zoom-to-tempo and chat-to-tempo build on.
---

# Tempo

Tempo is the time-tracking app inside Jira. Every worklog needs a Jira issue, a date and start time, a duration, a description and a Tempo **account** (the billing bucket). Read and write only the user's own worklogs, through the bundled helper.

## Setup

- **Credentials:** `~/.config/tempo/.env` (owner-only, mode 600) with `TEMPO_API_BASE`, `TEMPO_TOKEN`, `TEMPO_ACCOUNT_ID`, `JIRA_BASE`, `JIRA_EMAIL` and `JIRA_TOKEN`. The helper loads them inside its own process. Never print them, pass them as command arguments, or copy them into chat, files or skill folders.
- **Routing:** `~/.config/agent-skills/tempo-routing.md` is private and kept out of git. It lists each project's calls-and-meetings ticket and Tempo account, plus known recurring meeting titles. Read it whenever you choose a ticket or an account. When the user confirms a new mapping, add a row there.
- If either file is missing, say which one and stop. Don't create credentials.
- Before the first write in a session, read [references/api-access.md](references/api-access.md) for API details, the time-zone trap and recovery steps.

## Helper

```bash
python3 <skill-dir>/scripts/tempo.py identity                  # checks Jira user = Tempo user, shows Jira profile time zone
python3 <skill-dir>/scripts/tempo.py worklogs 2026-11-10 2026-11-14
python3 <skill-dir>/scripts/tempo.py issue GAI-657             # numeric id, summary, status, created
python3 <skill-dir>/scripts/tempo.py accounts
python3 <skill-dir>/scripts/tempo.py save <payload.json>
python3 <skill-dir>/scripts/tempo.py save <payload.json> --update <tempo-worklog-id>
```

`<skill-dir>` is this skill's folder. `save` writes only the configured user's time, refuses a likely duplicate (same date and issue with the same start time or description), then re-reads the saved worklog and checks every field.

## Quick log

A direct request that names a ticket (or an unambiguous project) and a duration, such as "log 45 minutes on GAI-123", is the user's approval. Save it without asking again unless one of the steps below is genuinely ambiguous.

1. **Date:** resolve it as described under *Dates*. The default is today.
2. **Ticket:** for a key, run `issue KEY`. For a description ("the client calls ticket", "the ticket for the cost work"), check the routing file first, then search Jira with whatever is available (an Atlassian connector, or the `jira` CLI). Ask if several tickets fit.
3. **Ticket health:** never log to a canceled ticket. Flag a Done ticket, or one older than about three weeks, unless the routing file lists it as a standing time-tracking ticket.
4. **Account:** use the routing file, then `accounts`. Tempo needs the account **key** (for example `GAI`), not its name. Ask if the account is not clear.
5. **Duration and description:** log the duration exactly as given, in any whole number of minutes. Use the user's words for the description, or write a short factual line from the work at hand. Don't call something a meeting unless it was one.
6. **Duplicates:** read that day's worklogs. If the same work is already there, say so instead of adding it again.
7. **Start time:** use the real time if you know it. Otherwise pick a free slot on that date and say it is a bookkeeping placeholder.
8. **Save:** write one payload to a temporary folder outside any repository, run `save`, then report the date, ticket, account, duration, description, worklog ID and the day's new total.

```json
{
  "issueId": 45049,
  "startDate": "2026-10-29",
  "startTime": "16:59:00",
  "timeSpentSeconds": 2700,
  "description": "Short factual description of the work",
  "attributes": [{"key": "_Account_", "value": "GAI"}]
}
```

## Dates

Every Tempo skill follows these rules.

- Check the current date and time first. Work in Europe/London unless the user says otherwise, and account for daylight saving time. Always state the exact date or dates you are using.
- "Previous working day" means Friday when today is Monday, and yesterday on any other day. Explicit dates or ranges are taken as given, inclusive.
- Keep the agreed date attached to a proposal through follow-up turns. Passing midnight, a later approval or a retry never moves work to another day. If an approval could refer to more than one pending proposal, ask which one.
- Tempo files a worklog under its literal `startDate`, read in the user's **Jira profile** time zone (shown by `identity`). That zone can differ from London. Convert the intended moment into the Jira profile zone before saving, without changing the profile. For a placeholder start time, pick one whose Tempo `startDate` and London date are both the intended day and that doesn't overlap existing entries. For a real meeting time, keep the observed moment, and if it crosses a date boundary, ask rather than shift it.
- After saving, re-read each entry and query the exact `startDate`. Confirm the day's total, issue, account, duration and description. A matching UTC moment alone does not prove the entry landed on the right timesheet day.

## Corrections

Read the existing worklog first, then use `save --update ID`. Fields you don't supply keep their current values. The helper never changes the issue, so moving time to another ticket needs a new entry plus removing the old one in Tempo, which the user must approve. Recheck both affected days afterwards.

## Safety

- After a timeout, a server error or any unclear result, re-read the worklogs before retrying. Never blindly repeat a write.
- Don't set `billableSeconds` or estimates. Without the right permission, Tempo rejects them with a 403.
- Never submit a timesheet for approval unless asked.
- If a write fails verification, stop dependent writes, keep the entries that did verify, and report exactly what state things are in.
