# LEARNING_RECORD · TASK-026

> 状态：`learning_status = not_started`。本文件只记录实际发生的学生参与；AI 实现本身不构成学习证据。

## 1. 学习目标

- 能解释刷鱼池过滤与鱼种注册表为什么分离。
- 能说出毒抗窗口、层数与递减倍率的关系。
- 能解释为什么咬伤经验必须在 `_yao_ji_lian_dong()` 之后读取最终体型。
- 能说明鱼王身份如何从记录 `nei_deng` 推导，以及为什么不复用 `shi_boss`。
- 能定位鱼王败退不 emit `bei_ji_bai` 的原因与失败后果。

## 2. 计划中的三个检查点

| 检查点 | 学生动作 | 证据类型 | 状态 |
|---|---|---|---|
| orientation | 打开 `scripts/yu_qun.gd`，指出 `_chou_yu_zhong()` 两处过滤循环；解释为什么不能删 `.tres` | `project_navigation`、`concept_explanation` | 未发生 |
| godot-inspection | F5 观察雷达金点；编辑器检查鱼王 `BossPengZhuangQu.monitoring` 与 `yu_wang` 组 | `editor_operation`、`scene_tree_inspection` | 未发生 |
| verification-handoff | 运行或解释门禁与探针结果，说明入口/输入/输出/依赖 | `test_execution`、`result_interpretation` | 未发生 |

## 3. 已记录证据

无。

## 4. 待巩固概念

- 池内过滤与运行时抽样。
- 状态窗口与递减层数。
- 按实际状态差结算。
- 由数据推导的运行时身份。
- 身份守卫与信号语义隔离。

## 5. 参与边界

- AI 负责代码、测试与文档；学生负责定位、解释、F5 目检与结果解释。
- AI 演示最多记为 `introduced`，不得写成 `applied`。
- 学生第一次表示不会时，AI 演示最小完整步骤，再让学生复述或检查一个明确结果。

## 6. AI 实现与验证事实（不构成学习证据）

- 2026-11-15 完成 TASK-026 代码、测试与文档；`learning_status` 仍为 `not_started`，因为三个检查点都未发生。
- 八步门禁 232 / 25 / 1422 / 8 / 20 / 144 / 1313 passed，合计 3164 断言，全绿。
- 机器人探针两次连续胜利：532.0 秒与 541.5 秒，Lv.16，体型峰值 25.5；两次均未遇到鱼王（峰值 0、败退 0）。
- 可用的教学切入：让学生解释“为什么鱼王身份从记录 `nei_deng>=10` 推导，而不新增 `wang` 键”；再对比 `ji_lu_ke_hua()` 的三种输入，说明“记录为空”与“节点已死”为何语义不同。
