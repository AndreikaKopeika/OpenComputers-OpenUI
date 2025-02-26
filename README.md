# OpenUI – Библиотека пользовательских интерфейсов для OpenComputers

**Описание:**  
OpenUI предоставляет набор функций для создания графических интерфейсов в OpenComputers. Помимо базовых элементов (страниц, виджетов, окон, диалогов) библиотека теперь включает расширенные возможности для работы с 3D-графикой, изображениями и рисовалкой (Canvas). Вы можете создавать интерактивные 3D-сцены, загружать/сохранять изображения в собственном формате (.oui), просматривать файловую систему для выбора файлов, а также рисовать и редактировать графику на Canvas.

---

## Основные утилиты

- **`wrapText(text, maxWidth)`**  
  Оборачивает строку `text` по заданной максимальной ширине `maxWidth`.

- **`darkenColor(color, factor)`**  
  Затемняет заданный цвет `color` с коэффициентом `factor` – используется для визуальных эффектов (например, при нажатии на кнопку).

- **`centerText(text, width)`**  
  Центрирует текст по заданной ширине – удобно для вывода заголовков и сообщений.

- **`OpenUI.saveOUI(filename, canvas)`**  
  Сохраняет данные изображения (матрицу пикселей) в файл формата .oui. Формат сохраняет размеры и список пикселей в шестнадцатеричном формате.

- **`OpenUI.loadOUI(filename)`**  
  Загружает изображение из файла формата .oui, возвращая ширину, высоту и таблицу пикселей.

---

## Страницы и окна

- **`OpenUI.newPage(params)`**  
  Создаёт новую страницу. Параметры:
  - `title` – заголовок страницы (по умолчанию `"OpenUI Page"`).
  - `bgColor` – фоновый цвет.
  - `isMain` – если установлено в `true`, страница становится главной.
  - При создании страницы выделяется GPU-буфер для отрисовки.

- **`OpenUI.createWindow(params)`**  
  Альтернативный вызов для создания главной страницы (`isMain=true`).

- **`OpenUI.setCurrentPage(page)`**  
  Устанавливает указанную страницу как активную и отрисовывает её.

- **`OpenUI.run()`**  
  Запускает главный цикл обработки событий (касания, нажатия клавиш, перетаскивания) для текущей страницы.

- **`OpenUI.newMiniWindow(params)`**  
  Создаёт мини-окно, которое можно перемещать за заголовок и закрывать. Параметры:
  - `x`, `y`, `width`, `height` – координаты и размеры окна.
  - `title` – заголовок окна.
  - `bgColor`, `fgColor` – цвета фона и текста.
  - `draggable` – разрешает перетаскивание (по умолчанию `true`).
  - `content` – функция отрисовки контента внутри окна.
  - `onClose` – функция, вызываемая при закрытии окна.
  - Новые методы `show()` и `hide()` позволяют программно отображать или скрывать окно.

- **`OpenUI.drawRoundedBox(x, y, width, height, bgColor, fgColor)`**  
  Рисует прямоугольник с закруглёнными углами – используется для оформления кнопок, полей и окон.

---

## Виджеты

### Базовые виджеты

- **`OpenUI.newButton(params)`**  
  Создаёт кнопку. Параметры:
  - `x`, `y` – позиция.
  - `text` – текст кнопки.
  - `bgColor`, `fgColor` – цвета.
  - `padding` – отступы.
  - `rounded` – если `true`, кнопка рисуется с закруглёнными углами.
  - `callback` – функция, вызываемая при нажатии.

- **`OpenUI.newLabel(params)`**  
  Создаёт текстовую метку. Параметры:
  - `x`, `y` – позиция.
  - `text` – текст.
  - `fgColor`, `bgColor` – цвета.

- **`OpenUI.newTextInput(params)`**  
  Создаёт поле ввода текста. Параметры:
  - `x`, `y`, `width` – координаты и ширина.
  - `text` – начальное значение.
  - `fgColor`, `bgColor` – цвета.
  - `rounded` – если `true`, рамка с закруглёнными углами.
  - `onChange` – функция, вызываемая при изменении текста.

- **`OpenUI.newCheckBox(params)`**  
  Создаёт флажок (чекбокс). Параметры:
  - `x`, `y` – позиция.
  - `text` – текст рядом с флажком.
  - `checked` – начальное состояние (`true`/`false`).
  - `onToggle` – функция, вызываемая при изменении состояния.

