---
name: aws-search-app-logs
description: Search, tail and troubleshoot application and build logs in AWS CloudWatch across development, staging and production. Use for "check the logs", "tail logs", "any errors?", "why did the cron fail?", "find this error", comparing environments, identifying a failing tenant, project, connector or job, correlating Slack alerts with UTC logs, or telling an application failure apart from a deployment or build failure.
---

# AWS Log Search

Search logs read-only. Treat CloudWatch application logs as runtime evidence. When the question is about CodePipeline, CodeBuild or CodeDeploy, use `aws-monitor-deployment` instead.

## Know the project

Read the private project notes in `~/.config/agent-skills/projects.md`. They give each project's AWS profile, region, app log groups and streams, and build log groups. If a group is unknown, discover it read-only:

```bash
aws logs describe-log-groups --profile PROFILE --region REGION --log-group-name-prefix PREFIX --query 'logGroups[].logGroupName' --output text
```

Build logs usually live at `/aws/codebuild/<pipeline>`.

## Core workflow

1. Confirm `aws` exists, resolve the profile and region, and test `aws sts get-caller-identity --profile PROFILE`. If SSO has expired, run `aws sso login --profile PROFILE` and retry.
2. Start broad across every requested environment, then narrow by log group and time window.
3. Run a summary query first, to find which environment has the signature and its first and latest timestamps.
4. Query the affected environment around one occurrence. Include identifiers and lifecycle messages: queueing, starting, retrying, completion, tenant, project and connector IDs, and folder or path names.
5. Map internal IDs to human-readable names using nearby logs or a read-only database or API query. Don't infer a connector's name from queue order when direct evidence exists.
6. Check nearby successes, and say whether the whole integration is down or a single configuration is failing.
7. Report exact UTC timestamps, and explain any conversion to the user's local or Slack display time.

## Search with the bundled script

```bash
python3 <skill-dir>/scripts/search_app_logs.py --profile PROFILE --groups GROUP1 GROUP2 \
  --search 'Invalid or missing Dropbox credentials' --hours 24 --mode summary

python3 <skill-dir>/scripts/search_app_logs.py --profile PROFILE --groups GROUP1 \
  --search 'Invalid or missing Dropbox credentials' --hours 2 --mode events --limit 100

python3 <skill-dir>/scripts/search_app_logs.py --groups GROUP1 --hours 2 \
  --query-string 'fields @timestamp, @message | filter @message like /Queuing sync for|tenantConnectorId|Job failed/ | sort @timestamp asc | limit 300'
```

Pass `--groups` explicitly. The script's built-in default groups only fit one project and may not all exist.

## Tail and filter with the CLI

Use the non-interactive `aws logs tail` (not the interactive `aws-logs-tail` tool):

```bash
aws logs tail GROUP --profile PROFILE --since 1h --format short
aws logs tail GROUP --profile PROFILE --log-stream-names "/staging/app-stg" --since 1h --format short
aws logs tail GROUP --profile PROFILE --follow --since 5m --format short      # run in the background
```

`filter-log-events` searches every stream in a group. Start and end times are in epoch milliseconds:

```bash
START=$(( ($(date +%s) - 48*3600) * 1000 ))                                 # last 48 hours
START=$(( $(date -j -f "%Y-%m-%d" "2026-03-10" +%s) * 1000 ))                # from a date (macOS)
aws logs filter-log-events --log-group-name GROUP --profile PROFILE --start-time $START \
  --filter-pattern '?ERROR ?Error ?FAILED ?Exception' --query 'events[*].[timestamp,message]' --output text | head -100
date -r $((TIMESTAMP / 1000)) -u                                             # convert a result timestamp
```

Useful filter patterns:

- **Build logs:** use quoted exact phrases, because Docker layer output contains file names like `errors.js`. Examples: `'"State: FAILED"'`, `'"[ERROR]"'`, `'"error TS"'`, `'"Migrating:"'`.
- **App logs:** `"ERROR"`, the broad `"?error ?Error ?Exception ?WARN"`, and `"UnhandledPromiseRejection"`.

## CloudWatch Logs Insights patterns

```text
# Which environment has it, and since when
fields @timestamp, @log, @message
| filter @message like /ERROR_SIGNATURE/
| stats min(@timestamp) as firstSeen, max(@timestamp) as lastSeen, count(*) as matchingLines by @log

# Latest configuration inventory
fields @timestamp, @log, @message
| filter @message like /Found [0-9]+ .* connectors/
| stats max(@timestamp) as lastDiscoveryAt, latest(@message) as lastDiscovery by @log

# Everything around an incident
fields @timestamp, @message
| filter @message like /Queuing|Starting|tenantConnectorId|tenantId|Job failed|completed/
| sort @timestamp asc
| limit 500
```

## Interpretation guardrails

- Pretty-printed Pino errors can produce many CloudWatch records with the same timestamp. `count(*)` counts matching lines, not separate incidents; use first and latest timestamps and lifecycle rows to count runs.
- Payload job retries can repeat the same task every minute and nest earlier error data. Find the original job input and where the retries ended.
- An error missing from staging or production may simply mean those environments have no configured connectors. Check the discovery or inventory rows before calling them healthy.
- `Secret not found` and `Access denied` are different failures. For secrets, inspect names and metadata only, never print values, and confirm the secret path generated at runtime before claiming a secret is missing.
- Stay read-only: CloudWatch `describe`, `filter`, `tail`, `start-query` and `get-query-results`; metadata-only Secrets Manager `list` and `describe`; and read-only database or API queries when needed. Never change jobs, connectors, secrets, deployments or queues.

## Final report

Include:

- a verdict for each environment;
- the failing app or job, and the human-readable tenant, project or connector (plus the internal ID when useful);
- the first and latest occurrence and the retry cadence;
- exact representative log rows;
- evidence from nearby successes, and how far the problem reaches;
- what is confirmed versus what is still inference;
- the safest next action, without doing it unless explicitly asked.
