local component = require("component")
local gpu = component.gpu
local OpenUI = require("openui")
local utils = OpenUI.utils

local button = {}

function button.new(params)
  local btn = {}
  btn.x = params.x or 1
  btn.y = params.y or 1
  btn.text = params.text or "Button"
  btn.bgColor = params.bgColor or 0x444444
  btn.fgColor = params.fgColor or 0xFFFFFF
  btn.callback = params.callback or function() end
  btn.padding = params.padding or 2
  btn.width = #btn.text + btn.padding * 2
  btn.height = params.height or 3
  
  btn.pressedColor = utils.darkenColor(btn.bgColor, 0.7)
  btn.pressed = false
  
  function btn:draw()
    local color = self.pressed and self.pressedColor or self.bgColor
    gpu.setBackground(color)
    for i = 0, self.height - 1 do
      gpu.fill(self.x, self.y + i, self.width, 1, " ")
    end
    local textX = self.x + math.floor((self.width - #self.text) / 2)
    local textY = self.y + math.floor((self.height - 1) / 2)
    gpu.setForeground(self.fgColor)
    gpu.set(textX, textY, self.text)
    gpu.setForeground(0xFFFFFF)
  end
  
  function btn:handleTouch(touchX, touchY)
    self.pressed = true
    self:draw()
    os.sleep(0.1)
    self.pressed = false
    self:draw()
    self.callback()
  end
  
  return btn
end

return button
