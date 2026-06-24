--========================================================
-- 暗黑破坏神4：G502 魔盒一键全流程（方案B：逐阶段）
-- 分辨率：2560 × 1440
--
-- 流程（每个阶段处理完整个背包，再进入下一阶段）：
--   阶段1 添加词缀（补满到 AFFIX_REFORGE_COUNT 条）
--   阶段2 升级至传奇
--   阶段3 嬗变物品
--
-- 启动键：G502 第5键按一下
-- 停止键：运行中持续按住 G502 第4键
--========================================================

--==================== 基础配置 ====================

local SCREEN_W = 2560
local SCREEN_H = 1440

local START_BUTTON = 5
local STOP_BUTTON  = 4

--==================== 背包处理范围（每次按实际背包修改）====================
-- 处理 ROWS 行 × COLS 列，从左到右、从上到下
local ROWS = 3
local COLS = 11

--==================== 阶段开关（调试时可单独关闭）====================
local DO_ADD_AFFIX = true   -- 阶段1：添加词缀
local DO_UPGRADE   = true   -- 阶段2：升级至传奇
local DO_TRANSMUTE = true   -- 阶段3：嬗变物品

--==================== 添加词缀次数 ====================
-- 第一次“重塑”后会点一次“接受”，之后连点“重塑”补满。
-- 总共点击“重塑” AFFIX_REFORGE_COUNT 次，加满到4条后多余的点击无效、不影响后续。
local AFFIX_REFORGE_COUNT = 4

--==================== 背包坐标 ====================

-- 第一行第一格中心
local BAG_START_X = 1722
local BAG_START_Y = 1017

-- 相邻格子中心间距
local BAG_STEP_X = 73
local BAG_STEP_Y = 102

--==================== 魔盒配方坐标 ====================
-- 注意：这些坐标分别沿用各自单独脚本中已验证可用的位置，
-- 因为放入装备后配方列表会重排，三个配方点法不同，不要随意统一。

-- 添加词缀：空盒时位于配方列表顶部（先点配方，再放装备）
local ADD_AFFIX_X = 1138
local ADD_AFFIX_Y = 330

-- 升级至传奇：放入装备后的位置（先放装备，再点配方）
local UPGRADE_X = 1138
local UPGRADE_Y = 1025

-- 嬗变物品：放入装备后的位置（先放装备，再点配方）
local TRANSMUTE_X = 1140
local TRANSMUTE_Y = 510

-- 左侧下方“重塑”按钮
local REFORGE_X = 468
local REFORGE_Y = 1140

-- 弹窗中的“接受”按钮
local ACCEPT_X = 1149
local ACCEPT_Y = 813

-- 魔盒左上角装备格（用于右键取回）
local CUBE_ITEM_X = 322
local CUBE_ITEM_Y = 480

-- 鼠标安全停留位置
local SAFE_X = 2103
local SAFE_Y = 929

--==================== 时间配置 ====================

-- 按下启动键后等待
local START_DELAY = 2000
-- 鼠标移动到目标后等待
local MOVE_DELAY = 200
-- 每一步点击完成后统一等待
local STEP_DELAY = 1000
-- 处理完一件装备后等待
local BETWEEN_ITEMS_DELAY = 1000
-- 切换阶段之间等待
local BETWEEN_PHASES_DELAY = 1000

--==================== 运行状态 ====================

local running = false

--========================================================
-- 像素坐标转换为 G HUB 绝对坐标
--========================================================

function MoveToPixel(x, y)
    local ghubX = math.floor(x * 65535 / (SCREEN_W - 1))
    local ghubY = math.floor(y * 65535 / (SCREEN_H - 1))
    MoveMouseTo(ghubX, ghubY)
end

--========================================================
-- 根据格子序号计算背包坐标
-- index：0 ~ (ROWS*COLS - 1)，从左到右、从上到下
--========================================================

function GetBagSlotPosition(index)
    local row = math.floor(index / COLS)
    local col = index % COLS

    local x = BAG_START_X + col * BAG_STEP_X
    local y = BAG_START_Y + row * BAG_STEP_Y

    -- 沿用原脚本：最后一列向上微调1像素
    if col == COLS - 1 then
        y = y - 1
    end

    return x, y
end

--========================================================
-- 停止键检测
--========================================================

function StopRequested()
    return IsMouseButtonPressed(STOP_BUTTON)
end

--========================================================
-- 可中断等待（每25毫秒检测一次停止键）
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
-- mouseButton：1=左键，2=中键，3=右键
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
-- 阶段1：添加词缀（单件）
-- 顺序：选配方(空盒顶部) → 右键放入装备 → 重塑+接受 → 连点重塑补满 → 取回1次
--========================================================

function AddAffixOne(slotIndex)
    local bagX, bagY = GetBagSlotPosition(slotIndex)
    local n = slotIndex + 1

    OutputLogMessage("【加词缀】第%d格 坐标=%d,%d\n", n, bagX, bagY)

    -- 1. 选配方“添加词缀”
    if not ClickAt(ADD_AFFIX_X, ADD_AFFIX_Y, 1, STEP_DELAY) then return false end
    -- 2. 右键背包装备放入魔盒
    if not ClickAt(bagX, bagY, 3, STEP_DELAY) then return false end
    -- 3. 第一次“重塑” + “接受”
    if not ClickAt(REFORGE_X, REFORGE_Y, 1, STEP_DELAY) then return false end
    if not ClickAt(ACCEPT_X, ACCEPT_Y, 1, STEP_DELAY) then return false end
    -- 4. 继续“重塑”补满（不再接受；加满后多点无效）
    for i = 2, AFFIX_REFORGE_COUNT do
        if not ClickAt(REFORGE_X, REFORGE_Y, 1, STEP_DELAY) then return false end
    end
    -- 5. 右键取回（仅一次）
    if not ClickAt(CUBE_ITEM_X, CUBE_ITEM_Y, 3, STEP_DELAY) then return false end

    MoveToSafePosition()
    OutputLogMessage("【加词缀】第%d格完成。\n", n)
    return SleepChecked(BETWEEN_ITEMS_DELAY)
