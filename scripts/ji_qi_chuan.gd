extends Node2D
class_name JiQiChuan
# 人类机器船（TASK-017 终局）：8 分钟（或鲸鲨提前开战）后降临，玩家咬弱点把它打沉
# 它和鱼群不是一家：不继承 YuNpc，只实现玩家咬击要用的最小契约
# （tixing / si_le / qu_dian / shou_dao_yao_ji），让 Yu 的自动咬击原样锁定它

signal bei_ji_bai  # 船被打沉：Main 据此判胜

const ZUI_DA_XUE := 360.0         # 血量：2026-11-02 用户再拍板：人类太弱，血量再 ×2（180→360）
const RUO_DIAN_BEI_LV := 3.0      # 弱点（玻璃舱）伤害倍率
const GEN_SUI_SU_DU := 90.0       # 横向跟随玩家的速度（px/秒）：慢到玩家能绕到侧面
const XUAN_FU_GAO_DU := 240.0     # 悬停在玩家上方多高
const GONG_JI_JIAN_GE := 1.0      # 两次攻击的间隔（秒）：2026-11-02 用户再拍板，9.0→1.0 变成高频压迫
const YU_WANG_BAN_JING := 100.0   # 渔网预警圈半径：0.45 秒 × 300 速 ≈ 135px，半径 100 才留得出躲位
const YU_WANG_YU_JING := 0.45     # 渔网预警时长：1 秒一击下仍保留 0.45 秒可躲窗口
const YU_WANG_KONG_ZHI := 1.5     # 渔网命中后的失控时长
const XIE_BI_SHI_CHANG := 0.45    # 机械臂伸出耗时：与渔网统一 0.45 秒前摇，玩家看得见也躲得开
const XIE_BI_SHANG_HAI := 1.0     # 机械臂伤害（走玩家现有受伤/无敌帧流程）
const XIE_BI_BAN_JING := 90.0     # 机械臂落点的判定半径：躲开就不掉血

var zui_da_xue := ZUI_DA_XUE  # 上限也做成变量：Main 的血条直接读，不必知道常量
var xue := ZUI_DA_XUE
var tixing := 99.0  # 鸭子类型契约：体型 99 → 玩家永远吞不掉，只能一口口咬
var si_le := false  # 鸭子类型契约：死亡后玩家不再锁定
var wan_jia: Yu = null  # 玩家引用：由 Main 生成时注入（不靠组名，测试也好塞假人）

var _zhua: Node2D
var _chuan_ti: AnimatedSprite2D
var _gong_ji_dingshi: Timer
var _gong_ji_lun := 0  # 攻击轮次：偶数渔网、奇数机械臂
var _yu_wang_dian := Vector2.ZERO  # 渔网落点（放招瞬间的玩家位置）
var _yu_wang_jin_xing := false
var _yu_wang_sheng_yu := 0.0
var _zheng_zai_chu_zhao := false  # 防重叠：上一招还在前摇/结算时，本轮定时器直接跳过，绝不会叠出两条网/两只臂


func _ready() -> void:
	_chuan_ti = $ChuanTi
	_zhua = $Zhua
	_chuan_ti.play(&"dong")  # 4 帧潜艇推进动画（场景 autoplay 也开了，这里显式写清意图）
	$Zhua/ZhuaTi.play(&"dong")  # 机械臂伸出时也在动，不像一张贴图平移
	_gong_ji_dingshi = $GongJiDingshi
	_gong_ji_dingshi.timeout.connect(_on_gong_ji_timeout)
	_gong_ji_dingshi.start(GONG_JI_JIAN_GE)  # 降临后 1 秒首次出招（与后续间隔读同一常量，避免两处数字打架）


func _process(delta: float) -> void:
	if si_le or wan_jia == null or not is_instance_valid(wan_jia):
		return
	# 慢速跟随：横向追玩家、纵向吊在玩家上方——玩家往上顶才能咬到玻璃舱
	position.x = move_toward(position.x, wan_jia.position.x, GEN_SUI_SU_DU * delta)
	position.y = clampf(wan_jia.position.y - XUAN_FU_GAO_DU, 90.0, 2150.0)
	_geng_xin_yu_wang(delta)


func qu_dian(bu: String) -> Vector2:
	# 鸭子类型契约：部位坐标——玻璃舱在上方（弱点），船体在下方（普通伤害）
	match bu:
		"zhi_ming":
			return global_position + Vector2(0, -20)
		_:
			return global_position + Vector2(0, 70)


func shou_dao_yao_ji(shang_hai: float, _lai_yuan = null, bu := "shen") -> void:
	# 鸭子类型契约：玩家咬一口。咬玻璃舱 ×3，咬船体 ×1
	if si_le:
		return
	var xi_shu := RUO_DIAN_BEI_LV if bu == "zhi_ming" else 1.0
	xue = maxf(0.0, xue - shang_hai * xi_shu)
	_shan_guang()
	if xue <= 0.0:
		_chen_mo()


func _shan_guang() -> void:
	# 受击反馈：贴图闪一下暖白，玩家能确认“咬中了”
	_chuan_ti.modulate = Color(1.6, 1.3, 1.0)
	var bu_jian := create_tween()
	bu_jian.tween_property(_chuan_ti, "modulate", Color.WHITE, 0.15)


