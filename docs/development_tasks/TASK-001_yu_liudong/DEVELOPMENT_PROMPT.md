# TASK-001: 玩家鱼跟随手指游动

> 引擎：Godot 4.7
> 开发策略：plan_driven
> 参与模式：guided_co_development
> 执行模式：teaching
> 任务规格版本：v3
> 审批状态：awaiting
> 交付状态：proposed
> Git 基线：d2bd9e47e8743d9d9ad5aaec322f8c52ec7231ad

## 一、任务目标

全新项目（见 `docs/PROJECT_STATUS_AUDIT.md`）尚无任何场景。本任务建立游戏的首批场景与完整玩家移动行为链，为后续所有系统奠定入口。

### 完成后可观察结果

- F5 运行直接进入游戏（无主场景选择框）：海床背景上有一条蓝色玩家鱼
- 按住屏幕拖动（PC 上按住鼠标）：鱼朝手指位置平滑游动，不瞬移
- 松开：鱼游到最后的目标位置后停下
- 检查器把 `yidong_sudu` 从 300 改成 100 后重跑：鱼明显变慢
- 左右往返拖动：鱼头始终朝前进方向（水平翻转）

### 本任务不做

- 鱼群生成（TASK-002）、碰撞与大小判定（TASK-003）、鱼种数据表（TASK-004）、
  经验成长（TASK-005）、升级 UI（TASK-006）、动画特效（第 7 课）、测试（第 9 课）
- 不加物理身体（Area2D 等属判定课）、不加 Autoload、信号、存档

## 二、当前工程状态

### 已实现并验证

- Git 仓库干净：基线 `d2bd9e4`（`git status` 为空）
- `project.godot` 可解析：4.7 / Mobile 渲染、1280×720 横屏、`emulate_touch_from_mouse=true`
- 素材已导入：`assets/sucai/kenney_fish/PNG/Default/`（.import 就位），本任务用
  `fish_blue.png`（玩家鱼）与 `background_terrain.png`（海床背景）

### 已存在但未验证或未接通

- 无场景、无脚本、无数据、无测试——全部待本任务及后续任务建立

### 审计新鲜度

- audited_commit：d2bd9e47e8743d9d9ad5aaec322f8c52ec7231ad
- environment_checked_at：2026-10-21T02:25:00Z
- engine_executable_source：common_path（`D:\001\Godot_v4.7.2-stable_win64.exe`）
- engine_version_detected：4.7.2（4.7.2.stable.official.ed1daf0bf）
- audit_invalidation_triggers：project.godot 结构性修改、引擎版本变化、共享配置/存档/事件总线变更、基线 commit 变化后未重审

### 当前依赖与阻塞

- 无依赖任务、无已知阻塞

## 三、功能所有权与团队集成

### 功能所有者

- owner_id：student-01
- owned_systems：玩家鱼移动（输入目标点 → 朝目标游动）
- owned_scenes：`res://scenes/Main.tscn`、`res://scenes/Yu.tscn`
- owned_scripts：`res://scripts/main.gd`、`res://scripts/yu.gd`
- owned_config_tables：无

### 集成合同

| 类型 | 名称/路径 | 提供方 | 使用方 | 合同 | 变更风险 |
|---|---|---|---|---|---|
| 属性 | `Yu.mubiao_dian: Vector2` | yu.gd | main.gd（写入） | 游动目标点，世界坐标 | 后续任务若改读写方需升版本 |
| 属性 | `Yu.yidong_sudu: float`(@export) | yu.gd | 检查器/后续成长系统 | 移动速度，像素/秒 | 同上 |

- 依赖任务：无；发出信号：无；接收信号：无；共享状态：无
- **登记的共享变更**：`project.godot` 仅新增 `run/main_scene = res://scenes/Main.tscn`，其他配置一律不动。未登记即禁止修改。

### 禁止的跨功能访问

- 本任务不涉及其他功能系统。Main 通过实例引用直接设置 `yu.mubiao_dian`（owner→owned 直接调用），禁止绕过该属性直接操控 Yu 内部 Sprite2D

