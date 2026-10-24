# TASK-008 交接说明（INTEGRATION_HANDOFF）

> 状态：not_started（任务包生成时占位，实现完成后回填）

## 交付物

待实现后填写（预定：新建 xue_liang_ui.gd / jie_suan.gd / XueLiangTiao.tscn / JieSuan.tscn；修改 yu.gd / zhang_ben.gd / Main.tscn）。

## 提供给后续任务的接口

待实现后填写（预定）：

| 接口 | 形态 | 使用者 |
|---|---|---|
| `ZhangBen.chong_zhi()` | 账本重置唯一入口 | 第 9 课测试断言（重开归零用例） |
| `Yu.xue_liang_bian_hua(dangqian, zuigao)` | 玩家信号 | 后续回血卡/血量扩展 |
| 死亡-重开闭环 | 完整用例 | 第 9 课 headless 测试的端到端素材 |
| 结算页 build 展示 | UI 挂载点 | 后续死因/时长统计扩展 |

## 场景树（交付后）

待实现后填写（预定：Main +XueLiangTiao 实例；死亡后切换为 JieSuan 独立场景）。

## 已知限制 / 后续任务注意

待实现后填写（预定：贪食观察项结论 / 嘴身拆分是否升 v2 / 结算扩展候选 → 后续迭代；无头测试断言含 chong_zhi 归零与满级封顶 → 第 9 课）。

## 集成检查清单

- [ ] 任务包通过 validate_task.py（v1）
- [ ] headless 导入 0 错误（输出筛查）
- [ ] headless 360 帧零错误（输出筛查）
- [ ] check_task_scope.py 无违例
- [ ] 学生 godot-inspection 完成
- [ ] 学生 verification-handoff 完成
- [ ] LEARNING_ROADMAP / TASK_INDEX / 引擎词总表（md + docx）已更新
