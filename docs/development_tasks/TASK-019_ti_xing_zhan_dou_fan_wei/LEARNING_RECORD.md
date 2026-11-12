# TASK-019 学习记录（LEARNING_RECORD）

## 当前状态

尚无学生学习证据。任务包按 plan_driven / guided_co_development / teaching 生成；用户已确认 TASK-019 v1 进入开发，学习检查点仍待执行。

## 计划中的三个检查点

1. **Orientation（取向）**：用户/学生能指出 `ZhangBen.dang_qian_ti_xing`、`Yu._ti_xing_vector()`、`YuNpc.boos_yao_shang_hai()` 在项目中的位置，并解释“当前体型既是血量也是尺寸”。
2. **Inspection（检查）**：在 Godot 编辑器中打开 `scripts/ji_neng_fan_wei.gd` 与一个 `ban_jing_shen_wei=true` 的 `.tres`，确认范围指示与命中计算是否同源。
3. **Verification/Handoff（验证与交接）**：亲手跑 `tests/pao_pi.bat` 或至少 `ce_zhang_ben`/`ce_panding`，解释 Results/ERROR 判定，并复述 Boss 三参咬伤与范围下限的输入输出。

## 记录规则

- 只记录实际观察到的参与；AI 实现本身不算学习证据。
- 学生首次表示不会时，先演示最小完整例子，再让其复述原理或检查一个具名结果；仍不会则记录为未解决概念并继续任务。
- 证据写入 `LEARNING_STATE.json`，字段包含 `evidence_type`、`step_id`、`checkpoint_id`、`summary`、`understanding_level`、`observed_at`。
