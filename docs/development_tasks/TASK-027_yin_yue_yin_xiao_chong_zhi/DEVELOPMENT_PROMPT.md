# TASK-027：全部音乐与音效重制

> 引擎：Godot 4.7
> 开发策略：plan_driven
> 参与模式：guided_co_development
> 执行模式：teaching
> 任务规格版本：v1
> 审批状态：awaiting
> 交付状态：proposed
> Git 基线：f27ae56893aed50db99ca6572659966bbca09b27

## 一、任务目标

按用户「游戏全部音乐重新生成一遍，全部！音效也是」的要求，把现有 3 条 BGM 与 19 条使用中音效全部重制，而不是重渲染旧工程。BGM 保持原 BPM、小节数与时长以控制 Web 包体；音效统一为 44.1kHz/16bit/单声道/峰值 -1.5dBFS，并把 7 个仍指向旧 wav 的键改接到新生成文件，删除 11 条旧 wav。

### 完成后可观察结果

- 3 条 BGM 全部由重写后的编曲渲染，循环试听无断缝。
- 19 条音效全部由 `shengcheng_yin_xiao.py` 生成，格式与峰值校验通过。
- `YinXiang.YIN_XIAO_BIAO` 仍是 19 键，`BGM_QU_MU` 仍是 3 首。
- `assets/yinxiao` 不再保留 11 条旧 wav。
- `tests/pao_pi.bat` 八步全绿，Web 导出可加载并播放。

### 本任务不做

- 不新增音效键、BGM 曲目或 gameplay 调用点。
- 不把 `qu_jing_sha` 接入游戏；它只写 `build/音乐试听`。
- 不改任何 gameplay 脚本、场景、`.tres`、存档或 `project.godot`。
- 不重做九图结尾演出（TASK-028）。

## 二、当前工程状态

### 已实现并验证

- `scripts/yin_xiang.gd`：`YIN_XIAO_BIAO` 19 键，`BGM_QU_MU` 3 首；`sheng_ji/yao/shou_shang/si_wang` 已指向 `yin_xiao_*`。
- `tools/yinyue/shengcheng_yin_xiao.py`：12 条 `qu_*` 与 `JOBS`，44.1kHz/16bit/单声道/-1.5dBFS，`validate()` 校验格式/时长/峰值。
- `tools/yinyue/shengcheng_yinyue.py`：LMMS `.mmp` → 3 BGM，56/96/140 BPM，12/16/24 小节，`loop_wav()` 尾音折回；`qu_jing_sha` 只写 `build/音乐试听`。
- `assets/yinxiao`：3 BGM + 12 条 `yin_xiao_*` + 11 条旧 wav（旧文件 22050Hz）。

### 已存在但未验证或未接通

- 7 个旧键（`an_niu`、`chi`、`tan_chuang`、`fang_neng_li`、`shi_kong`、`sheng_li`、`shi_bai`）仍指向旧 22050Hz wav。
- BGM 脚本无 `validate_bgm()`；`inst_triple` 只设置 `finer1`，左右失谐不一致。
- 11 条旧 wav 已无实际引用（`sheng_ji/yao/shou_shang/si_wang` 的旧文件已不被 preload）。

### 审计新鲜度

- audited_commit：`f27ae56893aed50db99ca6572659966bbca09b27`
- environment_checked_at：`2026-11-14T20:10:03+08:00`
- engine_executable_source：`GODOT_4_7_BIN`
- engine_version_detected：`4.7.2.stable.official.ed1daf0bf`
- audit_invalidation_triggers：YinXiang 键表/路径、生成器输出规格、assets 文件增删、导入缓存、LMMS 环境、引擎版本

### 当前依赖与阻塞

- LMMS `D:\LMMS\lmms.exe` 已存在；Python 环境可运行两个生成器。
- 基线 `f27ae56893aed50db99ca6572659966bbca09b27` 工作区干净。
- 本任务不改 gameplay，可与 TASK-026 交替执行；但因都改 `tests/ce_panding.gd`（本任务可能不改），计划仍按串行 026 → 027 → 028。

## 三、功能所有权与团队集成

### 功能所有者

- owner_id：`student-01`
- owned_systems：程序化音乐生成、程序化音效生成、音频键表接线
- owned_scenes：无
- owned_scripts：`yin_xiang.gd`、`shengcheng_yinyue.py`、`shengcheng_yin_xiao.py`
- owned_config_tables：无

### 集成合同

