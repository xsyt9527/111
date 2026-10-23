# TASK-004 学习记录：数据驱动鱼种

## 学习目标

| # | 目标 | 掌握证据 |
|---|---|---|
| 1 | 定位贴图数组的两处硬编码，说出"加新鱼要改场景"的结构问题 | orientation 讲解中定位 ✅ |
| 2 | 解释 Resource 三分工：脚本=模具 / .tres=数据 / 检查器=填表 | orientation 决策 + 改表实验 ✅ |
| 3 | 跟踪数据流：.tres → 生成器抽取 → 注入 → _ready 消费 | inspection + verification 全程 ✅ |
| 4 | 编辑器检查 .tres、改字段 F5 实验、还原 | inspection 三项操作 ✅ |

## 本课新概念

1. **自定义 Resource**：`extends Resource` + `class_name` + `@export` 字段 = 数据模具；实例是纯数据容器，不是场景节点
2. **.tres 资源文件**：填好数据的 Resource 存成磁盘文件；`script_class` 标记用哪个模具解析；双击即检查器编辑
3. **资源注入顺序**：生成器 `add_child()` 前赋 `yu_zhong`，`_ready()` 消费——与 TASK-002 的 sudu/fangxiang 同款约定
4. **注册表模式**：`Array[YuZhong]` 检查器拖入 + `pick_random()` 抽取——加新鱼零代码

## 检查点与证据

### orientation（实现前，2026-10-22）

- [x] 学生定位当前贴图数组的两处硬编码（讲解中对照 YuNpc.tscn / yu_npc.gd）
- [x] 设计决策 1：**A. 检查器拖入 Array[YuZhong] 注册表**（选定推荐项，不用运行时扫描）
- [x] 设计决策 2：**A. 游速归鱼种表管**（选定推荐项，种族速度与贴图成套）

### godot-inspection（实现后，2026-10-22，三项全过）

- [x] 编辑器 New Resource… 看到 YuZhong 字段（未保存落地）
- [x] 双击检查 zong_yu.tres 内容与字段
- [x] 改 lan_yu.tres 体型范围 F5 实验（蓝鱼整体变大），观察后还原——自评"都很棒"

### verification-handoff（2026-10-23，三条全过）

- [x] 同种成套：同贴图的鱼体型/速度相近，蓝红小、棕粉大、粉快于棕
- [x] 判定回归：吃小鱼、撞大鱼闪红无退化
- [x] 全量回归：跟随移动、随机间隔生成、同屏上限、出屏回收正常

## 学生提问

（本课无阻塞性提问；检查点操作一次通过）

## 学习记录表

| 日期 | 检查点 | 表现 | 待巩固 |
|---|---|---|---|
| 2026-10-22 | orientation | 两个设计决策均选推荐项（1A 2A） | — |
| 2026-10-22 | godot-inspection | 编辑器三项一次全过；改表实验亲证"零代码改整种鱼" | 第 6 课强化卡做 QiangHuaKa.tres 时复述"模具/数据/填表"三分工 |
| 2026-10-23 | verification | F5 三条全过 | — |
