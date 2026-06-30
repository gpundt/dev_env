#!/bin/bash
source ./_helpers.sh

PACKAGE_MANAGER=""
PACKAGE_INSTALL_COMAMND=""

function determine_package_manager() {
    if command -v apt &> /dev/null; then
        message "Package Manager" "Apt"
        PACKAGE_MANAGER="apt" 
        PACKAGE_INSTALL_COMAMND="sudo apt install"
    
    elif command -v pacman &> /dev/null; then
        message "Package Manager" "Pacman"
        PACKAGE_MANAGER="pacman"
        PACKAGE_INSTALL_COMMAND="sudo pacman -s"
    
    else
        error_message "Neither Apt or Pacman package manager found"
    fi
}

function _configure_tmux() {
    start_step_message "Configuring Tmux"

    mkdir -p ~/.tmux/plugins/
    copy_file $GIT_REPOS_DIR/tmp ~/.tmux/plugins/tpm "warning"
    copy_file $TMUX_CONF_SRC $TMUX_CONF_DST

    successful
}

function _configure_kitty() {
    start_step_message "Configuring Kitty"
    mkdir -p $KITTY_DIR
    copy_file $KITTY_CONF_SRC $KITTY_CONF_DST

    successful
}

function _configure_alacritty() {
    start_step_message "Configuring Alacritty"
    mkdir -p $ALACRITTY_DIR
    copy_file $ALACRITTY_CONF_SRC $ALACRITTY_CONF_DST

    successful
}

function main() {
    determine_package_manager
    install_deps "${PACKAGE_MANAGER}" "${PACKAGE_INSTALL_COMAMND}"
    pull_git_repos
    add_fonts

    _configure_tmux
    _configure_kitty
    _configure_alacritty
    install_rust
}
main