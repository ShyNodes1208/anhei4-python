# anhei4-python

暗黑破坏神4 赫拉迪姆魔盒自动化脚本（Python + 图像识别版）。

在背包放入装备后，按 **F8** 自动完成三阶段流程（方案 B：逐阶段）：

1. 添加词缀
2. 升级至传奇
3. 嬗变物品

## 环境要求

- Windows
- Python 3.10+
- 游戏分辨率 **2560×1440**（全屏或无边框窗口）
- 建议**以管理员身份**运行终端（热键与驱动级点击需要）

## 安装

```bash
pip install -r requirements.txt
```

## 使用

1. 打开游戏，进入魔盒界面并打开背包
2. 在 `d4_config.py` 中设置 `ROWS`、`COLS`（处理背包行列数）
3. 运行：

```bash
python d4_auto.py
```

4. 切回游戏，按 **F8** 开始，**F10** 停止；控制台按 **ESC** 退出程序

### 辅助命令

```bash
python d4_auto.py --calibrate   # 校准各按钮坐标
python d4_locate.py             # 实时查看模板匹配位置
python d4_capture.py              # 截屏并裁模板
```

## 配置说明

主要参数在 `d4_config.py`：

| 参数 | 说明 |
|---|---|
| `ROWS` / `COLS` | 背包处理范围 |
| `DO_ADD_AFFIX` / `DO_UPGRADE` / `DO_TRANSMUTE` | 阶段开关 |
| `AFFIX_REFORGE_COUNT` | 添加词缀重塑次数 |
| `STEP_DELAY` | 每步点击后等待（秒） |

## 图像识别

模板图放在 `templates/` 目录。配方按钮会随列表重排，脚本通过模板匹配动态定位；识别失败时退回固定坐标兜底。

不适用该配方的装备（如出现红字提示）会自动跳过，不会误点其他按钮。

取回装备统一使用魔盒 **「清除」** 按钮，比右键取回更安全。

## 目录结构

```
d4_auto.py      # 主流程
d4_config.py    # 配置
d4_vision.py    # 截屏与模板匹配
d4_input.py     # 鼠标输入
d4_capture.py   # 模板裁剪工具
d4_locate.py    # 实时定位调试
templates/      # 识别模板与参考截图
*.lua           # 早期 G HUB 版脚本（参考）
```

## 免责声明

本工具仅供个人学习与研究。使用自动化脚本可能违反游戏服务条款，请自行承担风险。
