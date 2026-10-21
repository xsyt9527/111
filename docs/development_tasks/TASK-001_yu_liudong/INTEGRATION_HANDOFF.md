# TASK-001 集成交接文档：玩家鱼跟随手指游动

> 状态：ready（交付完成后置 ready；interface 与实际实现一致）

## 1. 功能目的与所有者

- 目的：建立游戏入口（Main 主场景）与玩家鱼移动行为链——按住屏幕拖动 → Main 接收输入 → 目标点写入 Yu → Yu 平滑游动。
- 所有者：student-01。
- 覆盖场景：`res://scenes/Main.tscn`、`res://scenes/Yu.tscn`；脚本：`scripts/main.gd`、`scripts/yu.gd`。

## 2. 运行时入口

- `res://scenes/Main.tscn`，已在 `project.godot` 登记为 `run/main_scene`。
- F5 直接启动；Android 导出后也从此场景进入。

## 3. 输入与消费接口

- `_unhandled_input(event)` 接收：
  - `InputEventScreenTouch`（仅 `event.pressed == true`，即手指按下）
  - `InputEventScreenDrag`（按住期间移动）
- PC 调试依赖 `project.godot` 的 `pointing/emulate_touch_from_mouse=true`。
- 屏幕坐标直接当作世界坐标使用（本场景无 Camera2D；**若后续加入相机，此处需转换为世界坐标**）。

## 4. 输出、提供接口与发出信号

- 提供接口：
  - `Yu.mubiao_dian: Vector2` —— 游动目标点（世界坐标），由 Main 写入。
  - `Yu.yidong_sudu: float`（`@export`，默认 300）—— 移动速度，像素/秒，检查器可调。
- 发出信号：无。
- 运行时输出：玩家鱼 `position` 每帧朝 `mubiao_dian` 靠近；`$Sprite2D.flip_h` 按水平方向翻转。

## 5. 状态所有者与持久化行为

- `mubiao_dian` 由 Main 每帧按输入写入；Yu 只读自己的属性移动。无跨场景状态、无存档、无持久化。
- 场景重进即重置（Yu 的 `_ready` 把目标点设为自身位置）。

## 6. 关键场景、脚本、配置与测试

| 资产 | 作用 |
|---|---|
| `scenes/Main.tscn` | 主场景：Haodi（Sprite2D 海床背景，scale 20×11.25 铺满）+ Yu 实例 |
| `scenes/Yu.tscn` | 玩家鱼蓝图：Node2D 根 + Sprite2D（fish_blue.png） |
| `scripts/main.gd` | 输入接收与目标点写入；含调试 print（第 2 课前移除） |
| `scripts/yu.gd` | `class_name Yu`；`_process` 平滑移动 + 朝向翻转 |
| `project.godot` | `run/main_scene`、`emulate_touch_from_mouse` |
| 素材 | `assets/sucai/kenney_fish/PNG/Default/fish_blue.png`、`background_terrain.png`（CC0） |

## 7. 集成步骤（后续任务如何接入）

- TASK-002（鱼群）：在 Main 下新增鱼群生成容器，实例化鱼类场景；不得复用 `Yu` 场景本体（玩家鱼与 NPC 鱼分离）。
- TASK-003（判定）：读取双方体型比较；届时再为实体加 Area2D 与碰撞层。
- TASK-005/006（成长/升级）：可读取或写入 `Yu.yidong_sudu` 实现加速 buff；新增 UI 时输入处理继续集中在 Main 的输入入口或 UI 自己的 `_gui_input`，避免两处争抢。
- 新增场景请通过 Main 静态实例化或由 Main 协调器的公开方法接入，禁止从其他场景用长 NodePath 直接操作 Yu 内部节点。

## 8. 禁止的直接访问与冲突热点

- 禁止绕过 `Yu.mubiao_dian` 直接改写 Yu 的 `position`（会与 `_process` 抢控制权）。
- 禁止直接操作 `Yu/Sprite2D.flip_h`（朝向由 yu.gd 统一管理）。
- 冲突热点：`Main.tscn` 后续将挂鱼群、HUD、升级 UI；`project.godot` 的输入/显示节后续任务如需修改必须登记。

## 9. 必需集成检查与最新验证基线

- `"$GODOT_BIN" --headless --path . --import` 退出码 0
- `"$GODOT_BIN" --headless --path . --quit-after 10` 退出码 0
- F5 手动四条：按住跟随 / 松手停止 / 改速变慢 / 往返翻转（学生已确认通过 2026-10-21）
- 实现基线：42b0494；最终验证 commit 见 TASK_STATE.last_verified_commit。

## 10. 已知限制与待完成参与

- 仅支持单指（未区分 `event.index`）；多指会互相覆盖目标点。
- 无物理身体、无碰撞——判定属 TASK-003。
- 无动画——游动摆动/吞吃反馈属第 7 课。
- `main.gd` 调试 print 待第 2 课清理。
- 学习参与：三个检查点均有学生实际证据（见 LEARNING_STATE.json）。
