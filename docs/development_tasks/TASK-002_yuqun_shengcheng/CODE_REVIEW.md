# TASK-002 代码评审

> 评审日期：2026-10-22 · 评审方式：缺陷优先自审（AI 主导实现 + 学生验证后）

## 评审范围

`scripts/yu_npc.gd`、`scripts/yu_qun.gd`、`scenes/YuNpc.tscn`、`scenes/Main.tscn`（YuQun 子树）、`scripts/main.gd`（仅删 print）。

## 结论

**通过**。无 P0/P1/P2 缺陷。3 条低优先级备注（P3，不阻塞交付）。

## 发现与备注

| 级别 | 位置 | 内容 | 处置 |
|---|---|---|---|
| P3 | yu_npc.gd `_process` | 每帧调用 `get_viewport_rect()` 取屏宽；上限 14 条鱼时开销可忽略 | 保留现状（教学上"运行时取尺寸"价值大于微优化）；TASK-003+ 若鱼数大增可缓存或换 `VisibleOnScreenNotifier2D` |
| P3 | yu_npc.gd `_ready` | `flip_h` 依赖生成器在 `add_child` **之前**写入 `fangxiang`，属隐式顺序约定 | 已在集成合同与注释中写明；后续若 NPC 需要中途转向，改在 `_process` 每帧判定即可 |
| P3 | yu_qun.gd `_dangqian_yu_shu` | 每轮遍历子节点计数（O(n)，n≤15） | 无需优化；用 `is YuNpc` 过滤避免了把 Dingshi 误计入的典型错误 |

## 正确性要点核对

- Timer `one_shot=true` + 每次 `start()` 重排 `wait_time`：无重复触发、无漂移堆积 ✅
- 信号在 `_ready` 连接一次，Timer 随 YuQun 释放，无泄漏连接 ✅
- `queue_free()` 在 `_process` 中调用，引擎保证当帧末尾安全释放 ✅
- 上限达到时仍会 `_pai_xia_yi_ci()`，不会因满员而停止生成循环 ✅
- 出屏判定用 `-bianju ~ 屏宽+bianju` 双侧边界，与生成位置对称 ✅
- 未触碰 `project.godot`、`yu.gd`、`Yu.tscn`；NPC 与玩家无物理节点（留给 TASK-003）✅

## 与场景架构合同的一致性

实际场景树与 target_tree 一致：`Main → Haodi / Yu / YuQun → Dingshi + YuNpc×N`。生命周期检查四项（首次进入、重复 F5、30 秒稳定性、退出释放）在学生验证与无头长跑中均未见异常。
