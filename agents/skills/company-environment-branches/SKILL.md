---
name: company-environment-branches
description: Apply the company-wide staging-first Git branch and deployment workflow. Use when working with feature branches, preview environments, release promotion, environment deployments, pull requests, hotfixes, branch synchronization, or divergence involving staging, main, or a legacy development branch in any company repository.
---

# Company Environment Branches

Apply this policy across company repositories unless the user gives a stricter repository-specific instruction. Repository documentation and live rulesets are the source of truth when they differ from this general policy.

## Environment Flow

Treat `main` as the canonical production branch and `staging` as the shared pre-production environment:

1. Branch normal work from the latest `main`.
2. Open the feature pull request into `staging`; use its preview environment to validate the change in isolation.
3. Merge into `staging` only when required checks and approval pass, staging is free, and the agreed tester is ready to begin immediately.
4. Validate the single candidate in staging.
5. After validation, the developer opens a `staging` to `main` pull request. Production promotion remains a human-driven decision and must pass the repository's required checks and approval.
6. Verify the resulting staging or production deployment rather than treating a merge as deployment success.

Do not push directly to `staging` or `main`. Use pull requests except for the controlled staging-reset procedure below.

`development` is a legacy branch, not a target for new work. During retirement, do not retarget another developer's open pull request on their behalf. Keep the branch and its protections until owners have moved or closed their work and all dependent integrations have been checked.

## Staging Capacity

Only one feature may occupy staging at a time. Determine availability from the latest remote file contents, not commit identity or ahead/behind counts:

```bash
git fetch origin
git diff --stat origin/main origin/staging
```

- Any file difference means staging is occupied; leave the feature in its preview.
- No file difference means staging may be used after checks, approval, and tester readiness are confirmed.
- A failed or ambiguous comparison means availability is unknown; stop and coordinate with the release owners.

Re-fetch and repeat this check immediately before a staging merge.

## Pull Request Authority

For pull requests whose base is `staging`:

- Create the pull request without asking for separate confirmation when it is an in-scope delivery or branch-sync step.
- Inspect live remote refs, existing pull requests, branch protection or rulesets, mergeability, and required checks.
- Monitor pending checks.
- Do not merge merely because checks are green. Confirm staging is free, the tester is ready, and an authorized release owner has explicitly approved the exact merge.
- Stop and report failures, conflicts, occupied or ambiguous staging, missing approval, or required human review.
- Re-fetch and re-check the head SHA immediately before merging.

For pull requests whose base is `main`:

- Treat the action as production-sensitive and human-driven.
- Never create or merge the pull request autonomously.
- Inspect, compare, validate, or prepare guidance when requested, but require an explicit user instruction for the exact `main` PR creation action.
- Never auto-merge into `main`; require human verification and an explicit merge decision after checks and QA.

## Controlled Staging Reset

When a staging candidate is rejected or an urgent hotfix must displace it, an authorized release owner may reset `staging` to the currently fetched `main` SHA. This is an exception, not a routine synchronization method.

Before a reset:

- Notify the displaced feature owner and preserve the feature branch.
- Confirm database migrations and other stateful changes are compatible with the reset; moving Git does not undo them.
- Capture the current remote staging SHA and use an explicit `--force-with-lease`. Never use plain `--force`.

```bash
git fetch origin
staging_before=$(git rev-parse origin/staging)
git push \
  --force-with-lease="refs/heads/staging:$staging_before" \
  origin origin/main:refs/heads/staging
```

If the lease fails, stop and coordinate instead of retrying with `--force`. Verify the staging deployment after a successful reset. Branch deletion protection must remain enforced even for release owners.

## Merge Method

Use the repository's live rulesets as the source of truth. For synchronization between long-lived environment branches, prefer a merge commit when allowed so ancestry remains visible. Follow the repository's allowed merge methods and flag ancestry loss before using squash for an environment promotion.

## Verification

Before creating or merging a PR:

1. Fetch the relevant remote branches.
2. Check the working tree without altering unrelated user changes.
3. Compare both commit ancestry and file changes.
4. Check for an existing equivalent PR.
5. Confirm the base and head branches explicitly.
6. For staging, confirm there is no file diff from `main` and the tester is ready.
7. For main, confirm staging validation passed and the user explicitly authorized the production action.

After merging into `staging` or `main`, verify the PR state and merge commit. When requested to follow deployment, continue through the associated environment deployment and report its actual result rather than assuming a merge equals a successful deployment.

Keep automatic head-branch deletion disabled where a staging reset may require a feature branch to be reintroduced. Never delete `staging` or `main` as pull-request cleanup.
