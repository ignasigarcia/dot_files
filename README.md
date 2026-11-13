# dot_files

A repeatable macOS starter for a new laptop or desktop. It installs the core
development tools, links the version-controlled shell, Vim, tmux, Ghostty and
lazygit configuration into the home directory, and seeds a starter Codex
configuration.

## Quick start

On a new Mac, open Terminal and run:

```bash
git clone https://github.com/ignasigarcia/dot_files.git ~/dev/dot_files
cd ~/dev/dot_files
./bootstrap.sh
```

If the Mac does not have Apple's Command Line Tools yet, the first run opens
their installer and stops. Finish that installation, then run `./bootstrap.sh`
again.

The bootstrap is safe to rerun. Existing config files are moved to a timestamped
directory under `~/.dotfiles-backup/` before symlinks are created.

## Installed software

Homebrew manages:

- latest stable Vim
- GitHub CLI (`gh`)
- lazygit, git-delta and ripgrep
- Jira CLI (`jira`)
- pgcli
- tmux
- Docker Desktop
- Ghostty, IBM Plex Sans, and JetBrains Mono
- Helium browser
- Notion Calendar
- 1Password and its CLI
- Slack and Zoom
- JetBrains Toolbox and WebStorm

The bootstrap installs Oh My Zsh and nvm from their official upstream installers.
nvm then installs the latest Node.js LTS release, makes it the default, and updates
its bundled npm.

## Managed configuration

- `zsh/zshrc` -> `~/.zshrc`
- `vim/vimrc` -> `~/.vimrc`
- `ghostty/config` -> `~/.config/ghostty/config`
- `tmux/tmux.conf` -> `~/.tmux.conf`
- `lazygit/config.yml` -> `~/Library/Application Support/lazygit/config.yml`
- `codex/config.toml` is copied (not linked) to `~/.codex/config.toml` on a
  fresh Mac. Codex keeps editing its own copy, and its trusted-folder list and
  machine-specific state stay out of this repository.

Vim plugins live under `~/.vim/plugged`, and tmux plugins live under
`~/.tmux/plugins`. Both plugin managers are installed and initialized by the
bootstrap.

Put private or machine-specific shell configuration in `~/.zshrc.local`. Never
commit private keys, access tokens, browser profiles, cookies, or local secret
files.

## Manual onboarding

Some applications require an interactive sign-in or first launch:

```bash
gh auth login
jira init
```

Open 1Password first, sign in, and enable its SSH agent in **Settings >
Developer**. This lets Git and SSH use keys stored in 1Password without exposing
the private keys to either client. See the [1Password SSH agent
guide](https://www.1password.dev/ssh/agent) for the current setup steps. Then
open Docker Desktop, Helium, JetBrains Toolbox, WebStorm, Slack, Zoom, and Notion
Calendar once after installation. For Helium extension setup and the portable
extension manifest, see
[`helium/EXTENSIONS.md`](helium/EXTENSIONS.md).

## Agent skills

Codex and Claude Code share one set of skills and global instructions from
[`agents/`](agents/README.md). The bootstrap links them into `~/.agents/skills`,
`~/.claude/skills`, `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md`; rerun
`./agents/link-skills.sh` after adding or installing a skill.

Client-specific details stay out of this public repository, in
`~/.config/agent-skills/`. Copy that folder and `~/.config/tempo/` from your
previous machine before running the bootstrap.
