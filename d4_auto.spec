# -*- mode: python ; coding: utf-8 -*-
# PyInstaller 打包配置：python -m PyInstaller d4_auto.spec

import os

ROOT = os.path.abspath(SPECPATH)

REQUIRED_TEMPLATES = [
    "accept.png",
    "not_applicable.png",
    "recipe_add_affix.png",
    "recipe_upgrade.png",
    "recipe_transmute.png",
    "recipe_three_in_one.png",
]

datas = [
    (os.path.join(ROOT, "templates", name), "templates")
    for name in REQUIRED_TEMPLATES
    if os.path.isfile(os.path.join(ROOT, "templates", name))
]
datas.append((os.path.join(ROOT, "d4_config.py"), "."))

a = Analysis(
    [os.path.join(ROOT, "d4_auto.py")],
    pathex=[ROOT],
    binaries=[],
    datas=datas,
    hiddenimports=[
        "keyboard",
        "keyboard._winkeyboard",
        "pydirectinput",
        "mss",
        "cv2",
        "numpy",
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)

pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name="d4_auto",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
