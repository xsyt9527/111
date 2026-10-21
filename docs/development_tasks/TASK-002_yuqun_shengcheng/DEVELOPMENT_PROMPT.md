# TASK-002: 鱼群生成与屏幕外回收

> 引擎：Godot 4.7
> 开发策略：plan_driven
> 参与模式：guided_co_development
> 执行模式：teaching
> 任务规格版本：v1
> 审批状态：awaiting
> 交付状态：proposed
> Git 基线：fa2f75add18699e3b5ddb7243ed3f52016c38fc4

## 一、任务目标

在 TASK-001 的 Main 场景中加入持续运转的鱼群：NPC 鱼从屏幕两侧边缘外游入，外观、体型、速度随机，横穿屏幕后自动释放；同屏数量受上限保护。玩家鱼与鱼群本课相互穿过（碰撞属 TASK-003）。

### 完成后可观察结果

- F5 后约 1 秒出现第一条 NPC 鱼，之后以不均匀间隔持续出现
- 每条鱼从左侧或右侧屏幕外进入，颜色、大小、速度、高度各不相同，鱼头朝前进方向
- 鱼游出对面边缘后从场景树消失，Remote 面板中数量稳定在 `zuida_shuliang` 内
- 检查器可调生成间隔、上限、速度范围，重跑立即生效
- TASK-001 回归：玩家鱼仍可按住拖动跟随手指

### 本任务不做

- 碰撞/吃鱼/大小判定（TASK-003）、鱼种 .tres 数据表（TASK-004）、经验成长（TASK-005）、升级 UI（TASK-006）
- 对象池、Tween/动画、粒子、音效、Autoload、project.godot 修改

## 二、当前工程状态

### 已实现并验证（TASK-001）

- `scenes/Main.tscn`：Main(Node2D) → Haodi(Sprite2D 海床背景) + Yu 实例
- `scenes/Yu.tscn`：Yu(Node2D) → Sprite2D(fish_blue.png)
- `scripts/main.gd`：`_unhandled_input` 接收 ScreenTouch/ScreenDrag，写入 `yu.mubiao_dian`
- `scripts/yu.gd`：`_process` 用 move_toward + delta 朝目标点游动，`flip_h` 朝向
- 主场景已登记；`emulate_touch_from_mouse=true`
- 遗留：`main.gd::_gengxin_mubiao` 中的调试 `print` 需在本任务删除

### 已存在但未接通

- Kenney 鱼贴图（fish_blue / red / green / orange / brown / pink / grey 等）已导入，未用于 NPC

### 审计新鲜度

- audited_commit：fa2f75add18699e3b5ddb7243ed3f52016c38fc4
- environment_checked_at：2026-10-21T08:48:42Z
- engine_executable_source：common_path（`D:\001\Godot_v4.7.2-stable_win64.exe`）
- engine_version_detected：4.7.2（4.7.2.stable.official.ed1daf0bf）

### 当前依赖与阻塞

- 依赖 TASK-001（已完成）；无已知阻塞

## 三、功能所有权与团队集成

### 功能所有者

- owner_id：student-01
- owned_systems：NPC 鱼蓝图、鱼群生成器
- owned_scenes：`res://scenes/YuNpc.tscn`
- owned_scripts：`res://scripts/yu_npc.gd`、`res://scripts/yu_qun.gd`

### 集成合同

| 类型 | 名称/路径 | 提供方 | 使用方 | 合同 |
|---|---|---|---|---|
| 属性 | `YuNpc.tixing: float` | yu_npc.gd | TASK-003 大小判定 | 运行时体型系数 0.6~1.6，决定 scale |
| 属性 | `YuNpc.sudu / fangxiang` | yu_npc.gd | yu_qun.gd（add_child 前写入） | 游速像素/秒；1 向右、-1 向左 |
| 参数 | `YuQun.zuixiao_jiange / zuida_jiange / zuida_shuliang / sudu_fanwei` | yu_qun.gd(@export) | 检查器/后续难度调参 | 全部可在检查器调整 |
| 场景 | `Main.tscn → YuQun` | TASK-002 | Main 所有 | 只追加子树，不改既有节点 |

- 依赖任务：TASK-001
- 接收信号：`Dingshi.timeout`（YuQun._ready 内部 connect）
- 共享状态：无；**登记的共享变更：无**（project.godot 不动）

