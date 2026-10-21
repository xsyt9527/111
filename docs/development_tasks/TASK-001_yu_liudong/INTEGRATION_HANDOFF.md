# TASK-001 集成交接文档：玩家鱼跟随手指游动

> 状态：not_started（任务审批通过、实现完成并验证后，本文档将按实际实现接口更新并置 ready）

## 1. 功能目的与所有者

- 目的：建立游戏入口（Main 主场景）与玩家鱼移动行为链（按住拖动 → 平滑跟随）
- 所有者：student-01

## 2. 运行时入口

- 待实现后填写。预期：`res://scenes/Main.tscn`（project.godot run/main_scene）

## 3. 输入与消费接口

- 待实现后填写。预期：InputEventScreenTouch / InputEventScreenMotion（经 _unhandled_input）

## 4. 输出、提供接口与发出信号

- 待实现后填写。预期公开接口：
  - `Yu.mubiao_dian: Vector2`（游动目标点，世界坐标）
  - `Yu.yidong_sudu: float`（@export 移动速度）
- 预期无信号

## 5. 状态所有者与持久化行为

- 待实现后填写。预期：无跨场景状态、无持久化

## 6. 关键场景、脚本、配置与测试

- 待实现后填写。预期：scenes/Main.tscn、scenes/Yu.tscn、scripts/main.gd、scripts/yu.gd、project.godot（run/main_scene）

## 7. 集成步骤（后续任务如何接入）

- 待实现后填写。预期：鱼群（TASK-002）实例化同款蓝图场景挂入 Main；判定（TASK-003）读取双方体型比较

## 8. 禁止的直接访问与冲突热点

- 禁止绕过 `Yu.mubiao_dian` 直接操控 Yu 内部 Sprite2D
- project.godot 除 run/main_scene 外的配置节不归本任务所有

## 9. 必需集成检查与最新验证基线

- 待实现后填写。预期：无头导入退出码 0；F5 行为链四条手动检查

## 10. 已知限制与待完成参与

- 无信号、无物理身体（判定属 TASK-003）、无动画（第 7 课）
- 检查点参与待学生实际完成后记录
