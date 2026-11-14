# TASK-023 范围提案

## 用户反馈原文（2026-11-13）
1. 把地图放在设置下面，现在的 UI 位置怪怪的。
2. 地图就像个雷达一样，能探测，不需要背景地图的图，不然小小一张地图色彩太丰富，玩起来看着难受；再在设置里加一个透明度设置，方便观看。

## 目标
- 小地图从左上角移到右上角「设置」按钮下方，不再与现有 HUD 争夺左上空间。
- 小地图改无海图背景的雷达式绘制：半透明深色面板、淡化九宫格、当前房间亮框；玩家蓝、首领金、NPC 红、植物绿四类亮点与图例保持不变。
- 设置主面板新增「地图透明度」滑条（0.3~1.0，默认 0.85），拖动即时生效，并写入游玩设置 JSON，重启后保持。

## 三个步骤
1. **step-01 地图位置与雷达绘制**：改 `scenes/Main.tscn` 的 XiaoDiTu 矩形，改 `scripts/xiao_di_tu.gd` 的绘制，删除海图 preload。
2. **step-02 透明度设置与持久化**：`scripts/she_zhi.gd` 加滑条，`scripts/cun_dang.gd` 读写 `xiao_di_tu_tou_ming`。
3. **step-03 测试/门禁/文档**：追加 `tests/ce_panding.gd` 断言，跑八步门禁，更新索引/词表/学习路线/Word 词表。

## 文件边界
- 允许修改：`scripts/xiao_di_tu.gd`、`scenes/Main.tscn`、`scripts/she_zhi.gd`、`scripts/cun_dang.gd`、`scripts/main.gd`、`tests/ce_panding.gd`、`docs/TASK_INDEX.md`、`docs/引擎词总表.md`、`LEARNING_ROADMAP.md`、`Godot引擎词总表.docx`、`.godot/**`。
- 允许新增：仅 `docs/development_tasks/TASK-023_lei_da_xiao_di_tu/**`。

## 禁区
- 背景海图绘制、旋转扫描线动画、新增 Autoload。
- 局内存档 schema 改动（只动 `user://shenhaishiji_shezhi.json` 这一份游玩设置文件）。
- 攻击/掉落/体型数值。
- 不改写既有测试断言，只追加。
- 不 commit、不 push（由主代理统一执行）。

## 验收
- `validate_task.py` 输出 `VALID: TASK-023 v1 (plan_driven)`。
- `headless --import` 退出码 0，`tests/pao_pi.bat` 八步全绿，`check_task_scope.py` 零违规。
- F5：小地图在设置按钮下方、无海图背景、透明度滑条即时生效且重启保持。
