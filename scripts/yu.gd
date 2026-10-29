extends Node2D
class_name Yu
# 玩家鱼：移动规则 + 大吃小判定都在这里

@export var yidong_sudu := 300.0  # 移动速度，像素/秒

const TUN_CHI_BEI_LV := 1.1  # 吞噬门槛：体型 ≥ 对方 ×1.1 才能整吞
const DI_TU_DA_XIAO := Vector2(4128, 2304)  # 3×3 拼图世界尺寸（3 × 1376, 3 × 768）
const ROU_KUAI_CHANGJING := preload("res://scenes/RouKuai.tscn")  # 鱼肉块蓝图
const DIAO_ROU_SHU := 2  # 受伤一次掉 2 块（伤害量的临时映射，TASK-012 调参）
const CHI_YU_HUI_XUE := 0.5    # 吃掉一条鱼回半格体型（两三条鱼补回一次受伤）
const CHI_SHI_WU_HUI_XUE := 0.25  # 吃鱼肉/植物回四分之一格：垫底收益，不靠它回满

var fang_xiang := Vector2.ZERO  # 摇杆方向（单位向量），由 Main 每帧写入；零向量 = 松手
var dang_qian_jiao := 0.0  # 当前朝向角（弧度）：点可以瞬间改，朝向只能一点点拧
var dang_qian_su_du := 0.0  # 当前实际速度（像素/秒）：松手后平滑减到 0

@export var zhuanxiang_ji_su := 7.0  # 转向基准速率（弧度/秒）；实际速率 = 基准 ÷ √体型
@export var jia_su_du := 900.0  # 速度趋近目标值的加速度（像素/秒²）

var tixing: float:
	get:
		return ZhangBen.dang_qian_ti_xing  # 体型=当前血量：账本是唯一所有者，玩家不另存一份
var wudi := false  # 受伤后的短暂无敌标记
var bai_shi_jian := 0.0  # 摆尾相位时钟：游动时累积，驱动 sin 摆动

@onready var zui_qu: Area2D = $ZuiQu  # 嘴圈（吃）：够大才吞——收益的唯一入口
@onready var shang_qu: Area2D = $ShangQu  # 伤区（伤）：对方 ≥ 我 ×1.1 才掉体型——代价的唯一入口
@onready var chi_qu: Area2D = $ChiQu  # 吸附区（磁吸）：只打标记，判定不归它管——分行为须分 Area2D
@onready var rou_qu: Area2D = $RouQu  # 鱼肉区（吃鱼肉）：只认 layer 4 的鱼肉块
@onready var wudi_dingshi: Timer = $WudiDingshi  # 无敌计时器


func _ready() -> void:
	dang_qian_jiao = 0.0  # 开局朝右（贴图默认方向）
	scale = _ti_xing_vector()  # 开局体型=开局血量：场景里的 scale 只是编辑器占位
	add_to_group("player")  # NPC 靠这个组找到玩家，判断自己是不是“红光可吃”
	$AnimatedSprite2D.play("you")  # 播 4 帧游动动画（场景里 autoplay 也开了，这里显式写清意图）
	zui_qu.area_entered.connect(_on_zui_qu_entered)
	shang_qu.area_entered.connect(_on_shang_qu_entered)
	chi_qu.area_entered.connect(_on_chi_qu_entered)
	chi_qu.area_exited.connect(_on_chi_qu_exited)
	wudi_dingshi.timeout.connect(_jiechu_wudi)
	# 只连 ti_xing_bian_hua：升级回满、受伤扣血、吃东西回血都会广播它——
	# 一个信号管全部“显示体型变了”，避免和 sheng_ji 两条 tween 抢同一个 scale
	ZhangBen.ti_xing_bian_hua.connect(_on_ti_xing_bian_hua)
	ZhangBen.si_wang.connect(_si_wang)  # 体型（血量）归零：切结算
	ZhangBen.ka_yi_xuan.connect(_on_ka_yi_xuan)  # 听账本选卡广播：选卡就生效（预埋信号第一个消费者）


