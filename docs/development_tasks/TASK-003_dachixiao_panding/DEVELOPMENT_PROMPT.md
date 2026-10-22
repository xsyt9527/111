# TASK-003: 大吃小判定（Area2D 碰撞 + 体型比较）

> 引擎：Godot 4.7
> 开发策略：plan_driven
> 参与模式：guided_co_development
> 执行模式：teaching
> 任务规格版本：v1
> 审批状态：awaiting
> 交付状态：proposed
> Git 基线：da0685b7957615d90764651b8038ffd5be6b567f

## 一、任务目标

给玩家鱼与 NPC 鱼各加 Area2D 检测区，玩家撞到 NPC 时比较 `tixing`：大吃小（NPC 释放），小撞大受伤（闪红 + 1 秒无敌）。完成后「大鱼吃小鱼」玩法核心成立。

### 完成后可观察结果

- F5：玩家追上比自己小的鱼 → 鱼撞上即消失（被吃），生成器继续补新鱼
- F5：撞到比自己大的鱼 → 玩家瞬间变红，1 秒后恢复白色
- 无敌的 1 秒内反复穿过大鱼只伤一次；期间仍能吃小鱼
- 完整回归：跟随移动、鱼群生成、出屏回收无退化

### 本任务不做

- 经验/分数（TASK-005）、血量/死亡（TASK-008）、Tween/特效（第 7 课）、鱼种数据表（TASK-004）
- 玩家长大（`tixing` 只读不写）
- 不加物理推挤（Area2D 只检测不碰撞响应，鱼互相穿过是预期行为）

## 二、当前工程状态

### 已实现并验证（TASK-001/002）

- `Main.tscn`：Haodi + Yu 实例 + YuQun(Dingshi) 子树
- `yu.gd`：`mubiao_dian` 目标点 + `_process` 中 move_toward 移动 + flip_h
- `yu_npc.gd`：`tixing`（0.6~1.6 随机）、`sudu`/`fangxiang`、出屏 queue_free
- `yu_qun.gd`：随机间隔两侧生成、上限 14
- 玩家与 NPC 目前**互相穿过，无判定**

### 审计新鲜度

- audited_commit：da0685b7957615d90764651b8038ffd5be6b567f（工作区干净）
- environment_checked_at：2026-10-22T03:11:02Z
- engine_executable_source：common_path（`D:\001\Godot_v4.7.2-stable_win64.exe`）
- engine_version_detected：4.7.2（4.7.2.stable.official.ed1daf0bf）

### 当前依赖与阻塞

- 依赖 TASK-001（玩家移动）、TASK-002（NPC.tixing 与鱼群供给）；无阻塞

## 三、功能所有权与团队集成

### 功能所有者

- owner_id：student-01
- owned_systems：大吃小判定、受伤反馈
- 修改仅 4 文件：`Yu.tscn`、`yu.gd`、`YuNpc.tscn`、`yu_npc.gd`
- **零修改**：`Main.tscn`、`main.gd`、`yu_qun.gd`、`project.godot`

### 集成合同

| 类型 | 名称 | 提供方 | 使用方 | 合同 |
|---|---|---|---|---|
| 属性 | `Yu.tixing: float` | yu.gd | TASK-005 成长系统 | 默认 1.0；本课只读 |
| 方法 | `YuNpc.bei_chi()` | yu_npc.gd | yu.gd / TASK-005 | 被吃统一入口：queue_free |
| 方法 | `Yu._shoushang()` | yu.gd | 判定分支 / TASK-008 | 受伤统一入口：闪红+无敌 |
| 约定 | 碰撞层 Layer1=玩家 / Layer2=鱼群 | 本任务 | 后续所有物理任务 | mask 规则见下 |

- 信号（均在宿主 `_ready` 代码连接一次）：`PandingQu.area_entered(area)` → `_on_panding_qu_entered`；`WudiDingshi.timeout` → `_jiechu_wudi`
- **登记的共享变更：无**（project.godot 不动）

### 禁止的跨功能访问

- 禁止玩家脚本直接 `queue_free()` NPC（必须走 `bei_chi()`，经验系统以后要在入口加账）
- 禁止改动 `_process` 中移动段与 `yu_qun.gd` 任何逻辑
- 禁止写入 `Yu.tixing`（长大属 TASK-005）

## 四、学生参与与学习目标

### 学习目标

1. 定位两个 `PandingQu` 子树，说出 Area2D（区域与信号）与 CollisionShape2D（形状与大小）的分工
2. 用自己的话解释 layer 与 mask，说明"玩家 mask=2、NPC mask=0"为何不会重复判定
3. 跟踪一次判定的数据流：`area_entered(area)` → `get_parent()` → `tixing` 比较 → `bei_chi()` / `_shoushang()`
4. 编辑器核对 Layer/Mask 勾选、调圆形半径观察判定范围变化

### 检查点安排

| 检查点 | 时机 | 学生动作 | 证据类型 |
|---|---|---|---|
| orientation | step-01 前 | 定位文件 + layer/mask 概念确认 + 二选一设计决策 | project_navigation, concept_explanation |
| godot-inspection | step-02 后 | 检查器核对 Layer/Mask；半径调整实验 | editor_operation, configuration_inspection |
| verification-handoff | step-04 后 | F5 亲测吃/伤/无敌/回归 | result_interpretation, test_execution |

