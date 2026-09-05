--╔══════════════════════════════════════╗--
--║   		    Default Apps   		     ║--
--╚══════════════════════════════════════╝--


-- Hyprland default apps

TERMINAL        = "kitty"
MAIN_FILE_MANAGER    = "dolphin"
SECONDARY_FILE_MANAGER = "thunar"
BROWSER         = "firefox"
--EDITOR        = "gnome-text-editor --new-window"
--CALCULATOR    = "gnome-calculator"
MENU            = "XDG_DATA_DIRS=$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:" .. os.getenv("HOME") .. "/.local/share/flatpak/exports/share rofi -show combi -combi-modi 'drun,run' -show-icons"

-- Monitors
MONITOR1        = "DP-1"
MONITOR2        = "HDMI-A-1"
--MONITOR3      = ""
PRIMARY_MONITOR = MONITOR1

-- Workspaces
--NUM_WPM       = 3 -- Number of workspaces per monitor (Max 10)
