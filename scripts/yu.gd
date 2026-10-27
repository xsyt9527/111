extends Node2D
class_name Yu
# 玩家鱼：移动规则 + 大吃小判定都在这里

@export var yidong_sudu := 300.0  # 移动速度，像素/秒

const TUN_CHI_BEI_LV := 1.1  # 吞噬门槛：体型至少大 10% 才能整吞；中间带留给下一课咬击
const SHANG_HAI_BEI_LV := 0.85  # 受伤一次体型乘以它（1.0 → 0.85 → 0.72 …）
const TI_XING_SI_WANG := 0.5  # 体型跌破它即死亡（约连撞 5 次）

var fang_xiang := Vector2.ZERO  # 摇杆方向（单位向量），由 Main 每帧写入；零向量 = 松手
var dang_qian_jiao := 0.0  # 当前朝向角（弧度）：点可以瞬间改，朝向只能一点点拧
var dang_qian_su_du := 0.0  # 当前实际速度（像素/秒）：松手后平滑减到 0

@export var zhuanxiang_ji_su := 4.0  # 转向基准速率（弧度/秒）；实际速率 = 基准 / 体型
@export var jia_su_du := 900.0  # 速度趋近目标值的加速度（像素/秒²）

var tixing := 1.0  # 玩家体型系数（第 5 课成长会增大它，能吃的鱼随之变多）
var wudi := false  # 受伤后的短暂无敌标记
var mei_ji_fu_dian := 0.0  # 催肥：每级体型额外增幅（叠在 MEI_JI_TIXING 上）
var bai_shi_jian := 0.0  # 摆尾相位时钟：游动时累积，驱动 sin 摆动

@onready var zui_qu: Area2D = $ZuiQu  # 嘴圈（吃）：够大才吞——收益的唯一入口
@onready var shang_qu: Area2D = $ShangQu  # 伤区（伤）：对方 ≥ 我 ×1.1 才掉体型——代价的唯一入口
@onready var chi_qu: Area2D = $ChiQu  # 吸附区（磁吸）：只打标记，判定不归它管——分行为须分 Area2D
@onready var wudi_dingshi: Timer = $WudiDingshi  # 无敌计时器


func _ready() -> void:
	dang_qian_jiao = 0.0  # 开局朝右（贴图默认方向）
	zui_qu.area_entered.connect(_on_zui_qu_entered)
	shang_qu.area_entered.connect(_on_shang_qu_entered)
	chi_qu.area_entered.connect(_on_chi_qu_entered)
	chi_qu.area_exited.connect(_on_chi_qu_exited)
	wudi_dingshi.timeout.connect(_jiechu_wudi)
	ZhangBen.sheng_ji.connect(_on_sheng_ji)  # 听账本升级广播：升级就长大
	ZhangBen.ka_yi_xuan.connect(_on_ka_yi_xuan)  # 听账本选卡广播：选卡就生效（预埋信号第一个消费者）


func _process(delta: float) -> void:
	# 速度层：有方向就加速到 yidong_sudu，松手就平滑减到 0（速度 × delta 保证不同帧率一致）
	var mu_biao_su_du := yidong_sudu if fang_xiang != Vector2.ZERO else 0.0
	dang_qian_su_du = move_toward(dang_qian_su_du, mu_biao_su_du, jia_su_du * delta)

	# 转向层：有输入才拧朝向；大鱼（tixing 大）拧得慢，小鱼灵活
	if fang_xiang != Vector2.ZERO:
		dang_qian_jiao = _zhuan_xiang(dang_qian_jiao, fang_xiang.angle(), delta)

	# 位移层：永远沿着"当前朝向"游，而不是直接朝摇杆方向瞬移
	if dang_qian_su_du > 0.1:
		position += Vector2.RIGHT.rotated(dang_qian_jiao) * dang_qian_su_du * delta
		_xian_zhi_zai_ping_mu_nei()

	# 鱼头朝向当前朝向（贴图默认朝右，朝左时水平翻转）
	$Sprite2D.flip_h = cos(dang_qian_jiao) < 0.0
	# 摆尾：sin 周期驱动，速度越快摆得越起劲；摆幅与体型反比（大鱼稳重）
	bai_shi_jian += delta
	var bai_fu := 0.12 / maxf(tixing, 0.2) * clampf(dang_qian_su_du / maxf(yidong_sudu, 1.0), 0.0, 1.0)
	$Sprite2D.rotation = sin(bai_shi_jian * 10.0) * bai_fu


