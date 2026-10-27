# TASK-011 验证报告（VERIFICATION_REPORT）

## 自动化验证

| 检查 | 结果 |
|---|---|
| 引擎版本 | 4.7.2.stable.official.ed1daf0bf（`D:\001\Godot_v4.7.2-stable_win64.exe`） |
| headless --import（每步） | 退出码 0，输出筛查零命中 |
| 账本纯逻辑 ce_zhang_ben | `Results: 9 passed, 0 failed`，退出码 0 |
| 边界 ce_bian_jie | `Results: 11 passed, 0 failed`，退出码 0 |
| 数据校验 ce_shu_ju | `Results: 27 passed, 0 failed`，退出码 0，双红测命中 |
| 摇杆纯逻辑 ce_yao_gan（新） | `Results: 8 passed, 0 failed`，退出码 0 |
| 判定集成 ce_panding（场景模式） | `Results: 13 passed, 0 failed`，退出码 0 |
| `pao_pi.bat` 全绿路径 | 六步依序 + 「全绿：可以交付」+ 退出码 0 |
| 主场景无头运行 | 180 帧，无 error / not found |
| `check_task_scope.py check` | 18 allowed，0 violation |
| `validate_task.py` | VALID（实现完成后、回填 `last_verified_commit` 前） |

断言总数：**68**（9 + 11 + 27 + 8 + 13），0 失败。

## 红绿过程（三次红，全部由门禁抓住）

| # | 现场 | 输出 | 根因 | 修复 |
|---|---|---|---|---|
| 1 | step-02 伤区门槛 | `FAIL: 同体型落在中间带：不掉血（期望 2，实际 1）` | 条件写成「对方 ×1.1 > 我」，同体型 `1.1 > 1.0` 恒真 | 改为「对方 ≥ 我 ×1.1」 |
| 2 | ce_yao_gan 多点触控 | `FAIL: 别的手指松开不应打断摇杆（期望 1，实际 0）` | 测试按下点距中心 240px，超过按下判定范围 192px，事件被拒 | 按下点改到 140px |
| 3 | ce_panding 死亡用例 | `Results: 13 passed, 0 failed` **但** `ERROR: Parameter "data.tree" is null` + `SCRIPT ERROR` | 死亡触发切场景，测试节点被摘出树后 `get_tree()` 为 null，`quit()` 失败 | `_ready` 开头先抓住 `SceneTree` 引用，收卷用 `shu.quit()` |

第 3 次是活教材：**Results 全 passed、退出码也可能为 0，但输出里有 ERROR——门禁的第二只眼（ERROR 筛查）抓住了它**。只看断言计数会误判为全绿。

## 学生手动验证（2026-10-27）

| # | 项目 | 学生结果 |
|---|---|---|
| 1 | F5 摇杆拖动转向、松手减速 | ✅「行」 |
| 2 | 撞 2.0 倍大鱼：体型 1.00 → 0.85，数字与鱼同步缩小 | ✅ |
| 3 | 连续撞到 0.5 以下切结算页 | ✅ |
| 4 | 血条彻底消失 | ✅ |
| 5 | `Main.tscn` 场景树：`UI/YaoGan`、`TiXingUI/TiXingLabel` 存在，`XueLiangTiao` 消失 | ✅「对」 |
| 6 | `Yu` 检查器：`zhuanxiang_ji_su = 4`、`jia_su_du = 900` | ✅ 数值正确 |
| 7 | WASD 调试输入（仅 debug） | ✅「行」 |
| 8 | 学习复述 A：大鱼转向慢 = 转向速率 ÷ 体型 | ✅ |
| 9 | 学习复述 B：体型变化玩家能直观看见 | ✅（补讲了吞噬资格与生命值两重身份） |
| 10 | 整体手感 | 「体验完了，还好」——零期基线可接受 |

学生提问：「NPC 没有身体区，撞身体也受伤？」——已解释为 TASK-011 的临时碰撞替身；TASK-012 会给 NPC 拆出嘴/身部位，把伤害改为「被咬中」而非「碰到」。已记入学习记录与交接。

## 未覆盖边界（移交后续）

| 项 | 说明 |
|---|---|
| 真机触控 | 本轮只验证桌面鼠标模拟触摸；Android 真机多点触控待 TASK-010 |
| 死亡结算实际加载 | 测试只断言「跌破 0.5」，场景切换由 F5 人工确认 |
| Tween 视觉时序 | 受伤缩小 / 升级长大 / 吞吃脉冲三者叠加时的视觉冲突无自动断言（见 CODE_REVIEW P3-1） |
| 窗口尺寸变化 | 摇杆中心只在 `_ready` 计算，旋转/分屏不重算（P3-3） |
| 大体型出屏 | 屏幕边距固定 30px，未按体型换算（P3-5） |

## 结论

代码实现、自动化门禁、学生手动验证、范围检查全部通过；三份报告与交接材料完成后即可提交。