## 四、学生参与与学习目标

### 学习目标

- 学生能够**定位** Main.tscn / Yu.tscn / yu.gd / main.gd 四个文件并说出各自职责
- 学生能够**解释**「输入由 Main 接收、目标点写入 Yu 公开属性、Yu 自己移动」的分工及理由（Yu 保持可复用蓝图）
- 学生能够**检查**编辑器中的节点树与 @export 属性，并**应用**参数修改观察行为差异
- 学生能够**验证** F5 行为链并说出本功能的输入、输出、入口和一处故障排查位置

### 三个必需检查点

1. **orientation（step-01 实现前）**：确认任务目的、四个目标文件位置、核心概念「InputEvent 事件对象」，完成一个二选一设计决策（见 Step 3）
2. **godot-inspection（step-03 实现后）**：按精确路径在编辑器检查 Yu.tscn 节点树、@export 属性与 main.gd 的输入处理代码
3. **verification-handoff（step-04 完成后）**：F5 亲测四条行为 + 改速度重跑 + 口头交接（入口/输入/输出/依赖/排查位置）

### 参与边界

| 工作项 | AI 主导内容 | 学生参与内容 | 客观证据 |
|---|---|---|---|
| 场景搭建 | 建两个 .tscn 与两个 .gd | 检查节点树与 Script 面板 | editor_operation / scene_tree_inspection |
| 移动逻辑 | yu.gd 全部代码 | 解释分工、改 yidong_sudu 观察 | concept_explanation / parameter_adjustment |
| 输入处理 | main.gd 全部代码 | 阅读输入段、复述事件流向 | project_navigation |
| 验证 | 跑无头导入检查 | F5 四条行为亲测、说结论 | test_execution / result_interpretation |

### 防卡住与恢复规则

- 学生第一次说不会：AI 立即演示最小完整步骤，再让学生复述原理或检查一个命名结果；仍不会则 AI 说出正确观察、记 unresolved_concepts、**继续推进**
- AI 演示最多记 `introduced`；recognized 及以上须学生实际表现
- 编辑器暂不可用时改查 .tscn 文本/脚本/日志，如实记录证据类型
- 每次暂停写全 TASK_STATE（当前 Step/检查点/结果/下一动作/精确打开位置），恢复只看状态文件

## 五、行为合同与数据流

### 行为合同

- 前置条件：Main 为运行主场景；`emulate_touch_from_mouse=true`（已配置）
- 输入：InputEventScreenTouch（pressed/released）、InputEventScreenMotion（按住期间）
- 状态转换：无按住 → 目标点 = 鱼当前位置；按住 → 目标点持续 = 手指世界坐标；松手 → 目标点冻结于最后位置
- 输出：鱼位置每帧朝目标点前进 `yidong_sudu * delta` 像素；距离 < 5px 停止；朝向按移动方向水平翻转
- 失败、取消与重试：输入被 UI 消耗时 _unhandled_input 不触发（本任务无 UI，不适用；第 6 课卡片 UI 会依赖此机制）
- 边界情况：手指不动时鱼到达目标点即停；快速往返拖动时目标点连续更新不累积瞬移

### 数据流

    手指/鼠标按下拖动（硬件）
      -> InputEventScreenTouch / ScreenMotion（引擎打包为事件）
      -> Main._unhandled_input（解析：event.pressed / event.position）
      -> 屏幕坐标转世界坐标（get_global_transform / 本任务即恒等）
      -> yu.mubiao_dian = 世界坐标（Main 写入公开属性）
      -> Yu._process：move_toward(当前位置, 目标点, 速度*delta)（Yu 读自己的属性）
      -> 屏幕上鱼移动（视图结果）

数据所有者：目标点归 Main 瞬时写入、Yu 持有；移动规则全部在 yu.gd 内，节点不是状态容器。

## 六、场景节点树与加载

### 架构影响

- architecture_change：false
- entry_scene：res://scenes/Main.tscn（本任务建立，登记入 project.godot）
- lifecycle_rationale：新项目首个运行场景，无既有生命周期受影响；Yu 随 Main 进入树创建、退出释放

