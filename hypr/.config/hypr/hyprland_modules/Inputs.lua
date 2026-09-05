--╔══════════════════════════════════════╗--
--║   		  	   INPUTS   		     ║--
--╚══════════════════════════════════════╝--


---------------
---- INPUT ----
---------------

hl.config({
	input = {
		kb_layout = "br",
		kb_variant = "abnt2",
		kb_model = "abnt2",
		kb_options = "",
		kb_rules = "",
		repeat_rate = 20,
		repeat_delay = 350,

		follow_mouse = 1,

		sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

		touchpad = {
			natural_scroll = false,
		},
	},
})


---------------
----Devices----
---------------
-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})