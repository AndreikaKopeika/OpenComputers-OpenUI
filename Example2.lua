local OpenUI = require("openui")
local component = require("component")
local gpu = component.gpu
local os = require("os")

-- Получаем разрешение терминала
local termWidth, termHeight = gpu.getResolution()

-- Создаём главную страницу, используя всё доступное пространство
local mainPage = OpenUI.newPage{
  title = "Super Cool OpenUI Demo",
  bgColor = 0x222222
}

-- Консольный виджет внизу экрана (оставляем несколько строк сверху для других виджетов)
local consoleHeight = 6
local consoleWidget = OpenUI.newConsole{
  x = 2, 
  y = termHeight - consoleHeight - 1, 
  width = termWidth - 4, 
  height = consoleHeight,
  fgColor = 0xFFFFFF, 
  bgColor = 0x333333,
  maxLines = 10
}
OpenUI.consoleWidget = consoleWidget
mainPage:addWidget(consoleWidget)

-- Прогресс-бар для симуляции
local progressBar = OpenUI.newProgressBar{
    x = 2, y = 14,
    width = 30,
    progress = 0,
    fgColor = 0x00FF00,
    bgColor = 0x444444
  }
  mainPage:addWidget(progressBar)

-- Кнопка "Запустить симуляцию" (располагается в верхнем левом углу)
local runButton = OpenUI.newButton{
  x = 2, y = 2,
  text = "Запустить симуляцию",
  bgColor = 0x0077CC,
  fgColor = 0xFFFFFF,
  rounded = true,
  callback = function()
    OpenUI.print("Начало симуляции...")
    progressBar.progress = 0
    OpenUI.setCurrentPage(mainPage)
    for i = 1, 10 do
      progressBar.progress = i / 10
      OpenUI.print("Прогресс: " .. math.floor(progressBar.progress * 100) .. "%")
      OpenUI.setCurrentPage(mainPage)
      os.sleep(0.3)
    end
    OpenUI.print("Симуляция завершена!")
    OpenUI.showInfo("Симуляция завершена!", 2)
  end
}
mainPage:addWidget(runButton)



-- Слайдер для настройки "Скорости"
local speedSlider = OpenUI.newSlider{
  x = 2, y = 5,
  width = 20,
  min = 0,
  max = 100,
  value = 50,
  bgColor = 0x555555,
  fgColor = 0x00FF00,
  rounded = true,
  onChange = function(val)
    OpenUI.print("Скорость: " .. math.floor(val))
  end
}
mainPage:addWidget(speedSlider)

-- Поле ввода для ввода команды
local commandInput = OpenUI.newTextInput{
  x = 2, y = 8,
  width = 20,
  text = "Введите команду...",
  fgColor = 0x000000,
  bgColor = 0xFFFFFF,
  rounded = false,
  onChange = function(text)
    OpenUI.print("Команда: " .. text)
  end
}
mainPage:addWidget(commandInput)

-- Чекбокс для переключения тёмного режима
local darkModeCheckbox = OpenUI.newCheckBox{
  x = 2, y = 10,
  text = "Тёмный режим",
  checked = false,
  onToggle = function(state)
    if state then
      mainPage.bgColor = 0x111111
      OpenUI.print("Тёмный режим включён")
    else
      mainPage.bgColor = 0x222222
      OpenUI.print("Тёмный режим выключен")
    end
    OpenUI.setCurrentPage(mainPage)
  end
}
mainPage:addWidget(darkModeCheckbox)

-- Выпадающий список для выбора сложности
local difficultyDropdown = OpenUI.newDropdown{
  x = 2, y = 12,
  width = 20,
  options = {"Лёгкая", "Средняя", "Тяжёлая"},
  selected = 1,
  bgColor = 0x444444,
  fgColor = 0xFFFFFF,
  onChange = function(index)
    local levels = {"Лёгкая", "Средняя", "Тяжёлая"}
    OpenUI.print("Выбрана сложность: " .. levels[index])
  end
}
mainPage:addWidget(difficultyDropdown)



-- Кнопка для выхода
local exitButton = OpenUI.newButton{
  x = 2, y = 16,
  text = "Выход",
  bgColor = 0xCC0000,
  fgColor = 0xFFFFFF,
  rounded = true,
  callback = function()
    local answer = OpenUI.confirmDialog{
      message = "Вы действительно хотите выйти?",
      yesText = "Да",
      noText = "Нет"
    }
    if answer then
      OpenUI.print("Завершение работы...")
      os.exit()
    else
      OpenUI.print("Выход отменён")
    end
  end
}
mainPage:addWidget(exitButton)

-- Мини-окно с информационной панелью (располагается справа, если позволяет экран)
infoPanel = OpenUI.newMiniWindow{
  x = termWidth - 35, y = 3,
  width = 30,
  height = 10,
  title = "Инфо Панель",
  bgColor = 0x333333,
  fgColor = 0xFFFFFF,
  draggable = true,
  content = function(win)
    gpu.setBackground(win.bgColor)
    gpu.setForeground(win.fgColor)
    gpu.set(win.x + 2, win.y + 2, "Настройка симуляции:")
    gpu.set(win.x + 2, win.y + 3, "Скорость: " .. math.floor(speedSlider.value))
    gpu.set(win.x + 2, win.y + 4, "Сложность: " ..
      ({ "Лёгкая", "Средняя", "Тяжёлая" })[difficultyDropdown.selected])
    gpu.set(win.x + 2, win.y + 5, "Команда: " .. commandInput:getText())
  end,
  onClose = function()
    OpenUI.print("Инфо панель закрыта")
  end
}
mainPage:addWidget(infoPanel)

local winButton = OpenUI.newButton{
    x = 50, y = 2,
    text = "Показать инфопанель",
    bgColor = 0x0077CC,
    fgColor = 0xFFFFFF,
    rounded = true,
    callback = function()
        infoPanel:show()
    end
  }
mainPage:addWidget(winButton)

local winButton2 = OpenUI.newButton{
    x = 50, y = 6,
    text = "Скрыть инфопанель",
    bgColor = 0x0077CC,
    fgColor = 0xFFFFFF,
    rounded = true,
    callback = function()
        infoPanel:hide()
    end
  }
mainPage:addWidget(winButton2)

-- Выводим стартовые сообщения в консоль
OpenUI.print("Добро пожаловать в Super Cool Demo!")
OpenUI.print("Инициализация компонентов...")
OpenUI.print("Загрузка настроек...")

-- Отрисовываем главную страницу и запускаем главный цикл событий
OpenUI.setCurrentPage(mainPage)
OpenUI.run()
