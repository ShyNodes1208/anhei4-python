# anhei4-python

暗黑破坏神4 赫拉迪姆魔盒自动化脚本（Python + 图像识别版）。

**详细说明见 [使用说明.md](使用说明.md)**

## 功能

| 热键 | 功能 |
|------|------|
| F7 | 仅嬗变物品 |
| F8 | 添加词缀 → 升级至传奇 → 嬗变（三阶段全流程） |
| F9 | 三合一塑形（范围内每 3 格一组） |
| F10 | 停止 |

日常只需在 `d4_config.py` 修改 `SLOT_FIRST` / `SLOT_LAST` 设定处理范围。

## 环境要求

- Windows，Python 3.10+
- 游戏分辨率 **2560×1440**
- 建议**以管理员身份**运行终端

## 安装与运行

```bash
pip install -r requirements.txt
python d4_auto.py
```

切到游戏，打开魔盒+背包，按热键开始；控制台 **ESC** 退出。

```bash
python d4_auto.py --calibrate   # 校准坐标
```

## 目录结构

```
d4_auto.py      # 主程序
d4_config.py    # 配置
d4_vision.py    # 截屏与模板匹配
d4_input.py     # 鼠标输入
templates/      # 识别模板
```

## 免责声明

本工具仅供个人学习与研究。使用自动化脚本可能违反游戏服务条款，请自行承担风险。
