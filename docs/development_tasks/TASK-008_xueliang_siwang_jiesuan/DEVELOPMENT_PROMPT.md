# TASK-008: 血量、死亡与结算（血条 + 满级封顶 + 结算页 + 一键重开）

> 引擎：Godot 4.7
> 开发策略：plan_driven
> 参与模式：guided_co_development
> 执行模式：teaching
> 任务规格版本：v1
> 审批状态：awaiting
> 交付状态：proposed
> Git 基线：22a851cf373ef558b4c374a6597c9a5b3b76621e

## 一、任务目标

肉鸽补上最后一环——**有代价的死亡**。玩家血量 3 点（第 3 课 `_shoushang()` 挂钩点终于等到消费者），血条 UI 听玩家信号刷新（第 5 课"账本信号→经验条"模式二次复用）；血尽 `change_scene_to_file` 切结算场景（**本课新概念**：场景销毁重建 vs Autoload 常驻——bei_xi 悬空引用随销毁自然解决，P3-2 兑现）；结算页展示等级与本局 build（`yi_xuan_ka` 见天日）；账本 `chong_zhi()` 归零（P3-3 兑现）+ 一键重开闭环；满级封顶（TASK-005/006/007 三次 P3 合并，本课拍板落地）。完成后：**死得起，也重得开**——肉鸽循环正式闭环。

### 完成后可观察结果

- F5：撞大鱼三次，血条 3→2→1→0 → 切结算页，显示"Lv.X"和本局选过的卡名列表
- 点"再来一次"：回到 Main，经验条 Lv.1 空条、血条满、无已选卡、玩家无 buff——一切归零
- 满级（Lv.7）后：经验条停满、不再弹窗不再长大；低级升级照旧
- 完整回归：七课行为无退化

### 本任务不做

- 嘴/身判定圈拆分（贪食副作用——学生已拍板方案 A，血量上线后仅作**观察项**；改主意=范围变更升 v2）
- 死因/游戏时长/最高纪录等结算扩展（后续迭代）
- 局外永久解锁/元进度（明确不做：纯局内肉鸽）
- 测试代码（tests/ 第 9 课建）
- 血量规则超出"上限 3、每撞掉 1"（改数值=改 @export 即可，改规则=范围变更）

## 二、当前工程状态

### 已实现并验证（TASK-001~007）

- 七课闭环：移动→鱼群→吃/伤判定→数据驱动→账本成长→升级三选一→六卡生效+磁吸+动画
- **`_shoushang()` 是空挂钩**（第 3 课挖好）：目前只闪红+无敌，无实际代价——本课接血量
- **`yi_xuan_ka` 只入账无展示**——本课结算页消费
- 满级行为现状：Lv.7 后阈值停在表尾继续升、弹窗照常弹（未决策的边界）

### 审计新鲜度

- audited_commit：22a851cf373ef558b4c374a6597c9a5b3b76621e（工作区干净）
- environment_checked_at：2026-10-24T01:50:00Z
- engine_executable_source：common_path（`D:\001\Godot_v4.7.2-stable_win64.exe`）
- engine_version_detected：4.7.2
- 导入 0 错误；360 帧运行输出筛查零命中

### 当前依赖与阻塞

- 依赖 TASK-003（_shoushang 挂钩）、TASK-005（信号驱动 UI 模式）、TASK-006（yi_xuan_ka）、TASK-007（bei_xi 清理验证）；无阻塞

## 三、功能所有权与团队集成

### 功能所有者

- owner_id：student-01
- 新建 4 文件：`scripts/xue_liang_ui.gd`、`scripts/jie_suan.gd`（各 + .uid）、`scenes/XueLiangTiao.tscn`、`scenes/JieSuan.tscn`
- 修改 3 文件：`scripts/yu.gd`（血量+死亡）、`scripts/zhang_ben.gd`（封顶+chong_zhi）、`scenes/Main.tscn`（实例化血条）
- **零修改**：`yu_npc.gd`、`yu_qun.gd`、`yu_zhong.gd`、`main.gd`、`jing_yan_ui.gd`、`qiang_hua_dan_chuang.gd`、`QiangHuaDanChuang.tscn`、`Yu.tscn`、`YuNpc.tscn`、`project.godot`、`data/*`

### 集成合同

| 类型 | 名称 | 提供方 | 使用方 | 合同 |
|---|---|---|---|---|
| 挂钩兑现 | `yu._shoushang()` | TASK-003 挖点 | 本课 | 扣血 + 死亡判定接入，闪红无敌逻辑不动 |
| 模式复用 | 信号驱动 UI | TASK-005（账本→经验条） | 血条 | 照抄成"玩家信号→血条"，玩家是血量唯一所有者 |
| 数据消费 | `ZhangBen.deng_ji / yi_xuan_ka` | 账本 | 结算页 | 只读展示，零写入 |
| 方法新增 | `ZhangBen.chong_zhi()` | 账本（本课新增） | 结算页按钮 | 局内状态归零唯一入口（P3-3） |
| 生命周期 | `change_scene_to_file` | 引擎 | 死亡/重开 | Main↔JieSuan 双向切换；Autoload 全程常驻 |

