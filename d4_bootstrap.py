# -*- coding: utf-8 -*-
"""
PyInstaller 打包后的启动引导：优先加载 exe 同目录下的 d4_config.py。
首次运行会自动复制一份可编辑的配置到 exe 旁边。
"""

import importlib.util
import os
import shutil
import sys


def setup():
    if not getattr(sys, "frozen", False):
        return

    exe_dir = os.path.dirname(os.path.abspath(sys.executable))
    external = os.path.join(exe_dir, "d4_config.py")
    bundled = os.path.join(sys._MEIPASS, "d4_config.py")

    if not os.path.isfile(external) and os.path.isfile(bundled):
        shutil.copy2(bundled, external)

    src = external if os.path.isfile(external) else bundled
    spec = importlib.util.spec_from_file_location("d4_config", src)
    mod = importlib.util.module_from_spec(spec)
    sys.modules["d4_config"] = mod
    spec.loader.exec_module(mod)


setup()
