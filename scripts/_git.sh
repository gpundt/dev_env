#!/bin/bash
source ./_helpers.sh

# ── Git ─────────────────────
GIT_REPOS_DIR=$(pwd)/../deps/git
GIT_REPOS_LIST=$GIT_REPOS_DIR/git.list
GIT_SUCCESS=false


# ── Git Repos ─────────────
function pull_git_repos() {
    start_step_message "Pulling Git Repos Listed in '${GIT_REPOS_LIST}'"

    pushd "$GIT_REPOS_DIR" > /dev/null || {
        error_message "Failed to 'pushd ${GIT_REPOS_DIR}'"
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

    popd > /dev/null || {
        error_message "Failed to 'popd'"
        return
    }
    successful
    GIT_SUCCESS=true
}