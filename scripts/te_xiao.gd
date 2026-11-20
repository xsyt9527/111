extends RefCounted
# 一次性特效生成器：放电 / 中毒 + 12 套专属能力特效
# 不挂场景、不做常驻节点：触发时现场建一个 AnimatedSprite2D，播完自己 queue_free
# 调用方只给“挂在谁下面 + 世界坐标 + 大小”，特效帧资源全部在这里收口

const DIAN_TE_XIAO: SpriteFrames = preload("res://data/donghua/dian_texiao_4zhen.tres")
const DU_TE_XIAO: SpriteFrames = preload("res://data/donghua/du_texiao_4zhen.tres")
# 12 套专属能力特效：动画名统一为 bao、4 帧、loop=0（播完即销毁）
const XUAN_WO_TE_XIAO: SpriteFrames = preload("res://data/donghua/xuan_wo_4zhen.tres")
const YU_LEI_TE_XIAO: SpriteFrames = preload("res://data/donghua/yu_lei_chong_ci_4zhen.tres")
const KUANG_BAO_TE_XIAO: SpriteFrames = preload("res://data/donghua/kuang_bao_si_yao_4zhen.tres")
const NI_LIU_TE_XIAO: SpriteFrames = preload("res://data/donghua/ni_liu_shan_bi_4zhen.tres")
const YING_LIN_TE_XIAO: SpriteFrames = preload("res://data/donghua/ying_lin_fan_ji_4zhen.tres")
const DIAN_GAN_TE_XIAO: SpriteFrames = preload("res://data/donghua/dian_gan_shou_qi_4zhen.tres")
# 新增 4 主动特效：都是发光型素材，播放时用叠加混合，避免黑底在深海里变成方块
const YING_KE_TE_XIAO: SpriteFrames = preload("res://data/donghua/ying_ke_hu_ti_4zhen.tres")
const DIAN_MAI_TE_XIAO: SpriteFrames = preload("res://data/donghua/dian_mai_chong_4zhen.tres")
const YOU_ER_TE_XIAO: SpriteFrames = preload("res://data/donghua/you_er_qi_pao_4zhen.tres")
const XUE_XING_TE_XIAO: SpriteFrames = preload("res://data/donghua/xue_xing_kuang_re_4zhen.tres")

# 2026-11-17 像素特效试用：12 套旧特效在「待用」里各有一套像素版（pixelfx 渲染）
# 开关=true 走像素版；用户实玩判定不好用 → 改成 false，一键回退旧 4 帧，不删代码
# 选项 1（手动攻击命中）固定走像素版，不受这个开关影响
const SHI_YONG_DAI_YONG_XIANG_SU := true
const XIANG_SU_JIU_ZHEN_KUAN := 274.0  # 旧特效帧宽：像素版按这个屏幕足迹放大


static func shou_dong_yao_zhong(gen: Node, wei: Vector2, bi := 1.0) -> void:
	# 手动攻击命中像素火花（选项 1，永久）：自动咬 / 空挥 / 咬不动都不会调到这里
	# 资源缺失时静默跳过，不影响战斗（美术没导入也能跑）
	var ji := XiangSuTeXiao.qu(&"shou_dong_ming_zhong")
	if ji.is_empty():
		return
	_sheng_chu_xiang_su(gen, &"shou_dong_ming_zhong", ji, wei, bi, 0.55)


static func _bo_xiang_su(gen: Node, ming: StringName, wei: Vector2, bi: float, shi_chang: float,
		jia_se := false) -> bool:
	# 待用像素版入口：有资源就播并返回 true；没有返回 false，调用方接着走旧特效
	if not SHI_YONG_DAI_YONG_XIANG_SU:
		return false
	var ji := XiangSuTeXiao.qu(ming)
	if ji.is_empty():
		return false
	_sheng_chu_xiang_su(gen, ming, ji, wei, bi, shi_chang, jia_se)
	return true


