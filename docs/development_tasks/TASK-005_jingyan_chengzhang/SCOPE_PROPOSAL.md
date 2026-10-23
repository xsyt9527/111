# TASK-005 范围提案：经验与成长

## 任务概要

**做什么**：新建 Autoload 全局账本 `ZhangBen`（经验/等级/升级阈值），在 `bei_chi()` 入口记账（消费 TASK-004 的 `fenzhi`），账本升级时发信号、玩家鱼听信号长大（`Yu.tixing` 增大，判定圈随 scale 白送变大），并在主场景加一条经验条 UI（等级 + 进度）。

**为什么是它**：第 3、4 课挖好的三个挂钩点（`bei_chi()` 入口、`Yu.tixing`、`fenzhi` 字段）本课会师——吃鱼→记账→升级→长大→能吃的鱼变多，肉鸽成长循环第一环转动。Autoload 也是 zwz 对照学习里"阳光账本"的正式落地。

**可观察结果**：F5 吃鱼涨经验条；攒够升 Lv，玩家鱼肉眼可见变大、判定圈变大（原来吃不掉的鱼变得能吃）；撞大鱼闪红照旧。

## 控制变量

| 变量 | 取值 | 理由 |
|---|---|---|
| development_strategy | plan_driven | 无行为对照工程 |
| participation_mode | guided_co_development | 沿用既定教学约定 |
| execution_mode | teaching | 每步一个新概念 + 检查点停顿 |

## 功能所有权

- owner：student-01
- 新建：`scripts/zhang_ben.gd`（Autoload 账本）、`scripts/jing_yan_ui.gd`（经验条 UI 脚本）
- 修改 3 文件 + 1 配置：`project.godot`（注册 Autoload）、`yu_npc.gd`（bei_chi 加一行记账）、`yu.gd`（听升级信号长大）、`Main.tscn`（加经验条 UI 子树）
- **零修改**：`yu_qun.gd`、`yu_zhong.gd`、`Yu.tscn`、`YuNpc.tscn`、`main.gd`

## 集成合同

- **登记的共享变更：project.godot `[autoload]` 段新增 `ZhangBen="*res://scripts/zhang_ben.gd"`**——本课唯一结构性修改，经审计确认当前无任何 Autoload、无冲突
- 消费：`YuZhong.fenzhi`（TASK-004 数据）、`YuNpc.bei_chi()` 入口（TASK-003 预告挂钩点）、`Yu.tixing`（TASK-003 接口，首次写入）
- 提供信号：`ZhangBen.jing_yan_bian_hua(jing_yan, yuzhi)`、`ZhangBen.sheng_ji(xin_deng_ji)`——UI 与玩家各自连接
- 提供给 TASK-006：升级时机（sheng_ji 信号触发第 6 课的三选一弹窗）、账本数值结构
- 提供给 TASK-008：`jia_jing_yan()` 同款入口模式可扩血量/死亡记账

## 学习价值与学生参与

| Step | 行为 | 新概念 |
|---|---|---|
| 01 | zhang_ben.gd + Autoload 注册 | **Autoload 全局单例：任何场景都能访问的账本** |
| 02 | bei_chi() 记账 | 全局访问 + 数据消费（fenzhi 从"存"变"用"） |
| 03 | 升级信号 → 玩家长大 | **跨节点信号：账本 emit、玩家 connect** |
| 04 | 经验条 UI | **CanvasLayer + ProgressBar：UI 层与游戏层分离** |

三个检查点：
1. **orientation**：定位三个挂钩点 + 理解"全局单例 vs 场景节点" + 二选一设计决策 ×2
2. **godot-inspection**：项目设置看 Autoload 注册、远程场景树看 ZhangBen 根节点、改阈值实验后还原
3. **verification-handoff**：F5 亲测四条（涨条/升级长大/判定圈变大/全量回归）

## 场景架构影响

- architecture_change = true：**场景树根多一个 ZhangBen（Autoload，位于所有场景之上）**；Main 加 JingYanTiao(CanvasLayer) UI 子树
- 账本生命周期 = 游戏全程（跨场景、不随 Main 释放）；经验条 UI 随 Main
- 玩家 scale 首次被写入：子节点（判定圈）跟随缩放，第 3 课已验证该机制

## 排除项（本任务不做）

- 升级三选一弹窗（TASK-006）——升级暂只长大
- 血量/死亡/结算（TASK-008）
- 平滑成长动画（Tween 属第 7 课——本课 scale 直接跳变）
- 升级阈值 .tres 数据化（本课用脚本常量数组，聚焦 Autoload 概念；数据化与强化卡一起做）
- 经验条美化/动效（第 7 课统一手感调优）
- 死亡后重开时账本重置逻辑（第 8 课 change_scene 配套）

## 风险与阻塞

- 无已知阻塞。Autoload 名 `ZhangBen` 与既有 class_name 无冲突（已核对）
- 风险点：UI 监听信号必须在 ZhangBen 就绪后连接——Autoload 先于一切场景 _ready，天然满足
- 风险点：`bei_chi()` 里 yu_zhong 可能为 null（兜底鱼）——记账需判空，吃兜底鱼不给经验

## 审批方式

任何明确表达「确认 TASK-005 v1 进入开发」的文本均有效。范围变更将生成 v2 并作废本审批。

## 版本记录

- **v1**（2026-10-23，待审批）：初始范围。