- **`OpenUI.newProgressBar(params)`**  
  Создаёт индикатор выполнения. Параметры:
  - `x`, `y`, `width` – позиция и ширина.
  - `progress` – значение от 0 до 1.
  - `fgColor`, `bgColor` – цвета.

- **`OpenUI.newConsole(params)`**  
  Создаёт консольный виджет для вывода сообщений. Параметры:
  - `x`, `y`, `width`, `height` – позиция и размеры.
  - `fgColor`, `bgColor` – цвета.
  - `maxLines` – максимальное число строк.

- **`OpenUI.newSlider(params)`**  
  Создаёт слайдер для выбора значения в заданном диапазоне. Параметры:
  - `x`, `y`, `width` – позиция и ширина.
  - `min`, `max` – диапазон значений.
  - `value` – начальное значение.
  - `rounded` – закруглённое оформление.
  - `onChange` – функция, вызываемая при изменении значения.

- **`OpenUI.newDropdown(params)`**  
  Создаёт выпадающий список (dropdown). Параметры:
  - `x`, `y`, `width` – позиция и ширина.
  - `options` – массив вариантов.
  - `selected` – индекс выбранного варианта.
  - `onChange` – функция, вызываемая при выборе опции.

- **`OpenUI.confirmDialog(params)`**  
  Модальное окно с подтверждением (Да/Нет). Параметры:
  - `message` – сообщение.
  - `yesText`, `noText` – подписи кнопок.  
  Возвращает: `true`, если выбран "Да", или `false`, если "Нет".

- **`OpenUI.showInfo(message, duration)`**  
  Выводит информационное сообщение в виде всплывающего окна, которое автоматически исчезает через заданное время (`duration` в секундах).

- **`OpenUI.print(...)`**  
  Выводит текст в консольный виджет, если он назначен, или использует стандартный вывод.

### Новые виджеты для расширенной функциональности

- **`OpenUI.new3DWidget(params)`**  
  Создаёт виджет для отображения 3D-сцены (например, вращающийся куб). Параметры:
  - `x`, `y`, `width`, `height` – координаты и размеры области для 3D-рендеринга.
  - `bgColor`, `fgColor` – цвета фона и отрисовки.
  - `fov` – поле зрения.
  - `viewerDistance` – расстояние до наблюдателя.
  - `angle` – начальный угол поворота.
  - `model` – 3D-модель (вершины и рёбра); если не задана, используется модель куба по умолчанию.

- **`OpenUI.newImageWidget(params)`**  
  Виджет для работы с изображениями. Позволяет загружать изображение из файла формата **.oui** и отображать его пиксели. Дополнительные методы:
  - `setImageFile(filePath)` – загружает изображение из файла.
  - `getImageFile()` – возвращает путь к текущему изображению.

- **`OpenUI.newFileChooser(params)`**  
  Виджет для графического выбора файла из файловой системы (начиная с каталога **/home**). Поддерживает навигацию по папкам (вход в директорию, переход на уровень выше). Параметры:
  - `startPath` – начальный путь (по умолчанию **/home**).
  - `title` – заголовок виджета.
  - `onSelect(filePath)` – обратный вызов при выборе файла, возвращающий полный путь выбранного файла.

- **`OpenUI.newCanvas(params)`**  
  Виджет Canvas – рисовалка, позволяющая работать с пиксельной графикой. Позволяет:
  - Закрашивать отдельные «пиксели» по касанию.
  - Метод `setColor(color)` для установки текущего цвета рисования.
  - Методы `setPixel(px, py, color)` и `getPixel(px, py)` для работы с отдельными пикселями.
  - Методы `save(filename)` и `load(filename)` для сохранения/загрузки рисунка в формате **.oui**.

---

## Дополнительные функции для работы с изображениями

- **Формат .oui (OpenUI Image):**  
  Этот формат хранит размеры изображения и данные пикселей (цвета в шестнадцатеричном формате).  
  Методы:  
  - `OpenUI.saveOUI(filename, canvas)` – сохраняет содержимое Canvas в файл .oui.  
  - `OpenUI.loadOUI(filename)` – загружает изображение из файла .oui.

---

