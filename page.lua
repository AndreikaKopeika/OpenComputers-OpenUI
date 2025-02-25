local component = require("component")
local gpu = component.gpu
local OpenUI = require("openui")  -- Для доступа к mainPage и setCurrentPage

local page = {}

-- Создание новой страницы
function page.new(params)
  params = params or {}
  local pg = {}
  pg.title = params.title or "OpenUI Page"
  pg.bgColor = params.bgColor or 0x000000
  pg.width, pg.height = gpu.getResolution()
  pg.widgets = {}
  pg.focusedWidget = nil
  if not OpenUI.mainPage then
    pg.isMain = true
    OpenUI.mainPage = pg
  else
    pg.isMain = params.isMain or false
  end
  
  local bufferId = gpu.allocateBuffer(pg.width, pg.height)
  if not bufferId then
    OpenUI.print("Предупреждение: не удалось выделить видеопамять для страницы, использую экран.")
    bufferId = 0
  end
  pg.bufferId = bufferId
  
  pg.closeButton = { x = pg.width - 2, y = 1, width = 3, height = 1 }
  
  function pg:addWidget(widget)
    table.insert(self.widgets, widget)
  end
  
  function pg:draw()
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
  
  function pg:handleTouch(x, y)
    -- Если нажали на крестик
    if x >= self.closeButton.x and x < self.closeButton.x + self.closeButton.width and y == self.closeButton.y then
      if self.isMain then
        gpu.setBackground(0x000000)
        gpu.fill(1, 1, self.width, self.height, " ")
        OpenUI.running = false  -- Фикс: выход из цикла без генерации ошибки
        return
      else
        OpenUI.setCurrentPage(OpenUI.mainPage)
        return
      end
    end
    local widgetFocused = false
    for _, widget in ipairs(self.widgets) do
      if widget.handleTouch and x >= widget.x and x < widget.x + widget.width 
         and y >= widget.y and y < widget.y + widget.height then
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
  
  return pg
end

-- Для совместимости: создание главного окна
function page.createWindow(params)
  params = params or {}
  params.isMain = true
  return page.new(params)
end

-- Функция для смены текущей страницы
function OpenUI.setCurrentPage(pg)
  OpenUI.currentPage = pg
  pg:draw()
end

return page
