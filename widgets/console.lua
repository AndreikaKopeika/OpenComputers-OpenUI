local component = require("component")
local gpu = component.gpu
local OpenUI = require("openui")
local utils = OpenUI.utils

local console = {}

function console.new(params)
  local cons = {}
  cons.x = params.x or 1
  cons.y = params.y or 1
  cons.width = params.width or 40
  cons.height = params.height or 10
  cons.fgColor = params.fgColor or 0xFFFFFF
  cons.bgColor = params.bgColor or 0x000000
  cons.lines = {}
  cons.maxLines = params.maxLines or cons.height
  
  function cons:draw()
    gpu.setBackground(self.bgColor)
    gpu.fill(self.x, self.y, self.width, self.height, " ")
    gpu.setForeground(self.fgColor)
    local startLine = math.max(1, #self.lines - self.height + 1)
    for i = startLine, #self.lines do
      local line = self.lines[i]
      gpu.set(self.x, self.y + i - startLine, line)
    end
    gpu.setForeground(0xFFFFFF)
  end
  
  function cons:appendLine(text)
    local wrapped = utils.wrapText(text, self.width)
    for _, line in ipairs(wrapped) do
      table.insert(self.lines, line)
      if #self.lines > self.maxLines then
        table.remove(self.lines, 1)
      end
    end
    self:draw()
  end
  
  function cons:clear()
    self.lines = {}
    self:draw()
  end
  
  return cons
end

return console
