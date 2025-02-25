local utils = {}

function utils.wrapText(text, maxWidth)
  local lines = {}
  while #text > maxWidth do
    local part = text:sub(1, maxWidth)
    table.insert(lines, part)
    text = text:sub(maxWidth + 1)
  end
  if #text > 0 then table.insert(lines, text) end
  return lines
end

function utils.darkenColor(color, factor)
  local bit32 = require("bit32")
  local r = math.floor(bit32.rshift(color, 16) * factor)
  local g = math.floor(bit32.band(bit32.rshift(color, 8), 0xFF) * factor)
  local b = math.floor(bit32.band(color, 0xFF) * factor)
  return bit32.lshift(r, 16) + bit32.lshift(g, 8) + b
end

return utils
