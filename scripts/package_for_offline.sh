#!/bin/bash
source ./_fonts.sh
source ./_git.sh
source ./_helpers.sh
source ./_packages.sh

# ──── Script entrypoint ────────────────────────────────────────────────────────────
function main() {
    verify_package_manager
    if [[ "${PACKAGE_MANAGER}" == "pacman" ]]; then
        error_message "Offline packaging only supports Debian-based distros" "exit"
    fi
    
    pull_apt_deps
    pull_git_repos
    pull_fonts
    pull_submodules
}
main