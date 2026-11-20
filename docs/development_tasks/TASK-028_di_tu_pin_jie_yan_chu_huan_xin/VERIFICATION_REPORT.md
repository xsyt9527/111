# TASK-028 验证报告

- 任务：九图拼合结尾演出重做：慢推镜、左上角起逐张拼合、打字机与冷蓝船影
- 验证日期：2026-11-15
- 环境：Godot 4.7.2 headless（`D:\001\Godot_v4.7.2-stable_win64.exe`）
- 结论：源码视觉与测试断言完成；八步门禁 3273 断言全绿、scope 0 violation、验证器 VALID；F5 目检待用户确认

## 一、编译自测（本子任务已完成）

方法：临时 `extends SceneTree` 脚本，在 autoload 注册后加载并实例化演出脚本；临时文件跑完即删。

```text
LOAD_YANCHU=true CAN_INSTANTIATE=true NEW_NODE=true
```

- `--check-only --script` 单脚本模式不注册 Autoload：`main.gd` 在第一个 `ZhangBen` 标识符处停止，属工具限制；`di_tu_pin_jie_yan_chu.gd` 的 Autoload 仅 `YinXiang`，已在项目上下文中编译通过。
- 自测期间 027 音频处于旧 wav 已删、新 wav 未生成的中间态，`yin_xiang.gd` 的 7 个 `preload` 报 "no resource loaders"，`zhang_ben.gd` / `main.gd` 整链不可编译。主会话已确认 027 音频生成完成且 `--import` 0 ERROR；`main.gd` 的运行时编译由统一门禁覆盖。
- 本子任务自测阶段未跑上述四项；最终由主会话在工作区收尾后统一运行，结果见第二节。

## 二、八步门禁与范围检查

主会话在最终工作区执行 `tests/pao_pi.bat`，退出码 0，输出「全绿：可以交付」：

| 步骤 | 脚本 / 内容 | 断言 |
|---|---|---:|
| 1/8 | `--import` 资源导入 | 0 ERROR |
| 2/8 | `ce_zhang_ben` 账本纯逻辑 | 232 passed, 0 failed |
| 3/8 | `ce_bian_jie` 边界 | 25 passed, 0 failed |
| 4/8 | `ce_shu_ju` 资源数据校验 | 1422 passed, 0 failed |
| 5/8 | `ce_yao_gan` 摇杆纯逻辑 | 8 passed, 0 failed |
| 6/8 | `ce_zhan_dou` 咬击纯逻辑 | 20 passed, 0 failed |
| 7/8 | `ce_jie_suo` 局外解锁 | 144 passed, 0 failed |
| 8/8 | `ce_panding` 判定集成（场景模式） | 1422 passed, 0 failed |
| 合计 | 七份测试 | **3273** 断言，0 failed |

- `validate_task.py`：`VALID: TASK-028 v1 (plan_driven)`。
- `check_task_scope.py check`：`SCOPE: 23 allowed, 159 unchanged pre-existing, 0 violation(s)`（文档收尾后最终复跑）。
- 产品代码改动范围仅 `scripts/di_tu_pin_jie_yan_chu.gd`、`scripts/main.gd`、`tests/ce_panding.gd` 与文档；未改 `Main.tscn` / `project.godot` / 027 音频。

## 三、`tests/ce_panding.gd` 已落地断言（用例 6zf）

主会话已把原清单中的 A~H 组落到 `tests/ce_panding.gd` 用例 6zf，单文件 `ce_panding` 由 1313 增至 1422。实际覆盖：

- **源码静态契约**：`fei_ru_qi_dian(` 只剩定义；无 `_process`、`_zhen_dong`、`_tie_fei_xing`；含 `_ding_shi(7.3, _jie_shu_yan_chu)`。
- **顺序与常量**：`pin_jie_shun_xu(4)` 逐项等于 `[0..8]`；任意玩家格顺序相同；`HEI_BIAN_GAO=92.0`、`XIAN_YING_JIAN_GE=0.15`、`LUO_XIA_JU_LI∈[18,24]`、`JIN_XIAN_ALPHA=0.55`、`LENG_GUANG_ZUI_DA=0.12`、`YA_AN_ZUI_DA=0.12`、`BIAO_TI_ZI_SHI_JIAN=0.05`、`BO_WEN_ZUI_DA_BAN_JING=220.0`。
- **运行时显影**：`_jian_di_tu()` 后 9 块 `Sprite2D` 的 `region_rect` 逐块匹配、初始 `position` 在最终中心、`scale=1`、`alpha=0`；9 圈波纹、4 条接缝金线、金框初始 alpha 0；不存在 `_zhen_jing` / `_hong_guang` / `ZhenJing`。
- **船体与 UI**：`_jian_ren_lei()` 建 1 个 `AnimatedSprite2D`（`dong`、4×）与 2 枚舱灯；`_jian_ui()` 后标题/跳过按钮/冷蓝/压暗均按设计初始态。
- **跳过与单次收尾**：连接 `jie_shu` 后连续 ESC、`_tiao_guo()`、`_jie_shu_yan_chu()`，计数恒 1，节点自毁；`main.gd` 含 `_yan_chu_qian_qi_pao_ke_jian` / `_yan_chu_qian_she_zhi_ke_jian` 记录字段。
- 上述断言真实通过（`Results: 1422 passed, 0 failed`），不是纸面清单。

## 四、F5 目检清单（待用户确认，不伪造结果）

1. 九格是否从左上角开始按行优先逐张拼下，玩家格不再固定最后。
2. 每块是否有波纹与轻微落下，无飞入、无回弹、无重叠。
3. 接缝金线是否随拼合分段亮起，最终约 0.55。
4. 2.5 秒玩家格金框、镜头轻推与区域名/水位小字打字机是否成立。
5. 3.6 秒回全图留白是否自然。
6. 4.5 秒 4 帧船体是否从画面上缘压入，冷蓝背光与全图压暗是否克制（约 0.12）。
7. 标题打字机是否逐字出现。
8. 5.9 秒舱灯是否闪 2 次，落点是否只有一次气泡。
9. 全场无红闪、无震屏、无震惊气泡、玩家无翘头/上浮。
10. 跳过按钮 0.6 秒出现；按钮与 ESC 均能跳过，且结束后只生成一条机器船。
11. 演出期间装饰气泡层与设置按钮隐藏，结束后恢复。
12. 演出结束后画面回到玩家体型对应镜头，无灰区。

## 五、范围与未做声明

- `tests/ce_panding.gd` 已由主会话补齐 6zf 断言并真实运行；本子任务自身未改 tests。
- 已运行 `--import`、`tests/pao_pi.bat`、`check_task_scope.py`、`validate_task.py`，数字见第二、三节。
- 未改动 027 音频与 026/029 任务包产品代码。
- F5 目检结果未伪造；本报告只记录自动化可验证部分。
- 本轮未 commit、未 push。
