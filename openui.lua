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
OpenUI.version = "2.4"

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

-- Функция для рисования закруглённого прямоугольника с использованием символов Unicode
function OpenUI.drawRoundedBox(x, y, width, height, bgColor, fgColor)
    -- Если размеры слишком маленькие, просто заливаем область
    if width < 2 or height < 2 then
      gpu.setBackground(bgColor)
      gpu.fill(x, y, width, height, " ")
      return
    end
  
    gpu.setBackground(bgColor)
    gpu.setForeground(fgColor)
    -- Углы
    gpu.set(x, y, "╭")
    gpu.set(x + width - 1, y, "╮")
    gpu.set(x, y + height - 1, "╰")
    gpu.set(x + width - 1, y + height - 1, "╯")
    -- Верхняя и нижняя границы
    for i = x + 1, x + width - 2 do
      gpu.set(i, y, "─")
      gpu.set(i, y + height - 1, "─")
    end
    -- Боковые границы и заливка внутри
    for j = y + 1, y + height - 2 do
      gpu.set(x, j, "│")
      gpu.set(x + width - 1, j, "│")
      gpu.fill(x + 1, j, width - 2, 1, " ")
    end
    gpu.setForeground(0xFFFFFF)
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
    OpenUI.running = true  -- Флаг работы цикла
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
          elseif e == "drag" then
            local _, addr, x, y, button, player = table.unpack(eventData)
            if OpenUI.currentPage then
              -- Передаём событие каждому виджету, у которого есть обработка перетаскивания
              for _, widget in ipairs(OpenUI.currentPage.widgets) do
                if widget.handleDrag then
                  widget:handleDrag(x, y)
                end
              end
              OpenUI.currentPage:draw()
            end
          elseif e == "touch_up" then
            local _, addr, x, y, button, player = table.unpack(eventData)
            if OpenUI.currentPage then
              -- Передаём событие отпускания каждому виджету, у которого есть обработка отпускания
              for _, widget in ipairs(OpenUI.currentPage.widgets) do
                if widget.handleRelease then
                  widget:handleRelease(x, y)
                end
              end
              OpenUI.currentPage:draw()
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
  btn.rounded = params.rounded or false

  -- Дополнительные параметры: видимость и активность (enabled)
  btn.visible = (params.visible == nil) and true or params.visible
  btn.enabled = (params.enabled == nil) and true or params.enabled

  btn.pressedColor = darkenColor(btn.bgColor, 0.7)
  btn.pressed = false

  function btn:draw()
    if not self.visible then return end
    local bg = self.pressed and self.pressedColor or self.bgColor
    if self.rounded then
      OpenUI.drawRoundedBox(self.x, self.y, self.width, self.height, bg, self.fgColor)
      local textX = self.x + math.floor((self.width - #self.text) / 2)
      local textY = self.y + math.floor(self.height / 2)
      gpu.setForeground(self.fgColor)
      gpu.set(textX, textY, self.text)
    else
      gpu.setBackground(bg)
      for i = 0, self.height - 1 do
        gpu.fill(self.x, self.y + i, self.width, 1, " ")
      end
      local textX = self.x + math.floor((self.width - #self.text) / 2)
      local textY = self.y + math.floor((self.height - 1) / 2)
      gpu.setForeground(self.fgColor)
      gpu.set(textX, textY, self.text)
      gpu.setForeground(0xFFFFFF)
    end
  end

  function btn:handleTouch(touchX, touchY)
    if not self.visible or not self.enabled then return false end
    self.pressed = true
    self:draw()
    os.sleep(0.1)
    self.pressed = false
    self:draw()
    self.callback()
    return true
  end

  -- Методы управления видимостью
  function btn:hide()
    self.visible = false
    gpu.setBackground(0x000000)
    gpu.fill(self.x, self.y, self.width, self.height, " ")
  end

  function btn:show()
    self.visible = true
    self:draw()
  end

  -- Методы управления активностью
  function btn:disable()
    self.enabled = false
    -- Опционально: изменяем цвет текста для обозначения неактивного состояния
    self.oldFgColor = self.fgColor
    self.fgColor = 0x888888
    self:draw()
  end

  function btn:enable()
    self.enabled = true
    if self.oldFgColor then
      self.fgColor = self.oldFgColor
    end
    self:draw()
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
    input.rounded = params.rounded or false
  
    function input:draw()
      if self.rounded then
        OpenUI.drawRoundedBox(self.x, self.y, self.width, self.height, self.bgColor, self.fgColor)
        local displayText = self.text
        if #displayText > self.width - 2 then
          displayText = displayText:sub(#displayText - (self.width - 2) + 1, #displayText)
        end
        gpu.setForeground(self.fgColor)
        gpu.set(self.x + 1, self.y, displayText)
        if self.focus then
          local cursorX = self.x + math.min(self.cursorPos - 1, self.width - 2) + 1
          gpu.set(cursorX, self.y, "_")
        end
      else
        gpu.setBackground(self.bgColor)
        gpu.fill(self.x, self.y, self.width, self.height, " ")
        local displayText = self.text
        if #displayText > self.width then
          displayText = displayText:sub(#displayText - self.width + 1, #displayText)
        end
        gpu.setForeground(self.fgColor)
        gpu.set(self.x, self.y, displayText)
        if self.focus then
          local cursorX = self.x + math.min(self.cursorPos - 1, self.width - 1)
          gpu.set(cursorX, self.y, "_")
        end
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
-- Виджет: Консоль (Console) для вывода сообщений OpenUI.print
----------------------------------------------------------------

function OpenUI.newSlider(params)
    local slider = {}
    slider.x = params.x or 1
    slider.y = params.y or 1
    slider.width = params.width or 20
    slider.min = params.min or 0
    slider.max = params.max or 100
    slider.value = params.value or slider.min
    slider.bgColor = params.bgColor or 0x555555
    slider.fgColor = params.fgColor or 0x00FF00
    slider.rounded = params.rounded or false
    slider.onChange = params.onChange or function(val) end
    slider.height = params.height or 1
  
    function slider:draw()
      if self.rounded then
        OpenUI.drawRoundedBox(self.x, self.y, self.width, self.height, self.bgColor, self.fgColor)
      else
        gpu.setBackground(self.bgColor)
        gpu.fill(self.x, self.y, self.width, self.height, " ")
      end
      local ratio = (self.value - self.min) / (self.max - self.min)
      local handlePos = math.floor(ratio * (self.width - 1)) + self.x
      gpu.setBackground(self.fgColor)
      gpu.fill(handlePos, self.y, 1, self.height, " ")
      gpu.setBackground(0x000000)
    end
  
    function slider:handleTouch(touchX, touchY)
      if touchX < self.x then
        self.value = self.min
      elseif touchX >= self.x + self.width then
        self.value = self.max
      else
        local ratio = (touchX - self.x) / (self.width - 1)
        self.value = self.min + ratio * (self.max - self.min)
      end
      self.onChange(self.value)
      self:draw()
    end
  
    return slider
  end
  

----------------------------------------------------------------
-- Новый виджет: мини-окно (draggable window)
----------------------------------------------------------------
function OpenUI.newMiniWindow(params)
    local win = {}
    win.x = params.x or 1
    win.y = params.y or 1
    win.width = params.width or 30
    win.height = params.height or 10
    win.title = params.title or "Mini Window"
    win.bgColor = params.bgColor or 0x333333
    win.fgColor = params.fgColor or 0xFFFFFF
    win.draggable = (params.draggable == nil) and true or params.draggable  -- По умолчанию true
    win.visible = (params.visible == nil) and true or params.visible  -- По умолчанию true
    win.dragging = false
    win.offsetX = 0
    win.offsetY = 0
    win.onClose = params.onClose or function() end
    win.content = params.content or function(self) end

    -- Метод для отрисовки окна
    function win:draw()
        if not self.visible then return end  -- Если окно скрыто, не рисуем

        OpenUI.drawRoundedBox(self.x, self.y, self.width, self.height, self.bgColor, self.fgColor)

        -- Отрисовываем заголовок по центру
        local titleText = " " .. self.title .. " "
        local titleX = self.x + math.floor((self.width - #titleText) / 2)
        gpu.setForeground(self.fgColor)
        gpu.set(titleX, self.y, titleText)

        -- Кнопка закрытия [X]
        local closeText = "[X]"
        local closeX = self.x + self.width - #closeText - 1
        gpu.set(closeX, self.y, closeText)
        gpu.setForeground(0xFFFFFF)

        -- Отрисовка контента
        if self.content then
            self.content(self)
        end
    end

    -- Метод скрытия окна
    function win:hide()
        if self.visible then
            self.visible = false
            gpu.setBackground(0x000000) -- Очищаем область окна
            gpu.fill(self.x, self.y, self.width, self.height, " ")
        end
    end

    -- Метод отображения окна
    function win:show()
        if not self.visible then
            self.visible = true
            self:draw()
        end
    end

    -- Обработка касания (для закрытия и перетаскивания)
    function win:handleTouch(x, y)
        if not self.visible then return false end

        if y == self.y then
            local closeText = "[X]"
            local closeX = self.x + self.width - #closeText - 1
            if x >= closeX and x < closeX + #closeText then
                self:hide()  -- При нажатии на [X] скрываем окно
                self.onClose()
                return true
            elseif self.draggable then
                self.dragging = true
                self.offsetX = x - self.x
                self.offsetY = y - self.y
                return true
            end
        end
        return false
    end

    -- Обработка перетаскивания
    function win:handleDrag(x, y)
        if self.dragging and self.visible then
            self.x = x - self.offsetX
            self.y = y - self.offsetY
            self:draw()
            return true
        end
        return false
    end

    -- Завершение перетаскивания
    function win:handleRelease(x, y)
        if self.dragging then
            self.dragging = false
            return true
        end
        return false
    end

    return win
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
----------------------------------------------------------------
-- Вспомогательная функция для центрирования текста по заданной ширине
----------------------------------------------------------------
function OpenUI.centerText(text, width)
    local padding = math.floor((width - #text) / 2)
    return string.rep(" ", padding) .. text .. string.rep(" ", width - #text - padding)
  end
  
  ----------------------------------------------------------------
  -- Модальное окно с подтверждением (Yes/No)
  ----------------------------------------------------------------
  function OpenUI.confirmDialog(params)
    local message = params.message or "Вы уверены?"
    local yesText = params.yesText or "Да"
    local noText = params.noText or "Нет"
    local termWidth, termHeight = gpu.getResolution()
    local width = math.max(#message + 4, #yesText + #noText + 10, 30)
    local height = 7
    local startX = math.floor((termWidth - width) / 2)
    local startY = math.floor((termHeight - height) / 2)
  
    local result = nil
  
    -- Создаём модальный виджет подтверждения
    local confirmWidget = {
      x = startX,
      y = startY,
      width = width,
      height = height,
      draw = function(self)
        -- Рисуем фон и рамку
        gpu.setBackground(0x333333)
        gpu.fill(self.x, self.y, self.width, self.height, " ")
        OpenUI.drawRoundedBox(self.x, self.y, self.width, self.height, 0x333333, 0xFFFFFF)
        -- Выводим сообщение с переносом строк
        local wrapped = wrapText(message, self.width - 4)
        for i, line in ipairs(wrapped) do
          local centered = OpenUI.centerText(line, self.width - 2)
          gpu.set(self.x + 1, self.y + i, centered)
        end
        -- Рисуем кнопки
        local buttonsY = self.y + self.height - 1
        local yesX = math.floor(self.width / 4 - #yesText / 2)
        local noX = math.floor(3 * self.width / 4 - #noText / 2)
        gpu.setBackground(0x444444)
        gpu.setForeground(0xFFFFFF)
        gpu.set(self.x + yesX, buttonsY, yesText)
        gpu.set(self.x + noX, buttonsY, noText)
      end,
      handleTouch = function(self, touchX, touchY)
        local buttonsY = self.y + self.height - 1
        local yesX = math.floor(self.width / 4 - #yesText / 2)
        local noX = math.floor(3 * self.width / 4 - #noText / 2)
        if touchY == buttonsY then
          if touchX >= self.x + yesX and touchX < self.x + yesX + #yesText then
            result = true
          elseif touchX >= self.x + noX and touchX < self.x + noX + #noText then
            result = false
          end
        end
      end
    }
  
    -- Добавляем модальное окно в список виджетов текущей страницы
    local page = OpenUI.currentPage
    table.insert(page.widgets, confirmWidget)
    page:draw()
  
    -- Блокирующий цикл ожидания ответа с использованием page:handleTouch
    while result == nil do
      local e, addr, x, y, button, player = event.pull(0.1)
      if e == "touch" then
        page:handleTouch(x, y)
        page:draw()
      end
    end
  
    -- Удаляем модальное окно из списка виджетов и перерисовываем страницу
    for i, widget in ipairs(page.widgets) do
      if widget == confirmWidget then
        table.remove(page.widgets, i)
        break
      end
    end
    page:draw()
  
    return result
  end
    
  ----------------------------------------------------------------
  -- Виджет: Выпадающий список (Dropdown)
  ----------------------------------------------------------------
  function OpenUI.newDropdown(params)
    local dd = {}
    dd.x = params.x or 1
    dd.y = params.y or 1
    dd.width = params.width or 20
    dd.options = params.options or {"Опция 1", "Опция 2", "Опция 3"}
    dd.selected = params.selected or 1
    dd.expanded = false
    dd.bgColor = params.bgColor or 0x444444
    dd.fgColor = params.fgColor or 0xFFFFFF
    dd.onChange = params.onChange or function(index) end
    
    dd.height = 1  -- высота, когда список свернут
    
    function dd:draw()
      gpu.setBackground(self.bgColor)
      gpu.fill(self.x, self.y, self.width, self.height, " ")
      gpu.setForeground(self.fgColor)
      local selectedText = self.options[self.selected] or ""
      gpu.set(self.x + 1, self.y, selectedText)
      gpu.setForeground(0xFFFFFF)
      if self.expanded then
        for i, option in ipairs(self.options) do
          gpu.setBackground(self.bgColor)
          gpu.fill(self.x, self.y + i, self.width, 1, " ")
          if i == self.selected then
            gpu.setForeground(0x00FF00)
          else
            gpu.setForeground(self.fgColor)
          end
          gpu.set(self.x + 1, self.y + i, option)
        end
        gpu.setForeground(0xFFFFFF)
      end
    end
    
    function dd:handleTouch(touchX, touchY)
      if not self.expanded then
        if touchX >= self.x and touchX < self.x + self.width and touchY == self.y then
          self.expanded = true
          self.height = #self.options + 1  -- увеличиваем высоту, чтобы включить область вариантов
          self:draw()
        end
      else
        local optionIndex = touchY - self.y
        if optionIndex >= 1 and optionIndex <= #self.options then
          self.selected = optionIndex
          self.onChange(self.selected)
        end
        self.expanded = false
        self.height = 1  -- возвращаем исходную высоту
        self:draw()
      end
    end
    
    return dd
  end
  
  
  ----------------------------------------------------------------
  -- Функция для показа информационного сообщения (авто-скрытие)
  ----------------------------------------------------------------
  function OpenUI.showInfo(message, duration)
    duration = duration or 2
    local termWidth, termHeight = gpu.getResolution()
    local width = math.min(40, termWidth - 4)
    local wrapped = wrapText(message, width - 2)
    local height = #wrapped + 2
    local startX = math.floor((termWidth - width) / 2)
    local startY = math.floor(termHeight - height - 2)
    
    gpu.setBackground(0x222222)
    gpu.fill(startX, startY, width, height, " ")
    gpu.setForeground(0xFFFFFF)
    
    for i, line in ipairs(wrapped) do
      local centered = OpenUI.centerText(line, width - 2)
      gpu.set(startX + 1, startY + i, centered)
    end
    
    os.sleep(duration)
    
    gpu.setBackground(0x000000)
    gpu.fill(startX, startY, width, height, " ")
  end
  

----------------------------------------------------------------
-- 3D Виджеты --------------------------------------------------
----------------------------------------------------------------
-- Функция для 3D-проекции точки
local function projectPoint(x, y, z, fov, viewerDistance)
  local factor = fov / (viewerDistance + z)
  local projX = x * factor
  local projY = y * factor
  return projX, projY
end

-- Функция для рисования линии (алгоритм Брезенхэма)
local function drawLine(x1, y1, x2, y2, fgColor)
  local dx = math.abs(x2 - x1)
  local dy = math.abs(y2 - y1)
  local sx = x1 < x2 and 1 or -1
  local sy = y1 < y2 and 1 or -1
  local err = dx - dy
  while true do
    gpu.setForeground(fgColor)
    gpu.set(x1, y1, "*")
    if x1 == x2 and y1 == y2 then break end
    local e2 = 2 * err
    if e2 > -dy then
      err = err - dy
      x1 = x1 + sx
    end
    if e2 < dx then
      err = err + dx
      y1 = y1 + sy
    end
  end
end

-- Пример модели (куб)
local defaultCube = {
  vertices = {
    {-1, -1, -1},
    { 1, -1, -1},
    { 1,  1, -1},
    {-1,  1, -1},
    {-1, -1,  1},
    { 1, -1,  1},
    { 1,  1,  1},
    {-1,  1,  1},
  },
  edges = {
    {1,2}, {2,3}, {3,4}, {4,1},
    {5,6}, {6,7}, {7,8}, {8,5},
    {1,5}, {2,6}, {3,7}, {4,8},
  }
}

-- Новый виджет для 3D-отображения
function OpenUI.new3DWidget(params)
  local widget = {}
  widget.x = params.x or 1
  widget.y = params.y or 1
  widget.width = params.width or 40
  widget.height = params.height or 20
  widget.bgColor = params.bgColor or 0x000000
  widget.fgColor = params.fgColor or 0xFFFFFF
  widget.fov = params.fov or 50
  widget.viewerDistance = params.viewerDistance or 5
  widget.angle = params.angle or 0    -- Начальный угол поворота
  widget.model = params.model or defaultCube  -- Модель: список вершин и рёбер
  -- Определяем масштаб так, чтобы проекция вписывалась в область виджета.
  widget.scale = params.scale or math.min(widget.width, widget.height) / 2

  -- Метод для отрисовки 3D-сцены
  function widget:draw()
    -- Заливка фона виджета
    gpu.setBackground(self.bgColor)
    gpu.fill(self.x, self.y, self.width, self.height, " ")

    -- Обновляем угол для анимации (если нужна анимация)
    self.angle = self.angle + 0.05

    local projected = {}
    for i, vertex in ipairs(self.model.vertices) do
      local x = vertex[1]
      local y = vertex[2]
      local z = vertex[3]
      local cosA = math.cos(self.angle)
      local sinA = math.sin(self.angle)
      local xRot = x * cosA - z * sinA
      local zRot = x * sinA + z * cosA
      -- Вычисляем проекцию (функция projectPoint должна быть определена заранее)
      local projX, projY = projectPoint(xRot, y, zRot, self.fov, self.viewerDistance)
      -- Масштабируем и сдвигаем координаты так, чтобы они попали в центр виджета
      local screenX = self.x + math.floor(projX * self.scale + self.width / 2)
      local screenY = self.y + math.floor(projY * self.scale + self.height / 2)
      table.insert(projected, {screenX, screenY})
    end

    -- Отрисовка вершин (только если они попадают в область виджета)
    for i, p in ipairs(projected) do
      if p[1] >= self.x and p[1] < self.x + self.width and p[2] >= self.y and p[2] < self.y + self.height then
        gpu.setForeground(self.fgColor)
        gpu.set(p[1], p[2], "*")
      end
    end

    -- Отрисовка рёбер
    for i, edge in ipairs(self.model.edges) do
      local p1 = projected[edge[1]]
      local p2 = projected[edge[2]]
      if p1 and p2 then
        drawLine(p1[1], p1[2], p2[1], p2[2], self.fgColor)
      end
    end
  end

  function widget:handleTouch(x, y)
    -- При необходимости можно добавить интерактивное управление
    return false
  end

  return widget
end


----------------------------------------------------------------
------------- Работа с изоображениями .oui ---------------------
----------------------------------------------------------------

-- Вспомогательные функции для работы с форматом .oui

-- Функция для разбиения строки по разделителю
local function split(str, sep)
  local result = {}
  for word in string.gmatch(str, "([^" .. sep .. "]+)") do
    table.insert(result, word)
  end
  return result
end

-- Сохраняет данные изображения (canvas) в файл формата .oui
function OpenUI.saveOUI(filename, canvas)
  local file = io.open(filename, "w")
  if not file then
    error("Невозможно открыть файл для записи: " .. filename)
  end
  file:write(canvas.width, " ", canvas.height, "\n")
  for y = 1, canvas.height do
    local row = {}
    for x = 1, canvas.width do
      local color = canvas.pixels[y][x] or 0
      table.insert(row, string.format("%X", color))
    end
    file:write(table.concat(row, " ") .. "\n")
  end
  file:close()
end

-- Загружает изображение из файла формата .oui и возвращает ширину, высоту и таблицу пикселей
function OpenUI.loadOUI(filename)
  local file = io.open(filename, "r")
  if not file then
    error("Невозможно открыть файл для чтения: " .. filename)
  end
  local header = file:read("*l")
  local w, h = header:match("^(%d+)%s+(%d+)$")
  w = tonumber(w)
  h = tonumber(h)
  local pixels = {}
  for y = 1, h do
    pixels[y] = {}
    local line = file:read("*l")
    local parts = split(line, " ")
    for x = 1, w do
      local color = tonumber(parts[x], 16) or 0
      pixels[y][x] = color
    end
  end
  file:close()
  return w, h, pixels
end

-- Виджет для работы с изоображениями
function OpenUI.newImageWidget(params)
  local widget = {}
  widget.x = params.x or 1
  widget.y = params.y or 1
  widget.width = params.width or 20
  widget.height = params.height or 10
  widget.bgColor = params.bgColor or 0x000000
  widget.fgColor = params.fgColor or 0xFFFFFF
  widget.imageData = nil  -- двумерная таблица с данными пикселей
  widget.filePath = nil
  widget.onClick = params.onClick or function() end

  function widget:draw()
    gpu.setBackground(self.bgColor)
    gpu.fill(self.x, self.y, self.width, self.height, " ")
    if self.imageData then
      for j = 1, math.min(self.height, #self.imageData) do
        for i = 1, math.min(self.width, #self.imageData[j]) do
          local color = self.imageData[j][i]
          gpu.setBackground(color)
          gpu.set(self.x + i - 1, self.y + j - 1, " ")
        end
      end
      gpu.setBackground(self.bgColor)
    else
      local text = "No Image"
      gpu.setForeground(self.fgColor)
      gpu.set(self.x + math.floor((self.width - #text) / 2), self.y + math.floor(self.height / 2), text)
    end
  end

  function widget:setImageFile(filePath)
    self.filePath = filePath
    local w, h, pixels = OpenUI.loadOUI(filePath)
    self.imageData = pixels
    self:draw()
  end

  function widget:getImageFile()
    return self.filePath
  end

  function widget:handleTouch(x, y)
    if x >= self.x and x < self.x + self.width and y >= self.y and y < self.y + self.height then
      self.onClick()
      return true
    end
    return false
  end

  return widget
end

function OpenUI.newFileChooser(params)
  local widget = {}
  local fs = require("filesystem")
  widget.x = params.x or 1
  widget.y = params.y or 1
  widget.width = params.width or 30
  widget.height = params.height or 10
  widget.bgColor = params.bgColor or 0x222222
  widget.fgColor = params.fgColor or 0xFFFFFF
  widget.title = params.title or "File Chooser"
  widget.currentPath = params.startPath or "/home"
  widget.files = {} -- список файлов и папок
  widget.selected = 1
  widget.onSelect = params.onSelect or function(filePath) end
  widget.fileFilter = params.fileFilter  -- либо функция(filePath) -> bool, либо таблица допустимых расширений (например, {".png", ".oui"})
  widget.visible = (params.visible == nil) and true or params.visible
  widget.scrollOffset = 0

  function widget:refresh()
    self.files = {}
    if self.currentPath ~= "/" then
      table.insert(self.files, "..")
    end
    for file in fs.list(self.currentPath) do
      if file ~= "" then
        local fullPath = fs.concat(self.currentPath, file)
        if fs.isDirectory(fullPath) then
          table.insert(self.files, file)
        else
          if self.fileFilter then
            if type(self.fileFilter) == "function" then
              if self.fileFilter(fullPath) then
                table.insert(self.files, file)
              end
            elseif type(self.fileFilter) == "table" then
              for _, ext in ipairs(self.fileFilter) do
                if file:sub(-#ext) == ext then
                  table.insert(self.files, file)
                  break
                end
              end
            end
          else
            table.insert(self.files, file)
          end
        end
      end
    end
    self.selected = 1
    self.scrollOffset = 0
  end

  function widget:draw()
    if not self.visible then return end
    gpu.setBackground(self.bgColor)
    gpu.fill(self.x, self.y, self.width, self.height, " ")
    gpu.setForeground(self.fgColor)
    local titleText = " " .. self.title .. " (" .. self.currentPath .. ") "
    local titleX = self.x + math.floor((self.width - #titleText) / 2)
    gpu.set(titleX, self.y, titleText)
    local displayCount = self.height - 1
    for i = 1, displayCount do
      local index = i + self.scrollOffset
      local file = self.files[index]
      if file then
        if index == self.selected then
          gpu.setForeground(0x00FF00)
        else
          gpu.setForeground(self.fgColor)
        end
        local text = file:sub(1, self.width - 2)
        gpu.set(self.x + 1, self.y + i, text)
      else
        gpu.set(self.x + 1, self.y + i, string.rep(" ", self.width - 2))
      end
    end
    gpu.setForeground(0xFFFFFF)
  end

  function widget:handleTouch(touchX, touchY)
    if not self.visible then return false end
    if touchX >= self.x and touchX < self.x + self.width and
       touchY >= self.y + 1 and touchY < self.y + self.height then
      local index = touchY - self.y + self.scrollOffset
      if index >= 1 and index <= #self.files then
        self.selected = index
        local selectedItem = self.files[index]
        local fullPath = fs.concat(self.currentPath, selectedItem)
        if fs.isDirectory(fullPath) then
          self.currentPath = fs.canonical(fullPath)
          self:refresh()
          self:draw()
        else
          self.onSelect(fs.canonical(fullPath))
        end
        return true
      end
    end
    return false
  end

  function widget:handleScroll(direction)
    -- direction: +1 для прокрутки вниз, -1 для прокрутки вверх
    local displayCount = self.height - 1
    local maxOffset = math.max(0, #self.files - displayCount)
    self.scrollOffset = self.scrollOffset + direction
    if self.scrollOffset < 0 then self.scrollOffset = 0 end
    if self.scrollOffset > maxOffset then self.scrollOffset = maxOffset end
    self:draw()
    return true
  end

  function widget:hide()
    self.visible = false
    gpu.setBackground(0x000000)
    gpu.fill(self.x, self.y, self.width, self.height, " ")
  end

  function widget:show()
    self.visible = true
    self:draw()
  end

  widget:refresh()
  return widget
end


function OpenUI.newCanvas(params)
  local canvas = {}
  canvas.x = params.x or 1
  canvas.y = params.y or 1
  canvas.width = params.width or 20
  canvas.height = params.height or 10
  canvas.bgColor = params.bgColor or 0x000000
  canvas.currentColor = params.currentColor or 0xFF0000
  canvas.pixels = {}
  for j = 1, canvas.height do
    canvas.pixels[j] = {}
    for i = 1, canvas.width do
      canvas.pixels[j][i] = canvas.bgColor
    end
  end

  function canvas:draw()
    for j = 1, self.height do
      for i = 1, self.width do
        gpu.setBackground(self.pixels[j][i])
        gpu.set(self.x + i - 1, self.y + j - 1, " ")
      end
    end
    gpu.setBackground(0x000000)
  end

  function canvas:setColor(color)
    self.currentColor = color
  end

  function canvas:getPixel(px, py)
    return self.pixels[py] and self.pixels[py][px]
  end

  function canvas:setPixel(px, py, color)
    if px >= 1 and px <= self.width and py >= 1 and py <= self.height then
      self.pixels[py][px] = color
      gpu.setBackground(color)
      gpu.set(self.x + px - 1, self.y + py - 1, " ")
    end
  end

  function canvas:handleTouch(touchX, touchY)
    if touchX >= self.x and touchX < self.x + self.width and
       touchY >= self.y and touchY < self.y + self.height then
      local px = touchX - self.x + 1
      local py = touchY - self.y + 1
      self:setPixel(px, py, self.currentColor)
      return true
    end
    return false
  end

  function canvas:save(filename)
    OpenUI.saveOUI(filename, self)
  end

  function canvas:load(filename)
    local w, h, pixels = OpenUI.loadOUI(filename)
    if w and h and pixels then
      self.width = w
      self.height = h
      self.pixels = pixels
      self:draw()
    end
  end

  return canvas
end


return OpenUI