## 五、文件级实现规格

### 5.1 scenes/Yu.tscn（修改：追加两个子节点）

```
Yu (Node2D)
├─ Sprite2D（既有）
├─ PandingQu (Area2D)         ← 新增
│  collision_layer = 1        （我是玩家）
│  collision_mask = 2         （我检测鱼群）
│  └─ CollisionShape2D        ← 新增，CircleShape2D 半径 22
└─ WudiDingshi (Timer)        ← 新增，one_shot=true，wait_time=1.0
```

tscn 中形状为 SubResource：`[sub_resource type="CircleShape2D" id="..."] radius = 22.0`

### 5.2 scripts/yu.gd（修改：追加成员，移动段不动）

```gdscript
var tixing := 1.0  # 玩家体型系数（第 5 课成长会增大它）
var wudi := false  # 受伤后的短暂无敌标记

@onready var panding_qu: Area2D = $PandingQu
@onready var wudi_dingshi: Timer = $WudiDingshi

# _ready 内追加（mubiao_dian = position 保留）：
	panding_qu.area_entered.connect(_on_panding_qu_entered)
	wudi_dingshi.timeout.connect(_jiechu_wudi)

func _on_panding_qu_entered(qu: Area2D) -> void:
	# 闯进检测区的是 NPC 的 Area2D；它的父节点才是 YuNpc 本体
	var yu_npc := qu.get_parent() as YuNpc
	if yu_npc == null:
		return  # 不是 NPC（将来可能有别的区域），直接忽略
	if tixing > yu_npc.tixing:
		yu_npc.bei_chi()  # 我比它大：吃
	elif not wudi:
		_shoushang()      # 它比我大：受伤（无敌期跳过）

func _shoushang() -> void:
	wudi = true
	modulate = Color(1.0, 0.4, 0.4)  # 闪红示警
	wudi_dingshi.start()

func _jiechu_wudi() -> void:
	wudi = false
	modulate = Color.WHITE  # 恢复颜色
```

### 5.3 scenes/YuNpc.tscn（修改：追加检测区）

```
YuNpc (Node2D)
├─ Sprite2D（既有）
└─ PandingQu (Area2D)         ← 新增
   collision_layer = 2        （我是鱼群）
   collision_mask = 0         （我不检测任何人）
   └─ CollisionShape2D        ← 新增，CircleShape2D 半径 22
```

注意：NPC 根节点 `scale = tixing` 会连带缩放子节点，**判定圈自动跟着体型变大变小**——这是白送的。

### 5.4 scripts/yu_npc.gd（修改：追加一个方法）

```gdscript
func bei_chi() -> void:
	queue_free()  # 被玩家吃掉：释放自己（第 5 课在入口加经验记账）
```

## 六、分步实现顺序

1. **step-01**：Yu.tscn 加 PandingQu/形状 + WudiDingshi 占位；yu.gd 加 `tixing`。F5 回归
2. **step-02**：YuNpc.tscn 加 PandingQu/形状（layer=2, mask=0）。F5 回归
3. **step-03**：yu.gd 连 area_entered + 比较分支；yu_npc.gd 加 bei_chi()。F5 可吃鱼
4. **step-04**：受伤反馈 + 无敌计时接通。F5 完整可玩

每步跑 `--headless --import`；step-03 起加跑 `--fixed-fps 60 --quit-after 360`。

## 七、验证计划

### 自动化

- `"$GODOT_BIN" --version` 输出 4.7.x
- `"$GODOT_BIN" --headless --path . --import` 退出码 0（每步）
- `"$GODOT_BIN" --headless --path . --fixed-fps 60 --quit-after 360` 退出码 0（物理判定无错误）
- `PYTHONUTF8=1 python .../check_task_scope.py check docs/development_tasks/TASK-003_dachixiao_panding` 无违例

### 手动（学生主导）

- 吃：撞小鱼即消失，Remote 面板节点数回落再补
- 伤：撞大鱼闪红 1 秒恢复
- 无敌帧：1 秒内穿过大鱼只红一次，期间仍可吃小鱼
- 回归：移动、生成、回收全部正常

## 八、故障排查提示

| 现象 | 优先检查 |
|---|---|
| 撞鱼毫无反应 | PandingQu 的 Mask 是否勾了 2；CollisionShape2D 有没有形状（无形状会警告） |
| 每次碰撞判定两次 | 是不是两边都连了信号/两边 mask 都开了——本设计只让玩家检测 |
| 大鱼也消失了 | 比较方向写反（`>` 才吃）；或取错对象比较了 tixing_fanwei |
| 一直红着不变回来 | WudiDingshi 的 one_shot 是否勾、timeout 是否连了 `_jiechu_wudi` |
| NPC 一生成就被吃 | 生成位置在屏幕外，玩家够不到——检查是否误用全局坐标 |

## 九、范围边界

- 白名单以 `TASK_MANIFEST.json` 为准；未登记文件一律不改
- 新增文件仅三份报告；修改仅 4 个生产文件 + 文档
- `project.godot`、`main.gd`、`yu_qun.gd`、`Main.tscn` 零改动

## 十、审批

等待用户明确回复「确认 TASK-003 v1 进入开发」后：捕获实现基线 → orientation 检查点 → 开始 step-01。
