# 验证报告 — TASK-025 房间预置鱼群

验证日期：2026-11-14
基线提交：`bcc1f3dfe25267e4c4017946ee076bc7c5640899`
任务包：`docs/development_tasks/TASK-025_fang_jian_yu_qun_yu_zhi/`

## 一、结论

| 检查 | 结果 |
|---|---|
| `validate_task.py` | `VALID: TASK-025 v1 (plan_driven)` |
| `headless --import` | pass，0 ERROR |
| `tests/pao_pi.bat` 八步门禁 | 全绿，合计 3087 断言，0 failed |
| `check_task_scope.py check` | 0 violation（8 allowed / 214 unchanged pre-existing） |
| 机器人自动通关探针 | 胜利，576.9 秒，九房全部访问，34 次换房 |
| F5 人工目检 | **待用户执行**（无头环境无法拍板手感与雷达可读性） |

## 二、八步门禁明细

执行：`MSYS_NO_PATHCONV=1 cmd.exe /c "tests\\pao_pi.bat"`（2026-11-14）

```text
[1/8] headless --import                pass，0 ERROR
[2/8] ce_zhang_ben                     232 passed, 0 failed
[3/8] ce_bian_jie                      25 passed, 0 failed
[4/8] ce_shu_ju                        1422 passed, 0 failed
[5/8] ce_yao_gan                       8 passed, 0 failed
[6/8] ce_zhan_dou                      20 passed, 0 failed
[7/8] ce_jie_suo                       144 passed, 0 failed
[8/8] ce_panding（场景模式）           1236 passed, 0 failed
========== 全绿：可以交付 ==========
```

- 合计：232 + 25 + 1422 + 8 + 20 + 144 + 1236 = **3087**。
- 与 TASK-024 的 3138 相比净减 51 条：删除了换房欢迎鱼/安全入口/选种/补屏旧断言，新增 TASK-025 九房用例；不是测试减少而假绿。
- 唯一 WARNING 为测试主动触发的 `YinXiang: 未知音效名 mei_you_zhe_ge_yin`（既有负路径断言），不是 ERROR。
- `ce_panding` 单独复跑同为 `1236 passed, 0 failed`；历史上出现过一次「气泡吸引半径」补间一帧漂移偶发，复跑归零，与本任务改动无关。

## 三、任务包与范围

```text
validate_task.py   → VALID: TASK-025 v1 (plan_driven)
check_task_scope.py check
  → SCOPE: 8 allowed, 214 unchanged pre-existing, 0 violation(s)
```

允许项：

- 既有文件：`scripts/yu_qun.gd`、`scripts/yu_npc.gd`、`scripts/xiao_di_tu.gd`、`scripts/main.gd`、`tests/ce_panding.gd`
- 新增文件：`docs/development_tasks/TASK-025_fang_jian_yu_qun_yu_zhi/**`（任务包与三份报告）

未触碰 `project.godot`、`scenes/Main.tscn`、存档 schema、Autoload；`build/**`、`.godot/**`、图片与美术资源未 `git add`。

## 四、机器人自动通关探针（临时，已删除）

探针真实实例化 `Main.tscn`，3 倍速，只走公开接口。完整结果：

```text
TONG_GUAN|RESULT=SHENG_LI;T=576.9;Lv=19;BodyMax=30.0;BodyMin=1.9;
Damage=56.4;HungerMin=96.1;Skills=215;Cards=18;Evolutions=1;
Rooms=34;RoomSet=476301582;ShipSpawn=517.4;ShipHP=1140.0;
ShipSink=576.9;ShipLeft=0.0;ShipBattle=59.5
```

解读：

- `Rooms=34`：单局换房 34 次；`RoomSet=476301582` 覆盖房号 0~8 全部九格，真实场景中没有因九房记录加载/保存崩溃或卡死。
- `T=576.9` 胜利；`Lv=19`、体型峰值 30.0、最低 1.9；累计掉体型 56.4；饥饿最低 96.1；主动 215 次、三选一 18 张、进化 1 次。
- 机械船 517.4 秒出现（1140 HP），576.9 秒击沉，船战约 59.5 秒。
- 与 TASK-024 探针（557.1 秒、Lv.15、体型 24、掉体型 43.9、船战 65~70 秒）相比，本任务没有让难度失控；机器人仍能通关，且因为跨房吃植物更多，体型上限更高。
- 探针退出时 `9 ObjectDB instances leaked / 4 resources still in use at exit` 是强制退出的清理提示，不是游戏内 ERROR；门禁无此提示。

局限：

- 机器人是「上限操作 + 3 倍速 + 近似全图目标选择」，不能代表真人手感。
- 探针已删除，结果只保留在本报告与 `TASK_STATE.json` 的 `verification.probe` 字段。

## 五、覆盖矩阵

| 需求 | 自动化证据 | 人工证据 |
|---|---|---|
| 九房开局各预置固定数量记录 | `ce_panding` 九房记录数/40px 边距/无节点 | F5 雷达九格红点 |
| 换房不再整批刷新 | 旧房实体释放、记录保留、目标房按记录加载 | F5 来回换房位置延续 |
| 雷达显示其他房 NPC | `_hu_npc` 读 `fang_jian_ji_lu`；雷达既有断言未改 | F5 其他房红点移动/消失/变大 |
| 未加载房互吃 | 强制概率 1.0 下最小鱼优先被吃、吃方成长 | F5 红点消失/变大 |
| 档位淘汰/保底 | 淘汰最小 20%、补到 21、空房补保底 | F5 长时间观察 |
| 当前房补鱼节奏保留 | `Dingshi` 路径与记录登记断言 | F5 当前房仍陆续出新鱼 |
| 停刷期冻结与记录保留 | 虚拟游动/互吃/档位冻结、停刷换房记录不清空 | 决战期换房不刷鱼 |
| 成长恢复 | 载荷 3.0/2/7 在 `add_child` 后恢复 | 换房后大鱼仍大 |

## 六、残余风险与待确认

1. **手机雷达帧率**：0 压力时每帧约 315 个点，+2 压力时最多 405 个点（9×45）。桌面/无头无压力；真机若掉帧，可把 `XiaoDiTu._process` 改成 30Hz `queue_redraw`，本任务未改。
2. **未加载房减员速度**：20 秒 35% 概率互吃 + 每档淘汰 20%，保底 60%；实机观感需 F5 观察，必要时只调 `WEI_JIA_ZAI_BAO_DI_BI_LI` 或 `DANG_WEI_TAO_TAI_BI_LI`。
3. **贴脸保护边界**：玩家贴房角时，240px 推挤可能退到最远象限中心；测试已覆盖 ≥240px 且在房内 40px，但实机换房落点观感需 F5。
4. **停刷期换房不加载**：这是保留的旧行为；此时目标房记录 `node=null`，雷达仍画记录点。若用户希望决战期也有实体鱼，属于新范围，需另开任务。
5. **F5 人工检查**：雷达九格红点、其他房红点动态、换房延续、图例不变、补鱼节奏；本轮无头环境无法替代。

## 七、未授权动作

- **未 commit、未 push**；工作区改动保留给用户审阅。
- 未强制推送、未上传密钥/存档/无关文件、未关闭 TLS、未提取 token、未绕过凭据。
