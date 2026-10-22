# TASK-004 范围提案：数据驱动鱼种

## 任务概要

**做什么**：新建一个自定义 **Resource** 类 `YuZhong`（鱼种模具：贴图/等级/体型范围/游速范围/分值），为 6 种鱼各做一个 **.tres 数据文件**；NPC 鱼从"读检查器数组"改成"读鱼种数据"；生成器 YuQun 检查器拖入鱼种表，生成时随机抽一种赋给新鱼。

**为什么是它**：现在加一种新鱼要改 `YuNpc.tscn` 的贴图数组——外观数据写死在场景里。本课之后，**加新鱼 = 新建一个 .tres 填几个字段再拖进数组，一行代码不改**。这也是第 5 课经验数值（`fenzhi`）和第 6 课强化卡的数据地基。

**可观察结果**：F5 里鱼群照常游动，但**同种鱼外观成套**（贴图与体型/速度绑定）：蓝鱼小而慢、棕鱼大而慢、粉鱼大而快；改一个 .tres 的字段再 F5，对应鱼种整体变化；其他行为无退化。

## 控制变量

| 变量 | 取值 | 理由 |
|---|---|---|
| development_strategy | plan_driven | 无行为对照工程 |
| participation_mode | guided_co_development | 沿用既定教学约定 |
| execution_mode | teaching | 每步一个新概念 + 检查点停顿 |

## 功能所有权

- owner：student-01
- 新建：`scripts/yu_zhong.gd`（+ .uid）、`data/yuzhong/*.tres` × 6
- 修改 4 文件：`yu_npc.gd`（贴图/体型来源换成 yu_zhong，游动/回收/bei_chi 逻辑不动）、`yu_qun.gd`（生成时抽鱼种赋值，间隔/上限/边缘逻辑不动）、`YuNpc.tscn`（清掉 6 贴图 ext_resource 与 tie_tu_shu_zu）、`Main.tscn`（YuQun 拖入 6 个鱼种表）
- **零修改**：`yu.gd`、`Yu.tscn`、`main.gd`、`project.godot`

## 集成合同

- 消费：无新消费；`Yu.tixing` 比较逻辑不变（NPC 的 tixing 仍由 _ready 随机产生，只是范围来自鱼种表）
- 提供给 TASK-005：`YuZhong.fenzhi`（吃掉一条该种鱼得多少分）、`YuZhong.dengji`（鱼种等级）、`YuNpc.yu_zhong`（被吃时能查到自己是哪种鱼）
- 提供：鱼种表模式（第 6 课强化卡可复用"数据文件 + 代码模具"套路）
- 无新信号、无 Autoload、无 project.godot 变更

## 学习价值与学生参与

| Step | 行为 | 新概念 |
|---|---|---|
| 01 | 写 yu_zhong.gd 模具类 | **自定义 Resource：代码定义结构，检查器填数据** |
| 02 | 建 6 个 .tres 鱼种文件 | **.tres 资源文件：数据的实体文件** |
| 03 | YuNpc 改读 yu_zhong | 资源实例注入（生成前赋值，_ready 消费） |
| 04 | YuQun 抽鱼种 + Main 拖表 | **类型化资源数组 Array[YuZhong] 注册表** |

三个检查点：
1. **orientation**：定位当前贴图数组在哪里 + 理解"模具 vs 数据"分离 + 二选一设计决策 ×2
2. **godot-inspection**：编辑器新建 Resource 看到 YuZhong 字段（不保存）；双击检查 .tres；改一个鱼种字段做 F5 实验后还原
3. **verification-handoff**：F5 亲测四条（同种成套/速度差异/改表生效/全量回归）

## 场景架构影响

- architecture_change = false：Main/Yu/YuQun/YuNpc 生命周期全部不变，无新增节点；只是数据来源从场景内数组换成外部 .tres 资源
- 资源加载方式：.tres 经 ext_resource 静态引用（编译期确定），非运行时动态扫描

## 排除项（本任务不做）

- 经验/分数记账（TASK-005）——`fenzhi` 字段只存数据不消费
- 玩家成长、强化卡、动画（第 5/6/7 课）
- 运行时扫描文件夹自动注册鱼种（DirAccess 方案——导出 APK 有 .remap 坑，属进阶话题，见设计决策 1 的 B 选项说明）
- 按鱼种等级限制出场时机（难度曲线属 TASK-005 之后）

## 风险与阻塞

- 无已知阻塞。手写 .tres 引用贴图若缺 uid 属性，编辑器保存时会自动补上——文件已在白名单内，属预期内变更
- 风险点：`xin_yu.yu_zhong = zhong` 必须在 `add_child()` **之前**（_ready 里要读它）——与 TASK-002 的 sudu/fangxiang 同款注入顺序约定，已写进合同

## 审批方式

任何明确表达「确认 TASK-004 v1 进入开发」的文本均有效。范围变更将生成 v2 并作废本审批。

## 版本记录

- **v1**（2026-10-22，待审批）：初始范围。
