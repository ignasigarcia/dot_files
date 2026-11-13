# Agent skills for Codex and Claude Code

Codex and Claude Code use the same skill format: a folder holding a `SKILL.md` (YAML front matter with `name` and `description`, then Markdown instructions), plus optional `scripts/` and `references/`. This folder is the single source for the skills and global instructions both agents share.

```
agents/
  AGENTS.md         global instructions -> ~/.codex/AGENTS.md and ~/.claude/CLAUDE.md
  link-skills.sh    links everything into place; safe to rerun
  skills/<name>/    public skills -> ~/.agents/skills/<name> -> ~/.claude/skills/<name>
```

Codex reads `~/.agents/skills` directly. Claude Code only reads `~/.claude/skills`, so `link-skills.sh` links every skill in the shared folder there too, except `code-review` and `computer-use`, which would clash with Claude Code's built-in skills of the same names. `bootstrap.sh` runs the script; after adding or installing a skill, run it on its own:

```bash
./agents/link-skills.sh
```

## Private details stay out of this repository

This repository is public, so client names, colleagues, account IDs and ticket routing never go in it. They live in `~/.config/agent-skills/` (mode 700), which the skills read at run time:

```
~/.config/agent-skills/
  tempo-routing.md   calls-and-meetings ticket and Tempo account per project, recurring meeting titles
  projects.md        AWS profiles and accounts, pipelines, log groups, release routes, project quirks
  skills/<name>/     private skills (for example director-assistant), linked like the public ones
```

Tempo credentials live separately in `~/.config/tempo/.env` (mode 600). On a new machine, copy both folders from the old one (or from a password-manager backup) before running `link-skills.sh`.

## Skills in this repository

| Skill | What it does |
|---|---|
| `tempo` | Log, check or correct Tempo worklogs, such as "log 45 minutes on GAI-123". Holds the shared Tempo helper and rules. |
| `zoom-to-tempo` | Find attended Zoom calls for a date range, round each up to 15 minutes, and log what's missing. |
| `chat-to-tempo` | Rebuild worked hours from Codex and Claude Code chat history, propose entries, and save the approved ones. |
| `ship` | Commit, push, open or reuse the PR, wait for checks, and merge, using admin bypass when only reviews or rules block it. |
| `release-to-environment` | Promote a release to one environment and verify the deployment. |
| `release-through-environments` | Promote one change through every environment in order. |
| `company-environment-branches` | Staging-first branch, PR and merge policy. |
| `aws-monitor-deployment` | Follow CodePipeline, CodeBuild and CodeDeploy read-only, including quick build checks. |
| `aws-search-app-logs` | Search and tail CloudWatch application and build logs. |
| `aws-secrets-profiles` | Pick the right AWS profile and account before touching secrets. |
| `second-opinion` | Ask the other agent (Claude Code from Codex, or Codex from Claude Code) for a review. |
| `slim-changes` | Prefer small changes in existing files. |
| `company-research` | Deep research profile of a client company. |
| `rich-html-document` | Produce rich HTML documents instead of long Markdown. |

### Writing a skill that works in both agents

- Keep the front matter to `name` and `description`. Put trigger phrases in the description.
- Describe capabilities ("search Jira for the ticket") rather than one agent's tool names. Where the agents really differ, add a short note for each.
- Put repeatable API work in `scripts/` instead of pasting `curl` commands, and keep credentials in `~/.config`, loaded by the script.
- `agents/openai.yaml` holds Codex's display name and default prompt; Claude Code ignores it.

## Third-party skills

These are installed into `~/.agents/skills` by the [`skills`](https://github.com/vercel-labs/skills) installer (partly tracked in `~/.agents/.skill-lock.json`). They are not copied into this repository. Reinstall them with `npx skills add <source>` (see `npx skills --help` for installing globally or picking individual skills), then run `link-skills.sh`.

| Source | Skills |
|---|---|
| [mattpocock/skills](https://github.com/mattpocock/skills) | ask-matt, code-review, codebase-design, diagnosing-bugs, domain-modeling, grill-me, grill-with-docs, grilling, handoff, implement, implement-spec, improve-codebase-architecture, pr, prototype, research, retro, setup-matt-pocock-skills, tdd, teach, to-questionnaire, to-spec, to-tickets, triage, wait-what, wayfinder, wizard, writing-for-agents |
| [Code-and-Sorts/awesome-copilot-agents](https://github.com/Code-and-Sorts/awesome-copilot-agents) | jira-cli |
| [vercel-labs/skills](https://github.com/vercel-labs/skills) | find-skills |
| [softaworks/agent-toolkit](https://github.com/softaworks/agent-toolkit) | codex |
| [stablyai/orca](https://github.com/stablyai/orca) | orca-cli, orca-computer-use (also linked as computer-use), orchestration |
