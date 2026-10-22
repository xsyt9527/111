# 项目状态审计 — 深海食纪

> 第四次审计（第 4 课前），生成于 2026-10-22。

## 审计新鲜度

```yaml
audited_commit: d945087669e412e7   # TASK-003 状态关闭提交，工作区干净
environment_checked_at: 2026-10-22T07:30:00Z
engine_executable_source: common_path   # D:\001\Godot_v4.7.2-stable_win64.exe
engine_version_detected: 4.7.2          # 4.7.2.stable.official.ed1daf0bf
audit_invalidation_triggers:
  - project.godot 结构性修改（Autoload/主场景/输入映射/插件）
  - 引擎版本变化
  - 新增或变更共享配置、存档结构、事件总线、数据资源
  - 任何 TASK 基线 commit 变化后未重新审计受影响区域
```

## 工程状态清单

| 系统 | 状态 | 证据 |
|---|---|---|
| Git 仓库 | ✅ 干净，HEAD `d945087` | `git status --porcelain` 为空 |
| project.godot | ✅ 主场景 `res://scenes/Main.tscn`；无 Autoload/插件；本课无需改动 | TASK-003 后未动 |
| 场景 scenes/ | ✅ Yu.tscn（+PandingQu/WudiDingshi）、YuNpc.tscn（+PandingQu）、Main.tscn | TASK-003 交付 |
| 脚本 scripts/ | ✅ main.gd、yu.gd（判定+无敌）、yu_npc.gd（bei_chi）、yu_qun.gd | TASK-003 交付 |
| 判定系统 | ✅ 玩家 mask=2 单向检测，tixing 比较大吃小，闪红+1 秒无敌 | 学生四条实测全过 |
| 数据 data/ | **Missing**（本课 TASK-004 启用） | 尚不存在 |
| 测试 tests/ | **Missing**（第 9 课启用） | 尚不存在 |
| 素材 | ✅ Kenney Fish Pack 就位（6 种 fish_*.png 在用） | CC0 |
| 教材工具 | ✅ 词表 md 与 docx 同步（15 章节 11 表格） | TASK-003 收尾时重生成 |
| 任务流程 | ✅ TASK-001/002/003 全关闭 | `last_verified_commit=885c001` |

### 运行行为现状（实测基线）

- F5：玩家跟随手指；鱼群从两侧随机游入（贴图/体型 0.6~1.6/游速随机），同屏上限 14，出屏自动回收
- 玩家撞小鱼→被吃（消失）；撞大鱼→闪红 1 秒无敌（期间能吃不能伤）
- NPC 外观由**检查器里手动维护的 6 贴图数组**决定——本课要把它换成数据文件

## 已知遗留

- 无未了债务。TASK-003 的 4 条 P3 备注（get_parent 结构依赖、半径 22 初值、无吞吃特效、无音效）已记录在案，分属第 5/7/8 课处理
- NPC 的贴图数组 `tie_tu_shu_zu` 与体型范围 `tixing_fanwei` 是两处独立 @export——**加新鱼要改场景文件**，这是本课要解决的结构问题

无行为对照工程（development_strategy=plan_driven）。

## 推荐的接下来三个有界任务（按依赖和学习价值排序）

1. **TASK-004 数据驱动鱼种**（本审计选定）：自定义 Resource（`YuZhong`）+ 6 个 .tres 鱼种表；
   YuNpc 从"看数组"改成"看数据"，YuQun 检查器拖入鱼种表——加新鱼不改代码。
2. **TASK-005 经验与成长**：吃鱼涨经验（`bei_chi()` 入口记账，用上本课鱼种表的 `fenzhi`）、玩家 tixing 长大、Autoload 游戏账本。
3. **TASK-006 升级三选一**：get_tree().paused 模态 + 随机不放回抽样。

## 结论

玩法核心已成立，但"鱼是什么样"还写死在场景的检查器数组里。本课把外观数据搬进 .tres 资源文件，学会 Resource 注册表模式——这是第 5 课经验数值和第 6 课强化卡的数据地基。
