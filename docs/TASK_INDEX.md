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

TASK-021 产物：新增 `scripts/xiao_di_tu.gd`；改动 `scenes/Main.tscn`、`scripts/main.gd`、`scripts/yu_npc.gd`、`scripts/ji_qi_chuan.gd`、`scripts/yu_qun.gd`、`tests/ce_panding.gd`；实现报告 `docs/development_tasks/TASK-021_shang_di_shi_jiao/IMPLEMENTATION_REPORT.md`。
TASK-021 门禁：2026-11-12 首领房修复后完整八步门禁全绿（232 / 25 / 1422 / 8 / 20 / 144 / 1101 passed，0 failed，无 ERROR，单轮合计 2952 断言，脚本输出「全绿：可以交付」）；`validate_task.py` VALID；实现完成时 `check_task_scope.py` 10 allowed / 278 unchanged pre-existing / 0 violation。文档收尾后复跑为 14 allowed / 275 unchanged / 1 violation（`project.godot` 外部工作区改动，非本任务产生，详见实现报告第三节）。
TASK-021 浏览器实测（2026-11-12）：Chrome/Playwright 1280×720、本地 `http://127.0.0.1:8765` 新包通过主菜单→选角→局内、小地图四色与换房同步、换房黑场淡入、音频输出；控制台仅 Godot UID 回退 WARNING，无 `pageerror`；白闪逐帧截图未单独捕获。未 commit/push，Pages 未部署、线上未复测。
