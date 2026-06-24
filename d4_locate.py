# -*- coding: utf-8 -*-
"""
实时定位工具：证明“按钮就算移动，Python 也能实时找到它的位置”。

用法：
  python d4_locate.py
      每秒全屏查找所有模板，打印实时坐标。游戏里挪动/切换状态，输出会跟着变。

  python d4_locate.py accept.png
      只找指定模板。

  python d4_locate.py accept.png 0.7
      指定模板 + 阈值。

在控制台按 Ctrl+C 结束。
"""

import os
import sys
import time
import glob

import d4_config as cfg
import d4_vision as vision


def list_templates():
    if not os.path.isdir(cfg.TEMPLATE_DIR):
        return []
    return [os.path.basename(p) for p in glob.glob(os.path.join(cfg.TEMPLATE_DIR, "*.png"))]


def main():
    args = [a for a in sys.argv[1:]]
    threshold = cfg.MATCH_THRESHOLD
    names = None

    for a in args:
        try:
            threshold = float(a)
        except ValueError:
            names = [a if a.endswith(".png") else a + ".png"]

    if names is None:
        names = list_templates()

    if not names:
        print("templates/ 下没有模板图。先用 d4_capture.py 裁。")
        return

    print("实时定位（全屏查找），阈值=%.2f，模板：%s" % (threshold, ", ".join(names)))
    print("游戏里移动/切换画面，坐标会实时变化。Ctrl+C 结束。\n")

    try:
        while True:
            line = []
            for name in names:
                hit = vision.find(name, region=None, threshold=threshold)
                if hit is None:
                    line.append("%s: 未找到" % name)
                else:
                    x, y, score = hit
                    line.append("%s: (%d,%d) 置信=%.2f" % (name, x, y, score))
            print(time.strftime("[%H:%M:%S] ") + "  |  ".join(line), flush=True)
            time.sleep(1.0)
    except KeyboardInterrupt:
        print("\n结束。")


if __name__ == "__main__":
    main()