| 类型 | 名称/路径 | 提供方 | 使用方 | 合同 | 变更风险 |
|---|---|---|---|---|---|
| 消费 | `YinXiang.fang(bian_hao)` | 全项目 | 本任务 | 19 个键名稳定 | 改键名会断 24 处 `an_niu` |
| 消费 | `YinXiang.bo_bgm(qu)` | Main/结算 | 本任务 | `shen_hai/tan_suo/jue_zhan` | 改曲名会断 BGM 断言 |
| 提供 | `assets/yinxiao/yin_xiao_*.wav` | 本任务 | YinXiang | 44.1kHz/16bit/单声道/-1.5dBFS | 格式不符会导致导入/播放异常 |
| 提供 | `assets/yinxiao/bgm_*.wav` | 本任务 | YinXiang | 原 BPM/小节/时长、无缝循环 | 时长变化影响包体与循环 |
| 提供 | `validate_bgm()` | 本任务 | 生成器 | 格式/时长/峰值/循环缝 | 无校验会重演“太吵”或断缝 |
| 信号 | 无新增 | — | — | `bei_ji_bai` 等语义不变 | — |

### 禁止的跨功能访问

- 禁止改 `YIN_XIAO_BIAO` 的键名或新增键。
- 禁止把 `qu_jing_sha` 接入 `assets` 或 `BGM_QU_MU`。
- 禁止用脚本改 gameplay 逻辑来“适配”音频。

## 四、学生参与与学习目标

### 学习目标

- 学生能够定位 `YIN_XIAO_BIAO` 并解释键名与资源路径解耦。
- 学生能够查看生成器 `validate()` 与 `validate_bgm()`，解释格式/峰值/循环缝检查。
- 学生能够试听并指出 BGM 循环接缝与音效辨识度。
- 学生能够解释为什么旧 wav 要先等新文件导入与测试通过再删除。

### 三个必需检查点

1. **实现前定位与理解**：打开 `scripts/yin_xiang.gd`，指出 7 个旧键与 19 键总数；解释只换路径不改键名的原因。
2. **实现后 Godot 检查**：在编辑器检查 `assets/yinxiao` 的音频导入参数；F5 逐条触发音效。
3. **验证与交接**：运行生成器与门禁，解释 validate 输出与试听结论。

### 参与边界

| 工作项 | AI 主导内容 | 学生参与内容 | 客观证据 |
|---|---|---|---|
| 19 条音效 | 生成函数、JOBS、validate | 检查键表与试听 | `configuration_inspection`、`result_interpretation` |
| 键表接线 | preload 路径、删除旧 wav | 指出 7 个旧键并确认键名不变 | `project_navigation` |
| 3 条 BGM | 编曲、loop_wav、validate_bgm | 循环试听 | `test_execution` |
| 收尾 | 导入、门禁、包体、报告 | 解释包体与试听结论 | `result_interpretation` |

### 防卡住与恢复规则

- 学生第一次表示不会操作时，AI 演示最小步骤并让学生复述或检查一个明确结果；仍无法识别则由 AI 说明正确观察并记录待巩固概念。
- AI 演示最多记 `introduced`；只有学生实际试听/识别/解释才提高等级。
- 无法打开 LMMS GUI 时，可检查生成器输出、wav 格式与门禁结果，记录真实证据类型。

## 五、行为合同与数据流

### 行为合同

- 前置条件：`assets/yinxiao` 存在旧资源；生成器可运行。
- 输入：生成器 JOBS 参数、LMMS `.mmp`、`loop_wav` 参数。
- 状态转换：生成新 wav → `validate` → 导入 → 测试 → 改 preload → 删除旧 wav。
- 输出：19 条 SFX、3 条 BGM、19 键表、3 曲表。
- 失败、取消与重试：任一 validate 失败则不删除旧文件、不改 preload，保留可回退。
- 边界情况：BGM 时长 ±0.05 秒；SFX 时长 ±0.002 秒；峰值 -3~-1 dBFS；首尾 10ms 电平接近 0。

### 数据流

    JOBS/.mmp -> 合成 -> wav -> validate -> assets/yinxiao -> Godot import -> YinXiang preload -> fang/bo_bgm

## 六、场景节点树与加载

- architecture_change：false
- entry_scene：`res://scenes/Main.tscn`
- lifecycle_rationale：只替换 Autoload `YinXiang` 的 preload 资源路径与 assets 文件，不新增/删除节点、不改 Autoload 顺序与场景树。

## 七、文件范围

### 允许修改的现有文件

