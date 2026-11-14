# TASK-024 开发提示

按 `TASK_MANIFEST.json` 的三个 step 顺序实现；每个 step 完成后先自检再进入下一步。

## step-01 机械船鸭子契约与 HP 换算通道

- `scripts/ji_qi_chuan.gd`：`add_to_group(&"ji_qi_chuan")`、`shi_boss := true`；新增 `ji_neng_dui_bi_ti_xing()`、`shou_dao_ji_neng()`、`shou_dao_ji_neng_bai_fen()`、`shou_dao_ji_neng_hp()`、`shou_zhi_jie_shang()`、`jia_dian_ma()`、`jia_du_yun()`、`ding_zhu()`、`jia_zhuang_tai()`/`you_zhuang_tai()`/`zhuang_tai_sheng_yu()`、`zai_kong_zhi()`、`jia_qiang_suan()`、`diao_rou()`、`tui_kai()`、`bei_chi()`、`shi_fang_gao_liang()`、`xian_shi_deng_ji()`。
- 换算口径：1「级」= `JI_NENG_MEI_JI_HP`（8）HP；百分比直伤 = `max(xue) × 百分比 × 0.5`；控制单次 ≤ `KONG_ZHI_DAN_CI_SHANG_XIAN`（1.2 秒），抗性窗口 `KONG_ZHI_KANG_XING_SHI_CHANG`（3 秒）内再控 ×`KONG_ZHI_KANG_XING_XI_SHU`（0.35）；击退每次 ≤3px；`bei_chi` 留空。
- `_geng_xin_zhuang_tai(delta)` 必须由 `_process` 每帧调用，抗性先减、再减状态、再结算酸蚀 DoT。
- 船的 `si_le`/`xue`/`zui_da_xue`/沉没流程保持不变。

## step-02 玩家技能与被动统一扫描与结算

- `scripts/yu.gd`：
  - `di_ren_lie()`：合并 `yu_npc` 与 `ji_qi_chuan`，按实例 id 去重、过滤 `si_le`。
  - `_ji_neng_dui_bi_ti(mu)`：船走 `ji_neng_dui_bi_ti_xing()`，普通鱼返回真实 `tixing`。
  - `zhan_dou_bai_fen_shang(mu, bai_fen)`：船走 `shou_dao_ji_neng_bai_fen`，鱼保留「tixing×百分比，首领减半」。
  - `_zhuan_shu_shang_npc(mu, liang, dian_ma, du_yun)`：船走 `shou_dao_ji_neng`，鱼走 `shou_dao_yao_ji`。
  - 所有主动/被动里 `get_nodes_in_group("yu_npc")` 扫描改 `di_ren_lie()`；单体选择、范围、扇形、DoT、控制、击退、标记全部走上述入口。
- `scripts/zhuan_shu_ku/*.gd`：同样把 `yu_npc` 扫描改为 `wan.di_ren_lie()`；单体的 `tixing` 比较与「最大体型」选择读 `wan._ji_neng_dui_bi_ti(mu)` 或船的 `ji_neng_dui_bi_ti_xing()`。
- 普通鱼路径的数值与行为必须与改动前一致；只增加船分支。

## step-03 回归断言、自动通关与门禁文档

- `tests/ce_panding.gd` 只追加断言：船组/`shi_boss`、等级伤害换算、百分比减半、控制上限/抗性、DoT、`di_ren_lie` 去重与过滤、进化模块可扫描到船。
- 临时探针 `tests/tong_guan_probe.tscn`：真实实例化 Main，自动吃鱼/选卡/进化/放技能/打船；结束打印 `TONG_GUAN|...` 指标后退出。
- 依次运行：
  - `headless --import`
  - `tests/pao_pi.bat` 八步
  - `PYTHONUTF8=1 python .agents/skills/godot-guided-feature-workflow/scripts/validate_task.py docs/development_tasks/TASK-024_ji_xie_chuan_ji_neng_jian_rong`
  - `PYTHONUTF8=1 python .agents/skills/godot-guided-feature-workflow/scripts/check_task_scope.py check docs/development_tasks/TASK-024_ji_xie_chuan_ji_neng_jian_rong`
- 更新任务索引/引擎词表/学习路线/Word 词表，写实现报告；删除临时探针与日志；不 commit、不 push。

## 全局约束

- 所有新增自定义名用拼音 + 中文注释；每次新代码附当课引擎词表。
- 不把船并入 `yu_npc` 组；不改普通鱼/玩家既有数值；不新增 Autoload；不改存档 schema。
- 自动探针结论必须标注「机器人试跑」，不能冒充真人通关。
