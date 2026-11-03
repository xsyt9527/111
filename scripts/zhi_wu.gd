extends KeChiWu
class_name ZhiWu
# 可食用植物：海草 / 珊瑚（策划案第十章「可食用植物」）
# 体型来源之一：玩家吃了加经验 → 升级 → 体型 +1；被吃后进重生期，过一会儿再长出来
# 贴图与经验由生成器在 add_child 前注入；碰撞形状按贴图尺寸自动算

const CHONG_SHENG_MIAO := 25.0  # 吃掉后多久重新长出来（秒）
const DONG_HUA_MING := &"bai"   # 摆动动画：4 帧循环（data/donghua/*_4zhen.tres）
const PENG_ZHUANG_BI := 0.55    # 碰撞半径 = 帧短边 × 显示比例 × 这个系数

@export var xian_shi_bi := 0.5  # 显示比例：海草 0.5、珊瑚 0.38（生成器按植株类型注入）
@onready var chong_sheng: Timer = $ChongSheng
@onready var dong_hua: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("zhi_wu")  # 测试/统计按组找，不靠节点名
	collision_layer = 4  # 与鱼肉同层：玩家与 NPC 的 RouQu 都认 layer 4
	collision_mask = 0
	ke_chi = true  # 植物没有保护期：长着就能吃
	chong_sheng.timeout.connect(_chong_sheng)
	dong_hua.scale = Vector2.ONE * xian_shi_bi  # 统一显示比例，视觉大小一致
	var tie := _dang_qian_zhen()
	if tie != null:
		var ban_jing := minf(tie.get_width(), tie.get_height()) * xian_shi_bi * PENG_ZHUANG_BI
		var yuan := CircleShape2D.new()  # 每个植株独立形状：别改到场景里共享的 sub_resource
		yuan.radius = ban_jing
		$CollisionShape2D.shape = yuan
	# 进树就播摆动；测试若没挂动画，则安静跳过（碰撞保留场景默认值）
	if dong_hua.sprite_frames != null and dong_hua.sprite_frames.has_animation(DONG_HUA_MING):
		dong_hua.play(DONG_HUA_MING)
	super._ready()  # 基类按本体当前帧配红光层：放在最后，比例/动画都已定


func _dang_qian_zhen() -> Texture2D:
	# 取当前动画帧的贴图：碰撞半径按这一帧的实际像素算，不再读静态贴图
	if dong_hua.sprite_frames == null:
		return null
	if not dong_hua.sprite_frames.has_animation(dong_hua.animation):
		return null
	return dong_hua.sprite_frames.get_frame_texture(dong_hua.animation, dong_hua.frame)


func bei_chi() -> void:
	# 被吃：不生灭节点，藏起来等重生——地图上的株位是固定的，鱼群记忆不会错位
	if not ke_chi:
		return
	ke_chi = false
	dong_hua.visible = false
	dong_hua.stop()  # 隐身期间不空转；重生时从第 1 帧重新摆
	chong_sheng.start(CHONG_SHENG_MIAO)


func _chong_sheng() -> void:
	ke_chi = true
	dong_hua.visible = true
	if dong_hua.sprite_frames != null and dong_hua.sprite_frames.has_animation(DONG_HUA_MING):
		dong_hua.play(DONG_HUA_MING)
