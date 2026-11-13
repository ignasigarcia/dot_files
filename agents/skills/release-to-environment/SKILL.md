---
name: release-to-environment
description: 'Release code to one named environment end to end. Create or reuse the right pull request, inspect ancestry and the full diff, monitor checks and reviews, merge when authorized, follow the deployment, verify migrations and live health, and report the result. Use for "release to development", "release to staging", "release to production", "release to main", "deploy this to staging" or "ship this to prod". Use release-through-environments for the whole chain, and ship for an ordinary feature-branch PR.'
---

# Release to Environment

Carry one release through to proof that it is running. Neither a merged PR nor a successful build alone counts as a deployment.

## Load the component skills

Read and apply these before acting:

- `company-environment-branches`, for the environment flow, who may approve what, ancestry and merge policy.
- `ship`, for PR inspection, check monitoring and merge verification. Its admin bypass does **not** apply here: follow the merge rules in this skill.
- `aws-monitor-deployment`, whenever AWS CodePipeline or CodeBuild is involved.

Also read the repository's instructions, any deployment skill that clearly applies, and the private project notes in `~/.config/agent-skills/projects.md` (route, pipelines, quirks). Repository instructions can add stricter validation, but they never weaken protected-branch or production safeguards.

## Resolve the target

| Request | Default PR head | PR base | Environment |
| --- | --- | --- | --- |
| `release to development` | current non-environment branch | `development` | development |
| `release to staging` | `development`, or the feature branch on the preview route | `staging` | staging |
| `release to production` / `release to main` | `staging` | `main` | production |

Use the project's verified route; some projects have no active `development` (see the project notes). Use a feature branch directly as the staging head only when the user explicitly asks, for example "release this branch to staging". If the target is missing and can't be inferred safely, ask. Never push directly to `development`, `staging` or `main`.

## Confirm what will ship

Before touching anything, fetch and list what the merge would deploy (`git log --oneline origin/<base>..<head>` and the file diff).

- **Nothing to ship:** say so and stop.
- **Unrelated commits:** list them and confirm the user wants them released, because merging deploys all of them. This is the most common surprise; never skip it.
- **Uncommitted files:** stage only this change's files, by name. Leave local-only files out.

## Execute the release

1. Inspect the checkout, remotes, dirty files and existing worktrees. Preserve unrelated work, and use a separate worktree only when conflict resolution or validation needs writes.
2. Inspect the commit ancestry, the complete file diff and a trial merge. Stop on ambiguous contents, conflicts or unsafe deletions rather than guessing.
3. Run the repository's checks (lint, typecheck, tests). If one fails, find out why before reporting it: failures in generated or git-ignored folders are local noise, not this change. Say plainly which checks passed and which were skipped.
4. Inspect live rulesets, required checks, allowed merge methods, existing equivalent PRs and deployment wiring. Reuse an equivalent open PR. Confirm the target environment's pipeline exists before promising a deploy. If it doesn't, say so: the merge will still land, but nothing will deploy.
5. For a feature release, commit only in-scope changes and push only the feature branch. For an environment promotion, create the PR directly between the protected remote branches. When promoting staging to production, include the staging deployment evidence in the PR.
6. Watch every check to a final state, then recheck the draft state, exact head SHA, mergeability, required approvals, review decision and unresolved review threads.
7. Don't merge with failed or pending checks, conflicts, requested changes or unresolved review blockers, and don't use admin bypass. Resolve a duplicated automated finding only when the identical source finding has a documented, accepted rationale, and repeat that rationale on the promotion PR. Never dismiss a new security concern just to unblock a release.
8. Fetch and recheck source and target immediately before merging. Prefer a merge commit between long-lived environment branches when the rules allow it.
9. Merge into `development` or `staging` on your own only when the user asked for the end-to-end release and every gate is clear. For staging, also confirm the capacity, tester-readiness and release-owner rules in `company-environment-branches`. Verify the merged PR, the merge commit and the updated target branch.
10. Production is a two-step human decision:
    - "Release to production" authorizes creating the `staging` to `main` PR and monitoring its checks.
    - When the PR is clean, present the exact head SHA and the staging evidence, then get a fresh, explicit confirmation immediately before merging into `main`.
    - After confirmation, fetch and recheck again, merge, and continue through production verification.

## Monitor the deployment

1. Find the deployment provider and the exact pipeline from live configuration and the project notes. Don't infer a production account or pipeline from naming alone.
2. Match the deployment run to the merge commit SHA, not merely the newest run. A teammate's later merge may be running ahead of yours, and an older successful run doesn't count. A `Superseded` run means a newer commit overtook yours, so check whether your change actually shipped.
3. If AWS SSO has expired, sign in again and resume. Production may use a different AWS account, so discover the account and role without printing or saving credentials.
4. Follow the pipeline and its build and deploy logs to a final status using read-only operations only. Never start, retry, approve, stop or roll back infrastructure.
5. Report migration evidence and likely error lines. **Never create or run database migrations as part of a release**; only the user creates migrations. For CodeBuild/SST pipelines with no separate Deploy action, require explicit SST completion plus live smoke checks before calling the environment deployed.
6. Verify the running application with the repository's health endpoint or representative public and admin pages. Avoid authenticated or data-changing smoke tests unless explicitly authorized.
7. If the release fails, stop and report the exact failed phase, log evidence and links. Don't change application code under a release request unless the user separately asks for a fix.

## Completion report

Report concisely:

- source branch and SHA, target branch, PR number and URL;
- check and review result, merge method, merge commit;
- pipeline name, account and environment, run ID, and final status;
- build and deploy IDs, migration result, and any errors detected;
- live endpoint results and the final verdict: `DEPLOYED` or `NOT DEPLOYED SUCCESSFULLY`;
- any production confirmation or operational blocker still outstanding.

Don't call the release complete while a requested merge, pipeline, migration or live check is still pending.
