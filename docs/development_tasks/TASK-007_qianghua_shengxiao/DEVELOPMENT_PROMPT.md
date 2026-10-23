# TASK-007: 强化生效与动画（buff 落地 + 磁吸双 Area2D + Tween）

> 引擎：Godot 4.7
> 开发策略：plan_driven
> 参与模式：guided_co_development
> 执行模式：teaching
> 任务规格版本：v1
> 审批状态：awaiting
> 交付状态：proposed
> Git 基线：478ac76f0361ac0505491952f8d424102593b454

## 一、任务目标

让第 6 课选的强化卡**真正生效**，并给游戏装上**动画生命感**。yu.gd 监听 `ZhangBen.ka_yi_xuan` 信号，`switch(ka.xiao_guo)` 分发六卡效果：迅捷/催肥/贪食/活力四张直改玩家属性，睿智倍率入账本（`bei_chi` 乘算），磁吸走**双 Area2D**——新增 ChiQu 大圈只做吸附标记、原 PandingQu 改名 ShangQu 保留吃/伤判定（学生第 3 课提案正式兑现）。动画层用 **Tween**：升级平滑长大（替换瞬间跳变）+ 吞吃脉冲反馈 + 程序化 sin 摆尾。完成后：**选什么卡感觉得到，鱼像活的**。

### 完成后可观察结果

- F5：选迅捷游得快、选贪食判定圈变大、选活力无敌更长、选催肥每级长得更多、选睿智吃鱼涨条更快
- F5：选磁吸后小鱼进大圈**自动拐弯吸向玩家**，出圈恢复直线；大鱼（打不过的）不被吸
- F5：升级 0.3 秒平滑长大不再跳变；每吃一条玩家轻弹一下；游动时尾巴轻摆
- 完整回归：移动/生成/回收/判定/无敌/涨条/长大/升级弹窗全部无退化（尤其 ShangQu 改名后吃/伤判定照旧）

### 本任务不做

- 血量/死亡/结算（TASK-008）
- 满级处理决策（与 TASK-005/006 P3 合并，TASK-008）
- 新增强化卡/改卡数值（`data/qianghua` 零触碰——本课只消费现有六卡）
- 弹窗卡片翻转动效（占位视觉已够用，动画范围仅升级/吞吃/摆尾三处）

## 二、当前工程状态

### 已实现并验证（TASK-001~006）

- 六课闭环：移动 → 鱼群 → 大吃小 → 数据驱动鱼种 → 账本成长 → 升级三选一
- **ka_yi_xuan 信号已预埋待消费**（TASK-006 接口先行，本课第一个消费者连接）
- **QiangHuaKa.xiao_guo/shu_zhi 只存不用**——本课消费
- PandingQu 判定圈随根节点 scale 自动变大（第 3 课机制，催肥/贪食在其上叠加）

### 审计新鲜度

- audited_commit：478ac76f0361ac0505491952f8d424102593b454（工作区干净）
- environment_checked_at：2026-10-23T04:20:00Z
- engine_executable_source：common_path（`D:\001\Godot_v4.7.2-stable_win64.exe`）
- engine_version_detected：4.7.2
- 导入 0 错误；360 帧运行输出筛查零命中（TASK-006 升级的检查纪律）

### 当前依赖与阻塞

- 依赖 TASK-006（ka_yi_xuan + 卡数据）、TASK-003（Area2D 判定结构）、TASK-005（WudiDingshi/MEI_JI_TIXING）；无阻塞

## 三、功能所有权与团队集成

### 功能所有者

- owner_id：student-01
- 修改 3 个脚本：`yu.gd`（buff switch + ChiQu 吸附 + Tween + 摆尾）、`yu_npc.gd`（bei_xi 吸附追踪 + bei_chi 倍率乘算）、`zhang_ben.gd`（jing_yan_jia_cheng 倍率一处）
- 修改 1 个场景：`Yu.tscn`（PandingQu 改名 ShangQu + 新增 ChiQu）
- **零修改**：`yu_qun.gd`、`yu_zhong.gd`、`main.gd`、`jing_yan_ui.gd`、`qiang_hua_dan_chuang.gd`、`QiangHuaDanChuang.tscn`、`YuNpc.tscn`、`project.godot`、`data/*`

### 集成合同

