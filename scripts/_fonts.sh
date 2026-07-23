#!/bin/bash
source ./_helpers.sh

# ── Global Variables ────────────────────────────────────────────────────────────────
FONTS_LIST=$(pwd)/../deps/fonts/fonts.list
FONT_DST_DIR=~/.local/share/fonts/
FONTS_SUCCESS=false


# ──── Font Configuration ────────────────────────────────────────────────────────────
function install_fonts() {
    start_step_message "Adding Fonts"
    mkdir -p ~/.local/share/fonts

    if [[ "$1" == "offline" ]]; then
        info_message "Offline Install - Skipping pull..."
    else 
        if ! pull_fonts; then
            return
        fi
    fi

    for FONT_FILE in $(find ../deps/fonts -maxdepth 1 -name "*.zip" -type f); do
        local file_name=$(basename "$FONT_FILE")
        local font_name=$(basename "$FONT_FILE" .zip)

        CURRENT_FONT_DST=$FONT_DST_DIR/$font_name
        # Skip if this font is already installed (dir exists and has font files)
        if [ -d "$CURRENT_FONT_DST" ] && find "$CURRENT_FONT_DST" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -print -quit | grep -q .; then
            info_message "${FONT_NAME} already installed... skipping"
            continue
        fi

        mkdir -p "$CURRENT_FONT_DST"
        if ! unzip -o "$FONT_FILE" -d "$CURRENT_FONT_DST" > /dev/null 2>&1; then
            error_message "Failed to unzip '${FONT_FILE}'"
            return
        fi

        message "Installed Font" "${FONT_FILE}"
    done

    if ! fc-cache -fv; then
        error_message "Failed to 'fc-cache -fv'"
        return
    fi

    successful
    FONTS_SUCCESS=true
}

function pull_fonts() {
    start_step_message "Pulling Fonts Listed in '${FONTS_LIST}'"
    while IFS= read -r FONT_URL || [[ -n "$FONT_URL" ]]; do
        [ -z "$FONT_URL" ] && continue      # skip empty lines

        FONT_NAME=$(basename "$FONT_URL" .zip)
        OUTPUT_ZIP=../deps/fonts/${FONT_NAME}.zip

        # Skip if this font is already installed (dir exists and has font files)
        if [ -f "$OUTPUT_ZIP" ]; then
            info_message "${FONT_NAME} already pulled... skipping"
            continue
        fi

        if ! pull_from_url "$FONT_URL" "$OUTPUT_ZIP"; then
            error_message "Failed to pull font url: '${FONT_URL}'"
            return 1
        fi
        
    done < "${FONTS_LIST}"
    successful
}