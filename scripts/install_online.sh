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
        return
    fi

    copy_file $TMUX_CONF_SRC $TMUX_CONF_DST
    status=$?
    if [ $status -ne 0 ]; then
        return
    fi

    successful
    TMUX_CONFIG_SUCCESS=true
}

# ──── Configures Kitty using config file and plugins ───────────────────────────────
function _configure_kitty() {
    start_step_message "Configuring Kitty"
    mkdir -p $KITTY_DIR/themes
    copy_file $KITTY_CONF_SRC $KITTY_CONF_DST
    status=$?
    if [ $status -ne 0 ]; then
        return
    fi

    copy_file $GIT_REPOS_DIR/kitty-themes/themes/* $KITTY_DIR/themes/
    status=$?
    if [ $status -ne 0 ]; then
        return
    fi
    
    copy_file $KITTY_DIR/themes/Broadcast.conf $KITTY_DIR/current-theme.conf
    status=$?
    if [ $status -ne 0 ]; then
        return
    fi

    successful
    KITTY_CONFIG_SUCCESS=true
}

# ──── Configures Zsh using config file, plugins, and themes ────────────────────────
function _configure_zsh() {
    start_step_message "Configuring Zsh"
    start_step_message "Oh My Zsh" "substep"

    local ohmyzsh_init
    ohmyzsh_init=$(mktemp /tmp/ohmyzsh-install.XXXXXX.sh) || {
        error_message "Failed to create temp file for Oh My Zsh installer"
        return
    }
    trap 'rm -f "$ohmyzsh_init"' RETURN
    
    if ! curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$ohmyzsh_init"; then
        error_message "Failed to download Oh My Zsh install script"
        return
    fi

    if ! /bin/sh "$ohmyzsh_init" --unattended; then
        error_message "Failed to run ohmyzsh install script"
        return
    fi


    pushd "$GIT_REPOS_DIR" > /dev/null || {
        error_message "Failed to 'pushd ${GIT_REPOS_DIR}'"
        return
    }
    while IFS= read -r THEME || [[ -n "$THEME" ]]; do
        [ -z "$THEME" ] && continue     # skip empty lines
        for DIR in $(ls | grep -i "${THEME}"); do
            copy_file "${DIR}" "${ZSH_THEMES_DST}"
            status=$?
            if [ $status -ne 0 ]; then
                return
            fi
        done
    done < "${ZSH_THEMES_LIST}"

    while IFS= read -r PLUGIN || [[ -n "$PLUGIN" ]]; do
        [ -z "$PLUGIN" ] && continue     # skip empty lines
        for DIR in $(ls | grep -i "${PLUGIN}"); do
            copy_file "${DIR}" "${ZSH_PLUGINS_DST}"
            status=$?
            if [ $status -ne 0 ]; then
                return
            fi
        done
    done < "${ZSH_PLUGINS_LIST}"
    popd > /dev/null

    copy_file $ZSH_CONF_SRC $ZSH_CONF_DST
    status=$?
    if [ $status -ne 0 ]; then
        return
    fi

    # And in _configure_zsh:
    copy_file "$P10K_CONF_SRC" "$P10K_CONF_DST"
    if [ $? -ne 0 ]; then
        ZSH_CONFIG_SUCCESS=false
        return
    fi 

    successful
    ZSH_CONFIG_SUCCESS=true
}

# ──── Configures Alacritty using config file ───────────────────────────────────────
function _configure_alacritty() {
    start_step_message "Configuring Alacritty"
    mkdir -p $ALACRITTY_DIR
    copy_file $ALACRITTY_CONF_SRC $ALACRITTY_CONF_DST
    status=$?
    if [ $status -ne 0 ]; then
        return
    fi

    successful
    ALACRITTY_CONFIG_SUCCESS=true
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
    _configure_zsh
    install_rust

    recap
}
main