func _ti_xing_vector() -> Vector2:
	# 体型→缩放向量：走账本的统一换算入口，玩家与 NPC 共用同一条曲线
	return Vector2.ONE * ZhangBen.ti_xing_dao_chi_du(tixing)


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
		_xian_zhi_zai_di_tu_nei()

	# 鱼头朝向当前朝向（贴图默认朝右，朝左时水平翻转）
	# 死区：纯上/下时 cos≈0，浮点符号会把鱼头甩向左边；|cos|<0.15 时保持上一帧朝向
	var heng_xiang := cos(dang_qian_jiao)
	if absf(heng_xiang) > 0.15:
		$AnimatedSprite2D.flip_h = heng_xiang < 0.0
	# 摆尾：sin 周期驱动，速度越快摆得越起劲；摆幅与体型反比（大鱼稳重）
	bai_shi_jian += delta
	var bai_fu := 0.12 / maxf(float(tixing), 0.2) * clampf(dang_qian_su_du / maxf(yidong_sudu, 1.0), 0.0, 1.0)
	$AnimatedSprite2D.rotation = sin(bai_shi_jian * 10.0) * bai_fu
	_chi_rou()  # 每帧查鱼肉区：鱼肉过保护期后即使原地重叠也能被吃（area_entered 不会再发一次）


func _chi_rou() -> void:
	# 吃可食物：鱼肉与海草/珊瑚同一入口（策划案 8.1「任何鱼可进食」+ 第十章可食用植物）
	for qu in rou_qu.get_overlapping_areas():
		var wu := qu as KeChiWu
		if wu != null and wu.ke_chi:
			ZhangBen.jia_jing_yan(wu.jing_yan)  # 先记账再退场：bei_chi 之后节点可能已释放
			ZhangBen.hui_ti_xing(CHI_SHI_WU_HUI_XUE)  # 顺带回一点血：垫底收益，不靠它回满
			ZhangBen.hui_ji_e(wu.ji_e)  # 回饥饿：植物/鱼肉都是「双给」的一部分
			wu.bei_chi()


func _zhuan_xiang(dang_qian: float, mu_biao: float, delta: float) -> float:
	# 朝目标角一点点拧过去：差角取最短方向（避免绕远路），每帧步长 = 转向速率 × delta
	# 除的是 √体型而不是体型：线性太惩罚——Lv.8 会慢到转不动；开根号让小鱼跟手、大鱼仍显笨重
	var cha := wrapf(mu_biao - dang_qian, -PI, PI)
	var bu_chang := (zhuanxiang_ji_su / sqrt(maxf(float(tixing), 1.0))) * delta
	return dang_qian + clampf(cha, -bu_chang, bu_chang)


func _xian_zhi_zai_di_tu_nei() -> void:
	# 别游出九宫格大地图：留 30 像素边距（约半个鱼身），相机 limit 会跟着夹住视野
	var bian_ju := 30.0
	position.x = clampf(position.x, bian_ju, DI_TU_DA_XIAO.x - bian_ju)
	position.y = clampf(position.y, bian_ju, DI_TU_DA_XIAO.y - bian_ju)


