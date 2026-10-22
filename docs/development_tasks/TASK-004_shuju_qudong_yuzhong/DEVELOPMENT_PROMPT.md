# TASK-004: 数据驱动鱼种（自定义 Resource + .tres 注册表）

> 引擎：Godot 4.7
> 开发策略：plan_driven
> 参与模式：guided_co_development
> 执行模式：teaching
> 任务规格版本：v1
> 审批状态：awaiting
> 交付状态：proposed
> Git 基线：d945087f536807a20abbf233234037609ad07dee

## 一、任务目标

新建自定义 Resource 类 `YuZhong`（鱼种模具），做 6 个 `.tres` 鱼种数据文件；NPC 鱼从"读检查器贴图数组"改成"读注入的鱼种资源"；生成器检查器拖入鱼种表数组，生成时随机抽一种。完成后**加新鱼不改代码**——新建 .tres 填字段、拖进数组即可。

### 完成后可观察结果

- F5：同种鱼外观/体型/速度**成套**（贴图与数值绑定）：蓝鱼小、棕鱼大而慢、粉鱼大而快
- 双击任一 .tres 可在检查器改字段，改完 F5 对应鱼种整体变化
- 完整回归：大吃小判定、受伤无敌、跟随移动、出屏回收全部无退化

### 本任务不做

- 经验/分数记账（`fenzhi` 只存数据，无代码读它——TASK-005 消费）
- 运行时扫描文件夹自动注册鱼种（DirAccess + 导出 .remap 坑，进阶话题）
- 按等级限制鱼种出场（难度曲线，后续任务）
- 零碰 `yu.gd` / `Yu.tscn` / `main.gd`（判定与输入系统不动）

## 二、当前工程状态

### 已实现并验证（TASK-001/002/003）

- 玩家跟随手指移动；鱼群随机间隔从两侧游入，同屏上限 14，出屏回收
- 大吃小判定（玩家 mask=2 单向检测）、闪红 + 1 秒无敌
- **结构问题（本课起点）**：NPC 外观由 `YuNpc.tscn` 里手动维护的 6 贴图数组 `tie_tu_shu_zu` + 脚本 `tixing_fanwei` 决定——加新鱼要改场景文件，数值（分值/等级）也没地方放

### 审计新鲜度

- audited_commit：d945087f536807a20abbf233234037609ad07dee（工作区干净）
- environment_checked_at：2026-10-22T07:30:00Z
- engine_executable_source：common_path（`D:\001\Godot_v4.7.2-stable_win64.exe`）
- engine_version_detected：4.7.2（4.7.2.stable.official.ed1daf0bf）

### 当前依赖与阻塞

- 复用 TASK-002 的注入顺序约定（生成前赋值、add_child 后 _ready 消费）；无阻塞

## 三、功能所有权与团队集成

### 功能所有者

- owner_id：student-01
- 新建：`scripts/yu_zhong.gd`、`data/yuzhong/*.tres` × 6
- 修改 4 文件：`yu_npc.gd`（只换 _ready 数据来源）、`yu_qun.gd`（只换 _shengcheng_yi_tiao 赋值来源）、`YuNpc.tscn`（清贴图数组）、`Main.tscn`（YuQun 拖入鱼种表）
- **零修改**：`yu.gd`、`Yu.tscn`、`main.gd`、`project.godot`

### 集成合同

| 类型 | 名称 | 提供方 | 使用方 | 合同 |
|---|---|---|---|---|
| 类 | `YuZhong`（Resource） | yu_zhong.gd | .tres / yu_npc.gd / yu_qun.gd | 五字段数据模具 |
| 属性 | `YuNpc.yu_zhong: YuZhong` | yu_qun.gd 注入 | TASK-005 记账 | add_child 前赋值 |
| 数据 | `YuZhong.fenzhi: int` | .tres | TASK-005 | 本课只存不读 |
| 数据 | `YuZhong.dengji: int` | .tres | TASK-005+ | 鱼种等级 |
| 模式 | 注册表（模具+数据+数组） | 本任务 | 第 6 课强化卡 | 可复用套路 |

