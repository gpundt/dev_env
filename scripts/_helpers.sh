#!/bin/bash
# ──── Filepaths ────────────────────────────────────────────────────────────────────
TMUX_CONF_SRC=$(pwd)/../configs/tmux.conf
TMUX_CONF_DST=~/.tmux.conf
TMUX_CONFIG_SUCCESS=true

KITTY_DIR=~/.config/kitty
KITTY_CONF_SRC=$(pwd)/../configs/kitty.conf
KITTY_CONF_DST=$KITTY_DIR/kitty.conf
KITTY_CONFIG_SUCCESS=true

ALACRITTY_DIR=~/.config/alacritty
ALACRITTY_CONF_SRC=$(pwd)/../configs/alacritty.toml
ALACRITTY_CONF_DST=$ALACRITTY_DIR/alacritty.toml
ALACRITTY_CONFIG_SUCCESS=true

APT_DEPS_DIR=$(pwd)/../deps/apt
APT_DEPS_LIST=$APT_DEPS_DIR/apt.list
APT_INSTALL_SUCCESS=true

PACMAN_DEPS_LIST=$(pwd)/../deps/pacman/pacman.list
PACMAN_INSTALL_SUCCESS=true

GIT_REPOS_DIR=$(pwd)/../deps/git
GIT_REPOS_LIST=$GIT_REPOS_DIR/git.list
GIT_CLONE_SUCCESS=true

FONTS_LIST=$(pwd)/../deps/fonts/fonts.list
FONTS_CONFIG_SUCCESS=true

RUST_INSTALL_SUCCESS=true

# ──── Colors ─────────────────────────────────────────────────────────────────────── 
RED=$'\033[1;31m'
GREEN=$'\033[1;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[1;34m'
PURPLE=$'\033[1;35m'
CYAN=$'\033[1;36m'
RESET=$'\033[0m'

