# TASK-003 学习记录：大吃小判定

## 学习目标

| # | 目标 | 掌握证据 |
|---|---|---|
| 1 | 定位两个 PandingQu 子树，说出 Area2D / CollisionShape2D 分工 | orientation + 检查器核对 ✅ |
| 2 | 解释 layer 与 mask，说明单向检测防重复 | orientation 讲解 + 追问确认 ✅ |
| 3 | 跟踪判定数据流：area_entered → get_parent → 比较 → 分支 | 验证 + 提问触及本质 ✅ |
| 4 | 检查器核对 Layer/Mask、调半径观察判定范围 | inspection 三项操作 ✅ |

## 本课新概念

1. **Area2D 与 CollisionShape2D**：Area2D 是"信号发射器"（身份 layer + 监视 mask），CollisionShape2D 只是几何；同一 Area2D 挂多个形状会**合并成一个区**，分不清来源——分行为必须分 Area2D
2. **collision_layer / collision_mask**：「我是什么」vs「我监视谁」；单向检测（玩家 mask=2、NPC mask=0）防重复判定
3. **area_entered 信号**：参数就是闯入者的 Area2D，用 `get_parent() as YuNpc` 取回宿主
4. **体型比较与无敌帧**：`tixing > tixing` 大吃小；受伤闪红（modulate）+ Timer 1 秒无敌（能吃不能伤）

## 检查点与证据

### orientation（实现前，2026-10-22）

- [x] 学生理解 layer/mask 保安+监控比喻
- [x] 设计决策 1：**玩家侧单向检测**（选定推荐项）
- [x] 设计决策 2：**无敌期能吃不能伤**（选定推荐项）

### godot-inspection（实现后，2026-10-22）

- [x] 检查器核对两侧 Layer/Mask 勾选
- [x] Radius 22→35 判定范围实验（体验后还原）
- [x] 调试 → 显示碰撞形状，亲眼看判定圈

### verification-handoff（2026-10-22，四条全过）

- [x] 吃小鱼：挡路碰上即消失
- [x] 撞大鱼：闪红 1 秒恢复
- [x] 无敌帧：不连续受伤、期间能吃
- [x] 完整回归：移动/生成/回收正常

## 学生提问（本课亮点）

1. Layer/Mask 数值依据 → 已讲解：项目约定由设计推导，检查器 32 格核对 + 运行时显示碰撞形状
2. **吃的范围变大、被伤范围不变** → 独立发明了第 7 课「磁吸」buff；约定届时实现（ChiQu 大圈 + ShangQu 小圈）
3. 拆双范围是否等于加 CollisionShape2D → 已讲解：形状合并 vs 信号归属的区别

## 学习记录表

| 日期 | 检查点 | 表现 | 待巩固 |
|---|---|---|---|
| 2026-10-22 | orientation | 两个设计决策均选推荐项 | — |
| 2026-10-22 | inspection + verification | 检查器三项操作 + 四条实测全过；三个追问全部触及机制本质（尤其磁吸设想） | 第 7 课磁吸实现时复述"分行为须分 Area2D"的原理 |
