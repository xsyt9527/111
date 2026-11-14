# 实现报告 — TASK-023 雷达小地图与透明度设置

日期：2026-11-13
状态：实现完成，八步门禁全绿；F5 目检与红测待用户；**未 commit、未 push**。

## 一、用户目标

1. 小地图移到右上角「设置」按钮正下方，不再压在原生 UI 上。
2. 去掉海图背景，改成雷达式探测：半透明深色底 + 淡化九宫格 + 少量亮点，避免小地图色彩过杂。
3. 在设置面板增加「地图透明度」滑条，并持久化，方便按个人习惯观看。

## 二、实现

### 1. 位置与雷达化（`scripts/xiao_di_tu.gd`、`scenes/Main.tscn`）

- `XiaoDiTuUI/XiaoDiTu` 目标矩形 `(1008,52)-(1248,212)`，即设置按钮正下方；测试断言地图水平跨度覆盖按钮且顶部低于按钮底部，二者不重叠。
- 删除 `beijing_3x3.webp` 的 `preload` 与背景贴图绘制，改为 Control 立即模式 `_draw`：
  - `DI_TU_QU = Rect2(0,0,240,134)`；
  - 半透明深色底 `Color(0,0,0,0.82)` + 低 alpha 青色细边框；
  - 3×3 房间网格与雷达同心椭圆环、中心小十字；
  - 当前房间亮青边框；
  - 玩家蓝点、NPC 鱼红点、可吃植物绿点、首领/机械船金色点并加白描边。
- 数据只读 `player` / `yu_npc` / `zhi_wu` 组与 `Main.ji_qi_chuan`，不复制 gameplay 状态；`mouse_filter=IGNORE`，不抢摇杆/按钮输入。

### 2. 透明度设置与持久化（`scripts/she_zhi.gd`、`scripts/cun_dang.gd`、`scripts/main.gd`）

- 设置主面板运行时创建 `DiTuTouMingLie`（`DiTuTouMingLabel` / `DiTuTouMingHua` / `DiTuTouMingZhi`）：
  - 范围 `0.3 ~ 1.0`，步进 `0.05`，默认 `0.85`；
  - `value_changed` 实时写 `CunDang.xiao_di_tu_tou_ming` 并推 `XiaoDiTu.she_tou_ming_du(zhi)`；
  - `drag_ended` 才落盘，避免拖动过程反复写文件。
- `CunDang` 新增 `xiao_di_tu_tou_ming := 0.85`；读档缺键回退 0.85，坏值夹回 `0.3~1.0`；写档键名 `xiao_di_tu_tou_ming`。`SHE_ZHI_BAN_BEN` 保持 1：这是**新增可选键**，不改变旧档兼容性。
- `Main._ready()` 末尾按读档值调用 `xiao_di_tu.she_tou_ming_du(...)`，开局即生效。

## 三、断言与门禁

- `tests/ce_panding.gd` 新增/修正断言覆盖：地图落在设置按钮正下方不重叠、无背景贴图依赖、世界坐标到地图坐标映射、透明度默认值/范围/夹取、设置控件写入 `CunDang`、`she_tou_ming_du` 即时生效。
- 测试隔离：先切 `user://` 隔离目录并调用 `CunDang.zai_ru_she_zhi()`，避免真实玩家设置文件污染默认值断言。
- 2026-11-13 完整八步门禁：`232 / 25 / 1422 / 8 / 20 / 144 / 1287 passed`，0 failed，无 ERROR，合计 **3138 断言**，脚本输出「全绿：可以交付」。
- 与 TASK-022 的 1228 条 `ce_panding` 相比净增 59 条（TASK-023 38 条 + TASK-024 船兼容 21 条）。
- `validate_task.py`：`VALID: TASK-023 v1 (plan_driven)`。
- `check_task_scope.py check`：最终结果见交付说明；新增文档均在 TASK-023/TASK-024 允许列表内。

## 四、待人工确认

- F5 拖动设置滑条，小地图透明度是否即时变化。
- 退出重进后透明度是否保持；删除设置文件后是否回到 0.85。
- 实机观察雷达底、网格与四类亮点在复杂海景上是否足够清晰，不遮挡战斗。

## 五、边界

- 未改游戏数值、刷怪、战斗与存档 schema；`project.godot` 的 Web `gl_compatibility` 保留。
- 本轮未 commit / 未 push。
