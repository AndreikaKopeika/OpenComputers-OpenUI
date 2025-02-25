local component = require("component")
local gpu = component.gpu

local progressbar = {}

function progressbar.new(params)
  local pb = {}
  pb.x = params.x or 1
  pb.y = params.y or 1
  pb.width = params.width or 20
  pb.progress = params.progress or 0
  pb.fgColor = params.fgColor or 0x00FF00
  pb.bgColor = params.bgColor or 0x555555
  pb.height = 1
  
  function pb:draw()
    gpu.setBackground(self.bgColor)
    gpu.fill(self.x, self.y, self.width, self.height, " ")
    local filled = math.floor(self.width * self.progress)
    gpu.setBackground(self.fgColor)
    if filled > 0 then
      gpu.fill(self.x, self.y, filled, self.height, " ")
    end
    gpu.setBackground(0x000000)
  end
  
  function pb:setProgress(p)
    self.progress = math.max(0, math.min(1, p))
    if self.onChange then self.onChange(self.progress) end
  end
  
  return pb
end

return progressbar

