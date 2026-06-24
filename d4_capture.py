# -*- coding: utf-8 -*-
"""
模板裁剪工具。

用法：
  1) python d4_capture.py
     在游戏里摆好画面（比如让“接受”按钮出现，或让红字“不适用”出现），
     回到控制台按回车，会保存一张全屏截图 full_*.png。

  2) python d4_capture.py crop
     打开最近一次的全屏截图，用鼠标框选要的区域，按回车确认，
     会让你输入保存名（accept / not_applicable），自动存到 templates/。

也可以直接用任意截图软件裁好，命名为 templates/accept.png 和
templates/not_applicable.png 即可。

模板要求：
  - 必须在 2560x1440 下截取（和实际运行同分辨率）
  - 尽量裁“稳定不变”的小块：
      accept.png        -> “接受”按钮上的文字/图标
      not_applicable.png-> 红字“该物品不适用于此配方组合”里的一小段
"""

import os
import sys
import glob
import time

import cv2

import d4_config as cfg
import d4_vision as vision


def save_full():
    img, _ = vision.grab()
    fn = time.strftime("full_%Y%m%d_%H%M%S.png")
    cv2.imwrite(fn, img)
    print("已保存全屏截图：%s" % fn)
    return fn


def latest_full():
    files = sorted(glob.glob("full_*.png"))
    return files[-1] if files else None


def crop():
    path = latest_full()
    if not path:
        print("没有找到 full_*.png，请先运行 python d4_capture.py 截图。")
        return
    img = cv2.imread(path)
    print("在弹出的窗口里用鼠标框选区域，回车确认，c 取消。")
    roi = cv2.selectROI("crop (回车确认/ c 取消)", img, showCrosshair=True)
    cv2.destroyAllWindows()
    x, y, w, h = roi
    if w == 0 or h == 0:
        print("未选择区域。")
        return
    crop_img = img[y:y + h, x:x + w]

    name = input("保存为模板名 (accept / not_applicable): ").strip()
    if not name:
        print("未输入名称，取消。")
        return
    if not name.endswith(".png"):
        name += ".png"
    os.makedirs(cfg.TEMPLATE_DIR, exist_ok=True)
    out = os.path.join(cfg.TEMPLATE_DIR, name)
    cv2.imwrite(out, crop_img)
    print("已保存模板：%s  （区域 left=%d top=%d w=%d h=%d）" % (out, x, y, w, h))
    print("提示：可把上面的 left/top/w/h 用于 d4_config.py 里对应的 REGION_* 以缩小搜索范围。")


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "crop":
        crop()
        return
    input("摆好游戏画面后，回到这里按回车截图……")
    save_full()
    print("接着运行：python d4_capture.py crop  来裁出模板。")


if __name__ == "__main__":
    main()
