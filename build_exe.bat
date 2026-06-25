@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo === 安装打包依赖 ===
pip install -r requirements.txt -r requirements-build.txt
if errorlevel 1 exit /b 1

echo.
echo === 开始打包 d4_auto.exe ===
python -m PyInstaller --noconfirm --clean d4_auto.spec
if errorlevel 1 exit /b 1

echo.
echo === 完成 ===
echo 输出: dist\d4_auto.exe
echo.
echo 首次运行 exe 时，同目录会自动生成可编辑的 d4_config.py
echo 离线可用，无需 Python 环境。
pause
