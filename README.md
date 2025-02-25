# Документация для OpenUI (Новая версия)

## Введение

**OpenUI** — это библиотека для создания графического пользовательского интерфейса в OpenComputers. Новая версия OpenUI разбита на модули, что делает код более структурированным и удобным для поддержки. Библиотека поддерживает создание окон (страниц), кнопок, меток, полей ввода, чекбоксов, прогресс-баров и консоли. Для повышения производительности и удобства используется работа с GPU-буферами.

## Структура библиотеки

После установки у вас появится следующая структура файлов:

```
openui/
├── init.lua         -- Основной модуль, содержит функции запуска, вывода ошибок, глобальную консоль и пр.
├── page.lua         -- Модуль для работы со страницами (окнами)
├── utils.lua        -- Вспомогательные функции (обёртка текста, затемнение цвета и т.д.)
└── widgets          -- Виджеты интерфейса
    ├── button.lua
    ├── checkbox.lua
    ├── console.lua
    ├── label.lua
    ├── progressbar.lua
    └── textinput.lua
```

## Установка

Для установки новой версии OpenUI выполните следующие шаги:

1. Скачайте установочный скрипт:
   ```bash
   pastebin get vSjUmJHj -f installer
   ```
2. Запустите установщик:
   ```bash
   installer
   ```
   
Установщик создаст директорию `/home/openui` с описанной выше структурой файлов.

## Подключение библиотеки

После установки подключите библиотеку в своём коде:
```lua
local OpenUI = require("openui")
```
Модули и виджеты доступны через:
- Основные функции: `OpenUI.run()`, `OpenUI.showError()`, `OpenUI.print()`
- Страницы: `OpenUI.page.new()` и `OpenUI.page.createWindow()`
- Виджеты: `OpenUI.widgets.button`, `OpenUI.widgets.label`, `OpenUI.widgets.textinput`, `OpenUI.widgets.checkbox`, `OpenUI.widgets.progressbar`, `OpenUI.widgets.console`

## Основные функции

### 1. Создание окна (страницы)

Страница — это контейнер для виджетов. Создать главное окно можно следующим образом:
```lua
local mainPage = OpenUI.page.createWindow({
    title = "Главное окно",
    bgColor = 0x0000AA  -- Синий фон
})
```
Для создания дополнительных (вспомогательных) страниц используйте:
```lua
local page = OpenUI.page.new({
    title = "Вспомогательная страница",
    bgColor = 0x001100
})
```

### 2. Переключение страниц

Для смены текущей страницы используйте функцию, вызываемую внутри модуля `page`:
```lua
OpenUI.setCurrentPage(mainPage)
```
Эта функция обновляет глобальную переменную текущей страницы и перерисовывает окно.

### 3. Запуск интерфейса

После настройки всех страниц и добавления виджетов запустите главный цикл обработки событий:
```lua
OpenUI.run()
```
При завершении работы (например, при нажатии на крестик в главном окне) цикл корректно остановится без аварийного завершения.

## Виджеты

Все виджеты создаются через соответствующие модули, доступные по таблице `OpenUI.widgets`.

### 1. Кнопка (Button)

Кнопка выполняет заданную функцию при нажатии.
```lua
local button = OpenUI.widgets.button.new({
    x = 5,
    y = 3,
    text = "Нажми меня",
    bgColor = 0x444444,
    fgColor = 0xFFFFFF,
    callback = function()
        OpenUI.print("Кнопка нажата!")
    end
})
mainPage:addWidget(button)
```

### 2. Метка (Label)

Метка выводит текст.
```lua
local label = OpenUI.widgets.label.new({
    x = 2,
    y = 1,
    text = "Привет, мир!",
    fgColor = 0xFFFFFF
})
mainPage:addWidget(label)
```

### 3. Поле ввода (TextInput)

Поле ввода позволяет пользователю вводить текст. При изменении текста вызывается функция обратного вызова.
```lua
local input = OpenUI.widgets.textinput.new({
    x = 2,
    y = 5,
    width = 20,
    text = "Введите текст",
    onChange = function(text)
        OpenUI.print("Введено: " .. text)
    end
})
mainPage:addWidget(input)
```

### 4. Флажок (CheckBox)

Чекбокс позволяет переключать состояние (вкл./выкл.).
```lua
local checkbox = OpenUI.widgets.checkbox.new({
    x = 2,
    y = 7,
    text = "Согласен",
    onToggle = function(state)
        OpenUI.print("Флажок: " .. tostring(state))
    end
})
mainPage:addWidget(checkbox)
```

### 5. Индикатор выполнения (ProgressBar)

Индикатор выполнения отображает текущий прогресс.
```lua
local progress = OpenUI.widgets.progressbar.new({
    x = 2,
    y = 9,
    width = 30,
    progress = 0.5
})
mainPage:addWidget(progress)

-- Для обновления прогресса:
progress:setProgress(0.8)
```

### 6. Консоль (Console)

Консоль используется для вывода сообщений внутри интерфейса.
```lua
local console = OpenUI.widgets.console.new({
    x = 2,
    y = 11,
    width = 40,
    height = 5
})
OpenUI.consoleWidget = console  -- Устанавливаем глобальную консоль для OpenUI.print
mainPage:addWidget(console)

OpenUI.print("Программа запущена!")
```

