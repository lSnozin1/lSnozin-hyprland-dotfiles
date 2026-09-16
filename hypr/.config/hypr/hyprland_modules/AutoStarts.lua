--╔══════════════════════════════════════╗--
--║   		  	Auto Starts   		 	 ║--
--╚══════════════════════════════════════╝--

-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function()

	--noctalia (only kinda slightly important (arguably more important than hyprland itself (oky not really but still)))
	hl.exec_cmd("noctalia >/dev/null 2>&1 &")

	-- Shares session info so background features like screen sharing and file pickers work properly
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

	-- Starts the password vault so apps like VS Code or Git can store and unlock your saved logins
	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")

	-- Sets 'DP-1' (use monitor ID with hyprctl monitors to see) as your main monitor so older/XWayland games and apps open on your primary screen
	hl.exec_cmd("xrandr --output DP-1 --primary")

	-- headless kitty (not that that important but helps with kitty performance and resource usage by a noticiable margin)
	hl.exec_cmd("kitty --start-as=hidden --single-instance")

	-- permanent kitty for special workspace 'kitty' (not rlly important) 
	hl.exec_cmd("sleep 5 && kitty --class kitty-permanent --single-instance")

	-- permanent btop for special workspace 'btop' (not rlly important) (not part of single instance to allow for custom layout, uses more resources thanks to it though)
	hl.exec_cmd("sleep 5 && kitty --class btop-permanent -o confirm_os_window_close=1 -o tab_bar_min_tabs=2 -o window_padding_width=0 -e btop")

	-- wallpaper (not that important)
	hl.exec_cmd("sleep 5 && ~/Applications/waywallen-0.3.7-x86_64.AppImage --no-ui")
	
	-- Cliphist clipboard (not that important)
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")

	-- 	hl.exec_cmd('linux-wallpaperengine --screen-root ' .. PRIMARY_MONITOR .. ' --scaling stretch --fullscreen-pause-only-active --fps 60 --assets-dir "/mnt/SO/Program Files (x86)/Steam/steamapps/common/wallpaper_engine/assets" "/mnt/SO/Program Files (x86)/Steam/steamapps/workshop/content/431960/2799877694/"')	hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
	-- 	hl.exec_cmd('linux-wallpaperengine --screen-root ' .. MONITOR2 .. ' --scaling stretch --fullscreen-pause-only-active --fps 60 --assets-dir "/mnt/SO/Program Files (x86)/Steam/steamapps/common/wallpaper_engine/assets" "/mnt/SO/Program Files (x86)/Steam/steamapps/workshop/content/431960/2225690388/"') 
	--  hl.exec_cmd(terminal)
	--  hl.exec_cmd("nm-applet")
	--  hl.exec_cmd("waybar & hyprpaper & firefox")
end)
