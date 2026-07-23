#!/bin/bash
source ./_fonts.sh
source ./_git.sh
source ./_helpers.sh
source ./_languages.sh
source ./_packages.sh
source ./_terminals.sh
source ./_zsh.sh

# ──── Script entrypoint ────────────────────────────────────────────────────────────
function main() {
    determine_package_manager
    if [[ "${PACKAGE_MANAGER}" == "pacman" ]]; then
        error_message "Offline packaging only supports Debian-based distros" "exit"
    fi
    
    
    pull_git_repos
    pull_submodules
    pull_fonts
    #pull_rust_binary
    #pull_golang_binary
    pull_apt_deps
    pull_tmux
    pull_kitty_offline
    pull_ohmyzsh_offline
}
main