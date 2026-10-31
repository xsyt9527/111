# TASK-018 验证报告（VERIFICATION_REPORT）

> 状态：自动化验证完成；F5 手测与学习验收待用户执行。**未 commit / 未 push**，`last_verified_commit = null`。

## 自动化验证

| 检查 | 结果 |
|---|---|
| 引擎版本 | Godot 4.7.2.stable.official.ed1daf0bf |
| headless `--import` | 退出码 0，输出 0 个 `ERROR`（仅 Android build-tools 目录警告） |
| 账本纯逻辑 `ce_zhang_ben` | **131 passed, 0 failed**（基线 102） |
| 边界 `ce_bian_jie` | **24 passed, 0 failed**（基线 21） |
| 数据校验 `ce_shu_ju` | **83 passed, 0 failed**（基线 47） |
| 摇杆 `ce_yao_gan` | **8 passed, 0 failed**（未受影响） |
| 咬击 `ce_zhan_dou` | **11 passed, 0 failed**（未受影响） |
| 局外解锁 `ce_jie_suo`（新） | **58 passed, 0 failed** |
| 判定集成 `ce_panding`（场景模式） | **225 passed, 0 failed**（基线 193） |
| **合计** | **540 断言全绿** |
| `pao_pi.bat` 八步全绿 | 是；每步有 `Results:`，输出无 `ERROR` |
| Main 900 帧冒烟 | 退出码 0，0 个 `ERROR` |
| 选择页 120 帧冒烟 | 退出码 0，0 个 `ERROR` |
| 结算页 60 帧冒烟 | 退出码 0，0 个 `ERROR` |
| `validate_task.py` | **VALID: TASK-018 v1 (plan_driven)** |
| `check_task_scope.py check` | **SCOPE: 40 allowed, 196 unchanged pre-existing, 0 violation(s)**，退出码 0 |
| `Godot引擎词总表.docx` 重生成 | 已生成，170 章节 / 144 表格 |

门禁实际输出：

```text
=== [1/8] 导入 --import ===
=== [2/8] 账本纯逻辑 ce_zhang_ben ===
Results: 131 passed, 0 failed
=== [3/8] 边界 ce_bian_jie ===
Results: 24 passed, 0 failed
=== [4/8] 数据校验 ce_shu_ju ===
Results: 83 passed, 0 failed
=== [5/8] 摇杆纯逻辑 ce_yao_gan ===
Results: 8 passed, 0 failed
=== [6/8] 咬击纯逻辑 ce_zhan_dou ===
Results: 11 passed, 0 failed
=== [7/8] 局外解锁 ce_jie_suo ===
Results: 58 passed, 0 failed
=== [8/8] 判定集成 ce_panding（场景模式）===
Results: 225 passed, 0 failed
========== 全绿：可以交付 =========
```

## 红绿过程

1. **形态负速度红测**：临时把 `data/xingtai/dian_yao.tres` 的 `yi_dong_su_du` 从 `260.0` 改为负数，`ce_shu_ju` 输出 `Results: 81 passed, 2 failed`、退出码 1；恢复为 `260.0` 后复跑 `Results: 83 passed, 0 failed`。夹具和代码内红测均能命中校验器。
2. **坏存档回退**：`ce_jie_suo` 覆盖坏 JSON、非 Dictionary、版本不符、负胜场、浮点胜场、字符串胜场、未知形态、未解锁形态、非字符串当前形态；全部回退默认，且不改写原文件。
3. **失败/死亡不显示解锁**：`ce_panding` 在死亡页手动塞入一条瞬时提示，`JieSuan` 必须隐藏并消费；胜利页显示「解锁新形态：电鳐」并消费。
4. **旧场景残留（已修复）**：`scenes/QiangHuaDanChuang.tscn` 仍引用 TASK-014 已退役脚本/资源，首次 `pao_pi.bat` 第 1 步报 12 条 `ERROR`。删除该旧场景并清理 `.godot/editor` 后重新 `--import`，0 个 `ERROR`，八步门禁复跑 540 断言全绿，Main / 选择页冒烟 0 个 `ERROR`。
5. **`--script` 不加载 Autoload**：`cun_dang.gd` 早期直接引用 `ZhangBen` 导致编译错误；改为动态取节点 + 本地常量后，`ce_jie_suo` 裸实例模式通过。
6. **碰 Boss 死亡报错（已修复）**：玩家被 Boss 击杀切 `JieSuan` 时，旧场景 `YuNpc` 已离树仍被 `_process` 一帧，报 `get_viewport_rect` / `get_camera_2d`。加 `is_inside_tree()` 守卫后，`ce_panding` 新增 2 条离树回归断言，复跑 `Results: 225 passed, 0 failed` 且无 `ERROR`。

## 学生手动验证

（待用户执行 F5；`LEARNING_STATE.json` 保持 `not_started`）

建议按下列顺序验收：

1. 启动进入形态选择页；0 胜时只有灯笼鱼可点，电鳐/旗鱼显示锁定与所需胜场。
2. 选灯笼鱼出发；结算「再来一次」仍是灯笼鱼，「换形态」回到选择页。
3. 调试解锁全部后三张卡全开；分别选电鳐/旗鱼，确认：
   - 电鳐开局 Lv.1、体型更大、速度更慢、自带放电按钮；
   - 旗鱼速度更快、嘴巴更小、自带极速突进。
4. 打赢机器船：结算显示「解锁新形态：电鳐」；重启游戏后进度仍在。
5. 把 `user://shenhaishiji_jin_du.json` 改成坏 JSON 后启动：回到默认且 Output 无 `ERROR`。
6. 「调试：清空进度」回到 0 胜、只有灯笼鱼可选。
7. 主动撞 Boss 被击杀：切结算页时 Output 不得出现 `get_viewport_rect` / `get_camera_2d` 报错。

## 未覆盖边界（移交后续）

- 导出 PCK 后的 `preload` 注册表与 `user://` 存档路径未在真机/导出包验证（TASK-010）。
- 第 4 个形态、形态升级/皮肤、局外货币均不在本任务范围。
- TASK-014 遗留的 `scenes/QiangHuaDanChuang.tscn` 已删除；`--import` 与 Main / 选择页冒烟均 0 `ERROR`。
- 形态数值平衡（电鳐 Lv.1 是否过强、旗鱼 0.85 嘴巴是否过弱）需 F5 手感确认。

## 结论

- 自动化门禁：**通过**（八步 540 断言，无 `ERROR`，三场景冒烟通过）。
- 交付状态：`review`；交接状态：`pending`；学习状态：`not_started`。
- 不 commit / 不 push，`last_verified_commit` 保持 `null`。
