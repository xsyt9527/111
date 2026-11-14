# 任务索引 TASK_INDEX.md

| 任务 ID | 规格 | 标题 | 审批 | 交付 | 学习 | 交接 | 所有者 | 依赖 | 路径 |
|---|---|---|---|---|---|---|---|---|---|
| TASK-001 | v4 | 玩家鱼跟随手指游动 | approved | complete | partially_demonstrated | ready | student-01 | 无 | docs/development_tasks/TASK-001_yu_liudong/ |
| TASK-002 | v1 | 鱼群生成与屏幕外回收 | approved | complete | partially_demonstrated | ready | student-01 | TASK-001 | docs/development_tasks/TASK-002_yuqun_shengcheng/ |
| TASK-003 | v2 | 大吃小判定（Area2D 碰撞 + 体型比较） | approved | complete | partially_demonstrated | ready | student-01 | TASK-001, TASK-002 | docs/development_tasks/TASK-003_dachixiao_panding/ |
| TASK-004 | v1 | 数据驱动鱼种（自定义 Resource + .tres 注册表） | approved | complete | partially_demonstrated | ready | student-01 | TASK-002, TASK-003 | docs/development_tasks/TASK-004_shuju_qudong_yuzhong/ |
| TASK-005 | v1 | 经验与成长（Autoload 账本 + 记账 + 长大 + 经验条） | approved | complete | partially_demonstrated | ready | student-01 | TASK-003, TASK-004 | docs/development_tasks/TASK-005_jingyan_chengzhang/ |
| TASK-006 | v1 | 升级三选一（强化卡注册表 + 暂停 + 不放回抽样 + 弹窗） | approved | complete | partially_demonstrated | ready | student-01 | TASK-004, TASK-005 | docs/development_tasks/TASK-006_shengji_sanxuanyi/ |
| TASK-007 | v1 | 强化生效与动画（match 六卡 + 磁吸双 Area2D + Tween + 摆尾） | approved | complete | partially_demonstrated | ready | student-01 | TASK-003, TASK-005, TASK-006 | docs/development_tasks/TASK-007_qianghua_shengxiao/ |
| TASK-008 | v2 | 血量死亡结算（血条 + 满级封顶 + 结算重开闭环 + 嘴身拆分） | approved | complete | partially_demonstrated | ready | student-01 | TASK-003, TASK-005, TASK-006, TASK-007 | docs/development_tasks/TASK-008_xueliang_siwang_jiesuan/ |
| TASK-009 | v1 | 无头自动测试（四域测试 + 坏卡红测 + 跑批门禁，产品零修改） | approved | complete | partially_demonstrated | ready | student-01 | TASK-005, TASK-006, TASK-007, TASK-008 | docs/development_tasks/TASK-009_zidong_ceshi/ |
| TASK-010 | v1 | 安卓导出与 TapTap（工具链 + APK + 签名 + 真机） | awaiting | proposed | not_started | not_started | student-01 | TASK-009 | docs/development_tasks/TASK-010_anzhuo_daochu/ |
| TASK-011 | v1 | 零期 A：摇杆 + ×1.1 吞噬门槛 + 体型即血量 | approved | complete | demonstrated | ready | student-01 | TASK-003, TASK-005, TASK-008, TASK-009 | docs/development_tasks/TASK-011_zhandou_chonggou/ |
| TASK-014 | v1 | 能力系统：吃谁得谁 + 升级三选一 + 技能按钮 | approved | complete | not_started | ready | student-01 | TASK-012, TASK-013, TASK-015, TASK-017 | docs/development_tasks/TASK-014_neng_li/ |
| TASK-018 | v1 | 局外形态解锁：三形态 + 胜利解锁 + 启动选择页 | approved | review | not_started | pending | student-01 | TASK-005, TASK-008, TASK-014, TASK-017 | docs/development_tasks/TASK-018_ju_wai_xing_tai/ |
| TASK-019 | v1 | 体型战斗手感、技能范围统一与人类船伤害修正 | approved | review | not_started | pending | student-01 | TASK-005, TASK-008, TASK-014 | docs/development_tasks/TASK-019_ti_xing_zhan_dou_fan_wei/ |
| TASK-020 | v1 | 九宫格房间化：相机边界、换房过渡、按房刷怪与 Boss 房 | approved | review | not_started | pending | student-01 | TASK-019 | docs/development_tasks/TASK-020_jiu_gong_ge_fang_jian/ |
| TASK-021 | v1 | 上帝视角小地图、受击闪白与换房安全入场 | approved | review | not_started | pending | student-01 | TASK-019, TASK-020, TASK-017 | docs/development_tasks/TASK-021_shang_di_shi_jiao/ |
| TASK-022 | v1 | 小地图黑底/首领换色、玩家面板永久被动、决战动态镜头、机械船 ×0.8、33 被动图标、特效清单 | approved | review | not_started | pending | student-01 | TASK-019, TASK-020, TASK-021 | docs/development_tasks/TASK-022_shi_jue_jing_tou_yu_tu_biao/ |
| TASK-023 | v1 | 雷达式小地图移置设置按钮下方 + 设置内地图透明度持久化 | approved | review | not_started | ready | student-01 | TASK-021, TASK-022 | docs/development_tasks/TASK-023_lei_da_xiao_di_tu/ |
| TASK-024 | v1 | 主动技能与被动对机械船统一生效 + 自动通关难度评估 | approved | review | not_started | ready | student-01 | TASK-017, TASK-019, TASK-022, TASK-023 | docs/development_tasks/TASK-024_ji_xie_chuan_ji_neng_jian_rong/ |
| TASK-025 | v1 | 房间预置鱼群：取消换房整批刷新 + 雷达九房 NPC + 后台互吃 | approved | review | not_started | pending | student-01 | TASK-020, TASK-021, TASK-023 | docs/development_tasks/TASK-025_fang_jian_yu_qun_yu_zhi/ |

