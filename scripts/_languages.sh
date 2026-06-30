#!/bin/bash
source ./_helpers.sh

# ── Rustup and Cargo ───────
function install_rust() {
    start_step_message "Installing Cargo and Rustup"
    
    if command -v cargo &> /dev/null && command -v rustup &> /dev/null; then
        info_message "Skipping rustup and cargo install; already present..."
        RUST_SUCCESS=true
        return
    fi

    local rustup_init
    rustup_init=$(mktemp /tmp/rustup-init.XXXXXX.sh) || {
        error_message "Failed to create temp file for rustup installer"
        return
    }

    trap 'rm -f "$rustup_init"' RETURN

    start_step_message "Downloading rustup installer" "substep"
    if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o "$rustup_init"; then
        error_message "Failed to download rustup installer"
        return
    fi
    successful

    start_step_message "Running rustup_init install script" "substep"
    if ! /bin/sh "$rustup_init"; then
        error_message "Failed to install Cargo and Rustup"
        return
    fi

    successful
    RUST_SUCCESS=true
}

# ── Golang ─────────────────
function install_go() {
    start_step_message "Installing Golang"
    
    if command -v go &> /dev/null; then
        info_message "Skipping Golang install; already present..."
        GOLANG_SUCCESS=true
        return
    fi

    successful
    GOLANG_SUCCESS=TRUE
}