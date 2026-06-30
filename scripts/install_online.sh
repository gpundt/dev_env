#!/bin/bash
source ./_helpers.sh

PACKAGE_MANAGER=""
PACKAGE_INSTALL_COMMAND=""

# ──── Determines what ackage manager this host uses (Pacman | Apt) ────────────────
function determine_package_manager() {
    if command -v apt &> /dev/null; then
        message "Package Manager" "Apt"
        PACKAGE_MANAGER="apt" 
        PACKAGE_INSTALL_COMMAND="sudo apt install"
    
    elif command -v pacman &> /dev/null; then
        message "Package Manager" "Pacman"
        PACKAGE_MANAGER="pacman"
        PACKAGE_INSTALL_COMMAND="sudo pacman -s"
    
    else
        error_message "Neither Apt or Pacman package manager found"
    fi
}

# ──── Configures Tmux using config file and plugins ───────────────────────────────
function _configure_tmux() {
    start_step_message "Configuring Tmux"

    mkdir -p ~/.tmux/plugins/
    copy_file $GIT_REPOS_DIR/tpm ~/.tmux/plugins/
    status=$?
    if [ $status -ne 0 ]; then
        TMUX_CONFIG_SUCCESS=false
    fi

    copy_file $TMUX_CONF_SRC $TMUX_CONF_DST
    status=$?
    if [ $status -ne 0 ]; then
        TMUX_CONFIG_SUCCESS=false
    fi

    successful
}

# ──── Configures Kitty using config file and plugins ───────────────────────────────
function _configure_kitty() {
    start_step_message "Configuring Kitty"
    mkdir -p $KITTY_DIR/themes
    copy_file $KITTY_CONF_SRC $KITTY_CONF_DST
    status=$?
    if [ $status -ne 0 ]; then
        KITTY_CONFIG_SUCCESS=false
    fi

    copy_file $GIT_REPOS_DIR/kitty-themes/themes/* $KITTY_DIR/themes/
    status=$?
    if [ $status -ne 0 ]; then
        KITTY_CONFIG_SUCCESS=false
    fi
    
    copy_file $KITTY_DIR/themes/Broadcast.conf $KITTY_DIR/current-theme.conf
    status=$?
    if [ $status -ne 0 ]; then
        KITTY_CONFIG_SUCCESS=false
    fi

    successful
}

# ──── Configures Alacritty using config file ───────────────────────────────────────
function _configure_alacritty() {
    start_step_message "Configuring Alacritty"
    mkdir -p $ALACRITTY_DIR
    copy_file $ALACRITTY_CONF_SRC $ALACRITTY_CONF_DST
    status=$?
    if [ $status -ne 0 ]; then
        ALACRITTY_CONFIG_SUCCESS=false
    fi

    successful
}

# ──── Script entrypoint ────────────────────────────────────────────────────────────
function main() {
    determine_package_manager
    install_deps "${PACKAGE_MANAGER}" "${PACKAGE_INSTALL_COMMAND}"
    pull_git_repos
    install_fonts

    _configure_tmux
    _configure_kitty
    _configure_alacritty
    install_rust

    recap
}
main