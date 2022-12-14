local com = require("component") -- +
local gpu = com.gpu -- +
local term = require("term") -- +
local shell = require("shell") -- +
local event = require("event") -- +
local fs = require("filesystem") -- +
local unicode = require("unicode") -- +
local listChest = com.list("diamond") -- +
local arrChest = {} --Таблица сундуков +
local countAllItem = 0 --Количество слитков для обмена +
local countAllItemSave = 0 --Количество слитков для обмена сохраненые +
local acceptChest = com.me_interface --Получаем интерфейс для отправки предметов +
local listItemForSale = {} --Список предметов на продажу +
local checksum = 0 --Контрольная сумма +
local checksumSave = 0 --Контрольная сумма сохраненая +
local selectedCount = 0 --Выбранное количество предмета +

 
if not fs.exists("/lib/Sky.lua") then
    shell.execute("wget https://www.dropbox.com/s/1xbv3nrfpkm6mg0/Sky%28lib%29.lua?dl=1 /lib/Sky.lua")
end

shell.execute("wget -f https://raw.githubusercontent.com/Liseeeenok/shop-for-MC/main/shop_db.lua /home/shop/shop_bd.lua")

local arrCategories = require('shop_bd') --Таблица продаваемых предметов +

local Sky = require("Sky") -- +
 
local function getListChest() --Список сундуков со слитками +
  local index = 1 --Индекс для заполнения таблицы
  for i, adr in pairs(listChest) do --Заполняем и выводим таблицу
    table.insert(arrChest, i)
    print(index .. " " .. i)
    index = index + 1
  end
end
 
getListChest()
 
print("С какого сундука будут забираться слитки?")
local indexGiveChest = tonumber(io.read()) --Получаем сундук для отправки слитков +
local giveChest = com.proxy(arrChest[indexGiveChest])
 
local function getListItemForSale(itemGet) --Получаем список предметов на продажу +
  checksum = 0 --Обнуляем контрольную сумму
  listItemForSale = {} --Обнуляем прошлый список
  local listItemChest = acceptChest.getItemsInNetwork() --Смотрим какие ресурсы в сундуке лежат
  local j = 1
  for i=1, listItemChest["n"] do --Проходим по таблице ресурсов в интерфейсе
    for key, value in pairs(itemGet) do --Проходим по таблице ресурсов для продажи
      if listItemChest[j].name == value.name and listItemChest[j].damage == value.dmg then --Если названия сходятся
        local newItem = {id=value.id, rusName=value.rusName, sale=value.sale, countItem=listItemChest[j].size, idName=listItemChest[j].name, dmg=value.dmg} --Формируем новый объект
        checksum = newItem.countItem + checksum; --Формируем контрольную сумму
        table.insert(listItemForSale, newItem) --Заполняем таблицу для продажи
      end
    end
  j = j + 1
  end
end
 
local function updChest() --Обновление сундуков (количество слитков и сортировка) +
  countAllItem = 0 --Количество слитков для покупки
  for i, adr in ipairs(arrChest) do --Цикл по всем сундукам
      com.proxy(adr).condenseItems() --Делаем порядок в сундуке
      local arrThisChest = com.proxy(adr).getAllStacks(false) --Получаем кол-во ресурса в сундуке
      for index, item in pairs(arrThisChest) do --Проходи по всем ячейкам сундука
        countAllItem = countAllItem + item.qty --Суммируем количество слитков
    end
  end
end
 
local function pullItemChest(count) --Переброска слитков +
  while count > 0 do
    if count > 64 then
      count = count - giveChest.pushItemIntoSlot("East", 1, 64, _)    
    else
      count = count - giveChest.pushItemIntoSlot("East", 1, count, _)
    end
    updChest()
  end
end
 
local function pullItemForSale(count, itemGet) --Переброска проданных предметов +
  while count > 0 do
    if count > 64 then
      count = count - acceptChest.exportItem({id=itemGet.idName, dmg=itemGet.dmg, _}, "UP", 64, _).size
    else
      count = count - acceptChest.exportItem({id=itemGet.idName, dmg=itemGet.dmg, _}, "UP", count, _).size
    end
    updChest()
  end