func _chen_mo() -> void:
	# 打沉：关碰撞、停攻击、广播胜利，再沉下去淡出
	si_le = true
	_gong_ji_dingshi.stop()
	$SheDingQu.collision_layer = 0
	$ChuanTiQu.collision_layer = 0
	_zhua.visible = false
	_yu_wang_jin_xing = false
	_zheng_zai_chu_zhao = false
	queue_redraw()
	bei_ji_bai.emit()
	var bu_jian := create_tween()
	bu_jian.set_parallel(true)
	bu_jian.tween_property(self, "rotation", 0.35, 2.0)
	bu_jian.tween_property(self, "position:y", position.y + 260.0, 2.0)
	bu_jian.tween_property(_chuan_ti, "modulate:a", 0.0, 2.0)
	bu_jian.chain().tween_callback(queue_free)


func _on_gong_ji_timeout() -> void:
	# 两招交替：渔网（控制）→ 机械臂（伤害）→ 渔网……
	# 防重叠：1 秒间隔短于“出招 + 收招”总时长时，若上一招未收完就跳过本轮（不推进轮次、也不排队），
	# 等下一次定时器再出招——实现最简单，且保证场上最多只有一条网/一只机械臂。
	if si_le:
		return
	if _zheng_zai_chu_zhao:
		_gong_ji_dingshi.start(GONG_JI_JIAN_GE)
		return
	# 失控保护：渔网控住 1.5 秒，而攻击间隔只有 1 秒——玩家还没恢复就出下一招，
	# 必然接成「控住→机械臂必中」的连段。失控期间整拍跳过，等玩家能动了再出招。
	if ZhangBen.zai_kong_zhi():
		_gong_ji_dingshi.start(GONG_JI_JIAN_GE)
		return
	if _gong_ji_lun % 2 == 0:
		_kai_shi_yu_wang()
	else:
		_kai_shi_xie_bi()
	_gong_ji_lun += 1
	_gong_ji_dingshi.start(GONG_JI_JIAN_GE)


func _kai_shi_yu_wang() -> void:
	# 渔网：先在玩家当前位置画预警圈，0.45 秒后才落网——不追人，只封走位
	if wan_jia == null:
		return
	_zheng_zai_chu_zhao = true
	_yu_wang_dian = wan_jia.global_position
	_yu_wang_jin_xing = true
	_yu_wang_sheng_yu = YU_WANG_YU_JING
	queue_redraw()


func _geng_xin_yu_wang(delta: float) -> void:
	if not _yu_wang_jin_xing:
		return
	_yu_wang_sheng_yu -= delta
	queue_redraw()
	if _yu_wang_sheng_yu <= 0.0:
		_jie_suan_yu_wang()


func _jie_suan_yu_wang() -> void:
	# 落网：还在圈里就失控（停游/停咬/停吃），跑出去就没事
	_yu_wang_jin_xing = false
	_zheng_zai_chu_zhao = false  # 网已结算，允许下一招
	queue_redraw()
	if wan_jia != null and wan_jia.global_position.distance_to(_yu_wang_dian) <= YU_WANG_BAN_JING:
		ZhangBen.qiang_zhi_kong_zhi(YU_WANG_KONG_ZHI)


func _draw() -> void:
	# 预警圈画在船的本地下层：越接近落点越亮，玩家不用看数字也能判断时机
	if not _yu_wang_jin_xing:
		return
	var ju_li := to_local(_yu_wang_dian)
	var jin_du := 1.0 - _yu_wang_sheng_yu / YU_WANG_YU_JING
	draw_circle(ju_li, YU_WANG_BAN_JING, Color(0.35, 0.8, 1.0, 0.10 + 0.10 * jin_du))
	draw_arc(ju_li, YU_WANG_BAN_JING, 0.0, TAU, 64, Color(0.45, 0.9, 1.0, 0.35 + 0.45 * jin_du), 3.0)


func _kai_shi_xie_bi() -> void:
	# 机械臂：从船底伸向玩家“此刻”的位置（0.45 秒），落点固定——会走位就能躲
	if wan_jia == null:
		return
	_zheng_zai_chu_zhao = true
	_zhua.visible = true
	_zhua.global_position = global_position + Vector2(0, 250)
	var mu_biao := wan_jia.global_position
	var bu_jian := create_tween()
	bu_jian.tween_property(_zhua, "global_position", mu_biao, XIE_BI_SHI_CHANG).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	bu_jian.tween_callback(_jie_suan_xie_bi)


func _jie_suan_xie_bi() -> void:
	if si_le:
		return
	if wan_jia != null and wan_jia.global_position.distance_to(_zhua.global_position) <= XIE_BI_BAN_JING:
		wan_jia.shou_dao_yao_ji(XIE_BI_SHANG_HAI)  # 走玩家现有受伤入口：无敌帧、掉肉都照旧
	var bu_jian := create_tween()
	bu_jian.tween_property(_zhua, "global_position", global_position + Vector2(0, 250), 0.4)
	bu_jian.tween_callback(_shou_bi_wan_cheng)


func _shou_bi_wan_cheng() -> void:
	# 收臂结束才解锁，避免上一招的收臂回调把新伸出的机械臂藏掉
	_zhua.visible = false
	_zheng_zai_chu_zhao = false
