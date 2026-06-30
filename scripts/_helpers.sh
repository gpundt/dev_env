#!/bin/bash
# ──── Filepaths ────────────────────────────────────────────────────────────────────
TMUX_CONF_SRC=$(pwd)/../configs/tmux.conf
TMUX_CONF_DST=~/.tmux.conf
TMUX_CONFIG_SUCCESS=false

KITTY_DIR=~/.config/kitty
KITTY_CONF_SRC=$(pwd)/../configs/kitty.conf
KITTY_CONF_DST=$KITTY_DIR/kitty.conf
KITTY_CONFIG_SUCCESS=false

ALACRITTY_DIR=~/.config/alacritty
ALACRITTY_CONF_SRC=$(pwd)/../configs/alacritty.toml
ALACRITTY_CONF_DST=$ALACRITTY_DIR/alacritty.toml
ALACRITTY_CONFIG_SUCCESS=false

ZSH_PLUGINS_LIST=$(pwd)/../deps/zsh/plugins.list
ZSH_THEMES_LIST=$(pwd)/../deps/zsh/themes.list
ZSH_CONF_SRC=$(pwd)/../configs/zshrc
ZSH_CONF_DST=~/.zshrc
OHMYZSH_DIR=~/.oh-my-zsh
ZSH_PLUGINS_DST=$OHMYZSH_DIR/plugins/
ZSH_THEMES_DST=$OHMYZSH_DIR/themes/
ZSH_CONFIG_SUCCESS=false
P10K_CONF_SRC=$(pwd)/../configs/p10k.zsh
P10K_CONF_DST=~/.p10k.zsh

APT_DEPS_DIR=$(pwd)/../deps/apt
APT_DEPS_LIST=$APT_DEPS_DIR/apt.list
APT_INSTALL_SUCCESS=false

PACMAN_DEPS_LIST=$(pwd)/../deps/pacman/pacman.list
PACMAN_INSTALL_SUCCESS=false

GIT_REPOS_DIR=$(pwd)/../deps/git
GIT_REPOS_LIST=$GIT_REPOS_DIR/git.list
GIT_CLONE_SUCCESS=false

FONTS_LIST=$(pwd)/../deps/fonts/fonts.list
FONTS_CONFIG_SUCCESS=false

RUST_INSTALL_SUCCESS=false

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
            if [ $? -ne 0 ]; then
                return
            fi
        done < "${APT_DEPS_LIST}"
        APT_INSTALL_SUCCESS=true

    elif [[ "$1" == "pacman" ]]; then
        start_step_message "Installing Pacman Deps Listed in '${PACMAN_DEPS_LIST}'"
        while IFS= read -r PACKAGE; do
            _individual_dep_install "${PACKAGE}" "${package_manager}" "${package_install_command}"
            if [ $? -ne 0 ]; then
                return
            fi
        done < "${PACMAN_DEPS_LIST}"
        PACMAN_INSTALL_SUCCESS=true

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
            return 1
        fi
    fi

    return 0
}

# ── Git Repos ─────────────
function pull_git_repos() {
    start_step_message "Pulling Git Repos Listed in '${GIT_REPOS_LIST}'"

    pushd "$GIT_REPOS_DIR" > /dev/null || {
        error_message "Failed to 'pushd ${GIT_REPOS_DIR}'"
        GIT_CLONE_SUCCESS=false
        return
    }

    while IFS= read -r REPO || [[ -n "$REPO" ]]; do
        [ -z "$REPO" ] && continue      # skip empty lines

        local REPO_NAME
        REPO_NAME=$(basename "$REPO" .git)          # extracts repo name, strips .git if present

        if [ -d "$REPO_NAME" ]; then
            info_message "Skipping '${REPO_NAME}' — directory already exists"
            continue
        fi
        
        start_step_message "${REPO}" "substep"
        if ! git clone --depth=1 "$REPO" </dev/null; then
            warning_message "Failed to 'git clone ${REPO}'"
            return
        fi
    done < "${GIT_REPOS_LIST}"

    popd > /dev/null
    successful
    GIT_CLONE_SUCCESS=true
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
            return
        fi

        if ! unzip -o "$TMP_ZIP" -d "$FONT_DIR" > /dev/null 2>&1; then
            error_message "Failed to unzip '${TMP_ZIP}'"
            rm -rf "$TMP_ZIP"
            return
        fi

        rm -rf "$TMP_ZIP"
        message "Installed Font" "${FONT_NAME}"
        
    done < "${FONTS_LIST}"

    if ! fc-cache -fv; then
        error_message "Failed to 'fc-cache -fv'"
        return
    fi

    successful
    FONTS_CONFIG_SUCCESS=true
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
        "Zsh Configuration"
        "$package_label"
        "Git Repo Clones"
        "Font Installation"
        "Rust Installation"
    )
    local -a status_vars=(
        "$TMUX_CONFIG_SUCCESS"
        "$KITTY_CONFIG_SUCCESS"
        "$ALACRITTY_CONFIG_SUCCESS"
        "$ZSH_CONFIG_SUCCESS"
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

    if [[ "$ZSH_CONFIG_SUCCESS" == "true" ]]; then
        message "Next Steps" "Execute 'source ${ZSH_CONF_DST}'"
        message "Next Steps" "Exexute 'chsh -s '$(which zsh)'"
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
