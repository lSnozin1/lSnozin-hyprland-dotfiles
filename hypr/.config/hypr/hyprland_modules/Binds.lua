--╔══════════════════════════════════════╗--
--║   		  System Keybinds   		 ║--
--╚══════════════════════════════════════╝--

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more

-- binds or whatever that are commented are alternate options for a bind that i don't prefer, don't use anymore, or idk

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

------------------
---- LAUNCHER ----
------------------

hl.bind(mainMod .. " + SHIFT + Q", 		hl.dsp.exec_cmd(TERMINAL .. " --single-instance"), { description = "Launch terminal" })
hl.bind(mainMod .. " + escape", 		hl.dsp.exec_cmd("kitty fish --no-config"), { description = "Launch terminal backup" })

hl.bind(mainMod .. " + E", 				hl.dsp.exec_cmd(MAIN_FILE_MANAGER), { description = "Launch main file manager" })
hl.bind(mainMod .. " + SHIFT + E", 		hl.dsp.exec_cmd(SECONDARY_FILE_MANAGER), { description = "Launch secondary file manager" })

hl.bind(mainMod .. " + R", 				hl.dsp.exec_cmd(MENU), { description = "Launch menu" })

hl.bind(mainMod .. " + B", 				hl.dsp.exec_cmd("pidof resources > /dev/null && hyprctl dispatch 'hl.dsp.workspace.toggle_special(\"resources\")' || " .. MAIN_RESOURCE_MANAGER), { description = "Focus or Open Main Resource Manager" })


--	hl.bind(mainMod .. " + SHIFT + B",		hl.dsp.exec_cmd(SECONDARY_RESOURCE_MANAGER), { description = "Launch Secondary Resource Manager"})
--  hl.bind(mainMod .. " + SHIFT + B",		hl.dsp.exec_cmd("alacritty -e " .. SECONDARY_RESOURCE_MANAGER), { description = "Launch Secondary Resource Manager"})
-----------------
---- WINDOWS ----1
-----------------

-- Window manipulation
hl.bind(mainMod .. " + C", 				hl.dsp.window.close(), { description = "Close window" })
hl.bind(mainMod .. " + SHIFT + C",		hl.dsp.window.kill(), { description = "Force kill window" })

--hl.bind(mainMod .. " + SHIFT +C",   	hl.dsp.exec_cmd("hyprctl kill"), { description = "Kill window" })

hl.bind(mainMod .. " + P", 				hl.dsp.window.pseudo(), { description = "Toggle pseudo" })
hl.bind(mainMod .. " + L", 				hl.dsp.window.float({ action = "toggle" }), { description = "Toggle float" })
hl.bind(mainMod .. " + F", 				hl.dsp.window.fullscreen(), { description = "Toggle fullscreen" })

-- Change focus of workspaces
hl.bind(mainMod .. " + left", 			hl.dsp.focus({ direction = "left" }), { description = "Move focus left" })
hl.bind(mainMod .. " + right", 			hl.dsp.focus({ direction = "right" }), { description = "Move focus right" })
hl.bind(mainMod .. " + up", 			hl.dsp.focus({ direction = "up" }), { description = "Move focus up" })
hl.bind(mainMod .. " + down", 			hl.dsp.focus({ direction = "down" }), { description = "Move focus down" })

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", 		hl.dsp.window.drag(), { mouse = true }, { description = "Drag window" })
hl.bind(mainMod .. " + mouse:273", 		hl.dsp.window.resize(), { mouse = true }, { description = "Resize window" })

-- dwindle only
hl.bind(mainMod .. " + J", 				hl.dsp.layout("togglesplit"), { description = "Toggle split" })

---------------------------
---- GLOBAL WORKSPACES ----
---------------------------
---

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, 		   		hl.dsp.focus({ workspace = i }), { description = "Switch to workspace " .. i })
	hl.bind(mainMod .. " + SHIFT + " .. key,		hl.dsp.window.move({ workspace = i }), { description = "Move window to workspace " .. i })
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", 	hl.dsp.focus({ workspace = "e+1" }), { description = "Switch to next workspace" })
hl.bind(mainMod .. " + mouse_up", 		hl.dsp.focus({ workspace = "e-1" }), { description = "Switch to previous workspace" })


