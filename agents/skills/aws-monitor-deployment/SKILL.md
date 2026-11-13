---
name: aws-monitor-deployment
description: Monitor AWS releases read-only, from CodePipeline through CodeBuild and CodeDeploy. Check build status, tail and analyze CloudWatch build logs, verify that migrations ran, track deploy targets, and report whether the application actually deployed. Use for "monitor/watch/follow the deploy", "is the build done?", "check build status", "why did the build fail?", "tail the build logs", or any pipeline, CodeBuild, CodeDeploy or migration question.
---

# AWS Deployment Monitor

Monitor releases read-only, with CodePipeline as the source of truth. Use CodeBuild logs for diagnostics and migration evidence. Don't call a release deployed until the pipeline's deploy action succeeds.

## Know the project

Read the private project notes in `~/.config/agent-skills/projects.md`. They list each project's AWS profile, region, pipeline names, deploy stages and migration evidence. Treat them as defaults and verify with read-only discovery when a name isn't found. The usual conventions are:

- Pipelines are named `<repo>-<dev|stg|prd>`. The CodeBuild project shares the pipeline's name.
- The CodeBuild source is `CODEPIPELINE`, so only the pipeline starts builds.
- Not every repository has all three environments. If the pipeline for the requested environment doesn't exist, say so instead of substituting another one.

To discover names, derive the repository from `git remote get-url origin`, then run:

```bash
aws codepipeline list-pipelines --profile PROFILE --region REGION --no-paginate --query "pipelines[].name" --output text
aws codebuild list-projects --profile PROFILE --region REGION --output text
```

Prefer an exact environment suffix. Don't infer production from an ambiguous name when several candidates exist.

## Core workflow

1. Confirm the AWS CLI exists, resolve the profile and region, and test `aws sts get-caller-identity --profile PROFILE`. If SSO is missing or expired, run `aws sso login --profile PROFILE`, let the user finish the browser sign-in, and retry.
2. Resolve the pipeline name from the project notes or by discovery. Ask only if several plausible pipelines remain.
3. Run `scripts/monitor_pipeline.py`. It picks the latest active run, follows each action, tails the linked CodeBuild log, analyzes the complete build log, monitors any linked CodeDeploy deployment, and exits only when the pipeline reaches a final status.
4. Give short phase updates while it runs. At the end, report the pipeline, build, migration, error and deployment results.

```bash
python3 <skill-dir>/scripts/monitor_pipeline.py --profile PROFILE --pipeline PIPELINE
python3 <skill-dir>/scripts/monitor_pipeline.py --pipeline PIPELINE --wait-for-start 600   # wait up to 10 minutes for the next run
python3 <skill-dir>/scripts/monitor_pipeline.py --pipeline PIPELINE --execution-id UUID    # follow one known run
python3 <skill-dir>/scripts/monitor_pipeline.py --pipeline PIPELINE --login                # sign in first
python3 <skill-dir>/scripts/monitor_pipeline.py --pipeline PIPELINE --from-start           # replay the whole build log
```

The visible tail starts with the last 120 seconds; change that with `--since SECONDS`. The final error and migration analysis always scans the complete log. When a release just merged, pick the run whose source revision equals the merge commit SHA, not simply the newest run.

## Quick build check

When the user only wants a build's status or logs, not the whole release, use `scripts/monitor_codebuild.py --profile PROFILE --project PROJECT`, or the CLI directly:

```bash
BUILD_ID=$(aws codebuild list-builds-for-project --project-name "$P" --profile PROFILE --region REGION --no-paginate --query "ids[0]" --output text)
aws codebuild batch-get-builds --ids "$BUILD_ID" --profile PROFILE --region REGION \
  --query "builds[0].{status:buildStatus,phase:currentPhase,start:startTime,end:endTime,src:resolvedSourceVersion}" --output table
aws logs get-log-events --log-group-name "/aws/codebuild/$P" --log-stream-name "${BUILD_ID##*:}" \
  --profile PROFILE --region REGION --query "events[-40:].message" --output text
```

- The build phases run in this order: `SUBMITTED`, `QUEUED`, `PROVISIONING`, `DOWNLOAD_SOURCE`, `INSTALL`, `PRE_BUILD`, `BUILD`, `POST_BUILD`, `UPLOAD_ARTIFACTS`, `FINALIZING`, `COMPLETED`.
- On failure, pull the last 80 or so lines and find the real error. Common causes are `exit status 1`, `OOMKilled`, `TIMED_OUT`, missing native binaries and migration errors.
- A successful build is never proof that the application deployed. Check the parent pipeline afterwards.

## AWS CLI traps

- **Always add `--no-paginate` when `--query` indexes a list.** The CLI applies `--query` per page, so `--query "ids[0]"` can return one ID per page. That multi-line value then breaks `batch-get-builds`, log stream names, and comparisons in wait loops, which then exit instantly or never match.
- `--no-paginate` and `--max-items` can't be combined. Limit results with a slice such as `[:5]` instead.
- The log stream name is the **UUID after the colon** in the build ID, not the whole ID.
- In a wait loop, require the status to be non-empty **and** not `IN_PROGRESS`, and poll every 45 to 90 seconds. Builds take minutes, so tighter polling is wasted.

## Interpret migrations

- Report `SUCCEEDED` only with explicit completion evidence, or a successful chained command that clearly continued past the migrations. The project notes record what each project's success line looks like.
- Report `OBSERVED - completion not proven` if migration output starts without a trustworthy completion signal.
- Report `NOT OBSERVED` if the log has no migration evidence. Silence is not success.
- Treat migration-related error, failure, fatal, exception or non-zero exit output as a release concern, even when another status looks healthy.

## Final summary

Always include:

- pipeline name, run ID, final status and source revision;
- CodeBuild status and build ID;
- migration status with up to three short evidence lines;
- likely CodeBuild error lines, or `none detected`;
- each deploy action's status and external deployment ID, plus CodeDeploy target counts where relevant;
- a verdict: `DEPLOYED`, `NOT DEPLOYED SUCCESSFULLY`, or `PIPELINE SUCCEEDED, BUT NO DEPLOY ACTION WAS VERIFIED`.

Don't dump whole logs. Separate warnings from likely errors, and say where you are uncertain.

## Safety

Use read-only AWS commands only. The bundled scripts enforce an exact allowlist of `get`, `list` and log-read operations and refuse everything else. Never retry, stop, start, approve, roll back, update or delete any AWS resource, even if a later prompt loosely asks to "fix" a deployment. `aws sso login` refreshes local sign-in only and changes no deployment resources.
