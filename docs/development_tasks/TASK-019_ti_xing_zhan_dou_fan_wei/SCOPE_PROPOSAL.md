# TASK-019 范围提案（SCOPE_PROPOSAL）

## 范围内

- **体型与首领咬伤**：`zhang_ben.gd` 显示曲线加每 5 点体型 ×1.06 里程碑；`yu_npc.gd` 的 `boos_yao_shang_hai` 增可选第三参 `gong_ti`，按 `min(目标体型, 攻击者体型)` 结算；调用点传入 Boss `tixing`；保留两参旧调用兼容。
- **升级反馈**：`yu.gd` 监听 `ZhangBen.sheng_ji`，升级瞬间 0.6 秒无敌，并给 `AnimatedSprite2D` 一次 0.45 秒 1→1.16→1 脉冲。
- **红光**：`yu_npc.gd` 的 `HONG_GUANG_FANG_DA` 1.5→2.1；`ke_chi_wu.gd` 的 `HONG_GUANG_BEICHENG` 1.55→1.8；不动判定圈。
- **技能范围**：`yu.gd` 新增 `ti_chang()`、`ji_neng_ban_jing()`、`fan_wei_xiu_zheng()`；基础主动 8 处固定像素半径改用统一入口；六份进化主动半径套视觉下限；`ji_neng_fan_wei.gd` 接收玩家实例并调用同一入口；`neng_li.gd` 只补单位注释，不改数据结构。
- **固定镜头**：`main.gd` 的 `SHI_JIAO_MEI_JI` 改为 0.0，`_shi_jiao_bei()` 恒为 1.0；只改相机常量/函数，不碰房间逻辑。
- **人类船战**：`zhan_dou.gd` 旧咬击系数 0.15/0.05→0.24/0.08；`ji_qi_chuan.gd` 三种船招加“玩家当前体型 ×4%”项。
- **测试与文档**：`ce_zhang_ben`、`ce_zhan_dou`、`ce_panding`、六份 `ce_zhuanshu_*` 同步断言；八步门禁、范围检查、引擎词总表、学习路线、docx、任务包报告。

## 范围外（移交后续任务）

- 九宫格房间、Camera2D limit、换房淡入淡出、刷怪边界、Boss 房 → TASK-020
- 鲸鲨首领战 BGM 生成/接线 → 本轮独立试听交付，不进本任务
- Gemini 特效需求文档 v1.2 → 本轮独立 docs 交付
- 新增 BGM 资源、音效、特效 PNG → 新任务
- 改变 Boss 15 倍痛感/同体型 90% 口径 → 新任务
- 恢复逐级镜头拉远/极端体型镜头 → 新任务

## 零触碰清单

- `.agents/skills/**`（只读）
- `tests/` 既有文件不得删除（可改断言）
- `scenes/Main.tscn`、`main.gd` 的房间逻辑（留给 TASK-020；本任务只改相机常量与 `_shi_jiao_bei`）
- `project.godot`、Autoload、存档 schema、主场景顶层结构
- `scripts/yu_qun.gd`、`scripts/di_tu_pin_jie_yan_chu.gd`、`scripts/zhi_wu_qun.gd`
- 上一轮 33 张主动图标及其 `data/nengli/*.tres` 的既有改动（不覆盖、不回滚；仅允许为范围单位修正改必要字段）

## 白名单要点

- 修改（已跟踪）：`zhang_ben.gd`、`yu.gd`、`yu_npc.gd`、`ji_neng_fan_wei.gd`、`main.gd`、`ke_chi_wu.gd`、`ce_zhang_ben.gd`、`ce_panding.gd`、文档三份 + docx。
- 修改（上一轮未提交但已存在）：`zhan_dou.gd`、`ji_qi_chuan.gd`、`neng_li.gd`、`zhuan_shu_ku.gd`、`zhuan_shu_ku/*.gd`、`ce_zhan_dou.gd`、六份 `ce_zhuanshu_*.gd`。
- 新增：本任务包与实现报告；不改 `.godot` 以外的新资产。
- 生成物：`.godot/**` 导入缓存。

