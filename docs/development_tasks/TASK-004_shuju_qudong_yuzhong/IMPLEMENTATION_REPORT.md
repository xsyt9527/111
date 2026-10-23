# TASK-004 实现报告

## 概要

四步全部实现并通过自动检查：自定义 Resource 类 `YuZhong`（五字段鱼种模具）→ 6 个 `.tres` 鱼种数据文件 → NPC 外观/体型/速度来源从检查器数组切换为注入的鱼种资源 → 生成器注册表抽取 + Main 场景拖入鱼种表。**加新鱼 = 新建 .tres 填字段 + 拖进数组，零代码改动。**

## 分步交付

| Step | 内容 | 文件 | 自动检查 |
|---|---|---|---|
| 01 | 鱼种模具类 | scripts/yu_zhong.gd（+ .uid） | --headless --import 退出码 0 |
| 02 | 六行鱼种表 | data/yuzhong/*.tres × 6 | --headless --import 退出码 0 |
| 03 | NPC 换数据来源 | scripts/yu_npc.gd、scenes/YuNpc.tscn | import 0 错误 + 360 帧运行 0 错误 |
| 04 | 注册表接线 | scripts/yu_qun.gd、scenes/Main.tscn | import 0 错误 + 360 帧运行 0 错误 |

## 数据表（交付值）

| 鱼种 | 贴图 | dengji | tixing_fanwei | sudu_fanwei | fenzhi |
|---|---|---|---|---|---|
| lan_yu | fish_blue | 1 | (0.5, 0.8) | (60, 100) | 1 |
| hong_yu | fish_red | 1 | (0.6, 0.9) | (80, 120) | 1 |
| lv_yu | fish_green | 2 | (0.9, 1.2) | (70, 110) | 2 |
| cheng_yu | fish_orange | 2 | (1.0, 1.3) | (90, 130) | 3 |
| zong_yu | fish_brown | 3 | (1.2, 1.5) | (55, 90) | 5 |
| fen_yu | fish_pink | 3 | (1.3, 1.6) | (100, 140) | 5 |

## 设计决策（学生选定，均为推荐项）

1. 鱼种表经检查器拖入 `Array[YuZhong]` 注册表（不采用运行时 DirAccess 扫描——导出 .remap 坑）
2. 游速归鱼种表管（种族速度与贴图成套）

## 过程记录

- **重复实现事故与处置**：实现过程中发现提交 `7da2684`（2026-10-22 16:00:48，用户 git 身份）已包含与本规格功能等价的完整实现（来源无法从本会话行为追溯，疑似并行/此前一次执行）。逐字节比对确认等价、`.tres` 带编辑器规范化 uid（更规范）后，**采用该提交为权威版本**；会话内重复手写版经核实等价后 stash 备份（`git stash list` 可见，确认后可 drop）。
- **uid 链一致性**：`yu_zhong.gd.uid`（uid://coi0pm6q5sdc）、6 个 `.tres` 的 script 引用、Main.tscn 的资源引用三层一致；学生检查点实验后编辑器又为 lan_yu.tres 补了资源 uid（uid://bb38ynj8rbphg）并同步进 Main.tscn——预期内规范化。
- **一次性探针**（用后已删）：加载 Main.tscn → 实例化 → 直接调 `_shengcheng_yi_tiao()`，验证注册表 6 条全加载、注入的鱼种带贴图、速度落在对应鱼种区间内。两轮（手写版/提交版）均 TONGGUO。

## 行为变化清单

- 同种鱼外观/体型/速度成套（此前贴图与体型独立随机）
- 生成速度由鱼种表决定（此前生成器统一区间 60~160）
- NPC 无鱼种数据时兜底（体型 0.6~1.6、无贴图、sudu=100）——检查器清空注册表也不崩
- 判定系统（吃/伤/无敌）零改动，行为无退化（学生实测确认）
