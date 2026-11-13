#!/usr/bin/env bash
# Link the shared agent skills and global instructions into Codex and Claude Code.
# Safe to rerun after adding, renaming or installing skills.
#
#   dot_files/agents/skills/<name>        public skills (this repo)
#   ~/.config/agent-skills/skills/<name>  private skills (never committed)
#   ~/.agents/skills/<name>               shared folder; Codex reads it directly,
#                                         and `npx skills` installs third-party skills here
#   ~/.claude/skills/<name>               Claude Code; linked to the shared folder

set -Eeuo pipefail

readonly AGENTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_SKILLS="${AGENTS_DIR}/skills"
readonly PRIVATE_SKILLS="${HOME}/.config/agent-skills/skills"
readonly SHARED_SKILLS="${HOME}/.agents/skills"
readonly CLAUDE_SKILLS="${HOME}/.claude/skills"
readonly CODEX_SKILLS="${HOME}/.codex/skills"
readonly BACKUP_DIR="${BACKUP_DIR:-${HOME}/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"

# Third-party skills Claude Code should not see, because it has a built-in skill with the same name.
readonly CLAUDE_SKIP=(code-review computer-use)

link() {
  local source_path="$1"
  local target_path="$2"

  mkdir -p "$(dirname -- "${target_path}")"
  if [[ -e "${target_path}" && "$(realpath "${target_path}")" == "$(realpath "${source_path}")" ]]; then
    return
  fi
  if [[ -e "${target_path}" || -L "${target_path}" ]]; then
    local backup_path="${BACKUP_DIR}/${target_path#"${HOME}"/}"
    mkdir -p "$(dirname -- "${backup_path}")"
    mv "${target_path}" "${backup_path}"
    printf 'Backed up: %s\n' "${target_path}"
  fi
  ln -s "${source_path}" "${target_path}"
  printf 'Linked: %s -> %s\n' "${target_path}" "${source_path}"
}

is_skipped_for_claude() {
  local name="$1" skipped
  for skipped in "${CLAUDE_SKIP[@]}"; do
    [[ "${name}" == "${skipped}" ]] && return 0
  done
  return 1
}

# Remove broken links left behind by renamed or deleted skills. Real folders are never touched.
remove_broken_links() {
  local folder="$1" entry
  for entry in "${folder}"/*; do
    if [[ -L "${entry}" && ! -e "${entry}" ]]; then
      rm "${entry}"
      printf 'Removed broken link: %s\n' "${entry}"
    fi
  done
}

main() {
  local dir name entry

  # 1. Own skills (public and private) into the shared folder.
  for dir in "${REPO_SKILLS}"/*/ "${PRIVATE_SKILLS}"/*/; do
    [[ -f "${dir}SKILL.md" ]] || continue
    name="$(basename -- "${dir}")"
    link "${dir%/}" "${SHARED_SKILLS}/${name}"
  done
  remove_broken_links "${SHARED_SKILLS}"

  # 2. Everything in the shared folder into Claude Code.
  for entry in "${SHARED_SKILLS}"/*; do
    name="$(basename -- "${entry}")"
    [[ -f "${entry}/SKILL.md" ]] || continue
    is_skipped_for_claude "${name}" && continue
    link "${SHARED_SKILLS}/${name}" "${CLAUDE_SKILLS}/${name}"
  done
  remove_broken_links "${CLAUDE_SKILLS}"

  # 3. Codex already reads the shared folder, so links to it from ~/.codex/skills only duplicate skills.
  for entry in "${CODEX_SKILLS}"/*; do
    if [[ -L "${entry}" && -e "${entry}" && "$(realpath "${entry}")" == "$(realpath "${SHARED_SKILLS}")"/* ]]; then
      rm "${entry}"
      printf 'Removed duplicate Codex link: %s\n' "${entry}"
    fi
  done

  # 4. One set of global instructions for both agents.
  link "${AGENTS_DIR}/AGENTS.md" "${HOME}/.codex/AGENTS.md"
  link "${AGENTS_DIR}/AGENTS.md" "${HOME}/.claude/CLAUDE.md"

  if [[ ! -d "${HOME}/.config/agent-skills" ]]; then
    printf '\nNote: ~/.config/agent-skills is missing. Copy it from your previous machine; see agents/README.md.\n'
  fi
  if [[ -d "${BACKUP_DIR}" ]]; then
    printf '\nReplaced files were saved in: %s\n' "${BACKUP_DIR}"
  fi
}

main "$@"
