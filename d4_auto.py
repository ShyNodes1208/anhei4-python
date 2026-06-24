# -*- coding: utf-8 -*-
"""
暗黑4 魔盒一键全流程（Python + 图像识别版）

流程（方案B，逐阶段）：
  阶段1 添加词缀 -> 阶段2 升级至传奇 -> 阶段3 嬗变物品

相比 G HUB 版的优势：
  - 右键装备后会“看”有没有红字“不适用”，不适用就跳过这件，绝不会误点“重置暗金威能”
  - 点“重塑”后会“等”到“接受”按钮真出现才点，点的是识别到的真实位置
  - 跳过/失败的装备不会污染后续装备

操作：
  运行脚本后，切到游戏并打开魔盒+背包，按 F8 开始；运行中按 F10 停止。

可选参数：
  python d4_auto.py --calibrate   # 鼠标依次移动到各坐标，肉眼校准
  python d4_auto.py --shot        # 立即保存一张全屏截图，便于裁模板
"""

import sys
import time
import threading

import keyboard

import d4_config as cfg
import d4_input as ic
import d4_vision as vision


# 状态码
OK = "OK"            # 正常完成
SKIPPED = "SKIPPED"  # 该件不适用，已跳过
STOPPED = "STOPPED"  # 用户停止

_worker = None       # 工作线程


def log(msg):
    print(time.strftime("[%H:%M:%S] ") + msg, flush=True)


def bag_slot_xy(index):
    row = index // cfg.COLS
    col = index % cfg.COLS
    x = cfg.BAG_START_X + col * cfg.BAG_STEP_X
    y = cfg.BAG_START_Y + row * cfg.BAG_STEP_Y
    if col == cfg.COLS - 1:
        y -= 1
    return x, y


def clear_cube():
    """点“清除”按钮清空魔盒/取回装备（比右键取回安全；盒子为空也无害）。"""
    return ic.left_click(cfg.CLEAR_XY)


def find_and_click(template, fallback_xy, region=None, threshold=None, after_delay=None):
    """
    动态点击：先在 region 内找模板，找到就点它的实时位置；
    找不到则退回固定坐标 fallback_xy 兜底。
    """
    hit = vision.find(template, region=region, threshold=threshold)
    if hit is not None:
        log("  找到 %s @(%d,%d) 置信%.2f" % (template, hit[0], hit[1], hit[2]))
        return ic.click_at(hit[0], hit[1], button="left", after_delay=after_delay)
    log("  未找到 %s，退回固定坐标 %s" % (template, str(fallback_xy)))
    return ic.left_click(fallback_xy, after_delay=after_delay)


def click_recipe(template, fallback_xy):
    return find_and_click(
        template, fallback_xy,
        region=cfg.REGION_RECIPE,
        threshold=cfg.RECIPE_THRESHOLD,
    )


def handle_accept(timeout=None):
    """
    点“重塑”后调用：等待“接受”弹窗出现。
    出现就点它的真实位置，返回 True；超时未出现返回 False（视为无需接受）。
    """
    if timeout is None:
        timeout = cfg.ACCEPT_WAIT_TIMEOUT
    hit = vision.wait_for(
        cfg.TPL_ACCEPT,
        timeout=timeout,
        region=cfg.REGION_ACCEPT,
        stop_check=ic.stop_requested,
    )
    if ic.stop_requested():
        return False
    if hit is None:
        return False
    ic.click_at(hit[0], hit[1], button="left")
    return True


# ==================== 阶段1：添加词缀 ====================
def add_affix_one(index):
    bx, by = bag_slot_xy(index)
    n = index + 1
    log("【加词缀】第%d格 (%d,%d)" % (n, bx, by))

    # 1. 选配方“添加词缀”（动态找图，找不到退回固定坐标）
    if not click_recipe(cfg.TPL_RECIPE_ADD_AFFIX, cfg.ADD_AFFIX_XY):
        return STOPPED
    # 2. 右键装备放入魔盒
    if not ic.click_at(bx, by, button="right"):
        return STOPPED
    if not ic.sleep_checked(cfg.DETECT_AFTER_PLACE):
        return STOPPED

    # 3. 判断是否“不适用”
    if vision.exists(cfg.TPL_NOT_APPLICABLE, region=cfg.REGION_NOT_APPLICABLE):
        log("  -> 不适用，跳过该件")
        clear_cube()  # 保险：点清除，若有残留则取回
        ic.move_safe()
        return SKIPPED

    # 4. 连点“重塑”补满；第一次必有绑定弹窗，用长超时；之后用短超时兜底
    for i in range(cfg.AFFIX_REFORGE_COUNT):
        if not ic.left_click(cfg.REFORGE_XY):
            return STOPPED
        handle_accept(timeout=(cfg.ACCEPT_WAIT_TIMEOUT if i == 0 else 0.6))
        if ic.stop_requested():
            return STOPPED

    # 5. 清除（取回装备）
    if not clear_cube():
        return STOPPED

    ic.move_safe()
    if not ic.sleep_checked(cfg.BETWEEN_ITEMS_DELAY):
        return STOPPED
    return OK


