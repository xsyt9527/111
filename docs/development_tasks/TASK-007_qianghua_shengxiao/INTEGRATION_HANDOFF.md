# TASK-007 交接说明（INTEGRATION_HANDOFF）

> 状态：not_started（任务包生成时占位，实现完成后回填）

## 交付物

待实现后填写（预定：修改 yu.gd / yu_npc.gd / zhang_ben.gd / Yu.tscn，零新增资源）。

## 提供给后续任务的接口

待实现后填写（预定）：

| 接口 | 形态 | 使用者 |
|---|---|---|
| `ZhangBen.jing_yan_jia_cheng` + `she_jing_yan_jia_cheng()` | 账本倍率 | TASK-008 结算页可展示 build 收益；第 9 课测试断言 |
| yu.gd `_on_ka_yi_xuan` match 分发模式 | 代码模式 | 后续新增卡型在此加分支（键 + push_warning 兜底） |
| Yu 双 Area2D 结构（ChiQu 吸附 / ShangQu 判定） | 场景结构 | 后续范围类 buff 照抄双圈分职 |

## 场景树（交付后）

待实现后填写。

## 已知限制 / 后续任务注意

待实现后填写（预定：血量死亡/满级决策/账本重置 → TASK-008；无头测试断言含 xiao_guo 全键校验 → 第 9 课）。

## 集成检查清单

- [ ] 任务包通过 validate_task.py（v1）
- [ ] headless 导入 0 错误（输出筛查）
- [ ] headless 360 帧零错误（输出筛查）
- [ ] check_task_scope.py 无违例
- [ ] 学生 godot-inspection 完成
- [ ] 学生 verification-handoff 完成
- [ ] LEARNING_ROADMAP / TASK_INDEX / 引擎词总表（md + docx）已更新
