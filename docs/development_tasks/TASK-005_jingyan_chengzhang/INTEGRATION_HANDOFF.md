# TASK-005 交接说明（INTEGRATION_HANDOFF）

## 交付物

| 类型 | 路径 | 说明 |
|---|---|---|
| 新建 | `scripts/zhang_ben.gd` | Autoload 游戏账本（经验/等级唯一所有者 + 双信号广播） |
| 新建 | `scripts/jing_yan_ui.gd` | 经验条 UI 脚本（CanvasLayer，纯监听无状态） |
| 修改 | `project.godot` | [autoload] 段注册 ZhangBen（本项目首个 Autoload，星号启用） |
| 修改 | `scripts/yu_npc.gd` | bei_chi() 判空记账两行（兜底鱼不给经验） |
| 修改 | `scripts/yu.gd` | _ready 连 sheng_ji + _on_sheng_ji 长大（tixing += 0.2） |
| 修改 | `scenes/Main.tscn` | JingYanTiao(CanvasLayer) UI 子树（ProgressBar 600×20 + Lv 标签） |

## 提供给后续任务的接口

| 接口 | 形态 | 使用者 |
|---|---|---|
| `ZhangBen` | Autoload 单例（root 直下，与 Main 平级） | 全项目任意脚本按名直呼 |
| `ZhangBen.jia_jing_yan(fen)` | 唯一记账入口 | TASK-008 受伤/结算可复用同款入口模式（负数入口另议） |
| `ZhangBen.sheng_ji(xin_deng_ji)` | 信号 | **TASK-006 三选一弹窗的触发时机**：弹窗只需自己 connect，账本零改动 |
| `ZhangBen.jing_yan_bian_hua(jy, yz)` | 信号 | UI/结算页读进度；已连经验条 |
| `ZhangBen.MEI_JI_TIXING` / `SHENG_JI_YUZHI` | 常量 | 第 6 课强化卡若涉体型/阈值在此扩展（阈值数据化在此兑现） |

## 场景树（交付后）

```
root
├─ ZhangBen (Autoload)          ← TASK-005（先于场景就绪、切场景不销毁）
└─ Main (Node2D)
   ├─ Haodi (Sprite2D)
   ├─ Yu (Yu.tscn 实例)          ← 听 sheng_ji 长大（判定圈随 scale 白送变大）
   ├─ YuQun (yu_qun.gd)
   │  ├─ yu_zhong_zu = Array[YuZhong](6 种 .tres)
   │  ├─ Dingshi (Timer)
   │  └─ YuNpc × N（bei_chi 时报 fenzhi 入账）
   └─ JingYanTiao (CanvasLayer, jing_yan_ui.gd)   ← TASK-005
      ├─ JingYanTiaoBg (ProgressBar, 340,24 起 600×20)
      └─ DengJiLabel (Label, "Lv.1")
```

## 已知限制 / 后续任务注意

1. **满级（Lv.7 后）经验仍入账但条停满格**——第 6 课决策满级表现
2. **阈值是脚本常量**（设计决策 1）——第 6 课与强化卡一起 .tres 数据化
3. **无账本重置入口**——第 8 课死亡重开需要 chong_zhi()，玩家 tixing 与 UI 需同步归位（可加 chong_zhi 信号或复用现有信号）
4. **升级瞬间无动画**（瞬间跳变）——第 7 课 Tween 平滑成长
5. **白板兜底鱼不给经验**——符合设计；第 9 课测试可加断言

## 集成检查清单

- [x] 任务包通过 validate_task.py（v1）
- [x] headless 导入退出码 0（0 错误）
- [x] headless --fixed-fps 60 --quit-after 360 退出码 0（真实退出码复核）
- [x] check_task_scope.py 无违例（12 allowed, 0 violation）
- [x] 学生 godot-inspection 完成（2026-10-23，三项全过；实验参数还原遗漏已当场纠正）
- [x] 学生 verification-handoff 完成（2026-10-23，四条全过 + CanvasLayer 概念辨析）
- [x] LEARNING_ROADMAP / TASK_INDEX / 引擎词总表（md + docx）已更新
