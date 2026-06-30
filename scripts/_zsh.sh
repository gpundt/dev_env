#!/bin/bash
source ./_helpers.sh

# ──── Configures Zsh using config file, plugins, and themes ────────────────────────
function configure_zsh() {
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
    # Relocate zsh themes
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

    # Relocate zsh plugins
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

    # Relocate zsh config
    copy_file $ZSH_CONF_SRC $ZSH_CONF_DST
    status=$?
    if [ $status -ne 0 ]; then
        return
    fi

    # Relocate powerlevel10k config
    copy_file "$P10K_CONF_SRC" "$P10K_CONF_DST"
    if [ $? -ne 0 ]; then
        ZSH_SUCCESS=false
        return
    fi 

    successful
    ZSH_SUCCESS=true
}