--========================================================
-- 暗黑破坏神4：G502 升级至传奇
-- 分辨率：2560×1440
--
-- 每件装备流程：
-- 右键背包装备
-- → 点击“升级至传奇”
-- → 点击“重塑”
-- → 点击“接受”
-- → 右键取回
-- → 等待2秒
-- → 下一格
--========================================================

local SCREEN_W = 2560
local SCREEN_H = 1440

-- G502按键编号
local START_BUTTON = 5
local STOP_BUTTON  = 4

--==================== 操作范围 ====================

-- 按从左到右、从上到下处理
local ROWS = 3
local COLS = 11

--==================== 背包坐标 ====================

-- 第一行第一格中心
local BAG_START_X = 1722
local BAG_START_Y = 1017

-- 格子中心间距
local BAG_STEP_X = 73
local BAG_STEP_Y = 102

--==================== 魔盒操作坐标 ====================

-- “升级至传奇”
-- 根据2048×1152截图换算到2560×1440
local UPGRADE_LEGENDARY_X = 1138
local UPGRADE_LEGENDARY_Y = 1025

-- 左侧下方“重塑”
local REFORGE_X = 468
local REFORGE_Y = 1140

-- 弹窗“接受”
local ACCEPT_X = 1149
local ACCEPT_Y = 813

-- 魔盒左上角装备格，用于取回装备
local CUBE_ITEM_X = 322
local CUBE_ITEM_Y = 480

-- 鼠标安全停留位置
local SAFE_X = 2103
local SAFE_Y = 929

--==================== 时间配置 ====================

-- 按启动键后等待2秒
local START_DELAY = 2000

-- 鼠标移动到目标位置后等待
local MOVE_DELAY = 200

-- 每一步点击完成后等待1秒
local BAG_CLICK_DELAY = 1000
local RECIPE_DELAY = 1000
local REFORGE_DELAY = 1000
local ACCEPT_DELAY = 1000
local RETURN_DELAY = 1000

-- 每件装备完成后等待2秒
local BETWEEN_ITEMS_DELAY = 2000

--==================== 运行状态 ====================

local running = false

--========================================================
-- 像素坐标转换为G HUB绝对坐标
--========================================================

function MoveToPixel(x, y)
    local ghubX = math.floor(
        x * 65535 / (SCREEN_W - 1)
    )

    local ghubY = math.floor(
        y * 65535 / (SCREEN_H - 1)
    )

    MoveMouseTo(ghubX, ghubY)
end

--========================================================
-- 获取背包格子坐标
--
-- 顺序：
-- 第1行从左到右
-- 第2行从左到右
-- 第3行从左到右
--========================================================

function GetBagSlotPosition(index)
    local row = math.floor(index / COLS)
    local col = index % COLS

    local x = BAG_START_X + col * BAG_STEP_X
    local y = BAG_START_Y + row * BAG_STEP_Y

    -- 第11列沿用原脚本向上微调1像素
    if col == COLS - 1 and COLS == 11 then
        y = y - 1
    end

    return x, y
end

--========================================================
-- 检查停止键
--========================================================

function StopRequested()
    return IsMouseButtonPressed(STOP_BUTTON)
end

--========================================================
-- 可中断等待
--========================================================

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

--========================================================
-- 移动鼠标并点击
--
-- mouseButton：
-- 1 = 左键
-- 2 = 中键
-- 3 = 右键
--========================================================

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

--========================================================
-- 处理一件装备
--========================================================

function ProcessOneItem(slotIndex)
    local bagX, bagY = GetBagSlotPosition(slotIndex)
    local slotNumber = slotIndex + 1

    OutputLogMessage(
        "开始处理第%d格，坐标=%d,%d。\n",
        slotNumber,
        bagX,
        bagY
    )

    -- 1. 右键背包装备，将装备放入魔盒
    if not ClickAt(
        bagX,
        bagY,
        3,
        BAG_CLICK_DELAY
    ) then
        return false
    end

    -- 2. 左键点击“升级至传奇”
    if not ClickAt(
        UPGRADE_LEGENDARY_X,
        UPGRADE_LEGENDARY_Y,
        1,
        RECIPE_DELAY
    ) then
        return false
    end

    -- 3. 左键点击“重塑”
    if not ClickAt(
        REFORGE_X,
        REFORGE_Y,
        1,
        REFORGE_DELAY
    ) then
        return false
    end

    -- 4. 左键点击“接受”
    if not ClickAt(
        ACCEPT_X,
        ACCEPT_Y,
        1,
        ACCEPT_DELAY
    ) then
        return false
    end

    -- 5. 右键取回魔盒中的装备
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
        "第%d格升级完成，等待2秒。\n",
        slotNumber
    )

    return SleepChecked(BETWEEN_ITEMS_DELAY)
end

--========================================================
-- 处理全部指定格子
--========================================================

function RunAllSlots()
    local totalSlots = ROWS * COLS

    OutputLogMessage(
        "开始升级至传奇，共处理%d格。\n",
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
        "升级至传奇完成，共处理%d格。\n",
        totalSlots
    )

    return true
end

--========================================================
-- 启动脚本
--========================================================

function StartUpgradeLegendary()
    if running then
        OutputLogMessage("脚本正在运行。\n")
        return
    end

    running = true

    OutputLogMessage("脚本将在2秒后开始。\n")

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

--========================================================
-- G HUB事件入口
--========================================================

function OnEvent(event, arg)
    OutputLogMessage(
        "事件=%s，按键编号=%s\n",
        tostring(event),
        tostring(arg)
    )

    if event == "PROFILE_ACTIVATED" then
        EnablePrimaryMouseButtonEvents(true)

        OutputLogMessage(
            "升级至传奇脚本已加载。\n"
        )
    end

    if event == "MOUSE_BUTTON_PRESSED"
        and arg == START_BUTTON
        and not running then

        StartUpgradeLegendary()
    end
end