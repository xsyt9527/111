# TASK-018 实现报告（IMPLEMENTATION_REPORT）

> 状态：实现完成，交付状态 `review` / 交接 `pending` / 学习 `not_started`。本任务按工作区基线实现，**未 commit / 未 push**，因此不写 `complete`。

## 交付概览

| 指标 | 结果 |
|---|---|
| 门禁 | **八步全绿，540 断言**（131 / 24 / 83 / 8 / 11 / 58 / 225） |
| 主场景 / 选择页 / 结算页冒烟 | 均退出码 0，输出无 `ERROR`（Main 900 帧 / 选择页 120 帧 / 结算页 60 帧） |
| 产品文件 | 新增 9 个正式文件（脚本 3、场景 1、形态数据 3、单帧动画 2）+ 测试 2 个；修改 12 个既有文件 |
| 范围检查 | **通过**：`SCOPE: 40 allowed, 196 unchanged pre-existing, 0 violation(s)` |
| 学生 F5 | **待用户执行**，学习状态保持 `not_started` |

## 分步明细

### step-01 形态数据层

- 新增 `scripts/xing_tai.gd`：`XingTai extends Resource`，字段为 `bian_hao`、`ming_zi`、`miao_shu`、`dong_hua`、`kai_ju_deng_ji`、`yi_dong_su_du`、`zui_ba`、`zhuan_xiang_ji_su`、`kai_ju_neng_li`、`jie_suo_sheng_li_ci_shu`。
- 新增 `data/xingtai/deng_long_yu.tres`、`dian_yao.tres`、`qi_yu.tres`：
  - 灯笼鱼：阈值 0、Lv.0、速度 300、嘴巴 1.0、转向 7.0、无初始能力，复用四帧 `deng_long_yu_4zhen.tres`。
  - 电鳐：阈值 1、Lv.1、速度 260、嘴巴 1.0、转向 6.0、初始主动放电麻痹，单帧 `dian_yao_1zhen.tres`。
  - 旗鱼：阈值 2、Lv.0、速度 360、嘴巴 0.85、转向 7.5、初始主动极速突进，单帧 `qi_yu_1zhen.tres`。
- 新增 `data/donghua/dian_yao_1zhen.tres`、`qi_yu_1zhen.tres`：动画名统一 `&"you"`，单帧 speed 1.0。
- 新增 `tests/huai_xing_tai.tres` 负速度红测夹具；`tests/ce_shu_ju.gd` 增加形态池校验器、3 形态数值/阈值/初始能力映射、唯一 id、`"you"` 动画检查、坏形态红测 ×5，以及 `run/main_scene` 与 `autoload/CunDang` 断言。

### step-02 局外存档与解锁推导

- 新增 `scripts/cun_dang.gd`（Autoload `CunDang`）：
  - `XING_TAI_ZU` 显式 `preload` 三个形态，按阈值升序、同阈值按 id 排序。
  - `user://shenhaishiji_jin_du.json` schema v1：`{ban_ben, sheng_li_ci_shu, dang_qian_xing_tai}`。
  - 加载路径覆盖：文件不存在 / 无法打开 / JSON 非 Dictionary / 版本不符 / 胜场非数字或负数 / 当前形态非字符串、未知或未解锁；失败只回退默认，**不创建、不覆盖原文件**。
  - `ji_lu_sheng_li()` 胜场 +1，返回跨阈值新解锁形态，写入瞬时提示并立即保存；`qu_xin_jie_suo()` 返回副本并清空。
  - `_ready()` 动态取 `/root/ZhangBen` 并连接 `ju_jie_shu`；胜利瞬间落盘，死亡不走该信号。
- 新增 `tests/ce_jie_suo.gd`：58 断言，裸实例测试，全部使用 `user://ce_jie_suo_<pid>_<ticks>.json` 临时路径，结束删除。
- `tests/pao_pi.bat` 扩为八步，新增第 7 步 `ce_jie_suo`，原场景集成顺延第 8 步。

### step-03 账本与玩家形态接入

- `scripts/zhang_ben.gd`：新增 `dang_qian_xing_tai`、`xing_tai_yi_ying_yong`；新增 `kai_ju_xing_tai()`（直接设等级/体型/初始主动，不走 `jia_jing_yan`）与 `chong_zhi_bao_liu_xing_tai()`；`chong_zhi()` 末尾清形态字段并解除幂等锁，保持纯复位。
- `scripts/yu.gd`：新增 `ying_yong_xing_tai()`，在 `_ready()` 顶部、`scale = _ti_xing_vector()` 之前读取并应用形态；速度/嘴巴/转向做正数夹值，切换 `SpriteFrames` 后 `play("you")` 并清朝向。
- `scripts/main.gd`：`reset_smoothing()` 后补 `camera.zoom = Vector2.ONE / _shi_jiao_bei()`，避免电鳐 Lv.1 首帧镜头跳变。
- `tests/ce_zhang_ben.gd` 增至 131 断言；`tests/ce_bian_jie.gd` 增至 24 断言。

### step-04 选择页、结算页与入口

- 新增 `scenes/XingTaiXuanZe.tscn` + `scripts/xing_tai_xuan_ze.gd`：
  - 三张动态卡（`PanelContainer` + `StyleBoxFlat` + `VBoxContainer`），预览首帧、名称、说明、数值、状态与按钮。
  - 当前形态金色边框、已解锁青绿、锁定深灰且 `Button.disabled = true`；副标题「已胜利 N 次 · 解锁 X/3」。
  - 编辑器构建额外显示「调试：解锁全部形态」「调试：清空进度」。
  - 选卡成功：`CunDang.xuan_ze()` → `ZhangBen.chong_zhi()` → `ZhangBen.kai_ju_xing_tai()` → `change_scene_to_file(Main.tscn)`。