TASK-025 产物：改动 `scripts/yu_qun.gd`（九房记录/惰性初始化/换房保存加载/虚拟游动互吃/档位保底）、`scripts/yu_npc.gd`（`you_yu_qun_guan_li` + 恢复载荷）、`scripts/xiao_di_tu.gd`（九房记录优先 + 其他房低 alpha）、`scripts/main.gd`（两处换房传房号）、`tests/ce_panding.gd`（删除旧欢迎鱼/安全入口断言，改写九房用例）；新增 TASK-025 任务包与 `IMPLEMENTATION_REPORT.md` / `VERIFICATION_REPORT.md` / `CODE_REVIEW.md`；临时 `tests/_tmp_fang_jian_probe.gd/.tscn/.uid` 验证后删除。
TASK-025 门禁（2026-11-14）：完整八步全绿（232 / 25 / 1422 / 8 / 20 / 144 / 1236 passed，0 failed，无 ERROR，合计 3087 断言，脚本输出「全绿：可以交付」；比 TASK-024 净减 51 条：删除旧欢迎鱼/安全入口断言、新增九房用例）；`validate_task.py` VALID；`check_task_scope.py check` 0 violation（8 allowed / 214 unchanged pre-existing）。
TASK-025 自动探针（机器人，3 倍速）：胜利，局内 576.9 秒，Lv.19 / 体型峰值 30.0 / 最低 1.9，累计掉体型 56.4，饥饿最低 96.1，主动 215 次，三选一 18 张、进化 1 次；换房 34 次、九房全部访问（`RoomSet=476301582`）；船 517.4 秒出现（1140 HP），59.5 秒击沉。结论：九房鱼群未让难度失控，机器人仍通关；真人 F5 与手机雷达帧率待拍板。**本轮未 commit、未 push**。

TASK-024 产物：改动 `scripts/ji_qi_chuan.gd`（鸭子契约/HP 换算/控制抗性/DoT/轻击退）、`scripts/yu.gd`（`di_ren_lie` + 三个统一结算入口 + 全部技能扫描替换）、`scripts/zhuan_shu_ku/*.gd`（六份进化模块）、`tests/ce_panding.gd`（新增 21 条船兼容断言）；新增 TASK-024 任务包与实现报告；临时 `tests/tong_guan_probe.gd/.tscn/.uid` 验证后删除。
TASK-024 门禁（2026-11-13）：完整八步全绿（232 / 25 / 1422 / 8 / 20 / 144 / 1287 passed，0 failed，无 ERROR，合计 3138 断言，脚本输出「全绿：可以交付」）；`validate_task.py` VALID；`check_task_scope.py check` 0 violation。
TASK-024 自动探针（机器人，3 倍速）：胜利，局内 557.1 秒，Lv.15 / 体型峰值 24.0，累计掉体型 43.9，饥饿最低 87.5，主动 174 次，三选一 15 张、进化 1 次；船 487.3 秒出现（840 HP），约 65~70 秒后击沉（沉时 5 HP）。结论：机器人上限操作下难度偏中低，真人需 F5 实测拍板。**本轮未 commit、未 push**。

