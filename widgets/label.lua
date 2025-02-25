local component = require("component")
local gpu = component.gpu

local label = {}

function label.new(params)
  local lbl = {}
  lbl.x = params.x or 1
  lbl.y = params.y or 1
  lbl.text = params.text or ""
  lbl.fgColor = params.fgColor or 0xFFFFFF
  lbl.bgColor = params.bgColor
  lbl.width = #lbl.text
  lbl.height = 1
  
  function lbl:draw()
    if self.bgColor then
      gpu.setBackground(self.bgColor)
      gpu.fill(self.x, self.y, self.width, self.height, " ")
    end
    gpu.setForeground(self.fgColor)
    gpu.set(self.x, self.y, self.text)
    gpu.setForeground(0xFFFFFF)
  end
  
  function lbl:setText(newText)
    self.text = newText
    self.width = #newText
  end
  
  function lbl:getText()
    return self.text
  end
  
  return lbl
end

return label
