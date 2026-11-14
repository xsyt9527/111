# TASK-023 学习记录

（待用户参与后填写：三个参与检查点的证据、理解等级与学生原话。）

## 检查点
- orientation：能指出 Main.tscn 中 XiaoDiTu 节点、SheZhi 设置面板与 CunDang 设置文件的位置。
- inspection：在 Godot 编辑器里查看 HUD 节点矩形，确认小地图落在设置按钮下方。
- verification-handoff：能读懂 ce_panding 断言与门禁输出，解释透明度从滑条到画面的链路。

## 概念
- Control 立即模式绘制（`_draw` + `queue_redraw`）
- CanvasLayer/Control 布局（锚点、offset、节点矩形）
- 设置 JSON 持久化（`user://shenhaishiji_shezhi.json`、旧档缺键回退）
- 即时反馈（滑条 `value_changed` → 改字段 → 重绘）
