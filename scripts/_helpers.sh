#!/bin/bash
# ──── Filepaths ────────────────────────────────────────────────────────────────────
TMUX_CONF_SRC=$(pwd)/../configs/tmux.conf
TMUX_CONF_DST=~/.tmux.conf

KITTY_DIR=~/.config/kitty
KITTY_CONF_SRC=$(pwd)/../configs/kitty.conf
KITTY_CONF_DST=$KITTY_DIR/kitty.conf

ALACRITTY_DIR=~/.config/alacritty
ALACRITTY_CONF_SRC=$(pwd)/../configs/alacritty.toml
ALACRITTY_CONF_DST=$ALACRITTY_DIR/alacritty.toml

APT_DEPS_DIR=$(pwd)/../deps/apt
APT_DEPS_LIST=$APT_DEPS_DIR/apt.list

PACMAN_DEPS_LIST=$(pwd)/../deps/pacman/pacman.list

GIT_REPOS_DIR=$(pwd)/../deps/git
GIT_REPOS_LIST=$GIT_REPOS_DIR/git.list

FONTS_LIST=$(pwd)/../deps/fonts/fonts.list

# ──── Colors ─────────────────────────────────────────────────────────────────────── 
RED=$'\033[1;31m'
GREEN=$'\033[1;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[1;34m'
PURPLE=$'\033[1;35m'
CYAN=$'\033[1;36m'
RESET=$'\033[0m'

# ──── Messages ─────────────────────────────────────────────────────────────────────
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
    graceful_exit
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

# ──── Helper Functions ──────────────────────────────────────────────────────────────
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
    fi

    if ! sudo cp -r $1 $2 >/dev/null 2>&1; then
        if [[ "$3" == "warning" ]]; then
            warning_message "Failed to move $1 to $2"
            return
        else
            error_message "Failed to move $1 to $2"
        fi
    fi
}

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
        start_step_message "${package}"
        if ! $package_install_command $package; then
            error_message "Failed to '${package_install_command} ${package}'"
        fi
    fi
}

function download_apt_packages() {
    start_step_message "Installing Downloaded .deb Packages from '${APT_DEPS_DIR}'"
    if ! sudo dpkg -i $APT_DEPS_DIR/*.deb; then
        error_message "Failed to 'sudo dpkg -i ${APT_DEPS_DIR}/*.deb'"
    fi
}

function pull_git_repos() {
    start_step_message "Pulling Git Repos Listed in '${GIT_REPOS_LIST}'"
    git remote set-url origin https://github.com
    pushd $GIT_REPOS_DIR > /dev/null || error_message "Failed to 'pushd ${GIT_REPOS_DIR}'"
    while IFS= read -r REPO; do
        [ -z "$REPO" ] && continue      # skip empty lines
        start_step_message "${REPO}" "substep"
        if ! git clone "$REPO"; then
            warning_message "Failed to 'git clone ${REPO}'"
        fi
    done < "${GIT_REPOS_LIST}"
    popd > /dev/null
    successful
}

function add_fonts() {
    start_step_message "Adding Fonts"
    mkdir -p ~/.local/share/fonts
    while IFS= read -r FONT_URL; do
        [ -z "$FONT_URL" ] && continue      # skip empty lines
        start_step_message "${FONT_URL}"

        FONT_NAME=$(basename "$FONT_URL" .zip)
        FONT_DIR=~/.local/share/fonts/$FONT_NAME
        TMP_ZIP=/tmp/${FONT_NAME}.zip

        mkdir -p "$FONT_DIR"

        if ! curl -Lo "$TMP_ZIP" "$FONT_URL"; then
            warning_message "Failed to download '${FONT_URL}'"
            continue
        fi

        if ! unzip -o "$TMP_ZIP" -d "$FONT_DIR" > /dev/null 2>&1; then
            warning_message "Failed to unzip '${TMP_ZIP}'"
            rm -rf "$TMP_ZIP"
            continue
        fi

        rm -rf "$TMP_ZIP"
        message "Installed Font" "${FONT_NAME}"
        
    done < "${FONTS_LIST}"

    if ! fc-cache -fv; then
        error_message "Failed to 'fc-cache -fv'"
    fi
    successful
}

function install_rust() {
    if command -v cargo &> /dev/null && command -v rustup &> /dev/null; then
        return
    fi

    start_step_message "Installing Cargo and Rustup"
    if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh; then
        error_message "Failed to install Cargo and Rustup"
    fi

    message "Next Steps" "Execute 'source \"$HOME/.cargo/env\"'"
    successful
}
