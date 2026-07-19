#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly BREWFILE="${REPO_DIR}/Brewfile"
readonly NVM_VERSION="v0.40.6"
readonly BACKUP_DIR="${HOME}/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

log() {
  printf '\n==> %s\n' "$1"
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

require_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || fail "This bootstrap currently supports macOS only."
}

require_command_line_tools() {
  if xcode-select -p >/dev/null 2>&1; then
    return
  fi

  log "Requesting Apple's Command Line Tools"
  xcode-select --install
  fail "Finish the Command Line Tools installation, then run this script again."
}

install_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
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
    log "Installing nvm ${NVM_VERSION}"
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" |
      PROFILE=/dev/null bash
  else
    log "nvm is already installed"
  fi

  # shellcheck source=/dev/null
  source "${NVM_DIR}/nvm.sh"

  log "Installing the latest Node.js LTS release and npm"
  nvm install --lts --latest-npm
  nvm alias default 'lts/*'
  nvm use default
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
  backup_and_link "${REPO_DIR}/ghostty/config" "${HOME}/.config/ghostty/config"
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
  vim -Nu "${HOME}/.vimrc" -n -es -i NONE '+PlugInstall --sync' '+qa'
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
  log "Starter setup complete"
  cat <<'STEPS'

Open a new terminal, then finish the sign-ins that cannot be automated:

  gh auth login
  jira init

Also open 1Password, Docker Desktop, Helium, JetBrains Toolbox, WebStorm, Slack,
Zoom, and Notion Calendar once to finish their onboarding. Enable the 1Password
SSH agent after signing in; your private keys can then stay inside 1Password
instead of being exported to disk.
STEPS

  if [[ -d "${BACKUP_DIR}" ]]; then
    printf '\nPrevious config files were saved in: %s\n' "${BACKUP_DIR}"
  fi
}

main() {
  require_macos
  require_command_line_tools
  install_homebrew
  install_brew_bundle
  install_oh_my_zsh
  install_nvm_and_node
  link_dotfiles
  install_vim_plugins
  install_tmux_plugins
  print_next_steps
}

main "$@"
