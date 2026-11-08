-- Bell widget: glyph follows the swaync subscribe stream
-- Priority: control center open > do not disturb > pending notifications > idle

local state = { count = 0, dnd = false, visible = false }
local last_glyph = nil
local interval_set = false
local last_text = nil

local function pick_glyph()
  if state.visible then
    return "bell-cog"
  elseif state.dnd then
    return "bell-off"
  elseif state.count > 0 then
    return "bell-ringing-filled"
  end
  return "bell"
end

-- The callback only updates state; the UI is touched from update()
noctalia.runStream("swaync-client -s", function(line)
  local count = line:match('"count":%s*(%d+)')
  local dnd = line:match('"dnd":%s*(%a+)')
  local visible = line:match('"visible":%s*(%a+)')

  if count then
    state.count = tonumber(count) or 0
  end
  if dnd then
    state.dnd = (dnd == "true")
  end
  if visible then
    state.visible = (visible == "true")
  end
end)

function update()
  if not interval_set then
    noctalia.setUpdateInterval(250)
    interval_set = true
  end

  local glyph = pick_glyph()
  if glyph ~= last_glyph then
    barWidget.setGlyph(glyph)
    last_glyph = glyph
  end

  local text = ""
  if state.count > 0 then
    text = tostring(state.count)
  end
  if text ~= last_text then
    barWidget.setText(text)
    last_text = text
  end
  
end

function onClick()
  noctalia.runAsync("swaync-client -t -sw")
end

function onRightClick()
  noctalia.runAsync("swaync-client -d -sw")
end