- 无新信号；**登记的共享变更：无**（project.godot 不动）
- 数据流：`.tres 字段 → YuQun.pick_random → xin_yu.yu_zhong（add_child 前）→ YuNpc._ready 读出贴图/体型/速度`

### 禁止的跨功能访问

- 禁止任何代码读 `fenzhi`（记账是 TASK-005 的入口职责）
- 禁止改写 YuNpc 游动/回收/`bei_chi()` 与 YuQun 间隔/上限/边缘生成逻辑
- 禁止碰判定与输入系统

## 四、学生参与与学习目标

### 学习目标

1. 定位贴图数组的两处硬编码，说出"加新鱼要改场景文件"的结构问题
2. 用自己的话解释 Resource 三分工：**脚本=模具（定结构）、.tres=数据（存实例）、检查器=填表**
3. 跟踪数据流：.tres → 生成器抽取 → 注入 → _ready 消费
4. 编辑器检查 .tres、改一个字段 F5 观察该鱼种整体变化，之后还原

### 检查点安排

| 检查点 | 时机 | 学生动作 | 证据类型 |
|---|---|---|---|
| orientation | step-01 前 | 定位硬编码 + "模具 vs 数据"概念确认 + 两个设计决策 | project_navigation, concept_explanation |
| godot-inspection | step-02 后 | 编辑器 New Resource 看 YuZhong 字段（不保存）；双击检查 .tres；改字段 F5 实验后还原 | editor_operation, configuration_inspection |
| verification-handoff | step-04 后 | F5 亲测四条：同种成套/判定回归/改表生效/全量回归 | result_interpretation, test_execution |

## 五、文件级实现规格

### 5.1 scripts/yu_zhong.gd（新建：鱼种模具）

```gdscript
extends Resource
class_name YuZhong
# 鱼种数据模具：一个 .tres 文件 = 鱼种表的一行

@export var tie_tu: Texture2D                     # 这种鱼长什么样
@export var dengji := 1                           # 鱼种等级（第 5 课参考）
@export var tixing_fanwei := Vector2(0.6, 1.6)    # 体型随机范围
@export var sudu_fanwei := Vector2(60.0, 160.0)   # 游速随机范围（像素/秒）
@export var fenzhi := 1                           # 吃掉它得多少分（TASK-005 记账）
```

### 5.2 data/yuzhong/*.tres × 6（新建：鱼种数据）

| 文件 | 贴图 | dengji | tixing_fanwei | sudu_fanwei | fenzhi |
|---|---|---|---|---|---|
| lan_yu.tres | fish_blue.png | 1 | (0.5, 0.8) | (60, 100) | 1 |
| hong_yu.tres | fish_red.png | 1 | (0.6, 0.9) | (80, 120) | 1 |
| lv_yu.tres | fish_green.png | 2 | (0.9, 1.2) | (70, 110) | 2 |
| cheng_yu.tres | fish_orange.png | 2 | (1.0, 1.3) | (90, 130) | 3 |
| zong_yu.tres | fish_brown.png | 3 | (1.2, 1.5) | (55, 90) | 5 |
| fen_yu.tres | fish_pink.png | 3 | (1.3, 1.6) | (100, 140) | 5 |

手写 .tres 用 path 引用贴图（编辑器保存时自动补 uid——预期内变更）。

### 5.3 scripts/yu_npc.gd（修改：换数据来源，其余不动）

```gdscript
# 删除：@export var tie_tu_shu_zu / @export var tixing_fanwei
var yu_zhong: YuZhong   # 鱼种数据（生成器在 add_child 前注入）

func _ready() -> void:
	if yu_zhong != null:
		tixing = randf_range(yu_zhong.tixing_fanwei.x, yu_zhong.tixing_fanwei.y)
		scale = Vector2.ONE * tixing
		if yu_zhong.tie_tu != null:
			$Sprite2D.texture = yu_zhong.tie_tu
	else:
		# 兜底：没接到鱼种数据（生成器接线前的过渡态）
		tixing = randf_range(0.6, 1.6)
		scale = Vector2.ONE * tixing
	$Sprite2D.flip_h = fangxiang < 0.0
```