| 类型 | 名称 | 提供方 | 使用方 | 合同 |
|---|---|---|---|---|
| 信号消费 | `ZhangBen.ka_yi_xuan(ka)` | 账本（TASK-006） | yu.gd | 预埋接口兑现：连接即活，账本零改动 |
| 信号消费 | `ZhangBen.sheng_ji` | 账本（TASK-005） | yu.gd | 已有连接，本课改动画方式（Tween） |
| 方法新增 | `ZhangBen.she_jing_yan_jia_cheng(bei)` | 账本（本课新增） | yu.gd 睿智分支 | 倍率唯一所有者仍是账本 |
| 状态新增 | `YuNpc.bei_xi: Yu` | NPC（本课新增） | yu.gd 写 / yu_npc 读 | 吸附标记：非空时 NPC 自追玩家 |
| 数据 | `QiangHuaKa.xiao_guo/shu_zhi` | 卡池 .tres | yu.gd switch | 字符串键无编译期校验——push_warning 兜底 |

- **禁止**：效果数值写死在代码里（必须读 `ka.shu_zhi`，加卡/调数值零代码）
- **禁止**：jing_yan_jia_cheng 之外在账本新增玩家属性（账本不成玩家仓库）
- **禁止**：ShangQu 判定行为改动（只允许改名，吃/伤逻辑零碰）

## 四、学生参与与学习目标

### 学习目标

1. 复述 **Resource 三分工**（第 6 课遗留待巩固：.tres=全部数值、检查器=改数值的填表入口、.gd=模具定字段）
2. 解释磁吸为什么必须**双 Area2D**（分行为须分 Area2D——自己第 3 课的原则，本课亲手应用）
3. 说出 switch(xiao_guo) 字符串分发为什么要 push_warning 兜底
4. 区分**动画与状态**：Tween 只改显示，tixing/scale 数值即时到位，判定不依赖动画
5. 跟踪睿智卡数据流：选卡 → 账本 jing_yan_jia_cheng → bei_chi 乘算 → 涨条加速

### 检查点安排

| 检查点 | 时机 | 学生动作 | 证据类型 |
|---|---|---|---|
| orientation | step-01 前 | 复述两项抽查（Resource 三分工 / 分行为须分 Area2D）+ 两个设计决策 | project_navigation, concept_explanation |
| godot-inspection | step-02 后 | 开显示碰撞形状看双圈、远程树看 jing_yan_jia_cheng、F5 磁吸实测 | editor_operation, configuration_inspection |
| verification-handoff | step-04 后 | F5 亲测四条：六卡生效/磁吸行为/三动画/全量回归 | result_interpretation, test_execution |

## 五、文件级实现规格

### 5.1 scripts/zhang_ben.gd（修改一处：睿智倍率）

```gdscript
# 追加（其余零碰）：
var jing_yan_jia_cheng := 1.0  # 经验加成倍率（睿智卡生效，bei_chi 乘算用）

func she_jing_yan_jia_cheng(bei: float) -> void:
	# 睿智卡唯一入口：账本仍是倍率的唯一所有者
	jing_yan_jia_cheng = bei
```

`yu_npc.bei_chi` 里 `jia_jing_yan(yu_zhong.fenzhi)` 改为 `jia_jing_yan(int(yu_zhong.fenzhi * jing_yan_jia_cheng))`。

### 5.2 scripts/yu.gd（buff 生效系统：step-01 主体）

```gdscript
# 追加状态：
var mei_ji_fu_dian := 0.0  # 催肥：每级体型额外增幅（叠在 MEI_JI_TIXING 上）

# _ready 追加一行（预埋信号的第一个消费者）：
ZhangBen.ka_yi_xuan.connect(_on_ka_yi_xuan)

func _on_ka_yi_xuan(ka: QiangHuaKa) -> void:
	# 强化生效中枢：按效果键分发（第 6 课只入账的卡，这里兑现）
	match ka.xiao_guo:
		"yidong_sudu":       # 迅捷：游速乘 (1+shu_zhi)
			yidong_sudu *= 1.0 + ka.shu_zhi
		"mei_ji_tixing":     # 催肥：每级体型增幅叠加
			mei_ji_fu_dian += ka.shu_zhi
		"tun_shi_fanwei":    # 贪食：判定圈形状放大（随根 scale 再乘）
			$PandingQu/CollisionShape2D.scale *= Vector2.ONE * (1.0 + ka.shu_zhi)
		"wudi_shi_chang":    # 活力：无敌计时器时长乘 (1+shu_zhi)
			wudi_dingshi.wait_time *= 1.0 + ka.shu_zhi
		"jing_yan_jia_cheng":  # 睿智：倍率入账本（bei_chi 乘算）
			ZhangBen.she_jing_yan_jia_cheng(1.0 + ka.shu_zhi)
		"ci_xi_fanwei":      # 磁吸：step-02 实现双 Area2D
			push_warning("磁吸卡第 2 步实现（step-01 占位）")
		_:
			# 字符串键没有编译期校验：拼错不走 match 任何分支，静默失效最难查——必留兜底
			push_warning("未知强化效果键: " + ka.xiao_guo)
```