func _zhuan_xiang(dang_qian: float, mu_biao: float, delta: float) -> float:
	# 朝目标角一点点拧过去：差角取最短方向（避免绕远路），每帧步长 = 转向速率 × delta
	var cha := wrapf(mu_biao - dang_qian, -PI, PI)
	var bu_chang := (zhuanxiang_ji_su / maxf(tixing, 0.2)) * delta  # 体型越大，步长越小
	return dang_qian + clampf(cha, -bu_chang, bu_chang)


func _xian_zhi_zai_ping_mu_nei() -> void:
	# 别游出屏幕：留 30 像素边距（约半个鱼身），防止摇杆把鱼送到画面外
	var ping_mu := get_viewport_rect().size
	var bian_ju := 30.0
	position.x = clampf(position.x, bian_ju, ping_mu.x - bian_ju)
	position.y = clampf(position.y, bian_ju, ping_mu.y - bian_ju)


func _on_zui_qu_entered(qu: Area2D) -> void:
	# 闯进嘴圈：只管吃（收益的唯一入口）。比我大的进嘴圈直接无视——掉血归伤区管
	var yu_npc := qu.get_parent() as YuNpc
	if yu_npc == null:
		return
	# 吞噬门槛：我要比它大 10% 才吞得下；同体型/略大略小都吞不动（咬击带，TASK-012 兑现）
	if tixing >= yu_npc.tixing * TUN_CHI_BEI_LV:
		yu_npc.bei_chi()  # 够大：吃（无敌期照样能吃——吃与伤分家后互不阻塞）
		_tun_chi_maichong()  # 吞吃反馈：玩家轻弹一下


func _on_shang_qu_entered(qu: Area2D) -> void:
	# 闯进伤区：只管掉体型（代价的唯一入口）。吃逻辑已移嘴圈；无敌期内跳过，不重复伤
	var yu_npc := qu.get_parent() as YuNpc
	if yu_npc == null:
		return  # 不是鱼群（将来可能有别的区域闯进来），直接忽略
	# 对方要大到能吞我（它 ≥ 我 ×1.1）才伤得到；中间带同样无事发生
	if yu_npc.tixing >= tixing * TUN_CHI_BEI_LV and not wudi:
		_shoushang()


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
	# 受伤统一入口：闪红 + 无敌 + 掉体型（TASK-011：体型即血量，独立血条退役）
	wudi = true
	modulate = Color(1.0, 0.4, 0.4)  # 闪红示警
	wudi_dingshi.start()
	tixing *= SHANG_HAI_BEI_LV  # 数值立刻生效：吞噬/受伤判定马上用新体型
	_shou_shang_tween()  # 显示层平滑缩一圈
	if tixing < TI_XING_SI_WANG:
		_si_wang()


func _shou_shang_tween() -> void:
	# 受伤缩体：0.25 秒缩到新体型（与升级长大同一套显示/状态分离思路）
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * tixing, 0.25).set_ease(Tween.EASE_OUT)


func _si_wang() -> void:
	# 体型跌破死亡线：切结算页。change_scene_to_file 整场景销毁重建——
	# Main 全树（玩家 buff/bei_xi 标记/鱼群/弹窗）就地释放，账本（Autoload）常驻带走数据
	get_tree().change_scene_to_file("res://scenes/JieSuan.tscn")


func _jiechu_wudi() -> void:
	wudi = false
	modulate = Color.WHITE  # 恢复原色


func _on_sheng_ji(_xin_deng_ji: int) -> void:
	# 升级长大：tixing 数值即时到位（大小判定立刻用新值），显示层用 Tween 平滑长过去
	# 催肥的 mei_ji_fu_dian 在这里叠加（第 7 课 buff 生效）
	tixing += ZhangBen.MEI_JI_TIXING + mei_ji_fu_dian
	var tween := create_tween()  # 显示与状态分离：0.8 秒平滑长大，替换瞬间跳变
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
		"tun_shi_fanwei":  # 贪食：嘴圈形状放大（随根 scale 再乘）——身圈不动，只放大收益不放大代价
			$ZuiQu/CollisionShape2D.scale *= Vector2.ONE * (1.0 + ka.shu_zhi)
		"wudi_shi_chang":  # 活力：无敌计时器时长乘 (1+shu_zhi)
			wudi_dingshi.wait_time *= 1.0 + ka.shu_zhi
		"jing_yan_jia_cheng":  # 睿智：倍率入账本（bei_chi 乘算）
			ZhangBen.she_jing_yan_jia_cheng(1.0 + ka.shu_zhi)
		"ci_xi_fanwei":  # 磁吸：吸附圈形状放大（判定圈不动——两个圈各管各的）
			chi_qu.get_node("CollisionShape2D").scale *= Vector2.ONE * (1.0 + ka.shu_zhi)
		_:
			# 未知键兜底：选了卡但没效果时，Output 面板立刻能看到原因
			push_warning("未知强化效果键: " + ka.xiao_guo)
