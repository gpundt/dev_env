#!/bin/bash
source ./_helpers.sh

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
ZSH_SUCCESS=false

# ──── Configures Zsh using config file, plugins, and themes ────────────────────────
function configure_zsh() {
    start_step_message "Configuring Zsh"
    start_step_message "Oh My Zsh" "substep"
    if [ -d $OHMYZSH_DIR ]; then
        info_message "Skipping; Oh-my-zsh already exists..."
        ZSH_SUCCESS=true
        return
    fi

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