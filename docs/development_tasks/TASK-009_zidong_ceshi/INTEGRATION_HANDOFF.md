# TASK-009 交接说明（INTEGRATION_HANDOFF）

> 状态：not_started（任务包生成时占位，实现完成后回填）

## 交付物

待实现后填写（预定：新建 tests/ 四域测试脚本 + .uid、集成测试场景、坏卡夹具 huai_ka.tres、跑批 pao_pi.bat；产品代码零修改）。

## 提供给后续任务的接口

待实现后填写（预定：pao_pi.bat 回归门禁——第 10 课导出前必跑；运行器模式模板——后续新功能测试照抄；全键校验——加第 7 张卡自动守护）。

## 场景树（交付后）

待实现后填写（预定：产品树零变化；tests/ 新增六文件 + 夹具 + bat）。

## 已知限制 / 后续任务注意

待实现后填写（预定：测试覆盖范围边界——纯逻辑全覆盖、UI/动画无自动化（真人 F5 仍必要）；CI 上线候选；TASK-008 挂账清算结果）。

## 集成检查清单

- [ ] 任务包通过 validate_task.py（v1 生成/审批）
- [ ] headless 导入 0 错误（输出筛查）
- [ ] 四域测试各自退出码 0 + Results 全 passed
- [ ] pao_pi.bat 总体退出码 0
- [ ] 学生 godot-inspection 完成（含亲手建夹具）
- [ ] 学生 verification-handoff 完成（跑批全绿 + 红绿体验）
- [ ] LEARNING_ROADMAP / TASK_INDEX / 引擎词总表（md + docx）已更新