- **禁止**：血量出现在账本（沿第 7 课"账本不成玩家仓库"决策）
- **禁止**：结算页直接改账本数据（只读；归零只走 chong_zhi）
- **禁止**：chong_zhi 之外任何地方清 yi_xuan_ka / deng_ji

## 四、学生参与与学习目标

### 学习目标

1. 复述 **push_warning 与 error 的区别**（课后题刚纠正：拼错键=静默失效+Output 黄字，不崩溃）
2. 解释 **change_scene_to_file 做了什么**：旧场景全树销毁、新场景重建、Autoload 全程不动
3. 回答**"重开后哪些状态自动归位、哪些必须 chong_zhi"**（场景侧 vs 账本侧——本课核心）
4. 说出满级封顶为什么是**设计决策**（数据表有尽头，读表方必须处理表外）
5. 跟踪死亡数据流：撞大鱼 → `_shoushang` 扣血 → 信号刷血条 → 血尽 → 切结算 → 读账本展示 build

### 检查点安排

| 检查点 | 时机 | 学生动作 | 证据类型 |
|---|---|---|---|
| orientation | step-01 前 | 复述两项抽查（push_warning vs error / Autoload 与场景生命周期）+ 三个设计决策 | project_navigation, concept_explanation |
| godot-inspection | step-01 后 | 血条位置调整（检查器实操）+ F5 三撞掉血 + 远程树看 Xue Liang | editor_operation, configuration_inspection |
| verification-handoff | step-04 后 | F5 亲测四条：三撞血尽→结算 / 重开归零 / 满级封顶 / 全量回归 + 贪食观察项表态 | result_interpretation, test_execution |

### 设计决策（orientation 三连）

1. **血量数据放哪**：A 玩家身上 + 信号广播（推荐——血量是身体属性，账本不成玩家仓库）vs B 入账本（跟经验做邻居）
2. **满级处理**：A 封顶——Lv.7 后经验停满、不升级不弹窗（推荐——build 有终点，肉鸽单局有形状）vs B 无限级继续（阈值沿用表尾）
3. **死亡重开方式**：A `change_scene_to_file` 整场景重载 + 账本 chong_zhi（推荐——本课新概念，一键干净）vs B 不切场景原地手动复位（逐个还原血量/位置/鱼群/账本）

## 五、文件级实现规格

### 5.1 scripts/yu.gd（血量 + 死亡）

```gdscript
@export var zuida_xue := 3  # 血量上限（撞大鱼掉 1）
var xue_liang := 0  # 当前血量（_ready 里置满）
signal xue_liang_bian_hua(dangqian: int, zuigao: int)  # 血量变动：血条刷新

# _ready 追加：
xue_liang = zuida_xue

# _shoushang() 在闪红无敌之后追加：
xue_liang -= 1
xue_liang_bian_hua.emit(xue_liang, zuida_xue)
if xue_liang <= 0:
	_si_wang()  # step-01 占位 push_warning，step-03 接场景切换

# step-03 的 _si_wang()：
func _si_wang() -> void:
	get_tree().change_scene_to_file("res://scenes/JieSuan.tscn")
```

### 5.2 scenes/XueLiangTiao.tscn + scripts/xue_liang_ui.gd（血条，照抄经验条模式）

```
XueLiangTiao (CanvasLayer, xue_liang_ui.gd)
└─ XueLiangTiaoBg (ProgressBar 红色填充, 位置学生检查器实操调)
```

```gdscript
extends CanvasLayer
# 血条 UI：听玩家信号刷新（第 5 课"账本信号→经验条"同款模式，所有者换成玩家）

@onready var tiao: ProgressBar = $XueLiangTiaoBg

func _ready() -> void:
	var yu := get_tree().get_first_node_in_group("wan_jia") as Yu
	if yu == null:
		return
	tiao.max_value = yu.zuida_xue
	tiao.value = yu.xue_liang
	yu.xue_liang_bian_hua.connect(_on_xue_liang_bian_hua)

func _on_xue_liang_bian_hua(dangqian: int, zuigao: int) -> void:
	tiao.max_value = zuigao
	tiao.value = dangqian
```

> Yu 需加 `add_to_group("wan_jia")`（_ready 一行）——血条经 group 找到玩家，不依赖节点路径（场景结构解耦）。

### 5.3 scripts/zhang_ben.gd（满级封顶 + 重置）

```gdscript
# jia_jing_yan() 封顶分支（设计决策 2A）：表尾等级不再升级
func jia_jing_yan(fen: int) -> void:
	var yuzhi_zu := sheng_ji_biao.yuzhi_zu
	if deng_ji > yuzhi_zu.size():
		jing_yan = yuzhi_zu[-1]  # 满级：经验停在满格，不再升级不再广播
		jing_yan_bian_hua.emit(jing_yan, dangqian_yuzhi())
		return
	# ……既有逻辑不动

# 局内状态重置（P3-3 兑现）：
func chong_zhi() -> void:
	# 一键重开唯一入口：常驻者自己负责归零（玩家/鱼群随场景重建无需管）
	jing_yan = 0
	deng_ji = 1
	yi_xuan_ka.clear()
	jing_yan_jia_cheng = 1.0
```

