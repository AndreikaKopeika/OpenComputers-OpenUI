local component = require("component")
local gpu = component.gpu

local textinput = {}

function textinput.new(params)
  local input = {}
  input.x = params.x or 1
  input.y = params.y or 1
  input.width = params.width or 20
  input.text = params.text or ""
  input.fgColor = params.fgColor or 0x000000
  input.bgColor = params.bgColor or 0xFFFFFF
  input.onChange = params.onChange or function(text) end
  input.focus = false
  input.cursorPos = #input.text + 1
  input.height = 1
  
  function input:draw()
    gpu.setBackground(self.bgColor)
    gpu.fill(self.x, self.y, self.width, self.height, " ")
    gpu.setForeground(self.fgColor)
    local displayText = self.text
    if #displayText > self.width then
      displayText = displayText:sub(#displayText - self.width + 1, #displayText)
    end
    gpu.set(self.x, self.y, displayText)
    if self.focus then
      local cursorX = self.x + math.min(self.cursorPos - 1, self.width - 1)
      gpu.set(cursorX, self.y, "_")
    end
    gpu.setForeground(0xFFFFFF)
  end
  
  function input:handleTouch(touchX, touchY)
    self.focus = true
    self.cursorPos = #self.text + 1
  end
  
  function input:handleKey(char, code, player)
    if code == 14 then  -- Backspace
      if #self.text > 0 and self.cursorPos > 1 then
        self.text = self.text:sub(1, self.cursorPos - 2) .. self.text:sub(self.cursorPos)
        self.cursorPos = self.cursorPos - 1
        self.onChange(self.text)
      end
    elseif code == 28 then  -- Enter
      self.focus = false
    else
      local c = string.char(char)
      self.text = self.text:sub(1, self.cursorPos - 1) .. c .. self.text:sub(self.cursorPos)
      self.cursorPos = self.cursorPos + 1
      self.onChange(self.text)
    end
  end
  
  function input:setText(newText)
    self.text = newText
    self.cursorPos = #newText + 1
    self.onChange(self.text)
  end
  
  function input:getText()
    return self.text
  end
  
  return input
end

return textinput
