--╔══════════════════════════════════════╗--
--║   		     Workspaces   		     ║--
--╚══════════════════════════════════════╝--



-- Monitor Primário (DP-1): Workspaces 1 ao 7 (1 como padrão)
for i = 1, 7 do
    local rule = { workspace = tostring(i), monitor = PRIMARY_MONITOR }
    if i == 1 then rule.default = true end
    hl.workspace_rule(rule)
end

-- Monitor Secundário (HDMI-A-1): Workspaces 8 ao 10 (10 como padrão)
for i = 8, 10 do
    local rule = { workspace = tostring(i), monitor = MONITOR2 }
    if i == 10 then rule.default = true end
    hl.workspace_rule(rule)
end

-- Set names for workspaces for what they are *normally* used for, not set rules
local WS = {
    WEB = "1",
    CODE = "2",
    GAMES = "3",
    WEB_KITTY = "4",
    DISCORD = "10",
}

return WS