#!/bin/bash
source ./_helpers.sh

# ── Tmux ───────────────────
TMUX_CONF_SRC=$(pwd)/../configs/tmux.conf
TMUX_CONF_DST=~/.tmux.conf
TMUX_SUCCESS=false

# ── Kitty ──────────────────
KITTY_DIR=~/.config/kitty
KITTY_CONF_SRC=$(pwd)/../configs/kitty.conf
KITTY_CONF_DST=$KITTY_DIR/kitty.conf
KITTY_SUCCESS=false

# ── Alacritty ──────────────
ALACRITTY_DIR=~/.config/alacritty
ALACRITTY_CONF_SRC=$(pwd)/../configs/alacritty.toml
ALACRITTY_CONF_DST=$ALACRITTY_DIR/alacritty.toml
ALACRITTY_SUCCESS=false

# ──── Configures Tmux using config file and plugins ───────────────────────────────
function configure_tmux() {
  start_step_message "Configuring Tmux"

  mkdir -p ~/.tmux/plugins/catppuccin
  pushd "$GIT_REPOS_DIR/tmux" >/dev/null || {
    error_message "Failed to 'pushd \"$GIT_REPOS_DIR/tmux\"'"
    return
  }
  git checkout v2.3.0
  popd >/dev/null || {
    error_message "Failed to 'popd'"
    return
  }

  copy_file $GIT_REPOS_DIR/tmux ~/.tmux/plugins/catppuccin/tmux
  status=$?
  if [ $status -ne 0 ]; then
    return
  fi

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

  start_step_message "Pulling Installer" "substep"
  kitty_installer=$(mktemp /tmp/kitty_installer.XXXXXX.sh) || {
    error_message "Failed to create temp file for kitty installer"
    return
  }
  trap 'rm -f "$kitty_installer"' RETURN
  if ! curl https://sw.kovidgoyal.net/kitty/installer.sh -o "$kitty_installer"; then
    error_message "Failed to pull kitty installer"
    return
  fi

  start_step_message "Running Installer" "substep"
  if ! /bin/sh "$kitty_installer"; then
    error_message "Failed to run kitty installer"
    return
  fi

  mkdir -p $KITTY_DIR/themes
  copy_file $KITTY_CONF_SRC $KITTY_CONF_DST
  status=$?
  if [ $status -ne 0 ]; then
    return
  fi

  cp $GIT_REPOS_DIR/kitty-themes/themes/* $KITTY_DIR/themes/
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

