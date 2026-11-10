#!/bin/sh
set -eu

qml="$HOME/.config/hypr/utilities/quickshell/workspace-overview.qml"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/workspace-overview"

# Optional: still image (png/jpg/webp) shown on empty workspace cards
wallpaper=""

# Overview already open: cycle the selection instead of starting a new instance
if quickshell ipc --path "$qml" call workspaceOverview cycle >/dev/null 2>&1; then
    exit 0
fi

mkdir -p "$state_dir"
WORKSPACE_OVERVIEW_STATE_DIR="$state_dir"
WORKSPACE_OVERVIEW_SHOW_EMPTY="$(cat "$state_dir/show-empty" 2>/dev/null || true)"
WORKSPACE_OVERVIEW_WALLPAPER="$wallpaper"
export WORKSPACE_OVERVIEW_STATE_DIR WORKSPACE_OVERVIEW_SHOW_EMPTY WORKSPACE_OVERVIEW_WALLPAPER

exec quickshell --path "$qml" --no-duplicate