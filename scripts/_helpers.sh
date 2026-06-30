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

PACKAGE_MANAGER=""
PACKAGE_INSTALL_COMMAND=""

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