- `scenes/JieSuan.tscn` + `scripts/jie_suan.gd`：新增「换形态」按钮与「解锁新形态：XXX」提示；「再来一次」改调 `chong_zhi_bao_liu_xing_tai()`；`_xie_jie_suo()` 无条件消费瞬时提示，仅胜利显示。
- `project.godot`：`CunDang` 排在 `ZhangBen` 之后；`run/main_scene` 改为 `XingTaiXuanZe.tscn`。
- `tests/ce_panding.gd` 增至 225 断言：形态数值/单帧动画、第二个 `Yu` 的 `_ready` 自动应用、选择页 0 胜 2 锁与 2 胜 0 锁、胜利信号写档、结算提示消费、`YuNpc` 离树 `_process` 回归、死亡用例仍放最后。

### step-05 全量验证、文档与清理

- 八步门禁全绿：`131 / 24 / 83 / 8 / 11 / 58 / 225 = 540`，无 `ERROR`。
- 三个场景无头冒烟均退出码 0、无 `ERROR`。
- 负速度红测：临时把 `dian_yao.tres` 的 `yi_dong_su_du` 改为负值，`ce_shu_ju` 变红；恢复后复跑 `Results: 83 passed, 0 failed`。
- 更新 `docs/TASK_INDEX.md`、`LEARNING_ROADMAP.md`、`docs/CHONG_GOU_LU_XIAN.md`、`docs/引擎词总表.md`，重新生成 `Godot引擎词总表.docx`。
- 清理临时测试存档与临时日志；正式产物保留。

## 与计划的偏差

| 项 | 计划 | 实际 | 原因 |
|---|---|---|---|
| 总断言 | 预计 470~490 | **540** | 形态数据校验与集成用例更细；逐项锁死三形态数值/阈值/初始能力 |
| `ce_shu_ju` | ~67 | **83** | 新增 3 形态逐字段断言 + 坏形态红测 ×5 + 主场景/Autoload 断言 |
| `ce_zhang_ben` | ~112 | **131** | 补充幂等、保留形态重开、开局不触发升级、历史仅 1 条等边界 |
| `ce_jie_suo` | ~40 | **58** | 增加浮点胜场、字符串胜场、非字符串形态、提示只消费一次等坏档分支 |
| `ce_panding` | ~213 | **225** | 选择页锁定状态与结算提示消费各补充正反用例；Boss 死亡切场景回归 +2 |
| `ce_bian_jie` | ~23 | **24** | 增加脏形态后两个字段同时归零断言 |
| 主场景 / Autoload 断言位置 | 计划写在 step-04 | 实际在 step-01 的 `ce_shu_ju` | `ProjectSettings` 断言属于数据/入口契约，和形态池校验同文件更集中；step-04 不再重复 |
| `.godot/editor` 缓存 + 旧场景 | 未计划清理 | 删除 `scenes/QiangHuaDanChuang.tscn` 并清缓存重导 | TASK-014 退役后旧场景仍引用已删脚本/资源，`--import` 报 12 条 `ERROR`；删除旧场景后 0 `ERROR` |

## 修复过的问题

1. **`--script` 模式不加载 Autoload**：`cun_dang.gd` 直接写 `ZhangBen.ju_jie_shu` 会编译失败。改为 `const JIE_JU_SHENG_LI := 1` 对齐枚举，`_ready()` 用 `get_node_or_null("/root/ZhangBen")` 动态连接。
2. **坏 JSON 打 ERROR**：`JSON.parse_string("not json")` 会向 Output 打解析错误，门禁零容忍。改用 `JSON.new().parse(text)`，失败只返回错误码。
3. **旧编辑器缓存引用已退役资源**：`.godot/editor` 里仍开着 `QiangHuaDanChuang.tscn` 与旧脚本，`--import` 报 `ERROR`。删除 `.godot/editor` 后重新 `--import`，门禁复绿。
4. **碰 Boss 死亡时报视口错误**：玩家被 Boss 击杀后切 `JieSuan`，旧场景的 `YuNpc` 已离树却仍被 `_process` 一帧，`get_viewport_rect()` 与 `get_viewport().get_camera_2d()` 报 `ERROR`。在 `YuNpc._process()` 与 `_shi_jiao_fan_wei()` 顶部加 `is_inside_tree()` 守卫，离树直接返回；`ce_panding` 增加 2 条回归断言。
5. **本报告回填前最后一次全量门禁**：清缓存后复跑，八步全绿、无 `ERROR`。

## 遗留

- **F5 手测待用户执行**：选择页锁定状态、三形态开局、胜利解锁、重启保持、坏档回退、再来一次/换形态。
- **学习验收待用户执行**：`LEARNING_STATE.json` 保持 `not_started`。
- **TASK-014 遗留（已清理）**：`scenes/QiangHuaDanChuang.tscn` 已删除。它曾引用已退役的 `qiang_hua_dan_chuang.gd` / `qiang_hua_ka.gd` / `data/qianghua/*.tres`，导致 `--import` 报 12 条 `ERROR`；删除场景并清理 `.godot/editor` 后，`--import` 与 Main / 选择页冒烟均为 0 `ERROR`。
- **未 commit / 未 push**：`last_verified_commit` 为空，任务包只能记 `review`。
