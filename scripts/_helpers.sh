#!/bin/bash
# ──── Filepaths ────────────────────────────────────────────────────────────────────
TMUX_CONF_SRC=$(pwd)/../configs/tmux.conf
TMUX_CONF_DST=~/.tmux.conf

KITTY_CONF_SRC=$(pwd)/../configs/kitty.conf
KITTY_CONF_DST=~/.config/kitty/kitty.conf

ALACRITTY_CONFIG_SRC=$(pwd)/../configs/alacritty.toml
ALACRITTY_CONF_DST=/.config/alacritty/alacritty.toml

# ──── Colors ─────────────────────────────────────────────────────────────────────── 
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
RESET="\033[0m"

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
    echo -e "${RED}ERROR${RESET}: $1"
    graceful_exit
}
function warning_message() {
    echo -e "${YELLOW}WARNING${RESET}: $1"
}
function message() {
    echo -e "${PURPLE}$1${RESET}: $2"
}

# ──── Helper Functions ──────────────────────────────────────────────────────────────
function _create_dir() {
    if [ ! -d "$1" ]; then
        start_step_message "$1" "substep"
        if ! sudo mkdir -p "$1"; then
            error_message "Failed to create directory '$1'"
        fi
    fi
}

function _copy_file() {
    start_step_message "$1 -> $2" "substep"
    if ! sudo cp -r $1 $2; then
        error_message "Failed to move $1 to $2"
    fi
}

# ──── Config File Placement ────────────────────────────────────────────────────────
function _place_tmux_config() {
    start_step_message "Placing Tmux Config: '${TMUX_CONF_SRC}' -> '${TMUX_CONF_DST}'"
    _copy_file $TMUX_CONF_SRC $TMUX_CONF_DST
    successful
}

function _place_kitty_config() {
    start_step_message "Placing Kitty Config: '${KITTY_CONF_SRC}' -> '${KITTY_CONF_DST}'"
    mkdir -p ~/.config/kitty
    _copy_file $KITTY_CONF_SRC $KITTY_CONF_DST
    successful
}

function _place_alacritty_config() {
    start_step_message "Placing Alacritty Config: '${ALACRTTY_CONF_SRC}' -> '${ALACRITTY_CONF_DST}'"
    _copy_file $ALACRTTY_CONF_SRC $ALACRITTY_CONF_DST
    successful
}