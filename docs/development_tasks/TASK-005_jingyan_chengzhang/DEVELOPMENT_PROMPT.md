# TASK-005: 经验与成长（Autoload 账本 + bei_chi 记账 + 玩家长大 + 经验条 UI）

> 引擎：Godot 4.7
> 开发策略：plan_driven
> 参与模式：guided_co_development
> 执行模式：teaching
> 任务规格版本：v1
> 审批状态：awaiting
> 交付状态：proposed
> Git 基线：4ca0582b5d9f4832fca67b9c57d8c477ea2e5397

## 一、任务目标

新建 **Autoload 全局账本 ZhangBen**，在 `bei_chi()` 入口记账（消费第 4 课存的 `fenzhi`），升级时发信号、玩家鱼长大（`tixing` 增大、判定圈随 scale 白送变大），主场景加经验条 UI。完成后：吃鱼涨条 → 攒够升级 → 玩家变大 → 能吃的鱼变多——肉鸽成长循环第一环转动。

### 完成后可观察结果

- F5：吃鱼经验条按 fenzhi 增长（蓝鱼 +1、棕鱼 +5）
- 攒够升级：玩家瞬间变大、判定圈变大、原来吃不掉的鱼变得能吃、经验条清零重计、Lv +1
- 完整回归：移动/生成/回收/判定/闪红无敌全部无退化

### 本任务不做

- 升级三选一弹窗与暂停（TASK-006）——升级暂只长大
- 血量/死亡/结算（TASK-008）；平滑成长动画（Tween，第 7 课）
- 升级阈值 .tres 数据化（与第 6 课强化卡一起做）；账本重置（第 8 课配套）

## 二、当前工程状态

### 已实现并验证（TASK-001~004）

- 玩家移动、鱼群数据驱动生成（6 种鱼 .tres）、大吃小判定 + 无敌
- **三个挂钩点已挖好等待会师**：`bei_chi()` 入口（第 3 课预告）、`Yu.tixing`（第 3 课埋接口，只读未写）、`YuZhong.fenzhi`（第 4 课存数据无消费者）

### 审计新鲜度

- audited_commit：4ca0582b5d9f4832fca67b9c57d8c477ea2e5397（工作区干净）
- environment_checked_at：2026-10-23T00:30:00Z
- engine_executable_source：common_path（`D:\001\Godot_v4.7.2-stable_win64.exe`）
- engine_version_detected：4.7.2

### 当前依赖与阻塞

- 依赖 TASK-003（bei_chi/tixing/判定圈缩放）、TASK-004（fenzhi/yu_zhong）；无阻塞
- **本课将做本项目首个 project.godot 结构性修改**（注册 Autoload），已登记 shared change

## 三、功能所有权与团队集成

### 功能所有者

- owner_id：student-01
- 新建：`scripts/zhang_ben.gd`、`scripts/jing_yan_ui.gd`
- 修改 4 文件：`project.godot`（Autoload 注册）、`yu_npc.gd`（bei_chi 加一行）、`yu.gd`（听信号长大）、`Main.tscn`（经验条 UI）
- **零修改**：`yu_qun.gd`、`yu_zhong.gd`、`main.gd`、`Yu.tscn`、`YuNpc.tscn`

### 集成合同

| 类型 | 名称 | 提供方 | 使用方 | 合同 |
|---|---|---|---|---|
| 单例 | `ZhangBen`（Autoload） | zhang_ben.gd | 全项目任意脚本 | 按名直呼；jing_yan/deng_ji 唯一所有者 |
| 方法 | `ZhangBen.jia_jing_yan(fen)` | 账本 | bei_chi() | 唯一记账入口；判空由调用方做 |
| 信号 | `jing_yan_bian_hua(jing_yan, yuzhi)` | 账本 | jing_yan_ui | 进度条刷新 |
| 信号 | `sheng_ji(xin_deng_ji)` | 账本 | yu.gd（TASK-006 再连） | 升级广播：长大/弹窗各自连接 |
| 共享变更 | project.godot `[autoload]` += ZhangBen | 本任务 | 全项目 | 首个 Autoload，审计确认无冲突 |

