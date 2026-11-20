# TASK-026 验证报告

- 任务：生态精简、毒鱼耐受、咬伤经验、NPC 鱼王成长与雷达红点对账
- 验证日期：2026-11-15
- 环境：Godot 4.7.2 headless，`python -I -X utf8` 调用工作流脚本
- 结论：自动化门禁全绿，机器人探针两次连续胜利；F5 手感项待用户目检

## 一、八步门禁

命令：

```bash
cd /d/新游戏001
MSYS_NO_PATHCONV=1 cmd.exe /c "tests\pao_pi.bat"
```

| 步骤 | 脚本 / 内容 | 断言 |
|---|---|---:|
| 1/8 | `--import` 资源导入 | 0 ERROR |
| 2/8 | `ce_zhang_ben` 账本纯逻辑 | 232 passed, 0 failed |
| 3/8 | `ce_bian_jie` 边界 | 25 passed, 0 failed |
| 4/8 | `ce_shu_ju` 资源数据校验 | 1422 passed, 0 failed |
| 5/8 | `ce_yao_gan` 摇杆纯逻辑 | 8 passed, 0 failed |
| 6/8 | `ce_zhan_dou` 咬击纯逻辑 | 20 passed, 0 failed |
| 7/8 | `ce_jie_suo` 局外解锁 | 144 passed, 0 failed |
| 8/8 | `ce_panding` 判定集成（场景模式） | 1313 passed, 0 failed |
| 合计 | 七份测试 | **3164 passed, 0 failed** |

脚本末尾输出「全绿：可以交付」。日志中唯一 WARNING 是 `ce_panding` 故意传入未知音效名 `mei_you_zhe_ge_yin` 验证容错，非产品错误。

与 TASK-025 合计 3087 相比净增 77 条：新增 0b2 鱼王记录/清雷达、6k2 毒抗、6k3 咬伤经验与减免、6zc 鱼王全链路用例；没有删除旧断言凑绿。

## 二、单文件与静态检查

| 检查 | 结果 |
|---|---|
| `tests/ce_panding.gd` 单独运行 | 1313 passed, 0 failed |
| `validate_task.py` | `VALID: TASK-026 v1 (plan_driven)` |
| headless `--import` | 无 ERROR |
| `check_task_scope.py check` | `SCOPE: 169 allowed, 13 unchanged pre-existing, 0 violation(s)` |

## 三、机器人自动通关探针（临时，已删除）

探针 `tests/_tmp_yu_wang_probe.gd/.tscn/.uid` 真实实例化 `Main.tscn`，3 倍速，只走公开接口：写摇杆方向、调 `shi_fang_zhu_dong`、调升级/进化弹窗按钮回调。不是改数值作弊，只作机器人上限参考。

两次连续复跑：

| 指标 | 第 1 次 | 第 2 次 | TASK-025 基线 |
|---|---:|---:|---:|
| 结果 | SHENG_LI | SHENG_LI | SHENG_LI |
| 局内时长 T | 532.0 s | 541.5 s | 576.9 s |
| 等级 | Lv.16 | Lv.16 | Lv.19 |
| 体型峰值 / 最低 | 25.5 / 2.0 | 25.5 / 2.0 | 30.0 / 1.9 |
| 累计掉体型 | 129.0 | 141.5 | 56.4 |
| 饥饿最低 | 94.6 | 87.7 | 96.1 |
| 主动释放 | 346 | 286 | 215 |
| 三选一 / 进化 | 15 / 1 | 15 / 1 | 18 / 1 |
| 换房次数 | 19 | 13 | 34 |
| 到过的房号串 | 341052 | 54210 | 476301582（九房全覆盖） |
| 船出现 | 487.3 s | 487.3 s | 517.4 s |
| 船 HP | 960 | 960 | 1140 |
| 船战时长 | 44.6 s | 54.2 s | 59.5 s |
| 鱼王数量（历史峰值） | 0 | 0 | 无此系统 |
| 鱼王败退次数 | 0 | 0 | 无此系统 |

结论：

- 两次均胜利且远低于 650 秒，满足包内“仍胜利、不超 650 秒”的验收口径，无需按回滚口径调鱼王阈值/上限/咬伤系数。
- 探针机器人是重建的等价“上限操作”机器人，不是 TASK-025 原脚本，绝对数值不与基线逐项等同；换房覆盖也少于旧探针。
- 两次都未遇到鱼王：普通鱼在 487 秒内没有攒到隐藏 10 级。规则与测试成立，但“鱼王出现频率”是内容节奏问题，需 F5 或另开调参任务判断。
- 探针退出会有 `resources still in use at exit` 清理提示，是强制 `quit()` 未完整拆场景所致；门禁无此提示。

## 四、范围检查说明

最终收尾复跑：`SCOPE: 169 allowed, 13 unchanged pre-existing, 0 violation(s)`，产品代码与测试均无越界。

并行执行初期曾记录 49 条 VIOLATION（48 new + 1 existing），全部是任务包元数据或外部工作区文件（`docs/development_tasks` 下四包文档、`addons/ai_rig_2d/`、`rigs/`、`project.godot`），当时尚未完成四包白名单互登。协调者为四个任务包补齐 allowed 列表（含四包目录、`tools/yinyue/`、`addons/ai_rig_2d/`、`rigs/`、`project.godot` 等目录级规则）后复跑，产品代码 0 越界、违规清零。这里如实记录处理过程，没有通过隐藏文件或改基线伪造 0 violation。

## 五、待用户 F5 / 手机目检

1. 连吃毒鱼 4 条：毒晕条递增是否符合 45/31.5/18/13.5；停吃 8 秒后每 2 秒退一层是否可见。
2. 鱼王：能否在常规局遇到 10 级鱼王；金点、不可吞、追击、残血败退掉 3 块大肉与 2 倍鱼种经验的手感。
3. 雷达：吃完鱼、鱼群停刷、机械船降临后是否还残留红点；换房回来点是否恢复。
4. 咬伤经验：咬大鱼升级速度是否比旧版明显加快；同目标贴脸 0.6 秒接触减免是否能感觉到。
5. 鱼池：中后期是否还能遇到 1 级小鱼，狮子鱼是否确实延后出现。

以上均为无头环境无法替代的观感项；本轮不伪造目检结果。

## 六、红点残留补丁复验（2026-11-15 用户反馈）

- 复现方式：临时探针真实实例化 `Main.tscn`，吃掉当前房 3 条鱼后逐房 dump 记录。修复前当前房记录数仍是 45，其中 3 条记录的 `node` 已成为“已释放对象”（`== null` 为真、`typeof(node)` 仍为 `TYPE_OBJECT`），雷达继续按最后位置画点。
- 修复后：吃 3 条 → 当前房记录 45 → 42，`已释放残留=0`；停刷并吃光当前房 42 条 → 九房记录全部为 0，雷达截图只剩船/玩家金蓝点与植物绿点，无红点。
- 门禁复跑：`232 / 25 / 1422 / 8 / 20 / 144 / 1427 = 3278 passed, 0 failed`，脚本输出「全绿：可以交付」；`ce_panding` 单文件 1427 passed。
- `validate_task.py`：`VALID: TASK-026 v1 (plan_driven)`；`check_task_scope.py check`：`SCOPE: 169 allowed, 13 unchanged pre-existing, 0 violation(s)`。
- 临时探针 `tests/_tmp_hong_dian_probe*.gd/.tscn`、`tests/_tmp_freed_null.gd` 与调试截图目录均已删除。