目标节点树：

```text
Main (Node2D)          <- scripts/main.gd，接收输入、协调
├─ Haodi (Sprite2D)    <- 海床背景，background_terrain.png，居中
└─ Yu (Yu.tscn 实例)   <- scripts/yu.gd，玩家鱼蓝图
   └─ Sprite2D         <- fish_blue.png，挂 flip_h 翻转
```

加载策略：主场景由引擎直接加载；Yu 由 Main 场景文件内静态实例化（组合优先）。无运行时动态加载、无对象池、无信号连接。

## 七、文件范围

### 允许修改的现有文件

| 路径 | 修改原因 | 所有者 | 是否共享文件 |
|---|---|---|---|
| project.godot | 新增 run/main_scene | TASK-001 | 是（已登记） |
| docs/development_tasks/TASK-001_yu_liudong/TASK_STATE.json | 执行状态 | 工作流 | 否 |
| docs/development_tasks/TASK-001_yu_liudong/LEARNING_STATE.json | 学习状态 | 工作流 | 否 |
| docs/development_tasks/TASK-001_yu_liudong/LEARNING_RECORD.md | 学习记录 | 工作流 | 否 |
| docs/development_tasks/TASK-001_yu_liudong/INTEGRATION_HANDOFF.md | 交接文档 | 工作流 | 否 |
| docs/引擎词总表.md | 收录本课新词（项目惯例） | 全课程共享 | 是（仅追加） |
| LEARNING_ROADMAP.md | 打勾第 1 课（项目惯例） | 全课程共享 | 是（仅进度行） |
| docs/TASK_INDEX.md | 任务状态列（项目惯例） | 工作流 | 是（仅本任务行） |

### 允许新增的文件

| 路径 | 职责 | 调用方 |
|---|---|---|
| scenes/Yu.tscn | 玩家鱼蓝图 | Main.tscn 实例化 |
| scenes/Main.tscn | 主场景/协调者 | 引擎主场景 |
| scripts/yu.gd | 移动规则 | Yu.tscn |
| scripts/main.gd | 输入接收与协调 | Main.tscn |
| scripts/yu.gd.uid | Godot 自动生成的脚本 UID 元数据（v2 新增登记） | 引擎 |
| scripts/main.gd.uid | Godot 自动生成的脚本 UID 元数据（v2 新增登记） | 引擎 |
| docs/development_tasks/TASK-001_yu_liudong/IMPLEMENTATION_REPORT.md | 实施报告 | 工作流 |
| docs/development_tasks/TASK-001_yu_liudong/VERIFICATION_REPORT.md | 验证报告 | 工作流 |
| docs/development_tasks/TASK-001_yu_liudong/CODE_REVIEW.md | 评审报告 | 工作流 |

### 禁止修改的系统

- data/、tests/、鱼群生成、碰撞判定、经验成长、任何 Autoload——与 TASK_MANIFEST.json 一致

超出允许范围时停止并生成 v2，不自行扩大。

## 八、分步实现

### Step 1：搭建 Yu（玩家鱼）场景蓝图

**目标行为**：Yu.tscn 存在且 F6 单独运行可见鱼；检查器可见 `yidong_sudu=300`。

**核心概念**：场景即蓝图（复习深化）。是什么：.tscn 保存的节点树模板；Godot 中哪里：FileSystem 面板的场景文件；为什么需要：后续鱼群、食物全靠同款蓝图模式复用；与相近概念区别：蓝图是模板、实例是运行时实体（instantiate 三步曲）；误用失败表现：直接在 Main 里搭一条鱼不存成场景，第 2 课鱼群将无法批量生成。

**涉及文件**：scenes/Yu.tscn、scripts/yu.gd

**AI 实现内容**：建场景、挂贴图（fish_blue.png，缩放 1.0，位于原点）、写 yu.gd 框架（class_name 不用；@export var yidong_sudu := 300.0 # move speed；var mubiao_dian: Vector2）。

