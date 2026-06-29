#!/bin/bash
source ./_helpers.sh

function _pull_apt_deps() {
    start_step_message "Downloading Apt Packages and Storing in '${APT_DEPS_DIR}'"
}

function main() {
    _pull_apt_deps
    pull_git_repos
}
main