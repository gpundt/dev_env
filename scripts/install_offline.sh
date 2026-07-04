#!/bin/bash
source ./_helpers.sh

# ──── Script entrypoint ────────────────────────────────────────────────────────────
function main() {
    install_apt_deps "offline"

    place_tmux_config
    place_kitty_config
    place_alacritty_config
}
main