# TASK-019 集成交接（INTEGRATION_HANDOFF）

## 1. 功能目的与所有者

- **目的**：修复首领小体型仍秒杀升级玩家；加深体型成长反馈；统一技能范围换算；放大可吃红光；提高人类船战双向伤害。
- **所有者**：student-01（TASK-019）。

## 2. 运行时入口

- 主场景：`res://scenes/Main.tscn`。
- 玩家：`res://scenes/Yu.tscn` → `scripts/yu.gd`。
- 首领：`res://scripts/yu_npc.gd`。
- 范围指示：`scripts/neng_li_ui.gd` → `scripts/ji_neng_fan_wei.gd`。
- 船战：`scripts/ji_qi_chuan.gd` + `scripts/zhan_dou.gd`。
- 相机：`scripts/main.gd` → `Camera2D`。

## 3. 输入与消费接口

- `ZhangBen.dang_qian_ti_xing`（当前体型=血量）、`ti_xing_shang_xian()`（上限）、`sheng_ji`（升级信号）、`shou_shang()`。
- `Yu.scale`、`Yu._shen_wei()`、`$AnimatedSprite2D`、`jin_ru_wudi()`。
- `NengLi.ban_jing`、`ban_jing_shen_wei`、`dang_zhi()`。
- `JiNengFanWei.xian_shi()`。
- `ZhanDou.yao_ji_shang_hai()`、`jiu_yao_ji_shang_hai()`。
- `JiQiChuan.shou_dao_yao_ji()` 与船招常量。
- `Main._shi_jiao_bei()`、`Camera2D`。

## 4. 输出、提供接口与信号

- `ZhangBen.ti_xing_dao_chi_du()`：每 5 点体型 ×1.06 里程碑。
- `Yu.ti_chang()`：当前形态帧宽 × `scale.x`。
- `Yu.fan_wei_xiu_zheng(shijie, zui_xiao_bei)`：世界半径视觉下限。
- `Yu.ji_neng_ban_jing(neng, dang, zui_xiao_bei)`：主动技能世界半径唯一入口。
- `YuNpc.boos_yao_shang_hai(shou_ti, zui_ba, gong_ti := -1.0)`：第三参可选，兼容旧调用。
- `JiQiChuan.WAN_JIA_TI_XING_SHANG_HAI_BI`：船招按玩家体型加成。
- `JiNengFanWei.xian_shi(..., wan_jia: Yu = null)`：可选玩家实例。
- 信号：只接收 `ZhangBen.sheng_ji`，不新增信号。

## 5. 状态所有者与持久化

- `ZhangBen` 仍是等级/当前体型/上限唯一真源；不新增持久化状态。
- `Yu` 的无敌计时是瞬时状态；升级脉冲 tween 只存在内存。
- 船战伤害每次读取玩家当前体型，不缓存。
- 存档 schema 不变。

## 6. 关键场景、脚本、配置与测试

- `scripts/zhang_ben.gd`、`scripts/yu.gd`、`scripts/yu_npc.gd`、`scripts/zhan_dou.gd`、`scripts/ji_qi_chuan.gd`、`scripts/neng_li.gd`、`scripts/ji_neng_fan_wei.gd`、`scripts/main.gd`、`scripts/ke_chi_wu.gd`、`scripts/zhuan_shu_ku/*.gd`。
- `tests/ce_zhang_ben.gd`、`tests/ce_zhan_dou.gd`、`tests/ce_panding.gd`、`tests/ce_zhuanshu_*.gd`。
- `data/nengli/*.tres`（仅在单位语义需要时改字段，不改 schema）。

## 7. 集成步骤

1. 先合 TASK-019，跑 `ce_zhang_ben`/`ce_zhan_dou`/`ce_panding` 与八步门禁。
2. 确认 `main.gd` 相机常量为 1.0；TASK-020 在此之后接手房间 limit，不再改相机常量。
3. 确认 `tests/ce_panding.gd` 的相机断言已改为 1.0；TASK-020 只追加房间用例，不覆盖这些断言。
4. 确认 `Yu.ji_neng_ban_jing` 与 `JiNengFanWei` 调用一致；TASK-020 不改范围逻辑。
5. 重导 APK，检查无 ERROR。

## 8. 禁止直接访问与冲突热点

- 禁止 TASK-020 直接改 `zhang_ben.gd`/`yu_npc.gd`/`ji_qi_chuan.gd`/`zhan_dou.gd`。
- 禁止 TASK-020 重写 `ce_panding.gd` 的相机/船战/Boss 断言；只能追加。
- 禁止在 `Yu._shen_wei()` 与 `ti_chang()` 之间混用单位。
- 禁止把已经乘过 `_shen_wei()` 的进化半径再乘一次。
- 禁止把升级免伤连到 `YuNpc`。

## 9. 必跑集成检查与最新验证基线

- `headless --import` 退出码 0。
- `tests/ce_zhang_ben.gd`、`tests/ce_zhan_dou.gd`、`tests/ce_panding.gd` 全 passed。
- `tests/pao_pi.bat` 八步全绿。
- `check_task_scope.py check` 无违例。
- F5 手测同体型/小体型/升级三种咬伤、6 身位范围圈、Lv.1 vs Lv.10 体型、船战伤害。
- 最新验证基线由 `TASK_STATE.json` 记录；当前尚未实现。

## 10. 已知限制与待参与

- 尚未实现；学习证据为空。
- Lv.9 后体型是否超出单房间视野需 TASK-020/试玩确认。
- 固定 1.0 镜头是对策划案“每级拉远 10%”的主动偏离，后续如需极端体型镜头另开任务。
- BGM 与特效文档不在本任务内。