游动/出屏回收/`bei_chi()` **一行不动**。YuNpc.tscn 同步清掉 6 个贴图 ext_resource 与 `tie_tu_shu_zu` 属性。

### 5.4 scripts/yu_qun.gd（修改：抽鱼种）

```gdscript
# 删除：@export var sudu_fanwei
@export var yu_zhong_zu: Array[YuZhong]   # 鱼种注册表（检查器拖入 .tres）

# _shengcheng_yi_tiao 内：
	var xin_yu: YuNpc = YU_NPC_CHANGJING.instantiate()
	if not yu_zhong_zu.is_empty():
		var zhong: YuZhong = yu_zhong_zu.pick_random()
		xin_yu.yu_zhong = zhong                       # 先注入（add_child 前）
		xin_yu.sudu = randf_range(zhong.sudu_fanwei.x, zhong.sudu_fanwei.y)
	else:
		xin_yu.sudu = 100.0   # 没配鱼种表的兜底
	# fangxiang / position / add_child 照旧
```

Main.tscn 给 YuQun 节点写 `yu_zhong_zu = Array[YuZhong]([...6 个 .tres...])` 与对应 ext_resource。

## 六、分步实现顺序

1. **step-01**：yu_zhong.gd 模具类（纯新增，零行为变化）
2. **step-02**：6 个 .tres 鱼种数据（纯新增，零行为变化）
3. **step-03**：yu_npc.gd + YuNpc.tscn 换数据来源（过渡态：兜底值，无贴图）
4. **step-04**：yu_qun.gd 抽鱼种 + Main.tscn 拖表 → F5 完整可玩

每步跑 `--headless --import`；step-03 起加跑 `--fixed-fps 60 --quit-after 360`。

## 七、验证计划

### 自动化

- `"$GODOT_BIN" --version` 输出 4.7.x
- `"$GODOT_BIN" --headless --path . --import` 退出码 0（每步）
- `"$GODOT_BIN" --headless --path . --fixed-fps 60 --quit-after 360` 退出码 0
- `PYTHONUTF8=1 python .../check_task_scope.py check docs/development_tasks/TASK-004_shuju_qudong_yuzhong` 无违例

### 手动（学生主导）

- 同种成套：同贴图的鱼体型/速度相近（蓝小慢、棕大慢、粉大快）
- 判定回归：小鱼可吃、大鱼撞了闪红
- 改表生效：改 lan_yu.tres 的 tixing_fanwei → F5 蓝鱼整体变大小 → 还原
- 全量回归：移动、生成、回收正常

## 八、故障排查提示

| 现象 | 优先检查 |
|---|---|
| 鱼全没贴图 | YuQun 的 yu_zhong_zu 数组是不是空的（没拖 .tres）；或拖了但 step-03 的注入顺序错了 |
| 生成时报 unknown property | yu_zhong 赋值发生在 add_child 之后（_ready 已经跑过）——必须在 add_child 前 |
| .tres 双击打不开/字段空 | .tres 头部 script 引用路径是否正确指向 yu_zhong.gd |
| 同种鱼速度没变化 | sudu 是注入时从鱼种表抽的——检查是不是还留着生成器旧 sudu_fanwei 的赋值 |
| 改了 .tres 没生效 | 编辑器是否重新保存/F5 重启（.tres 是静态引用，运行中不会热更新） |

## 九、范围边界

- 白名单以 `TASK_MANIFEST.json` 为准；未登记文件一律不改
- 新增生产文件：yu_zhong.gd（+ .uid）、6 个 .tres；修改 4 个生产文件 + 文档
- `yu.gd`、`Yu.tscn`、`main.gd`、`project.godot` 零改动

## 十、审批

等待用户明确回复「确认 TASK-004 v1 进入开发」后：捕获实现基线 → orientation 检查点 → 开始 step-01。