## Работа с событиями

### Обработка касаний

Все виджеты автоматически обрабатывают события `touch`. При касании вызывается функция `handleTouch(x, y)`, которая обрабатывает нажатие, например, кнопки или чекбокса.

### Обработка клавиатуры

Если у виджета определена функция `handleKey(char, code, player)`, он может обрабатывать ввод с клавиатуры. Например, текстовое поле вызывает эту функцию для ввода символов.

Пример имитации нажатия клавиши (символ "A"):
```lua
input:handleKey(65, 30)
```

## Обработка ошибок

При возникновении ошибки OpenUI отобразит её в отдельном окне с подробным сообщением:
```lua
OpenUI.showError("Ошибка подключения!")
```
Это позволяет пользователю увидеть информацию об ошибке и корректно завершить работу приложения.

## Пример
```lua
local OpenUI = require("openui")

-- Создаем главное окно (страницу)
local mainPage = OpenUI.page.createWindow({
  title = "Мое Приложение",
  bgColor = 0x001122  -- Темно-синий фон
})

----------------------------------------------------------------
-- Виджет: Метка
----------------------------------------------------------------
local welcomeLabel = OpenUI.widgets.label.new({
  x = 2,
  y = 2,
  text = "Добро пожаловать в мое приложение!",
  fgColor = 0xFFFFFF
})
mainPage:addWidget(welcomeLabel)

----------------------------------------------------------------
-- Виджет: Поле ввода
----------------------------------------------------------------
local inputField = OpenUI.widgets.textinput.new({
  x = 2,
  y = 4,
  width = 30,
  text = "",
  fgColor = 0x000000,
  bgColor = 0xCCCCCC,
  onChange = function(text)
    OpenUI.print("Введено: " .. text)
  end
})
mainPage:addWidget(inputField)

----------------------------------------------------------------
-- Виджет: Кнопка
----------------------------------------------------------------
local updateButton = OpenUI.widgets.button.new({
  x = 2,
  y = 6,
  text = "Обновить метку",
  bgColor = 0x444444,
  fgColor = 0xFFFFFF,
  callback = function()
    local newText = inputField:getText()
    welcomeLabel:setText("Вы ввели: " .. newText)
    mainPage:draw()  -- Перерисовка страницы для отображения изменений
    OpenUI.print("Метка обновлена!")
  end
})
mainPage:addWidget(updateButton)

----------------------------------------------------------------
-- Виджет: Флажок (чекбокс)
----------------------------------------------------------------
local debugCheckBox = OpenUI.widgets.checkbox.new({
  x = 2,
  y = 8,
  text = "Включить режим отладки",
  fgColor = 0xFFFFFF,
  bgColor = 0x001122,
  onToggle = function(state)
    OpenUI.print("Режим отладки: " .. tostring(state))
  end
})
mainPage:addWidget(debugCheckBox)

----------------------------------------------------------------
-- Виджет: Индикатор выполнения (прогресс-бар)
----------------------------------------------------------------
local progressBar = OpenUI.widgets.progressbar.new({
  x = 2,
  y = 10,
  width = 40,
  progress = 0.3,  -- Начальное значение 30%
  fgColor = 0x00FF00,
  bgColor = 0x555555
})
mainPage:addWidget(progressBar)

-- Для демонстрации обновления прогресса (псевдо-анимация)
local function updateProgress()
  for i = 0.3, 1, 0.1 do
    progressBar:setProgress(i)
    mainPage:draw()
    os.sleep(0.2)
  end
end

----------------------------------------------------------------
-- Виджет: Консоль для вывода сообщений
----------------------------------------------------------------
local consoleWidget = OpenUI.widgets.console.new({
  x = 2,
  y = 12,
  width = 50,
  height = 5,
  fgColor = 0xFFFFFF,
  bgColor = 0x000000
})
OpenUI.consoleWidget = consoleWidget  -- Глобальная консоль для OpenUI.print
mainPage:addWidget(consoleWidget)

OpenUI.print("Приложение запущено!")

----------------------------------------------------------------
-- Дополнительный виджет: кнопка для обновления прогресса
----------------------------------------------------------------
local progressButton = OpenUI.widgets.button.new({
  x = 45,
  y = 10,
  text = "Старт",
  bgColor = 0x444444,
  fgColor = 0xFFFFFF,
  callback = function()
    updateProgress()
    OpenUI.print("Прогресс обновлен!")
  end
})
mainPage:addWidget(progressButton)

----------------------------------------------------------------
-- Запуск приложения
----------------------------------------------------------------
OpenUI.setCurrentPage(mainPage)
OpenUI.run()

```

## Заключение

Новая модульная версия OpenUI предоставляет те же возможности для создания графических интерфейсов, но теперь имеет более удобную и структурированную архитектуру. Используйте OpenUI для создания современных, отзывчивых и удобных интерфейсов в ваших проектах на OpenComputers!

---

Пусть ваш интерфейс будет удобным и функциональным! 🚀
