#!/bin/bash
source ./_helpers.sh

function _verify_package_manager() {
    if command -v apt &> /dev/null; then
        return
    
    else
        error_message "Offline packaging only supports Debian-based distros"
    fi
}

function _pull_apt_deps() {
    start_step_message "Downloading Apt Packages and Storing in '${APT_DEPS_DIR}'"
}

function main() {
    _verify_package_manager
    _pull_apt_deps
    pull_git_repos
}
main