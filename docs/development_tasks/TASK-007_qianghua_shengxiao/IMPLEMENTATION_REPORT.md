# TASK-007 实现报告（IMPLEMENTATION_REPORT）

## 交付概览

四步全部按规格实现：buff 生效系统（match 六卡）→ 磁吸双 Area2D → Tween 平滑长大 + 吞吃脉冲 → sin 摆尾。预埋信号 ka_yi_xuan 的第一个消费者上线，六张强化卡从"只入账"变为"可感知生效"；第 3 课学生提案"分行为须分 Area2D"正式落地。

## 分步明细

### step-01 buff 生效系统

| 文件 | 改动 |
|---|---|
| `zhang_ben.gd` | +`jing_yan_jia_cheng := 1.0` + `she_jing_yan_jia_cheng()`（倍率唯一所有者=账本） |
| `yu.gd` | +`mei_ji_fu_dian`；`_ready` 连 `ka_yi_xuan`；`_on_ka_yi_xuan` match 六分支 + 未知键 push_warning 兜底（TASK-006 P3 兑现）；`_on_sheng_ji` 叠加催肥增幅 |
| `yu_npc.gd` | `bei_chi` 记账乘账本倍率 `int(fenzhi * jing_yan_jia_cheng)` |

六卡效果全部读 `ka.shu_zhi`——改卡数值零代码。磁吸分支 step-01 为 push_warning 占位。

### step-02 磁吸双 Area2D

| 文件 | 改动 |
|---|---|
| `Yu.tscn` | PandingQu 改名 ShangQu（r=22，判定职责不变）+ 新增 ChiQu（r=90，layer 默认 1 / mask=2）各带独立 CollisionShape2D |
| `yu.gd` | 引用同步改名；+`_on_chi_qu_entered`（打得过才打标记 `bei_xi = self`）/ `_on_chi_qu_exited`（出圈清标记）；磁吸分支换真货（只放大 ChiQu 形状，判定圈不动） |
| `yu_npc.gd` | +`bei_xi: Yu`；`_process` 被吸分支（朝 `bei_xi.global_position` 游，×1.2 速，按方向翻转） |

设计决策 1A（NPC 自决）：玩家只打标记，路小鱼自己走。

### step-03 Tween 动画一

- `_on_sheng_ji`：瞬间 `scale =` 跳变 → `create_tween().tween_property(..., 0.3).set_ease(Tween.EASE_OUT)`；**tixing 数值仍即时到位**（判定不等动画——显示与状态分离）
- +`_tun_chi_maichong()`：链式两段（0.08s 弹大 8% → 0.12s 回弹），每段以 tixing 收尾不漂移；`_on_shang_qu_entered` 吃鱼分支调用

### step-04 摆尾

- +`bai_shi_jian` 相位时钟；`_process` 游动时 `rotation = sin(bai_shi_jian * 10.0) * 0.12 / tixing`（摆幅与体型反比），静止回正 0
- 程序化动画：零关键帧、零新资源

## 自动化检查（每步全跑）

- `--headless --import` 退出码 0 + 输出筛查（error/not found）零命中 ×4 步
- `--headless --fixed-fps 60 --quit-after 360` 退出码 0 + 输出筛查零命中 ×4 步
- `check_task_scope.py check`：7 allowed, 0 violation

## 范围遵守

- 修改恰为白名单 4 文件（yu.gd / yu_npc.gd / zhang_ben.gd / Yu.tscn）+ 任务包文件
- zhang_ben.gd 只加了倍率一处；yu_qun.gd / yu_zhong.gd / main.gd / 弹窗 / data/ 零触碰
- 零新增资源文件、零场景 uid 杜撰（Yu.tscn 改动仅节点改名 + 新增节点，沿用既有 sub_resource 模式）
