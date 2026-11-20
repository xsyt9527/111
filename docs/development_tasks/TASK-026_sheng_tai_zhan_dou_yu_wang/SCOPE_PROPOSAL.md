# SCOPE_PROPOSAL · TASK-026

## 任务

生态精简、毒鱼耐受、咬伤经验与 NPC 鱼王成长：收敛野外鱼池、让低等级鱼全期可刷、狮子鱼延后出现；新增只对「连吃毒鱼」生效的递减毒抗；普通咬击按目标实际掉肉给经验并给同目标接触伤害短减免；NPC 隐藏等级达到 10 后晋升为鱼王，每房最多 2 只、不可整吞、不逃跑、雷达金点、败退给大肉与经验且不触发鲸鲨信号。

## 用户原文（批准依据）

> 现在鱼种太多，我感觉不需要这么多，还有前期毒鱼太多吃起来难受（加个免疫力吧，短期吃多有抗性！），你可以删除一部分，然后结尾那个动画太ai了，你参考其他游戏优化下，对了claude的下面我装了一些skill，你看着用，还有游戏全部音乐重新生成一遍，全部！音效也是，对了，npc鱼可以弄成也可成长（所有鱼类都可能成为boss！），这样就不会显的后期只有那些鱼了，还有我咬比我大的鱼好像没有获得经验（他变小了，我也变小了，导致一直吃不掉，然后经验也不涨，难受）

补充口径（用户通过 AskUserQuestion 确认）：

- 鱼种精简 = 退池保留：只退铜眼 `hong_yu`、暗影剑鱼 `an_ying_jian_yu`，`.tres`、图鉴、选角、进化树、专属技全部保留。
- 狮子鱼 `cheng_yu` 保留但延后：`_dang >= 2`（40 秒后）才可抽到。
- 毒抗 = 连吃递减：45 / 31.5 / 18 / 13.5，8 秒窗口，停吃 8 秒后每 2 秒退层。
- NPC 成王 = 隐藏等级 `deng_ji_nei >= 10` 晋升，每房上限 2，阈值可调。

## 范围

- `scripts/yu_qun.gd`：`TUI_CHU_PAI_CHI`、`DU_YU_ZUI_DI_DANG`、`shua_xin_zui_di` 恒 1、`yu_wang_shu()`、虚拟互吃晋升名额守卫。
- `scripts/zhang_ben.gd`：毒抗字段、`jia_du_yun_chi_du_yu()`、独立 `_geng_xin_du_kang()`、`chong_zhi()` 清零。
- `scripts/yu.gd`：`chi_du_yu()` 委托、咬伤经验小数池、0.6 秒同目标接触减免、鱼王整吞守卫。
- `scripts/yu_npc.gd`：`yu_wang` 字段、晋升/恢复、不可整吞/不逃跑/继续成长、残血败退、推挤层、毒鱼抗性调用。
- `scripts/xiao_di_tu.gd`：鱼王记录与实体去重金点。
- `scripts/zhuan_shu_ku/fen_yu.gd`：`_ke_chi()` 排除鱼王。
- `tests/ce_panding.gd`：改写档位旧断言，新增鱼池/毒抗/咬伤/鱼王用例。
- 任务包与文档：`docs/TASK_INDEX.md`、`LEARNING_ROADMAP.md`、`docs/引擎词总表.md`、`Godot引擎词总表.docx`。

## 不做

- 不新增 Autoload、不改存档 schema、不改主场景顶层结构或 `project.godot`。
- 不删除鱼种 `.tres`、图鉴条目、选角卡、进化树或专属技。
- 不给鱼王复用 `shi_boss`，不 emit `bei_ji_bai`，不改鲸鲨规则。
- 不重做九图结尾演出（TASK-028）、不重制音频（TASK-027）。
- 不 commit/push（由主代理统一执行）。

## 验收

- 野外抽 1000 次无 `hong_yu`/`an_ying_jian_yu`；`_dang<2` 无 `cheng_yu`，`_dang>=2` 可含；`shua_xin_zui_di()` 全部返回 1。
- 连吃毒鱼伤害 45 → 31.5 → 18 → 13.5，第 5 条仍 13.5；8 秒后每 2 秒退层；`jia_du_yun(45)` 仍是 45。
- 咬 1 点体型给 5 经验；咬到 0.5 后不再给；机械船不给；同目标 0.6 秒接触伤害 ×0.2。
- 第 10 级晋升鱼王、+2 体型、推挤层开、金点；第 3 只停在 9 级并保留经验；换房恢复不再加 2。
- 鱼王不可整吞、不逃跑、可继续成长；残血给 3 块大肉 + 2 倍鱼种经验后静默消失；`bei_ji_bai` 计数为 0。
- `tests/pao_pi.bat` 八步全绿；`validate_task.py` VALID；`check_task_scope.py check` 零违规；机器人探针仍胜利。

## 批准

- 版本：v1
- 状态：待批准（`awaiting`）
- 建议表达：`确认 TASK-026 v1 进入开发`
