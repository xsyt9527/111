# TASK-003 交接说明（INTEGRATION_HANDOFF）

## 交付物

| 类型 | 路径 | 说明 |
|---|---|---|
| 修改 | `scenes/Yu.tscn` | 追加 PandingQu(Area2D) + CollisionShape2D + WudiDingshi(Timer) |
| 修改 | `scripts/yu.gd` | 追加 tixing/wudi、area_entered 判定、_shoushang()/_jiechu_wudi() |
| 修改 | `scenes/YuNpc.tscn` | 追加 PandingQu(Area2D, layer=2, mask=0) + CollisionShape2D |
| 修改 | `scripts/yu_npc.gd` | 追加 bei_chi() |

## 提供给后续任务的接口

| 接口 | 形态 | 使用者 |
|---|---|---|
| `Yu.tixing` | float，默认 1.0，只读 | TASK-005 成长（长大后能吃的鱼变多） |
| `YuNpc.bei_chi()` | 方法 | TASK-005 经验记账的挂钩点 |
| `Yu._shoushang()` | 方法 | TASK-008 血量/死亡的挂钩点 |
| 碰撞层约定 | Layer1=玩家 / Layer2=鱼群 | 后续所有物理任务沿用（新阵营加新层） |

## 场景树（交付后）

```
Main (Node2D)
├─ Haodi (Sprite2D)
├─ Yu (Yu.tscn)
│  ├─ Sprite2D
│  ├─ PandingQu (Area2D, layer=1, mask=2)
│  │  └─ CollisionShape2D (CircleShape2D r=22)
│  └─ WudiDingshi (Timer, one_shot, 1.0s)
└─ YuQun (yu_qun.gd)
   ├─ Dingshi (Timer, one_shot)
   └─ YuNpc × N（运行时）
       ├─ Sprite2D
       └─ PandingQu (Area2D, layer=2, mask=0)
           └─ CollisionShape2D (CircleShape2D r=22，随 tixing 缩放)
```

## 已知限制 / 后续任务注意

1. 无经验/分数：被吃的鱼只是消失（TASK-005 在 `bei_chi()` 入口记账）
2. 无血量：受伤只有表现（TASK-008 在 `_shoushang()` 入口扣血）
3. 无吞吃特效：瞬间消失略生硬（第 7 课 Tween 做缩放消失 + 涟漪）
4. 判定圈半径 22 是初值，手感调优留到第 7 课统一做
5. `area.get_parent()` 依赖 Area2D 是宿主直接子节点——若以后在 NPC 里加中间容器节点需同步改取法
6. 无敌期间"能吃不能伤"是当前规则；若第 7 课做护盾 buff 可复用 wudi 标记

## 集成检查清单

- [ ] 任务包通过 validate_task.py
- [ ] headless 导入退出码 0
- [ ] headless --fixed-fps 60 --quit-after 360 退出码 0
- [ ] check_task_scope.py 无违例
- [ ] 学生 verification-handoff 完成
- [ ] LEARNING_ROADMAP / TASK_INDEX / 引擎词总表（md + docx）更新