> 注意：Godot 4 的 `match` 即 switch；六张卡效果全部读 `ka.shu_zhi`，不写死数值。

### 5.3 Yu.tscn 双 Area2D（step-02：磁吸，学生提案兑现）

```
Yu (Node2D)
├─ Sprite2D
├─ ShangQu (Area2D)          ← 原 PandingQu 改名（吃/伤判定职责不变）
│  └─ CollisionShape2D (CircleShape r=22)
├─ ChiQu (Area2D)            ← 新增：吸附标记圈
│  └─ CollisionShape2D (CircleShape r≈90)
└─ WudiDingshi (Timer)
```

两个 Area2D 均 Layer=1、Mask=2（同第 3 课约定）；yu.gd 里 `$PandingQu` 引用同步改 `$ShangQu`。

```gdscript
# yu.gd 追加：
@onready var chi_qu: Area2D = $ChiQu  # 吸附圈：只打标记，判定仍是 ShangQu 的事

func _on_chi_qu_entered(qu: Area2D) -> void:
	var yu_npc := qu.get_parent() as YuNpc
	if yu_npc != null and tixing > yu_npc.tixing:
		yu_npc.bei_xi = self  # 打得过的小鱼：打吸附标记

func _on_chi_qu_exited(qu: Area2D) -> void:
	var yu_npc := qu.get_parent() as YuNpc
	if yu_npc != null:
		yu_npc.bei_xi = null  # 出圈放手：不吸一辈子
```

磁吸卡生效：`"ci_xi_fanwei"` 分支改为 `chi_qu.get_node("CollisionShape2D").scale *= Vector2.ONE * (1.0 + ka.shu_zhi)`。

### 5.4 scripts/yu_npc.gd（被吸追踪：NPC 自决）

```gdscript
var bei_xi: Yu = null  # 吸附目标（玩家 ChiQu 打的标记；非空 = 被吸中）

# _process 改为：
func _process(delta: float) -> void:
	if bei_xi != null:
		# 被吸中：朝玩家游（吸力略快于自身游速）
		position = position.move_toward(bei_xi.global_position, sudu * 1.2 * delta)
		$Sprite2D.flip_h = bei_xi.global_position.x < position.x
	else:
		# 原直线游动 + 出屏回收（零改动）
		position.x += fangxiang * sudu * delta
	$Sprite2D.flip_h = ...  # 见上，按分支设置
	var pingmu_kuan := get_viewport_rect().size.x
	if position.x < -bianju or position.x > pingmu_kuan + bianju:
		queue_free()
```

bei_xi 挂的是玩家引用——玩家整局不销毁，无需担心悬空引用。

### 5.5 yu.gd Tween 动画（step-03/04）

```gdscript
# step-03 升级平滑长大（替换 _on_sheng_ji 里的瞬间 scale 赋值）：
func _on_sheng_ji(_xin_deng_ji: int) -> void:
	tixing += ZhangBen.MEI_JI_TIXING + mei_ji_fu_dian  # 数值即时到位（判定立即用新值）
	var tween := create_tween()  # 显示层：0.3 秒平滑长到新体型
	tween.tween_property(self, "scale", Vector2.ONE * tixing, 0.3).set_ease(Tween.EASE_OUT)

# step-03 吞吃脉冲（_on_panding_qu_entered 吃鱼分支追加调用）：
func _tun_chi_maichong() -> void:
	var tween := create_tween().set_parallel(false)  # 链式：先弹大再回弹
	tween.tween_property(self, "scale", Vector2.ONE * tixing * 1.08, 0.08)
	tween.tween_property(self, "scale", Vector2.ONE * tixing, 0.12)

# step-04 摆尾（_process 内，游动时才摆）：
var bai_shi_jian := 0.0  # 摆尾相位时钟

# _process 游动分支：
bai_shi_jian += delta
$Sprite2D.rotation = sin(bai_shi_jian * 10.0) * 0.12 / tixing  # 大鱼摆得慢（体型反比）
# 到达目标点分支：$Sprite2D.rotation = 0（静止不摆）
```

