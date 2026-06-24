# -*- coding: utf-8 -*-
"""
输入模块：鼠标移动/点击 + 可中断等待 + 停止键检测。
鼠标用 pydirectinput（驱动级，适合游戏）。
"""

import time
import ctypes

import pydirectinput
import keyboard

import d4_config as cfg


# 让 Windows 不对本进程做 DPI 缩放，保证坐标 == 实际像素
try:
    ctypes.windll.user32.SetProcessDPIAware()
except Exception:
    pass

pydirectinput.PAUSE = 0.0
pydirectinput.FAILSAFE = False


def stop_requested():
    """按下停止键即返回 True。"""
    try:
        return keyboard.is_pressed(cfg.STOP_KEY)
    except Exception:
        return False


def sleep_checked(seconds):
    """可中断等待：等待期间检测停止键。被中断返回 False。"""
    end = time.time() + seconds
    while time.time() < end:
        if stop_requested():
            return False
        time.sleep(0.02)
    return True


def move_to(x, y):
    pydirectinput.moveTo(int(x), int(y))


def move_safe():
    move_to(*cfg.SAFE_XY)


def click_at(x, y, button="left", after_delay=None):
    """
    移动到 (x, y) 并点击。button: 'left' / 'right'。
    返回 False 表示被停止键中断。
    """
    if after_delay is None:
        after_delay = cfg.STEP_DELAY

    if stop_requested():
        return False

    move_to(x, y)
    if not sleep_checked(cfg.MOVE_DELAY):
        return False

    # 用 mouseDown/mouseUp（驱动级），对游戏兼容性比 click(button=...) 更好
    pydirectinput.mouseDown(button=button)
    time.sleep(0.03)
    pydirectinput.mouseUp(button=button)

    return sleep_checked(after_delay)


def left_click(xy, after_delay=None):
    return click_at(xy[0], xy[1], button="left", after_delay=after_delay)


def right_click(xy, after_delay=None):
    return click_at(xy[0], xy[1], button="right", after_delay=after_delay)
