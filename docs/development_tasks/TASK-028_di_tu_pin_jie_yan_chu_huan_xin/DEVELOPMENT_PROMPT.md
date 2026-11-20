# TASK-028：九图拼合结尾演出重做

> 引擎：Godot 4.7
> 开发策略：plan_driven
> 参与模式：guided_co_development
> 执行模式：teaching
> 任务规格版本：v1
> 审批状态：awaiting
> 交付状态：proposed
> Git 基线：f27ae56893aed50db99ca6572659966bbca09b27

## 一、任务目标

用户认为现有通关前九图拼合演出「太 AI」：九块图飞入 + 回弹 + 红闪 + 大标题 + 震屏 + 玩家翘头旋转，特效堆叠、流水线感强。本任务只重做这 7.3 秒演出，参考《潜水员戴夫》式分镜，用慢推镜、九格波纹显影、单一焦点、打字机与留白替代特效堆叠。

### 完成后可观察结果

- 0.0~1.6 秒黑边合拢到 92px、镜头从玩家特写缓拉到全图。
- 0.5~2.5 秒九块图在最终位置 alpha/scale 显影，每块一圈波纹，玩家格最后。
- 2.5~3.6 秒玩家格金框、镜头轻推、区域名打字机。
- 4.5~5.9 秒机械船 4 帧动态船体从上方压入，冷蓝背光，无红闪/震屏。
- 7.3 秒收尾，`jie_shu` 只发一次；演出后机械船正常生成。
- ESC 或跳过按钮可在 0.6 秒后跳过，仍只发一次 `jie_shu`。

### 本任务不做

- 不改演出总时长、九图静态纯函数契约、Main 无敌/船生成时序。
- 不新增音效键/BGM 曲目/美术资源。
- 不改 gameplay 数值、鱼种、存档、`project.godot`、主场景顶层结构。
- 不重制音频（TASK-027）、不调整生态与鱼王（TASK-026）。

## 二、当前工程状态

### 已实现并验证

- `scripts/di_tu_pin_jie_yan_chu.gd`：九图拼合演出，`YAN_CHU_SHI_CHANG=7.3`；`_kai_shi()` 相机 1.15 秒拉全图、黑边 56px、九块图 0.45 秒起每 0.17 秒 `_tie_fei_xing`、玩家格落位回调、金线、`_ding_shi(4.5, _kai_shi_ren_lei)`、`_ding_shi(7.3, _jie_shu_yan_chu)`。
- `_kai_shi_ren_lei()`：`jing_bao` + `jue_zhan`、船 1.0 秒落到 `REN_LEI_LUO_DIAN`、红闪、大标题、震屏。
- `_jie_shu_yan_chu()`：唯一收尾入口，杀 tween、还原玩家、`jie_shu.emit()`、`queue_free()`。
- `tests/ce_panding.gd` 83-119 行：九图静态契约 `GE_SHU=9`、`DI_TU_CHI_CUN=4128×2304`、`MEI_GE_CHI_CUN=1376×768`、`quan_tu_zoom`、`ge_zi_qu`、`ge_zi_zhong_xin`、`wan_jia_pian`、`pin_jie_shun_xu`、`fei_ru_qi_dian` ≥1000px、`WAN_JIA_JU_JIAO=0.88`、`YAN_CHU_SHI_CHANG >= 7.0`。

### 已存在但未验证或未接通

- 震惊气泡节点与 `_process` 跟随。
- 演出期间 `QiPaoCeng` 会随机入镜；`SheZhi` 设置按钮仍可点，会暂停并冻住 pausable tween。
- 无 ESC 跳过。

### 审计新鲜度

- audited_commit：`f27ae56893aed50db99ca6572659966bbca09b27`
- environment_checked_at：`2026-11-14T20:10:03+08:00`
- engine_executable_source：`GODOT_4_7_BIN`
- engine_version_detected：`4.7.2.stable.official.ed1daf0bf`
- audit_invalidation_triggers：演出时长/纯函数/信号、Main 连接与船时序、九图断言、HUD 层名、音效键表、场景结构、引擎版本