### 禁止的跨功能访问

- 禁止修改 `Yu.tscn` / `yu.gd` 的移动逻辑
- 禁止在 YuNpc 中直接引用玩家（`$Yu`、group 等）——判定课再建关系
- 禁止绕过 `tixing` 用贴图尺寸推断体型

## 四、学生参与与学习目标

### 学习目标

1. 定位新文件并说出生成器 / NPC 蓝图的职责边界
2. 解释随机数、Timer.timeout、get_viewport_rect、queue_free 各自解决的问题
3. 编辑器检查 YuQun 子树与参数，调整后 F5 观察差异
4. 用 Remote 面板解释 YuNpc 数量的增减，说出一处排查位置

### 检查点安排

| 检查点 | 时机 | 学生动作 | 证据类型 |
|---|---|---|---|
| orientation | step-01 前 | 定位文件 + 说出分工 + 二选一设计决策（随机间隔 vs 固定间隔） | project_navigation, concept_explanation |
| godot-inspection | step-02 后 | 打开 Main.tscn 检查 YuQun/Dingshi、检查器参数 | editor_operation, scene_tree_inspection |
| verification-handoff | step-04 后 | F5 亲测生成/游入/回收，调参观察，说出排查位置 | result_interpretation, test_execution |

## 五、文件级实现规格

### 5.1 scripts/yu_npc.gd（新建）

```gdscript
extends Node2D
class_name YuNpc
# NPC 鱼：进树时随机外观，横向直线游动，游出屏幕自动释放

@export var tie_tu_shu_zu: Array[Texture2D]  # 候选贴图（检查器拖入多种鱼）
@export var tixing_fanwei := Vector2(0.6, 1.6)  # 体型系数随机范围
@export var bianju := 80.0  # 屏幕外多远算离开（像素）

var tixing := 1.0  # 实际体型系数（TASK-003 大小判定读取）
var sudu := 100.0  # 游速（像素/秒），生成器写入
var fangxiang := -1.0  # 1 向右，-1 向左，生成器写入

func _ready() -> void:
	# 随机体型与贴图：Godot 4 启动时自动播种，无需 randomize()
	tixing = randf_range(tixing_fanwei.x, tixing_fanwei.y)
	scale = Vector2.ONE * tixing
	if not tie_tu_shu_zu.is_empty():
		$Sprite2D.texture = tie_tu_shu_zu.pick_random()
	$Sprite2D.flip_h = fangxiang < 0.0  # 默认贴图朝右

func _process(delta: float) -> void:
	position.x += fangxiang * sudu * delta
	var pingmu_kuan := get_viewport_rect().size.x
	if position.x < -bianju or position.x > pingmu_kuan + bianju:
		queue_free()  # 游出屏幕：释放节点
```

### 5.2 scripts/yu_qun.gd（新建）

```gdscript
extends Node2D
class_name YuQun
# 鱼群生成器：按随机间隔从屏幕两侧生成 NPC 鱼

const YU_NPC_CHANGJING := preload("res://scenes/YuNpc.tscn")  # NPC 鱼蓝图

@export var zuixiao_jiange := 0.6  # 最短生成间隔（秒）
@export var zuida_jiange := 1.8    # 最长生成间隔（秒）
@export var zuida_shuliang := 14   # 同屏 NPC 数量上限
@export var sudu_fanwei := Vector2(60.0, 160.0)  # 游速范围（像素/秒）

@onready var dingshi: Timer = $Dingshi

func _ready() -> void:
	dingshi.timeout.connect(_on_dingshi_timeout)
	dingshi.start()

func _on_dingshi_timeout() -> void:
	if _dangqian_yu_shu() < zuida_shuliang:
		_shengcheng_yi_tiao()
	_pai_xia_yi_ci()

func _dangqian_yu_shu() -> int:
	var shu := 0
	for zi in get_children():
		if zi is YuNpc:
			shu += 1
	return shu

func _shengcheng_yi_tiao() -> void:
	var xin_yu: YuNpc = YU_NPC_CHANGJING.instantiate()
	xin_yu.sudu = randf_range(sudu_fanwei.x, sudu_fanwei.y)
	var pingmu := get_viewport_rect().size
	var cong_zuo := randf() < 0.5
	if cong_zuo:
		xin_yu.fangxiang = 1.0
		xin_yu.position = Vector2(-xin_yu.bianju, randf_range(60.0, pingmu.y - 60.0))
	else:
		xin_yu.fangxiang = -1.0
		xin_yu.position = Vector2(pingmu.x + xin_yu.bianju, randf_range(60.0, pingmu.y - 60.0))
	add_child(xin_yu)

func _pai_xia_yi_ci() -> void:
	dingshi.wait_time = randf_range(zuixiao_jiange, zuida_jiange)
	dingshi.start()
```

