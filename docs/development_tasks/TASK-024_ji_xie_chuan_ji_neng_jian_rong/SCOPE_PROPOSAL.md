# SCOPE PROPOSAL — TASK-024

## 用户原文

> 我觉得技能被动什么的应该要能对机械船使用。然后，你运行游戏自己通关一次，试试难度够不够

## 目标

1. **机械船能吃玩家的一切技能与被动**：主动技能（单体/范围/扇形/百分比/DoT/控制/击退/标记）与被动（近身麻、共生海葵、酸蚀、掉肉、选最大目标等）对 `JiQiChuan` 与对普通鱼一样生效，但伤害单位从「体型级」换算成船体 HP。
2. **船不被无限锁死**：电麻/毒晕/石化/定身等控制有单次上限与抗性窗口，船仍会出招。
3. **难度实测**：用临时自动通关探针完整跑一局，记录结果与关键指标，如实说明这是机器人下限，不等同真人体验。

## 范围

### 会改

- `scripts/ji_qi_chuan.gd`：独立组 `ji_qi_chuan`、`shi_boss=true`、鸭子契约方法、HP 换算、状态计时、DoT、轻击退、吞噬 no-op。
- `scripts/yu.gd`：`di_ren_lie()` 统一敌人列表、`_ji_neng_dui_bi_ti()` 参照体型、`zhan_dou_bai_fen_shang()` 百分比入口、`_zhuan_shu_shang_npc()` 等级伤害入口；所有主动/被动技能扫描替换。
- `scripts/zhuan_shu_ku/*.gd`：六份进化模块的敌人扫描改用玩家统一列表。
- `tests/ce_panding.gd`：只追加船兼容断言，不改既有断言。
- `docs/TASK_INDEX.md`、`docs/引擎词总表.md`、`LEARNING_ROADMAP.md`、`Godot引擎词总表.docx`：交付记录与词表。
- `project.godot`：恢复被误删的 `renderer/rendering_method.web="gl_compatibility"`（全局约束禁止删除该行）。
- 临时探针 `tests/tong_guan_probe.gd/.tscn`，验证完删除。

### 不会改

- 不把船加入 `yu_npc` 组；不改刷怪、吞噬、NPC 同类 AI。
- 不改普通鱼/玩家既有伤害、掉落、体型曲线与技能范围平衡。
- 不新增 Autoload，不改存档 schema，不改主场景顶层结构。
- 不 commit、不 push。

## 实现基线说明

本任务与 TASK-022/023 在同一批未提交改动上进行，`implementation_baseline` 沿用 TASK-023 捕获的 194 个既有改动快照（commit `bcc1f3d`），因此 `check_task_scope.py` 会把 TASK-023 期间产生的小地图/设置改动也视为「基线之后的变化」。这些文件列入 `allowed_existing_files` 仅用于让门禁能区分本任务文件与并行任务的未提交改动，不代表本任务修改了它们。

## 验收

- `validate_task.py` VALID。
- `headless --import` 无 ERROR。
- `tests/pao_pi.bat` 八步全绿、0 failed。
- `check_task_scope.py check` 零违规。
- 自动探针完整一局，输出 `TONG_GUAN|RESULT` 与结果/时长/等级/体型/受伤/技能/卡牌/船战指标。
- F5 实机：技能命中船、被动持续生效、控制短时且不锁死、普通鱼战斗不回归。
