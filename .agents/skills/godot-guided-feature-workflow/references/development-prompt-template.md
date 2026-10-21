# Development Prompt Template

Generate a self-contained `DEVELOPMENT_PROMPT.md`. Replace every placeholder and remove only sections that genuinely do not apply.

```markdown
# TASK-NNN: 功能名称

> 引擎：Godot 4.7
> 开发策略：plan_driven / behavior_guided / hybrid
> 参与模式：guided_co_development / guided_practice / independent_challenge
> 执行模式：teaching / batch
> 任务规格版本：vN
> 审批状态：awaiting
> 交付状态：proposed
> Git 基线：<commit>

## 一、任务目标

说明本任务解决的问题、玩家或开发者可观察结果，以及为什么它是当前合适的下一步。

### 完成后可观察结果

- 使用可运行、可检查、可判定的描述。

### 本任务不做

- 明确排除相邻系统、重构、内容扩充和长期功能。

## 二、当前工程状态

### 已实现并验证

- 行为、路径、接口和验证证据。

### 已存在但未验证或未接通

- 区分代码、场景、资源、配置和运行时连接。

### 审计新鲜度

- audited_commit：
- environment_checked_at：
- engine_executable_source：
- engine_version_detected：
- audit_invalidation_triggers：

### 当前依赖与阻塞

- 列出依赖任务、稳定接口、Godot 版本、配置校验器和环境限制。

## 三、功能所有权与团队集成

### 功能所有者

- owner_id：
- owned_systems：
- owned_scenes：
- owned_scripts：
- owned_config_tables：

### 集成合同

| 类型 | 名称/路径 | 提供方 | 使用方 | 合同 | 变更风险 |
|---|---|---|---|---|---|

分别列出依赖任务、消费接口、提供接口、发出信号、接收信号、共享状态、冲突热点和必需集成检查。

明确登记是否修改 `project.godot`、Autoload、主场景、存档结构、事件总线或共享配置。未登记即禁止修改。

### 禁止的跨功能访问

- 禁止通过长 NodePath、`/root` 搜索或场景内部节点路径访问其他学生负责的功能。
- 只能通过本节登记的公开接口、信号或数据合同集成。

## 四、学生参与与学习目标

### 学习目标

- 使用“学生能够定位、解释、检查、验证、诊断……”描述可观察能力。
- AI 完成代码不自动证明学习目标达成。

### 三个必需检查点

1. **实现前定位与理解**：学生确认任务目的、受影响位置、一个核心概念和一个有限设计选择。
2. **实现后 Godot 检查**：学生按精确编辑器路径检查场景、节点、脚本、信号或配置中的真实对象。
3. **验证与交接**：学生运行或解释检查，说明入口、输入、输出、依赖、公开接口和故障排查位置。

### 参与边界

| 工作项 | AI 主导内容 | 学生参与内容 | 客观证据 |
|---|---|---|---|

`guided_co_development` 默认由 AI 完成主要工程实现。学生不必手写核心功能，但不得只被动观看。

### 防卡住与恢复规则

- 学生第一次表示不知道或不会操作时，AI 立即演示最小完整步骤，再让学生复述原理或检查一个明确结果；仍无法识别时由 AI 说明正确观察、记录待巩固概念并继续已批准活动，不得重复追问或无限等待。
- AI 演示本身最多记录为 `introduced`，只有学生实际复述、识别、应用或诊断后才能提高理解等级。
- Godot 编辑器操作暂时不可用时，可以改为检查指定 `.tscn`、脚本、配置项、截图、测试结果或日志，但必须记录真实证据类型，不得把查看结果写成已完成编辑器操作。
- 每次暂停都要在 `TASK_STATE.json` 中写明当前 Step、检查点、已完成结果、下一项学生操作，以及需要打开的精确文件、场景或报告。
- 不设置缺席处理流程。不同时间参与的学生通过任务所有权、公开接口和 `INTEGRATION_HANDOFF.md` 完成协作与交接。

## 五、行为合同与数据流

### 行为合同

- 前置条件：
- 输入：
- 状态转换：
- 输出：
- 失败、取消与重试：
- 边界情况：

`behavior_guided` 或 `hybrid` 摘要引用同目录 `BEHAVIOR_SPEC.md`，并分开记录已观察行为、当前需求、技术决策、主动差异和未知项。验收标准不得依赖行为对照工程仍然可用。

### 数据流

    输入
      -> 解析与校验
      -> 领域规则或状态变更
      -> 公开结果/信号
      -> 调用方或视图

说明每段数据的所有者。UI 和场景节点不得成为业务规则或需持久化状态的唯一真实来源。

## 六、场景节点树与加载

### 架构影响

- architecture_change：true / false
- entry_scene：
- lifecycle_rationale：

`false` 时写明节点树和生命周期不变的依据即可。

`true` 时必须补全：

- 当前相关节点树和目标节点树。
- 场景/节点职责、所有者和公开接口。
- 创建、进入树、退出、释放和重入行为。
- 加载策略及失败/重复请求处理。
- 信号连接者、断开所有者和防重复连接策略。
- 跨场景状态保存和重新注入方式。
- AnimationPlayer、AnimationTree、Tween 和轨道 NodePath 依赖。
- 首次加载、退出、卸载、重入、快速重复切换和重复信号检查。

场景提取或顶层节点树重组必须使用独立审批任务。

## 七、文件范围

### 允许修改的现有文件

| 路径 | 修改原因 | 所有者 | 是否共享文件 |
|---|---|---|---|

### 允许新增的文件

| 路径 | 职责 | 调用方 |
|---|---|---|

### 禁止修改的系统

- 与 `TASK_MANIFEST.json` 完全一致。

超出允许范围时停止并生成新规格版本，不自行扩大任务。

## 八、分步实现

### Step 1：一个可独立验证的行为

**目标行为**：写明输入、状态转换、输出和失败行为。

**核心概念**：只讲一个本步新增概念，并按“是什么、Godot 中在哪里、为什么需要、与相近概念的区别、误用时的可观察失败”解释。

**涉及文件**：列出精确路径。

**AI 实现内容**：说明 AI 将完成的设计、代码、测试和文档。

**学生参与点**：说明本步对应哪个检查点、学生要打开哪里、观察什么、做出什么选择或解释。

**设计选择**：最多给两个方案，推荐一个并说明取舍。

**自动验证**：命令、预期退出码和关键断言。

**Godot 检查**：使用 `"$GODOT_BIN"` 的命令或精确编辑器导航、可观察结果和错误日志要求。

**验证含义**：说明每项检查证明什么、没有证明什么。

**记录要求**：更新 TASK_STATE、LEARNING_STATE、LEARNING_RECORD、实施报告和验证报告中的具体字段；暂停时写明当前 Step/检查点、已完成结果、下一项学生操作和精确打开位置。

**通过条件**：可判定条件。

**下一步**：`teaching` 模式在本步的意义检查点停止；不是每个函数或文件都停止。

### Step 2...Step N

保持相同结构。每一步建立在已验证合同上，并且只增加一个主要新概念。

## 九、完整验证

### 工程与配置

- GDScript 解析、资源路径、UID、节点路径、信号、Autoload、稳定 ID 和配置校验。

### 自动化与 Godot 4.7

- 纯逻辑测试、测试场景或 headless 检查。
- 只有 `--version` 显示 4.7.x 才能认证 Godot 4.7 结果。
- 必需检查无法执行时，交付状态设为 `verification_blocked`。

### 场景生命周期

- 首次加载、退出、卸载、重入、快速重复切换、节点释放、信号连接数量和动画目标。

### Git 范围

- 使用 `check_task_scope.py check` 检查提交、暂存、未暂存、未跟踪文件和实现前已有脏文件。

### 学习证据

- 检查三类必需参与结果，但允许功能完成而学习状态仍为 `participation_pending`。
- 只记录学生真实完成的定位、编辑器操作、解释、验证或诊断。

### 集成交接

- `INTEGRATION_HANDOFF.md` 与实际接口一致。
- 在最新集成基线上重跑必需集成检查。

## 十、停止条件

- 需要修改范围外文件或其他学生所有权范围。
- 公开接口、Autoload、存档、事件总线、主场景或共享配置发生未登记变更。
- 任务规格、行为合同或场景生命周期与现实冲突。
- Godot 版本不符却需要认证 4.7 行为。
- 发现未登记的跨场景 NodePath、动画轨道或信号连接。
- 实际范围明显超过估计或需要新的架构层。

记录证据，更新状态，并停止；不得以临时兼容代码绕过。

## 十一、完成与交接定义

- 所有批准的行为条件有证据。
- 配置与 Godot 4.7 必需检查通过。
- 缺失必需检查时使用 `verification_blocked`，不得写“完成”。
- 代码审查无未解决的范围内 P0/P1/P2。
- 最终差异只包含允许文件和实现前已登记且未被改变的脏文件。
- `LEARNING_STATE.json` 不夸大学生参与。
- `INTEGRATION_HANDOFF.md` 写明入口、输入、输出、依赖、关键文件、接入方法、禁止访问、验证和限制。
- 功能完成、学习完成和集成完成使用独立状态。

## 十二、审批

任何能明确表达“同意 TASK-NNN vN 进入开发”的用户文本都有效。记录原文、时间和规格版本。建议表达：`确认 TASK-NNN vN 进入开发`。

范围改变后生成 vN+1，旧审批设为 `superseded`。
```

## Writing rules

- Use exact project paths, node names, signal names, configuration columns, and commands.
- Separate observed facts, assumptions, decisions, and unknowns.
- Order Steps by dependency and observable behavior, not by file type.
- Do not require whole-script reading from beginners.
- Do not use vague acceptance criteria such as “运行正常”.
- Do not imply that another agent has hidden context.
- Use `当前工程`, `现有系统`, `项目内配置`, `行为对照`, and `行为对照工程` when context is needed.
