#!/usr/bin/env bash
# One command for a new machine:  git clone ... && ./bootstrap.sh
#
# macOS:  Homebrew tools and desktop apps, shell/editor configs, Codex and Claude
#         Code CLIs, shared agent skills.
# Linux:  headless setup. Missing basics from the system package manager, shell/editor
#         configs, Codex and Claude Code CLIs, shared agent skills. No GUI apps.
#
# Safe to rerun: existing files are moved to ~/.dotfiles-backup/<timestamp>/.

set -Eeuo pipefail

readonly REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly BREWFILE="${REPO_DIR}/Brewfile"
readonly NVM_INSTALLER_VERSION="v0.40.6"
readonly BACKUP_DIR="${HOME}/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
export BACKUP_DIR # agents/link-skills.sh saves replaced files to the same folder
readonly OS="$(uname -s)"

log() {
  printf '\n==> %s\n' "$1"
}

note() {
  printf 'Note: %s\n' "$1"
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

is_mac() {
  [[ "${OS}" == "Darwin" ]]
}

has() {
  command -v "$1" >/dev/null 2>&1
}

check_platform() {
  case "${OS}" in
    Darwin | Linux) ;;
    *) fail "Unsupported system: ${OS}. This bootstrap supports macOS and Linux." ;;
  esac
}

# --- macOS ------------------------------------------------------------------

require_command_line_tools() {
  if xcode-select -p >/dev/null 2>&1; then
    return
  fi

  log "Requesting Apple's Command Line Tools"
  xcode-select --install
  fail "Finish the Command Line Tools installation, then run this script again."
}

install_homebrew() {
  if ! has brew; then
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    fail "Homebrew was installed, but its executable could not be found."
  fi
}

install_brew_bundle() {
  log "Installing Homebrew packages and applications"
  brew bundle --file="${BREWFILE}"
}

# --- Linux ------------------------------------------------------------------

# Install only the missing basics, so reruns never ask for a password.
install_linux_packages() {
  local -a missing=()
  local tool sudo=""

  for tool in curl git vim tmux zsh python3 zstd; do
    has "${tool}" || missing+=("${tool}")
  done
  # Node.js's official Linux builds need libatomic, which minimal images leave out.
  ldconfig -p 2>/dev/null | grep -q 'libatomic\.so\.1' || missing+=(libatomic)
  if [[ ${#missing[@]} -eq 0 ]]; then
    log "System packages are already installed"
    return
  fi

  if [[ "$(id -u)" -ne 0 ]]; then
    has sudo || fail "Missing ${missing[*]} and sudo is unavailable. Install them, then rerun."
    sudo="sudo"
  fi

  log "Installing system packages: ${missing[*]}"
  if has apt-get; then
    missing=("${missing[@]/#libatomic/libatomic1}")
    ${sudo} apt-get update
    ${sudo} env DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}" ca-certificates
  elif has dnf; then
    ${sudo} dnf install -y "${missing[@]/#vim/vim-enhanced}"
  else
    fail "Missing ${missing[*]}. Install them with your package manager, then rerun."
  fi
}

use_zsh_as_login_shell() {
  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ "$(basename -- "${SHELL:-}")" == "zsh" ]]; then
    return
  fi

  log "Making zsh the login shell"
  if [[ "$(id -u)" -eq 0 ]]; then
    chsh -s "${zsh_path}"
  elif has sudo; then
    sudo chsh -s "${zsh_path}" "$(id -un)"
  else
    chsh -s "${zsh_path}"
  fi || note "Could not change the login shell. Run: chsh -s ${zsh_path}"
}

# --- Both -------------------------------------------------------------------

install_oh_my_zsh() {
  if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    log "Oh My Zsh is already installed"
    return
  fi

  log "Installing Oh My Zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    "" --unattended
}

install_nvm_and_node() {
  export NVM_DIR="${HOME}/.nvm"

  if [[ ! -s "${NVM_DIR}/nvm.sh" ]]; then
    log "Installing nvm ${NVM_INSTALLER_VERSION}"
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_INSTALLER_VERSION}/install.sh" |
      PROFILE=/dev/null bash
  else
    log "nvm is already installed"
  fi

  # nvm's scripts aren't written for strict mode, so relax it around them and
  # check the result explicitly instead.
  log "Installing the latest Node.js LTS release and npm"
  set +eEuo pipefail
  # shellcheck source=/dev/null
  source "${NVM_DIR}/nvm.sh"
  nvm install --lts --latest-npm
  nvm alias default 'lts/*' >/dev/null
  nvm use default >/dev/null
  set -eEuo pipefail

  node --version >/dev/null 2>&1 && npm --version >/dev/null 2>&1 ||
    fail "Node.js was installed but doesn't run. Check its error with: node --version"
  printf 'Using Node.js %s and npm %s\n' "$(node --version)" "$(npm --version)"
}

# The official cross-platform installers, so Mac and Linux get the same tools.
install_agent_clis() {
  export PATH="${HOME}/.local/bin:${PATH}"

  if has claude; then
    log "Claude Code is already installed"
  else
    log "Installing Claude Code"
    curl -fsSL https://claude.ai/install.sh | bash
  fi

  if has codex; then
    log "Codex CLI is already installed"
  else
    log "Installing the Codex CLI"
    npm install -g @openai/codex
  fi
}