**学生参与点**：orientation 检查点——打开项目定位 scenes/、scripts/ 目录与目标文件名。

**设计选择**：无（本步纯搭建）。

**自动验证**：`"$GODOT_BIN" --headless --path . --import` 退出码 0。

**Godot 检查**：编辑器 FileSystem → scenes → Yu.tscn 双击，Scene 面板确认 `Yu(Node2D) → Sprite2D`；选中根节点 Inspector → Script 可见 `Yidong Sudu = 300`。

**验证含义**：导入通过 = 语法与资源路径有效；不证明运行时行为（行为靠 Step 4 与手动检查）。

**记录要求**：TASK_STATE.step_state 追加 step-01；LEARNING_STATE 记录导航证据。

**通过条件**：上述 Godot 检查全部可观察成立。

**下一步**：Step 2（不停顿，orientation 检查点已在实现前完成）。

### Step 2：建立 Main 主场景并登记入口

**目标行为**：F5 不弹主场景选择框，直接见背景与鱼。

**核心概念**：主场景（run/main_scene）。是什么：project.godot 里登记的运行入口场景；Godot 中哪里：Project Settings → Application → Run → Main Scene；为什么需要：F5 的运行起点，Android 导出后也是它先加载；与相近概念区别：主场景是「启动哪个」，当前场景（Current Scene）是「此刻哪个」（change_scene_to_file 换的后者，第 8 课用）；误用失败表现：不设置则每次 F5 弹选择框、导出的 APK 无法启动游戏。

**涉及文件**：scenes/Main.tscn、scripts/main.gd、project.godot

**AI 实现内容**：Main.tscn（Node2D 根 + Haodi 背景精灵居中 + 实例化 Yu）+ main.gd 框架 + project.godot 登记主场景。

**学生参与点**：无独立停顿（orientation 已完成）。

**设计选择**：无。

**自动验证**：导入退出码 0；`grep run/main_scene project.godot` 值为 `res://scenes/Main.tscn`。

**Godot 检查**：F5 直接进入游戏画面（海床 + 蓝）。

**验证含义**：证明入口登记与组合有效；不证明输入与移动。

**记录要求**：step_state 追加 step-02。

**通过条件**：F5 无选择框且两元素可见。

**下一步**：Step 3。

### Step 3：按住检测：Main 接收触摸并写入目标点

**目标行为**：按住拖动时 Output 面板目标点坐标持续更新；松手后停止更新（此步鱼尚不动）。

**核心概念**：InputEvent 事件对象与 _unhandled_input（本课新词）。是什么：引擎把每个输入动作打包成 InputEvent 子类对象（ScreenTouch/ScreenMotion/MouseButton…）沿场景树传递；Godot 中哪里：Node._unhandled_input(event) 回调、Input Map；为什么需要：跟随手指需要「按住+移动+松开」三种事件，与捡金币「按键查询 Input.is_action_pressed」是两种输入路数；与相近概念区别：Input 单例是主动查询（每帧问），_unhandled_input 是被动接收（事件来了才叫你）；误用失败表现：忘记判断 `event.pressed` 会把松手也当按住，鱼一直追着最后一次触摸跑。

**涉及文件**：scripts/main.gd、scripts/yu.gd

**AI 实现内容**：main.gd 的 `_unhandled_input(event)` 分支处理 ScreenTouch（pressed → 更新目标）、ScreenMotion（按住期间 → 更新目标）；`yu.mubiao_dian = event.position`（本场景无相机变换，屏幕坐标即世界坐标）；调试 print 目标点（Step 4 验证后可留可删——留，第 2 课前清理）。

**学生参与点**：无独立停顿（为 inspection 检查点蓄力）。

**设计选择**（orientation 检查点决策，二选一，推荐 A）：
- **A. Main 接收输入、写入 Yu 公开属性（推荐）**：Main 是协调者，Yu 不关心输入来自手指还是手柄，保持纯「朝目标游」的复用蓝图；第 6 课 UI 卡片出现时输入天然统一在 Main 层
- B. Yu 自己监听 _unhandled_input：少一层传递更简单，但 Yu 从此绑死触摸输入，复用性差

