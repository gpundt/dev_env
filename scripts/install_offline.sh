#!/bin/bash
source ./_fonts.sh
source ./_helpers.sh
source ./_languages.sh
source ./_terminals.sh


# ──── Script entrypoint ────────────────────────────────────────────────────────────
function main() {
    install_fonts "offline"
    # install_rust "offline"
    # install_go "offline
    configure_tmux "offline"
    configure_kitty "offline"
    configure_zsh "offline"
}
main