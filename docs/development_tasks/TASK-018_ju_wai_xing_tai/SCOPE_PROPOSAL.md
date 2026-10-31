# TASK-018 范围提案（SCOPE_PROPOSAL）

## 范围内

- **形态数据层**：新增 `scripts/xing_tai.gd`（`Resource` + `class_name XingTai`）；`data/xingtai/` 三个形态表（灯笼鱼 / 电鳐 / 旗鱼）；`data/donghua/` 两个单帧 `SpriteFrames`（电鳐 / 旗鱼，动画名统一 `"you"`）。
- **局外存档层**：新增 Autoload `CunDang`（`scripts/cun_dang.gd`）：`user://shenhaishiji_jin_du.json` schema v1，累计胜利解锁、当前形态选择、损坏回退、调试解锁/清空、胜利瞬间写档。
- **局内接入**：`ZhangBen` 增加 `dang_qian_xing_tai` / `xing_tai_yi_ying_yong` / `kai_ju_xing_tai()` / `chong_zhi_bao_liu_xing_tai()`；`Yu` 增加 `ying_yong_xing_tai()` 并在 `_ready()` 应用；`Main._ready()` 首帧补 `camera.zoom`。
- **入口与结算**：新增 `scenes/XingTaiXuanZe.tscn` + `scripts/xing_tai_xuan_ze.gd`（动态三卡、锁定状态、当前形态、编辑器调试按钮）；`JieSuan.tscn` 新增 `HuanXingTai` 按钮与 `JieSuoTiShi` 解锁提示，`ChongKai` 改为保留形态。
- **项目配置**：`project.godot` 新增 `CunDang` Autoload（排在 `ZhangBen` 之后），`run/main_scene` 改为 `res://scenes/XingTaiXuanZe.tscn`。
- **测试**：新增 `tests/ce_jie_suo.gd`（门禁第 7 步）；`ce_shu_ju` / `ce_zhang_ben` / `ce_bian_jie` / `ce_panding` 增加形态与入口断言；`pao_pi.bat` 扩为八步。

## 范围外（移交后续任务）

- 第 4 个形态、形态升级/皮肤、局外货币 → 新任务
- 难度两档、音效、美术精修 → 新任务
- 地图逐格封锁 → TASK-016
- 安卓导出与 TapTap 提审 → TASK-010
- 能力扩展（剑鱼长矛 / 桶眼鱼隐身）→ TASK-014 后续
- NPC 新行为、鱼种扩表 → 不在本任务

## 零触碰清单

- `.agents/skills/**`（只读）
- `tests/` 既有文件不得删除（可改断言）
- `scripts/yu_npc.gd` / `scripts/yu_qun.gd` / `scripts/zhan_dou.gd` / `data/yuzhong/**` / `data/nengli/**`（本任务不改）
- `scenes/Main.tscn` / `scenes/Yu.tscn`（本任务不需要改场景树）
- 旧存档兼容：不存在旧局外存档，schema 从 v1 开始

## 白名单要点

- 新增：`scripts/xing_tai.gd`、`scripts/cun_dang.gd`、`scripts/xing_tai_xuan_ze.gd`、`scenes/XingTaiXuanZe.tscn`、`data/xingtai/*.tres`、`data/donghua/*_1zhen.tres`、`tests/ce_jie_suo.gd`、`tests/huai_xing_tai.tres`、本任务包。
- 修改：`project.godot`、`scripts/zhang_ben.gd`、`scripts/yu.gd`、`scripts/main.gd`、`scripts/jie_suan.gd`、`scenes/JieSuan.tscn`、`tests/ce_zhang_ben.gd`、`tests/ce_bian_jie.gd`、`tests/ce_shu_ju.gd`、`tests/ce_panding.gd`、`tests/pao_pi.bat`、文档三份 + docx。
- 生成物：`.godot/**` 导入缓存（编辑器/无头导入自动更新）。

## 设计约束（审批时一并确认）

1. **局外存档独立于账本**：`CunDang` 只管跨局/跨启动；`ZhangBen.chong_zhi()` 保持纯复位，不在其中自动装形态。
2. **存档用 JSON**：损坏时静默回退默认且不覆盖原文件，避免 `ERROR` 污染门禁。
3. **形态在切 Main 前应用**：保证 `Yu._ready`、经验条、能力弹窗首帧就正确。
4. **胜利瞬间写档**：`CunDang` 监听 `ZhangBen.ju_jie_shu`，玩家在结算页直接退出也不丢解锁。
5. **交付不 commit**：任务包最终记 `delivery_status=review`、`handoff_status=pending`、`last_verified_commit=null`。

## 执行中范围变更

（暂无）