## 六、分步实现顺序

1. **step-01**：buff 生效系统——yu.gd 监听 ka_yi_xuan + match 六分支（磁吸占位 push_warning）+ zhang_ben.gd 倍率 + bei_chi 乘算（F5 五卡可感知）
2. **step-02**：磁吸双 Area2D——PandingQu 改名 ShangQu + 新增 ChiQu + bei_xi 自追（F5 磁吸可视化 + 改名回归）
3. **step-03**：Tween 一——升级平滑长大 + 吞吃脉冲（F5 动画可见）
4. **step-04**：Tween 二——摆尾 + 参数调优 + 全量回归

每步跑 `--headless --import` + `--fixed-fps 60 --quit-after 360`，**输出经 grep 筛查 error/not found**（TASK-006 教训：不信任裸退出码）。

## 七、验证计划

### 自动化

- `"$GODOT_BIN" --version` 输出 4.7.x
- `"$GODOT_BIN" --headless --path . --import` 退出码 0（每步）
- `"$GODOT_BIN" --headless --path . --fixed-fps 60 --quit-after 360` 输出筛查零命中
- `PYTHONUTF8=1 python .../check_task_scope.py check docs/development_tasks/TASK-007_qianghua_shengxiao` 无违例

### 手动（学生主导）

- 六卡逐张感知：迅捷快/催肥增幅大/贪食圈大/活力无敌长/睿智涨条快/磁吸会吸
- 磁吸行为边界：吸小鱼不吸大鱼、出圈放手、被吸中照常能被吃
- 三动画：平滑长大/吞吃脉冲/摆尾；暂停期间动画冻结正确
- 全量回归：六课行为 + 升级弹窗闭环

## 八、故障排查提示

| 现象 | 优先检查 |
|---|---|
| 选卡毫无效果 | _on_ka_yi_xuan 是否连接（远程树下断点/print）；xiao_guo 拼写是否与 .tres 一致（看 Output 有无 push_warning） |
| 部分卡生效部分不生效 | match 分支键名与 .tres 的 xiao_guo 逐字比对（大小写敏感） |
| 磁吸大圈不吸 | ChiQu 的 Mask 是否=2（监视鱼群）；area_entered 连接是否写好；小鱼是否其实打不过（只吸 tixing 更小的） |
| 鱼被吸走后再也不放手 | area_exited 是否清 bei_xi；玩家跑太快出圈时 exited 必触发 |
| 改名后吃/伤判定失效 | yu.gd 的 $PandingQu 是否同步改 $ShangQu；场景里节点名是否真改了（大小写） |
| 升级动画和吞吃脉冲打架 | 脉冲 0.08s 很短；若升级瞬间连续吃鱼，脉冲 tween 结束值以当前 tixing 为准——每次 tween 都以 tixing 收尾不会漂移 |
| 暂停时动画还在跑 | Tween 默认随节点 process_mode 冻结——若没冻结，检查是否误建在别的节点上 |
| 睿智不涨条 | bei_chi 是否乘了 jing_yan_jia_cheng；int() 截断（fenzhi 1 × 1.25 = 1.25 → int = 1）——低分鱼感知弱，吃高分鱼对比 |

## 九、范围边界

- 白名单以 `TASK_MANIFEST.json` 为准；未登记文件一律不改
- zhang_ben.gd 只允许一处新增（jing_yan_jia_cheng + setter），jia_jing_yan/xuan_ka/旧信号/MEI_JI_TIXING 零碰
- yu_npc.gd 的生成/回收逻辑零改动；yu_qun.gd 全程零碰
- 零新增资源文件：动画全为运行时 Tween/sin，无 AnimationPlayer、无新贴图

## 十、审批

等待用户明确回复「确认 TASK-007 v1 进入开发」后：捕获实现基线 → orientation 检查点（含两项复述抽查 + 两个设计决策）→ 开始 step-01。