### 当前依赖与阻塞

- 依赖 TASK-020 的九图拼合原型；TASK-020 交接曾写「禁止改九图演出流程（用户认可的前动画）」，本次用户 2026-11-14 明确要求重做，本任务包记录覆盖关系。
- 基线 `f27ae56893aed50db99ca6572659966bbca09b27` 工作区干净。
- 串行排在 TASK-026/027 之后，避免同工作区改 `ce_panding.gd` 冲突。

## 三、功能所有权与团队集成

### 功能所有者

- owner_id：`student-01`
- owned_systems：通关前九图拼合演出、演出期间 HUD 临时隐藏、演出跳过
- owned_scenes：无
- owned_scripts：`di_tu_pin_jie_yan_chu.gd`、`main.gd`
- owned_config_tables：无

### 集成合同

| 类型 | 名称/路径 | 提供方 | 使用方 | 合同 | 变更风险 |
|---|---|---|---|---|---|
| 消费 | `Main._bo_fang_ren_lei_yan_chu()` | Main | 演出 | 创建演出节点并连接 `jie_shu` | 改流程会破船时序 |
| 提供 | `DiTuPinJieYanChu.jie_shu` | 演出 | Main | 只发一次 | 重复发会重复生成机械船 |
| 提供 | `_unhandled_input(ui_cancel)` | 演出 | 玩家 | ESC 跳过 | 与按钮跳过重复发信号 |
| 提供 | `fei_ru_qi_dian()` | 演出 | 静态测试 | 保留但运行时不使用 | 删除会破旧契约 |
| 共享 | `YAN_CHU_SHI_CHANG=7.3` | 演出 | 测试/Main | 与 `_ding_shi(7.3)` 一致 | 两处不同步会提前/延后收尾 |

### 禁止的跨功能访问

- 禁止改 Main 的 10 秒无敌与机械船生成时序。
- 禁止改 `HUD_CENG_MING` 的 `XiaoDiTuUI` 层名。
- 禁止新增音效键或用 BGM 曲名之外的音频。

## 四、学生参与与学习目标

### 学习目标

- 学生能够解释「显影」与「飞入」的时间轴差别。
- 学生能够指出九图静态纯函数契约并说明为什么保留。
- 学生能够定位 `_jie_shu_yan_chu()` 唯一收尾入口，解释 `jie_shu` 只发一次。
- 学生能够说明演出期间隐藏 `QiPaoCeng`/设置按钮的原因。

### 三个必需检查点

1. **实现前定位与理解**：打开 `scripts/di_tu_pin_jie_yan_chu.gd`，指出 `_kai_shi()` 与 `_kai_shi_ren_lei()` 的时间轴；解释为什么保留 `fei_ru_qi_dian()` 但运行时不使用。
2. **实现后 Godot 检查**：F5 触发结尾演出，观察九格显影、玩家格金框、船体压入；检查无震惊气泡节点。
3. **验证与交接**：运行门禁，解释 `jie_shu` 单次断言与演出后船生成。

### 参与边界

| 工作项 | AI 主导内容 | 学生参与内容 | 客观证据 |
|---|---|---|---|
| 九格显影 | 时间轴、波纹、金线、测试 | F5 目检顺序与观感 | `editor_operation`、`result_interpretation` |
| 玩家焦点 | 金框、打字机、镜头 | 指出单一焦点与留白 | `concept_explanation` |
| 船体入场 | 4 帧船、冷蓝背光、标题 | 目检无红闪/震屏 | `scene_tree_inspection` |
| 收尾/跳过 | 唯一入口、ESC、HUD 隐藏 | 解释单次 jie_shu 与船生成 | `test_execution` |

### 防卡住与恢复规则

- 学生第一次表示不会时，AI 演示最小步骤并让学生复述或检查一个明确结果；仍无法识别则由 AI 说明正确观察并记录待巩固概念。
- AI 演示最多记 `introduced`；学生实际目检/解释才提高等级。
- Godot 编辑器不可用时，可检查脚本时间轴、测试输出或截图，记录真实证据。

