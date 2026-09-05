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
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("noctalia >/dev/null 2>&1 &")
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP & gnome-keyring-daemon --start --components=secrets")
	hl.exec_cmd("sleep 5 && ~/Applications/waywallen-0.3.7-x86_64.AppImage --no-ui")



	-- 	hl.exec_cmd('linux-wallpaperengine --screen-root ' .. PRIMARY_MONITOR .. ' --scaling stretch --fullscreen-pause-only-active --fps 60 --assets-dir "/mnt/SO/Program Files (x86)/Steam/steamapps/common/wallpaper_engine/assets" "/mnt/SO/Program Files (x86)/Steam/steamapps/workshop/content/431960/2799877694/"')	hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
	-- 	hl.exec_cmd('linux-wallpaperengine --screen-root ' .. MONITOR2 .. ' --scaling stretch --fullscreen-pause-only-active --fps 60 --assets-dir "/mnt/SO/Program Files (x86)/Steam/steamapps/common/wallpaper_engine/assets" "/mnt/SO/Program Files (x86)/Steam/steamapps/workshop/content/431960/2225690388/"') 
	--  hl.exec_cmd(terminal)
	--  hl.exec_cmd("nm-applet")
	--  hl.exec_cmd("waybar & hyprpaper & firefox")
end)
