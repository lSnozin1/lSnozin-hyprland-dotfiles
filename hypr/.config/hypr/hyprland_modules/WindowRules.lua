--╔══════════════════════════════════════╗--
--║   		    Window Rules   		 	 ║--
--╚══════════════════════════════════════╝--


-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful
package.path = package.path .. ";" .. debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") .. "?.lua"
local WS = require("Workspaces")

local suppressMaximizeRule = hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },
	
	suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },

	move = "20 monitor_h-120",
	float = true,
})

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({
	name = "no-gaps-wtv1",
	match = { float = false, workspace = "w[tv1]" },
	border_size = 0,
	rounding = 0,
})
hl.window_rule({
	name = "no-gaps-f1",
	match = { float = false, workspace = "f[1]" },
	border_size = 0,
	rounding = 0,
})


-- windows rule for Workspace 1 & 4 (firefox profiles)
local perfil1 = "Main"
local perfil1Workspace = WS.WEB

local perfil2 = "kitty"
local perfil2Workspace = WS.WEB_KITTY

local firefoxHandled = {}

local function checkAndMove(w)
    if w == nil or firefoxHandled[w.pid] then return end
	
    if w.title:match("— " .. perfil1 .. " —") then
        hl.dispatch(hl.dsp.window.move({ workspace = perfil1Workspace, follow = true, window = w }))
        firefoxHandled[w.pid] = true
    elseif w.title:match("— " .. perfil2 .. " —") then
        hl.dispatch(hl.dsp.window.move({ workspace = perfil2Workspace, follow = true, window = w }))
        firefoxHandled[w.pid] = true
    end
end

hl.on("window.open", checkAndMove)
hl.on("window.title", checkAndMove)


-- window rule for Workspace 2 (Code)
hl.window_rule({
	name = "set-vscode-workspace",
	match = { class = "code" },
	workspace = WS.CODE,
})

-- window rule for Workspace 3 (Games)
hl.window_rule({
	name = "set-games-workspace",
	match = { class = "org.vinegarhq.Sober" },
	workspace = WS.GAMES,
})

-- window rule for Workspace 10 (discord)
hl.window_rule({
	name = "set-discord-workspace",
	match = { class = "discord" },
	workspace = WS.DISCORD,
})