# TASK-003 范围提案：大吃小判定

## 任务概要

**做什么**：给玩家鱼和 NPC 鱼各装一个**不可见的物理检测区**（Area2D + 圆形 CollisionShape2D）。玩家撞到 NPC 的瞬间，比较两边体型：

- 玩家 `tixing` **>** NPC `tixing` → **吃掉**：NPC `bei_chi()` 自我释放
- 玩家 `tixing` **≤** NPC `tixing` → **受伤**：玩家闪红 1 秒 + 无敌帧（期间不重复受伤、仍能吃小鱼）

**为什么是它**：前两课做好了"能动"和"有鱼"，但互相穿过不算游戏。本课之后，「大鱼吃小鱼」的玩法核心正式成立——这也是复习 signals-groups 技能的最佳载体（Area2D 的 `area_entered` 就是一个真信号）。

**可观察结果**：F5 里追着小鱼撞它会消失，被大鱼撞到会闪红一秒；其他一切行为无退化。

## 控制变量

| 变量 | 取值 | 理由 |
|---|---|---|
| development_strategy | plan_driven | 无行为对照工程 |
| participation_mode | guided_co_development | 沿用既定教学约定 |
| execution_mode | teaching | 每步一个新概念 + 检查点停顿 |

## 功能所有权

- owner：student-01
- 修改文件仅 4 个：`Yu.tscn`、`yu.gd`（追加判定/受伤成员，**移动逻辑一行不动**）、`YuNpc.tscn`、`yu_npc.gd`（追加 `bei_chi()`，**游动/回收逻辑不动**）
- **零修改**：`Main.tscn`、`main.gd`、`yu_qun.gd`、`project.godot`
- 无新增生产文件；新增文件仅任务包三份报告

## 集成合同

- 消费：`YuNpc.tixing`（TASK-002 接口）
- 提供给 TASK-005：`Yu.tixing`（玩家体型，长大时增大它）、`YuNpc.bei_chi()`（吃鱼经验挂钩点）
- 提供给 TASK-008：`Yu._shoushang()`（血量/死亡挂钩点）
- **碰撞层约定（全项目沿用）**：Layer 1 = 玩家，Layer 2 = 鱼群；玩家 mask=2（我检测鱼），NPC mask=0（我不检测，避免重复判定）
- 信号：`area_entered`（玩家侧连接）、`timeout`（无敌计时，复习）

## 学习价值与学生参与

| Step | 行为 | 新概念 |
|---|---|---|
| 01 | 玩家加检测区 + tixing 成员 | **Area2D / CollisionShape2D** |
| 02 | NPC 加检测区（只挂层不检测） | **collision_layer / collision_mask** |
| 03 | area_entered → 比较 → 吃/伤分支 | **area_entered 信号与参数** |
| 04 | 闪红 + 1 秒无敌 | 无敌帧 + modulate（Timer 复习） |

三个检查点：
1. **orientation**：定位两个检测区 + 理解 layer/mask 概念 + 二选一设计决策
2. **godot-inspection**：检查器核对 Layer/Mask 勾选、圆形半径调整实验
3. **verification-handoff**：F5 亲测吃小鱼、闪红、无敌帧、全量回归

## 场景架构影响

- architecture_change = true：Yu 与 YuNpc 各追加 `PandingQu → CollisionShape2D` 子树；Yu 追加 `WudiDingshi`（Timer）
- 不产生新的动态节点；所有信号宿主内连接，随宿主释放
- Main / YuQun / Dingshi 零改动

## 排除项（本任务不做）

- 经验/分数（TASK-005）、血量/死亡（TASK-008）、吞吃特效与 Tween（第 7 课）
- 玩家长大（`tixing` 本课只读不写）
- 不加 RigidBody2D/CharacterBody2D（Area2D 只做检测，不做物理推挤——鱼不会互相弹开）
- 不改 project.godot 物理设置

## 风险与阻塞

- 无已知阻塞。圆形半径 22 的判定手感可能偏松/偏紧，检查器可调（本课留参数，正式手感调优在第 7 课）
- 风险点：`area.get_parent()` 依赖"Area2D 是 YuNpc 直接子节点"的结构约定——已写进注释与合同

## 审批方式

任何明确表达「确认 TASK-003 v1 进入开发」的文本均有效。范围变更将生成 v2 并作废本审批。

## 版本记录

- **v1**（2026-10-22 审批通过，原文：「确认 TASK-003 v1 进入开发」）：初始范围。
- **v2**（2026-10-22，待审批）：学生编辑器检查期间，Godot 编辑器给 Main.tscn 补写了 Yu.tscn 的 uid 引用（纯记账，零行为变化）；另 WPS 占用词表 docx 产生的 ~$ 锁文件反复触发范围检查。v2 = 白名单补登记 scenes/Main.tscn 与 .gitignore，并在 .gitignore 新增 `~$*` 忽略规则根治锁文件问题。保留 v1 实现基线 1b872c7（不重新捕获）。行为与验收零变化。
