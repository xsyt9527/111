# TASK-020 学习记录（LEARNING_RECORD）

## 当前状态

尚无学生学习证据。任务包按 plan_driven / guided_co_development / teaching 生成；用户已确认 TASK-020 v1 进入开发，学习检查点仍待执行。

## 计划中的三个检查点

1. **Orientation（取向）**：用户/学生能指出 `Main.dang_qian_fang_jian`、`fang_jian_qu()`、`YuQun.fang_jian_qu` 在项目中的位置，并解释“九宫格房间只是同一张背景上的 9 个逻辑矩形”。
2. **Inspection（检查）**：在 Godot 编辑器中打开 `scenes/Main.tscn`，选中 `Camera2D` 查看 `limit_left/top/right/bottom`，再对比运行时 `_suo_fang_jian(4)` 的目标值，说明为什么 limit 由 Main 运行时切换。
3. **Verification/Handoff（验证与交接）**：亲手跑 `tests/pao_pi.bat` 或至少 `ce_panding`，解释 Results/ERROR 判定，并复述“0.12 秒淡出 → 黑场换房/夹人 → 0.12 秒淡入”的状态顺序。

## 记录规则

- 只记录实际观察到的参与；AI 实现本身不算学习证据。
- 学生首次表示不会时，先演示最小完整例子，再让其复述原理或检查一个具名结果；仍不会则记录为未解决概念并继续任务。
- 证据写入 `LEARNING_STATE.json`，字段包含 `evidence_type`、`step_id`、`checkpoint_id`、`summary`、`understanding_level`、`observed_at`。