**自动验证**：导入退出码 0。

**Godot 检查**：F5 后按住拖动，Output 面板坐标随指针更新，松手即停。

**验证含义**：证明事件流贯通；不证明移动（下一课切片）。

**记录要求**：step_state 追加 step-03；**在此停：godot-inspection 检查点**（学生打开 scripts/main.gd 找到 _unhandled_input，说出 ScreenTouch 和 ScreenMotion 各自负责什么；打开 Yu.tscn 检查器确认 mubiao_dian 不是 @export——它是代码写入的内部目标，学生能说出为什么）。

**通过条件**：调试输出按预期更新 + 检查点完成。

**下一步**：Step 4。

### Step 4：平滑游动：Yu 每帧朝目标点游

**目标行为**：完整行为链可玩（按住→跟随→松手→停止）；改速度可见差异；flip_h 生效。

**核心概念**：move_toward + delta（复习深化）。是什么：`位置.move_toward(目标, 速度 * delta)` 每帧逼近；Godot 中哪里：Node2D.position（Vector2 API）；为什么需要：跟随手指要平滑逼近而非瞬移，且不同帧率下手速一致；与相近概念区别：`position = 目标` 是瞬移（捡金币第 1 课负速度实验的亲戚），move_toward 是限速逼近；误用失败表现：漏乘 delta 则高帧率机器上鱼飞快（捡金币课已见过同类）。

**涉及文件**：scripts/yu.gd

**AI 实现内容**：_process(delta) 中 move_toward + 距离阈值停止（<5px）+ 按水平速度方向设 flip_h。

**学生参与点**：verification-handoff 检查点——F5 亲测四条行为；检查器把 yidong_sudu 改 100 重跑观察；口头交接。

**设计选择**：无。

**自动验证**：导入退出码 0；`check_task_scope.py check` 无违例。

**Godot 检查**：手动检查四条（按住跟随/松手停止/变慢/翻转）。

**验证含义**：行为链成立 = 本任务目标达成；未覆盖物理碰撞（后续任务）。

**记录要求**：step_state 追加 step-04；更新三个报告与交接文档；LEARNING_ROADMAP 打勾。

**通过条件**：四条手动检查全部成立。

**下一步**：FINAL_VERIFY → CODE_REVIEW → 交接。

## 九、完整验证

### 工程与配置

- 导入退出码 0（脚本解析、资源路径有效）
- project.godot 仅新增 run/main_scene 一行（git diff 确认）

### 自动化与 Godot 4.7

- `"$GODOT_BIN" --version` = 4.7.2 认证
- 每步导入检查 + 最终导入检查

### 场景生命周期

- F5 首次加载一个 Main 实例；F5 重跑无残留节点、无重复输出；退出无报错

### Git 范围

- `check_task_scope.py check`：已提交/暂存/未暂存/未跟踪全部对照白名单，无违例

### 学习证据

- 三类必需参与结果检查（允许 learning_status 停在 participation_pending）

### 集成交接

- INTEGRATION_HANDOFF.md 与实际接口一致后置 ready

## 十、停止条件

- 需要改范围外文件或系统（Autoload、信号、data/、tests/ 等）
- run/main_scene 之外的 project.godot 配置需要变更
- 场景树与本清单不符（如 Yu 出现物理节点）
- 4.7 认证失效或导入检查无法运行（→ verification_blocked）

## 十一、完成与交接定义

- 四条手动行为检查 + 导入 + 范围检查全部通过
- 评审无未解决范围内 P0/P1/P2
- LEARNING_STATE 不夸大参与；INTEGRATION_HANDOFF 十节写全实际接口
- 功能完成、学习完成、集成完成独立上报（学习可留 participation_pending）

## 十二、审批

任何明确表达「同意 TASK-001 v1 进入开发」的用户文本均有效，记录原文、时间和规格版本。建议表达：`确认 TASK-001 v1 进入开发`。范围改变后生成 v2，旧审批设为 superseded。
