#!/bin/bash

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
    echo -e "\t${CYAN}* $1 *${RESET}"
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
  local width="${3:-30}" # Total width defaults to 30 if not specified
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

  if ! sudo cp -rf "$1" "$2" >/dev/null 2>&1; then
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

# ──── Help Message ───────────────────────────────────────────────────────────────
function help_message() {
  local script_name="$1"

  if [[ "$script_name" == "./install_online.sh" ]]; then
    message "Usage" "${script_name} [OPTION]"
    message "Help"  "${script_name} -h"
    message "Cleanup" "${script_name} --cleanup"
  fi
}

# ──── Configuration Cleanup ───────────────────────────────────────────────────────
function cleanup() {
  start_step_message "Cleaning Up"

  start_step_message "Git"

  pushd "$GIT_REPOS_DIR" > /dev/null || {
      error_message "Failed to 'pushd ${GIT_REPOS_DIR}'"
      return
  }
  if ! find . -mindepth 1 ! -name "$(basename "$GIT_REPOS_LIST")" -delete; then
    error_message "Failed to clean '${GIT_REPOS_DIR}'"
    return
  fi
  popd > /dev/null || {
      error_message "Failed to 'popd'"
      return
  }

  successful
}

# ──── Configuration Recap ─────────────────────────────────────────────────────────
function recap() {
  start_step_message "Installation Recap"

  local package_label package_status
  if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
    package_label="Apt Package Installation"
    package_status="$APT_SUCCESS"
  else
    package_label="Pacman Package Installation"
    package_status="$PACMAN_SUCCESS"
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
    "Golang Installation"
  )
  local -a status_vars=(
    "$TMUX_SUCCESS"
    "$KITTY_SUCCESS"
    "$ALACRITTY_SUCCESS"
    "$ZSH_SUCCESS"
    "$package_status"
    "$GIT_SUCCESS"
    "$FONTS_SUCCESS"
    "$RUST_SUCCESS"
    "$GOLANG_SUCCESS"
  )

  local i
  for i in "${!item_labels[@]}"; do
    _recap_item "${item_labels[$i]}" "${status_vars[$i]}"
  done

  if [[ "$RUST_SUCCESS" == "true" ]]; then
    message "Next Steps" "Execute 'source \"$HOME/.cargo/env\"'"
  fi

  if [[ "$ZSH_SUCCESS" == "true" ]]; then
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
