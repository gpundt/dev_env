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

    _pull_go_binaries
    if [ $? -ne 0 ]; then
        error_message "Failed to pull golang bianary tarball"
        return
    fi

    sudo rm -rf /usr/local/go

    start_step_message "Extracting '${TARBALL}'" "substep"
    if ! sudo tar -C /usr/local -xzf "$TARBALL"; then
        error_message "Failed to 'sudo tar -C /usr/local -xzf ${TARBALL}'"
        rm -rf ./go*.tar.gz
        return
    fi
    rm -rf ./go*.tar.gz

    successful
    GOLANG_SUCCESS=true
}

function _pull_go_binaries() {
    start_step_message "Pulling Binaries"

    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  GO_ARCH="amd64" ;;
        aarch64) GO_ARCH="arm64" ;;
        armv7l)  GO_ARCH="armv6l" ;;
        *) error_message "Unsupported architecture: ${ARCH}" && return 1  ;;
    esac
                
    TARBALL="go${GOLANG_VERSION}.linux-${ARCH}.tar.gz"
    URL="https://go.dev/dl/{TARBALL}"

    start_step_message "${TARBALL}" "substep"
    if ! wget -q --show-progress "$URL"; then
        return 1
    fi

    return 0

}