end
 
local function giveAll() --Выдача всех слитков покупателю +
  while countAllItem > 0 do
    giveChest.pushItemIntoSlot("North", 1, 64, _)
    updChest()
  end
end
 
 
local function updSelectedCount(count) --Обновляет количество запрашиваемого ресурса +
  if count >= 0 then
    if selectedCount == 0 then
      selectedCount = count
    elseif selectedCount < 1000 then
      selectedCount = selectedCount*10 + count
    end
  else
    selectedCount = math.modf(selectedCount/10)
  end
end
 
function event.shouldInterrupt() -- Блокирует закрытие через Ктрл + альт + С
    return false
end
---------------------GUI------------------
 
function Sky.Table1(x,y,w,h,col1,col2,text) --Первая ячейка таблицы
    gpu.setForeground(col1)
    gpu.set(x + w/2 - unicode.len(text)/2, y+h/2, text)
    gpu.setForeground(col2)
    for i = 1, w-2 do
        gpu.set(x+i,y+h-1,"─")
    end
    for i = 1, h-2 do
        gpu.set(x,y+i,"│")
        gpu.set(x+w-1,y+i,"│")
    end
    gpu.set(x,y+h-1,"└")
    gpu.set(x+w-1,y+h-1,"┘")
end
 
function Sky.Table2(x,y,w,h,col1,col2,text) --Остальные ячейки таблицы
    gpu.setForeground(col1)
    gpu.set(x + w/2 - unicode.len(text)/2, y+h/2, text)
    gpu.setForeground(col2)
    for i = 1, w-2 do
        gpu.set(x+i,y+h-1,"─")
    end
    for i = 1, h-2 do
        gpu.set(x+w-1,y+i,"│")
    end
    gpu.set(x,y+h-1,"─")
    gpu.set(x+w-1,y+h-1,"┘")
end
 
 
local function setOldColor()
  gpu.setForeground(0xffffff)
  gpu.setBackground(0)
end
 
local function printLogo()
  gpu.setBackground(0x00ff00)
  gpu.fill(31, 2, 8, 1, " ") --S
  gpu.fill(29, 3, 2, 2, " ")
  gpu.fill(31, 5, 6, 1, " ")
  gpu.fill(37, 6, 2, 2, " ")
  gpu.fill(29, 8, 8, 1, " ")
  --
  gpu.fill(41, 2, 2, 7, " ") --H
  gpu.fill(43, 4, 6, 1, " ")
  gpu.fill(49, 5, 2, 4, " ")
  --
  gpu.fill(55, 4, 6, 1, " ") --O
  gpu.fill(55, 8, 6, 1, " ")
  gpu.fill(53, 5, 2, 3, " ")
  gpu.fill(61, 5, 2, 3, " ")
  --
  gpu.fill(67, 4, 6, 1, " ") --P
  gpu.fill(65, 4, 2, 7, " ")
  gpu.fill(67, 8, 6, 1, " ")
  gpu.fill(73, 5, 2, 3, " ")
  --
  gpu.fill(80, 2, 2, 7, " ") --B
  gpu.fill(82, 4, 6, 1, " ")
  gpu.fill(88, 5, 2, 3, " ")
  gpu.fill(82, 8, 6, 1, " ")
  --
  gpu.fill(92, 4, 2, 4, " ") --Y
  gpu.fill(94, 8, 6, 1, " ")
  gpu.fill(100, 4, 2, 6, " ")
  gpu.fill(94, 10, 6, 1, " ")
  --
  gpu.fill(106, 2, 2, 6, " ") --L
  gpu.fill(108, 8, 8, 1, " ")
  --
  gpu.fill(118, 2, 2, 1, " ") --I
  gpu.fill(118, 4, 2, 5, " ")
  --
  gpu.fill(124, 4, 5, 1, " ") --S
  gpu.fill(122, 5, 2, 1, " ")
  gpu.fill(124, 6, 4, 1, " ")
  gpu.fill(128, 7, 2, 1, " ")
  gpu.fill(123, 8, 5, 1, " ")