- **禁止**：经验/等级的写入出现在账本之外的任何位置（唯一所有者）
- **禁止**：修改 yu_qun.gd / yu_zhong.gd / main.gd / Yu.tscn / YuNpc.tscn

## 四、学生参与与学习目标

### 学习目标

1. 定位三个挂钩点，说出本课如何让它们会师（数据流闭环）
2. 解释 Autoload：为什么账本要全局单例而不是 Main 的子节点（跨场景存活、先于场景就绪）
3. 跟踪记账数据流：bei_chi → jia_jing_yan(fenzhi) → 升级 → sheng_ji → 玩家长大 + UI 刷新
4. 编辑器查看 Autoload 注册与远程场景树 ZhangBen 节点、阈值调参实验后还原

### 检查点安排

| 检查点 | 时机 | 学生动作 | 证据类型 |
|---|---|---|---|
| orientation | step-01 前 | 定位三个挂钩点 + "全局单例 vs 场景节点"概念确认 + 两个设计决策 | project_navigation, concept_explanation |
| godot-inspection | step-02 后 | 项目设置看 Autoload、远程树看 ZhangBen 数值增长、改阈值实验后还原 | editor_operation, configuration_inspection |
| verification-handoff | step-04 后 | F5 亲测四条：涨条/升级长大/判定圈变大/全量回归 | result_interpretation, test_execution |

## 五、文件级实现规格

### 5.1 scripts/zhang_ben.gd（新建：Autoload 账本）

```gdscript
extends Node
# 游戏账本（Autoload 全局单例）：经验与等级的唯一所有者
# 先于一切场景就绪、切场景不销毁；任意脚本直接按名访问 ZhangBen

signal jing_yan_bian_hua(jing_yan: int, yuzhi: int)  # 经验变动：UI 刷新进度条
signal sheng_ji(xin_deng_ji: int)                    # 升级：玩家长大、（第 6 课）弹三选一

const SHENG_JI_YUZHI := [8, 20, 35, 55, 80, 110]  # 每级所需经验（第 6 课数据化）
const MEI_JI_TIXING := 0.2  # 每级体型增幅（只给玩家读）

var jing_yan := 0  # 当前经验（本级的，升级时扣掉已用部分）
var deng_ji := 1   # 当前等级


func jia_jing_yan(fen: int) -> void:
	# 唯一记账入口：吃鱼经验都从这进账
	jing_yan += fen
	var yuzhi := dangqian_yuzhi()
	if jing_yan >= yuzhi:
		jing_yan -= yuzhi
		deng_ji += 1
		sheng_ji.emit(deng_ji)
	jing_yan_bian_hua.emit(jing_yan, dangqian_yuzhi())


func dangqian_yuzhi() -> int:
	# 满级后封顶：经验条停在最后一级阈值
	if deng_ji > SHENG_JI_YUZHI.size():
		return SHENG_JI_YUZHI[-1]
	return SHENG_JI_YUZHI[deng_ji - 1]
```

project.godot 追加：

```ini
[autoload]
ZhangBen="*res://scripts/zhang_ben.gd"
```

### 5.2 scripts/yu_npc.gd（修改：bei_chi 加一行）

```gdscript
func bei_chi() -> void:
	# 被玩家吃掉的统一入口：先记账再释放（第 3 课挖好的挂钩点在此兑现）
	if yu_zhong != null:
		ZhangBen.jia_jing_yan(yu_zhong.fenzhi)  # 吃兜底鱼不给经验
	queue_free()
```

### 5.3 scripts/yu.gd（修改：听升级信号长大）

```gdscript
# _ready 内追加（其余连接照旧）：
	ZhangBen.sheng_ji.connect(_on_sheng_ji)

func _on_sheng_ji(xin_deng_ji: int) -> void:
	# 升级长大：tixing 增大，判定圈随根节点 scale 自动变大（第 3 课验证过的机制）
	tixing += ZhangBen.MEI_JI_TIXING
	scale = Vector2.ONE * tixing
```

