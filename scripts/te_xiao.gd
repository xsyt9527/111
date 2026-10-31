extends RefCounted
# 一次性特效生成器：放电 / 中毒共用
# 不挂场景、不做常驻节点：触发时现场建一个 AnimatedSprite2D，播完自己 queue_free
# 调用方只给“挂在谁下面 + 世界坐标 + 大小”，特效帧资源全部在这里收口

const DIAN_TE_XIAO: SpriteFrames = preload("res://data/donghua/dian_texiao_4zhen.tres")
const DU_TE_XIAO: SpriteFrames = preload("res://data/donghua/du_texiao_4zhen.tres")


static func fang_dian(gen: Node, wei: Vector2, bi := 1.0) -> void:
	# 放电圈：电鳐半径 90 → 特效直径约 180 像素，scale 1.0 正好覆盖
	_sheng_chu(gen, DIAN_TE_XIAO, wei, bi)


static func zhong_du(gen: Node, wei: Vector2, bi := 0.55) -> void:
	# 中毒：小一圈的毒雾，只是“被反毒了”的反馈，不表示范围伤害
	_sheng_chu(gen, DU_TE_XIAO, wei, bi)


static func _sheng_chu(gen: Node, kuang: SpriteFrames, wei: Vector2, bi: float) -> void:
	if gen == null or not gen.is_inside_tree():
		return  # 场景切换/测试裸节点：没有父节点可挂就不放特效
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = kuang
	fx.z_index = 5  # 盖在鱼上面：电光 / 毒雾要看得见
	gen.add_child(fx)
	fx.global_position = wei
	fx.scale = Vector2.ONE * bi
	fx.play(&"bao")
	fx.animation_finished.connect(fx.queue_free)  # 播完就销毁：不留下满地空节点
