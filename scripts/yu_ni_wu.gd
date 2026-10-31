extends Node2D
class_name YuNiWu
# 淤泥雾团：淤泥弹的落点产物（策划案 8.2 通用能力池）
# NPC 走进雾里感知打折（dang_qian_gan_zhi 按 yu_ni_wu 组实时算）；
# 档 3 起雾里玩家的可见度再打折（wan_jia_yin_bi，被 _wan_jia_gan_zhi 消费）
# 自带寿命：到点自释放，不留残雾；没有专门美术，用 _draw 画两层半透明圆凑合

var ban_jing := 200.0        # 雾半径（世界像素）：施放时从能力表读
var gan_zhi_xi_shu := 0.25   # 雾中 NPC 感知系数（越低越瞎）：档 1~3 共用
var wan_jia_yin_bi := 0.0    # 雾中玩家可见度系数（0 = 无附加；档 3 = 0.5）
var shi_chang := 3.0         # 雾持续（秒）：档 2 起加长


func _ready() -> void:
	add_to_group("yu_ni_wu")
	z_index = 4  # 盖在鱼上面、一次性特效（z_index 5）下面：一眼看出“这是雾”
	var sheng_ming := get_tree().create_timer(maxf(0.1, shi_chang))
	sheng_ming.timeout.connect(queue_free)  # 到点自散；节点先被释放时连接会自动断开
	queue_redraw()


func _draw() -> void:
	# 两层墨绿：外圈淡、内圈浓一点，够玩家看出“哪片是安全视野”
	draw_circle(Vector2.ZERO, ban_jing, Color(0.25, 0.32, 0.18, 0.20))
	draw_circle(Vector2.ZERO, ban_jing * 0.6, Color(0.22, 0.28, 0.16, 0.24))
