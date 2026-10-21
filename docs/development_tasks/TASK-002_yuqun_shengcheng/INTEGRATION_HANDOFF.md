# TASK-002 交接说明（INTEGRATION_HANDOFF）

## 交付物

| 类型 | 路径 | 说明 |
|---|---|---|
| 场景 | `scenes/YuNpc.tscn` | NPC 鱼蓝图（Node2D + Sprite2D） |
| 脚本 | `scripts/yu_npc.gd` | 随机外观、横向游动、出屏 queue_free |
| 脚本 | `scripts/yu_qun.gd` | Timer 驱动生成器：随机间隔、两侧边缘、数量上限 |
| 修改 | `scenes/Main.tscn` | 追加 YuQun(Dingshi) 子树 |
| 修改 | `scripts/main.gd` | 删除调试 print（逻辑未变） |

## 提供给后续任务的接口

| 接口 | 形态 | 使用者 |
|---|---|---|
| `YuNpc.tixing` | float 0.6~1.6 | TASK-003 大小比较 |
| `YuNpc.sudu` / `YuNpc.fangxiang` | float | 生成器写入；TASK-003 可选用于追逐 |
| `YuQun` 四个 @export | 检查器参数 | 难度调参 |

## 场景树（交付后）

```
Main (Node2D)
├─ Haodi (Sprite2D)
├─ Yu (Yu.tscn)
└─ YuQun (yu_qun.gd)
   ├─ Dingshi (Timer, one_shot)
   └─ YuNpc × N（运行时）
```

## 已知限制 / 后续任务注意

1. NPC 与玩家暂无碰撞，视觉上会互相穿过（TASK-003 解决）
2. 无对象池：高频生成时 instantiate/queue_free 有开销；当前上限 14 足够
3. `zuida_shuliang` 统计只数 `is YuNpc` 的子节点，若以后给 YuQun 加其他子节点无需调整
4. YuNpc 只有横向直线运动，无上下起伏（第 7 课动画）
5. 若 TASK-004 引入鱼种 Resource，`tie_tu_shu_zu` / `tixing_fanwei` 将由数据表替代

## 集成检查清单

- [x] 任务包通过 validate_task.py
- [ ] headless 导入退出码 0
- [ ] headless --quit-after 300 退出码 0
- [ ] check_task_scope.py 无违例
- [ ] 学生 verification-handoff 完成
- [ ] LEARNING_ROADMAP / TASK_INDEX / 引擎词总表更新
