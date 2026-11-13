# Global working agreements

These instructions apply to every coding agent on this machine. Codex reads them as `~/.codex/AGENTS.md` and Claude Code as `~/.claude/CLAUDE.md`; both are links to `dot_files/agents/AGENTS.md`.

## Communication style

Write responses for a human reader, not a log file. Readability matters more than raw brevity:

- Lead with the answer or outcome in one or two plain sentences, then give supporting detail.
- Use complete sentences and correct grammar. Never sacrifice grammar for concision.
- Avoid dense fragments, abbreviation-heavy shorthand, and arrow chains like `A → B → fails` — spell out what you mean in prose.
- Briefly explain technical terms, acronyms, and internal codenames the first time they appear, unless the conversation shows I already know them.
- Keep responses short by leaving out low-value detail, not by compressing the writing. If a detail doesn't change what I'd do next, drop it.
- When summarizing work you did, say what changed, where, and why it matters — in plain English a teammate could skim without rereading.

## Code changes

- Prefer completing each feature with as few files as practical while preserving readability, and group related concepts into logical folders and subfolders without creating an unreasonable or unmanageable hierarchy. The `slim-changes` skill has the details.

## Private context

Client-specific details that must stay out of this public repository live in `~/.config/agent-skills/`: Tempo ticket routing, AWS accounts and pipelines, release routes, and private skills. Skills say when to read them. Never copy their contents into a repository.

## Jira CLI

If you get an "invalid issue types in config" error, re-run:

```
jira init --server https://germinate.atlassian.net --login "$(git config user.email)" --project <PROJECT_KEY> --board <BOARD_NAME> --installation cloud --force
```

IMPORTANT: Never use HEREDOC syntax (`$(cat <<'EOF' ... EOF)`) for the `-b` body parameter. It causes the CLI to hang or fail silently. Always use plain inline strings with newlines directly in the `-b` parameter.

Common commands:

```bash
# Create ticket
jira issue create -p <PROJECT> -t Task -s "Summary" -b "Description" -y Medium --no-input

# List tickets
jira issue list -p <PROJECT>

# View ticket
jira issue view <TICKET_KEY>

# List projects
jira project list
```