static func _sheng_chu_xiang_su(gen: Node, ming: StringName, ji: Dictionary, wei: Vector2,
		bi: float, shi_chang: float, jia_se := false) -> void:
	# 像素特效播放：最近邻过滤、按 JSON pivot 对齐原点、按旧帧宽放大
	# 一次性播完即销毁；循环 / 超长效果按 shi_chang 淡出收尾，避免放电拖两秒
	if gen == null or not gen.is_inside_tree():
		return
	var kuang: SpriteFrames = ji["kuang"]
	var chi: Vector2 = ji["chi_cun"]
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = kuang
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx.z_index = 5
	fx.add_to_group(&"xiang_su_te_xiao")  # 测试/清理用：像素特效统一可查
	fx.offset = XiangSuTeXiao.yuan_dian_pian_yi(ming)
	fx.scale = Vector2.ONE * bi * (XIANG_SU_JIU_ZHEN_KUAN / maxf(chi.x, 1.0))
	if jia_se:
		var cai := CanvasItemMaterial.new()
		cai.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		fx.material = cai
	gen.add_child(fx)
	fx.global_position = wei
	fx.play(&"bao")
	if not bool(ji["xun_huan"]):
		fx.animation_finished.connect(func() -> void:
			if is_instance_valid(fx):
				fx.queue_free())
	_ding_shi_xiao_hui(fx, shi_chang)


static func _ding_shi_xiao_hui(fx: AnimatedSprite2D, shi_chang: float) -> void:
	# 定时淡出：循环特效没有 animation_finished，必须按时间收；最后 0.15 秒渐隐
	# 定时器用 WeakRef 拿节点：特效先被播完销毁时，lambda 不会抓着已释放对象报 capture freed
	if shi_chang <= 0.0:
		return
	var shu := fx.get_tree()
	if shu == null:
		return
	var ruan: WeakRef = weakref(fx)
	var ding := shu.create_timer(shi_chang)
	ding.timeout.connect(func() -> void:
		var zhu = ruan.get_ref()
		if zhu == null or not is_instance_valid(zhu) or zhu.is_queued_for_deletion():
			return
		var tui: Tween = zhu.create_tween()
		tui.tween_property(zhu, "modulate:a", 0.0, 0.15)
		var ruan_tui: WeakRef = weakref(zhu)
		tui.finished.connect(func() -> void:
			var zui = ruan_tui.get_ref()
			if zui != null and is_instance_valid(zui):
				zui.queue_free()))


static func fang_dian(gen: Node, wei: Vector2, bi := 1.0) -> void:
	# 放电圈：电鳗半径 90 → 特效直径约 180 像素，scale 1.0 正好覆盖
	if _bo_xiang_su(gen, &"dian_texiao", wei, bi, 0.55):
		return
	_sheng_chu(gen, DIAN_TE_XIAO, wei, bi)


static func zhong_du(gen: Node, wei: Vector2, bi := 0.55) -> void:
	# 中毒：小一圈的毒雾，只是“被反毒了”的反馈，不表示范围伤害
	if _bo_xiang_su(gen, &"du_texiao", wei, bi, 0.85):
		return
	_sheng_chu(gen, DU_TE_XIAO, wei, bi)


static func bo(gen: Node, kuang: SpriteFrames, wei: Vector2, bi := 1.0) -> void:
	# 通用播放入口：能力特效统一走这里，复用 _sheng_chu 的挂载 / 播放 / 自动销毁
	_sheng_chu(gen, kuang, wei, bi)


# ---- 8 套专属能力特效的语义化包装：调用方只关心“哪个能力、放哪、多大” ----

static func xuan_wo(gen: Node, wei: Vector2, bi := 1.1) -> void:
	# 漩涡：以玩家为涡心，略放大一点让涡纹盖住吸卷半径
	if _bo_xiang_su(gen, &"xuan_wo", wei, bi, 1.0):
		return
	bo(gen, XUAN_WO_TE_XIAO, wei, bi)


