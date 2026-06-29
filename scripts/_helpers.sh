#!/bin/bash
# ──── Filepaths ────────────────────────────────────────────────────────────────────
TMUX_CONF_SRC=$(pwd)/../configs/tmux.conf
TMUX_CONF_DST=~/.tmux.conf

KITTY_CONF_SRC=$(pwd)/../configs/kitty.conf
KITTY_CONF_DST=~/.config/kitty/kitty.conf

ALACRITTY_CONFIG_SRC=$(pwd)/../configs/alacritty.toml
ALACRITTY_CONF_DST=/.config/alacritty/alacritty.toml

APT_DEPS_DIR=$(pwd)/../deps/apt
APT_DEPS_LIST=$APT_DEPS_DIR/apt.list

GIT_REPOS_DIR=$(pwd)/../deps/git
GIT_REPOS_LIST=$GIT_REPOS_DIR/git.list

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
    if ! sudo cp -r $1 $2; then
        error_message "Failed to move $1 to $2"
    fi
}

function install_apt_deps() {
    if [[ "$1" == "offline" ]]; then
        start_step_message "Installing Downloaded .deb Packages from '${APT_DEPS_DIR}'"
        if ! sudo dpkg -i $APT_DEPS_DIR/*.deb; then
            error_message "Failed to 'sudo dpkg -i ${APT_DEPS_DIR}/*.deb'"
        fi
    else
        start_step_message "Installing Apt Deps Listed in '${APT_DEPS_LIST}'"
        if ! sudo apt install -y $(cat $APT_DEPS_LIST); then
            error_message "Failed to install apt deps from ${APT_DEPS_LIST}"
        fi
    fi
    successful
}

function pull_git_repos() {
    start_step_message "Pulling Git Repos Listed in '${GIT_REPOS_LIST}'"
    while IFS= read -r REPO; do
        [ -z "$REPO" ] && continue      # skip empty lines
        start_step_message "${REPO}" "substep"
        if ! git clone "$REPO" $GIT_REPOS_DIR/; then
            error_message "Failed to 'git clone ${REPO}'"
        fi
    done < "${GIT_REPOS_LIST}"
    successful
}

# ──── Config File Placement ────────────────────────────────────────────────────────
function place_tmux_config() {
    start_step_message "Placing Tmux Config: '${TMUX_CONF_SRC}' -> '${TMUX_CONF_DST}'"
    _copy_file $TMUX_CONF_SRC $TMUX_CONF_DST
    successful
}

function place_kitty_config() {
    start_step_message "Placing Kitty Config: '${KITTY_CONF_SRC}' -> '${KITTY_CONF_DST}'"
    mkdir -p ~/.config/kitty
    _copy_file $KITTY_CONF_SRC $KITTY_CONF_DST
    successful
}

function place_alacritty_config() {
    start_step_message "Placing Alacritty Config: '${ALACRTTY_CONF_SRC}' -> '${ALACRITTY_CONF_DST}'"
    _copy_file $ALACRTTY_CONF_SRC $ALACRITTY_CONF_DST
    successful
}