## 设计约束（审批时一并确认）

1. **Boss 咬伤按双方体型**：同体型仍 90%，小体型 Boss 对大体型玩家按小体型结算；两参旧调用必须保持 0.9。
2. **升级免伤只给玩家**：0.6 秒，避免升级同帧/下一帧被咬；精灵脉冲只动子节点，不动根节点 scale。
3. **技能范围显示与命中同源**：`JiNengFanWei` 必须调用 `Yu.ji_neng_ban_jing`，不能继续直接读 `neng.ban_jing`。
4. **固定镜头 1.0**：体型不再被镜头拉远抵消；与 1376×768 房间尺寸兼容。
5. **不降低普通接触伤害**：`MEI_CI_SHANG_HAI` 保持 1.0，避免早期难度进一步变简单。
6. **交付不 commit**：最终记 `delivery_status=review`、`handoff_status=pending`、`last_verified_commit=null`。

## 执行中范围变更

### 2026-11-10 · 并行交付白名单登记（不改变 TASK-019 实现边界）

已批准计划把以下两项作为与 TASK-019 并行的独立交付；它们不属于 TASK-019 的 gameplay 实现，也不进入 TASK-019 的验收范围。为了让 `check_task_scope.py` 能区分“计划内并行交付”与“越界改动”，将其路径登记到 manifest 白名单：

- **计划 D · 鲸鲨首领战 BGM 试听**：`tools/yinyue/shengcheng_yinyue.py`（修改）、`tools/yinyue/bgm_jing_sha.mmp`（新增）、`docs/音乐试听_鲸鲨首领战_2026-11-10.md`（新增）；试听 WAV 只落在被 `.gitignore` 忽略的 `build/音乐试听/`，不接 `BGM_QU_MU`、不进 `assets/`。
- **计划 E · Gemini 特效需求 v1.2**：`docs/技能图标与特效需求_Gemini_2026-11-10.md`（新增/改写）；只改 docs。

同时修正 manifest 的既有文件归类：`zhan_dou.gd`、`ji_qi_chuan.gd`、`neng_li.gd`、`ce_zhan_dou.gd` 是基线中已跟踪的既有文件，原先误放在 `allowed_new_files`，现移入 `allowed_existing_files`；内容改动仍只限 TASK-019 声明的船战公式与断言。

这两项并行交付的验收由主代理按原计划执行（音乐：时长/采样率/峰值/循环端点；文档：数量口径与 33 张已完成图标禁止重画），不与 TASK-019 的八步门禁混同。

### 2026-11-10 · TASK-020 并行任务白名单登记（只登记，不并入 TASK-019）

TASK-020「九宫格房间化」是用户与 TASK-019 同一轮确认的独立任务，有独立任务包、独立基线与独立范围。它在 TASK-019 之后修改 `scripts/yu_qun.gd` 并把 `docs/development_tasks/TASK-020_jiu_gong_ge_fang_jian/**` 加入仓库，所以 TASK-019 的 scope check 会看到这些路径。为避免把「已批准的后续任务」误报成 TASK-019 越界：

- `scripts/yu_qun.gd` 移入 `allowed_existing_files`；
- `docs/development_tasks/TASK-020_jiu_gong_ge_fang_jian/**` 加入 `allowed_new_files`。

这两项仅用于跨任务识别：TASK-019 的实现与验收仍只包含 `SCOPE_PROPOSAL.md`「范围内」列出的内容；`yu_qun.gd` 的房间刷怪/换房逻辑归 TASK-020，不写进 TASK-019 实现报告，也不由 TASK-019 的测试断言负责。manifest 的 `forbidden_systems` 同步改为「TASK-019 自身不得实现 TASK-020 房间逻辑；TASK-020 在独立范围内实现」。
