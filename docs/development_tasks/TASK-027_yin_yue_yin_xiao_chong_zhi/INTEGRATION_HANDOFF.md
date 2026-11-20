# INTEGRATION_HANDOFF · TASK-027

> 状态：`handoff_status = ready`。音频文件域与接线已实现并验证；未 commit、未 push，F5 试听待用户。

## 1. 功能目的与归属

- 目的：重制 3 条 BGM 与 19 条使用中音效；统一音效格式；把 7 个旧键接到新文件；删除 11 条旧 wav。
- 归属：`student-01`；owned scripts 为 `yin_xiang.gd`、`shengcheng_yinyue.py`、`shengcheng_yin_xiao.py`。

## 2. 运行入口

- 运行时：Autoload `YinXiang` 的 `_ready()` 预加载 `YIN_XIAO_BIAO` 与 `BGM_QU_MU`，`fang()` 播音效，`bo_bgm()` 播 BGM。
- 生成时：`python -I tools/yinyue/shengcheng_yin_xiao.py`、`python -I tools/yinyue/shengcheng_yinyue.py`。

## 3. 输入与消费接口

- 19 个音效键：`yao`、`tun_xia`、`sheng_ji`、`shou_shang`、`si_wang`、`chong_ci`、`dian_xi`、`du_xi`、`xuan_wo`、`sheng_na`、`jing_bao`、`jiao_zhi`、`chi`、`shi_kong`、`tan_chuang`、`fang_neng_li`、`sheng_li`、`shi_bai`、`an_niu`。
- 3 个 BGM 键：`shen_hai`、`tan_suo`、`jue_zhan`。
- 调用方：24 处 `an_niu`、能力/技能/战斗/结算脚本。

## 4. 输出与提供接口

- `assets/yinxiao/yin_xiao_*.wav`：19 条 SFX，44.1kHz/16bit/单声道/峰值 -1.5dBFS。
- `assets/yinxiao/bgm_*.wav`：3 条 BGM，原 BPM/小节/时长，无缝循环。
- `YinXiang.YIN_XIAO_BIAO`：19 键。
- `YinXiang.BGM_QU_MU`：3 首。
- 无新增信号。

## 5. 状态归属与持久化

- 音频资源是只读资产；运行时不写存档。
- `YinXiang` 只持有播放器池与当前曲目状态，不持久化。
- 旧 wav 删除后不可回退，需依赖 Git 基线 `f27ae568...`。

## 6. 关键场景、脚本、配置与测试

- `scripts/yin_xiang.gd`：键表、preload、播放器池、循环标记。
- `tools/yinyue/shengcheng_yin_xiao.py`：19 条 JOBS、`render_mmp`、`postprocess`、`validate`。
- `tools/yinyue/shengcheng_yinyue.py`：3 BGM、`loop_wav`、`validate_bgm`。
- `assets/yinxiao/`：音频文件与 `.import`。
- `tests/ce_panding.gd`：`YIN_XIAO_BIAO.size()==19`、BGM 3 首断言。

## 7. 集成流程

1. 确认 TASK-027 `check_task_scope.py check` 零违规。
2. 合入两个生成器、`yin_xiang.gd`、音频文件与 `.import`。
3. 运行 `--import` 0 ERROR；`tests/pao_pi.bat` 八步全绿。
4. F5 与 Web 试听 3 BGM + 19 SFX。
5. 更新 `TASK_STATE.json` 与 `handoff_status`。

## 8. 禁止直接访问与冲突热点

- 禁止改 19 个键名或新增键。
- 禁止把 `qu_jing_sha` 接入 assets/BGM_QU_MU。
- 禁止在旧 wav 未验证前删除。
- 冲突热点：`yin_xiang.gd` 的 24 处 `an_niu` 调用；`ce_panding.gd` 的 19/3 断言；`.godot` 导入缓存。

## 9. 必需集成检查与最新验证基线

- 基线：`f27ae56893aed50db99ca6572659966bbca09b27`；本包开工前已 `capture`（2026-11-14T17:11:48Z，85 条既有改动）。
- 完工：两个生成器 validate 全过（SFX 19/19、BGM 3/3）；`--import` 0 ERROR；八步门禁 `232 / 25 / 1422 / 8 / 20 / 144 / 1422` 全绿（3273 断言）；`validate_task.py` VALID；scope 106 allowed / 73 unchanged / 0 violation。
- 文档收尾后最终复跑：scope 117 allowed / 65 unchanged / 0 violation。
- 资源：`assets/yinxiao/` 22 条 wav + 22 个 `.import`（19 SFX + 3 BGM）；11 条旧 wav 与 `.import` 已删除。
- F5 试听与 Web 包体对比待用户；本包未 commit、未 push。

## 10. 已知限制与待参与事项

- BGM 重编曲的主观质量需用户试听。
- Web 导出包体与加载时间需实测。
- 学生参与检查点尚未发生；`learning_status = not_started`。
- 未 commit、未 push；F5/Web 验收由用户执行。
- 7 条新增 `yin_xiao_*.mmp` 与 12 条重写 `.mmp` 目前未入版本库，提交时需一并纳入，否则无法从工程复现音效。