## Заключение

**OpenUI** – гибкий инструмент для создания пользовательских интерфейсов в OpenComputers. Благодаря новейшим расширениям вы можете не только создавать классические UI-элементы, но и работать с 3D-графикой, изображениями, файловой навигацией и рисовалкой с сохранением/загрузкой в собственном формате .oui. Возможности библиотеки легко расширяются новыми идеями и доработками.

---

## Пример использования новых функций

```lua
local OpenUI = require("openui")
local component = require("component")
local gpu = component.gpu
local os = require("os")

-- Создаём главную страницу
local mainPage = OpenUI.newPage{
  title = "OpenUI Demo: Canvas & File Chooser",
  bgColor = 0x737373
}

----------------------------------
-- 1. Виджет Canvas (16×16) для рисования
----------------------------------
local canvasWidget = OpenUI.newCanvas{
  x = 2, y = 2,
  width = 30, height = 15,
  bgColor = 0xFFFFFF,    -- белый фон
  currentColor = 0xFF0000 -- красный цвет по умолчанию
}
mainPage:addWidget(canvasWidget)

----------------------------------
-- 2. Виджет Image для отображения изображения (.oui)
----------------------------------
local imageWidget = OpenUI.newImageWidget{
  x = 45, y = 2,
  width = 30, height = 15,
  bgColor = 0x000000,
  fgColor = 0xFFFFFF,
  onClick = function()
    OpenUI.print("Image widget нажат!")
  end
}
-- Пытаемся загрузить изображение из файла "/home/sample.oui" (если файл существует)
pcall(function() imageWidget:setImageFile("/home/sample.oui") end)
mainPage:addWidget(imageWidget)

----------------------------------
-- 3. Кнопка "Сохранить Canvas"
----------------------------------
local saveButton = OpenUI.newButton{
  x = 2, y = 19,
  text = "Save Canvas",
  bgColor = 0x0077CC,
  fgColor = 0xFFFFFF,
  rounded = true,
  callback = function()
    local filename = "/home/canvas_save.oui"
    canvasWidget:save(filename)
    OpenUI.print("Canvas сохранён в " .. filename)
    OpenUI.showInfo("Canvas saved!", 2)
  end
}
mainPage:addWidget(saveButton)

----------------------------------
-- 4. Кнопка "Загрузить Canvas"
----------------------------------
local loadButton = OpenUI.newButton{
  x = 20, y = 19,
  text = "Load Canvas",
  bgColor = 0x0077CC,
  fgColor = 0xFFFFFF,
  rounded = true,
  callback = function()
    local filename = "/home/canvas_save.oui"
    pcall(function() canvasWidget:load(filename) end)
    OpenUI.print("Canvas загружен из " .. filename)
    OpenUI.showInfo("Canvas loaded!", 2)
  end
}
mainPage:addWidget(loadButton)

----------------------------------
-- 5. Виджет File Chooser для выбора файла из /home (перемещён на правую сторону)
----------------------------------
local fileChooser = OpenUI.newFileChooser{
  x = 45, y = 16, -- теперь на правой стороне, под imageWidget
  width = 30, height = 8,
  bgColor = 0x333333,
  fgColor = 0xFFFFFF,
  title = "File Chooser",
  startPath = "/home",
  fileFilter = {".oui"},
  onSelect = function(filePath)
    OpenUI.print("Выбран файл: " .. filePath)
    -- Загружаем выбранное изображение в imageWidget
    imageWidget:setImageFile(filePath)
  end
}
mainPage:addWidget(fileChooser)

----------------------------------
-- 6. Консоль для вывода логов
----------------------------------
local consoleWidget = OpenUI.newConsole{
  x = 2, y = 30,
  width = 80, height = 8,
  fgColor = 0xFFFFFF, bgColor = 0x444444,
  maxLines = 10
}
OpenUI.consoleWidget = consoleWidget
mainPage:addWidget(consoleWidget)

----------------------------------
-- Стартовые сообщения и запуск интерфейса
----------------------------------
OpenUI.print("Demo загружен: Canvas (16×16), Image, Save/Load кнопки и File Chooser")
OpenUI.print("Рисуйте на Canvas и выбирайте файлы для загрузки изображений.")

OpenUI.setCurrentPage(mainPage)
OpenUI.run()

```
