---
name: release-through-environments
description: 'Promote one change through the full release chain: create or reuse PRs, wait for checks and reviews, merge, and verify each deployment before proceeding. Use for requests to release through all environments, development to staging to production, or preview to staging to production. Supports projects without development; preserves final human confirmation before merging production.'
---

# Release Through Environments

Carry a named feature branch or existing PR through the project's actual environments. This is the multi-environment workflow; use `release-to-environment` for a single named target and `ship` for an ordinary feature PR. Read the private project notes in `~/.config/agent-skills/projects.md` for each project's known route and quirks. Creating or discussing this skill does not authorize a release.

## Scope and authority

An instruction to run this workflow authorizes creating or reusing the in-scope PRs, merging into development and staging after all gates pass, and monitoring deployments. Do not ask again for those steps. Preserve the user's standing requirement for a fresh confirmation immediately before merging production: prepare the exact production PR and its evidence first, then ask once. After confirmation, revalidate, merge, and monitor production without another permission question.

Respect required GitHub approvals and environment deployment approvals. Never bypass rulesets, use admin merge overrides, self-approve for another reviewer, force-push, reset environments, delete branches, or start/retry/approve/roll back cloud deployments. A release request does not authorize application fixes or migration creation. Preserve dirty checkouts and do not commit unrelated or ambiguous changes.

## Discover the route

1. Read repository instructions. Inspect the remote URL, checkout status, requested branch/PR, live branch refs, rulesets, CI workflows, deployment configuration, and repository release guidance. Confirm authenticated identity and repository permissions. If sandbox networking makes CLI authentication appear invalid, verify with the permitted network execution path before recommending reauthentication.
2. Resolve the complete route from current repository evidence, not the presence of an old branch alone:

   | Active project flow | Sequence |
   | --- | --- |
   | Development environment | feature PR into `development` → development deployment → `development` PR into `staging` → staging deployment/QA → `staging` PR into `main` → production deployment |
   | Preview environment, no active development | feature PR into `staging` → feature preview deployment/validation → staging merge → staging deployment/QA → `staging` PR into `main` → production deployment |

   The project notes record each project's expected route; verify it against current configuration. Do not create or target `development` there just because an obsolete branch exists. Discover alternate branch names from explicit repository configuration rather than inventing them.
3. For this multi-environment request, the repository's verified active route takes precedence over outdated generic defaults in `release-to-environment`, `ship`, or `company-environment-branches`. Retain applicable project protections, staging capacity rules, required QA, and production confirmation.
4. Show the route and candidate briefly. Ask only if the project route, requested candidate, or included release content remains ambiguous. Do not switch local branches just to promote remote environment refs.

## Execute each stage in order

Do not advance until the preceding deployment and validation pass.

1. Fetch source and target refs. Inspect commit ancestry, the complete promotion diff, and mergeability. Look for an equivalent open PR using the exact repository/head/base; reuse it. If already merged, verify the deployed revision before considering the stage complete. If no diff remains, explain the evidence and avoid an empty PR.
2. Inspect the whole release content, not just the original feature PR. If development or staging contains unrelated unreleased work, identify it and obtain scope approval before promoting it. Do not silently release everything accumulated on an environment branch. Stop for conflicts or unsafe deletions and report the blocker.
3. If the candidate is local, validate according to repository instructions before committing/pushing only explicitly authorized, in-scope work. Push feature branches only; never push directly to environment branches. Existing remote PRs do not require a local commit or push. Follow any project-specific package-manager and migration rules from the project notes. Never create or edit migrations; only the user does.
4. Create or reuse the PR with explicit head and base. If your tool can attach a PR to the chat, attach every newly created PR and any existing PR the user asked to work on. Include prior-environment deployment and QA evidence in promotion PR descriptions.
5. Wait for all reported PR checks to finish. Apply GitHub rules to skipped/neutral checks; do not ignore failing optional checks. Require non-draft state, mergeability, all required reviews, no requested changes, and no unresolved actionable review threads. A required human approval is a blocker, not permission to bypass it. If the head changes, restart verification for the new SHA.
6. On the preview route, verify the preview belongs to the exact feature revision and complete relevant validation before merging staging. Respect staging capacity and tester readiness where project policy requires them. Human acceptance cannot be inferred from a successful build or an HTTP 200.
7. Re-fetch and recheck the head, base, rules, checks, reviews, release scope, and prior-environment proof immediately before merging. For development/staging, merge once gates pass. Prefer merge commits between long-lived environment branches when allowed. Do not delete environment branches as cleanup. If the base moves, re-evaluate the merge result and checks; if source content changes, revalidate that content in the preceding environment.
8. Verify GitHub reports the PR merged, record its merge commit, and verify the target ref contains it. Use expected-head protection when the merge API/CLI supports it. Monitor and verify that environment before creating or advancing its next promotion.

## Deployment and health proof

For AWS, read `../aws-monitor-deployment/SKILL.md` and use its read-only monitoring workflow. Discover the correct account/profile, region, pipeline, and execution for each environment; do not assume they are shared. For other providers, use the repository's provider and deployment evidence.

- Correlate the deployment source revision to this stage's merge commit (or exact feature SHA for previews). An older successful run is insufficient. Explicitly trace artifact/source metadata if the provider reports a different revision.
- Wait for the full pipeline and deployment to reach terminal success. Build success alone is insufficient. If deployment occurs inside CodeBuild/SST with no separate deploy action, require explicit SST completion and live smoke checks.
- Record migration completion evidence, or report not observed/not applicable accurately. A started migration is not proof of completion. Never create migrations during a release.
- Verify representative health/public/admin routes and the changed behavior with appropriate nonmutating checks. Use repository QA requirements; distinguish automated smoke results from required human acceptance.
- If superseded, stalled, failed, canceled, unavailable, or uncorrelated, stop advancement and report the exact status, SHA, execution links, and relevant log evidence. Do not retry or repair infrastructure under this workflow.
- Use bounded waits and concise progress updates. Repeated unchanged status is not useful evidence. Preserve completed stages so a resumed run rechecks evidence and continues rather than duplicating PRs or merges. Do not create recurring automation unless asked.

## Production confirmation and completion

Once staging deployment/QA and production PR checks/reviews pass, present the production PR link, exact candidate head SHA, release contents, and staging proof. Ask for the final production merge confirmation and explain that this is the user's standing production rule. A source change after confirmation requires renewed staging validation and confirmation; a target change requires reinspection and fresh applicable checks before proceeding.

After confirmation, merge and monitor production using the same deployment and live verification gates. Do not stop at merge or build success.

Finish with a compact table: environment, PR link, merged/deployed SHA, checks/reviews, deployment execution/result, migration result, and live verification. State which stages completed and the exact outstanding blocker, if any. Call the overall release complete only after production deployment and required validation succeed.

Example invocation: `$release-through-environments PR #328 through production` in Codex, or `/release-through-environments PR #328 through production` in Claude Code. For an existing branch: "release the current feature branch through all environments".
