# INTEGRATION_HANDOFF · TASK-028

> 状态：`handoff_status = ready`。源码、Main 集成与 6zf 测试已落地并验证；未 commit、未 push，F5 目检待用户。

## 1. 功能目的与归属

- 目的：重做通关前 7.3 秒九图拼合演出，用慢推镜、九格显影、单一焦点、打字机、留白与 4 帧动态船体冷蓝入场替代飞入/回弹/红闪/震屏/震惊气泡；演出期间隐藏气泡层与设置按钮；ESC 跳过；`jie_shu` 只发一次。
- 归属：`student-01`；owned scripts 为 `di_tu_pin_jie_yan_chu.gd`、`main.gd`。

## 2. 运行入口

- `Main._bo_fang_ren_lei_yan_chu()` 创建 `DiTuPinJieYanChu` 并连接 `jie_shu`。
- 演出内部 `_kai_shi()` 启动 7.3 秒时间轴；`_jie_shu_yan_chu()` 是唯一收尾入口。
- ESC/跳过按钮走 `_tiao_guo()`，最终仍进 `_jie_shu_yan_chu()`。

## 3. 输入与消费接口

- `Main.dang_qian_fang_jian`、`fang_jian_qu()`、`qu_yu_pian()`。
- `DiTuPinJieYanChu.quan_tu_zoom`、`ge_zi_qu()`、`ge_zi_zhong_xin()`、`wan_jia_pian`、`pin_jie_shun_xu`、`WAN_JIA_JU_JIAO`、`YAN_CHU_SHI_CHANG`。
- `YinXiang.fang("jing_bao")`、`YinXiang.bo_bgm(&"jue_zhan")`。
- `data/donghua/ji_qi_chuan_4zhen.tres`、静态 `CHUAN_TIE_TU` 兜底。

## 4. 输出与提供接口

- `jie_shu`：演出结束唯一信号，只发一次。
- `fei_ru_qi_dian()`：保留供静态契约调用，运行时不再使用。
- `_unhandled_input(event)`：监听 `ui_cancel` 跳过。
- `Main` 演出期间 `QiPaoCeng`/设置按钮隐藏，结束后恢复原 `visible`。

## 5. 状态归属与持久化

- 演出状态只存在节点生命周期内，不写存档。
- `YAN_CHU_SHI_CHANG=7.3` 与 `_ding_shi(7.3)` 必须一致。
- 玩家位置/旋转/相机 offset 在 `_jie_shu_yan_chu()` 还原。

## 6. 关键场景、脚本、配置与测试

- `scripts/di_tu_pin_jie_yan_chu.gd`：时间轴、九格显影、波纹、金线、玩家焦点、打字机、船体、背光、收尾、跳过。
- `scripts/main.gd`：演出期间 HUD 临时隐藏/恢复。
- `tests/ce_panding.gd`：九图静态契约保留；新增显影/无气泡/单次 `jie_shu`/跳过断言。
- 配置：无新增；`project.godot`、`scenes/Main.tscn` 不改。

## 7. 集成流程

1. 确认 TASK-028 `check_task_scope.py check` 零违规。
2. 合入 `di_tu_pin_jie_yan_chu.gd`、`main.gd`、`tests/ce_panding.gd`。
3. 运行 `--import` 0 ERROR；`tests/pao_pi.bat` 八步全绿。
4. F5 触发结尾演出，检查九格显影、玩家焦点、船体、跳过、演出后船生成。
5. 更新 `TASK_STATE.json` 与 `handoff_status`。

## 8. 禁止直接访问与冲突热点

- 禁止改 `YAN_CHU_SHI_CHANG`、`_ding_shi(7.3)`、九图静态纯函数契约。
- 禁止改 Main 的 10 秒无敌/船生成时序或顶层节点树。
- 禁止新增音效键/BGM 曲目。
- 冲突热点：TASK-020 九图原型；Main HUD 层名；`QiPaoCeng` 随机气泡；`SheZhi` 设置按钮暂停 tween。

## 9. 必需集成检查与最新验证基线

- 基线：`f27ae56893aed50db99ca6572659966bbca09b27`；开工前已 `capture`（2026-11-14T18:16:22Z）。
- 完工：`--import` 0 ERROR；八步门禁 `232 / 25 / 1422 / 8 / 20 / 144 / 1422` 全绿（3273 断言）；`validate_task.py` VALID；scope 13 allowed / 167 unchanged / 0 violation。
- 文档收尾后最终复跑：scope 23 allowed / 159 unchanged / 0 violation。
- 测试：`ce_panding` 用例 6zf 覆盖顺序/常量/显影初始态/船体/单次 `jie_shu`/ESC 跳过；1313→1422。
- F5 演出目检与手机比例评估待用户；本包未 commit、未 push。

## 10. 已知限制与待参与事项

- 92px 黑边、4 帧船体、冷蓝背光、打字机速度均需 F5/手机比例评估。
- 演出总时长保持 7.3 秒，不为观感延长，避免 Main 10 秒无敌与船生成时序风险。
- 学生参与检查点尚未发生；`learning_status = not_started`。
- 未 commit、未 push；F5 验收由用户执行。
- 落点气泡世界坐标 `(2064, 900)` 是否在最终镜头内需 F5 确认；自动化只验证调用一次。
