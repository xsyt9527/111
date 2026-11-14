# LEARNING_RECORD · TASK-025

## 学习目标

1. 能解释为什么未加载房间只存 Dictionary、不实例化 `YuNpc`。
2. 能说明记录与当前房实体为什么需要每帧同步、记录为什么是唯一权威。
3. 能解释虚拟互吃与档位淘汰如何让雷达上的鱼点移动、消失、变大。
4. 能说出换房保存/加载的固定顺序，以及停刷时为什么只保存不加载。

## 核心概念

- 数据层与表现层分离
- 双态同步与唯一权威
- 无节点轻量模拟
- Godot 节点生命周期与 `add_child` 时序
- 雷达按数据模型绘制

## 已发生的学习活动

实现与自动验证已完成（2026-11-14），但学生本人尚未参与 orientation / godot-inspection / verification-handoff；`learning_status` 保持 `not_started`。

本轮 AI 侧已完成的概念讲解材料见 `IMPLEMENTATION_REPORT.md` 与 `CODE_REVIEW.md`：

- 为什么未加载房只存 Dictionary：避免 8×35=280 个隐藏房间实体常驻，雷达只需位置数据。
- 为什么记录是唯一权威：换房时实体被释放，只有记录能把位置/体型/隐藏成长带到下一房。
- `add_child` 时序：恢复载荷必须在 `add_child` 前写入，由 `_ready` 末尾应用，否则默认鱼种值覆盖成长。
- 虚拟互吃与档位淘汰：20 秒节拍 + 0.25 秒虚拟游动，只改字典即可让雷达点移动/消失/变大。

## 计划中的参与检查点

- `orientation`：实现前由学生指出 `YuQun`、`YuNpc`、`XiaoDiTu`、`Main` 各自职责与换房调用链，并复述九房记录方案。（尚未进行）
- `godot-inspection`：学生实际打开场景树/脚本，确认 `YuQun` 与 `Main` 的节点关系、`Dingshi` 排程与雷达数据来源。（尚未进行）
- `verification-handoff`：学生实际跑一次门禁或 F5 验收，读出断言数与雷达/换房结果。（尚未进行；自动门禁结果已记录在 `VERIFICATION_REPORT.md`）

## 证据记录

当前 `LEARNING_STATE.json` 的 `evidence` 为空。只有实际观察到的学生行为才记录；AI 演示最多记为 `introduced`，学生本人未做过的操作不记 `editor_operation` 或 `applied`。