# ==================== 阶段2/3：升传奇 / 嬗变（先放装备，再点配方）====================
def recipe_one(index, recipe_tpl, recipe_xy, label):
    bx, by = bag_slot_xy(index)
    n = index + 1
    log("【%s】第%d格 (%d,%d)" % (label, n, bx, by))

    # 1. 右键装备放入魔盒
    if not ic.click_at(bx, by, button="right"):
        return STOPPED
    if not ic.sleep_checked(cfg.DETECT_AFTER_PLACE):
        return STOPPED

    # 2. 点配方（动态找图，找不到退回固定坐标）
    if not click_recipe(recipe_tpl, recipe_xy):
        return STOPPED
    if not ic.sleep_checked(cfg.DETECT_AFTER_PLACE):
        return STOPPED

    # 3. 判断是否“不适用”：是则清除取回并跳过
    if vision.exists(cfg.TPL_NOT_APPLICABLE, region=cfg.REGION_NOT_APPLICABLE):
        log("  -> 不适用，清除取回并跳过该件")
        clear_cube()
        ic.move_safe()
        return SKIPPED

    # 4. 重塑 + 接受
    if not ic.left_click(cfg.REFORGE_XY):
        return STOPPED
    handle_accept()

    # 5. 清除（取回装备）
    if not clear_cube():
        return STOPPED

    ic.move_safe()
    if not ic.sleep_checked(cfg.BETWEEN_ITEMS_DELAY):
        return STOPPED
    return OK


def upgrade_one(index):
    return recipe_one(index, cfg.TPL_RECIPE_UPGRADE, cfg.UPGRADE_XY, "升传奇")


def transmute_one(index):
    return recipe_one(index, cfg.TPL_RECIPE_TRANSMUTE, cfg.TRANSMUTE_XY, "嬗变")


# ==================== 阶段调度 ====================
def run_phase(label, process_fn):
    total = cfg.ROWS * cfg.COLS
    log("==== 阶段开始：%s，共%d格 ====" % (label, total))
    done = 0
    skipped = 0
    for index in range(total):
        if ic.stop_requested():
            ic.move_safe()
            log("检测到停止键，%s阶段中断。" % label)
            return STOPPED
        code = process_fn(index)
        if code == STOPPED:
            ic.move_safe()
            log("%s阶段在第%d格停止。" % (label, index + 1))
            return STOPPED
        elif code == SKIPPED:
            skipped += 1
        else:
            done += 1
    ic.move_safe()
    log("==== 阶段完成：%s（成功%d，跳过%d）====" % (label, done, skipped))
    return OK


def run_all():
    log("将在 %.0f 秒后开始……" % cfg.START_DELAY)
    if not ic.sleep_checked(cfg.START_DELAY):
        ic.move_safe()
        log("启动已取消。")
        return

    if cfg.DO_ADD_AFFIX:
        if run_phase("添加词缀", add_affix_one) == STOPPED:
            ic.move_safe(); return
        if not ic.sleep_checked(cfg.BETWEEN_PHASES_DELAY):
            ic.move_safe(); return

    if cfg.DO_UPGRADE:
        if run_phase("升级至传奇", upgrade_one) == STOPPED:
            ic.move_safe(); return
        if not ic.sleep_checked(cfg.BETWEEN_PHASES_DELAY):
            ic.move_safe(); return

    if cfg.DO_TRANSMUTE:
        if run_phase("嬗变物品", transmute_one) == STOPPED:
            ic.move_safe(); return

    ic.move_safe()
    log("全部阶段执行完成。")


# ==================== 辅助：校准 / 截图 ====================
def calibrate():
    points = [
        ("背包第1格", bag_slot_xy(0)),
        ("背包最后一格", bag_slot_xy(cfg.ROWS * cfg.COLS - 1)),
        ("添加词缀", cfg.ADD_AFFIX_XY),
        ("升级至传奇", cfg.UPGRADE_XY),
        ("嬗变物品", cfg.TRANSMUTE_XY),
        ("重塑", cfg.REFORGE_XY),
        ("接受", cfg.ACCEPT_XY),
        ("清除", cfg.CLEAR_XY),
        ("安全位置", cfg.SAFE_XY),
    ]
    log("校准模式：3秒后鼠标依次移动到各点，请切到游戏观察。")
    time.sleep(3)
    for name, (x, y) in points:
        log("移动到 %s (%d,%d)" % (name, x, y))
        ic.move_to(x, y)
        time.sleep(1.2)
    log("校准结束。")


def shot():
    import cv2
    img, _ = vision.grab()
    fn = time.strftime("shot_%Y%m%d_%H%M%S.png")
    cv2.imwrite(fn, img)
    log("已保存截图：%s" % fn)


def main():
    if "--calibrate" in sys.argv:
        calibrate(); return
    if "--shot" in sys.argv:
        shot(); return

    print("=" * 50)
    print(" 暗黑4 魔盒一键全流程（Python 图像识别版）")
    print(" 处理范围：%d 行 x %d 列" % (cfg.ROWS, cfg.COLS))
    print(" 阶段：加词缀=%s 升传奇=%s 嬗变=%s"
          % (cfg.DO_ADD_AFFIX, cfg.DO_UPGRADE, cfg.DO_TRANSMUTE))
    print(" 开始键: %s    停止键: %s" % (cfg.START_KEY.upper(), cfg.STOP_KEY.upper()))
    print("=" * 50)
    print("切到游戏，打开魔盒+背包，按 %s 开始……" % cfg.START_KEY.upper())

    keyboard.add_hotkey(cfg.START_KEY, start_worker)
    keyboard.wait("esc")  # 在控制台按 ESC 退出程序（不是游戏里的ESC）
    log("程序退出。")


def start_worker():
    """F8 回调：只负责启动独立工作线程，保证 keyboard 线程空闲以响应 F10。"""
    global _worker
    if _worker is not None and _worker.is_alive():
        log("已在运行中，忽略本次启动。")
        return
    _worker = threading.Thread(target=run_all, daemon=True)
    _worker.start()


if __name__ == "__main__":
    main()
