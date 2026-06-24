--========================================================
-- 暗黑破坏神4：G502 添加词缀2次
-- 分辨率：2560×1440
--========================================================

local SCREEN_W = 2560
local SCREEN_H = 1440

local START_BUTTON = 5
local STOP_BUTTON  = 4

-- 操作范围
local ROWS = 1
local COLS = 10

-- 背包坐标
local BAG_START_X = 1722
local BAG_START_Y = 1017
local BAG_STEP_X = 73
local BAG_STEP_Y = 102

-- 添加词缀
local ADD_AFFIX_X = 1138
local ADD_AFFIX_Y = 330

-- 重塑
local REFORGE_X = 468
local REFORGE_Y = 1140

-- 接受
local ACCEPT_X = 1149
local ACCEPT_Y = 813

-- 魔盒装备取回位置
local CUBE_ITEM_X = 322
local CUBE_ITEM_Y = 480

-- 安全位置
local SAFE_X = 2103
local SAFE_Y = 929

-- 时间配置
local START_DELAY = 2000
local MOVE_DELAY = 200

-- 每步点击后等待1秒
local RECIPE_DELAY = 500
local BAG_CLICK_DELAY = 500
local REFORGE_DELAY = 500
local ACCEPT_DELAY = 500
local RETURN_DELAY = 500

-- 每件完成后等待2秒
local BETWEEN_ITEMS_DELAY = 1000

local running = false

-- 像素坐标转换
function MoveToPixel(x, y)
    local ghubX = math.floor(
        x * 65535 / (SCREEN_W - 1)
    )

    local ghubY = math.floor(
        y * 65535 / (SCREEN_H - 1)
    )

    MoveMouseTo(ghubX, ghubY)
end

-- 获取背包格子坐标
function GetBagSlotPosition(index)
    local row = math.floor(index / COLS)
    local col = index % COLS

    local x = BAG_START_X + col * BAG_STEP_X
    local y = BAG_START_Y + row * BAG_STEP_Y

    -- 第11列向上微调1像素
    if col == COLS - 1 then
        y = y - 1
    end

    return x, y
end

function StopRequested()
    return IsMouseButtonPressed(STOP_BUTTON)
end

-- 可中断等待
function SleepChecked(milliseconds)
    local elapsed = 0
    local interval = 25

    while elapsed < milliseconds do
        if StopRequested() then
            return false
        end

        local sleepTime = interval

        if elapsed + sleepTime > milliseconds then
            sleepTime = milliseconds - elapsed
        end

        Sleep(sleepTime)
        elapsed = elapsed + sleepTime
    end

    return true
end

-- 移动并点击
function ClickAt(x, y, mouseButton, afterDelay)
    if StopRequested() then
        return false
    end

    MoveToPixel(x, y)

    if not SleepChecked(MOVE_DELAY) then
        return false
    end

    PressAndReleaseMouseButton(mouseButton)

    return SleepChecked(afterDelay)
end

function MoveToSafePosition()
    MoveToPixel(SAFE_X, SAFE_Y)
end

-- 处理一件装备
function ProcessOneItem(slotIndex)
    local bagX, bagY = GetBagSlotPosition(slotIndex)
    local slotNumber = slotIndex + 1

    OutputLogMessage(
        "开始处理第%d格，坐标=%d,%d。\n",
        slotNumber,
        bagX,
        bagY
    )

    -- 1. 点击“添加词缀”
    if not ClickAt(
        ADD_AFFIX_X,
        ADD_AFFIX_Y,
        1,
        RECIPE_DELAY
    ) then
        return false
    end

    -- 2. 右键背包装备
    if not ClickAt(
        bagX,
        bagY,
        3,
        BAG_CLICK_DELAY
    ) then
        return false
    end

    -- 3. 第1次点击“重塑”
    if not ClickAt(
        REFORGE_X,
        REFORGE_Y,
        1,
        REFORGE_DELAY
    ) then
        return false
    end

    -- 4. 第1次点击“接受”
    if not ClickAt(
        ACCEPT_X,
        ACCEPT_Y,
        1,
        ACCEPT_DELAY
    ) then
        return false
    end

    -- 5. 第2次点击“重塑”
    -- 第二次不点击“接受”
    if not ClickAt(
        REFORGE_X,
        REFORGE_Y,
        1,
        REFORGE_DELAY
    ) then
        return false
    end

    -- 6. 右键取回装备
    if not ClickAt(
        CUBE_ITEM_X,
        CUBE_ITEM_Y,
        3,
        RETURN_DELAY
    ) then
        return false
    end
    -- 7. 右键取回装备
    if not ClickAt(
        CUBE_ITEM_X,
        CUBE_ITEM_Y,
        3,
        RETURN_DELAY
    ) then
        return false
    end
    MoveToSafePosition()

    OutputLogMessage(
        "第%d格处理完成，等待2秒。\n",
        slotNumber
    )

    return SleepChecked(BETWEEN_ITEMS_DELAY)
end

-- 处理全部格子
function RunAllSlots()
    local totalSlots = ROWS * COLS

    OutputLogMessage(
        "开始添加词缀，共处理%d格。\n",
        totalSlots
    )

    for slotIndex = 0, totalSlots - 1 do
        if StopRequested() then
            MoveToSafePosition()
            OutputLogMessage("检测到停止键。\n")
            return false
        end

        if not ProcessOneItem(slotIndex) then
            MoveToSafePosition()

            OutputLogMessage(
                "脚本在第%d格停止。\n",
                slotIndex + 1
            )

            return false
        end
    end

    MoveToSafePosition()

    OutputLogMessage(
        "全部完成，共处理%d格。\n",
        totalSlots
    )

    return true
end

function StartAddAffix()
    if running then
        OutputLogMessage("脚本正在运行。\n")
        return
    end

    running = true

    OutputLogMessage("脚本将在2秒后启动。\n")

    if not SleepChecked(START_DELAY) then
        running = false
        MoveToSafePosition()
        OutputLogMessage("启动已取消。\n")
        return
    end

    RunAllSlots()

    running = false
    MoveToSafePosition()
end

function OnEvent(event, arg)
    OutputLogMessage(
        "事件=%s，按键编号=%s\n",
        tostring(event),
        tostring(arg)
    )

    if event == "PROFILE_ACTIVATED" then
        EnablePrimaryMouseButtonEvents(true)
        OutputLogMessage("添加词缀脚本已加载。\n")
    end

    if event == "MOUSE_BUTTON_PRESSED"
        and arg == START_BUTTON
        and not running then

        StartAddAffix()
    end
end