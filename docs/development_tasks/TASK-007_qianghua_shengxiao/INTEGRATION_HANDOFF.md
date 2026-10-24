# TASK-007 交接说明（INTEGRATION_HANDOFF）

## 交付物

| 类型 | 路径 | 说明 |
|---|---|---|
| 修改 | `scripts/yu.gd` | +`_on_ka_yi_xuan` match 六分支（push_warning 兜底）+ ChiQu 吸附标记 + Tween 平滑长大/吞吃脉冲 + sin 摆尾 + 引用改名 ShangQu + `mei_ji_fu_dian`/`bai_shi_jian` |
| 修改 | `scripts/yu_npc.gd` | +`bei_xi` 吸附标记（被吸自追 ×1.2 速）+ `bei_chi` 乘账本倍率 |
| 修改 | `scripts/zhang_ben.gd` | +`jing_yan_jia_cheng`（默认 1.0）+ `she_jing_yan_jia_cheng()` 唯一入口 |
| 修改 | `scenes/Yu.tscn` | PandingQu 改名 ShangQu（r=22 判定）+ 新增 ChiQu（r=90 吸附），各独立 CollisionShape2D |

零新增资源文件；动画全为运行时 Tween/sin。

## 提供给后续任务的接口

| 接口 | 形态 | 使用者 |
|---|---|---|
| `ZhangBen.jing_yan_jia_cheng` + `she_jing_yan_jia_cheng()` | 账本倍率 | TASK-008 结算页可展示 build 收益；第 9 课测试断言 |
| yu.gd `_on_ka_yi_xuan` match 分发模式 | 代码模式 | 后续新增卡型：.tres + match 分支两处（键必带 push_warning 兜底惯例） |
| Yu 双 Area2D 结构（ChiQu 吸附 / ShangQu 判定） | 场景结构 | 后续范围类 buff 照抄双圈分职 |
| `YuNpc.bei_xi` | 吸附标记 | TASK-008 死亡清理时注意悬空引用（见 CODE_REVIEW P3-2） |

## 场景树（交付后）

```
root
├─ ZhangBen (zhang_ben.gd, Autoload)  ← +jing_yan_jia_cheng +she_jing_yan_jia_cheng（TASK-007）
└─ Main (Node2D)
   ├─ Haodi / JingYanTiao / QiangHuaDanChuang / YuQun   ← 零改动
   └─ Yu (Yu.tscn)
      ├─ Sprite2D  ← 摆尾 rotation（sin 驱动）
      ├─ ShangQu (Area2D, mask=2)  ← 原 PandingQu 改名，吃/伤判定 r=22 不变
      │  └─ CollisionShape2D
      ├─ ChiQu (Area2D, mask=2)  ← TASK-007 新增，吸附标记 r=90
      │  └─ CollisionShape2D
      └─ WudiDingshi (Timer)  ← wait_time 随活力卡乘算
```

## 已知限制 / 后续任务注意

1. **贪食放大受伤范围**（方案 A，学生知情决策）——TASK-008 血量上线时重新评估嘴/身拆分（CODE_REVIEW P3-1）
2. **bei_xi 悬空引用**——玩家若在 TASK-008 会死亡/销毁，销毁前需清标记或 is_instance_valid 防御（P3-2）
3. **升级与吞吃 tween 同帧轻微抖动**——终态不漂移；手感可感时用 Tween.kill()（P3-3）
4. **xiao_guo 全键校验**——第 9 课加断言：遍历卡池逐张触发，零 push_warning（P3-4）
5. Resource 三分工（.gd 模具 / .tres 全部数值）学生第 4 次挂账——第 9 课测试写 .tres 时再验

## 集成检查清单

- [x] 任务包通过 validate_task.py（v1，生成/审批两次 VALID）
- [x] headless 导入 0 错误（输出筛查，每步）
- [x] headless 360 帧零错误（输出筛查，每步）
- [x] check_task_scope.py 无违例（7 allowed, 0 violation）
- [x] 学生 godot-inspection 完成（双圈/磁吸边界/改名回归/五卡补验"都ok了"）
- [x] 学生 verification-handoff 完成（六卡 + 三动画 + 全量回归"都对"）
- [x] LEARNING_ROADMAP / TASK_INDEX / 引擎词总表（md + docx）已更新