### 5.3 scenes/YuNpc.tscn（新建）

- 根 `YuNpc`（Node2D，挂 yu_npc.gd）
- 子 `Sprite2D`：texture = fish_blue.png（占位，运行时被随机替换）
- 根节点 `tie_tu_shu_zu` 在编辑器中拖入 6~8 种 fish_*.png（建议 blue/red/green/orange/brown/pink）

### 5.4 scenes/Main.tscn（修改）

在 Yu 之后追加：

```
YuQun (Node2D + yu_qun.gd)
└─ Dingshi (Timer, one_shot=true, wait_time=1.0)
```

不改 Haodi / Yu / 根节点任何属性。

### 5.5 scripts/main.gd（修改）

仅删除 `_gengxin_mubiao` 内的调试 `print("mubiao_dian = ", yu.mubiao_dian)` 及注释。输入逻辑不动。

## 六、分步实现顺序

1. **step-01**：YuNpc 场景 + yu_npc.gd（外观 + 移动 + 回收一并写入，但本步只验证随机外观；F6 运行）
2. **step-02**：Main 加 YuQun/Dingshi；yu_qun.gd 先实现"视口中央生成"与 Timer 链
3. **step-03**：生成位置改为两侧边缘外 + 方向/速度随机；yu_npc.gd 已具备游动
4. **step-04**：确认出屏回收生效 + 数量上限；headless 长跑验证

每步结束跑 `--headless --import`，最后跑 `--quit-after 300` 与范围检查。

## 七、验证计划

### 自动化

- `"$GODOT_BIN" --version` 输出 4.7.x
- `"$GODOT_BIN" --headless --path . --import` 退出码 0（每步）
- `"$GODOT_BIN" --headless --path . --quit-after 300` 退出码 0（覆盖生成与回收）
- `PYTHONUTF8=1 python .agents/skills/godot-guided-feature-workflow/scripts/check_task_scope.py check docs/development_tasks/TASK-002_yuqun_shengcheng` 无违例

### 手动（学生主导）

- F5：鱼从两侧游入，颜色/大小/速度/高度随机
- F5 长观察：Remote 面板 YuNpc 数量稳定
- 检查器改 `zuida_shuliang=2`、改间隔，观察差异后还原
- 回归：玩家鱼跟随手指正常

## 八、故障排查提示

| 现象 | 优先检查 |
|---|---|
| 一条鱼都不生成 | 信号是否连接（Output 有无报错）、Dingshi 是否 autostart/启动、YuQun 是否在 Main 下 |
| 鱼生成后不动 | `_process` 是否在、fangxiang 是否为 0、sudu 是否为 0 |
| 鱼出屏不消失 | 回收判断是否用 `get_viewport_rect().size.x`、bianju 是否过大 |
| 节点数一直涨 | `zuida_shuliang` 统计是否把 Dingshi 也算进去（只数 `is YuNpc`） |
| 每次运行外观一样 | 检查是否手动调用了 `seed()`；Godot 4 不需要 randomize() |

## 九、范围边界

- 白名单以 `TASK_MANIFEST.json` 为准；未登记文件一律不改
- 新增文件仅：YuNpc.tscn、yu_npc.gd(+.uid)、yu_qun.gd(+.uid)、三份报告
- 修改文件仅：Main.tscn、main.gd、引擎词总表.md、LEARNING_ROADMAP.md、TASK_INDEX.md、PROJECT_STATUS_AUDIT.md、docx、任务包自身文档

## 十、审批

等待用户明确回复「确认 TASK-002 v1 进入开发」后：捕获实现基线 → 开始 step-01。
