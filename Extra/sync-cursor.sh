#!/usr/bin/env bash
# ==============================================================================
# sync-cursor.sh
# Syncs cursor theme & size from Hyprland's EnvVars.lua across:
#   1. gsettings (GNOME/GTK runtime)
#   2. ~/.icons/default/index.theme (X11 / XWayland root fallback)
#   3. ~/.config/gtk-3.0/settings.ini (GTK3 apps)
#   4. ~/.config/gtk-4.0/settings.ini (GTK4 apps)
#   5. ~/.config/uwsm/env (UWSM session environment)
#   6. Live compositor update via hyprctl setcursor
# ==============================================================================

set -euo pipefail

# 1. Locate EnvVars.lua
ENVVARS_FILE=""
if [ -f "$HOME/Projects/lSnozin-hyprland-dotfiles/.config/hypr/hyprland_modules/EnvVars.lua" ]; then
    ENVVARS_FILE="$HOME/Projects/lSnozin-hyprland-dotfiles/.config/hypr/hyprland_modules/EnvVars.lua"
elif [ -f "$HOME/.config/hypr/hyprland_modules/EnvVars.lua" ]; then
    ENVVARS_FILE="$HOME/.config/hypr/hyprland_modules/EnvVars.lua"
else
    echo "Error: EnvVars.lua not found!" >&2
    exit 1
fi

echo "Reading cursor settings from: $ENVVARS_FILE"

# 2. Extract HYPRCURSOR_THEME (or XCURSOR_THEME fallback)
THEME=$(grep -E 'hl\.env\([[:space:]]*["'\'']HYPRCURSOR_THEME["'\'']' "$ENVVARS_FILE" | head -n1 | sed -E 's/.*hl\.env\([[:space:]]*["'\'']HYPRCURSOR_THEME["'\''][[:space:]]*,[[:space:]]*["'\'']([^"'\'']+)["'\''].*/\1/')
if [ -z "$THEME" ]; then
    THEME=$(grep -E 'hl\.env\([[:space:]]*["'\'']XCURSOR_THEME["'\'']' "$ENVVARS_FILE" | head -n1 | sed -E 's/.*hl\.env\([[:space:]]*["'\'']XCURSOR_THEME["'\''][[:space:]]*,[[:space:]]*["'\'']([^"'\'']+)["'\''].*/\1/')
fi

# Extract HYPRCURSOR_SIZE (or XCURSOR_SIZE fallback)
SIZE=$(grep -E 'hl\.env\([[:space:]]*["'\'']HYPRCURSOR_SIZE["'\'']' "$ENVVARS_FILE" | head -n1 | sed -E 's/.*hl\.env\([[:space:]]*["'\'']HYPRCURSOR_SIZE["'\''][[:space:]]*,[[:space:]]*["'\'']?([0-9]+)["'\'']?.*/\1/')
if [ -z "$SIZE" ]; then
    SIZE=$(grep -E 'hl\.env\([[:space:]]*["'\'']XCURSOR_SIZE["'\'']' "$ENVVARS_FILE" | head -n1 | sed -E 's/.*hl\.env\([[:space:]]*["'\'']XCURSOR_SIZE["'\''][[:space:]]*,[[:space:]]*["'\'']?([0-9]+)["'\'']?.*/\1/')
fi

if [ -z "$THEME" ] || [ -z "$SIZE" ]; then
    echo "Error: Could not determine cursor theme or size from $ENVVARS_FILE" >&2
    exit 1
fi

echo "-> Detected Theme : $THEME"
echo "-> Detected Size  : $SIZE"

# Helper to update a key inside an INI file without touching other lines
update_ini_key() {
    local file="$1"
    local key="$2"
    local value="$3"

    if [ ! -f "$file" ]; then
        mkdir -p "$(dirname "$file")"
        printf "[Settings]\n%s=%s\n" "$key" "$value" > "$file"
        return
    fi

    if grep -q "^[[:space:]]*${key}=" "$file"; then
        sed -i -E "s|^[[:space:]]*${key}=.*|${key}=${value}|" "$file"
    else
        if grep -q "^\[Settings\]" "$file"; then
            sed -i "/^\[Settings\]/a ${key}=${value}" "$file"
        else
            printf "\n[Settings]\n%s=%s\n" "$key" "$value" >> "$file"
        fi
    fi
}

# 3. Apply to gsettings
if command -v gsettings >/dev/null 2>&1; then
    echo "Syncing gsettings..."
    gsettings set org.gnome.desktop.interface cursor-theme "$THEME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size "$SIZE" 2>/dev/null || true
fi

# 4. Apply to ~/.icons/default/index.theme
INDEX_THEME="$HOME/.icons/default/index.theme"
echo "Syncing $INDEX_THEME..."
if [ -f "$INDEX_THEME" ]; then
    if grep -q "^[[:space:]]*Inherits=" "$INDEX_THEME"; then
        sed -i -E "s|^[[:space:]]*Inherits=.*|Inherits=${THEME}|" "$INDEX_THEME"
    else
        printf "Inherits=%s\n" "$THEME" >> "$INDEX_THEME"
    fi
else
    mkdir -p "$(dirname "$INDEX_THEME")"
    cat <<EOF > "$INDEX_THEME"
[Icon Theme]
Name=Default
Inherits=${THEME}
EOF
fi

# 5. Apply to GTK 3.0 and GTK 4.0 settings.ini
for gtk_file in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
    if [ -f "$gtk_file" ]; then
        echo "Syncing $gtk_file..."
        update_ini_key "$gtk_file" "gtk-cursor-theme-name" "$THEME"
        update_ini_key "$gtk_file" "gtk-cursor-theme-size" "$SIZE"
    fi
done

# 6. Keep ~/.config/uwsm/env in sync if present
UWSM_ENV="$HOME/.config/uwsm/env"
if [ -f "$UWSM_ENV" ]; then
    echo "Syncing $UWSM_ENV..."
    sed -i -E "s|^export HYPRCURSOR_THEME=.*|export HYPRCURSOR_THEME=\"${THEME}\"|" "$UWSM_ENV"
    sed -i -E "s|^export XCURSOR_THEME=.*|export XCURSOR_THEME=\"${THEME}\"|" "$UWSM_ENV"
    sed -i -E "s|^export HYPRCURSOR_SIZE=.*|export HYPRCURSOR_SIZE=${SIZE}|" "$UWSM_ENV"
    sed -i -E "s|^export XCURSOR_SIZE=.*|export XCURSOR_SIZE=${SIZE}|" "$UWSM_ENV"
fi

# 7. Apply live to Hyprland compositor
if command -v hyprctl >/dev/null 2>&1; then
    echo "Applying live with hyprctl setcursor..."
    hyprctl setcursor "$THEME" "$SIZE" 2>/dev/null || true
fi

if command -v xsetroot >/dev/null 2>&1; then
    xsetroot -cursor_name left_ptr 2>/dev/null || true
fi

echo "Done! Cursor synchronized to $THEME (size $SIZE)."
