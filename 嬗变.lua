--========================================================
-- 暗黑破坏神4：G502 背包33格自动嬗变
-- 分辨率：2560 × 1440
--
-- 执行顺序：
-- 右键装备 → 嬗变物品 → 重塑 → 接受
-- → 右键取回 → 等待2秒 → 下一件
--========================================================

--==================== 基础配置 ====================

local SCREEN_W = 2560
local SCREEN_H = 1440

-- G502按键编号
local START_BUTTON = 5       -- 按一下启动
local STOP_BUTTON  = 4       -- 运行期间持续按住停止

-- 背包规格：3行×11列
local ROWS = 3
local COLS = 11

--==================== 背包坐标 ====================

-- 第一行第一格中心
local BAG_START_X = 1722
local BAG_START_Y = 1017

-- 横向、纵向格子中心间距
local BAG_STEP_X = 73
local BAG_STEP_Y = 102

--==================== 魔盒操作坐标 ====================

-- 中间配方列表中的“嬗变物品”
--local TRANSMUTE_X = 1130
--local TRANSMUTE_Y = 600

-- 中间配方列表第三项“嬗变物品”
local TRANSMUTE_X = 1140
local TRANSMUTE_Y = 510

-- 左侧下方“重塑”按钮
local REFORGE_X = 468
local REFORGE_Y = 1140

-- 弹窗中的“接受”按钮
local ACCEPT_X = 1149
local ACCEPT_Y = 813

-- 魔盒左上角装备格中心
local CUBE_ITEM_X = 322
local CUBE_ITEM_Y = 480

-- 鼠标安全停留位置
local SAFE_X = 2103
local SAFE_Y = 929

--==================== 时间配置 ====================

-- 按下启动键后等待2秒
local START_DELAY = 2000

-- 鼠标到达点击位置后等待
local MOVE_DELAY = 200

-- 每一步点击完成后等待1秒
local BAG_CLICK_DELAY = 1000
local TRANSMUTE_DELAY = 1000
local REFORGE_DELAY = 1000
local ACCEPT_DELAY = 1000
local RETURN_DELAY = 1000

-- 一件装备完成后等待2秒
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
-- 获取背包格子中心坐标
--
-- row：0～2
-- col：0～10
--========================================================

function GetBagSlotPosition(row, col)
    local x = BAG_START_X + col * BAG_STEP_X
    local y = BAG_START_Y + row * BAG_STEP_Y

    -- 原始脚本第11列向上微调1像素
    if col == COLS - 1 then
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
--
-- 等待过程中每25毫秒检测一次停止键
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

--========================================================
-- 移动到安全位置
--========================================================

function MoveToSafePosition()
    MoveToPixel(SAFE_X, SAFE_Y)
end

--========================================================
-- 执行单件装备完整嬗变流程
--========================================================

function TransmuteOneItem(bagX, bagY, slotNumber)
    OutputLogMessage(
        "开始处理第%d格，坐标=%d,%d\n",
        slotNumber,
        bagX,
        bagY
    )

    -- 1. 右键背包装备，将其放入魔盒
    if not ClickAt(
        bagX,
        bagY,
        3,
        BAG_CLICK_DELAY
    ) then
        return false
    end

    -- 2. 左键选择“嬗变物品”
    if not ClickAt(
        TRANSMUTE_X,
        TRANSMUTE_Y,
        1,
        TRANSMUTE_DELAY
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

    -- 5. 右键魔盒装备，将其放回背包
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

--========================================================
-- 依次处理背包全部33格
--
-- 顺序：
-- 第一行从左到右
-- 第二行从左到右
-- 第三行从左到右
--========================================================

function RunAllSlots()
    OutputLogMessage(
        "开始自动嬗变，共处理%d格。\n",
        ROWS * COLS
    )

    for row = 0, ROWS - 1 do
        for col = 0, COLS - 1 do
            if StopRequested() then
                MoveToSafePosition()
                OutputLogMessage("检测到停止键。\n")
                return false
            end

            local bagX, bagY =
                GetBagSlotPosition(row, col)

            local slotNumber =
                row * COLS + col + 1

            local success = TransmuteOneItem(
                bagX,
                bagY,
                slotNumber
            )

            if not success then
                MoveToSafePosition()

                OutputLogMessage(
                    "脚本在第%d格停止。\n",
                    slotNumber
                )

                return false
            end
        end
    end

    MoveToSafePosition()

    OutputLogMessage(
        "背包33格全部嬗变完成。\n"
    )

    return true
end

--========================================================
-- 启动自动嬗变
--========================================================

function StartTransmute()
    if running then
        OutputLogMessage(
            "脚本正在运行，忽略重复启动。\n"
        )
        return
    end

    running = true

    OutputLogMessage(
        "脚本将在2秒后开始执行。\n"
    )

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
        "事件：%s，按键编号：%s\n",
        tostring(event),
        tostring(arg)
    )

    if event == "PROFILE_ACTIVATED" then
        EnablePrimaryMouseButtonEvents(true)

        OutputLogMessage(
            "暗黑4自动嬗变脚本已加载。\n"
        )
    end

    if event == "MOUSE_BUTTON_PRESSED"
        and arg == START_BUTTON
        and not running then

        StartTransmute()
    end
end