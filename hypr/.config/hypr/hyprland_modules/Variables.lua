--╔══════════════════════════════════════╗--
--║   		  	 Variables   		 	 ║--
--╚══════════════════════════════════════╝--

-- https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({
	-- General section of the hyprland variables
	general = {
		gaps_in = 5,			-- gaps between windows
		gaps_out = 20,			-- gaps between windows and screen edges
		border_size = 2, 		-- size of the border around windows

		col = {
			active_border = { colors = { "rgba(f47fffee)", "rgba(f47fffee)" }, angle = 45 },  	-- color of the border around focused windows	
			inactive_border = "rgba(595959aa)",													-- color of the border around unfocused windows
		},

		resize_on_border = false,		-- enables resizing windows by clicking and dragging on borders and gaps

		allow_tearing = false,			-- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on

		layout = "dwindle",				-- which layout to use. ["dwindle"/"master"/"scrolling"/"monocle"]
	},

	-- Decoration section of the hyprland variables
	decoration = {
		rounding = 10,					-- rounded corners’ radius (in layout px)
		rounding_power = 1,				-- adjusts the curve used for rounding corners, larger is smoother, 2.0 is a circle, 4.0 is a squircle. [2.0 - 10.0]

		active_opacity = 1.0,			-- opacity of active windows. [0.0 - 1.0]
		inactive_opacity = 1.0,			-- opacity of inactive windows. [0.0 - 1.0]
		
		blur = {
			enabled = true,				-- enable kawase window background blur / this section

			size = 3,					-- blur size (distance)
			passes = 1,					-- the amount of passes to perform
			vibrancy = 0.1696,			-- Increase saturation of blurred colors. [0.0 - 1.0]

		},
		
		shadow = {
			enabled = false,			-- Enable drop shadows on windows / this section

			range = 4,					-- Shadow range (“size”) in layout px
			render_power = 3,			-- in what power to render the falloff (more power, the faster the falloff) [1 - 4]
			color = 0xee1a1a1a,			-- shadow’s color. Alpha dictates shadow’s opacity.
		},
	},
	-- Animations section of the hyprland variables
	animations = {
		enabled = true,					-- Enable animations, configurable on Animations.lua
	},
	-- Misc section of the hyprland variables
	misc = {
		disable_hyprland_logo = false, 			-- If true disables the random hyprland logo / anime girl background. :(
		disable_scale_notification = false,		-- disables notification popup when a monitor fails to set a suitable scale
		force_default_wallpaper = 1, 			-- Set to 0 or 1 to disable the anime mascot wallpapers
		vrr = 1,								-- controls the VRR (Adaptive Sync) of your monitors. 0 - off, 1 - on, 2 - fullscreen only, 3 - fullscreen with video or game content type [0/1/2/3]
		mouse_move_enables_dpms = false,		-- If DPMS is set to off, wake up the monitors if the mouse moves.
		key_press_enables_dpms = false,			-- If DPMS is set to off, wake up the monitors if a key is pressed.
		name_vk_after_proc = false,				-- Name virtual keyboards after the processes that create them. E.g. /usr/bin/fcitx5 will have hl-virtual-keyboard-fcitx5.
		always_follow_on_dnd = false,			-- Will make mouse focus follow the mouse when drag and dropping. Recommended to leave it enabled, especially for people using focus follows mouse at 0.
		layers_hog_keyboard_focus = false,		-- If true, will make keyboard-interactive layers keep their focus on mouse move (e.g. wofi, bemenu)
		animate_manual_resizes = true,			-- If true, will animate manual window resizes/moves
		animate_mouse_windowdragging = false,	-- If true, will animate windows being dragged by mouse, note that this can cause weird behavior on some curves
		disable_autoreload = false,				-- If true, the config will not reload automatically on save, and instead needs to be reloaded with hyprctl reload. Might save on battery.
		enable_swallow = false,					-- Enable window swallowing
		focus_on_activate = false,				-- Whether Hyprland should focus an app that requests to be focused (an activate request)
		mouse_move_focuses_monitor = true,		-- Whether mouse moving into a different monitor should focus it
		allow_session_lock_restore = false,		-- if true, will allow you to restart a lockscreen app in case it crashes
		session_lock_xray = false,				-- if true, keep rendering workspaces below your lockscreen
		close_special_on_empty = true,			-- close the special workspace if the last window is removed
		on_focus_under_fullscreen = 0,			-- if there is a fullscreen or maximized window, decide whether a tiled window requested to focus should replace it, stay behind or disable the fullscreen/maximized state. 0 - ignore focus request (keep focus on fullscreen window), 1 - takes over, 2 - unfullscreen/unmaximize [0/1/2]
		exit_window_retains_fullscreen = false,	-- whether closing a fullscreen window makes the next focused window to be fullscreened. 0 - disabled, 1 - enabled, 2 - only when closing a grouped window, 3 - only when closing a non-grouped window [0/1/2/3]
		initial_workspace_tracking = 0,			-- if enabled, windows will open on the workspace they were invoked on. 0 - disabled, 1 - single-shot, 2 - persistent (all children too)
		middle_click_paste = true,				-- whether to enable middle-click-paste (aka primary selection)
		render_unfocused_fps = 1,				-- the maximum limit for render_unfocused windows’ fps in the background (see also Window-Rules - render_unfocused)
		disable_xdg_env_checks = true,			-- disable the warning if XDG environment is externally managed
		disable_hyprland_guiutils_check = true,	-- disable the warning if hyprland-guiutils is not installed
		lockdead_screen_delay = 0,				-- delay after which the “lockdead” screen will appear in case a lockscreen app fails to cover all the outputs (5 seconds max)
		enable_anr_dialog = false,				-- whether to enable the ANR (app not responding) dialog when your apps hang
		anr_missed_pings = 0,					-- number of missed pings before showing the ANR dialog
		size_limits_tiled = false,				-- whether to apply min_size and max_size rules to tiled windows
		screencopy_force_8b = false,			-- forces 8 bit screencopy
		disable_watchdog_warning = true,		-- whether to disable the warning about not using start-hyprland
	},

	-- Binds section of the hyprland variables
	binds = {
		pass_mouse_when_bound = false,			-- if disabled, will not pass the mouse events to apps / dragging windows around if a keybind has been triggered.
	},

	-- Xwayland section of the hyprland variables
	xwayland = {
		enabled = true,							-- allow running applications using X11 / this section

		use_nearest_neighbor = true,			-- uses the nearest neighbor filtering for xwayland apps, making them pixelated rather than blurry
		force_zero_scaling = true,				-- forces a scale of 1 on xwayland windows on scaled displays.
		create_abstract_socket = false,			-- Create the abstract Unix domain socket for XWayland connections. (XWayland restart is required for changes to take effect; Linux only)
	},

	-- OpenGL section of the hyprland variables
	opengl = {
		nvidia_anti_flicker = false,			-- reduces flickering on nvidia at the cost of possible frame drops on lower-end GPUs. On non-nvidia, this is ignored.
	},

	-- Render section of the hyprland variables
	render = {
		direct_scanout = 1,						-- Enables direct scanout. Direct scanout attempts to reduce lag when there is only one fullscreen application on a screen (e.g. game). It is also recommended to set this to false if the fullscreen application shows graphical glitches. 0 - off, 1 - on, 2 - auto (on with content type ‘game’)
		expand_undersized_textures = false,		-- Whether to expand undersized textures along the edge, or rather stretch the entire texture.
		xp_mode = false,						-- Disables back buffer and bottom layer rendering.
		ctm_animation = 0,						-- Whether to enable a fade animation for CTM changes (hyprsunset). 2 means “auto” which disables them on Nvidia.
		cm_enabled = false,						-- Whether the color management pipeline should be enabled or not (requires a restart of Hyprland to fully take effect)
		send_content_type = true,				-- Report content type to allow monitor profile autoswitch (may result in a black screen during the switch)
		cm_auto_hdr = 0,						-- Auto-switch to HDR in fullscreen when needed. 0 - off, 1 - switch to cm, hdr, 2 - switch to cm, hdredid
		new_render_scheduling = true,			-- Automatically uses triple buffering when needed, improves FPS on underpowered devices.
		non_shader_cm = 0,						-- Enable CM without shader. 0 - disable, 1 - whenever possible, 2 - DS and passthrough only, 3 - disable and ignore CM issues
		non_shader_cm_interop = 0,				-- 0 - external ctm (hyprsunset, etc.) is disabled in fullscreen, 1 - external ctm is enabled in fullscreen, 2 - external ctm is disabled for fullscreen photo/video/game content types
		commit_timing_enabled = true,			-- Enable commit timing proto. Requires restart
		use_fp16 = 0,							-- Use FP16 buffers internally. 0 - disabled, 1 - enabled, 2 - enabled in hdr mode
		keep_unmodified_copy = 0,				-- Keep unmodified SDR frame copy for screensharing. 0 - disabled, 1 - on, 2 - auto (enabled in HDR with SDR modifiers). Set to 1 if screenshots are transparent.
		use_shader_blur_blend = false,			-- Use experimental blurred bg blending (glitched on rotated screens). Set to true if blur is missing with fp16 or keep_unmodified_copy
		icc_vcgt_enabled = false,				-- Enable sending VCGT ramps to KMS with ICC profiles
		fp16_sdr_tf = 0,						-- Internal workbuffer transfer function for fp16 in SDR mode. 0 - monitor, 1 - linear
	},

	-- Cursor section of the hyprland variables
	cursor = {
		invisible = false,						-- don’t render cursors
		sync_gsettings_theme = false,			-- sync xcursor theme with gsettings, it applies cursor-theme and cursor-size on theme load to gsettings making most CSD gtk based clients use same xcursor theme and size.
		no_hardware_cursors = 0,				-- disables hardware cursors. 0 - use hw cursors if possible, 1 - don’t use hw cursors, 2 - auto (disable when tearing)
	},

	-- Ecosystem section of the hyprland variables
	ecosystem = {
		no_update_news = false,					-- disable the popup that shows up when you update hyprland to a new version.
		no_donation_nag = false,				-- disable the popup that shows up twice a year encouraging to donate.
		enforce_permissions = false,			-- whether to enable permission control.
	},

	-- Quirks section of the hyprland variables
	quirks = {
		prefer_hdr = 0,							-- Report HDR mode as preferred. 0 - off, 1 - always, 2 - gamescope only
	},


	-- Debug section of the hyprland variables
	debug = {
		overlay = false,						-- print the debug performance overlay. Disable VFR for accurate results.
		damage_blink = false,					-- (epilepsy warning!) flash areas updated with damage tracking
		gl_debugging = false,					-- enables OpenGL debugging with glGetError and EGL_KHR_debug, requires a restart after changing
		vfr = true,								-- controls the VFR status of Hyprland. Heavily recommended to leave enabled to conserve resources.
		disable_logs = true,					-- disable logging to a file
		disable_time = true,					-- disables time logging
		damage_tracking = 0,					-- redraw only the needed bits of the display. Do not change. (default: full - 2) monitor - 1, none - 0
		enable_stdout_logs = false,				-- enables logging to stdout
		manual_crash = 0,						-- set to 1 and then back to 0 to crash Hyprland.
		suppress_errors = false,				-- if true, do not display config file parsing errors.
		log_damage = false,						-- enables logging the damage.
		disable_scale_checks = true,			-- disables verification of the scale factors. Will result in pixel alignment and rounding errors.
		error_limit = 0,						-- limits the number of displayed config file parsing errors.
		error_position = 0,						-- sets the position of the error bar. top - 0, bottom - 1
		colored_stdout_logs = false,			-- enables colors in the stdout logs.
		pass = false,							-- enables render pass debugging.
		full_cm_proto = false,					-- claims support for all cm proto features (requires restart)
		ds_handle_same_buffer = true,			-- special case for direct scanout with unmodified buffer
		ds_handle_same_buffer_fifo = true,		-- special case for direct scanout with unmodified buffer unlocks fifo
		fifo_pending_workaround = true,			-- fifo workaround for empty pending list
		render_solitary_wo_damage = true,		-- render solitary window with empty damage
		invalidate_fp16 = 0,					-- Allow fp16 buffer invalidation (invalidation increases performance but produces glitches on some systems). 0 - not allowed, 1 - allowed, 2 - not allowed on nvidia
	},
	
	-- Experimental section of the hyprland variables
	experimental = {
		wp_cm_1_2 = true,						-- allow wp-cm-v1 version 2
	}
})
