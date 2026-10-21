# TASK-002 范围提案：鱼群生成与屏幕外回收

## 任务概要

**做什么**：在 TASK-001 建立的 Main 场景里加一个鱼群系统——

1. `YuNpc`：NPC 鱼蓝图，进树时随机贴图与体型，沿直线横向游动，游出屏幕自动释放；
2. `YuQun`：生成器节点，用 Timer 按随机间隔从屏幕左/右边缘外生成 NPC 鱼，同屏数量有上限。

**为什么是它**：玩家鱼能动了，但海里还是空的。鱼群是后续「大鱼吃小鱼」的猎物池——TASK-003 的碰撞判定、TASK-005 的经验成长都需要「有鱼可吃」。同时本课用一个系统串起四个新概念（随机数、Timer、视口尺寸、节点回收），每个都在下一步真实用到。

**可观察结果**：F5 后鱼从两侧随机游入，颜色、大小、速度各异，穿过屏幕后消失；同屏数量稳定；玩家鱼跟随手指仍正常。

## 控制变量

| 变量 | 取值 | 理由 |
|---|---|---|
| development_strategy | plan_driven | 无行为对照工程 |
| participation_mode | guided_co_development | 沿用既定教学约定：AI 主导实现，学生导航/选择/检查/验证 |
| execution_mode | teaching | 每课一个新概念 + 检查点停顿 |

## 功能所有权

- owner：student-01
- owned_scenes：`scenes/YuNpc.tscn`
- owned_scripts：`scripts/yu_npc.gd`、`scripts/yu_qun.gd`
- 既有文件改动：`scenes/Main.tscn` 追加 YuQun 子树；`scripts/main.gd` 仅删除调试 print
- 共享变更登记：**无**（不修改 `project.godot`，不新增 Autoload）
- 冲突热点：Main.tscn 后续还会被 TASK-006 修改；本任务只追加子树，不动 Haodi / Yu

## 集成合同

- 提供给 TASK-003：`YuNpc.tixing`（体型系数）——大鱼吃小鱼的比较依据
- 提供给后续难度调参：`YuQun` 的生成间隔、上限、速度范围 @export
- 接收信号：`Dingshi.timeout`（内部连接，不对外）
- 无共享状态、无 Autoload、无存档

## 学习价值与学生参与

四个 Step、四个概念：

| Step | 行为 | 新概念 |
|---|---|---|
| 01 | NPC 鱼蓝图 + 随机外观 | **随机数**（randf_range / pick_random） |
| 02 | 生成器挂 Main + 定时生成 | **Timer / timeout 信号** |
| 03 | 两侧边缘生成 + 横游 | **get_viewport_rect() 视口尺寸** |
| 04 | 出屏回收 + 数量上限 | **queue_free 与生命周期**（复习） |

三个检查点：
1. **orientation**：实现前——学生定位文件，说出「生成器 vs NPC 蓝图」分工，并做一个二选一设计决策（随机间隔 vs 固定间隔）
2. **godot-inspection**：实现后——在编辑器检查 Main.tscn 的 YuQun 子树、Timer 属性、YuNpc 检查器参数
3. **verification-handoff**：F5 亲测生成/游入/回收，调参数看差异，说出一处排查位置

## 场景架构影响

- architecture_change = true：Main 下新增常驻子树 `YuQun → Dingshi`，以及运行时动态子节点 `YuNpc × N`
- 生命周期：YuQun/Timer 随 Main 创建释放；YuNpc 由生成器创建、出屏 queue_free
- 无池化，无跨场景状态，无动画依赖

## 排除项（本任务不做）

- 碰撞与大小判定（TASK-003）、鱼种数据表（TASK-004）、经验成长（TASK-005）、升级 UI（TASK-006）
- 对象池、Tween 动画、粒子、音效
- 不修改 `project.godot`，不新增 Autoload

## 风险与阻塞

- 无已知阻塞。素材已导入；TASK-001 场景结构已验证
- 风险点：Godot 4.7 中 Timer 信号连接若写成旧式字符串会报错——本任务统一用代码 `connect()`，实现时以 headless 导入验证

## 审批方式

任何明确表达「确认 TASK-002 v1 进入开发」的文本均有效。范围变更将生成 v2 并作废本审批。

## 版本记录

- **v1**（2026-10-21，待审批）：初始范围。