## 五、行为合同与数据流

### 行为合同

- 前置条件：Main 触发通关前演出，玩家节点存在。
- 输入：`Main` 创建演出节点；玩家所在格 `wan_jia_pian`；九图纹理。
- 状态转换：0.0 黑边/镜头 → 0.5 九格显影 → 2.5 玩家焦点/打字机 → 3.6 回全图 → 4.5 船入场 → 5.9 停驻 → 6.6 收尾 → 7.3 `_jie_shu_yan_chu()`。
- 输出：视觉演出；`jie_shu` 信号一次；玩家位置/旋转还原；HUD 恢复。
- 失败、取消与重试：ESC/按钮跳过走同一 `_tiao_guo()`；重复调用不重复 emit。
- 边界情况：`YAN_CHU_SHI_CHANG` 与 `_ding_shi(7.3)` 必须一致；演出期间设置按钮不可用；演出后 `QiPaoCeng` 恢复。

### 数据流

    Main._bo_fang_ren_lei_yan_chu -> new DiTuPinJieYanChu -> _kai_shi 时间轴
      -> _jie_shu_yan_chu（杀 tween/还原玩家/清 offset）-> jie_shu.emit() -> Main 继续船时序

## 六、场景节点树与加载

- architecture_change：false
- entry_scene：`res://scenes/Main.tscn`
- lifecycle_rationale：`DiTuPinJieYanChu` 仍是 Main 运行时创建的演出节点；只改内部视觉与时间轴，并对既有 `QiPaoCeng`/设置按钮做临时 `visible` 切换；不新增/删除主场景节点、不改顶层树、Autoload 与存档。

## 七、文件范围

### 允许修改的现有文件

| 路径 | 修改原因 | 所有者 | 是否共享文件 |
|---|---|---|---|
| `scripts/di_tu_pin_jie_yan_chu.gd` | 7.3 秒新分镜 | student-01 | 是（TASK-020） |
| `scripts/main.gd` | 演出期间隐藏/恢复气泡层与设置按钮 | student-01 | 是 |
| `tests/ce_panding.gd` | 保留静态契约，新增演出用例 | student-01 | 是 |
| `docs/TASK_INDEX.md` 等 | 任务与词表收尾 | student-01 | 是 |

### 允许新增的文件

| 路径 | 职责 | 调用方 |
|---|---|---|
| `docs/development_tasks/TASK-028_.../IMPLEMENTATION_REPORT.md` | 实现报告 | 团队 |
| `docs/development_tasks/TASK-028_.../VERIFICATION_REPORT.md` | 验证报告 | 团队 |
| `docs/development_tasks/TASK-028_.../CODE_REVIEW.md` | 代码审查 | 团队 |

### 禁止修改的系统

- `YAN_CHU_SHI_CHANG`、`_ding_shi(7.3)`、九图静态纯函数契约。
- 音效键表、BGM 曲目、HUD 层名。
- Main 无敌/船生成时序、gameplay 数值、存档、`project.godot`。

## 八、分步实现

### Step 1：黑边合拢、九格波纹显影与接缝金线

**目标行为**：0.0~1.6 秒黑边 92px、镜头缓拉；0.5~2.5 秒九块图在最终中心显影，玩家格最后；1.2~2.2 秒金线分段亮到 0.55。

**核心概念**：显影而非飞入——元素初始就在最终位置，只改变透明度与缩放。误用时的可观察失败是继续从 `fei_ru_qi_dian()` 起飞，导致九块图重叠、回弹与「AI 感」。

**涉及文件**：`scripts/di_tu_pin_jie_yan_chu.gd`、`tests/ce_panding.gd`。