TASK-023 产物：改动 `scripts/xiao_di_tu.gd`（无背景雷达绘制）、`scripts/she_zhi.gd`（设置内透明度滑条）、`scripts/cun_dang.gd`（`xiao_di_tu_tou_ming` 持久化）、`scripts/main.gd`（开局应用）、`scenes/Main.tscn`（地图移到设置按钮下方）、`tests/ce_panding.gd`（布局/映射/透明度断言）；新增实现报告。
TASK-023 门禁（2026-11-13）：与 TASK-024 同轮八步全绿，合计 3138 断言；`validate_task.py` VALID；`check_task_scope.py check` 0 violation。与 TASK-022 的 1228 条 `ce_panding` 相比净增 59 条（TASK-023 38 + TASK-024 21）。F5 目检与红测待用户；**未 commit、未 push**。

TASK-022 产物：新增 `docs/特效需求清单_2026-11-12.md` 与 TASK-022 任务包；改动 `scripts/xiao_di_tu.gd`、`scripts/she_zhi.gd`、`scripts/main.gd`、`scripts/ji_qi_chuan.gd`、`scripts/yu.gd`、`scenes/Main.tscn`、`tests/ce_panding.gd`、33 个 `data/nengli/*.tres`、`docs/技能图标与特效需求_Gemini_2026-11-10.md`（v1.3）；新增 66 个图标 PNG（两套画风）+ 66 个 `.import`；实现报告 `docs/development_tasks/TASK-022_shi_jue_jing_tou_yu_tu_biao/IMPLEMENTATION_REPORT.md`。
TASK-022 门禁（2026-11-12）：完整八步全绿（232 / 25 / 1422 / 8 / 20 / 144 / 1228 passed，0 failed，无 ERROR，合计 3079 断言，脚本输出「全绿：可以交付」）；`validate_task.py` VALID；`check_task_scope.py check` 176 allowed / 7 unchanged pre-existing / 0 violation。视觉探针实测地图上/下/左/右/中可见矩形均在地图内，无灰区。**本轮未 commit、未 push**，F5 目检与红测待用户。

TASK-021 产物：新增 `scripts/xiao_di_tu.gd`；改动 `scenes/Main.tscn`、`scripts/main.gd`、`scripts/yu_npc.gd`、`scripts/ji_qi_chuan.gd`、`scripts/yu_qun.gd`、`tests/ce_panding.gd`；实现报告 `docs/development_tasks/TASK-021_shang_di_shi_jiao/IMPLEMENTATION_REPORT.md`。
TASK-021 门禁：2026-11-12 首领房修复后完整八步门禁全绿（232 / 25 / 1422 / 8 / 20 / 144 / 1101 passed，0 failed，无 ERROR，单轮合计 2952 断言，脚本输出「全绿：可以交付」）；`validate_task.py` VALID；实现完成时 `check_task_scope.py` 10 allowed / 278 unchanged pre-existing / 0 violation。文档收尾后复跑为 14 allowed / 275 unchanged / 1 violation（`project.godot` 外部工作区改动，非本任务产生，详见实现报告第三节）。
TASK-021 浏览器实测（2026-11-12）：Chrome/Playwright 1280×720、本地 `http://127.0.0.1:8765` 新包通过主菜单→选角→局内、小地图四色与换房同步、换房黑场淡入、音频输出；控制台仅 Godot UID 回退 WARNING，无 `pageerror`；白闪逐帧截图未单独捕获。已发布 commit `42df5f1` 并 push `main`；Pages workflow `43160662448` success，线上空缓存复测通过（加载 28.15s→主菜单、33.80s→局内、换房 diff 44.91）。