### 5.4 scenes/Main.tscn + scripts/jing_yan_ui.gd（新建：经验条 UI）

Main 追加子树：

```
JingYanTiao (CanvasLayer, 挂 jing_yan_ui.gd)
├─ JingYanTiaoBg (ProgressBar)   position≈(340, 24)，size 600×20
└─ DengJiLabel (Label, "Lv.1")   position≈(250, 18)
```

```gdscript
extends CanvasLayer
# 经验条 UI：只管听账本信号刷新显示，不存任何状态

@onready var jindutiao: ProgressBar = $JingYanTiaoBg
@onready var dengji_label: Label = $DengJiLabel

func _ready() -> void:
	# 初始显示 + 连接账本两个信号（各一次）
	_shuaxin(ZhangBen.jing_yan, ZhangBen.dangqian_yuzhi(), ZhangBen.deng_ji)
	ZhangBen.jing_yan_bian_hua.connect(_on_jing_yan_bian_hua)
	ZhangBen.sheng_ji.connect(_on_sheng_ji)

func _on_jing_yan_bian_hua(jing_yan: int, yuzhi: int) -> void:
	jindutiao.max_value = yuzhi
	jindutiao.value = jing_yan

func _on_sheng_ji(xin_deng_ji: int) -> void:
	dengji_label.text = "Lv.%d" % xin_deng_ji

func _shuaxin(jing_yan: int, yuzhi: int, deng_ji: int) -> void:
	jindutiao.max_value = yuzhi
	jindutiao.value = jing_yan
	dengji_label.text = "Lv.%d" % deng_ji
```

## 六、分步实现顺序

1. **step-01**：zhang_ben.gd + Autoload 注册（纯新增，零行为变化，远程树可见 ZhangBen）
2. **step-02**：bei_chi() 记账（账本暗涨，远程树可核对数值）
3. **step-03**：玩家听 sheng_ji 长大（升级瞬间肉眼变大）
4. **step-04**：经验条 UI（涨条/清零/Lv 跳变可见）

每步跑 `--headless --import` + `--fixed-fps 60 --quit-after 360`。

## 七、验证计划

### 自动化

- `"$GODOT_BIN" --version` 输出 4.7.x
- `"$GODOT_BIN" --headless --path . --import` 退出码 0（每步）
- `"$GODOT_BIN" --headless --path . --fixed-fps 60 --quit-after 360` 退出码 0
- `PYTHONUTF8=1 python .../check_task_scope.py check docs/development_tasks/TASK-005_jingyan_chengzhang` 无违例

### 手动（学生主导）

- 吃鱼涨条（蓝 +1、棕 +5 可区分）；升级瞬间玩家变大 + 条清零 + Lv +1
- 升级后判定圈变大：原来吃不掉的鱼现在能吃
- 全量回归：移动/生成/回收/判定/无敌

## 八、故障排查提示

| 现象 | 优先检查 |
|---|---|
| 脚本报错 ZhangBen not found | project.godot 的 [autoload] 段是否写入、名称拼写是否一致；改后需重启 F5 |
| 吃鱼不涨经验 | bei_chi() 里判空分支是否把正常鱼也挡了（yu_zhong 应为非空——检查注册表是否清空） |
| 升级不长大 | sheng_ji 信号连接是否写在 _ready；连接与 emit 的参数个数是否一致 |
| 经验条不刷新 | jing_yan_bian_hua 连接；ProgressBar 的 max_value 是否为 0（yuzhi 没传对） |
| 升级后无敌/闪红异常 | 是 scale 连带缩放了 WudiDingshi？（Timer 无形体，不受影响）——检查是否误改了别的节点 |

## 九、范围边界

- 白名单以 `TASK_MANIFEST.json` 为准；未登记文件一律不改
- **project.godot 只允许 Autoload 一处修改**（其他段落零碰）
- 新增生产文件：zhang_ben.gd、jing_yan_ui.gd（各 + .uid）；修改 4 个生产文件 + 文档

## 十、审批

等待用户明确回复「确认 TASK-005 v1 进入开发」后：捕获实现基线 → orientation 检查点 → 开始 step-01。