**AI 实现内容**：`_jian_di_tu()` 把九块图初始位置设为 `ge_zi_zhong_xin(pian)`、`scale=1`、`alpha=0`；`_kai_shi()` 按 `pin_jie_shun_xu` 每块错峰约 0.15 秒 alpha 0→1、scale 0.96→1，并创建 `Line2D` 波纹圆环（半径 12→220、透明度淡出）；金线分段亮起；黑边 92px/0.5 秒；相机 1.6 秒 SINE/EASE_IN_OUT 到全图中心；保留 `fei_ru_qi_dian()` 加注释「兼容静态契约，演出不再飞入」。

**学生参与点**：检查点 `orientation`；指出旧 `_tie_fei_xing()` 的起点计算，并解释为什么新演出不需要它。

**设计选择**：A. 在最终位置显影（推荐，单一焦点、无重叠）；B. 保留飞入但缩短距离（仍有回弹感，不推荐）。

**自动验证**：九块图初始位置等于 `ge_zi_zhong_xin(pian)`；alpha/scale 显影断言；静态契约不变。

**Godot 检查**：F5 目检九格显影与波纹。

**验证含义**：证明实现路径与时间轴，不证明观感；观感需用户 F5。

**记录要求**：更新 step-01 状态与学习证据。

**通过条件**：显影断言全绿，静态契约断言不变。

### Step 2：玩家格焦点、区域名打字机与镜头呼吸

**目标行为**：2.5~3.6 秒玩家格金框、镜头轻推、区域名打字机；3.6~4.5 秒回全图、区域名淡出；无震惊气泡。

**核心概念**：单一焦点——同一时间只让一个元素成为视觉中心。误用时的可观察失败是同时亮金框、弹震惊气泡、放大字，视线无处落脚。

**涉及文件**：`scripts/di_tu_pin_jie_yan_chu.gd`。

**AI 实现内容**：玩家格金框 Tween；镜头 0.6 秒轻推、停留；区域名 Label 用 `visible_ratio` 打字机，副标题「第 N 天 · 水位线 −12m」；3.6 秒回全图并淡出；删除震惊气泡节点与 `_process` 跟随。

**学生参与点**：检查点 `godot-inspection`；F5 观察玩家格金框与打字机节奏。

**设计选择**：A. 只保留玩家格金框与区域名（推荐，单一焦点）；B. 保留震惊气泡+大字（视觉堆叠，不推荐）。

**自动验证**：不再创建震惊气泡节点；区域名 `visible_ratio` 0→1；演出后玩家位置/旋转还原。

**Godot 检查**：F5 目检焦点与打字机。

**验证含义**：证明焦点与文本显现，不证明节奏舒适度。

**记录要求**：更新 step-02。

**通过条件**：无气泡断言与打字机断言全绿。

### Step 3：机械船动态入场、冷蓝背光与去红闪震屏

**目标行为**：4.5~5.9 秒 `jing_bao` + `jue_zhan`，4 帧船体 1.4 秒压入，冷蓝背光 alpha ≤0.12，全图压暗 12%，标题打字机；5.9~6.6 秒停驻、舱灯闪 2 次、落点气泡；无红闪/震屏/玩家翘头。

**核心概念**：动态剪影——用 4 帧船体与冷色背光制造压迫，而不是靠红闪与震屏堆叠。误用时的可观察失败是红闪盖住船体细节、震屏让九图抖动。

**涉及文件**：`scripts/di_tu_pin_jie_yan_chu.gd`。

**AI 实现内容**：改用 `data/donghua/ji_qi_chuan_4zhen.tres` 的 `AnimatedSprite2D`，保留 `CHUAN_TIE_TU` 静态兜底；背光改冷蓝 `Color(0.58,0.74,0.92)`、最高 alpha 约 0.12；全图压暗 12%；标题 0.05 秒/字；删除红闪、震屏、翘头；5.9 秒舱灯闪 2 次、落点一次气泡。

**学生参与点**：检查点 `godot-inspection`；F5 观察船体压入与背光。

**设计选择**：A. 4 帧船体 + 冷蓝背光（推荐，压迫但不刺眼）；B. 保留红闪/震屏（与用户反馈冲突，不推荐）。

**自动验证**：使用 4 帧资源且保留静态兜底；冷蓝颜色与 alpha 上限；无红闪/震屏节点；标题打字机。

