# Документация для OpenUI

## Введение
**OpenUI** — это библиотека для создания графического пользовательского интерфейса в OpenComputers. Она поддерживает создание окон, кнопок, меток, полей ввода, чекбоксов, прогресс-баров и консоли. OpenUI работает с GPU-буферами для повышения производительности и удобства использования.

## Установка
Сохраните `openui.lua` в вашу файловую систему OpenComputers и подключите библиотеку в своём коде:
```bash
wget 'https://github.com/AndreikaKopeika/OpenComputers-OpenUI/blob/main/openui.lua' -f openui.lua
```

```lua
local OpenUI = require("openui")
```

## Основные функции

### 1. Создание окна (страницы)
Страница — это контейнер для виджетов. Можно создать несколько страниц и переключаться между ними.

```lua
local mainPage = OpenUI.createWindow({
    title = "Главное окно",
    bgColor = 0x0000AA  -- Синий фон
})
```

`createWindow` создаёт главное окно (основную страницу), `newPage` создаёт обычные страницы.

### 2. Переключение страниц
Для переключения между страницами используйте:

```lua
OpenUI.setCurrentPage(mainPage)
```

### 3. Запуск интерфейса
После настройки всех страниц и виджетов запустите главный цикл:

```lua
OpenUI.run()
```

## Виджеты

### 1. Кнопка (Button)
Кнопка выполняет функцию при нажатии.

```lua
local button = OpenUI.newButton({
    x = 5,
    y = 3,
    text = "Нажми меня",
    bgColor = 0x444444,
    fgColor = 0xFFFFFF,
    callback = function()
        print("Кнопка нажата!")
    end
})
mainPage:addWidget(button)
```

### 2. Метка (Label)
Отображает текст.

```lua
local label = OpenUI.newLabel({
    x = 2,
    y = 1,
    text = "Привет, мир!",
    fgColor = 0xFFFFFF
})
mainPage:addWidget(label)
```

### 3. Поле ввода (TextInput)
Позволяет пользователю вводить текст.

```lua
local input = OpenUI.newTextInput({
    x = 2,
    y = 5,
    width = 20,
    text = "Введите текст",
    onChange = function(text)
        print("Введено: " .. text)
    end
})
mainPage:addWidget(input)
```

### 4. Флажок (CheckBox)
Переключатель с состояниями `вкл./выкл.`.

```lua
local checkbox = OpenUI.newCheckBox({
    x = 2,
    y = 7,
    text = "Согласен",
    onToggle = function(state)
        print("Флажок: " .. tostring(state))
    end
})
mainPage:addWidget(checkbox)
```

### 5. Индикатор выполнения (ProgressBar)
Показывает прогресс.

```lua
local progress = OpenUI.newProgressBar({
    x = 2,
    y = 9,
    width = 30,
    progress = 0.5
})
mainPage:addWidget(progress)
```

Изменить прогресс можно так:

```lua
progress:setProgress(0.8)
```

### 6. Консоль (Console)
Выводит текст в интерфейсе.

```lua
local console = OpenUI.newConsole({
    x = 2,
    y = 11,
    width = 40,
    height = 5
})
OpenUI.consoleWidget = console  -- Устанавливаем глобальную консоль
mainPage:addWidget(console)

OpenUI.print("Программа запущена!")  -- Выведет сообщение в консоль
```

## Работа с событиями

### Обработка касаний
Все виджеты автоматически обрабатывают события `touch`. Например, `handleTouch(x, y)` вызывается при касании кнопки.

### Обработка клавиатуры
Если у виджета есть `handleKey(char, code, player)`, он сможет обрабатывать ввод с клавиатуры.

Пример для текстового поля:
```lua
input:handleKey(65, 30)  -- Символ "A"
```

## Обработка ошибок
Если в коде произойдёт ошибка, OpenUI отобразит её в красивом окне:

```lua
OpenUI.showError("Ошибка подключения!")
```

## Заключение
OpenUI — удобная библиотека для создания интерфейсов в OpenComputers. Она поддерживает буферизацию, виджеты и удобные методы для работы с событиями.

Используйте OpenUI для создания удобных графических интерфейсов в ваших проектах! 🚀
