extends KeChiWu
class_name ZhiWu
# 可食用植物：海草 / 珊瑚（策划案第十章「可食用植物」）
# 体型来源之一：玩家吃了加经验 → 升级 → 体型 +1；被吃后进重生期，过一会儿再长出来
# 贴图与经验由生成器在 add_child 前注入；碰撞形状按贴图尺寸自动算

const CHONG_SHENG_MIAO := 25.0  # 吃掉后多久重新长出来（秒）
const XIAN_SHI_BI := 0.5        # 贴图显示比例（源图约 110×192 → 55×96）
const PENG_ZHUANG_BI := 0.55    # 碰撞半径 = 贴图短边 × 显示比例 × 这个系数

@onready var chong_sheng: Timer = $ChongSheng


func _ready() -> void:
	add_to_group("zhi_wu")  # 测试/统计按组找，不靠节点名
	collision_layer = 4  # 与鱼肉同层：玩家与 NPC 的 RouQu 都认 layer 4
	collision_mask = 0
	ke_chi = true  # 植物没有保护期：长着就能吃
	chong_sheng.timeout.connect(_chong_sheng)
	var tie: Texture2D = $Sprite2D.texture
	if tie != null:
		$Sprite2D.scale = Vector2.ONE * XIAN_SHI_BI  # 统一显示比例，视觉大小一致
		var ban_jing := minf(tie.get_width(), tie.get_height()) * XIAN_SHI_BI * PENG_ZHUANG_BI
		var yuan := CircleShape2D.new()  # 每个植株独立形状：别改到场景里共享的 sub_resource
		yuan.radius = ban_jing
		$CollisionShape2D.shape = yuan
	super._ready()  # 基类按 $Sprite2D 的贴图与比例配红光层：放在最后，比例已定


func bei_chi() -> void:
	# 被吃：不生灭节点，藏起来等重生——地图上的株位是固定的，鱼群记忆不会错位
	if not ke_chi:
		return
	ke_chi = false
	$Sprite2D.visible = false
	chong_sheng.start(CHONG_SHENG_MIAO)


func _chong_sheng() -> void:
	ke_chi = true
	$Sprite2D.visible = true
