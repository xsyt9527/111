# TASK-001 学习记录

> 事实记录，与 LEARNING_STATE.json 一致。不记录 AI 实现本身作为学习证据。

## 概念清单

| 概念 | 引入方式 | 学生表现 |
|---|---|---|
| 场景即蓝图（复用视角） | step-01 实现 | 检查场景树辨认 Yu 为实例，属识别级 |
| 主场景 run/main_scene | step-02（project.godot 登记） | — |
| InputEvent 事件对象与 _unhandled_input | step-03 实现 | 能区分 ScreenTouch（按下）与 ScreenDrag（拖动）为观察级 |
| move_toward + delta | step-04 实现 | 亲测速度参数差异（300→100） |
| InputEventScreenDrag | 修正 ScreenMotion 错误时引入 | 已收录引擎词表 |

## 检查点记录

### orientation（completed）

- 学生在方案 A（Main 接收输入、写入 Yu 公开属性）与方案 B（Yu 自监听）之间明确选择 A。
- 证据：concept_explanation / recognized。
- 学生提问：Main.tscn 里的 Haodi 节点是什么？（AI 说明为海床背景 Sprite2D；`Haodi` 为拼音命名惯例）

### godot-inspection（completed）

- 在检查器读到 `Yidong Sudu = 300`（editor_operation / recognized）。
- 查看 Main.tscn 节点树并提问 Haodi 身份（scene_tree_inspection / recognized）。
- F5 观察 `mubiao_dian` 数字跟随变化而鱼不动，正确区分“事件接收”与“移动实现”（result_interpretation / recognized）。

### verification-handoff（completed）

- F5 亲测四条：按住跟随、松手停止、改速变慢（300→100，已还原）、左右往返鱼头翻转——全部确认正确（test_execution / result_interpretation / recognized）。
- 学生以执行与结果确认完成参与；未进行口头契约复述（integration_contract_understood 保持 null）。

## 学生提问与待巩固概念

- Main.tscn 的 Haodi 节点是什么？（已解答）
- 建议后续巩固：亲眼观察 `_process` 与 `_unhandled_input` 的调用时机差异（可用临时 print 验证）。

## 学习状态结论

- learning_status：partially_demonstrated（三个检查点均有实际动作；解释级证据尚不足）
