#!/bin/bash
source ./_helpers.sh

function main() {
    install_apt_deps
    pull_git_repos

    place_tmux_config
    place_kitty_config
    place_alacritty_config
}
main