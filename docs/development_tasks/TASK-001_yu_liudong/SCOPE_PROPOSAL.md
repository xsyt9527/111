# TASK-001 范围提案：玩家鱼跟随手指游动

## 任务概要

**做什么**：建立游戏的首批场景——Main（主场景，海床背景 + 协调输入）与 Yu（玩家鱼蓝图），实现完整行为链：
按住屏幕拖动 → Main 收到触摸事件 → 把目标点写入 Yu 的公开属性 → Yu 每帧朝目标点平滑游动 → 松手停止。

**为什么是它**：全新项目尚无任何场景与主场景（见 `docs/PROJECT_STATUS_AUDIT.md`）。这是后续一切系统（鱼群生成、大吃小判定、经验成长、升级 UI）的入口和地基；同时以最小体量复习并深化捡金币课的三个核心概念（场景蓝图、实例化、delta 移动），引入两个新词（InputEvent 事件对象、主场景登记）。

**可观察结果**：F5 直接进入游戏，一条鱼随手指平滑游动；检查器可调速度；左右拖动鱼头自动翻转。

## 控制变量

| 变量 | 取值 | 理由 |
|---|---|---|
| development_strategy | plan_driven | 无行为对照工程 |
| participation_mode | guided_co_development | 沿用既定教学约定：AI 主导实现，学生导航/选择/检查/验证 |
| execution_mode | teaching | 每课一个新概念 + 检查点停顿，学生选定边教边做 |

## 功能所有权

- owner：student-01
- owned_scenes：`scenes/Main.tscn`、`scenes/Yu.tscn`
- owned_scripts：`scripts/main.gd`、`scripts/yu.gd`
- 共享变更登记：仅 `project.godot` 新增 `run/main_scene = res://scenes/Main.tscn`（当前无主场景，本任务建立入口），其他配置一律不动
- 冲突热点：Main.tscn 后续会挂鱼群（TASK-002）与升级 UI（TASK-006），本任务只建最小骨架，不留多余分支

## 集成合同

- 提供接口：`Yu.mubiao_dian`（目标点，Main 写入）、`Yu.yidong_sudu`（@export 速度，检查器可调）
- 无信号、无 Autoload、无共享状态——最小耦合
- 后续任务通过「实例化 Yu.tscn 同款蓝图模式」复用本任务建立的场景组合惯例

## 学习价值与学生参与

四个 Step、四个概念：场景蓝图（复习深化）→ 主场景入口 → **InputEvent 事件对象（新）** → move_toward+delta（复习深化）。

三个检查点：
1. **orientation**：实现前——学生打开项目定位四个目标文件，理解「Main 接收输入、Yu 负责移动」的分工设计（含一个二选一设计决策）
2. **godot-inspection**：实现后——学生在编辑器检查 Yu.tscn 节点树、@export 属性、InputEvent 处理代码位置
3. **verification-handoff**：学生 F5 亲测行为链 + 改 @export 速度观察差异，说出输入/输出/入口与一处排查位置

## 场景架构影响

- architecture_change = false（新项目建立首个入口场景，无既有生命周期受影响）
- 文件量：新增 4 个生产文件 + 3 个实现期报告；修改 1 个共享文件（project.godot，已登记）

## 排除项（本任务不做）

- 鱼群生成（TASK-002）、碰撞与大小判定（TASK-003）、鱼种数据表（TASK-004）、经验成长（TASK-005）、升级 UI（TASK-006）
- 不加物理身体（Area2D/CharacterBody2D 属判定课）
- 不加动画（Tween 属第 7 课）
- 不加 Autoload、信号、存档

## 风险与阻塞

- 无已知阻塞。素材（fish_blue.png、background_terrain.png）已导入就位
- 触摸事件在 PC 上依赖 `emulate_touch_from_mouse`（project.godot 已启用，审计确认）

## 审批方式

任何明确表达「确认 TASK-001 v1 进入开发」的文本均有效。范围变更将生成 v2 并作废本审批。