end
 
local function printBalance() --Вывод баланса +
  if countAllItemSave ~= countAllItem then
    countAllItemSave = countAllItem
    gpu.setBackground(0)
    gpu.fill(146,2,14,1, " ")
    Sky.Button(145,1,16,3,0x33DB00,0x334980, "Баланс: "..countAllItem)
  end
end
 
local function printSelectedCount(price) --Вывод Коли-ва покупаемых предметов +
  gpu.fill(71, 27, 15, 1, " ")
  gpu.setForeground(0x33DB00)
  Sky.Text(66, 27, "Количество: "..selectedCount)
  gpu.fill(89, 27, 8, 1, " ")
  Sky.Text(85, 27, "Цена: "..price)
end
 
local function clearScreen() --Отчистка таблицы
  gpu.setBackground(0)
  gpu.fill(1, 21, 160, 33, " ")
end

local function clearFullScreen() --Отчистка экрана полностью
  gpu.setBackground(0)
  gpu.fill(1, 11, 160, 40, " ")
end

local function printHeaderTable()
    gpu.setForeground(0x994900)
    Sky.Button(72,14,16,3,0x33DB00,0x334980, "Назад:")
    Sky.Text(16,17,"Для покупки нужно нажать на название предмета")
    Sky.Button(16,18,32,3,0x994900,0x334980, "id")
    Sky.Button(47,18,34,3,0x994900,0x334980, "Название")
    Sky.Button(80,18,32,3,0x994900,0x334980, "Цена за 1 шт")
    Sky.Button(111,18,32,3,0x994900,0x334980, "Количество в сети")
end

local function printItemSale(itemGet) --Окно покупки товара
  printBalance()
  clearFullScreen()
--------------------------Рамка--------------------------------------
  for i = 42, 119 do
    gpu.set(i,24,"=")
    gpu.set(i,45,"=")
  end
  for i = 24, 45 do
    gpu.set(40, i, "||")
    gpu.set(120, i, "||")
  end
  if selectedCount <= itemGet.countItem and math.ceil(selectedCount*itemGet.sale) <= countAllItem then
    Sky.Text(160/2 - unicode.len("[ " .. "Процесс покупки товара..." .. " ]")/2,25,"[ " .. "Процесс покупки товара..." .. " ]")
    gpu.setForeground(0x33DB00)
    Sky.Text(160/2 - unicode.len("Процесс покупки товара...")/2,25,"Процесс покупки товара...")
    pullItemChest(math.ceil(selectedCount*itemGet.sale))
    pullItemForSale(selectedCount, itemGet)
    Sky.Text(160/2 - unicode.len("Спасибо за покупку!")/2,29,"Спасибо за покупку!")
    Sky.Text(160/2 - unicode.len("Товар уже в сундуке")/2,31,"Товар уже в сундуке")
    Sky.Text(160/2 - unicode.len("Не забудьте забрать слитки в главном меню!")/2,34,"Не забудьте забрать слитки в главном меню!")
  elseif math.ceil(selectedCount*itemGet.sale) > countAllItem then
    Sky.Text(160/2 - unicode.len("[ " .. "ОШИБКА" .. " ]")/2,25,"[ " .. "ОШИБКА" .. " ]")
    gpu.setForeground(0x33DB00)
    Sky.Text(160/2 - unicode.len("ОШИБКА")/2,25,"ОШИБКА")
    Sky.Text(160/2 - unicode.len("У Вас недостаточно слитков")/2,30,"У Вас недостаточно слитков")
  elseif selectedCount > itemGet.countItem then
    Sky.Text(160/2 - unicode.len("[ " .. "ОШИБКА" .. " ]")/2,25,"[ " .. "ОШИБКА" .. " ]")
    gpu.setForeground(0x33DB00)
    Sky.Text(160/2 - unicode.len("ОШИБКА")/2,25,"ОШИБКА")
    Sky.Text(160/2 - unicode.len("В сети недостаточно товара")/2,30,"В сети недостаточно товара")
  end
  Sky.Button(72,38,16,3,0x33DB00,0x334980, "ОК")
