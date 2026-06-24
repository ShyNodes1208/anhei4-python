# -*- coding: utf-8 -*-
"""
视觉模块：截屏 + 模板匹配。
提供 find / exists / wait_for，让主流程能根据“游戏真实画面”做判断。
"""

import os
import time
import threading

import cv2
import numpy as np
import mss

import d4_config as cfg


# mss 不是线程安全的：每个线程用各自的实例
_thread_local = threading.local()
_template_cache = {}


def _get_sct():
    sct = getattr(_thread_local, "sct", None)
    if sct is None:
        sct = mss.mss()
        _thread_local.sct = sct
    return sct


def grab(region=None):
    """
    截屏并返回 BGR ndarray。
    region: (left, top, width, height)，None 表示全屏。
    """
    if region is None:
        monitor = {"left": 0, "top": 0, "width": cfg.SCREEN_W, "height": cfg.SCREEN_H}
        offset = (0, 0)
    else:
        left, top, width, height = region
        monitor = {"left": left, "top": top, "width": width, "height": height}
        offset = (left, top)

    raw = _get_sct().grab(monitor)
    img = np.array(raw)  # BGRA
    img = cv2.cvtColor(img, cv2.COLOR_BGRA2BGR)
    return img, offset


def _load_template(name):
    if name in _template_cache:
        return _template_cache[name]
    path = os.path.join(cfg.TEMPLATE_DIR, name)
    if not os.path.exists(path):
        raise FileNotFoundError(
            "缺少模板图: %s\n请先用 d4_capture.py 裁出该模板。" % path
        )
    tpl = cv2.imread(path, cv2.IMREAD_COLOR)
    if tpl is None:
        raise ValueError("无法读取模板图: %s" % path)
    _template_cache[name] = tpl
    return tpl


def find(template_name, region=None, threshold=None):
    """
    在指定区域查找模板。
    返回命中中心的屏幕坐标 (x, y, score)，未命中返回 None。
    """
    if threshold is None:
        threshold = cfg.MATCH_THRESHOLD

    tpl = _load_template(template_name)
    img, (ox, oy) = grab(region)

    th, tw = tpl.shape[:2]
    if img.shape[0] < th or img.shape[1] < tw:
        return None

    res = cv2.matchTemplate(img, tpl, cv2.TM_CCOEFF_NORMED)
    _, max_val, _, max_loc = cv2.minMaxLoc(res)

    if max_val < threshold:
        return None

    cx = ox + max_loc[0] + tw // 2
    cy = oy + max_loc[1] + th // 2
    return (cx, cy, float(max_val))


def exists(template_name, region=None, threshold=None):
    return find(template_name, region=region, threshold=threshold) is not None


def wait_for(template_name, timeout, region=None, threshold=None, poll=0.1, stop_check=None):
    """
    在 timeout 秒内轮询查找模板。
    命中返回 (x, y, score)；超时返回 None；stop_check() 为真则提前返回 None。
    """
    deadline = time.time() + timeout
    while time.time() < deadline:
        if stop_check is not None and stop_check():
            return None
        hit = find(template_name, region=region, threshold=threshold)
        if hit is not None:
            return hit
        time.sleep(poll)
    return None