-- Special Workspaces (scratchpads)
hl.bind(mainMod .. " + S", 							hl.dsp.workspace.toggle_special("magic"), { description = "Toggle special workspace 'magic'" })
hl.bind(mainMod .. " + SHIFT + S", 					hl.dsp.window.move({ workspace = "special:magic" }), { description = "Move window to special workspace 'magic'" })

-- 'kitty' workspace
hl.bind(mainMod .. " + Q", 							hl.dsp.workspace.toggle_special("kitty"), { description = "Toggle special workspace that has permanent kitty" })

-- 'btop' workspace
hl.bind(mainMod .. " + SHIFT + B",					hl.dsp.workspace.toggle_special("btop"), { description = "Toggle special workspace that has permanent btop"})

-- hl.bind(mainMod .. " + HOME", 					hl.dsp.workspace.toggle_special("headless_kitty"), { description = "Toggle special workspace 'headless-kitty'" })
-- hl.bind(mainMod .. " + SHIFT + HOME", 			hl.dsp.window.move({ workspace = "special:headless_kitty" }), { description = "Move window to special workspace 'headless-kitty'" })

-------------------
---- UTILITIES ----
-------------------
-- print related keybinds
hl.bind(mainMod .. " + Print", 				hl.dsp.exec_cmd("hyprshot -m region --freeze --clipboard-only"), { description = "Take screenshot with selection" })
hl.bind(mainMod .. " + CTRL + Print", 		hl.dsp.exec_cmd("hyprshot -m output -m active"), { description = "Instant Take screenshot" })
hl.bind(mainMod .. " + SHIFT + Print", 		hl.dsp.exec_cmd("grimblast --freeze save area - | satty --filename -"), { description = "Take screenshot with selection and edition" })

-- cliphist
hl.bind(mainMod .. " + V", 					hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"), { description = "Paste from clipboard history" })

-- Midia keybinds - Requires playerctl
hl.bind("XF86AudioNext", 					hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Next track" })
hl.bind("XF86AudioPause", 					hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/Pause" })
hl.bind("XF86AudioPlay", 					hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/Pause" })
hl.bind("XF86AudioPrev", 					hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Previous track" })

-- Midia keybinds - extras that uses keypad keys
hl.bind(mainMod .. " + KP_Up", 				hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, description = "Increase volume" })
hl.bind(mainMod .. " + KP_Down", 			hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, description = "Decrease volume" })
hl.bind(mainMod .. " + KP_Begin", 			hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, description = "Toggle mute" })
hl.bind(mainMod .. " + KP_Insert", 			hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, description = "Toggle mic mute" })
hl.bind(mainMod .. " + KP_Add",      		hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%+"), { locked = true, description = "Increase mic volume" })
hl.bind(mainMod .. " + KP_Subtract", 		hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%-"), { locked = true, description = "Decrease mic volume" })


--  Opens Workspace Overview (a qml script)
hl.bind("ALT + TAB", hl.dsp.exec_cmd("~/.config/hypr/utilities/scripts/workspace-overview.sh"))






-- Noctalia side bar toggle
hl.bind(mainMod .. " + U",					hl.dsp.exec_cmd("noctalia msg bar-toggle utils"), { description = "Toggle Noctalia Sidebar" })



-- Locks the Pc with Noctalia Lockscreen
hl.bind(mainMod .. " + N",					hl.dsp.exec_cmd("noctalia msg session lock"), { description = "Lock PC" })

-- Closes Hyprland // executes hyprshutdown if available, otherwise it will just exit the session
hl.bind(mainMod .. " + M",					hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"), { description = "Exit Hyprland" })


-- 
-----------------
---- SUBMAPS ----
-----------------

-- hl.bind(mainMod .. " + HOME", hl.dsp.submap("Special_Workspaces"))

-- hl.define_submap("Special_Workspaces", "reset", function()

	-- hl.bind(mainMod .. " + Q", 				hl.dsp.exec_cmd(TERMINAL .. " --single-instance"), { description = "Launch terminal" })

	-- hl.bind(mainMod .. " + Q", 				hl.dsp.workspace.toggle_special("kitty"), { description = "Toggle special workspace that has permanent kitty" })


	-- hl.bind("escape", hl.dsp.submap("reset"))  -- backuo button to leave submap
-- end)


--------------------------------
---- Custom Global Keybinds ----
--------------------------------

local DiscMute = "Scroll_Lock"
hl.bind(DiscMute, 						hl.dsp.pass({ window = "class:^(discord)$" }), { description = "Mutes Mic on discord" })