backup_and_link() {
  local source_path="$1"
  local target_path="$2"

  mkdir -p "$(dirname -- "${target_path}")"

  if [[ -L "${target_path}" && "$(readlink "${target_path}")" == "${source_path}" ]]; then
    printf 'Already linked: %s\n' "${target_path}"
    return
  fi

  if [[ -e "${target_path}" || -L "${target_path}" ]]; then
    mkdir -p "${BACKUP_DIR}"
    mv "${target_path}" "${BACKUP_DIR}/$(basename -- "${target_path}")"
    printf 'Backed up: %s\n' "${target_path}"
  fi

  ln -s "${source_path}" "${target_path}"
  printf 'Linked: %s -> %s\n' "${target_path}" "${source_path}"
}

link_dotfiles() {
  log "Linking repository configuration"
  backup_and_link "${REPO_DIR}/zsh/zshrc" "${HOME}/.zshrc"
  backup_and_link "${REPO_DIR}/vim/vimrc" "${HOME}/.vimrc"
  backup_and_link "${REPO_DIR}/tmux/tmux.conf" "${HOME}/.tmux.conf"

  if is_mac; then
    backup_and_link "${REPO_DIR}/ghostty/config" "${HOME}/.config/ghostty/config"
    backup_and_link "${REPO_DIR}/lazygit/config.yml" "${HOME}/Library/Application Support/lazygit/config.yml"
  fi
}

# Codex keeps rewriting its config, so seed it once instead of linking it.
install_codex_config() {
  local target="${HOME}/.codex/config.toml"

  if [[ -e "${target}" || -L "${target}" ]]; then
    printf 'Keeping existing Codex config: %s\n' "${target}"
    return
  fi

  mkdir -p "${HOME}/.codex"
  cp "${REPO_DIR}/codex/config.toml" "${target}"
  chmod 600 "${target}"
  printf 'Installed starter Codex config: %s\n' "${target}"
}

link_agent_skills() {
  log "Linking shared Codex and Claude Code skills"
  "${REPO_DIR}/agents/link-skills.sh"
}

install_vim_plugins() {
  local plug_path="${HOME}/.vim/autoload/plug.vim"

  mkdir -p "${HOME}/.vim/autoload" "${HOME}/.vim/undo"
  if [[ ! -f "${plug_path}" ]]; then
    log "Installing vim-plug"
    curl -fsSL \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
      -o "${plug_path}"
  fi

  log "Installing Vim plugins"
  # Headless Vim exits non-zero for harmless startup warnings (for example, a
  # colour scheme that is only available once its plugin is installed).
  vim -Nu "${HOME}/.vimrc" -n -es -i NONE '+PlugInstall --sync' '+qa' ||
    note "Vim reported warnings while installing plugins."
  [[ -n "$(ls -A "${HOME}/.vim/plugged" 2>/dev/null)" ]] ||
    fail "Vim plugins were not installed. Open Vim and run :PlugInstall to see why."
}

install_tmux_plugins() {
  local tpm_dir="${HOME}/.tmux/plugins/tpm"

  if [[ ! -d "${tpm_dir}/.git" ]]; then
    log "Installing tmux plugin manager"
    git clone https://github.com/tmux-plugins/tpm "${tpm_dir}"
  fi

  log "Installing tmux plugins"
  "${tpm_dir}/bin/install_plugins"
}

print_next_steps() {
  log "Setup complete"
  cat <<'STEPS'

Open a new terminal, then finish the sign-ins that cannot be automated:

  claude                        # sign in to Claude Code
  codex login                   # sign in to Codex
  gh auth login                 # if gh is installed
  aws sso login --profile grm   # if the AWS CLI is installed

Private files never live in this public repository. Copy these from your previous
machine if you need them: ~/.config/agent-skills/, ~/.config/tempo/ and
~/.aws/config. Then rerun ./agents/link-skills.sh.
STEPS

  if is_mac; then
    cat <<'STEPS'

Also open 1Password, Docker Desktop, ChatGPT (Codex), Claude, Helium, JetBrains
Toolbox, WebStorm, Slack, Zoom and Notion Calendar once to finish their
onboarding. Enable the 1Password SSH agent after signing in, so your private
keys can stay inside 1Password instead of being exported to disk.
STEPS
  fi

  if [[ -d "${BACKUP_DIR}" ]]; then
    printf '\nPrevious config files were saved in: %s\n' "${BACKUP_DIR}"
  fi
}

main() {
  check_platform

  if is_mac; then
    require_command_line_tools
    install_homebrew
    install_brew_bundle
  else
    install_linux_packages
  fi

  install_oh_my_zsh
  is_mac || use_zsh_as_login_shell
  install_nvm_and_node
  install_agent_clis
  link_dotfiles
  install_codex_config
  link_agent_skills
  install_vim_plugins
  install_tmux_plugins
  print_next_steps
}

main "$@"
