local OpenUI = {}
OpenUI.consoleWidget = nil
OpenUI.currentPage = nil
OpenUI.mainPage = nil
OpenUI.running = false  -- флаг работы цикла

-- Загружаем вспомогательные модули
package.path = package.path .. ";/lib/openui/?.lua"
OpenUI.utils = require("openui.utils")
OpenUI.page = require("openui.page")
OpenUI.widgets = {
  button = require("openui.widgets.button"),
  label = require("openui.widgets.label"),
  textinput = require("openui.widgets.textinput"),
  checkbox = require("openui.widgets.checkbox"),
  progressbar = require("openui.widgets.progressbar"),
  console = require("openui.widgets.console")
}

----------------------------------------------------------------
-- Функция запуска основного цикла событий
----------------------------------------------------------------
local event = require("event")
local component = require("component")
local gpu = component.gpu

function OpenUI.run()
  OpenUI.running = true
  local function eventLoop()
    while OpenUI.running do
      local eventData = { event.pull(0.1) }
      if #eventData > 0 then
        local e = eventData[1]
        if e == "touch" then
          local _, addr, x, y, button, player = table.unpack(eventData)
          if OpenUI.currentPage then
            OpenUI.currentPage:handleTouch(x, y)
          end
        elseif e == "key_down" and OpenUI.currentPage 
          and OpenUI.currentPage.focusedWidget 
          and OpenUI.currentPage.focusedWidget.handleKey then
          local _, addr, char, code, player = table.unpack(eventData)
          OpenUI.currentPage.focusedWidget:handleKey(char, code, player)
          OpenUI.currentPage:draw()
        end
      else
        if OpenUI.currentPage then
          OpenUI.currentPage:draw()
        end
      end
    end
  end
  
  local ok, err = xpcall(eventLoop, debug.traceback)
  if not ok then
    OpenUI.showError(err)
  end
  os.exit(0)
end

----------------------------------------------------------------
-- Функция вывода ошибок в отдельном окошке
----------------------------------------------------------------
function OpenUI.showError(err)
  local termWidth, termHeight = gpu.getResolution()
  local errorWidth = math.min(40, termWidth - 4)
  
  local msg = tostring(err)
  local wrappedLines = OpenUI.utils.wrapText(msg, errorWidth - 2)
  local errorHeight = #wrappedLines + 4
  
  local startX = math.floor((termWidth - errorWidth) / 2)
  local startY = math.floor((termHeight - errorHeight) / 2)
  
  gpu.setActiveBuffer(0)
  gpu.setBackground(0x880000)
  for y = startY, startY + errorHeight - 1 do
    gpu.fill(startX, y, errorWidth, 1, " ")
  end
  
  gpu.setForeground(0xFFFFFF)
  local title = " Ошибка "
  local titleX = startX + math.floor((errorWidth - #title) / 2)
  gpu.set(titleX, startY, title)
  
  for i, line in ipairs(wrappedLines) do
    gpu.set(startX + 1, startY + 1 + i, line)
  end
  
  local okText = "[ OK ]"
  local okX = startX + math.floor((errorWidth - #okText) / 2)
  local okY = startY + errorHeight - 1
  gpu.set(okX, okY, okText)
  
  while true do
    local e, addr, x, y, button, player = event.pull("touch")
    if e == "touch" and x >= okX and x < okX + #okText and y == okY then
      break
    end
  end
  
  gpu.setBackground(0x000000)
  gpu.fill(1, 1, termWidth, termHeight, " ")
  os.exit(1)
end

----------------------------------------------------------------
-- Функция OpenUI.print – вывод в консольный виджет (если назначен)
----------------------------------------------------------------
function OpenUI.print(...)
  local args = {...}
  local str = ""
  for i, v in ipairs(args) do
    str = str .. tostring(v) .. "\t"
  end
  if OpenUI.consoleWidget then
    OpenUI.consoleWidget:appendLine(str)
  else
    _G.print(str)
  end
end

return OpenUI
