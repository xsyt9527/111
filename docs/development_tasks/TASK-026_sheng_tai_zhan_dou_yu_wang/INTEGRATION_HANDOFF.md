# INTEGRATION_HANDOFF · TASK-026

> 状态：`handoff_status = ready`。代码、测试与文档已完成；工程可交付用户审查，学习检查点尚未发生。
> 本轮未 commit、未 push。

## 1. 功能目的与归属

- 目的：收敛野外鱼池、低等级全期可刷、狮子鱼延后；连吃毒鱼递减耐受；咬大鱼按实际掉肉给经验并给同目标接触减免；NPC 隐藏等级达到 10 晋升鱼王，每房最多 2 只、不可整吞、不逃跑、雷达金点、败退给大肉与经验且不触发鲸鲨信号。
- 归属：`student-01`；owned scripts 为 `yu_qun.gd`、`yu_npc.gd`、`zhang_ben.gd`、`yu.gd`、`xiao_di_tu.gd`、`fen_yu.gd`。

## 2. 运行入口

- 主场景 `res://scenes/Main.tscn`；`YuQun` 负责野外抽鱼与九房记录；`YuNpc` 负责 NPC 成长与鱼王身份；`ZhangBen` 负责玩家毒晕；`Yu` 负责咬击与接触伤害；`XiaoDiTu` 负责雷达。

## 3. 输入与消费接口

- `YuQun._dang`、`shua_xin_shang_xian()`、`deng_ji_gai_lv()`、九房记录字段。
- `YuNpc.tixing`、`deng_ji_nei`、`jing_yan_nei`、`shi_boss`、`si_le`、`yu_zhong`、`_sheng_ji_yu_zhi_nei()`。
- `ZhangBen.du_yun`、`jia_du_yun()`、`KONG_ZHI_SHANG_XIAN`、`chong_zhi()`。
- `Yu._chang_shi_yao_ji()`、`_yao_ji_lian_dong()`、`_on_shang_qu_entered()`、`shou_dao_yao_ji()`。
- `ZhanDou.yao_ji_shang_hai()`、`zhi_ming_ke_sha()`。

## 4. 输出与提供接口

- `YuQun.TUI_CHU_PAI_CHI`：退池鱼种 `hong_yu`、`an_ying_jian_yu`。
- `YuQun.DU_YU_ZUI_DI_DANG = 2`：狮子鱼最低档位。
- `YuQun.shua_xin_zui_di(dang)`：恒返回 1。
- `YuQun.yu_wang_shu(pian)`：九房记录权威统计 `nei_deng>=10` 且未死亡的数量；裸夹具退回 `yu_wang` 组。
- `YuQun.hui_xie_ji_lu(yu)`：晋升同帧回写记录。
- `YuQun.qing_chu_qi_ta_fang_ji_lu()`：停刷时清非当前房记录。
- `YuNpc.yu_wang`：鱼王身份；组名 `yu_wang`。
- `YuNpc._yu_wang_bai_tui(lai_yuan)`：残血败退，掉 3 块大肉、给 2 倍鱼种经验、不 emit `bei_ji_bai`。
- `ZhangBen.jia_du_yun_chi_du_yu(liang)`：只对吃毒鱼生效的递减入口；`Yu.chi_du_yu(liang)` 委托它。
- `XiaoDiTu.ji_lu_ke_hua(rec)`：雷达记录可画纯函数（死鱼/无效节点过滤）。
- 无新增全局信号；`bei_ji_bai` 仍只属于鲸鲨。

## 5. 状态归属与持久化

- 九房记录是鱼王名额唯一权威；不新增 `wang` 键，身份由 `nei_deng>=10` 推导。
- 毒抗字段只存在 `ZhangBen` 单局内，`chong_zhi()` 清零，不写存档。
- 咬伤经验小数池只属于玩家 `Yu` 单局内，不写存档。
- `yu_wang` 组由晋升加入、节点销毁时自动移除。

## 6. 关键场景、脚本、配置与测试

