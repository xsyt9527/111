# TASK-011 范围提案（SCOPE_PROPOSAL）

## 范围内

- **虚拟摇杆**：新建 `scenes/YaoGan.tscn`（CanvasLayer：底板 + 摇杆头，左下角）+ `scripts/yao_gan.gd`（限幅、归一化方向、松手归零）
- **玩家转向模型**：`yu.gd` 删除 `mubiao_dian`/`TINGZHI_JULI` 链路，新增朝向角与转向速率（随体型下降：基准 4.0 / tixing），按朝向 × 速度前进
- **吞噬门槛**：`TUN_CHI_BEI_LV := 1.1`——≥1.1 才整吞；0.9~1.1 中间带本课"无事发生"（咬击留给 TASK-012）；伤区同步按 ×1.1 判定
- **体型即血量**：`_shoushang()` 改为 `tixing *= 0.85` + 缩小 tween；`tixing < 0.5` 触发结算；删除 `xue_liang`/`zuida_xue`/`xue_liang_bian_hua`
- **体型显示**：Main 移除 `XueLiangTiao` 实例，新增体型数值/条
- **测试**：新增 `tests/ce_yao_gan.gd`；改 `tests/ce_panding.gd`；`pao_pi.bat` 加一步

## 范围外（移交后续任务）

- 咬击（自动锁定嘴/身部位）与控制条（电麻/毒晕）→ TASK-012
- 饥饿条与消化槽 → TASK-013
- 能力系统与三选一退役 → TASK-014
- NPC 行为状态机、互吃、索敌 → TASK-015
- 地图九宫格、空间压缩、人类战、局外形态 → TASK-016~018
- 安卓导出 → TASK-010（本课完成后恢复）

## 零触碰清单

- `data/**`（鱼种表、卡池、阈值表字段结构）
- `scripts/zhang_ben.gd` / `scripts/qiang_hua_dan_chuang.gd` / `scripts/jing_yan_ui.gd`（经验与三选一暂留）
- `scripts/yu_qun.gd`（生成器本课不动）
- `.agents/skills/**`（只读）
- `tests/` 既有文件不得删除（可改断言）

## 白名单要点

- 新增：`scenes/YaoGan.tscn`、`scripts/yao_gan.gd`（+ .uid）、`tests/ce_yao_gan.gd`（+ .uid）+ 三份报告
- 修改：`scripts/main.gd`、`scripts/yu.gd`、`scripts/yu_npc.gd`（如需）、`scenes/Main.tscn`、`scenes/Yu.tscn`（如需）、`tests/ce_panding.gd`、`tests/pao_pi.bat`
- 本任务特色：**第一次正式的玩法重构**——退役两条链路（点击移动、血条），门禁必须同步保持全绿
