extends RefCounted
# 一次性特效生成器：放电 / 中毒 + 8 套专属能力特效
# 不挂场景、不做常驻节点：触发时现场建一个 AnimatedSprite2D，播完自己 queue_free
# 调用方只给“挂在谁下面 + 世界坐标 + 大小”，特效帧资源全部在这里收口

const DIAN_TE_XIAO: SpriteFrames = preload("res://data/donghua/dian_texiao_4zhen.tres")
const DU_TE_XIAO: SpriteFrames = preload("res://data/donghua/du_texiao_4zhen.tres")
# 8 套专属能力特效：动画名统一为 bao、4 帧、12 fps、loop=0（播完即销毁）
const XUAN_WO_TE_XIAO: SpriteFrames = preload("res://data/donghua/xuan_wo_4zhen.tres")
const YU_NI_TE_XIAO: SpriteFrames = preload("res://data/donghua/yu_ni_dan_4zhen.tres")
const SHENG_NA_TE_XIAO: SpriteFrames = preload("res://data/donghua/sheng_na_mai_chong_4zhen.tres")
const YU_LEI_TE_XIAO: SpriteFrames = preload("res://data/donghua/yu_lei_chong_ci_4zhen.tres")
const KUANG_BAO_TE_XIAO: SpriteFrames = preload("res://data/donghua/kuang_bao_si_yao_4zhen.tres")
const NI_LIU_TE_XIAO: SpriteFrames = preload("res://data/donghua/ni_liu_shan_bi_4zhen.tres")
const YING_LIN_TE_XIAO: SpriteFrames = preload("res://data/donghua/ying_lin_fan_ji_4zhen.tres")
const DIAN_GAN_TE_XIAO: SpriteFrames = preload("res://data/donghua/dian_gan_shou_qi_4zhen.tres")


static func fang_dian(gen: Node, wei: Vector2, bi := 1.0) -> void:
	# 放电圈：电鳐半径 90 → 特效直径约 180 像素，scale 1.0 正好覆盖
	_sheng_chu(gen, DIAN_TE_XIAO, wei, bi)


static func zhong_du(gen: Node, wei: Vector2, bi := 0.55) -> void:
	# 中毒：小一圈的毒雾，只是“被反毒了”的反馈，不表示范围伤害
	_sheng_chu(gen, DU_TE_XIAO, wei, bi)


static func bo(gen: Node, kuang: SpriteFrames, wei: Vector2, bi := 1.0) -> void:
	# 通用播放入口：能力特效统一走这里，复用 _sheng_chu 的挂载 / 播放 / 自动销毁
	_sheng_chu(gen, kuang, wei, bi)


# ---- 8 套专属能力特效的语义化包装：调用方只关心“哪个能力、放哪、多大” ----

static func xuan_wo(gen: Node, wei: Vector2, bi := 1.1) -> void:
	# 漩涡：以玩家为涡心，略放大一点让涡纹盖住吸卷半径
	bo(gen, XUAN_WO_TE_XIAO, wei, bi)


static func yu_ni(gen: Node, wei: Vector2, bi := 1.0) -> void:
	# 淤泥弹：落在雾团生成点，标示“这一团泥雾在这里”
	bo(gen, YU_NI_TE_XIAO, wei, bi)


static func sheng_na(gen: Node, wei: Vector2, bi := 1.2) -> void:
	# 声呐脉冲：以玩家为圆心向外扩散，略放大一点表现扫描范围
	bo(gen, SHENG_NA_TE_XIAO, wei, bi)


static func yu_lei(gen: Node, wei: Vector2, bi := 1.0) -> void:
	# 鱼雷冲刺：起手位置的一次冲刺水花（后续位移由冲撞分支负责）
	bo(gen, YU_LEI_TE_XIAO, wei, bi)


static func kuang_bao(gen: Node, wei: Vector2, bi := 1.0) -> void:
	# 狂暴撕咬：开启狂暴窗口时在玩家身上亮一下
	bo(gen, KUANG_BAO_TE_XIAO, wei, bi)


static func ni_liu(gen: Node, wei: Vector2, bi := 1.0) -> void:
	# 逆流闪避：开启无敌窗口时的闪身特效
	bo(gen, NI_LIU_TE_XIAO, wei, bi)


static func ying_lin(gen: Node, wei: Vector2, bi := 1.0) -> void:
	# 硬鳞反击：真正触发反伤时在玩家身上亮一下（不是每次受击都播）
	bo(gen, YING_LIN_TE_XIAO, wei, bi)


static func dian_gan(gen: Node, wei: Vector2, bi := 1.0) -> void:
	# 电感受器：被动预警触发时在玩家身上亮一下（调用方负责节流）
	bo(gen, DIAN_GAN_TE_XIAO, wei, bi)


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