# ──── Message Functions ─────────────────────────────────────────────────────────────
function graceful_exit() {
    echo -e "${RED}*Closing*${RESET}"
    exit 1
}
function start_step_message() {
    if [[ $# -eq 2 && "$2" == "substep" ]]; then
        echo -e "\n\t${CYAN}* $1 *${RESET}"
    else
        echo -e "\n${CYAN}[*] $1 [*]${RESET}"
    fi
}
function successful() {
    echo -e "\t - ${GREEN}*Successful*${RESET}"
}
function error_message() {
    _print_aligned "${RED}ERROR${RESET}:" "$1" $2
    if [[ "$3" == "exit" ]]; then
        graceful_exit
    fi
}
function warning_message() {
    _print_aligned "${YELLOW}WARNING${RESET}:" "$1" $2
}
function info_message() {
    _print_aligned "${BLUE}INFO${RESET}:" "$1" $2
}
function message() {
    _print_aligned "${PURPLE}$1${RESET}:" "$2" $3
}
function _print_aligned() {
    local left_str="$1"
    local right_str="$2"
    local width="${3:-30}"      # Total width defaults to 30 if not specified
    printf "%-*s%s%s\n" "$width" "$left_str" "$right_str"
}

# ──── File Helper Functions ─────────────────────────────────────────────────────────
function create_dir() {
    if [ ! -d "$1" ]; then
        start_step_message "$1" "substep"
        if ! sudo mkdir -p "$1"; then
            error_message "Failed to create directory '$1'"
        fi
    fi
}

function copy_file() {
    start_step_message "$1 -> $2" "substep"
    if [ ! -e "$1" ]; then
        if [[ "$3" == "warning" ]]; then
            warning_message "Src '$1' does not exist"
        else
            error_message "Src '$1' does not exist"
        fi
        return 1
    fi

    if ! sudo cp -rf $1 $2 >/dev/null 2>&1; then
        if [[ "$3" == "warning" ]]; then
            warning_message "Failed to move $1 to $2"
            return
        else
            error_message "Failed to move $1 to $2"
        fi
        return 1
    fi
    return 0
}

# ──── Package Installations ─────────────────────────────────────────────────────────
# ── Apt and Pacman ─────────
function install_deps() {
    local package_manager=$1
    local package_install_command=$2

    if [[ "${package_manager}" == "apt" ]]; then
        start_step_message "Installing Apt Deps Listed in '${APT_DEPS_LIST}'"
        while IFS= read -r PACKAGE; do
            _individual_dep_install "${PACKAGE}" "${package_manager}" "${package_install_command}"
        done < "${APT_DEPS_LIST}"

    elif [[ "$1" == "pacman" ]]; then
        start_step_message "Installing Pacman Deps Listed in '${PACMAN_DEPS_LIST}'"
        while IFS= read -r PACKAGE; do
            _individual_dep_install "${PACKAGE}" "${package_manager}" "${package_install_command}"
        done < "${PACMAN_DEPS_LIST}"

    else
        error_message "Package Manager '$package_manager' not supported"
    fi
    successful
}

function _individual_dep_install() {
    local package=$1
    local package_manager=$2
    local package_install_command=$3

    if ! command -v $package &> /dev/null; then
        start_step_message "${package}" "substep"
        if ! $package_install_command $package; then
            error_message "Failed to '${package_install_command} ${package}'"
            if [[ "${package_manager}" == "apt" ]]; then
                APT_INSTALL_SUCCESS=false
            else
                PACMAN_INSTALL_SUCCESS=false
            fi
        fi
    fi
}

# ── Git Repos ─────────────
function pull_git_repos() {
    start_step_message "Pulling Git Repos Listed in '${GIT_REPOS_LIST}'"

    pushd "$GIT_REPOS_DIR" > /dev/null || {
        error_message "Failed to 'pushd ${GIT_REPOS_DIR}'"
    }

    while IFS= read -r REPO || [[ -n "$REPO" ]]; do
        [ -z "$REPO" ] && continue      # skip empty lines
        start_step_message "${REPO}" "substep"
        if ! git clone "$REPO" </dev/null; then
            warning_message "Failed to 'git clone ${REPO}'"
            GIT_CLONE_SUCCESS=false
        fi
    done < "${GIT_REPOS_LIST}"

    popd > /dev/null
    successful
}

# ── Fonts ────────────────
function install_fonts() {
    start_step_message "Adding Fonts"
    mkdir -p ~/.local/share/fonts
    while IFS= read -r FONT_URL || [[ -n "$FONT_URL" ]]; do
        [ -z "$FONT_URL" ] && continue      # skip empty lines
        start_step_message "${FONT_URL}" "substep"

        FONT_NAME=$(basename "$FONT_URL" .zip)
        FONT_DIR=~/.local/share/fonts/$FONT_NAME
        TMP_ZIP=/tmp/${FONT_NAME}.zip

        mkdir -p "$FONT_DIR"

        if ! curl -Lo "$TMP_ZIP" "$FONT_URL"; then
            error_message "Failed to download '${FONT_URL}'"
            FONTS_CONFIG_SUCCESS=false
            continue
        fi

        if ! unzip -o "$TMP_ZIP" -d "$FONT_DIR" > /dev/null 2>&1; then
            error_message "Failed to unzip '${TMP_ZIP}'"
            rm -rf "$TMP_ZIP"
            FONTS_CONFIG_SUCCESS=false
            continue
        fi

        rm -rf "$TMP_ZIP"
        message "Installed Font" "${FONT_NAME}"
        
    done < "${FONTS_LIST}"

    if ! fc-cache -fv; then
        error_message "Failed to 'fc-cache -fv'"
        FONTS_CONFIG_SUCCESS=false
    fi
    successful
}

# ── Rustup and Cargo ───────
function install_rust() {
    if command -v cargo &> /dev/null && command -v rustup &> /dev/null; then
        return
    fi

    local rustup_init
    rustup_init=$(mktemp /tmp/rustup-init.XXXXXX.sh) || {
        error_message "Failed to create temp file for rustup installer"
        RUST_INSTALL_SUCCESS=false
        return
    }

    trap 'rm -f "$rustup_init"' RETURN

    start_step_message "Downloading Rustup Installer"
    if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o "$rustup_init"; then
        error_message "Failed to download rustup installer"
        RUST_INSTALL_SUCCESS=false
        return
    fi
    successful

    start_step_message "Installing Cargo and Rustup"
    if ! /bin/sh "$rustup_init"; then
        error_message "Failed to install Cargo and Rustup"
        RUST_INSTALL_SUCCESS=false
        return
    fi
    successful
}

# ──── Configuration Recap ─────────────────────────────────────────────────────────
function recap() {
    start_step_message "Installation Recap"
    
    local package_label package_status
    if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
        package_label="Apt Package Installation"
        package_status="$APT_INSTALL_SUCCESS"
    else
        package_label="Pacman Package Installation"
        package_status="$PACMAN_INSTALL_SUCCESS"
    fi

    local -a item_labels=(
        "Tmux Configuration"
        "Kitty Configuration"
        "Alacritty Configuration"
        "$package_label"
        "Git Repo Clones"
        "Font Installation"
        "Rust Installation"
    )
    local -a status_vars=(
        "$TMUX_CONFIG_SUCCESS"
        "$KITTY_CONFIG_SUCCESS"
        "$ALACRITTY_CONFIG_SUCCESS"
        "$package_status"
        "$GIT_CLONE_SUCCESS"
        "$FONTS_CONFIG_SUCCESS"
        "$RUST_INSTALL_SUCCESS"
    )
    
    local i
    for i in "${!item_labels[@]}"; do
        _recap_item "${item_labels[$i]}" "${status_vars[$i]}"
    done

    if [[ "$RUST_INSTALL_SUCCESS" == "true" ]]; then
        message "Next Steps" "Execute 'source \"$HOME/.cargo/env\"'"
    fi
}

function _recap_item() {
    local item_label="$1"
    local status_var="$2"

    if [[ "$status_var" == "true" ]]; then
        message "$item_label" "${GREEN}Success${RESET}" 40
    else
        message "$item_label" "${RED}Failure${RESET}" 40
    fi
}