### 5.4 scenes/JieSuan.tscn + scripts/jie_suan.gd（结算页，独立场景）

```
JieSuan (CanvasLayer 根, jie_suan.gd)   ← 不实例化进 Main；场景切换目标
├─ BanDi (ColorRect 全屏深色)
├─ BiaoTi (Label "本局终了")
├─ DengJi (Label "Lv.X"  ← _ready 读 ZhangBen.deng_ji)
├─ KaLieBiao (VBoxContainer  ← _ready 遍历 yi_xuan_ka 动态生成卡名 Label)
└─ ChongKai (Button "再来一次")
```

```gdscript
extends CanvasLayer
# 结算页：读账本展示本局成果；重开 = 账本归零 + 切回 Main

func _ready() -> void:
	$DengJi.text = "Lv." + str(ZhangBen.deng_ji)
	for ka in ZhangBen.yi_xuan_ka:
		var ming := Label.new()
		ming.text = ka.ming_zi
		$KaLieBiao.add_child(ming)
	$ChongKai.pressed.connect(_on_chong_kai)

func _on_chong_kai() -> void:
	ZhangBen.chong_zhi()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
```

### 5.5 scenes/Main.tscn（实例化血条）

追加 `XueLiangTiao (XueLiangTiao.tscn 实例)`，与 JingYanTiao 并列。

## 六、分步实现顺序

1. **step-01**：血量 + 血条——yu.gd 血量/信号/扣血（死亡占位 push_warning）+ XueLiangTiao + Main 实例化（F5 三撞掉血）
2. **step-02**：满级封顶——zhang_ben.gd jia_jing_yan 表尾分支（F5 满级停涨不弹窗）
3. **step-03**：死亡切换 + 结算页——JieSuan.tscn/jie_suan.gd + yu.gd `_si_wang()` 接线（F5 血尽见结算）
4. **step-04**：chong_zhi + 重开闭环 + 全量回归（F5 死→结算→重开→全归零→第二局照常）

每步 `--headless --import` + `--fixed-fps 60 --quit-after 360`，输出经 grep 筛查 error/not found。

## 七、验证计划

### 自动化

- `"$GODOT_BIN" --version` 输出 4.7.x
- `"$GODOT_BIN" --headless --path . --import` 退出码 0（每步）
- `"$GODOT_BIN" --headless --path . --fixed-fps 60 --quit-after 360` 输出筛查零命中
- `PYTHONUTF8=1 python .../check_task_scope.py check docs/development_tasks/TASK-008_xueliang_siwang_jiesuan` 无违例

### 手动（学生主导）

- 三撞血尽 → 结算页（等级 + build 卡名与实际选卡一致）
- 重开归零：账本四项 + 血条满 + 玩家无 buff；第二局完整可玩
- 满级封顶：条停满不弹窗；低级升级照旧
- 全量回归七课 + 贪食观察项表态（方案 A 维持 or 范围变更）

## 八、故障排查提示

| 现象 | 优先检查 |
|---|---|
| 血条不动 | Yu 是否 add_to_group("wan_jia")；血条 _ready 是否晚于玩家就绪（Main 里血条节点排在 Yu 之后）；信号连接是否成功 |
| 撞一次掉好几格血 | 无敌期是否生效（wudi 期间不重复伤——第 3 课机制）；是否一次碰撞触发多次 entered |
| 血尽不切结算 | _si_wang 是否被调（Output 有无占位警告）；step-03 后检查 change_scene_to_file 路径拼写 |
| 结算页卡名空白 | yi_xuan_ka 是否有数据（本局真选过卡吗）；.tres 的 ming_zi |
| 重开后等级没归零 | chong_zhi 是否在切场景**之前**调用；账本字段是否全部覆盖（四个一个不能漏） |
| 重开后血条空/满异常 | 血条 _ready 读 zuida_xue/xue_liang 初值；玩家 _ready 置满血时机 |
| 满级后还在弹窗 | 封顶分支 return 是否在升级判断之前；deng_ji 与表长的比较符 |
| 切场景瞬间报错 | bei_xi 鱼是否随销毁正常释放（P3-2：应无报错——有报错说明有节点在销毁后仍访问） |

## 九、范围边界

- 白名单以 `TASK_MANIFEST.json` 为准；未登记文件一律不改
- zhang_ben.gd 两处新增（封顶分支 + chong_zhi），既有方法/信号零语义变化
- yu.gd 只动 _shoushang（追加）与新增血量/_si_wang/add_to_group；移动/判定/buff/动画结构不动
- JieSuan 为独立场景，**不进 Main、不动 project.godot 主场景**
- 零新增数据资源；零触碰 data/

## 十、审批

等待用户明确回复「确认 TASK-008 v1 进入开发」后：捕获实现基线 → orientation 检查点（两项复述抽查 + 三个设计决策）→ 开始 step-01。
