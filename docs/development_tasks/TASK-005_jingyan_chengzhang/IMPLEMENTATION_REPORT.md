# TASK-005 实现报告

## 概要

四步全部实现并通过自动检查：Autoload 全局账本 `ZhangBen`（经验/等级唯一所有者 + 两信号广播）→ `bei_chi()` 记账消费 `fenzhi` → 玩家听 `sheng_ji` 信号长大（判定圈随 scale 白送变大）→ CanvasLayer 经验条 UI。**肉鸽成长循环第一环闭环：吃鱼 → 涨条 → 升级 → 长大 → 能吃的鱼变多。**

## 分步交付

| Step | 内容 | 文件 | 自动检查 |
|---|---|---|---|
| 01 | 账本 + Autoload 注册 | scripts/zhang_ben.gd（+ .uid）、project.godot | --headless --import 退出码 0 |
| 02 | bei_chi 记账 | scripts/yu_npc.gd | import 0 错误 + 360 帧运行退出码 0 |
| 03 | 听信号长大 | scripts/yu.gd | import 0 错误 + 360 帧运行退出码 0 |
| 04 | 经验条 UI | scripts/jing_yan_ui.gd（+ .uid）、scenes/Main.tscn | import 0 错误 + 360 帧退出码 0 + scope 0 违例 |

## 交付形态

- **账本**：`SHENG_JI_YUZHI := [8, 20, 35, 55, 80, 110]`（本级经验，升级扣除）、`MEI_JI_TIXING := 0.2`（升 1 级体型 ×1.2）、满级封顶停最后一级阈值
- **注册**：`project.godot` `[autoload]` 段 `ZhangBen="*res://scripts/zhang_ben.gd"`——本项目首个 Autoload
- **记账**：`bei_chi()` 判空后 `ZhangBen.jia_jing_yan(yu_zhong.fenzhi)`，兜底鱼不给经验
- **长大**：`_on_sheng_ji` 里 `tixing += 0.2; scale = Vector2.ONE * tixing`——PandingQu 随根节点缩放，判定圈零代码变大
- **UI**：JingYanTiao(CanvasLayer) → ProgressBar(340,24 起 600×20) + Label("Lv.1")，纯监听无状态

## 设计决策（学生选定，均为推荐项）

1. 升级阈值用脚本常量数组（本课聚焦 Autoload 概念，数据化与第 6 课强化卡一起做）
2. 账本发 `sheng_ji` 信号、玩家自己监听长大（解耦——账本不认识任何场景节点，TASK-006 弹窗只需再连同一信号）

## 过程记录

- **学生实验参数还原遗漏**：godot-inspection 中改 `SHENG_JI_YUZHI` 首项 8→3 验证升级后未还原（实验本身成功：吃 3 条即升级）。讲解发现后代为还原并重申"实验参数当场还原"纪律——TASK-004 课的待巩固项之一"实验后还原"仍需下节课继续观察。
- **学生需求与课程计划吻合**：学生在 godot-inspection 主动提出"感觉不到变大，可不可以加入升级体型变大"——恰为 step-03 既定内容，学习目标与课程节奏对齐。
- **CanvasLayer 疑问**：verification 阶段学生发现"CanvasLayer 不是在 Main 下面吗"与我"账本不能挂 Main 下"的表述表面矛盾——已讲清两个维度（挂在哪=生命周期：UI 随场景生灭是对的；怎么画=渲染：CanvasLayer 切断 Node2D 变换继承）。该问题本身是高质量概念辨析证据。
- **管道退出码坑**：`cmd | tail; echo $?` 取的是 tail 的退出码——改用直接执行取真实退出码复跑确认。

## 行为变化清单

- 吃 NPC 鱼经验入账（蓝 +1、红 +1、绿 +2、橙 +3、棕/粉 +5）；兜底鱼 0
- 攒满本级阈值：`deng_ji` +1、经验清零重计、玩家瞬间变大 0.2、判定圈连带变大——原"打不过"的鱼可反杀
- 屏幕顶部新增经验条 + Lv 标签，实时刷新；开局先画一次避免空白
- 移动/生成/回收/判定/无敌零改动，行为无退化（学生实测确认）
