# TASK-003 代码评审

> 评审日期：2026-10-22 · 评审方式：缺陷优先自审（AI 主导实现 + 学生四条验证后）

## 评审范围

`scripts/yu.gd`（判定/受伤段）、`scripts/yu_npc.gd`（bei_chi）、`scenes/Yu.tscn`、`scenes/YuNpc.tscn`（PandingQu 子树）。

## 结论

**通过**。无 P0/P1/P2 缺陷。4 条 P3 备注（不阻塞交付）。

## 发现与备注

| 级别 | 位置 | 内容 | 处置 |
|---|---|---|---|
| P3 | yu.gd `_on_panding_qu_entered` | `qu.get_parent() as YuNpc` 依赖"Area2D 是宿主直接子节点"的结构约定 | 已写注释与交接文档；若 NPC 加中间容器需同步改取法 |
| P3 | yu.gd / Yu.tscn | 玩家判定圈 r=22 固定；第 5 课若以根节点 scale 实现长大，子节点自动跟随缩放，无需改代码 | 留给 TASK-005 确认手感 |
| P3 | yu.gd `_shoushang()` | 受伤无音效/无击退，表现仅闪红 | 第 7/8 课统一补反馈 |
| P3 | yu_npc.gd `bei_chi()` | 被吃瞬间消失无过渡 | 第 7 课 Tween 缩放消失；入口已挖好 |

## 正确性要点核对

- 单向检测：玩家 mask=2 唯一监视方，NPC mask=0 → 一次碰撞仅一个信号 ✅
- `area_entered` 参数即对方 Area2D；非 YuNpc 宿主的闯入者被 `as` 转换为 null 后安全忽略 ✅
- 无敌规则：吃分支不查 `wudi`（能吃）、伤分支查 `wudi`（不重复伤）——与学生选定规则一致 ✅
- `WudiDingshi` one_shot + `_shoushang()` 内 `start()`：无重复计时，timeout 恢复 modulate ✅
- 被 `bei_chi()` 的 NPC 连同其 Area2D 一起释放，不产生幽灵判定 ✅
- 移动段（TASK-001）与生成/游动/回收段（TASK-002）零改动，逐行核对 ✅
- 未触碰 `project.godot`、`main.gd`、`yu_qun.gd`、`Main.tscn`（后者仅编辑器 uid 记账，v2 已登记）✅

## 与场景架构合同的一致性

实际场景树与 target_tree 一致（Yu 侧 +NPC 侧各含 PandingQu→CollisionShape2D，Yu 另含 WudiDingshi）。生命周期检查：信号在宿主 `_ready` 连接一次、随宿主释放；被吃 NPC 即时释放无残留；连续 F5 无重复连接。学生四条手动验证 + 无头长跑均未见异常。