**Godot 检查**：F5 目检船体与背光。

**验证含义**：证明资源与色彩路径，不证明压迫感强度。

**记录要求**：更新 step-03。

**通过条件**：船体/背光/无红闪断言全绿。

### Step 4：HUD 临时隐藏、ESC 跳过、测试与门禁

**目标行为**：演出期间隐藏 `QiPaoCeng`/设置按钮，结束后恢复；ESC/按钮跳过只发一次 `jie_shu`；7.3 秒收尾清理全部 Tween 与临时节点。

**核心概念**：单一收尾入口——所有 Tween 与临时节点在 `_jie_shu_yan_chu()` 同一处清理。误用时的可观察失败是跳过路径与超时路径各发一次 `jie_shu`，Main 重复生成机械船。

**涉及文件**：`scripts/main.gd`、`scripts/di_tu_pin_jie_yan_chu.gd`、`tests/ce_panding.gd`。

**AI 实现内容**：`main.gd` 在 `_bo_fang_ren_lei_yan_chu` 期间记录并隐藏 `QiPaoCeng`/设置按钮，`jie_shu` 后恢复；`_unhandled_input` 监听 `ui_cancel` 调 `_tiao_guo()`；`_tiao_guo()` 与跳过按钮走同一路径；`_jie_shu_yan_chu()` 加一次性守卫；新增 `jie_shu` 单次与跳过路径测试；跑门禁与 validate/scope。

**学生参与点**：检查点 `verification-handoff`；解释 `jie_shu` 单次与演出后船生成。

**设计选择**：A. 单一 `_jie_shu_yan_chu()` + 一次性守卫（推荐）；B. 跳过路径单独收尾（容易重复发信号，不推荐）。

**自动验证**：`jie_shu` 单次；HUD 隐藏/恢复；`YAN_CHU_SHI_CHANG` 与 `_ding_shi(7.3)` 一致；八步全绿。

**Godot 检查**：F5 演出后机械船正常生成、ESC/按钮跳过后不重复。

**验证含义**：证明生命周期与信号单次，不证明真机触控跳过体验。

**记录要求**：完成全部状态、报告与交接。

**通过条件**：全部门禁与 F5 通过；未 commit/push。

## 九、完整验证

### 工程与配置

- GDScript 解析、节点路径、信号连接、资源引用、UID 无新增；`project.godot` 不改。

### 自动化与 Godot 4.7

- `GODOT_BIN --version` 显示 4.7.x；`--import` 0 ERROR；`tests/pao_pi.bat` 八步全绿。

### 场景生命周期

- 演出节点创建/收尾/释放；正常与跳过路径 `jie_shu` 各只发一次；HUD 隐藏/恢复；玩家位置/旋转/相机 offset 还原；演出后机械船生成。

### Git 范围

- `check_task_scope.py capture` 开工前；`check` 完工后 0 violation。

### 学习证据

- 三个检查点；未发生则 `participation_pending`。

### 集成交接

- `INTEGRATION_HANDOFF.md` 与实际时间轴、信号、HUD 隐藏一致。

## 十、停止条件

- 需要改演出总时长、Main 无敌/船生成时序或九图静态契约。
- 需要新增音效键/BGM/美术资源。
- 需要改主场景顶层结构或 HUD 层名。
- 正常与跳过路径无法保证 `jie_shu` 单次。

记录证据、更新状态并停止，不得用临时兼容代码绕过。

## 十一、完成与交接定义

- 新分镜 7.3 秒全部有 F5 或测试证据。
- 九图静态契约与 19/3 音效契约不变。
- 八步门禁、validate、scope、import 全过。
- 代码审查无未解决范围内 P0/P1/P2。
- 学习状态不夸大；交接文档写清时间轴、信号、HUD 与跳过。

## 十二、审批

任何能明确表达“同意 TASK-028 v1 进入开发”的用户文本都有效。记录原文、时间与规格版本。建议表达：`确认 TASK-028 v1 进入开发`。
