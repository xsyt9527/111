# 实现报告 — TASK-024 技能/被动对机械船统一生效 + 自动通关难度评估

日期：2026-11-13
状态：实现完成，八步门禁全绿；机器人自动通关一局；F5 实机复核与难度拍板待用户；**未 commit、未 push**。

## 一、用户目标

1. 玩家的主动技能与被动必须能作用于机械船（`JiQiChuan`），不能只对普通鱼生效。
2. 由我实际运行一局并尝试通关，用数据评估当前难度是否足够。

## 二、实现

### 1. 机械船鸭子契约（`scripts/ji_qi_chuan.gd`）

- `add_to_group(&"ji_qi_chuan")`、`shi_boss := true`；**不加入** `yu_npc`，避免刷怪、吞噬、同类 AI 把船当鱼。
- 新增统一受伤入口：
  - `ji_neng_dui_bi_ti_xing()`：需要「对方体型」的技能以**玩家当前体型**为参照，避免船的 `tixing=99` 直接进 3% 咬伤公式导致伤害爆表。
  - `shou_dao_ji_neng(liang)`：1「级」= `JI_NENG_MEI_JI_HP=8` 船体 HP。
  - `shou_dao_ji_neng_bai_fen(bai_fen)`：`max(xue) × 百分比 × 0.5`，首领固定减半。
  - `shou_dao_ji_neng_hp(shang_hai)`：已换算 HP 的入口，供撕裂齿/腐肉诱饵等联动使用。
  - `shou_zhi_jie_shang(liang)`：兼容「无视防御」通道，仍按级→HP。
- 控制与状态：
  - `jia_dian_ma` / `jia_du_yun`：0~100 条，满条短失控（`YUN_XUAN_SHI_CHANG=1.2` 秒）；
  - `ding_zhu` / `jia_zhuang_tai`：单次上限 `KONG_ZHI_DAN_CI_SHANG_XIAN=1.2` 秒；3 秒抗性窗口内再控 ×`0.35`；
  - 六状态白名单 `shi_hua/feng_kuang/kong_ju/mei_huo/zhi_mang/shu_fu`；
  - `zai_kong_zhi()` 会跳过船的下一次出招，避免「控住→下一招必中」；
  - `jia_qiang_suan`：酸蚀每秒按 `mei_miao × 8` 扣船体 HP，`_geng_xin_zhuang_tai(delta)` 每帧结算；
  - `tui_kai`：单次位移最多 3px；`bei_chi`：no-op，船不可整吞；
  - `shi_fang_gao_liang` / `xian_shi_deng_ji`：高亮与 Lv.99 标记。
- 船原有 `si_le / xue / zui_da_xue / 沉没流程` 保持不变；船血仍按玩家体型 ×40（本次探针开局 21 体型 → 840 HP）。

### 2. 玩家统一扫描与结算（`scripts/yu.gd`、`scripts/zhuan_shu_ku/*.gd`）

- `Yu.di_ren_lie()`：合并 `yu_npc` + `ji_qi_chuan`，按 `instance_id` 去重，过滤 `si_le`。
- `_ji_neng_dui_bi_ti(mu)`：船走 `ji_neng_dui_bi_ti_xing()`，普通鱼返回真实 `tixing`。
- `zhan_dou_bai_fen_shang(mu, bai_fen)`：船走 `shou_dao_ji_neng_bai_fen`；普通鱼保留「`tixing × 百分比`，首领减半」。
- `_zhuan_shu_shang_npc(mu, liang, dian_ma, du_yun)`：船走 `shou_dao_ji_neng`，普通鱼走 `shou_dao_yao_ji`。
- 主动/被动中的 `get_nodes_in_group("yu_npc")` 扫描统一替换为 `di_ren_lie()`，覆盖放电、声呐、水刃、酸雾、电网、钻突、剧毒突刺、真空刃、幽灵弹、破空俯冲、孔雀、石化、近身即麻、共生海葵、冲撞、落雷等。
- 六份进化模块（分鱼/红鱼/蓝鱼/巨口鱼/野灯笼鱼/棕鱼）各自新增 `_di_ren()` 助手：优先 `wan.di_ren_lie()`，旧测试假人回退 `yu_npc`；船分支通过 `has_method` + `call` 走鸭子接口。
- 保留的少量 `yu_npc` 直接扫描均有鱼专属语义：鲲吞天地只吸可整吞的鱼、吞星只吃灯笼鱼/肉块、蓝鱼聚群只数钻光鱼；船 `tixing=99` 本就不在可吞范围。

