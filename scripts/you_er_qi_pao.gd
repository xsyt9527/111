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

var _biao: AnimatedSprite2D
var _po_le := false


func _ready() -> void:
	add_to_group("you_er_qi_pao")  # NPC 与测试都按组找，不靠节点名
	z_index = 5  # 盖在鱼上面：玩家一眼能看到诱饵
	sheng_yu = maxf(0.1, chi_xu)
	_biao = AnimatedSprite2D.new()
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
	position.y -= PIAO_SU * delta  # 慢慢上浮：不是钉在原地的图标
	if sheng_yu <= 0.0:
		po(null)


func bei_yao(yu) -> void:
	# 被 NPC 咬破：播完整四帧爆破；满档顺手炸晕咬它的鱼
	if _po_le:
		return
	_po_le = true
	TE_XIAO.you_er_qi_pao(get_parent(), global_position)
	if zha_yun and yu != null and is_instance_valid(yu) and yu.has_method("jia_du_yun"):
		yu.jia_du_yun(ZhangBen.KONG_ZHI_SHANG_XIAN)
	queue_free()


func po(yu = null) -> void:
	# 到期 / 被咬破共用出口：没被咬也播一次破裂，避免气泡凭空消失
	bei_yao(yu)
