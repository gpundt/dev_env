#!/bin/bash
source ./_helpers.sh

# ──── Determines what ackage manager this host uses (Pacman | Apt) ────────────────
function determine_package_manager() {
    if command -v apt &> /dev/null; then
        message "Package Manager" "Apt"
        PACKAGE_MANAGER="apt" 
        PACKAGE_INSTALL_COMMAND="sudo apt install"
    
    elif command -v pacman &> /dev/null; then
        message "Package Manager" "Pacman"
        PACKAGE_MANAGER="pacman"
        PACKAGE_INSTALL_COMMAND="sudo pacman -s"
    
    else
        error_message "Neither Apt or Pacman package manager found"
    fi
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
        APT_SUCCESS=true

    elif [[ "$1" == "pacman" ]]; then
        start_step_message "Installing Pacman Deps Listed in '${PACMAN_DEPS_LIST}'"
        while IFS= read -r PACKAGE; do
            _individual_dep_install "${PACKAGE}" "${package_manager}" "${package_install_command}"
            if [ $? -ne 0 ]; then
                return
            fi
        done < "${PACMAN_DEPS_LIST}"
        PACMAN_SUCCESS=true

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

function pull_apt_deps() {
    start_step_message "Pulling Apt Dependencies Listed in '${APT_DEPS_LIST}'"
    pushd "$APT_DEPS_DIR" > /dev/null || {
        error_message "Failed to 'pushd ${APT_DEPS_DIR}'"
        return
    }

    while IFS= read -r PACKAGE || [[ -n "$PACKAGE" ]]; do
        [ -z "$PACKAGE" ] && continue  # skip empty lines

        start_step_message "${PACKAGE} -> '${APT_DEPS_DIR}'" "substep"
        if ! sudo apt download -y "${PACKAGE}"; then
            error_message "Failed to download ${PACKAGE}"
            return
        fi
    done < "${APT_DEPS_LIST}"

    popd > /dev/null
    successful
    APT_SUCCESS=true
}