func _on_zui_qu_entered(qu: Area2D) -> void:
	# 闯进嘴圈：只管吃（收益的唯一入口）。比我大的进嘴圈直接无视——掉血归伤区管
	var yu_npc := qu.get_parent() as YuNpc
	if yu_npc == null:
		return
	# 吞噬门槛：我要比它大 10% 才吞得下；同体型/略大略小都吞不动（咬击带，TASK-012 兑现）
	var dui_fang_ti_xing := yu_npc.tixing  # 先记下体型：bei_chi 之后节点已释放
	if tixing >= dui_fang_ti_xing * TUN_CHI_BEI_LV:
		yu_npc.bei_chi()  # 够大：吃（无敌期照样能吃——吃与伤分家后互不阻塞）
		_tun_chi_maichong()  # 吞吃反馈：玩家轻弹一下
		ZhangBen.hui_ti_xing(CHI_YU_HUI_XUE)  # 吃条鱼回半格血：受伤后靠吃回来
		ZhangBen.hui_ji_e(ZhangBen.chi_yu_hui_ji_e(dui_fang_ti_xing))  # 回饥饿：路人鱼最顶饱


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
	# 受伤统一入口：闪红 + 无敌 + 扣当前体型（血量）
	# 等级（体型上限）不动——被打只觉得鱼变小了，不会掉级、更不会因为掉级丢进度
	wudi = true
	modulate = Color(1.0, 0.4, 0.4)  # 闪红示警
	wudi_dingshi.start()
	ZhangBen.shou_shang()  # 账本扣血 → ti_xing_bian_hua → 平滑缩小；归零时账本广播 si_wang
	if ZhangBen.dang_qian_ti_xing > 0.0:
		diao_rou(DIAO_ROU_SHU)  # 没死才掉 2 块鱼肉（死亡直接进结算，不铺一地）


func diao_rou(shu: int) -> void:
	# 掉鱼肉：往四周随机方向弹出去，避免和受伤者叠在一起被秒吃
	for i in range(shu):
		var rou: RouKuai = ROU_KUAI_CHANGJING.instantiate()
		var jiao := randf_range(0.0, TAU)
		rou.position = position + Vector2(cos(jiao), sin(jiao)) * randf_range(46.0, 58.0)
		rou.position.x = clampf(rou.position.x, 40.0, DI_TU_DA_XIAO.x - 40.0)
		rou.position.y = clampf(rou.position.y, 40.0, DI_TU_DA_XIAO.y - 40.0)
		# 受伤信号来自物理查询刷新期间，此时直接 add_child(Area2D) 会报
		# "Can't change this state while flushing queries"——物理帧里必须延迟到空闲帧
		if Engine.is_in_physics_frame():
			get_parent().add_child.call_deferred(rou)
		else:
			get_parent().add_child(rou)  # 挂到场景层，不跟玩家一起移动/缩放


func _si_wang() -> void:
	# 体型跌破死亡线：切结算页。change_scene_to_file 整场景销毁重建——
	# Main 全树（玩家 buff/bei_xi 标记/鱼群/弹窗）就地释放，账本（Autoload）常驻带走数据
	get_tree().change_scene_to_file("res://scenes/JieSuan.tscn")


func _jiechu_wudi() -> void:
	wudi = false
	modulate = Color.WHITE  # 恢复原色


func _on_ti_xing_bian_hua(_dang_qian: float, _shang_xian: float) -> void:
	# 显示体型变了（升级回满 / 受伤变小 / 吃东西回血）：账本已是新值，显示层 Tween 追过去
	# 0.25 秒——受伤要立刻看得见“我变小了”，回血也别慢吞吞
	var tween := create_tween()
	tween.tween_property(self, "scale", _ti_xing_vector(), 0.25).set_ease(Tween.EASE_OUT)


func _tun_chi_maichong() -> void:
	# 吞吃瞬间脉冲：链式两段——先快速弹大 8%，再回弹到真实体型（每次都以 tixing 收尾，不漂移）
	var tween := create_tween()
	tween.tween_property(self, "scale", _ti_xing_vector() * 1.08, 0.08)
	tween.tween_property(self, "scale", _ti_xing_vector(), 0.12)


func _on_ka_yi_xuan(ka: QiangHuaKa) -> void:
	# 强化生效中枢：按效果键分发（第 6 课只入账的卡，这里兑现）
	# 数值全读 ka.shu_zhi——改卡数据零代码；键是字符串没有编译期校验，拼错静默失效最难查
	match ka.xiao_guo:
		"yidong_sudu":  # 迅捷：游速乘 (1+shu_zhi)
			yidong_sudu *= 1.0 + ka.shu_zhi
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
