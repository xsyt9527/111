# SCOPE_PROPOSAL · TASK-027

## 任务

全部音乐与音效重制：3 条 BGM 重编曲（保持 56/96/140 BPM、12/16/24 小节与原时长），12 条既有音效重写 + 7 条旧键音效补齐，19 条 SFX 统一由生成器产出；`yin_xiang.gd` 只换 7 个 preload 路径、不改键名；删除 11 条旧 wav；19 键与 3 BGM 断言不变。

## 用户原文（批准依据）

> 现在鱼种太多，我感觉不需要这么多，还有前期毒鱼太多吃起来难受（加个免疫力吧，短期吃多有抗性！），你可以删除一部分，然后结尾那个动画太ai了，你参考其他游戏优化下，对了claude的下面我装了一些skill，你看着用，还有游戏全部音乐重新生成一遍，全部！音效也是，对了，npc鱼可以弄成也可成长（所有鱼类都可能成为boss！），这样就不会显的后期只有那些鱼了，还有我咬比我大的鱼好像没有获得经验（他变小了，我也变小了，导致一直吃不掉，然后经验也不涨，难受）

本任务只负责其中「全部音乐重新生成一遍，全部！音效也是」部分。

## 范围

- `tools/yinyue/shengcheng_yin_xiao.py`：12 条既有音效重写，JOBS 扩到 19 条，新增 7 条旧键生成函数。
- `tools/yinyue/shengcheng_yinyue.py`：`qu_shen_hai`/`qu_tan_suo`/`qu_jue_zhan` 重编曲，补 `validate_bgm()`，修 `inst_triple` 左右失谐。
- `scripts/yin_xiang.gd`：7 个旧键 preload 指向 `yin_xiao_*`，19 个键名不变。
- `assets/yinxiao/`：3 BGM + 19 SFX 重新生成；删除 11 条旧 wav 与 `.import`。
- `tests/ce_panding.gd`：仅在必要时同步音频契约断言，不改 19/3 的语义。
- 任务包与文档：`docs/TASK_INDEX.md`、`LEARNING_ROADMAP.md`、`docs/引擎词总表.md`、`Godot引擎词总表.docx`。

## 不做

- 不新增音效键、不改 19 个键名、不新增 BGM 曲目。
- 不把 `qu_jing_sha` 接入 `assets` 或 `BGM_QU_MU`。
- 不修改任何 gameplay 脚本、场景、`.tres`、存档或 `project.godot` 音频配置。
- 不 commit/push（由主代理统一执行）。

## 验收

- `shengcheng_yin_xiao.py` 19 条 job 全部成功，`validate()` 格式/时长/峰值全过。
- `shengcheng_yinyue.py` 3 条 BGM 全部成功，`validate_bgm()` 全过；总大小 ≤20MB。
- `YIN_XIAO_BIAO.size()==19`、`BGM_QU_MU.size()==3` 断言不变。
- `--import` 0 ERROR；八步门禁全绿；`validate_task.py` VALID；`check_task_scope.py check` 零违规。
- F5 与 Web 试听：三条 BGM 循环无断缝，19 条音效均可触发。

## 批准

- 版本：v1
- 状态：待批准（`awaiting`）
- 建议表达：`确认 TASK-027 v1 进入开发`