| 路径 | 修改原因 | 所有者 | 是否共享文件 |
|---|---|---|---|
| `tools/yinyue/shengcheng_yin_xiao.py` | 19 条音效生成 | student-01 | 否 |
| `tools/yinyue/shengcheng_yinyue.py` | 3 BGM 重编曲 + validate_bgm | student-01 | 否 |
| `scripts/yin_xiang.gd` | 7 个旧键 preload 路径 | student-01 | 是（全项目调用） |
| `tests/ce_panding.gd` | 必要时同步音频契约 | student-01 | 是 |
| `assets/yinxiao/bgm_*.wav` | 重新生成 | student-01 | 是 |
| `assets/yinxiao/yin_xiao_*.wav` | 重新生成 | student-01 | 是 |
| `assets/yinxiao/<11 条旧 wav>` | 删除 | student-01 | 是 |

### 允许新增的文件

| 路径 | 职责 | 调用方 |
|---|---|---|
| `assets/yinxiao/yin_xiao_an_niu.wav` 等 7 条 | 旧键新音效 | `YinXiang` |
| `docs/development_tasks/TASK-027_.../IMPLEMENTATION_REPORT.md` | 实现报告 | 团队 |
| `docs/development_tasks/TASK-027_.../VERIFICATION_REPORT.md` | 验证报告 | 团队 |
| `docs/development_tasks/TASK-027_.../CODE_REVIEW.md` | 代码审查 | 团队 |

### 禁止修改的系统

- 任何 gameplay 脚本、场景、`.tres`、存档、`project.godot`。
- 19 个音效键名、3 首 BGM 曲名与断言。
- `qu_jing_sha` 的试听隔离策略。

## 八、分步实现

### Step 1：12 条既有音效重写与 7 条旧键音效补齐

**目标行为**：19 条 job 全部成功，`validate()` 全过。

**核心概念**：参数化音频合成管线——统一采样率、位深、声道与峰值约束。误用时的可观察失败是 19 条里混入 22050Hz 或立体声文件，导致导入警告与播放音量不一致。

**涉及文件**：`tools/yinyue/shengcheng_yin_xiao.py`、`assets/yinxiao/yin_xiao_*.wav`。

**AI 实现内容**：重写 12 条 `qu_*` 的包络与音色；新增 7 条 `qu_an_niu`、`qu_chi`、`qu_tan_chuang`、`qu_fang_neng_li`、`qu_shi_kong`、`qu_sheng_li`、`qu_shi_bai`；`JOBS` 扩到 19；`validate()` 检查格式、精确时长 ±0.002、峰值 -3~-1 dBFS、循环接缝；`main()` 清单同步。

**学生参与点**：检查点 `orientation`；打开 `YIN_XIAO_BIAO` 数 19 键，指出 7 个旧键。

**设计选择**：A. 19 条统一走一个生成器（推荐，格式一致）；B. 保留 7 条旧 wav（会保留 22050Hz 不一致，不推荐）。

**自动验证**：19 条 job 成功、validate 全过、文件数量 19。

**Godot 检查**：`--import` 无音频导入 ERROR。

**验证含义**：证明格式与峰值一致，不证明主观好听。

**记录要求**：更新 step-01 状态与学习证据。

**通过条件**：19 条生成与校验全过。

### Step 2：音效键表接线与旧 wav 清理

**目标行为**：7 个旧键指向新文件；19 键不变；删除 11 条旧 wav 后导入与门禁仍绿。

**核心概念**：键表解耦——调用方按稳定键名播放，资源路径可在键表内替换。误用时的可观察失败是把键名改成文件名，导致 24 处 `an_niu` 调用点全部失效。

**涉及文件**：`scripts/yin_xiang.gd`、`assets/yinxiao/*.wav`、`tests/ce_panding.gd`。

**AI 实现内容**：改 7 个 preload 路径（`an_niu`、`chi`、`tan_chuang`、`fang_neng_li`、`shi_kong`、`sheng_li`、`shi_bai`）；确认 `sheng_ji/yao/shou_shang/si_wang` 已指向新文件；删除 11 条旧 wav 与 `.import`；重新 import；保留 `YIN_XIAO_BIAO.size()==19` 与 3 BGM 断言。

**学生参与点**：检查点 `godot-inspection`；在编辑器打开 `yin_xiang.gd`，确认键名未变、路径已换。

**设计选择**：A. 只换路径、键名不动（推荐，零调用点改动）；B. 把键名统一成 `yin_xiao_*`（会改 24 处调用点，不推荐）。

**自动验证**：19 键、3 曲、`--import` 0 ERROR、门禁全绿。

**Godot 检查**：F5 按钮/吃植物/弹窗/技能/失控/胜负均出声。

**验证含义**：证明接线与资源清理正确，不证明每条音效辨识度。

