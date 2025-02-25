local component = require("component")
local gpu = component.gpu

local checkbox = {}

function checkbox.new(params)
  local cb = {}
  cb.x = params.x or 1
  cb.y = params.y or 1
  cb.text = params.text or ""
  cb.fgColor = params.fgColor or 0xFFFFFF
  cb.bgColor = params.bgColor or 0x000000
  cb.checked = params.checked or false
  cb.onToggle = params.onToggle or function(state) end
  
  cb.width = 4 + #cb.text
  cb.height = 1
  
  function cb:draw()
    local symbol = self.checked and "[X]" or "[ ]"
    gpu.setBackground(self.bgColor)
    gpu.setForeground(self.fgColor)
    gpu.set(self.x, self.y, symbol .. " " .. self.text)
    gpu.setForeground(0xFFFFFF)
  end
  
  function cb:handleTouch(touchX, touchY)
    self.checked = not self.checked
    self.onToggle(self.checked)
  end
  
  return cb
end

return checkbox
