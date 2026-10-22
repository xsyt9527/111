# 项目状态审计 — 深海食纪

> 第三次审计（第 3 课前），生成于 2026-10-22。

## 审计新鲜度

```yaml
audited_commit: da0685b7957615d90764651b8038ffd5be6b567f
environment_checked_at: 2026-10-22T03:11:02Z
engine_executable_source: common_path   # D:\001\Godot_v4.7.2-stable_win64.exe
engine_version_detected: 4.7.2          # 4.7.2.stable.official.ed1daf0bf
audit_invalidation_triggers:
  - project.godot 结构性修改（Autoload/主场景/输入映射/插件）
  - 引擎版本变化
  - 新增或变更共享配置、存档结构、事件总线
  - 任何 TASK 基线 commit 变化后未重新审计受影响区域
```

## 工程状态清单

| 系统 | 状态 | 证据 |
|---|---|---|
| Git 仓库 | ✅ 干净，HEAD `da0685b` | `git status --short` 为空 |
| project.godot | ✅ 主场景 `res://scenes/Main.tscn`；无 Autoload/插件；本课无需改动 | TASK-002 后未动 |
| 场景 scenes/ | ✅ Main.tscn（Haodi + Yu + YuQun→Dingshi）、Yu.tscn、YuNpc.tscn（6 贴图随机） | TASK-002 交付 |
| 脚本 scripts/ | ✅ main.gd（输入）、yu.gd（玩家移动）、yu_npc.gd（NPC 随机/游动/回收）、yu_qun.gd（生成器） | TASK-002 交付 |
| 数据 data/ | **Missing**（第 4 课启用） | 空目录 |
| 测试 tests/ | **Missing**（第 9 课启用） | 空目录 |
| 素材 | ✅ Kenney Fish Pack 就位 | CC0 |
| 教材工具 | ✅ 词表 docx 与 md 同步（11 章节 8 表格） | TASK-002 收尾时重生成 |
| 任务流程 | ✅ TASK-001/002 全关闭；学习证据含 explained 级 | `last_verified_commit=529fec7` |

### 运行行为现状（实测基线）

- F5：海床背景 + 玩家鱼（tixing 概念上为 1.0）+ 鱼群从两侧游入（随机贴图/体型 0.6~1.6/速度，同屏上限 14）
- 玩家与 NPC **互相穿过，无任何碰撞判定**——这是本课要解决的
- NPC 游出屏幕自动释放；玩家按住拖动跟随

## 已知遗留

- 无未了债务。TASK-002 的 P3 备注（get_viewport_rect 每帧调用、flip_h 顺序约定）已记录在案，不在本课处理
- 玩家尚无 `tixing` 成员（TASK-003 将引入）；NPC 已有 `tixing`（TASK-002 接口）

无行为对照工程（development_strategy=plan_driven）。

## 推荐的接下来三个有界任务（按依赖和学习价值排序）

1. **TASK-003 大吃小判定**：Area2D + CollisionShape2D + 碰撞层/掩码 + area_entered 信号；
   比较 `Yu.tixing` 与 `YuNpc.tixing`：大吃小（NPC 释放）、撞大鱼受伤（闪红 + 1 秒无敌）。
2. **TASK-004 数据驱动鱼种**：鱼种表 .tres（贴图、体型范围、分值），替换 @export 数组。
3. **TASK-005 经验与成长**：吃鱼涨经验、玩家 tixing 变大、Autoload 游戏账本。

## 结论

两条鱼（玩家与 NPC）都已就位但互不相识。本课用物理检测区把它们接上，玩法核心「大鱼吃小鱼」正式成立。