--------------------------Рамка--------------------------------------
  while true do
    printBalance()
    local e,adress,x,y,numberMouse,nick = event.pull(1, "touch")
    if e == "touch" then
      if x >= 72 and  x <= 87 and y >= 38 and y <= 40 then
        clearFullScreen()
        selectedCount  = 0
        printHeaderTable()
        checksum = 0
        return
      end
    end
  end
end
 
local function printCountForSale(itemGet) --Окно выбора кол-ва товара
  clearScreen()
--------------------------Рамка--------------------------------------
  gpu.setBackground(0x000000)
  gpu.setForeground(0x334980)
  for i = 42, 119 do
      gpu.set(i,24,"=")
      gpu.set(i,45,"=")
  end
  for i = 24, 45 do
      gpu.set(40, i, "||")
      gpu.set(120, i, "||")
  end
  Sky.Text(160/2 - unicode.len("[ " .. "Сколько Вы хотите купить?" .. " ]")/2,25,"[ " .. "Сколько Вы хотите купить?" .. " ]")
  gpu.setForeground(0x33DB00)
  Sky.Text(160/2 - unicode.len("Сколько Вы хотите купить?")/2,25,"Сколько Вы хотите купить?")
--------------------------Рамка--------------------------------------
  printSelectedCount(math.ceil(selectedCount*itemGet.sale))
  Sky.Button(66,29,11,3,0x994900,0x334980, "1")
  Sky.Button(77,29,11,3,0x994900,0x334980, "2")
  Sky.Button(88,29,11,3,0x994900,0x334980, "3")
  Sky.Button(66,32,11,3,0x994900,0x334980, "4")
  Sky.Button(77,32,11,3,0x994900,0x334980, "5")
  Sky.Button(88,32,11,3,0x994900,0x334980, "6")
  Sky.Button(66,35,11,3,0x994900,0x334980, "7")
  Sky.Button(77,35,11,3,0x994900,0x334980, "8")
  Sky.Button(88,35,11,3,0x994900,0x334980, "9")
  Sky.Button(66,38,11,3,0x994900,0x334980, "←")
  Sky.Button(77,38,11,3,0x994900,0x334980, "0")
  Sky.Button(88,38,15,3,0x994900,0x334980, "Подтвердить")
  while true do
    updChest()
    printBalance()
    if checksumSave ~= checksum then
      gpu.setBackground(0)
      gpu.fill(1, 21, 160, 2, " ")
      Sky.Table1(16,20,32,3,0x33DB00,0x334980, itemGet.id)
      Sky.Table2(47,20,34,3,0x33DB00,0x334980, itemGet.rusName)
      Sky.Table2(80,20,32,3,0x33DB00,0x334980, itemGet.sale)
      Sky.Table2(111,20,32,3,0x33DB00,0x334980, tostring(itemGet.countItem))
    end
    local e,adress,x,y,numberMouse,nick = event.pull(1, "touch")
    if e == "touch" then
      if x >= 72 and  x <= 87 and y >= 14 and y <= 16 then
        clearScreen() --Назад
        selectedCount = 0
        checksumSave = 0
        return
      elseif x >= 88 and  x <= 125 and y >= 38 and y <= 40 then
        printItemSale(itemGet) --Подтвердить
        return
      elseif x >= 66 and x <= 76 and y >= 38 and y <= 40 then
        updSelectedCount(-1)
        printSelectedCount(math.ceil(selectedCount*itemGet.sale)) --backspace
      elseif x >= 77 and x <= 87 and y >= 38 and y <= 40 then
        updSelectedCount(0)
        printSelectedCount(math.ceil(selectedCount*itemGet.sale)) --0
      else
        local xBut1
        local xBut2
        for i=1, 9 do
            if i>=1 and i <=3 then
                xBut1 = 55+11*i
                xBut2 = 65+11*i
                if x >= xBut1 and x <= xBut2 and y >= 29 and y <= 31 then
                  updSelectedCount(i)
                  printSelectedCount(math.ceil(selectedCount*itemGet.sale))
                end
            elseif i>=4 and i <=6 then
                xBut1 = 55+11*(i-3)
                xBut2 = 65+11*(i-3)
                if x >= xBut1 and x <= xBut2 and y >= 32 and y <= 34 then
                  updSelectedCount(i)
                  printSelectedCount(math.ceil(selectedCount*itemGet.sale))
                end
            elseif i>=7 and i <=9 then
                xBut1 = 55+11*(i-6)
                xBut2 = 65+11*(i-6)
                if x >= xBut1 and x <= xBut2 and y >= 35 and y <= 37 then
                  updSelectedCount(i)
                  printSelectedCount(math.ceil(selectedCount*itemGet.sale))
                end
            end
        end
      end
    end
  end
