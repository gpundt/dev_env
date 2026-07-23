#!/bin/bash
source ./_helpers.sh

# ── Global Variables ────────────────────────────────────────────────────────────────
# ── Tmux ───────────────────
TMUX_CONF_SRC=$(pwd)/../configs/tmux.conf
TMUX_CONF_DST=~/.tmux.conf
TMUX_SUCCESS=false

# ── Kitty ──────────────────
KITTY_DIR=~/.config/kitty
KITTY_CONF_SRC=$(pwd)/../configs/kitty.conf
KITTY_CONF_DST=$KITTY_DIR/kitty.conf

KITTY_OFFLINE_PULL_DIR=$(pwd)/../deps/kitty
KITTY_OFFLINE_PULL_LIST=$KITTY_OFFLINE_PULL_DIR/kitty.list
KITTY_SUCCESS=false

# ──── Configures Tmux using config file and plugins ───────────────────────────────
function configure_tmux() {
  start_step_message "Configuring Tmux"

  if ! which tmux >/dev/null; then
    error_message "Tmux not found"
    return
  fi

  if [[ "$1" == "offline" ]]; then
    info_message "Offline Install - Skipping branch pull..."
  else
    if ! pull_tmux_branch; then
      error_message "Failed to pull correct Tmux branch"
      return
    fi
  fi

  mkdir -p ~/.tmux/plugins/catppuccin
  if ! copy_file "$GIT_REPOS_DIR"/tmux ~/.tmux/plugins/catppuccin/tmux; then
    return
  fi

  if ! copy_file "$GIT_REPOS_DIR"/tpm ~/.tmux/plugins/; then
    return
  fi

  if ! copy_file "$TMUX_CONF_SRC" $TMUX_CONF_DST; then
    return
  fi

  successful
  TMUX_SUCCESS=true
}

function pull_tmux_branch() {
  start_step_message "Pulling Correct Tmux Repo Branch"
  pushd "$GIT_REPOS_DIR/tmux" >/dev/null || {
    error_message "Failed to 'pushd \"$GIT_REPOS_DIR/tmux\"'"
    return 1
  }
  git checkout v2.3.0
  popd >/dev/null || {
    error_message "Failed to 'popd'"
    return 1
  }

  successful
}

# ──── Configures Kitty using config file and plugins ───────────────────────────────
function configure_kitty() {
  start_step_message "Configuring Kitty"

  # Offline kitty config
  if [[ "$1" == "offline" ]]; then
    if ! _install_kitty_offline; then
      return
    fi
  
  else
    if ! _install_kitty_online; then
      return
    fi
  fi
  
  if ! command -v kitty >/dev/null 2>&1; then
    error_message "Kitty failed to install"
    return
  fi

  # Move kitty config
  if ! copy_file "$KITTY_CONF_SRC" "$KITTY_CONF_DST"; then
    return
  fi

  # Move kitty themes
  mkdir -p $KITTY_DIR/themes
  if ! cp "$GIT_REPOS_DIR"/kitty-themes/themes/* $KITTY_DIR/themes/; then
    return
  fi

  if ! copy_file "$KITTY_DIR"/themes/Broadcast.conf $KITTY_DIR/current-theme.conf; then
    return
  fi

  successful
  KITTY_SUCCESS=true
}

function pull_kitty_offline() {
  start_step_message "Pulling Kitty Binaries Listed in '${KITTY_OFFLINE_PULL_LIST}'"
  X86_URL=$(cat "${KITTY_OFFLINE_PULL_LIST}" | grep "x86_64")
  X86_TAR="${X86_URL##*/}"
  KITTY_X86_TAR_OUTPUT="${KITTY_OFFLINE_PULL_DIR}/${X86_TAR}"

  ARM_URL=$(cat "${KITTY_OFFLINE_PULL_LIST}" | grep "arm64")
  ARM_TAR="${ARM_URL##*/}"
  KITTY_ARM_TAR_OUTPUT="${KITTY_OFFLINE_PULL_DIR}/${ARM_TAR}"

  if [ ! -f "$KITTY_X86_TAR_OUTPUT" ]; then
    start_step_message "${X86_TAR}" "substep"
    if ! pull_from_url $X86_URL $KITTY_X86_TAR_OUTPUT; then
      return 1
    fi
  else
    info_message "Skipping '${KITTY_X86_TAR_OUTPUT}' - already exists"
  fi

  if [ ! -f "$KITTY_ARM_TAR_OUTPUT" ]; then
    start_step_message "${ARM_TAR}" "substep"
    if ! pull_from_url $ARM_URL $KITTY_ARM_TAR_OUTPUT; then
      return 1
    fi
  else
    info_message "Skipping '${KITTY_ARM_TAR_OUTPUT}' - already exists"
  fi

  successful
  return 0
}

function _install_kitty_offline() {
  ARCH=$(uname -m)
  case "$ARCH" in
      x86_64)  KITTY_ARCH="x86_64" ;;
      aarch64) KITTY_ARCH="arm64" ;;
      *) error_message "Unsupported architecture: ${ARCH}" && return 1  ;;
  esac
  
  KITTY_TAR_SRC=$(pwd)/../deps/kitty/kitty-0.48.0-$KITTY_ARCH.txz
  
  mkdir -p ~/.local/kitty.app
  if ! tar xJf "$KITTY_TAR_SRC" -C ~/.local/kitty.app; then
    error_message "Failed to extract kitty tar '${KITTY_TAR_SRC}'"
    return 1
  fi

  cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
  sed -i "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty.desktop
  sed -i "s|Exec=kitty|Exec=$HOME/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty.desktop

  ln -s ~/.local/kitty.app/bin/kitty ~/.local/bin/kitty

  return 0
}

function _install_kitty_online() {
  start_step_message "Pulling Kitty Installer" "substep"
  kitty_installer=$(mktemp /tmp/kitty_installer.XXXXXX.sh) || {
    error_message "Failed to create temp file for kitty installer"
    return 1
  }
  trap 'rm -f "$kitty_installer"' RETURN
  if ! curl https://sw.kovidgoyal.net/kitty/installer.sh -o "$kitty_installer"; then
    error_message "Failed to pull kitty installer"
    return 1
  fi

  start_step_message "Running Installer" "substep"
  if ! /bin/sh "$kitty_installer"; then
    error_message "Failed to run kitty installer"
    return 1
  fi

  cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
  sed -i "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty.desktop
  sed -i "s|Exec=kitty|Exec=$HOME/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty.desktop

  return 0
}
