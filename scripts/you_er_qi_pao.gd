extends Node2D
class_name YouErQiPao
# 诱饵气泡：主动「诱饵气泡」吐出的常驻目标。
# 本体只负责“活着、漂着、被咬破时演出”；吸引谁、谁去咬，由 YuNpc 的目标选择负责。
const KUANG: SpriteFrames = preload("res://data/donghua/you_er_qi_pao_4zhen.tres")
const TE_XIAO := preload("res://scripts/te_xiao.gd")
const PIAO_SU := 8.0  # 上浮速度（像素/秒）：让气泡看起来是“活的”

var chi_xu := 3.0  # 存在时长（秒）：施放时从能力表读
var ban_jing := 360.0  # 吸引半径（世界像素）：NPC 只在这个圈里被吸过来
var zha_yun := false  # 满档：被咬破时炸晕咬它的鱼
var sheng_yu := 3.0  # 剩余寿命（秒）
# 孔雀幻影：不是气泡，而是「长得像玩家」的假鱼；被咬时把毒/掉肉结算回真身
var wei_zhuang_frames: SpriteFrames = null  # 伪装用的鱼动画帧（空 = 原气泡外观）
var wei_zhuang_anim: StringName = &"you"
var huan_ying_zhu = null  # 真身（玩家）：被咬时回调它统一结算
var huan_ying_du := 0.0  # 咬幻影的 NPC 吃多少毒晕
var huan_ying_diao_rou := 0.0  # 咬幻影的 NPC 掉多少级体型
var bu_shang_fu := false  # 幻影不随水泡上浮

var _biao: AnimatedSprite2D
var _po_le := false


func _ready() -> void:
	add_to_group("you_er_qi_pao")  # NPC 与测试都按组找，不靠节点名
	z_index = 5  # 盖在鱼上面：玩家一眼能看到诱饵
	sheng_yu = maxf(0.1, chi_xu)
	_biao = AnimatedSprite2D.new()
	if wei_zhuang_frames != null and wei_zhuang_frames.has_animation(wei_zhuang_anim) \
			and wei_zhuang_frames.get_frame_count(wei_zhuang_anim) > 0:
		# 孔雀幻影：直接套玩家当前的鱼动画，NPC 眼里就是另一条“玩家”
		_biao.sprite_frames = wei_zhuang_frames
		_biao.play(wei_zhuang_anim)
		_biao.modulate = Color(0.7, 0.9, 1.0, 0.6)
		add_child(_biao)
		return
	# 常驻阶段只循环前两帧（生成 / 上浮诱惑）：后两帧是“被咬破”，留给一次性爆破特效
	var piao := SpriteFrames.new()
	piao.add_animation(&"piao")
	piao.set_animation_speed(&"piao", 4.0)
	piao.set_animation_loop(&"piao", true)
	piao.add_frame(&"piao", KUANG.get_frame_texture(&"bao", 0))
	piao.add_frame(&"piao", KUANG.get_frame_texture(&"bao", 1))
	_biao.sprite_frames = piao
	_biao.play(&"piao")
	add_child(_biao)


func _process(delta: float) -> void:
	sheng_yu = maxf(0.0, sheng_yu - delta)
	if not bu_shang_fu:
		position.y -= PIAO_SU * delta  # 慢慢上浮：不是钉在原地的图标
	if sheng_yu <= 0.0:
		po(null)


func bei_yao(yu) -> void:
	# 被 NPC 咬破：播完整四帧爆破；满档顺手炸晕咬它的鱼
	# 孔雀幻影：咬中的 NPC 统一由真身结算（毒晕 + 掉肉），同一目标只吃一次
	if _po_le:
		return
	_po_le = true
	TE_XIAO.you_er_qi_pao(get_parent(), global_position)
	if huan_ying_zhu != null and is_instance_valid(huan_ying_zhu) \
			and huan_ying_zhu.has_method("_kong_que_ying_bei_yao"):
		huan_ying_zhu._kong_que_ying_bei_yao(yu, huan_ying_du, huan_ying_diao_rou)
	elif zha_yun and yu != null and is_instance_valid(yu) and yu.has_method("jia_du_yun"):
		yu.jia_du_yun(ZhangBen.KONG_ZHI_SHANG_XIAN)
	queue_free()


func po(yu = null) -> void:
	# 到期 / 被咬破共用出口：没被咬也播一次破裂，避免气泡凭空消失
	bei_yao(yu)
