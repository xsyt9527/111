# TASK-006 学习记录：升级三选一

## 学习目标

| # | 目标 | 掌握证据 |
|---|---|---|
| 1 | 复述 Resource 三分工，指出 QiangHuaKa 与 YuZhong 同构 | ⚠️ 及格线（结构✓；.tres="分值"→纠正全部数值；检查器✗→纠正填表入口）；step-01 亲手做了一遍同构流程（applied）——第 7 课前再验 |
| 2 | 解释 get_tree().paused 与 process_mode=WHEN_PAUSED | ✅ F5 亲眼验证冻结全场 + 弹窗可点击；"点卡无反应"中间态被准确识别（applied） |
| 3 | 说不放回抽样三步及必要性 | ✅ 决策即选 A；三卡互不相同、二次组合不同实测确认（applied） |
| 4 | 跟踪选择数据流：按钮 → xuan_ka → yi_xuan_ka + ka_yi_xuan | ✅ 远程树亲见 Yi Xuan Ka 追加（applied） |

## 本课新概念

- **get_tree().paused**：引擎级全局冻结——所有默认 Pausable 节点的 _process/_physics_process/Timer 一律停；信号 emit 不受影响
- **process_mode（When Paused=3）**：节点级豁免权——弹窗根节点独醒，按钮才能在冻结中响应
- **不放回抽样三连**：duplicate（原表不动）→ shuffle（随机性）→ slice(0,3)（天然无重复）
- **常量数据化**：SHENG_JI_YUZHI 退役 → preload .tres，等值切换零行为变化；Autoload 无检查器实例所以用 preload 不用拖
- **场景实例化复用**：弹窗做独立场景再实例化进 Main（自带注册表，可单独编辑）
- **接口预埋**：ka_yi_xuan 信号本课 emit 无消费者——第 7 课一行 connect 即接上

## 检查点与证据

### orientation（实现前）

- [x] 复述抽查 1：Resource 三分工——及格线（结构✓；.tres 只答"分值"→纠正为全部数值；检查器答"鱼种"✗→纠正为改数值的填表入口）；第 7 课前再验
- [x] 复述抽查 2：账本位置——基本过关（销毁连带 ✓；"全局"→纠正为"场景树根 root"，全局是效果不是位置）
- [x] 设计决策 1：A——注册表模式复用（加卡零代码）
- [x] 设计决策 2：A——get_tree().paused + WHEN_PAUSED（引擎级冻结，新系统自动继承）

### godot-inspection（step-03 后）

- [x] 双击 .tres 看卡数据（含磁吸卡）
- [x] F5 验证冻结 + 弹卡 + process_mode 生效（"可以选择，也有冻结"）
- [x] 改阈值表实验后**当场还原**（git diff 复核无残留——本次纪律执行到位，上次的账销掉）
- 亮点：发现 Node not found 报错（真人测试暴露自动化盲区）；准确识别"点卡无反应"是预期中间态而非 bug

### verification-handoff（实现后）

- [x] 升级瞬间全场冻结、弹 3 张互不相同的卡
- [x] 点选一张立即恢复游动；远程树 Yi Xuan Ka 追加
- [x] 两次升级两次弹窗、卡组合随机不同
- [x] 全量回归：移动/生成/回收/判定/无敌/涨条/长大（学生确认"都对"）

## 学生提问

- "报错了"（step-03 后 F5）——真人测试发现自动化盲区，Node not found 定位为 $ 路径少算层级；检查方式升级为输出筛查
- "现在的冻结包括了选择，只能点，没作用"——准确识别 step-04 预期中间态，非 bug

## 学习记录表

| 日期 | 检查点 | 表现 | 待巩固 |
|---|---|---|---|
| 2026-10-23 | orientation + godot-inspection + verification 全流程 | 设计决策 1A 2A；两项复述抽查及格线（账本位置/三分工细节被纠正）；F5 验证冻结弹卡 + 点选中间态识别准确；阈值实验**当场还原**（纪律账销掉）；发现 Node not found 报错帮自动化查漏；四条验证全过 | Resource 三分工细节（.tres=全部数值、检查器=填表入口）第 7 课开场再验 |
