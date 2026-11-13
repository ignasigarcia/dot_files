---
name: ship
description: Ship the current branch end to end. Commit the in-scope changes, push, open or reuse the branch's pull request, wait for the checks, and merge it, using the user's GitHub admin bypass when only reviews or branch rules block the merge. Use for "ship this", "/ship", "$ship", "push this PR, wait for the checks and merge", "push and merge" or "finish this PR". Say "just push" to stop after pushing. For promotions between environment branches use release-to-environment.
---

# Ship

This is the user's quick path from local changes to a merged PR. Asking for it authorizes committing the in-scope work, pushing, creating or reusing the PR, and merging. Don't ask for confirmation at each step. Stop only in the cases listed below.

## 1. Check the branch

- Read the repository's instructions (`AGENTS.md`, `CLAUDE.md`, contributing notes). Inspect `git status --short --branch`, the current branch, the `origin` URL, the upstream and the `HEAD` SHA.
- Stop if `HEAD` is detached, there are unresolved conflicts, or the current branch is an environment branch (`development`, `staging`, `main`, `master`). Never push straight to those. Offer to move the work onto a feature branch instead.

## 2. Commit the in-scope changes

- Review the whole diff. Stage only the files that belong to this work, by name; never use `git add -A`. Leave local-only files (editor settings, `settings.local.json`, scratch files, `.env`) out.
- If you can't tell whether a dirty file belongs to this work, ask about that file. Never stash, reset or discard anything to make shipping easier.
- Run the repository's quick checks (lint, typecheck, tests) when they are cheap, and say which ran.
- Match the style of `git log --oneline -10`. If the user gave a commit message, use it as the subject. If there is nothing new to commit, continue with what is already committed, or stop if nothing is ahead of the remote.

## 3. Push

- Run `git fetch origin`, then `git push -u origin HEAD`. Never force-push.
- Confirm the remote branch SHA matches local `HEAD`; that is the candidate SHA.
- If the user said "just push", report the branch and SHA and stop here.

## 4. Find or open the PR

- Reuse the open PR whose head is this branch (`gh pr list --head <branch> --state open --json number,url,baseRefName`).
- Otherwise use the base the user named. If none was named, follow `company-environment-branches`: new work normally targets `staging`, and `development` only where it is still the active integration branch. Ask if the base is unclear.
- Title the PR with the ticket key and a summary when there is a ticket. In the body, say what changed and how it was checked.
- If the base is `staging` and another feature already occupies staging (the capacity check in `company-environment-branches`), stop and ask. Merging would mix two features in QA.
- If the base is `main` or `master`, which is production, prepare everything but ask once before merging. This is the user's standing production rule.

## 5. Wait for the checks

- Watch with `gh pr checks <number> --watch --interval 30`. Run it in the background if it takes a while.
- A failing check stops the merge. Open its log, report the real error and the failing command, and offer a fix if it is small and clearly in scope. Never bypass a red check or blindly re-run it.
- Treat skipped and neutral checks the way GitHub does.

## 6. Merge, bypassing protection if needed

- Re-query the PR and confirm: it is open and not a draft, its head is still the candidate SHA, it has no conflicts, and its checks are green.
- Choose the method the repository allows (`gh repo view --json mergeCommitAllowed,squashMergeAllowed,rebaseMergeAllowed`): its usual method for feature PRs, and a merge commit between long-lived environment branches.
- Try a normal `gh pr merge <number> --<method>` first. If GitHub refuses only because of branch protection or rulesets (a missing approval, a required review, or "base branch policy prohibits the merge") and the checks are green, merge with `gh pr merge <number> --<method> --admin`. The user is on the repository's bypass list and has approved this for ship. Say in the report that the bypass was used, and why.
- **Never bypass:** failing checks, merge conflicts, a draft PR, or a review that explicitly requests changes. Stop and report those instead.
- Don't delete the branch unless asked.
- When `release-to-environment` or `release-through-environments` borrows these steps, its stricter merge rules apply. The bypass is only for when the user asks to ship directly.

## 7. Verify and report

- Re-query the PR and confirm it is `MERGED`, its base, and its merge commit SHA. Fetch the base branch and confirm it contains the merge commit.
- Report the branch, pushed SHA, PR number and URL, base, checks result, merge method, whether the admin bypass was used, and the merge commit SHA.
- A merge is not a deployment. If the base deploys automatically, say so and offer to follow it with `aws-monitor-deployment`.
