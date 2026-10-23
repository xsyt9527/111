# TASK-006 学习记录：升级三选一

## 学习目标

| # | 目标 | 掌握证据 |
|---|---|---|
| 1 | 复述 Resource 三分工（第 4 课遗留抽查），指出 QiangHuaKa 与 YuZhong 同构 | （待 orientation） |
| 2 | 解释 get_tree().paused 为何一行冻结全场、弹窗为何必须 process_mode=WHEN_PAUSED | （待 orientation） |
| 3 | 说出不放回抽样三步（duplicate→shuffle→slice）及每步必要性 | （待讲解+inspection） |
| 4 | 跟踪选择数据流：按钮 → xuan_ka(ka) → yi_xuan_ka + ka_yi_xuan 信号（第 7 课消费） | （待验证） |

## 本课新概念

（实现后填写）

## 检查点与证据

### orientation（实现前）

- [ ] 复述抽查 1：Resource 三分工（第 4 课遗留）
- [ ] 复述抽查 2：账本为何不挂 Main 下（第 5 课遗留）
- [ ] 设计决策 1：强化卡数据形态（A. 注册表模式复用 / B. 脚本硬编码）
- [ ] 设计决策 2：暂停实现方式（A. get_tree().paused + WHEN_PAUSED / B. 手动停各系统）

### godot-inspection（step-03 后）

- [ ] 双击 data/qianghua/ci_xi.tres 看磁吸卡四字段（自己提案的卡！）
- [ ] 检查器看 QiangHuaDanChuang 根节点 Process Mode = When Paused
- [ ] 改阈值表实验（如首项 8→3 快速触发弹窗），观察后**当场还原**

### verification-handoff（实现后）

- [ ] 升级瞬间全场冻结、弹 3 张互不相同的卡
- [ ] 点选一张立即恢复游动；远程树 Yi Xuan Ka 追加
- [ ] 两次升级两次弹窗、卡组合随机不同
- [ ] 全量回归：移动/生成/回收/判定/无敌/涨条/长大

## 学生提问

（随课程记录）

## 学习记录表

| 日期 | 检查点 | 表现 | 待巩固 |
|---|---|---|---|
| （待填写） | | | |
