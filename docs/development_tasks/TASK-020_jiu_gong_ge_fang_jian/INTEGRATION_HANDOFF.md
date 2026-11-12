# TASK-020 集成交接（INTEGRATION_HANDOFF）

## 1. 功能目的与所有者

- **目的**：把现有 4128×2304 九宫格背景的 9 个 1376×768 区域切成九个可玩房间：相机房间 limit、换房淡入淡出、按房间刷怪、Boss 房 8；保留人类战九图演出与船战相机。
- **所有者**：student-01（TASK-020）。
- **前置**：TASK-019 v1 已完成并验证（相机固定 1.0、范围/伤害收口）。

## 2. 运行时入口

- 主场景：`res://scenes/Main.tscn`。
- 相机：`scripts/main.gd` → `Camera2D`。
- 鱼群：`scripts/yu_qun.gd`。
- 九图演出：`scripts/di_tu_pin_jie_yan_chu.gd`（只读，不改流程）。
- 人类战：`scripts/main.gd` 的 `_bo_fang_ren_lei_yan_chu()` / `_on_ren_lei_yan_chu_jie_shu()` / `scripts/ji_qi_chuan.gd`。

## 3. 输入与消费接口

- `Main.DI_TU_MEI_GE`（1376×768）、`DI_TU_MING`、`qu_yu_ming()`、`_xian_shi_xiao_xi()`。
- `DiTuPinJieYanChu.DI_TU_CHI_CUN`、`MEI_GE_CHI_CUN`、`ge_zi_qu()`、`wan_jia_pian()`（规则必须同源）。
- `Camera2D` 的 `limit_left/top/right/bottom`、`offset`、`zoom`、`reset_smoothing()`、`position_smoothing_enabled`。
- `Yu.global_position`、`Yu.fang_xiang`、`Yu._xian_zhi_zai_di_tu_nei()`。
- `YuQun._shi_jiao_fan_wei()`、`shua_xin_ting_zhi`、`YuNpc.shi_boss`、`Dingshi`。
- `ZhangBen.JieDuan` / `ji_qi_chuan.si_le`（人类战状态判定）。
- Boss 常量 `BOOS_CHU_SHENG_DIAN`、`BOOS_XUN_LUO_DIAN`。

## 4. 输出、提供接口与信号

- `Main.dang_qian_fang_jian`：当前房间 0..8。
- `Main.fang_jian_qu(pian) -> Rect2`：房间矩形纯函数。
- `Main.qu_yu_pian(shijie_wei) -> int`：世界坐标 → 房间号纯函数。
- `Main._suo_fang_jian(pian)` / `Main._suo_quan_tu()`：相机 limit 切换。
- `Main._qie_huan_fang_jian(pian)`：换房协程（淡出/黑场/淡入）。
- `YuQun.fang_jian_qu`：当前刷怪房间矩形。
- `YuQun.qie_huan_fang_jian(qu)`：更新房间、清普通鱼、重置刷新。
- 信号：不新增；沿用九图演出 `jie_shu` 与船战 `bei_ji_bai`。
- 黑幕：运行时 `CanvasLayer(layer=100)` + `ColorRect`，不写入 `Main.tscn`。

## 5. 状态所有者与持久化

- `Main` 是 `dang_qian_fang_jian` 唯一所有者；只存内存，新局重置为 4。
- `YuQun` 只持有当前房间矩形；Boss 仍由 Main 生成/管理，不是 YuQun 子节点。
- 不修改 `user://` 存档 schema；不持久化房间进度。
- 人类战全图相机是运行时状态；船沉/结算后无需持久化。

## 6. 关键场景、脚本、配置与测试

- `scripts/main.gd`、`scenes/Main.tscn`（尽量不改，运行时设置优先）、`scripts/yu_qun.gd`、`tests/ce_panding.gd`（只追加房间用例）。
- 配置：`DI_TU_MEI_GE`、`DI_TU_CHI_CUN`、`FANG_JIAN_HUAN_CHU_SHI_JIAN=0.12`、`FANG_JIAN_JIN_BIAO_LIU=6`、`REN_LEI_QUAN_TU_OFFSET=(0,-260)`、`REN_LEI_QUAN_TU_ZOOM=0.85`。
- 测试：`ce_panding` 房间矩形/越界/切房目标；八步门禁 `tests/pao_pi.bat` 仍八步。

## 7. 集成步骤

1. 确认 TASK-019 已合并：`SHI_JIAO_MEI_JI=0.0`、`_shi_jiao_bei()==1.0`，相机断言已改 1.0。
2. 在 TASK-019 验证后 capture TASK-020 基线（避免把 TASK-019 改动误判为本任务新增）。
3. 按 step-01→03 实现；每步跑 `ce_panding`。
4. 运行 `tests/pao_pi.bat` 连续两轮；F5 手测九格与人类战。
5. 更新任务包状态与文档；不 commit / 不 push。

## 8. 禁止直接访问与冲突热点

- 禁止改 `zhang_ben.gd` / `yu_npc.gd` / `ji_qi_chuan.gd` / `zhan_dou.gd` / `ji_neng_fan_wei.gd`（TASK-019 所有）。
- 禁止改 `di_tu_pin_jie_yan_chu.gd` 的九图切片/演出流程（用户认可的前动画）。
- 禁止用 `get_children().clear()` / 整体 `queue_free()` 清 YuQun（会删 Timer，且可能误删 Boss——虽然 Boss 不在 YuQun，但必须按类型过滤）。
- 禁止在 `_process` 每帧重设房间 limit（只在 `_suo_fang_jian`/`_suo_quan_tu` 切换）。
- 禁止换房时把玩家夹到整图边界而不是新房 6px（会导致反复越界或穿房）。
- 禁止在人类战期间触发换房（`_zai_ren_lei_zhan()` 必须短路）。
- 禁止改 `project.godot`、Autoload、存档 schema、主场景顶层节点类型。

## 9. 必跑集成检查与最新验证基线

- `headless --import` 退出码 0。
- `tests/ce_panding.gd` 全 passed（含追加房间用例）。
- `tests/pao_pi.bat` 八步全绿。
- `check_task_scope.py check` 无违例。
- F5：九格逐格换房、黑场 0.24 秒、房间名、旧房清鱼/新房铺鱼、Boss 房 8、人类战九图动画与船战相机。
- 最新验证基线由 `TASK_STATE.json` 记录；当前尚未实现。

## 10. 已知限制与待参与

- 尚未实现；学习证据为空。
- 不做门锁/钥匙/顺序封印/无缝滚动；本轮只做“一格一屏 + 黑场切房”。
- Boss 固定房间 8 改变旧的全图巡逻；若用户要“Boss 破房”规则，另开任务。
- 高等级体型在 1376×768 房间内的活动空间需 F5 确认。
