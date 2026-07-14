#!/bin/bash
source ./_helpers.sh

# ── Global Variables ────────────────────────────────────────────────────────────────
FONTS_LIST=$(pwd)/../deps/fonts/fonts.list
FONTS_SUCCESS=false


# ──── Font Configuration ────────────────────────────────────────────────────────────
function install_fonts() {
    start_step_message "Adding Fonts"
    mkdir -p ~/.local/share/fonts
    while IFS= read -r FONT_URL || [[ -n "$FONT_URL" ]]; do
        [ -z "$FONT_URL" ] && continue      # skip empty lines
        start_step_message "${FONT_URL}" "substep"

        FONT_NAME=$(basename "$FONT_URL" .zip)
        FONT_DIR=~/.local/share/fonts/$FONT_NAME
        TMP_ZIP=/tmp/${FONT_NAME}.zip

        # Skip if this font is already installed (dir exists and has font files)
        if [ -d "$FONT_DIR" ] && find "$FONT_DIR" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -print -quit | grep -q .; then
            info_message "${FONT_NAME} already installed... skipping"
            continue
        fi

        mkdir -p "$FONT_DIR"

        if ! pull_font_url "$FONT_URL" "$TMP_ZIP"; then
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
    FONTS_SUCCESS=true
}

function pull_fonts() {
    start_step_message "Pulling Fonts"
    while IFS= read -r FONT_URL || [[ -n "$FONT_URL" ]]; do
        [ -z "$FONT_URL" ] && continue      # skip empty lines
        start_step_message "${FONT_URL}" "substep"

        FONT_NAME=$(basename "$FONT_URL" .zip)
        OUTPUT_ZIP=../deps/fonts/${FONT_NAME}.zip

        # Skip if this font is already installed (dir exists and has font files)
        if [ -d "$FONT_DIR" ] && find "$OUTPUT_DIR" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -print -quit | grep -q .; then
            info_message "${FONT_NAME} already pulled... skipping"
            continue
        fi

        if ! pull_font_url "$FONT_URL" "$OUTPUT_ZIP"; then
            return
        fi
        
    done < "${FONTS_LIST}"
    successful
}

function pull_font_url() {
    local url=$1
    local tmp_zip=$2

    if ! curl -Lo "$tmp_zip" "$url"; then
        error_message "Failed to download '${url}'"
        return 1
    fi

    return 0
}