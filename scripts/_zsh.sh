#!/bin/bash
source ./_helpers.sh

# ── Global Variables ────────────────────────────────────────────────────────────────
# ── Zsh ─────────────────────
ZSH_CONF_SRC=$(pwd)/../configs/zshrc
ZSH_CONF_DST=~/.zshrc
ZSH_PLUGINS_LIST=$(pwd)/../deps/zsh/plugins.list
ZSH_THEMES_LIST=$(pwd)/../deps/zsh/themes.list
OHMYZSH_DIR=~/.oh-my-zsh
ZSH_PLUGINS_DST=$OHMYZSH_DIR/plugins/
ZSH_THEMES_DST=$OHMYZSH_DIR/themes/
P10K_CONF_SRC=$(pwd)/../configs/p10k.zsh
P10K_CONF_DST=~/.p10k.zsh

OHMYZSH_OFFLINE_PULL=$(pwd)/../deps/zsh/ohmyzsh.zip
GITSTATUSD_X86_OFFLINE_PULL=$(pwd)/../deps/zsh/gitstatusd-linux-x86_64.tar.gz 
GITSTATUSD_ARM_OFFLINE_PULL=$(pwd)/../deps/zsh/gitstatusd-linux-aarch64.tar.gz
ZSH_SUCCESS=false

# ──── Configures Zsh using config file, plugins, and themes ────────────────────────
function configure_zsh() {
    start_step_message "Configuring Zsh"
    start_step_message "Oh My Zsh" "substep"
    if [ -d $OHMYZSH_DIR ]; then
        info_message "${OHMYZSH_DIR} Exists; skipping pull..."
    elif [[ "$1" == "offline" ]]; then
        if ! _install_ohmyzsh_offline; then
            return
        fi
    else
        if ! _install_ohmyzsh_online; then
            return
        fi
    fi

    pushd "$GIT_REPOS_DIR" > /dev/null || {
        error_message "Failed to 'pushd ${GIT_REPOS_DIR}'"
        return
    }
    # Relocate zsh themes
    while IFS= read -r THEME || [[ -n "$THEME" ]]; do
        [ -z "$THEME" ] && continue     # skip empty lines
        for DIR in $(ls | grep -i "${THEME}"); do
            if ! copy_file "${DIR}" "${ZSH_THEMES_DST}"; then
                return
            fi
        done
    done < "${ZSH_THEMES_LIST}"

    # Relocate zsh plugins
    while IFS= read -r PLUGIN || [[ -n "$PLUGIN" ]]; do
        [ -z "$PLUGIN" ] && continue     # skip empty lines
        for DIR in $(ls | grep -i "${PLUGIN}"); do
            if ! copy_file "${DIR}" "${ZSH_PLUGINS_DST}"; then
                return
            fi
        done
    done < "${ZSH_PLUGINS_LIST}"
    popd > /dev/null || {
        error_message "Failed to 'popd'"
        return
    }

    # Relocate zsh config
    if ! copy_file "$ZSH_CONF_SRC" "$ZSH_CONF_DST"; then
        return
    fi

    # Relocate powerlevel10k config
    if ! copy_file "$P10K_CONF_SRC" "$P10K_CONF_DST"; then
        return
    fi 

    successful
    ZSH_SUCCESS=true
}

function pull_ohmyzsh_offline() {
    start_step_message "Pulling oh-my-zsh Locally"
    # Pull oh-my-zsh master zip
    if [ ! -f "$OHMYZSH_OFFLINE_PULL" ]; then
        if ! pull_from_url "https://github.com/ohmyzsh/ohmyzsh/archive/refs/heads/master.zip" "$OHMYZSH_OFFLINE_PULL"; then
            return 1
        fi
    else
        info_message "'$OHMYZSH_OFFLINE_PULL' Already Exists; Skipping pull..."
    fi

    # Pull x86_64 gitstatusd binary
    if [ ! -f "$GITSTATUSD_X86_OFFLINE_PULL" ]; then
        if ! pull_from_url "https://github.com/romkatv/gitstatus/releases/download/v1.5.4/gitstatusd-linux-x86_64.tar.gz" "$GITSTATUSD_X86_OFFLINE_PULL"; then
            return 1
        fi
    else
        info_message "'$GITSTATUSD_X86_OFFLINE_PULL' Already Exists; Skipping pull..."
    fi

    # Pull aarch64 gitstatusd binary
    if [ ! -f "$GITSTATUSD_ARM_OFFLINE_PULL" ]; then
        if ! pull_from_url "https://github.com/romkatv/gitstatus/releases/download/v1.5.4/gitstatusd-linux-aarch64.tar.gz" "$GITSTATUSD_ARM_OFFLINE_PULL"; then
            return 1
        fi
    else
        info_message "'$GITSTATUSD_ARM_OFFLINE_PULL' Already Exists; Skipping pull..."
    fi
    successful
}

function _install_ohmyzsh_offline() {
    start_step_message "Installing OhMyZsh" "substep"
    
    # Unzip oh-my-zsh master zip to destination
    mkdir -p ~/.oh-my-zsh
    if ! unzip "$OHMYZSH_OFFLINE_PULL" -d ~/.oh-my-zsh/; then
        error_message "Failed to unzip '${OHMYZSH_OFFLINE_PULL}'"
        return 1
    fi

    if ! mv ~/.oh-my-zsh/ohmyzsh-master/* ~/.oh-my-zsh/; then
        error_message "Failed to move contents of '~/.oh-my-zsh/ohmyzsh-master/' to '~/.oh-my-zsh/'"
        return 1
    fi

    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  GITSTATUSD_TARBALL=$GITSTATUSD_X86_OFFLINE_PULL ;;
        aarch64) GITSTATUSD_TARBALL=$GITSTATUSD_ARM_OFFLINE_PULL ;;
        *) error_message "Unsupported architecture: ${ARCH}" && return 1  ;;
    esac

    # Move correct gitstatusd binary
    mkdir -p ~/.cache/gitstatus
    if ! tar -xvzf $GITSTATUSD_TARBALL -C ~/.cache/gitstatus/; then
        error_message "Failed to extract '${GITSTATUSD_TARBALL}' to '~/.cache/gitstatus/'"
        return 1
    fi

    successful
    return 0
}

function _install_ohmyzsh_online() {
    # Install oh-my-zsh via installer script
    ohmyzsh_init=$(mktemp /tmp/ohmyzsh-install.XXXXXX.sh) || {
        error_message "Failed to create temp file for Oh My Zsh installer"
        return 1
    }
    trap 'rm -f "$ohmyzsh_init"' RETURN

    if ! pull_from_url "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" "$ohmyzsh_init"; then
        return 1
    fi

    if ! /bin/sh "$ohmyzsh_init" --unattended; then
        error_message "Failed to run ohmyzsh install script"
        return 1
    fi
}