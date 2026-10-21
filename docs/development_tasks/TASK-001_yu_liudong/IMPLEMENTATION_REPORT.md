# TASK-001 实施报告

## 任务与版本

- TASK-001 v4（v1 初始实现范围；v2/v3/v4 均为白名单记账修正，行为零变化）
- 实现基线：42b0494（v2 捕获，v3/v4 保留未重捕）

## 分步实施

| Step | 内容 | 结果 |
|---|---|---|
| step-01 | Yu.tscn（Node2D + Sprite2D）+ yu.gd（@export 速度、mubiao_dian） | 已完成 |
| step-02 | Main.tscn（Haodi 背景 + Yu 实例）+ main.gd + project.godot 主场景登记 | 已完成 |
| step-03 | main.gd `_unhandled_input`：ScreenTouch/ScreenDrag → 写入 `yu.mubiao_dian` | 已完成（首次导入即抓到 InputEventScreenMotion 不存在的错误，改为 ScreenDrag） |
| step-04 | yu.gd `_process`：move_toward + delta、到达阈值、flip_h 朝向 | 已完成 |

## 设计决策

1. **输入归属（学生选择 A）**：Main 接收输入并写入 Yu 公开属性 `mubiao_dian`；Yu 保持纯移动蓝图。为第 6 课 UI 卡片输入统一留出空间。
2. **静态组合**：Yu 在 Main.tscn 中静态实例化，无动态加载、无对象池、无信号。
3. **朝向**：贴图默认朝右，`mubiao_dian.x < position.x` 时 `flip_h = true`。
4. **到达判定**：距离 ≤ 5px 视为到达，避免在目标点附近抖动。

## AI 工作

- 编写 4 个生产文件、2 个场景；建立主场景登记；跑无头导入/冒烟验证；维护任务状态、学习证据与报告。

## 学生工作（实际观察）

- orientation：在两个输入架构方案中选定 A。
- godot-inspection：读出检查器 `Yidong Sudu = 300`；查看 Main.tscn 节点树并提问 Haodi 节点身份；F5 观察 `mubiao_dian` 跟随变化而鱼未移动，正确区分事件接收与移动实现。
- verification-handoff：F5 亲测四条行为（跟随、停止、改速、翻转）全部确认通过。

## 变更文件

- 新增：`scenes/Yu.tscn`、`scenes/Main.tscn`、`scripts/yu.gd`、`scripts/main.gd`、`scripts/*.gd.uid`（引擎生成）
- 修改：`project.godot`（仅 run/main_scene）、`docs/引擎词总表.md`、`LEARNING_ROADMAP.md`（待打勾）、`docs/TASK_INDEX.md`、任务包文档
- 编辑器自动重写：Main.tscn 补 uid/unique_id/editable 元数据（无害）

## 接口变化

- 新增公开接口：`Yu.mubiao_dian: Vector2`、`Yu.yidong_sudu: float`
- 无信号、无 Autoload、无共享状态

## 偏差与处理

- `InputEventScreenMotion` 不存在 → 引擎解析报错 → 改为 `InputEventScreenDrag`（已记录进引擎词表）。
- v2/v3/v4 版本迭代均源于文件白名单登记，不涉及行为、验收或接口。
- 调试 `print` 保留在 main.gd（已注明第 2 课前移除）。