end
 
local function printCategory(itemGet) --Окно товара в категории
  clearFullScreen()
  printHeaderTable()
  while true do
    updChest()
    printBalance()
    getListItemForSale(itemGet)
    if checksumSave ~= checksum then
        checksumSave = checksum
        clearScreen()
        for index, item in pairs(listItemForSale) do
          Sky.Table1(16,18+index*2,32,3,0x33DB00,0x334980, item.id)
          Sky.Table2(47,18+index*2,34,3,0x33DB00,0x334980, item.rusName)
          Sky.Table2(80,18+index*2,32,3,0x33DB00,0x334980, item.sale)
          Sky.Table2(111,18+index*2,32,3,0x33DB00,0x334980, tostring(item.countItem))
        end
    end
    local e,adress,x,y,numberMouse,nick = event.pull(1, "touch")
    if e == "touch" then
      if x >= 72 and  x <= 87 and y >= 14 and y <= 16 then
        clearFullScreen()
        return
      else
        for index, item in pairs(listItemForSale) do
          if x >= 16 and  x <= 142 and y >= 18+index*2 and y <= 20+index*2 then
            checksumSave = 0
            printCountForSale(item)
          end
        end
      end
    end
  end
end
 
-------------------------------------------------------------------
term.clear()
printLogo()
local redrawing = true
while true do
  updChest()
  printBalance()
  setOldColor()
  if redrawing then
    Sky.Button(72,14,16,3,0x33DB00,0x334980, "Категории:")
    for index, item in pairs(arrCategories) do
      if index <= 4 then
        local xBut = 16+32*(index-1)
        Sky.Button(xBut,18,32,3,0x33DB00,0x334980, item.category)
      elseif index > 4 and index <= 8 then
        local xBut = 16+32*(index-5)
        Sky.Button(16+32*(index-5),22,32,3,0x33DB00,0x334980, item.category)
      end
    end
    Sky.Button(71,48,18,3,0x33DB00,0x334980, "Забрать слитки")
    redrawing = false
  end
  local e,adress,x,y,numberMouse,nick = event.pull(1, "touch")
  if e == "touch" then
    if y >= 48 and y <= 50 and x >= 71 and x <= 88 then
      giveAll()
      setOldColor()
    else
      for index, item in pairs(arrCategories) do
        if index <= 4 then
          local xBut = 16+32*(index-1)
          if y >= 18 and y <= 20 and x >= xBut and x <= xBut + 31 then
            checksumSave = 0
            redrawing = true
            printCategory(item.items)
          end
        elseif index > 4 and index <= 8 then
          local xBut = 16+32*(index-5)
          if y >= 22 and y <= 24 and x >= xBut and x <= xBut + 31 then
            checksumSave = 0
            redrawing = true
            printCategory(item.items)
          end
        end
      end
    end
  end
-------------Временный выход из программы-------------------------
  if e == "touch" then
    if x == 1 and y == 1 then
       giveAll()
       setOldColor()
       term.clear()
       os.exit()
     end
   end
end