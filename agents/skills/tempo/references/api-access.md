# Tempo API access

## What has been validated

Read-only calls returned the configured user's worklogs, work attributes and accounts, and confirmed that the Jira identity matches the Tempo user. Creating a worklog through the API, followed by a fresh read and a dated query, has also been validated. Update permissions have not been tested yet, so verify every authorized update.

## Credentials

`~/.config/tempo/.env` is mode 600 and holds `TEMPO_API_BASE`, `TEMPO_TOKEN`, `TEMPO_ACCOUNT_ID`, `JIRA_BASE`, `JIRA_EMAIL` and `JIRA_TOKEN`. Load them only inside the helper process. Keep the values out of chat, shell arguments, logs, skill files and anything committed. Ticket and account routing lives separately in `~/.config/agent-skills/tempo-routing.md`.

The helper refuses to send credentials anywhere except the configured Tempo API host (`api.tempo.io`, or its EU or US variant) and an `https://<site>.atlassian.net` Jira base.

## API facts

- The validated base is `https://api.tempo.io/4`; keep whatever base is configured.
- `GET /worklogs/user/{accountId}` takes inclusive `from`/`to` dates. The helper follows pagination and spaces requests at least one second apart.
- Jira keys resolve through `GET /rest/api/3/issue/{key}` with Basic authentication.
- Tempo requires the numeric Jira `issueId`, never the key.
- This tenant requires the `_Account_` work attribute, whose value is the account **key** (for example `GAI`), not its display name.

## Saving

Put one reviewed payload in a JSON file in a temporary folder outside any repository:

```json
{
  "issueId": 45049,
  "startDate": "2026-10-29",
  "startTime": "16:59:00",
  "timeSpentSeconds": 2700,
  "description": "What was done (for meetings: topic, participants, actual start-end).",
  "attributes": [{"key": "_Account_", "value": "GAI"}]
}
```

```bash
python3 <skill-dir>/scripts/tempo.py save work/entry.json
python3 <skill-dir>/scripts/tempo.py save work/correction.json --update EXISTING_TEMPO_WORKLOG_ID
```

The helper adds the configured author. It accepts any positive whole number of minutes; rounding meetings up to 15-minute blocks is zoom-to-tempo's job. It refuses a possible duplicate on the same date and issue with the same start time or description, but checking for duplicates by meaning is still your job. Corrections keep the existing values and work attributes, then apply the supplied fields; the issue never changes.

**Billable seconds.** Setting `billableSeconds` explicitly, even to 0, returned 403 ("The user does not have permission to set billable hours in destination space"). That is a field-permission failure, not bad authentication. Leave the field out on creation and Tempo applies its default. A non-billable account does not force the raw field to zero. Updates preserve the existing value, so a 403 on update may need the same diagnosis.

## Time zones

The Jira profile time zone, shown by `tempo.py identity`, controls how the API reads `startDate` and `startTime`. With a Los Angeles profile, `startDate=2026-10-29 startTime=17:45:00` was stored as `2026-10-30T00:45:00Z`. Worklogs created in the Tempo web UI used the browser's London time instead.

Before writing real attendance through the API, convert the actual moment into the Jira profile zone, including daylight saving time and possible date changes. Then check that the returned `startDateTimeUtc` matches the intended moment. Don't change the user's profile to work around this. When reconciling a range near midnight, widen the API date query and compare UTC moments inside the requested London window. The helper checks literal fields but does not do this conversion for you.

## Errors and access recovery

On a 401 or 403, read the specific API error first, then check token expiry, scopes and the configured regional base. Use the browser only to inspect or recover access: in Tempo, go to Settings, then Data Access, then API Integration. Reuse existing credentials while they work. If a replacement is truly needed, request the minimum scopes (view, create and update worklogs, plus reading accounts and work attributes), follow the user's credential and approval rules, and store it only in the `.env` file. Validate identity and a dated worklog read before writing anything.

Sources: [Tempo REST API guidance](https://help.tempo.io/kb/latest/different-ways-to-log-work-in-tempo-timesheets), [official OpenAPI schema](https://apidocs.tempo.io/tempo-openapi.yaml).
