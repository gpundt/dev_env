#!/bin/bash
source ./_helpers.sh

# ──── Configures Tmux using config file and plugins ───────────────────────────────
function configure_tmux() {
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
    TMUX_SUCCESS=true
}

# ──── Configures Kitty using config file and plugins ───────────────────────────────
function configure_kitty() {
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
    KITTY_SUCCESS=true
}

# ──── Configures Alacritty using config file ───────────────────────────────────────
function configure_alacritty() {
    start_step_message "Configuring Alacritty"
    mkdir -p $ALACRITTY_DIR
    copy_file $ALACRITTY_CONF_SRC $ALACRITTY_CONF_DST
    status=$?
    if [ $status -ne 0 ]; then
        return
    fi

    successful
    ALACRITTY_SUCCESS=true
}