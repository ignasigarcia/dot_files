---
name: second-opinion
description: Get a code review or second opinion from the other coding agent and assess its findings in the current chat. When running in Codex, ask Claude Code; when running in Claude Code, ask Codex. Use when the user asks for "Claude's opinion", "ask Codex", "get a second opinion", or "have the other agent review this".
---

# Second opinion

Run the other agent's real command-line tool, read-only, and bring its findings back into this chat. Honor any model or effort the user names, and never silently substitute a weaker one.

## Prepare the review

- Pin down the user's question and the review scope: uncommitted changes, a branch against its base, a PR, or a design. Infer it from the current task when that's clear. Record the relevant Git state, and include untracked source files that are part of the change.
- Give the reviewer the requirements and the relevant repository guidance, not just a diff. Include the diff and any check results in the prompt, so the reviewer doesn't need a shell.
- For a fresh second opinion, let the reviewer assess the evidence before showing it your preferred answer. When continuing a disagreement, state both positions accurately and separate observations, proposals and decisions already approved.
- Keep it analysis-only unless the user separately asks for implementation. Ask for concrete findings with file locations, consequences and the smallest useful fix. Ask the reviewer to separate verified defects from design trade-offs and unsupported suspicions, and tell it not to read credentials, `.env` files or unrelated user data.
- Put the prompt and the captured output in a unique temporary folder outside the repository. Pass the prompt through stdin or a file, never by interpolating it into a shell command.

## From Codex: ask Claude Code

The default is Opus 5.5 at high effort. Check `claude --help` if the flags have changed.

```sh
claude --print \
  --model claude-opus-5-5 --effort high \
  --permission-mode plan \
  --tools 'Read,Glob,Grep' \
  --strict-mcp-config --mcp-config '{"mcpServers":{}}' \
  --output-format json \
  < "$review_dir/prompt.txt" > "$review_dir/result.json"
```

This gives Claude source reading only: no editing, shell or connected services. Don't add permission-bypass flags. Check the JSON success and error fields before treating the output as a review, and keep the session ID if a follow-up may help.

## From Claude Code: ask Codex

The default is the user's configured Codex model at high reasoning effort. Check `codex exec --help` if the flags have changed.

```sh
codex exec --sandbox read-only --skip-git-repo-check \
  -c model_reasoning_effort=high \
  -o "$review_dir/result.md" - < "$review_dir/prompt.txt" 2>/dev/null
```

The `read-only` sandbox lets Codex inspect files but not change them. Don't use the `--dangerously-*` flags. If the run fails, report the authentication, model, rate-limit or permission error accurately.

## Other harnesses

If the user explicitly asks for **T3 Code**, use its thread CLI (`~/.t3/bin/t3 thread start/send/show --help`). Select the Claude provider and exact model, and verify high effort through a supported setting before launch. If the user asks for **Orca**, follow the `orchestration` skill. Don't change app-wide defaults or add permanent connections for an ordinary review.

## Reconcile in this chat

- Read the whole response and check its important claims against the source. Treat it as evidence, not as authority or approval to implement.
- Summarize what you accept, what you reject or qualify, and what remains the user's decision. Say which checks actually ran; a reviewer reading the tests is not a passing test run.
- If there is a material disagreement, send one focused follow-up with the conflicting evidence, resuming by session ID rather than with a generic "continue last". Stop at agreement or at a clearly stated trade-off; don't start an open-ended debate or make the user copy messages between tools.
- Report the model and effort actually used. Asking for a review never authorizes applying its suggestions, committing or releasing.
