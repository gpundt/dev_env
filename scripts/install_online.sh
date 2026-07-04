#!/bin/bash
source ./_helpers.sh

source ./_packages.sh
source ./_git.sh
source ./_fonts.sh
source ./_terminals.sh
source ./_zsh.sh
source ./_languages.sh

if [[ "$1" == "-h" ]]; then
  help_message "$0"
  exit 0
fi

# ──── Script entrypoint ────────────────────────────────────────────────────────────
function main() {
  local option="$1"

  determine_package_manager
  install_deps "${PACKAGE_MANAGER}" "${PACKAGE_INSTALL_COMMAND}"
  pull_git_repos
  install_fonts

  configure_tmux
  configure_kitty
  configure_alacritty
  configure_zsh

  install_rust
  install_go

  if [[ "$option" == "--cleanup" ]]; then
    cleanup
  fi

  recap
}
main "$1"