## 三、新增断言（`tests/ce_panding.gd`，21 条）

- 船在 `ji_qi_chuan` 组、**不在** `yu_npc` 组、`shi_boss=true`、鸭子方法存在。
- 技能参照体型取玩家 9.0（不是船 99）。
- `shou_dao_ji_neng(1) = 8 HP`；`shou_dao_ji_neng_bai_fen(10) = 360×10%×0.5 = 18 HP`；已换算 HP 入口直扣。
- 定身 2 秒 → 1.2 秒上限；抗性窗口内再控 → 0.42 秒；抗性窗口重置 3 秒。
- 六状态白名单：石化可挂、白名单外返回 false。
- 酸蚀每秒 2 级 = 16 HP，2 秒 32 HP。
- 击退单次最多 3px；`di_ren_lie` 含船、含存活鱼、过滤死亡鱼。
- 断言后复原船血与状态，原有船战断言继续全绿。

## 四、门禁结果

- `headless --import`：退出码 0，无 `SCRIPT ERROR` / `Parse Error`。
- `tests/pao_pi.bat` 八步：
  `232 / 25 / 1422 / 8 / 20 / 144 / 1287 passed`，0 failed，无 ERROR，合计 **3138 断言**，脚本输出「全绿：可以交付」。
- `validate_task.py`：`VALID: TASK-024 v1 (plan_driven)`。
- `check_task_scope.py check`：收尾复跑结果见交付说明；实现期检查为 `21 allowed, 185 unchanged pre-existing, 0 violation(s)`（临时探针日志已删除）。

## 五、机器人自动通关实测

- 工具：临时 `tests/tong_guan_probe.tscn`，无头实例化真实 `Main.tscn`，自动转向吃鱼/植物、升级三选一/进化选第一张、主动技能冷却好就放、船出现后攻击玻璃舱。
- 运行参数：`--headless --quit-after 42000`，`Engine.time_scale=3`（3 倍速压缩试跑；游戏内逻辑仍按同一 `delta` 换算，机器人转向精度反而更粗）。
- 结果：

| 指标 | 数值 |
| --- | --- |
| 结局 | **胜利（SHENG_LI）** |
| 局内时长 | 557.1 秒（9 分 17 秒） |
| 玩家等级 / 体型 | Lv.15 / 峰值 24.0（开局 1.0，最低 0.9） |
| 累计掉体型 | 43.9 |
| 饥饿最低 | 87.5（几乎全程接近满值） |
| 主动技能次数 | 174 次 |
| 三选一 / 进化 | 15 张 / 1 次 |
| 船出现 | 487.3 秒，HP 840 |
| 船沉时剩余 | 5 HP（下一口/下一跳击杀） |
| 船战时长 | 约 65~70 秒（487.3 → 557.1；探针未单独捕获沉船帧） |
| 自动判负线 | 600 秒，通关时仍余约 43 秒 |

- 难度判断（**机器人试跑，不等于真人体验**）：
  - 机器人 8 分钟内只掉 18 点体型，饥饿最低 87.5；船战最深掉到 16.4/22.5（约 73%），随后升级回满并击沉船。
  - 以「每帧完美转向 + 技能一好就放 + 大量吃植物」的上限操作衡量，当前难度**偏中低**：Boss 更像 DPS 检查，而不是生存压力；植物密度让饥饿几乎不构成威胁。
  - 真人会因转向失误、技能空放、躲避船招而明显更吃紧，所以不能据此直接判「太简单」；但也没有出现「机器人险些失败」的迹象。
  - 若后续要加难度，优先可调的三个旋钮是：船体 HP 系数（当前体型 ×40）、技能等级→HP 汇率（当前 8）、饥饿下降/植物密度；本轮**没有**擅自改这些数值。

## 六、待人工确认

- F5 船战中放主动技能，确认船血条下降、技能动画/伤害数字正常。
- F5 测试控制技能：船应有短失控，但不会 3 秒内被无限锁死。
- F5 用普通鱼战斗复测，确认与改动前一致。
- 用户根据探针数据决定是否调整难度；调整需另开任务/明确授权。

## 七、边界与清理

- 未新增 Autoload、未改存档 schema、未改主场景顶层结构。
- 未把船并入 `yu_npc`；未改普通鱼/玩家既有伤害与掉落数值。
- 临时探针 `tests/tong_guan_probe.gd/.tscn/.uid` 与运行日志在交付前删除。
- 本轮未 commit / 未 push。
