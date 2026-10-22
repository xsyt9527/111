# TASK-002 实现报告

> 提交：`f282d00`（生产代码）+ 收尾提交
> 基线：`898f03b8807190fdc77a47412e52a8dc0631e524`
> 引擎认证：Godot 4.7.2.stable.official.ed1daf0bf（`--version` 实测）

## 按步实现

| Step | 内容 | 文件 | 状态 |
|---|---|---|---|
| 01 | YuNpc 蓝图：_ready 随机贴图（pick_random）+ 随机体型（randf_range 0.6~1.6）| yu_npc.gd / YuNpc.tscn | ✅ |
| 02 | YuQun 挂入 Main：Dingshi(Timer, one_shot) + timeout 代码连接 + 随机间隔重排 | yu_qun.gd / Main.tscn | ✅ |
| 03 | 两侧边缘生成：get_viewport_rect().size 定边界，随机左右、随机高度、随机速度，add_child 前写入 fangxiang/sudu | yu_qun.gd | ✅ |
| 04 | 出屏回收（queue_free）+ 同屏上限（只数 is YuNpc 的子节点） | yu_npc.gd / yu_qun.gd | ✅ |

## 与开发提示的偏差（均为小项，未改行为合同）

1. `YuNpc.tscn` 根节点预设 `position = Vector2(640, 360)`：让 F6 单独运行时鱼在屏幕中央可见约 7 秒（否则从 (0,0) 出发 0.8 秒就出屏）。生成器在 add_child 前会覆盖该值，运行行为不受影响。
2. `scripts/main.gd` 按计划仅删除调试 print。
3. 学生实验参数 `zuida_shuliang = 2`（检查器操作留痕在 Main.tscn）已于收尾时恢复默认 14。

## 自动验证

- `--headless --path . --import` 退出码 0（多次）
- `--headless --path . --fixed-fps 60 --quit-after 360` 退出码 0（模拟 6 秒，覆盖多次生成与回收）
- `check_task_scope.py check`：0 违例（11 允许 / 0 违规）
- 类注册检查：导入日志显示 `YuNpc`、`YuQun` 全局类名注册成功

## 交接接口（已按合同提供）

- `YuNpc.tixing: float`（0.6~1.6）→ TASK-003 大小判定
- `YuNpc.sudu / fangxiang` → 生成器写入，TASK-003 可复用
- `YuQun` 四个 @export → 难度调参入口
