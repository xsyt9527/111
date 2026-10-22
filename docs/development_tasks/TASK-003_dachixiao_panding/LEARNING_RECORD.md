# TASK-003 学习记录：大吃小判定

## 学习目标

| # | 目标 | 掌握证据 |
|---|---|---|
| 1 | 定位两个 PandingQu 子树，说出 Area2D / CollisionShape2D 分工 | orientation 导航 |
| 2 | 解释 layer 与 mask，说明为何玩家 mask=2、NPC mask=0 不重复判定 | orientation 口头说明 |
| 3 | 跟踪判定数据流：area_entered → get_parent → tixing 比较 → bei_chi/_shoushang | 检查点问答 |
| 4 | 检查器核对 Layer/Mask、调半径观察判定范围 | inspection + verification |

## 本课新概念

1. **Area2D 与 CollisionShape2D**：Area2D 是"不可见的检测区 + 信号发射器"，CollisionShape2D 决定区域的形状和大小
2. **collision_layer / collision_mask**：layer 是"我是什么"（别人能检测到我），mask 是"我检测谁"
3. **area_entered 信号**：两个检测区重叠瞬间发出，参数就是对方的 Area2D（复习 signals）
4. **体型比较与无敌帧**：`tixing > tixing` 大吃小；受伤后 Timer 无敌 1 秒防连击（modulate 闪红）

## 检查点与证据

### orientation（实现前）

- [ ] 学生定位 Yu.tscn / YuNpc.tscn 里将新增的 PandingQu 位置
- [ ] 学生用自己的话说出 layer/mask 区别
- [ ] 学生完成二选一设计决策（见检查点提问）
- 记录：待填写

### godot-inspection（实现后）

- [ ] 选中玩家 PandingQu：Layer 1 勾、Mask 2 勾
- [ ] 选中 NPC PandingQu：Layer 2 勾、Mask 全不勾
- [ ] 调整 CollisionShape2D 半径（22 → 35）观察判定范围变大，还原
- 记录：待填写

### verification-handoff（验证）

- [ ] F5 吃小鱼：撞上即消失
- [ ] F5 撞大鱼：闪红 1 秒恢复
- [ ] 无敌帧：连续穿过大鱼只红一次，期间仍能吃
- [ ] 完整回归：移动/生成/回收正常
- 记录：待填写

## 学习记录表

| 日期 | 检查点 | 表现 | 待巩固 |
|---|---|---|---|
| — | — | 待第 3 课实现后填写 | — |
