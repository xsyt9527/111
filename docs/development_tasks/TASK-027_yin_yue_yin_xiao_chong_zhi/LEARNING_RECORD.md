# LEARNING_RECORD · TASK-027

> 状态：`learning_status = not_started`。只记录实际发生的学生参与。

## 1. 学习目标

- 能解释为什么只改 preload 路径而保持 19 个键名不变。
- 能说明 44.1kHz/16bit/单声道/峰值约束如何由 `validate()` 检查。
- 能解释 `loop_wav` 如何把尾音折回开头形成无缝循环。
- 能定位旧 wav 删除前必须先通过导入与测试的顺序原因。

## 2. 计划中的三个检查点

| 检查点 | 学生动作 | 证据类型 | 状态 |
|---|---|---|---|
| orientation | 打开 `scripts/yin_xiang.gd`，指出 7 个旧键与 19 键总数 | `project_navigation`、`concept_explanation` | 未发生 |
| godot-inspection | 检查 `assets/yinxiao` 导入参数；F5 逐条试听 | `configuration_inspection`、`editor_operation` | 未发生 |
| verification-handoff | 运行或解释生成器 validate 与门禁结果 | `test_execution`、`result_interpretation` | 未发生 |

## 3. 已记录证据

无。

## 4. 待巩固概念

- 参数化音频合成管线。
- 键表解耦。
- 无缝循环与尾音折回。
- 资源导入与运行时接线分离。
- 音频格式与峰值校验。

## 5. 参与边界

- AI 负责生成器、键表接线、删除旧文件与文档；学生负责检查键表、试听与解释校验结果。
- AI 演示最多记 `introduced`，不得写成 `applied`。
