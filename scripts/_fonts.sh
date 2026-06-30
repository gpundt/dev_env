#!/bin/bash
source ./_helpers.sh

# ── Fonts ────────────────
function install_fonts() {
    start_step_message "Adding Fonts"
    mkdir -p ~/.local/share/fonts
    while IFS= read -r FONT_URL || [[ -n "$FONT_URL" ]]; do
        [ -z "$FONT_URL" ] && continue      # skip empty lines
        start_step_message "${FONT_URL}" "substep"

        FONT_NAME=$(basename "$FONT_URL" .zip)
        FONT_DIR=~/.local/share/fonts/$FONT_NAME
        TMP_ZIP=/tmp/${FONT_NAME}.zip

        mkdir -p "$FONT_DIR"

        if ! curl -Lo "$TMP_ZIP" "$FONT_URL"; then
            error_message "Failed to download '${FONT_URL}'"
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
    FONTS_CONFIG_SUCCESS=true
}