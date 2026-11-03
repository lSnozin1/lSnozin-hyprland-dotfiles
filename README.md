<div align="center">

# lSnozin's Hyprland Dotfiles

> **Made pretty much for me only, feel free to use though, or take ideas I guess!**  
> *Current state: Beta / Work in progress — functional daily driver on CachyOS (Arch Linux).*

[![OS: CachyOS](https://img.shields.io/badge/OS-CachyOS%20%2F%20Arch-blue?logo=arch-linux)](https://cachyos.org/)
[![Compositor: Hyprland](https://img.shields.io/badge/WM-Hyprland%20(Lua)-00b4d8?logo=hyprland)](https://hyprland.org/)
[![Shell: Fish](https://img.shields.io/badge/Shell-Fish-red?logo=gnubash)](https://fishshell.com/)
[![Terminal: Kitty](https://img.shields.io/badge/Terminal-Kitty-green?logo=kitty)](https://sw.kovidgoyal.net/kitty/)
[![Managed with GNU Stow](https://img.shields.io/badge/Managed%20with-GNU%20Stow-orange)](https://www.gnu.org/software/stow/)

</div>

---

## Overview

This repository holds my personal setup and configurations for a smooth, responsive Wayland desktop experience. Built on top of **CachyOS** with **Hyprland**, it uses a modular **Lua-based Hyprland configuration**, **Noctalia** as a full desktop shell, and **GNU Stow** for painless dotfile deployment.

### Key Highlights:
- **Modular Hyprland in Lua:** Clean split into `DefaultApps`, `Binds`, `AutoStarts`, `Monitors`, `WindowRules`, and more under `hyprland_modules/`.
- **Desktop Shell via Noctalia:** Status bar, toasts, lockscreen, session controls, and sidebar utility panels all handled cohesively.
- **Fast GPU Terminal:** Kitty running with single-instance daemon mode, custom Python tab bar, and instant scratchpad workspaces.
- **Multi-Tier App Philosophy:** Primary GUI tools for comfort, secondary fallbacks for speed/search, and CLI tools for emergency terminal-only workflows (e.g. Dolphin &rarr; Thunar &rarr; Yazi).
- **Automated Hardware Watchdog:** Custom `sysalert.sh` script monitored via a user systemd timer for CPU/GPU temperatures and resource throttling alerts.

---

## Components & Apps

> Things used by this setup. Most items can be swapped to your liking without breaking everything.

### Session / Wayland Environment

| Category | Application | Role / Description |
| :---: | :--- | :--- |
| **Compositor** | [Hyprland][hyprland] | Dynamic tiling Wayland compositor configured through modular Lua files. |
| **Desktop Shell** | [Noctalia][noctalia] | Handles the system bars, toasts, sidebar drawer, lockscreen, and session dialogs. |
| **Display Manager** | [SDDM][sddm] | QML-based login manager with custom `silent` theme (Reimu / Celestial preset). |
| **Launcher** | [Rofi-Wayland][rofi] | Application runner, window switcher, and dmenu backend (with Flatpak desktop support). |
| **Qt Theming** | [qt6ct][qt6ct] | Ensures Qt6/Qt5 applications (like Dolphin) match system dark styling. |
| **Overview** | [Quickshell][quickshell] | Lightweight QML workspace overview switcher triggered via `Alt + Tab`. |

### Terminal & Shell

| Category | Application | Role / Description |
| :---: | :--- | :--- |
| **Terminal** | [Kitty][kitty] | Fast GPU-accelerated terminal emulator with custom tab bar and hidden daemon instance. |
| **Shell** | [Fish][fish] | Friendly interactive shell with autosuggestions and CachyOS optimizations. |
| **System Info Fetch** | [Fastfetch][fastfetch] | Custom `dualfetch.sh` script with Miku ASCII / visual banner, dynamic resize safe-guards. |
| **CLI Text Editors** | [Vim][vim] / [Nano][nano] | Quick terminal editing (Vim for modal work, Nano for quick edits). |
| **AUR Helpers** | [yay][yay] / [paru][paru] | Pacman wrappers and AUR package management. |

### File Management

| Category | Application | Role / Description |
| :---: | :--- | :--- |
| **Primary File Manager** | [Dolphin][dolphin] | Visually appealing, feature-packed main GUI file manager. |
| **Secondary File Manager** | [Thunar][thunar] | Lightweight GTK fallback with quick responsiveness and great search integration. |
| **Terminal File Manager** | [Yazi][yazi] | Blazing fast async terminal/TUI file manager for keyboard-driven workflows & backups. |
| **File Searcher** | [FSearch][fsearch] | Instant standalone GTK file search utility (similar to Everything on Windows). |

### System Monitoring & Alerts

| Category | Application | Role / Description |
| :---: | :--- | :--- |
| **Primary System Monitor** | [Resources][resources] | Clean modern GTK4 monitor for real-time CPU, GPU, memory, and disk utilization. |
| **Secondary Monitor** | [Mission Center][missioncenter] | Detailed hardware performance inspector (Windows Task Manager style). |
| **Terminal Monitor** | [Btop][btop] | Resource monitor on a dedicated Hyprland special scratchpad (`Super + Shift + B`). |
| **Hardware Alert Daemon** | `sysalert.sh` | Custom script + systemd user timer alerting on high CPU/GPU temp, RAM, or VRAM pressure. |

### Audio & Media

| Category | Application | Role / Description |
| :---: | :--- | :--- |
| **Audio Server** | [PipeWire][pipewire] + [WirePlumber][wireplumber] | Low-latency audio server and session router. |
| **Volume Control** | [Pavucontrol][pavucontrol] / [alsamixer][alsamixer] | Graphical and terminal-based sound card / channel mixers. |
| **Screenshot Tool** | [Grimblast][grimblast] / [Hyprshot][hyprshot] | Area / active monitor screen capture with clipboard piping. |
| **Image Viewer / Editor** | [Satty][satty] | Screenshot annotation, arrows, highlight, and crop tool. |
| **Media Player** | [MPV][mpv] | Lightweight, versatile video player with custom scripts (`modernz`). |
| **Screen Recorder** | [GPU Screen Recorder][gpu-screen-recorder] | NVENC/hardware-accelerated screen capture integrated into Noctalia. |

### Theming, Fonts & Extras

| Category | Application | Role / Description |
| :---: | :--- | :--- |
| **UI Fonts** | Adwaita Sans / Adwaita Mono | Default desktop and system font faces. |
| **Icon & Nerd Font** | [Papirus][papirus] / [Adwaita][adwaita] / Symbols Nerd Font | System icon theme and symbol support across terminal and bars. |
| **Clipboard History** | [Cliphist][cliphist] | Wayland clipboard history accessible via Rofi menu (`Super + V`). |
| **Wallpaper Engine** | [Waywallen][waywallen] | Animated and live wallpapers for Wayland. |
| **Gaming Overlays** | [MangoHud][mangohud] / [MangoJuice][mangojuice] | On-screen FPS, frametime, and GPU/CPU stats for Vulkan/OpenGL games. |
| **Code Editor** | [VS Code][vscode] | Main code and workspace editor. |
| **Web Browser** | [Firefox][firefox] | Daily driver privacy-focused browser. |
| **Gaming Client** | [Sober][sober] | Roblox runtime on Linux with logging launcher wrapper in `.local/bin`. |

---

## Repository Structure

```
lSnozin-hyprland-dotfiles/
├── .config/
│   ├── btop/              # Btop themes and layout configuration
│   ├── fastfetch/         # Dualfetch script, custom JSON configs, and Miku banner
│   ├── fish/              # Fish shell config, greeting logic, and functions
│   ├── hypr/              # Hyprland root config + modular Lua scripts
│   │   ├── hypridle.conf  # Idle screen timeout and lock settings
│   │   ├── hyprland.lua   # Master loader for modules
│   │   ├── hyprland_modules/ # DefaultApps, Binds, Monitors, AutoStarts, etc.
│   │   └── utilities/     # Workspace overview and helper scripts
│   ├── kitty/             # Terminal configuration, custom tab bar, and themes
│   ├── noctalia/          # Noctalia shell configuration and custom palettes
│   ├── rofi/              # Application launcher themes, scripts, and layouts
│   └── systemd/user/      # User timers and services (e.g., sysalert)
├── .local/
│   ├── bin/               # Custom scripts (sysalert.sh, sober-logged)
│   └── share/             # Custom desktop entries (.desktop files)
├── sddm/                  # SDDM theme (silent), avatars, and sddm.conf
├── .stowrc                # Default Stow arguments (--no-folding, --target=~)
└── .stow-local-ignore     # Files ignored during stow symlinking
```

---

## Installation & Deployment

> [!IMPORTANT]  
> Always back up your existing configurations in `~/.config` before stowing, especially if you already have existing `hypr`, `fish`, or `kitty` directories!

### 1. Prerequisites (Arch / CachyOS)

Ensure you have `git` and `stow` installed:

```bash
sudo pacman -S git stow
```

Install core dependencies (adjust according to what you wish to use):

```bash
# Core Wayland & Shell
sudo pacman -S hyprland kitty fish fastfetch rofi-wayland pipewire wireplumber pavucontrol

# File managers & tools
sudo pacman -S dolphin thunar yazi fsearch btop

# Media, Screenshots & Utilities
sudo pacman -S satty mpv cliphist playerctl

# AUR helpers / additional tools (using yay or paru)
yay -S noctalia-git grimblast-git resources mission-center qt6ct ttf-nerd-fonts-symbols
```

### 2. Clone the Repository

Clone this repository into your home or projects directory:

```bash
git clone https://github.com/lSnozin/lSnozin-hyprland-dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 3. Deploy with GNU Stow

The repository includes a `.stowrc` file configured with `--no-folding` and `--target=~`. To symlink all configurations to your home directory:

```bash
stow .
```

If you encounter conflicts with files that already exist, you can adopt or back them up:

```bash
# To inspect what stow will do without modifying anything:
stow --simulate -v .

# If you want stow to link and replace existing files (use with caution!):
stow --adopt .
```

### 4. Optional Configurations

#### A. Hardware Watchdog Alert Service
To enable the system temperature and memory alert daemon:

```bash
systemctl --user daemon-reload
systemctl --user enable --now sysalert.timer
```

#### B. Display Manager (SDDM Theme)
If you want to use the included `silent` SDDM theme:

```bash
sudo cp -r sddm/usr/share/sddm/themes/silent /usr/share/sddm/themes/
sudo cp sddm/etc/sddm.conf /etc/sddm.conf
# Set your user profile icon (optional):
sudo cp sddm/usr/share/sddm/faces/lsnozin.face.icon /usr/share/sddm/faces/$USER.face.icon
```

#### C. Monitor Setup
The monitor configuration is defined in [.config/hypr/hyprland_modules/Monitors.lua](file:///.config/hypr/hyprland_modules/Monitors.lua) and [DefaultApps.lua](file:///.config/hypr/hyprland_modules/DefaultApps.lua).  
Check your connected outputs with:

```bash
hyprctl monitors
```

Then edit `Monitors.lua` and `DefaultApps.lua` to match your display names (`DP-1`, `HDMI-A-1`, etc.), refresh rates, and preferred positions.

---

## Keybindings Quick Reference

The main modifier key is `SUPER` (Windows key). Here are the primary shortcuts:

### Applications & Launchers
| Shortcut | Action |
| :--- | :--- |
| `Super + Shift + Q` | Launch Kitty terminal (single-instance) |
| `Super + Q` | Toggle permanent Kitty terminal scratchpad |
| `Super + Escape` | Emergency terminal (Kitty running Fish with `--no-config`) |
| `Super + E` | Launch primary file manager (**Dolphin**) |
| `Super + Shift + E` | Launch secondary file manager (**Thunar**) |
| `Super + R` | Application launcher menu (**Rofi**) |
| `Super + B` | Focus or toggle primary resource manager (**Resources**) |
| `Super + Shift + B` | Toggle permanent **Btop** resource scratchpad |
| `Super + V` | Open clipboard manager history (**Cliphist** + Rofi) |

### Window & Workspace Management
| Shortcut | Action |
| :--- | :--- |
| `Super + C` | Close focused window |
| `Super + Shift + C` | Force kill window |
| `Super + F` | Toggle fullscreen |
| `Super + L` | Toggle floating mode |
| `Super + P` | Toggle pseudo-tiling |
| `Super + J` | Toggle layout split (dwindle) |
| `Super + [0-9]` | Switch to workspace 1–10 |
| `Super + Shift + [0-9]` | Move active window to workspace 1–10 |
| `Super + Left / Right / Up / Down` | Move window focus |
| `Super + LMB (drag)` | Drag and move window |
| `Super + RMB (drag)` | Resize window |
| `Alt + Tab` | Workspace overview switcher |

### Shell, Media & Screenshot
| Shortcut | Action |
| :--- | :--- |
| `Super + U` | Toggle **Noctalia** sidebar drawer |
| `Super + Shift + R` | Toggle Noctalia bookmarks panel |
| `Super + N` | Lock screen (Noctalia) |
| `Super + M` | Exit Hyprland session / hyprshutdown |
| `Super + Print` | Snip selection to clipboard (`grimblast --freeze copy area`) |
| `Super + Shift + Print` | Snip selection and annotate with **Satty** |
| `Super + F13` | Instant snapshot of active monitor to file & clipboard |
| `Media Keys` / `Super + KP_*` | Volume, microphone, and audio player controls |

---

<!-- =============== -->
<!-- Reference Links -->
<!-- =============== -->

[hyprland]: https://github.com/hyprwm/Hyprland
[sddm]: https://github.com/sddm/sddm
[noctalia]: https://github.com/noctalia-dev/noctalia
[kitty]: https://github.com/kovidgoyal/kitty
[fish]: https://fishshell.com/
[fastfetch]: https://github.com/fastfetch-cli/fastfetch
[rofi]: https://github.com/davatorium/rofi
[quickshell]: https://github.com/outfoxxed/quickshell
[btop]: https://github.com/aristocratos/btop
[resources]: https://github.com/nokyan/resources
[missioncenter]: https://missioncenter.io/
[dolphin]: https://github.com/kde/dolphin
[thunar]: https://github.com/xfce-mirror/thunar
[yazi]: https://github.com/sxyazi/yazi
[fsearch]: https://github.com/cboxdoerfer/fsearch
[pipewire]: https://pipewire.org/
[wireplumber]: https://pipewire.pages.freedesktop.org/wireplumber/
[pavucontrol]: https://freedesktop.org/software/pulseaudio/pavucontrol/
[alsamixer]: https://alsa-project.org/
[vim]: https://www.vim.org/
[nano]: https://www.nano-editor.org/
[vscode]: https://code.visualstudio.com/
[yay]: https://github.com/Jguer/yay
[paru]: https://github.com/Morganamilo/paru
[adwaita]: https://gitlab.gnome.org/GNOME/adwaita-icon-theme
[papirus]: https://github.com/PapirusDevelopmentTeam/papirus-icon-theme
[qt6ct]: https://github.com/trialuser02/qt6ct
[firefox]: https://www.mozilla.org/firefox/
[hyprshot]: https://github.com/Gustash/Hyprshot
[grimblast]: https://github.com/hyprwm/contrib/tree/main/grimblast
[gpu-screen-recorder]: https://github.com/BrycensRanch/gpu-screen-recorder-git-copr
[cliphist]: https://github.com/sentriz/cliphist
[mangohud]: https://github.com/flightlessmango/MangoHud
[mangojuice]: https://github.com/radiolamp/mangojuice
[satty]: https://github.com/gabm/Satty
[mpv]: https://mpv.io/
[waywallen]: https://github.com/waywallen/waywallen
[sober]: https://sober.vinegarhq.org/