- `scripts/yu_qun.gd`：池过滤、档位门、低等级全期刷、`yu_wang_shu()`、`hui_xie_ji_lu()`、停刷清房。
- `scripts/yu_npc.gd`：鱼王字段/晋升/恢复/规则/败退、名额权威、`_tun_diao` 守卫。
- `scripts/zhang_ben.gd`：毒抗字段、递减入口、窗口与退层、`chong_zhi` 清零。
- `scripts/yu.gd`：`chi_du_yu()`、咬伤经验小数池、0.6 秒接触减免、鱼王吞噬守卫。
- `scripts/xiao_di_tu.gd`：鱼王记录/实体金点、`ji_lu_ke_hua()` 死记录过滤。
- `scripts/zhuan_shu_ku/fen_yu.gd`：`_ke_chi()` 排除鱼王。
- `tests/ce_panding.gd`：0b2、6k2、6k3、6zc 等用例。
- 配置：无新增；`project.godot`、`scenes/Main.tscn` 不改。

## 7. 集成流程

1. `validate_task.py` 与 `check_task_scope.py check`；产品代码零越界。工具会把本包未跟踪的包内文档、后续任务包元数据以及外部新增的 `addons/ai_rig_2d`、`rigs/` 判为 VIOLATION，属工作流限制，详见 VERIFICATION_REPORT 第四节。
2. 合入 `scripts/` 六个文件与 `tests/ce_panding.gd`，同一提交保持接口一致。
3. 运行 `MSYS_NO_PATHCONV=1 cmd.exe /c "tests\\pao_pi.bat"`，八步全绿。
4. F5 检查：40 秒内无狮子鱼、后期 1 级鱼、毒抗递减、咬伤经验、雷达金点、鱼王败退、机械船不提前。
5. 更新 `TASK_STATE.json` 的 `last_verified_commit` 与 `handoff_status`。

## 8. 禁止直接访问与冲突热点

- 禁止按 `yu_npc` 组全表清理或统计鱼王；只能读 `YuQun` 记录与 `yu_wang` 组。
- 禁止绕过 `YuQun` 记录直接改写鱼王名额。
- 禁止让鱼王 emit `bei_ji_bai` 或复用 `shi_boss`。
- 禁止在 `jia_du_yun()` 内打折；必须走 `jia_du_yun_chi_du_yu()`。
- 冲突热点：`yu_qun.gd` 与 TASK-025 九房初始化/虚拟互吃；`yu_npc.gd` 与 TASK-019/024；`zhang_ben.gd` 毒晕断言；`yu.gd` 统一结算；`xiao_di_tu.gd` 雷达图例。

## 9. 必需集成检查与最新验证基线

- 生成时基线：`f27ae56893aed50db99ca6572659966bbca09b27`；工作区有未提交的 TASK-022~025 收尾产物与任务包文档。
- 完工后：`validate_task.py` VALID；headless `--import` 0 ERROR；`tests/pao_pi.bat` 八步全绿，232 / 25 / 1422 / 8 / 20 / 144 / 1313 passed，合计 **3164 断言**。
- 单文件 `ce_panding`：1313 passed, 0 failed。
- 机器人探针（临时，已删除）两次连续胜利：
  - 532.0 秒，Lv.16，体型峰值 25.5 / 最低 2.0，掉体型 129.0，饥饿最低 94.6，主动 346 次，三选一 15 张、进化 1 次；换房 19 次；船 487.3 秒出现（960 HP），44.6 秒击沉；鱼王峰值 0、败退 0。
  - 541.5 秒，Lv.16，体型峰值 25.5 / 最低 2.0，掉体型 141.5，饥饿最低 87.7，主动 286 次，三选一 15 张、进化 1 次；换房 13 次；船 487.3 秒出现（960 HP），54.2 秒击沉；鱼王峰值 0、败退 0。
- 与 TASK-025 基线（576.9 秒、Lv.19、峰值 30.0、换房 34 次、船 517.4 秒 1140 HP）相比，两次均低于 650 秒稳定胜利，未触发回滚口径。探针为重建的等价上限操作机器人，绝对数值不与旧脚本逐项等同。
- 本轮未 commit、未 push。

## 10. 已知限制与待参与事项

- 探针 487 秒内鱼王出现 0 次：规则成立但常规局频率偏低，需 F5 或另开节奏调参任务。
- 9 级普通鱼空档会让玩家 Lv7+ 的 A11 大鱼抽样可能返回 null。
- 前 40 秒 2 级档被狮子鱼过滤后只剩 1 级鱼，前期可能偏单调。
- 咬伤经验系数 5、鱼王阈值 10/上限 2 均需 F5 评估。
- 学生参与检查点尚未发生；`learning_status = not_started`。
- F5 人工验收由用户执行。