static func yu_lei(gen: Node, wei: Vector2, bi := 1.0) -> void:
	# 鱼雷冲刺：起手位置的一次冲刺水花（后续位移由冲撞分支负责）
	if _bo_xiang_su(gen, &"yu_lei", wei, bi, 0.6):
		return
	bo(gen, YU_LEI_TE_XIAO, wei, bi)


static func kuang_bao(gen: Node, wei: Vector2, bi := 1.0) -> void:
	# 狂暴撕咬：开启狂暴窗口时在玩家身上亮一下
	if _bo_xiang_su(gen, &"kuang_bao", wei, bi, 0.85):
		return
	bo(gen, KUANG_BAO_TE_XIAO, wei, bi)


static func ni_liu(gen: Node, wei: Vector2, bi := 1.0) -> void:
	# 逆流闪避：开启无敌窗口时的闪身特效
	if _bo_xiang_su(gen, &"ni_liu", wei, bi, 0.7):
		return
	bo(gen, NI_LIU_TE_XIAO, wei, bi)


static func ying_lin(gen: Node, wei: Vector2, bi := 1.0) -> void:
	# 硬鳞反击：真正触发反伤时在玩家身上亮一下（不是每次受击都播）
	if _bo_xiang_su(gen, &"ying_lin", wei, bi, 0.8):
		return
	bo(gen, YING_LIN_TE_XIAO, wei, bi)


static func dian_gan(gen: Node, wei: Vector2, bi := 1.0) -> void:
	# 电感受器：被动预警触发时在玩家身上亮一下（调用方负责节流）
	if _bo_xiang_su(gen, &"dian_gan", wei, bi, 0.6):
		return
	bo(gen, DIAN_GAN_TE_XIAO, wei, bi)


# ---- 新增 4 主动特效：发光型素材统一走叠加混合 ----

static func ying_ke_hu_ti(gen: Node, wei: Vector2, bi := 1.0) -> void:
	# 硬壳护体：缩壳成形 / 受击再亮一圈，都由调用方决定时机
	if _bo_xiang_su(gen, &"ying_ke", wei, bi, 0.9, true):
		return
	_sheng_chu(gen, YING_KE_TE_XIAO, wei, bi, true)


static func dian_mai_chong(gen: Node, wei: Vector2, bi := 1.0) -> void:
	# 电脉冲：以玩家为圆心的电环爆发
	if _bo_xiang_su(gen, &"dian_mai", wei, bi, 0.9, true):
		return
	_sheng_chu(gen, DIAN_MAI_TE_XIAO, wei, bi, true)


static func you_er_qi_pao(gen: Node, wei: Vector2, bi := 1.0) -> void:
	# 诱饵气泡：吐泡 / 咬破时的一次性演出（常驻气泡本体由 YouErQiPao 负责）
	if _bo_xiang_su(gen, &"you_er", wei, bi, 0.9, true):
		return
	_sheng_chu(gen, YOU_ER_TE_XIAO, wei, bi, true)


static func xue_xing_kuang_re(gen: Node, wei: Vector2, bi := 1.0) -> void:
	# 血腥狂热：开启狂热窗口时在玩家身上卷起血雾
	if _bo_xiang_su(gen, &"xue_xing", wei, bi, 1.0, true):
		return
	_sheng_chu(gen, XUE_XING_TE_XIAO, wei, bi, true)


static func _sheng_chu(gen: Node, kuang: SpriteFrames, wei: Vector2, bi: float, jia_se := false) -> void:
	if gen == null or not gen.is_inside_tree():
		return  # 场景切换/测试裸节点：没有父节点可挂就不放特效
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = kuang
	fx.z_index = 5  # 盖在鱼上面：电光 / 毒雾要看得见
	if jia_se:
		var cai := CanvasItemMaterial.new()
		cai.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD  # 黑底不叠亮：发光素材不会出现黑方块
		fx.material = cai
	gen.add_child(fx)
	fx.global_position = wei
	fx.scale = Vector2.ONE * bi
	fx.play(&"bao")
	fx.animation_finished.connect(fx.queue_free)  # 播完就销毁：不留下满地空节点
