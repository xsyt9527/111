# LEARNING_RECORD · TASK-028

> 状态：`learning_status = not_started`。只记录实际发生的学生参与。

## 1. 学习目标

- 能解释「显影」与「飞入」在时间轴上的差别。
- 能说明为什么九图静态纯函数契约必须保留。
- 能指出 `_jie_shu_yan_chu()` 是唯一收尾入口并解释 `jie_shu` 只发一次。
- 能说明演出期间隐藏 `QiPaoCeng`/设置按钮的原因。

## 2. 计划中的三个检查点

| 检查点 | 学生动作 | 证据类型 | 状态 |
|---|---|---|---|
| orientation | 打开 `di_tu_pin_jie_yan_chu.gd`，指出旧飞入起点与保留 `fei_ru_qi_dian()` 的原因 | `project_navigation`、`concept_explanation` | 未发生 |
| godot-inspection | F5 观察九格显影、玩家格金框、船体压入；检查无震惊气泡 | `editor_operation`、`scene_tree_inspection` | 未发生 |
| verification-handoff | 运行门禁并解释 `jie_shu` 单次与演出后船生成 | `test_execution`、`result_interpretation` | 未发生 |

## 3. 已记录证据

无。

## 4. 待巩固概念

- 显影与飞入。
- 单一焦点与留白。
- 打字机 `visible_ratio`。
- 4 帧 `AnimatedSprite2D` 与冷色背光。
- 单一收尾入口与 Tween 生命周期。

## 5. 参与边界

- AI 负责时间轴、节点、测试与文档；学生负责 F5 目检、概念解释与结果解读。
- AI 演示最多记 `introduced`，不得写成 `applied`。
