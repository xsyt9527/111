extends Node2D
class_name Yu
# 玩家鱼：移动规则 + 大吃小判定都在这里

@export var yidong_sudu := 300.0  # 移动速度，像素/秒

const TINGZHI_JULI := 5.0  # 到达判定距离（像素）：离目标点这么近就算到了
var mubiao_dian: Vector2  # 游动目标点（世界坐标），由 Main 写入

var tixing := 1.0  # 玩家体型系数（第 5 课成长会增大它，能吃的鱼随之变多）
var wudi := false  # 受伤后的短暂无敌标记
var mei_ji_fu_dian := 0.0  # 催肥：每级体型额外增幅（叠在 MEI_JI_TIXING 上）
var bai_shi_jian := 0.0  # 摆尾相位时钟：游动时累积，驱动 sin 摆动

@onready var shang_qu: Area2D = $ShangQu  # 判定区（原 PandingQu）：吃/伤都归它管
@onready var chi_qu: Area2D = $ChiQu  # 吸附区（磁吸）：只打标记，判定不归它管——分行为须分 Area2D
@onready var wudi_dingshi: Timer = $WudiDingshi  # 无敌计时器


func _ready() -> void:
	mubiao_dian = position  # 开局原地不动
	shang_qu.area_entered.connect(_on_shang_qu_entered)
	chi_qu.area_entered.connect(_on_chi_qu_entered)
	chi_qu.area_exited.connect(_on_chi_qu_exited)
	wudi_dingshi.timeout.connect(_jiechu_wudi)
	ZhangBen.sheng_ji.connect(_on_sheng_ji)  # 听账本升级广播：升级就长大
	ZhangBen.ka_yi_xuan.connect(_on_ka_yi_xuan)  # 听账本选卡广播：选卡就生效（预埋信号第一个消费者）


func _process(delta: float) -> void:
	# 已经到达目标点：原地不动，尾巴回正
	if position.distance_to(mubiao_dian) <= TINGZHI_JULI:
		$Sprite2D.rotation = 0.0
		return
	# 朝目标点前进：速度 × delta 保证不同帧率下游速一致
	position = position.move_toward(mubiao_dian, yidong_sudu * delta)
	# 鱼头朝向游动方向（贴图默认朝右，目标在左侧时水平翻转）
	$Sprite2D.flip_h = mubiao_dian.x < position.x
	# 摆尾：sin 周期驱动尾巴左右轻摆（程序化动画，无关键帧资源）
	bai_shi_jian += delta
	$Sprite2D.rotation = sin(bai_shi_jian * 10.0) * 0.12 / tixing  # 摆幅与体型反比：大鱼摆得稳重


func _on_shang_qu_entered(qu: Area2D) -> void:
	# 闯进判定区的是 NPC 的 Area2D；它的父节点才是 YuNpc 本体
	var yu_npc := qu.get_parent() as YuNpc
	if yu_npc == null:
		return  # 不是鱼群（将来可能有别的区域闯进来），直接忽略
	if tixing > yu_npc.tixing:
		yu_npc.bei_chi()  # 我比它大：吃（无敌期照样能吃）
		_tun_chi_maichong()  # 吞吃反馈：玩家轻弹一下
	elif not wudi:
		_shoushang()  # 它比我大：受伤（无敌期内跳过，不重复伤）


func _on_chi_qu_entered(qu: Area2D) -> void:
	# 小鱼游进吸附大圈：只给它打标记，路让它自己走（设计决策 1A：NPC 自决）
	var yu_npc := qu.get_parent() as YuNpc
	if yu_npc != null and tixing > yu_npc.tixing:
		yu_npc.bei_xi = self  # 打得过的小鱼才吸；大鱼不吸


func _on_chi_qu_exited(qu: Area2D) -> void:
	# 游出吸附圈：放手（不吸一辈子）
	var yu_npc := qu.get_parent() as YuNpc
	if yu_npc != null:
		yu_npc.bei_xi = null


func _shoushang() -> void:
	# 受伤统一入口：第 8 课血量/死亡系统在这里挂钩
	wudi = true
	modulate = Color(1.0, 0.4, 0.4)  # 闪红示警
	wudi_dingshi.start()


func _jiechu_wudi() -> void:
	wudi = false
	modulate = Color.WHITE  # 恢复原色


func _on_sheng_ji(_xin_deng_ji: int) -> void:
	# 升级长大：tixing 数值即时到位（大小判定立刻用新值），显示层用 Tween 平滑长过去
	# 催肥的 mei_ji_fu_dian 在这里叠加（第 7 课 buff 生效）
	tixing += ZhangBen.MEI_JI_TIXING + mei_ji_fu_dian
	var tween := create_tween()  # 显示与状态分离：0.3 秒平滑长大，替换瞬间跳变
	tween.tween_property(self, "scale", Vector2.ONE * tixing, 0.8).set_ease(Tween.EASE_OUT)


func _tun_chi_maichong() -> void:
	# 吞吃瞬间脉冲：链式两段——先快速弹大 8%，再回弹到真实体型（每次都以 tixing 收尾，不漂移）
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * tixing * 1.08, 0.08)
	tween.tween_property(self, "scale", Vector2.ONE * tixing, 0.12)


func _on_ka_yi_xuan(ka: QiangHuaKa) -> void:
	# 强化生效中枢：按效果键分发（第 6 课只入账的卡，这里兑现）
	# 数值全读 ka.shu_zhi——改卡数据零代码；键是字符串没有编译期校验，拼错静默失效最难查
	match ka.xiao_guo:
		"yidong_sudu":  # 迅捷：游速乘 (1+shu_zhi)
			yidong_sudu *= 1.0 + ka.shu_zhi
		"mei_ji_tixing":  # 催肥：每级体型增幅叠加
			mei_ji_fu_dian += ka.shu_zhi
		"tun_shi_fanwei":  # 贪食：判定圈形状放大（随根 scale 再乘）
			$PandingQu/CollisionShape2D.scale *= Vector2.ONE * (1.0 + ka.shu_zhi)
		"wudi_shi_chang":  # 活力：无敌计时器时长乘 (1+shu_zhi)
			wudi_dingshi.wait_time *= 1.0 + ka.shu_zhi
		"jing_yan_jia_cheng":  # 睿智：倍率入账本（bei_chi 乘算）
			ZhangBen.she_jing_yan_jia_cheng(1.0 + ka.shu_zhi)
		"ci_xi_fanwei":  # 磁吸：吸附圈形状放大（判定圈不动——两个圈各管各的）
			chi_qu.get_node("CollisionShape2D").scale *= Vector2.ONE * (1.0 + ka.shu_zhi)
		_:
			# 未知键兜底：选了卡但没效果时，Output 面板立刻能看到原因
			push_warning("未知强化效果键: " + ka.xiao_guo)
