# SCOPE_PROPOSAL · TASK-028

## 任务

九图拼合结尾演出重做：保持 7.3 秒总时长与九图静态纯函数契约，把「飞入 + 回弹 + 红闪 + 大标题 + 震屏 + 玩家翘头」改为慢推镜、九格波纹显影、单一焦点、区域名打字机、留白与 4 帧动态船体冷蓝入场；删除震惊气泡；演出期间隐藏气泡层与设置按钮；新增 ESC 跳过；`jie_shu` 只发一次。

## 用户原文（批准依据）

> 现在鱼种太多，我感觉不需要这么多，还有前期毒鱼太多吃起来难受（加个免疫力吧，短期吃多有抗性！），你可以删除一部分，然后结尾那个动画太ai了，你参考其他游戏优化下，对了claude的下面我装了一些skill，你看着用，还有游戏全部音乐重新生成一遍，全部！音效也是，对了，npc鱼可以弄成也可成长（所有鱼类都可能成为boss！），这样就不会显的后期只有那些鱼了，还有我咬比我大的鱼好像没有获得经验（他变小了，我也变小了，导致一直吃不掉，然后经验也不涨，难受）

本任务只负责其中「结尾那个动画太 ai 了，参考其他游戏优化下」部分。

## 范围

- `scripts/di_tu_pin_jie_yan_chu.gd`：重写 `_jian_di_tu`/`_jian_ui`/`_kai_shi`/`_on_wan_jia_pian_luo_di`/`_cong_te_xie_hui_quan_tu`/`_kai_shi_ren_lei`/`_shou_wei` 的视觉与时间轴；删除震惊气泡与 `_process` 跟随；新增 ESC 跳过。
- `scripts/main.gd`：演出期间临时隐藏 `QiPaoCeng` 与设置按钮，结束后恢复；不改 Main 流程。
- `tests/ce_panding.gd`：保留九图静态契约，新增显影/无气泡/单次 jie_shu/跳过路径断言。
- 任务包与文档：`docs/TASK_INDEX.md`、`LEARNING_ROADMAP.md`、`docs/引擎词总表.md`、`Godot引擎词总表.docx`。

## 不做

- 不改 `YAN_CHU_SHI_CHANG=7.3`、`_ding_shi(7.3, _jie_shu_yan_chu)`、九图静态纯函数契约。
- 不新增音效键/BGM 曲目；只使用现有 `jing_bao`、`an_niu`、`sheng_ji` 等。
- 不改 `HUD_CENG_MING` 中的 `XiaoDiTuUI`。
- 不改 Main 的 10 秒无敌、机械船生成时序、顶层节点树、gameplay 数值、存档或 `project.godot`。
- 不 commit/push（由主代理统一执行）。

## 验收

- 九块图初始位置等于 `ge_zi_zhong_xin(pian)`，运行时不再用 `fei_ru_qi_dian()` 计算起点。
- 波纹/alpha 显影、玩家格最后、`WAN_JIA_JU_JIAO=0.88` 与 `pin_jie_shun_xu` 契约不变。
- 无震惊气泡、无红闪、无震屏、无玩家翘头/旋转。
- 船体使用 `ji_qi_chuan_4zhen.tres`，冷蓝背光 alpha ≤0.12，标题打字机。
- 演出期间 `QiPaoCeng`/设置按钮隐藏，结束后恢复。
- `jie_shu` 正常路径与 ESC/按钮跳过路径都只发一次。
- 八步门禁全绿；`validate_task.py` VALID；`check_task_scope.py check` 零违规。
- F5 演出结束后机械船正常生成且可继续操作。

## 批准

- 版本：v1
- 状态：待批准（`awaiting`）
- 建议表达：`确认 TASK-028 v1 进入开发`
