# TASK-004 交接说明（INTEGRATION_HANDOFF）

## 交付物

| 类型 | 路径 | 说明 |
|---|---|---|
| 新建 | `scripts/yu_zhong.gd` | 鱼种数据模具（Resource 类，五字段） |
| 新建 | `data/yuzhong/*.tres` × 6 | 鱼种数据文件（蓝/红/绿/橙/棕/粉，带稳定 uid） |
| 修改 | `scripts/yu_npc.gd` | 外观/体型来源改为 yu_zhong 注入（游动/回收/bei_chi 不动） |
| 修改 | `scripts/yu_qun.gd` | 生成时抽鱼种并注入（间隔/上限/边缘逻辑不动） |
| 修改 | `scenes/YuNpc.tscn` | 清掉贴图数组与 ext_resource |
| 修改 | `scenes/Main.tscn` | YuQun 拖入 6 个鱼种表（yu_zhong_zu 数组） |

## 提供给后续任务的接口

| 接口 | 形态 | 使用者 |
|---|---|---|
| `YuZhong` | Resource 类（tie_tu/dengji/tixing_fanwei/sudu_fanwei/fenzhi） | 所有数据消费方 |
| `YuNpc.yu_zhong` | 属性（生成器 add_child 前注入） | TASK-005 记账时查该鱼 fenzhi/dengji |
| `YuZhong.fenzhi` | int 数据字段（本课只存不读） | TASK-005 经验系统（bei_chi 入口） |
| `YuZhong.dengji` | int 数据字段 | TASK-005+（难度曲线/成长参考） |
| 注册表模式 | 模具 + .tres + Array[YuZhong] | 第 6 课强化卡可直接复用（同套路做 QiangHuaKa.tres） |

## 场景树（交付后）

```
Main (Node2D)
├─ Haodi (Sprite2D)
├─ Yu (Yu.tscn 实例)          ← 零改动
└─ YuQun (yu_qun.gd)
   ├─ yu_zhong_zu = Array[YuZhong]([6 个 data/yuzhong/*.tres])   ← TASK-004
   ├─ Dingshi (Timer, one_shot)
   └─ YuNpc × N（运行时，add_child 前注入 yu_zhong + sudu）
       ├─ Sprite2D（贴图来自鱼种表）
       └─ PandingQu (Area2D, layer=2, mask=0)
           └─ CollisionShape2D (r=22，随 tixing 缩放)
```

## 已知限制 / 后续任务注意

1. fenzhi/dengji 已存数据但无代码消费（TASK-005 在 `bei_chi()` 入口记账，`yu_zhong.fenzhi` 即每口经验）
2. 检查器清空 yu_zhong_zu 会退化"白板鱼"（无贴图、sudu=100）——兜底设计，不崩
3. 类型化数组在 .tscn 里的序列化格式由编辑器决定；手工编辑场景后应开编辑器保存一次
4. 无按等级限制出场（难度曲线留给 TASK-005+）
5. 加新鱼流程：`data/yuzhong/` 右键 New Resource → YuZhong → 填字段 → 拖进 Main 场景 YuQun 的 Yu Zhong Zu 数组——零代码

## 集成检查清单

- [x] 任务包通过 validate_task.py（v1）
- [x] headless 导入退出码 0（0 错误）
- [x] headless --fixed-fps 60 --quit-after 360 退出码 0（0 错误）
- [x] check_task_scope.py 无违例（15 allowed, 0 violation）
- [x] 学生 godot-inspection 完成（2026-10-22，三项全过）
- [x] 学生 verification-handoff 完成（2026-10-23，三条全过）
- [x] LEARNING_ROADMAP / TASK_INDEX / 引擎词总表（md + docx）已更新
