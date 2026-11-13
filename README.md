# dot_files

One command to set up a new machine, on macOS or on a headless Linux box.

```bash
git clone https://github.com/ignasigarcia/dot_files.git ~/dev/dot_files
cd ~/dev/dot_files
./bootstrap.sh
```

The bootstrap detects the system and is safe to rerun. Existing config files are
moved to a timestamped folder under `~/.dotfiles-backup/` before links are created.

| | macOS | Linux (no GUI) |
|---|---|---|
| System tools | Homebrew and everything in the `Brewfile` | Only missing basics (curl, git, Vim, tmux, zsh, Python 3, zstd) via `apt-get` or `dnf` |
| Desktop apps | Yes (`Brewfile` casks) | No |
| zsh + Oh My Zsh, nvm + Node.js LTS | Yes | Yes (zsh becomes the login shell) |
| Codex CLI and Claude Code CLI | Yes | Yes |
| Shell, Vim and tmux config, Vim and tmux plugins | Yes | Yes |
| Ghostty and lazygit config | Yes | No |
| Shared agent skills and global instructions | Yes | Yes |

On a Mac without Apple's Command Line Tools, the first run opens their installer
and stops. Finish that installation, then run `./bootstrap.sh` again. On Linux,
installing missing packages may ask for your sudo password.

## Installed software

On macOS, Homebrew manages:

- latest stable Vim, tmux, GitHub CLI (`gh`), Jira CLI (`jira`) and pgcli
- lazygit, git-delta and ripgrep
- AWS CLI and zstd
- ChatGPT (which includes the Codex app) and Claude
- Docker Desktop
- Ghostty, IBM Plex Sans, and JetBrains Mono
- Helium browser
- Notion Calendar
- 1Password and its CLI
- Slack and Zoom
- JetBrains Toolbox and WebStorm

On both systems, the bootstrap installs Oh My Zsh and nvm from their official
installers. nvm then installs the latest Node.js LTS release, makes it the default
and updates npm. The Codex CLI comes from npm (`@openai/codex`) and Claude Code
from Anthropic's native installer, so both systems get the same tools.

## Managed configuration

- `zsh/zshrc` -> `~/.zshrc`
- `vim/vimrc` -> `~/.vimrc`
- `tmux/tmux.conf` -> `~/.tmux.conf`
- `ghostty/config` -> `~/.config/ghostty/config` (macOS)
- `lazygit/config.yml` -> `~/Library/Application Support/lazygit/config.yml` (macOS)
- `codex/config.toml` is copied (not linked) to `~/.codex/config.toml` when that
  file doesn't exist yet. Codex keeps editing its own copy, and its trusted-folder
  list and machine-specific state stay out of this repository.

Vim plugins live under `~/.vim/plugged`, and tmux plugins live under
`~/.tmux/plugins`. Both plugin managers are installed and initialized by the
bootstrap.

Put private or machine-specific shell configuration in `~/.zshrc.local`. Never
commit private keys, access tokens, browser profiles, cookies, or local secret
files.

## Agent skills

Codex and Claude Code share one set of skills and global instructions from
[`agents/`](agents/README.md). The bootstrap links them into `~/.agents/skills`,
`~/.claude/skills`, `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md`; rerun
`./agents/link-skills.sh` after adding or installing a skill.

Client-specific details stay out of this public repository, in
`~/.config/agent-skills/`. Copy that folder, `~/.config/tempo/` and
`~/.aws/config` from your previous machine, then rerun `./agents/link-skills.sh`.

## Apps built from source

These aren't in Homebrew, so install them by hand after the bootstrap (they need
Xcode):

- **Memento Mori menu bar app**
  ([ignasigarcia/memento-mori-menubar](https://github.com/ignasigarcia/memento-mori-menubar),
  private): shows the weeks left in the menu bar and a life calendar when clicked.
  Clone it, follow the build steps in its README, then set your birthday from the
  menu bar icon. It turns on "Open at login" by itself on first launch.

## Manual onboarding

Some tools need an interactive sign-in:

```bash
claude                        # Claude Code
codex login                   # Codex
gh auth login
jira init
aws sso login --profile grm
```

On a Mac, also sign in to ChatGPT (Codex) and Claude, connect the Zoom app in
Codex and the Atlassian connector in Claude, and open 1Password first: sign in and
enable its SSH agent in **Settings > Developer**. This lets Git and SSH use keys
stored in 1Password without exposing the private keys to either client. See the
[1Password SSH agent guide](https://www.1password.dev/ssh/agent) for the current
setup steps. Then open Docker Desktop, Helium, JetBrains Toolbox, WebStorm, Slack,
Zoom, and Notion Calendar once after installation. For Helium extension setup and
the portable extension manifest, see [`helium/EXTENSIONS.md`](helium/EXTENSIONS.md).