end

--========================================================
-- 阶段2：升级至传奇（单件）
-- 顺序：右键放入装备 → 选配方 → 重塑 → 接受 → 取回
--========================================================

function UpgradeOne(slotIndex)
    local bagX, bagY = GetBagSlotPosition(slotIndex)
    local n = slotIndex + 1

    OutputLogMessage("【升传奇】第%d格 坐标=%d,%d\n", n, bagX, bagY)

    if not ClickAt(bagX, bagY, 3, STEP_DELAY) then return false end
    if not ClickAt(UPGRADE_X, UPGRADE_Y, 1, STEP_DELAY) then return false end
    if not ClickAt(REFORGE_X, REFORGE_Y, 1, STEP_DELAY) then return false end
    if not ClickAt(ACCEPT_X, ACCEPT_Y, 1, STEP_DELAY) then return false end
    if not ClickAt(CUBE_ITEM_X, CUBE_ITEM_Y, 3, STEP_DELAY) then return false end

    MoveToSafePosition()
    OutputLogMessage("【升传奇】第%d格完成。\n", n)
    return SleepChecked(BETWEEN_ITEMS_DELAY)
end

--========================================================
-- 阶段3：嬗变物品（单件）
-- 顺序：右键放入装备 → 选配方 → 重塑 → 接受 → 取回
--========================================================

function TransmuteOne(slotIndex)
    local bagX, bagY = GetBagSlotPosition(slotIndex)
    local n = slotIndex + 1

    OutputLogMessage("【嬗变】第%d格 坐标=%d,%d\n", n, bagX, bagY)

    if not ClickAt(bagX, bagY, 3, STEP_DELAY) then return false end
    if not ClickAt(TRANSMUTE_X, TRANSMUTE_Y, 1, STEP_DELAY) then return false end
    if not ClickAt(REFORGE_X, REFORGE_Y, 1, STEP_DELAY) then return false end
    if not ClickAt(ACCEPT_X, ACCEPT_Y, 1, STEP_DELAY) then return false end
    if not ClickAt(CUBE_ITEM_X, CUBE_ITEM_Y, 3, STEP_DELAY) then return false end

    MoveToSafePosition()
    OutputLogMessage("【嬗变】第%d格完成。\n", n)
    return SleepChecked(BETWEEN_ITEMS_DELAY)
end

--========================================================
-- 执行一个阶段：对全部格子依次调用 processFn
--========================================================

function RunPhase(label, processFn)
    local totalSlots = ROWS * COLS

    OutputLogMessage("==== 阶段开始：%s，共%d格 ====\n", label, totalSlots)

    for slotIndex = 0, totalSlots - 1 do
        if StopRequested() then
            MoveToSafePosition()
            OutputLogMessage("检测到停止键，%s阶段中断。\n", label)
            return false
        end

        if not processFn(slotIndex) then
            MoveToSafePosition()
            OutputLogMessage("%s阶段在第%d格停止。\n", label, slotIndex + 1)
            return false
        end
    end

    MoveToSafePosition()
    OutputLogMessage("==== 阶段完成：%s ====\n", label)
    return true
end

--========================================================
-- 启动：依次执行三个阶段（方案B）
--========================================================

function StartAll()
    if running then
        OutputLogMessage("脚本正在运行，忽略重复启动。\n")
        return
    end

    running = true
    OutputLogMessage("脚本将在2秒后开始执行。\n")

    if not SleepChecked(START_DELAY) then
        running = false
        MoveToSafePosition()
        OutputLogMessage("启动已取消。\n")
        return
    end

    if DO_ADD_AFFIX then
        if not RunPhase("添加词缀", AddAffixOne) then
            running = false
            MoveToSafePosition()
            return
        end
        if not SleepChecked(BETWEEN_PHASES_DELAY) then
            running = false
            MoveToSafePosition()
            return
        end
    end

    if DO_UPGRADE then
        if not RunPhase("升级至传奇", UpgradeOne) then
            running = false
            MoveToSafePosition()
            return
        end
        if not SleepChecked(BETWEEN_PHASES_DELAY) then
            running = false
            MoveToSafePosition()
            return
        end
    end

    if DO_TRANSMUTE then
        if not RunPhase("嬗变物品", TransmuteOne) then
            running = false
            MoveToSafePosition()
            return
        end
    end

    running = false
    MoveToSafePosition()
    OutputLogMessage("全部阶段执行完成。\n")
end

--========================================================
-- G HUB 事件入口
--========================================================

function OnEvent(event, arg)
    OutputLogMessage("事件=%s，按键编号=%s\n", tostring(event), tostring(arg))

    if event == "PROFILE_ACTIVATED" then
        EnablePrimaryMouseButtonEvents(true)
        OutputLogMessage("魔盒一键全流程脚本已加载。\n")
    end

    if event == "MOUSE_BUTTON_PRESSED"
        and arg == START_BUTTON
        and not running then

        StartAll()
    end
end