**记录要求**：更新 step-02。

**通过条件**：19/3 断言与门禁全绿，旧 wav 已删除且无引用告警。

### Step 3：3 条 BGM 重编曲与循环校验

**目标行为**：3 条 BGM 重编曲成功，时长、格式、峰值与循环缝校验全过。

**核心概念**：无缝循环——把尾音折回开头，使播放器从末尾回到 0 时没有可听断点。误用时的可观察失败是循环点出现明显“啪”声或电平跳变。

**涉及文件**：`tools/yinyue/shengcheng_yinyue.py`、`assets/yinxiao/bgm_*.wav`。

**AI 实现内容**：重写 `qu_shen_hai`、`qu_tan_suo`、`qu_jue_zhan` 的编曲与混音，保持 56/96/140 BPM、12/16/24 小节、约 51.4/40.0/41.1 秒；`loop_wav` 继续折回尾音；新增 `validate_bgm()` 检查 44.1kHz/单声道/16bit、时长 ±0.05 秒、峰值、首尾 10ms 电平；修复 `inst_triple` 的 `finel/finer` 成对设置。

**学生参与点**：检查点 `godot-inspection`/试听；循环播放主菜单曲，听接缝。

**设计选择**：A. 保持原时长重编曲（推荐，控包体）；B. 延长 BGM（Web 包体增大，不推荐）。

**自动验证**：3 条渲染成功、validate_bgm 全过、总大小 ≤20MB。

**Godot 检查**：F5 三条 BGM 循环无断缝。

**验证含义**：证明循环与格式，不证明编曲主观质量。

**记录要求**：更新 step-03。

**通过条件**：validate_bgm 全过，试听无断缝。

### Step 4：导入、门禁、试听与文档收尾

**目标行为**：全量验证通过，文档更新，包体可控。

**核心概念**：资源导入与运行时接线分离——先保证导入无 ERROR，再验证播放链路。误用时的可观察失败是跳过导入直接跑门禁，掩盖资源路径错误。

**涉及文件**：`tests/ce_panding.gd`、`docs/TASK_INDEX.md`、`docs/引擎词总表.md`、`LEARNING_ROADMAP.md`、`Godot引擎词总表.docx`。

**AI 实现内容**：跑两个生成器、`--import`、八步门禁、validate、scope；Web 导出对比 `index.pck` 大小；写三份报告；更新索引与词表。

**学生参与点**：检查点 `verification-handoff`；解释 validate 输出与包体变化。

**设计选择**：A. 全部通过再交付（推荐）；B. 跳过 Web 包体对比（风险高，不推荐）。

**自动验证**：全部检查通过。

**Godot 检查**：F5 与 Web 试听。

**验证含义**：证明工程与 Web 可加载播放，不证明用户主观满意。

**记录要求**：完成全部状态与报告。

**通过条件**：全部门禁与试听通过；未 commit/push。

## 九、完整验证

### 工程与配置

- Python 生成器语法与路径；wav 格式；`.import` 与 `.godot` 缓存无 ERROR。

### 自动化与 Godot 4.7

- `GODOT_BIN --version` 显示 4.7.x；`--import` 0 ERROR；`tests/pao_pi.bat` 八步全绿。

### 场景生命周期

- Autoload `YinXiang` 顺序不变；BGM 循环与 `finished` 兜底仍有效；旧 wav 删除后无悬挂 preload。

### Git 范围

- `check_task_scope.py capture` 开工前；`check` 完工后 0 violation。

### 学习证据

- 三个检查点；未发生则 `participation_pending`。

### 集成交接

- `INTEGRATION_HANDOFF.md` 与实际键表/文件一致。

## 十、停止条件

- 需要新增键/曲目或改 gameplay 脚本。
- 生成器无法产出符合格式的文件。
- 删除旧 wav 后出现导入 ERROR 或运行时缺资源。
- BGM 时长/包体超出约束且无法通过重编曲控制。

记录证据、更新状态并停止，不得用临时音频占位绕过。

## 十一、完成与交接定义

- 19 条 SFX 与 3 条 BGM 全部生成并通过校验。
- 19 键/3 曲断言不变；门禁全绿；Web 可播放。
- 代码审查无未解决范围内 P0/P1/P2。
- 最终差异只含允许文件。
- 学习状态不夸大；交接文档写清键表、路径、校验与试听限制。

## 十二、审批

任何能明确表达“同意 TASK-027 v1 进入开发”的用户文本都有效。记录原文、时间与规格版本。建议表达：`确认 TASK-027 v1 进入开发`。
