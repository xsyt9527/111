# 集成交接 — TASK-024

## 交付物

- `scripts/ji_qi_chuan.gd`：机械船鸭子契约与 HP 换算/控制兼容层。
- `scripts/yu.gd`：`di_ren_lie()` 统一敌人列表与三个统一结算入口；全部主动/被动扫描替换。
- `scripts/zhuan_shu_ku/*.gd`：进化专属技扫描改用玩家统一敌人列表。
- `tests/ce_panding.gd`：新增船兼容断言。
- `docs/development_tasks/TASK-024_ji_xie_chuan_ji_neng_jian_rong/IMPLEMENTATION_REPORT.md`：实现与难度实测报告。
- 临时 `tests/tong_guan_probe.gd/.tscn` 验证后删除。

## 对外接口

### JiQiChuan

| 方法 | 说明 |
| --- | --- |
| `ji_neng_dui_bi_ti_xing() -> float` | 供鱼技能公式取「对方体型」参照（玩家当前体型） |
| `shou_dao_ji_neng(liang, lai_yuan=null)` | 等级伤害→HP（`liang * JI_NENG_MEI_JI_HP`） |
| `shou_dao_ji_neng_bai_fen(bai_fen, lai_yuan=null)` | 百分比直伤：`max(xue)*bai_fen/100*0.5` |
| `shou_dao_ji_neng_hp(shang_hai, lai_yuan=null)` | 已换算 HP 伤害 |
| `shou_zhi_jie_shang(liang, lai_yuan=null)` | 兼容「无视防御」通道，按级→HP |
| `jia_dian_ma / jia_du_yun(liang)` | 电麻/毒晕条，满 100 触发短失控 |
| `ding_zhu(shi_chang)` | 定身，单次上限+抗性 |
| `jia_zhuang_tai(ming, shi_chang, mu_dian=0) -> bool` | 六状态白名单，返回是否成功 |
| `you_zhuang_tai / zhuang_tai_sheng_yu / zai_kong_zhi` | 查询 |
| `jia_qiang_suan(shi_chang, mei_miao, bei_yao=true)` | 酸蚀 DoT |
| `diao_rou(shu, mei_kuai_ti_xing=0.3, ...)` | 掉肉折算 HP |
| `tui_kai(fang, ju_li)` | 极轻位移，单次 ≤3px |
| `bei_chi(...)` | no-op，船不可整吞 |
| `shi_fang_gao_liang / xian_shi_deng_ji` | 高亮/等级标记兼容 |

### Yu

| 方法 | 说明 |
| --- | --- |
| `di_ren_lie() -> Array[Node2D]` | `yu_npc` + `ji_qi_chuan`，去重过滤死亡 |
| `_ji_neng_dui_bi_ti(mu) -> float` | 船→参照体型；鱼→真实 tixing |
| `zhan_dou_bai_fen_shang(mu, bai_fen)` | 百分比伤害统一入口 |
| `_zhuan_shu_shang_npc(mu, liang, dian_ma=0, du_yun=0)` | 等级伤害统一入口 |

## 门禁结果

- [x] `validate_task.py` VALID（`VALID: TASK-024 v1 (plan_driven)`）
- [x] `headless --import` 0 ERROR
- [x] `tests/pao_pi.bat` 八步全绿：232 / 25 / 1422 / 8 / 20 / 144 / 1287，合计 3138 断言，0 failed，无 ERROR
- [x] `check_task_scope.py check` 零违规（实现期 21 allowed / 185 unchanged pre-existing / 0 violation）
- [x] 自动通关探针完整一局：`RESULT=SHENG_LI`，557.1 秒，Lv.15，船 840 → 5 HP，船战约 65~70 秒
- [x] 实现报告：`IMPLEMENTATION_REPORT.md`

## 风险与待确认

- 未 commit / 未 push；所有改动留在工作区，由用户决定提交。
- 自动探针为机器人操作，只能作为难度下限参考。
- 船体 HP 换算常量 8 与控制抗性参数需要 F5 实机手感确认。
