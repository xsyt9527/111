# 项目状态审计 — 深海食纪

> 第二次审计（第 2 课前），生成于 2026-10-21。

## 审计新鲜度

```yaml
audited_commit: fa2f75add18699e3b5ddb7243ed3f52016c38fc4
environment_checked_at: 2026-10-21T08:48:42Z
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
| Git 仓库 | ✅ 干净，HEAD `fa2f75a` | `git status --short` 为空 |
| project.godot | ✅ 可解析；主场景 `res://scenes/Main.tscn`；无 Autoload/插件 | TASK-001 登记的唯一共享变更 |
| 场景 scenes/ | ✅ Main.tscn（Haodi 背景 + Yu 实例）、Yu.tscn（Node2D+Sprite2D） | TASK-001 交付并验证 |
| 脚本 scripts/ | ✅ main.gd（触摸输入）、yu.gd（玩家移动） | TASK-001 交付并验证 |
| 数据 data/ | **Missing**（第 4 课启用） | 空目录 |
| 测试 tests/ | **Missing**（第 9 课启用） | 空目录 |
| 素材 assets/sucai/kenney_fish/ | ✅ 256 张 PNG 已导入，其中 fish_*.png 多种颜色可用 | Kenney Fish Pack 2.0，CC0 |
| 教材工具 tools/ | ✅ shengcheng_cibiao_docx.py 可生成 Word 词表 | `Godot引擎词总表.docx` 已生成 |
| 任务流程 | ✅ TASK-001 全流程关闭（v4 审批，delivery=complete） | `last_verified_commit=ef7bc3d` |

### 运行行为现状（实测基线）

- F5 进入 Main：海床背景 + 蓝色玩家鱼
- 按住拖动：玩家鱼平滑跟随手指；松手停止；左右拖动鱼头翻转
- 尚无任何 NPC 鱼、无碰撞、无经验/升级系统

## 已知遗留

- `scripts/main.gd` 末尾有一条 TASK-001 调试用 `print("mubiao_dian = ...")`，注释标注「第 2 课前移除」——TASK-002 顺手清理（已登记进白名单）。
- 没有池化、没有相机、没有视差——均非当前阶段问题。

无行为对照工程（development_strategy=plan_driven）。

## 推荐的接下来三个有界任务（按依赖和学习价值排序）

1. **TASK-002 鱼群生成**：Timer 驱动、边缘随机游入、屏幕外自动回收。
   新概念：随机数、Timer/timeout 信号、get_viewport_rect、queue_free 生命周期。
2. **TASK-003 大吃小判定**：Area2D 碰撞 + 体型比较，小鱼被吃、撞大鱼受伤。
   依赖 TASK-002 的 `YuNpc.tixing` 体型接口。
3. **TASK-004 数据驱动鱼种**：鱼种表 .tres（贴图、体型、分值），加新鱼不改代码。
   依赖 TASK-002 的随机外观参数与本课留下的 @export 数组。

## 结论

TASK-001 地基稳固，无遗留债务。下一课直接建立 NPC 鱼蓝图与鱼群生成器，为判定与成长系统准备「可被吃的鱼」。
