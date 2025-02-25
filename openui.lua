-- openui.lua
local component = require("component")
local event = require("event")
local computer = require("computer")
local gpu = component.gpu
local bit32 = require("bit32")

local OpenUI = {}

-- Глобальная консоль для OpenUI.print (если назначена)
OpenUI.consoleWidget = nil

-- Текущая страница и главная страница
OpenUI.currentPage = nil
OpenUI.mainPage = nil

----------------------------------------------------------------
-- Функция для обёртки текста по указанной ширине
----------------------------------------------------------------
local function wrapText(text, maxWidth)
  local lines = {}
  while #text > maxWidth do
    local part = text:sub(1, maxWidth)
    table.insert(lines, part)
    text = text:sub(maxWidth + 1)
  end
  if #text > 0 then table.insert(lines, text) end
  return lines
end

----------------------------------------------------------------
-- Функция для красивого вывода ошибок в отдельном окошке
----------------------------------------------------------------
function OpenUI.showError(err)
  local termWidth, termHeight = gpu.getResolution()
  local errorWidth = math.min(40, termWidth - 4)
  
  local msg = tostring(err)
  local wrappedLines = wrapText(msg, errorWidth - 2)
  local errorHeight = #wrappedLines + 4  -- 1 строка для заголовка, 1 строка для кнопки, 2 строки отступов
  
  local startX = math.floor((termWidth - errorWidth) / 2)
  local startY = math.floor((termHeight - errorHeight) / 2)
  
  gpu.setActiveBuffer(0) -- работаем с экраном
  gpu.setBackground(0x880000)
  for y = startY, startY + errorHeight - 1 do
    gpu.fill(startX, y, errorWidth, 1, " ")
  end
  
  gpu.setForeground(0xFFFFFF)
  local title = " Ошибка "
  local titleX = startX + math.floor((errorWidth - #title) / 2)
  gpu.set(titleX, startY, title)
  
  -- Выводим обёрнутый текст, начиная со строки startY+2
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
-- Вспомогательная функция для затемнения цвета
----------------------------------------------------------------
local function darkenColor(color, factor)
  local r = math.floor(bit32.rshift(color, 16) * factor)
  local g = math.floor(bit32.band(bit32.rshift(color, 8), 0xFF) * factor)
  local b = math.floor(bit32.band(color, 0xFF) * factor)
  return bit32.lshift(r, 16) + bit32.lshift(g, 8) + b
end

----------------------------------------------------------------
-- Создание новой страницы (page) с использованием GPU‑буфера
-- Параметры: title, bgColor, isMain (если не указано, первая страница становится главной)
----------------------------------------------------------------
function OpenUI.newPage(params)
  params = params or {}
  local page = {}
  page.title = params.title or "OpenUI Page"
  page.bgColor = params.bgColor or 0x000000
  page.width, page.height = gpu.getResolution()
  page.widgets = {}       -- список виджетов на странице
  page.focusedWidget = nil
  if OpenUI.mainPage == nil then
    page.isMain = true
    OpenUI.mainPage = page
  else
    page.isMain = params.isMain or false
  end
  
  -- Пытаемся выделить буфер
  local bufferId = gpu.allocateBuffer(page.width, page.height)
  if not bufferId then
    -- Фолбэк: используем экран (буфер 0) и выводим предупреждение
    OpenUI.print("Предупреждение: не удалось выделить видеопамять для страницы, использую экран.")
    bufferId = 0
  end
  page.bufferId = bufferId
  
  page.closeButton = { x = page.width - 2, y = 1, width = 3, height = 1 }
  
  function page:addWidget(widget)
    table.insert(self.widgets, widget)
  end
  
  function page:draw()
    gpu.setActiveBuffer(self.bufferId)
    gpu.setBackground(self.bgColor)
    gpu.fill(1, 1, self.width, self.height, " ")
    
    gpu.setForeground(0xFFFFFF)
    gpu.set(2, 1, self.title)
    
    gpu.setForeground(0xFF0000)
    gpu.set(self.closeButton.x, self.closeButton.y, "[X]")
    gpu.setForeground(0xFFFFFF)
    
    for _, widget in ipairs(self.widgets) do
      widget:draw()
    end
    
    gpu.setActiveBuffer(0)
    gpu.bitblt(0, 1, 1, self.width, self.height, self.bufferId, 1, 1)
  end
  
  function page:handleTouch(x, y)
    if x >= self.closeButton.x and x < self.closeButton.x + self.closeButton.width and y == self.closeButton.y then
      if self.isMain then
        gpu.setBackground(0x000000)
        gpu.fill(1, 1, self.width, self.height, " ")
        os.exit()
      else
        OpenUI.setCurrentPage(OpenUI.mainPage)
        return
      end
    end
    local widgetFocused = false
    for _, widget in ipairs(self.widgets) do
      if widget.handleTouch and x >= widget.x and x < widget.x + widget.width and y >= widget.y and y < widget.y + widget.height then
        widget:handleTouch(x, y)
        self.focusedWidget = widget.handleKey and widget or nil
        widgetFocused = true
        break
      end
    end
    if not widgetFocused then
      self.focusedWidget = nil
    end
    self:draw()
  end
  
  return page
end

----------------------------------------------------------------
-- Для совместимости: OpenUI.createWindow создаёт главную страницу
----------------------------------------------------------------
function OpenUI.createWindow(params)
  params = params or {}
  params.isMain = true
  return OpenUI.newPage(params)
end

----------------------------------------------------------------
-- Переключение на указанную страницу
----------------------------------------------------------------
function OpenUI.setCurrentPage(page)
  OpenUI.currentPage = page
  page:draw()
end

----------------------------------------------------------------
-- Главный цикл обработки событий (с использованием GPU‑буферов)
----------------------------------------------------------------
function OpenUI.run()
  local function eventLoop()
    while true do
      local eventData = { event.pull(0.1) }
      if #eventData > 0 then
        local e = eventData[1]
        if e == "touch" then
          local _, addr, x, y, button, player = table.unpack(eventData)
          if OpenUI.currentPage then
            OpenUI.currentPage:handleTouch(x, y)
          end
        elseif e == "key_down" and OpenUI.currentPage and OpenUI.currentPage.focusedWidget and OpenUI.currentPage.focusedWidget.handleKey then
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
  os.exit()
end

----------------------------------------------------------------
-- Виджеты (как и раньше)
----------------------------------------------------------------
function OpenUI.newButton(params)
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
  
  btn.pressedColor = darkenColor(btn.bgColor, 0.7)
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

----------------------------------------------------------------
-- Виджет: Метка (Label)
----------------------------------------------------------------
function OpenUI.newLabel(params)
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

----------------------------------------------------------------
-- Виджет: Поле ввода (TextInput)
----------------------------------------------------------------
function OpenUI.newTextInput(params)
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

----------------------------------------------------------------
-- Виджет: Флажок (CheckBox)
----------------------------------------------------------------
function OpenUI.newCheckBox(params)
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

----------------------------------------------------------------
-- Виджет: Индикатор выполнения (ProgressBar)
----------------------------------------------------------------
function OpenUI.newProgressBar(params)
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

----------------------------------------------------------------
-- Виджет: Консоль (Console) для вывода сообщений OpenUI.print
----------------------------------------------------------------
function OpenUI.newConsole(params)
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
    local wrapped = wrapText(text, self.width)
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

----------------------------------------------------------------
-- Функция OpenUI.print: выводит текст в консольный виджет (если назначен)
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
