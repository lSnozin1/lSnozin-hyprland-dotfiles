<div align="center">

# Made pretty much for me only, feel free to use though, or take ideas i guess

</div>

## Components

> Things used by this setup, though i think you can change the majority with no problems, maybe


### Session / Environment:

|     **Category**      | **Application**                               | **Description**                                                       |
| :-------------------: | :-------------------------------------------- | :-------------------------------------------------------------------- |
|    **Compositor**     | [Hyprland][hyprland]                          | Kinda Obvious (CashyOS - Arch BTW)                                    |
|  **Display Manager**  | [SDDM][sddm]                                  | QML-based display manager for Wayland and X11                         |
|   **Desktop Shell**   | [Noctalia][noctalia]                          | A desktop shell that handles System bars, toasts, & ALOT of things    |
|     **Launcher**      | [Rofi][rofi]                                  | Window switcher, application launcher, and dmenu replacement.         |
|    **QT Theming**     | [qt6ct][qt6ct]                                | Required to fix inconsistencies on QT apps (Dolphin for example)      |


### Terminal / System:

|     **Category**      | **Application**                               | **Description**                                                       |
| :-------------------: | :-------------------------------------------- | :-------------------------------------------------------------------- |
|     **Terminal**      | [Kitty][kitty]                                | Fast, feature-rich, GPU-based terminal emulator.                      |
|       **Shell**       | [Fish][fish]                                  | User-friendly command line shell                                      |
|    **Info fetch**     | [Fastfetch][fastfetch]                        | Fastfetch is a neofetch-like tool for fetching system information     |
|  **CLI Text Editor**  | [Vim][vim]                                    | Advanced modal terminal text editor                                   |
|                       | [nano][nano]                                  | Simple and user-friendly terminal text editor                         |
|  **System Monitor**   | [Btop][btop]                                  | A really simple monitor of resources that uses the terminal.          |
|     **AUR Helper**    | [yay][yay]                                    | Primary pacman wrapper and AUR helper                                 |
|                       | [paru][paru]                                  | Feature-packed secondary AUR helper                                   |


### Files:

|     **Category**      | **Application**                               | **Description**                                                       |
| :-------------------: | :-------------------------------------------- | :-------------------------------------------------------------------- |
|   **File Manager**    | [Dolphin][dolphin]                            | Visually Appealing, works good, main file manager                     |
|                       | [Thunar][thunar]                              | Has a better search system than dolphin, secondary file manager       |
|   **File Searcher**   | [FSearch][fsearch]                            | Fast standalone GTK file search utility                               |


### Audio:

|     **Category**      | **Application**                               | **Description**                                                       |
| :-------------------: | :-------------------------------------------- | :-------------------------------------------------------------------- |
|    **Audio Server**   | [PipeWire][pipewire]                          | Low-latency audio server and session manager                          |
|                       | [WirePlumber][wireplumber]                    | Session manager for PipeWire                                          |
|   **Audio Control**   | [Pavucontrol][pavucontrol]                    | Graphical audio volume controller                                     |
|                       | [alsamixer][alsamixer]                        | Terminal-based audio mixer                                            |


### Midia Capture / Viewer

|     **Category**      | **Application**                               | **Description**                                                       |
| :-------------------: | :-------------------------------------------- | :-------------------------------------------------------------------- |
|    **Screenshot**     | [Hyprshot][hyprshot]                          | CLI screenshot utility tailored for Hyprland                          |
|                       | [Grimblast][grimblast]                        | Allows for 'annotation' on screenshots                                |
|  **Screen Recorder**  | [GPU Screen Recorder][gpu-screen-recorder]    | Used from a Noctalia plugin                                           |
|   **Image Viewer**    | [Satty][satty]                                | Default Wayland image viewer and annotation tool                      |
|   **Media Player**    | [MPV][mpv]                                    | Video player with `modernz` script.                                   |


### Font / Icons

|     **Category**      | **Application**                               | **Description**                                                       |
| :-------------------: | :-------------------------------------------- | :-------------------------------------------------------------------- |
|       **Font**        | Adwaita Sans / Adwaita Mono                   | Default system UI and terminal fonts                                  |
|    **Icon Theme**     | [Adwaita][adwaita]                            | Default GNOME desktop icon theme                                      |


### Not Essential / Whatevs

|     **Category**      | **Application**                               | **Description**                                                       |
| :-------------------: | :-------------------------------------------- | :-------------------------------------------------------------------- |
|    **Code Editor**    | [VS Code][vscode]                             | Visually good, extensive code editor for all occasions                |
|     **Browser**       | [Firefox][firefox]                            | Fast, privacy-focused default web browser                             |
|    **FPS Overlay**    | [MangoHud][mangohud]                          | Simple overlay for fps and general performance in games               |
|                       | [MangoJuice][mangojuice]                      | Graphical configurator for MangoHud                                   |
| **Wallpaper Manager** | [Waywallen][waywallen]                        | Wallpaper Engine for Linux                                            |
| **Clipboard Manager** | [Cliphist][cliphist]                          | Wayland clipboard manager (Not really needed with Noctalia)           |



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
[btop]: https://github.com/aristocratos/btop
[dolphin]: https://github.com/kde/dolphin
[thunar]: https://github.com/xfce-mirror/thunar
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