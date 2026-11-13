---
name: aws-secrets-profiles
description: Pick the correct AWS CLI profile and account before checking or managing environment secrets in AWS Secrets Manager for development, staging or production. Use whenever a task touches environment secrets.
---

# AWS secrets: environment profiles

The confirmed mapping from environment to AWS profile and account is in the private project notes, `~/.config/agent-skills/projects.md`, under "AWS accounts and profiles". Read it first. Production usually lives in a **different account and profile** from development and staging. Never substitute the development profile for production.

- Pass the chosen profile explicitly with `--profile`. Use the project's configured region, and look up the exact secret identifiers rather than guessing them from environment names.
- Before any authorized secret change, confirm the account with `aws sts get-caller-identity --profile PROFILE`. A profile name alone doesn't prove which account it points at.
- Inspect secret key names without printing values. Keep the current secret version, historical versions, and values already deployed into Lambda environment variables distinct.
- This mapping doesn't authorize secret changes, deployments or credential removal. Follow the user's current request, and don't modify AWS profile configuration as part of choosing a profile.
