# TASK-011 交接说明（INTEGRATION_HANDOFF）

> 状态：not_started（任务包已生成，等待审批）

## 交付物

- 待实现后填写

## 提供给后续任务的接口

- `yao_gan.gd` 输出的归一化方向（TASK-012 的咬击瞄准可复用）
- `TUN_CHI_BEI_LV` / `TI_XING_SI_WANG` 常量（调参唯一入口）
- 体型显示节点（TASK-013 饥饿条/控制条 UI 的锚点）
- 退役清单：`mubiao_dian` 链路、`xue_liang` 血条链路

## 场景树（交付后）

- 待实现后填写

## 已知限制 / 后续任务注意

- 0.9~1.1 中间带本课"无事发生"，咬击在 TASK-012 补上
- 体型=血量 与 经验升级 并存，短期可能"越升级越耐打"，TASK-014 统一
- 待实现后补充其余限制

## 集成检查清单

- [ ] 任务包通过 validate_task.py（v1 生成/审批）
- [ ] headless 导入零错误
- [ ] ce_yao_gan / ce_panding 退出码 0，pao_pi.bat 六步全绿
- [ ] F5 全量回归（移动/吞噬/受伤/死亡/升级/三选一/结算重开）
- [ ] 学生 godot-inspection 完成
- [ ] 学生 verification-handoff 完成
- [ ] LEARNING_ROADMAP / TASK_INDEX / 引擎词总表（md + docx）已更新
- [ ] TASK-010（安卓导出）已恢复并排期
