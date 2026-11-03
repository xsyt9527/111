extends Node2D
# 纯装饰气泡层：从镜头可视区底部不断冒泡，只做氛围，不参与任何碰撞/判定
# 素材：assets/sucai/qipao/hai_di_qi_pao_4zhen.png（4 帧 256 格，动画名 bao，6 fps）
# 性能：整层共用一个 _process 计时 + 一个常量 SpriteFrames，不逐帧 new Timer

const QI_PAO_ZHEN := preload("res://data/donghua/hai_di_qi_pao_4zhen.tres")  # 4 帧气泡动画
const ZUI_DA_SHU := 30              # 同屏上限（含正在播放的破裂帧）
const JIAN_GE_MIN := 0.10           # 生成间隔下限（秒）
const JIAN_GE_MAX := 0.30           # 生成间隔上限（秒）
const CHU_SHENG_XIA_FANG_MIN := 20.0  # 生成点在可视底边下方 20~60px
const CHU_SHENG_XIA_FANG_MAX := 60.0
const SUO_FANG_MIN := 0.08          # 256 格 → 20~90px
const SUO_FANG_MAX := 0.35
const SHANG_SHENG_MIN := 30.0       # 上浮速度 30~70 px/s
const SHANG_SHENG_MAX := 70.0
const BAI_DONG_FU_DU_MIN := 5.0     # 左右摆动幅度（px）
const BAI_DONG_FU_DU_MAX := 14.0
const BAI_DONG_PIN_LV_MIN := 1.0    # 摆动角频率 1.0~2.2 rad/s
const BAI_DONG_PIN_LV_MAX := 2.2
const TOU_MING_MIN := 0.55          # modulate.a 0.55~0.85
const TOU_MING_MAX := 0.85
const LI_KAI_SHANG_FANG := 200.0    # 越过可视顶边 200px 就回收，防泄漏
const BEI_JING_MO_REN := Vector2(1280.0, 720.0)  # 无相机时的项目逻辑分辨率

var _ji_shi := 0.0                  # 距上次生成的累计时间
var _xia_ci_jian_ge := JIAN_GE_MIN  # 本次生成的随机间隔


class QiPao extends AnimatedSprite2D:
	# 单个气泡的私有运动参数：摆动以原始 x 为基准，避免左右漂移累积
	var yuan_x := 0.0
	var shang_sheng_su_du := 40.0
	var bai_dong_fu_du := 8.0
	var bai_dong_pin_lv := 1.5
	var bai_dong_xiang_wei := 0.0
	var yi_dong_shi_jian := 0.0


func _ready() -> void:
	_xia_ci_jian_ge = randf_range(JIAN_GE_MIN, JIAN_GE_MAX)


func _process(delta: float) -> void:
	# 单一计时器：到点生成一个；重置而不是累减，避免卡顿后一帧爆出一串
	_ji_shi += delta
	if _ji_shi >= _xia_ci_jian_ge:
		_ji_shi = 0.0
		_xia_ci_jian_ge = randf_range(JIAN_GE_MIN, JIAN_GE_MAX)
		if _dang_qian_shu() < ZUI_DA_SHU:
			sheng_cheng_yi_ge()

	# 推进所有气泡：上浮 + sin 轻摆；播完或越界由回调/这里回收
	var ding_bu := _ke_jian_ding_bu()
	for zi in get_children():
		var qi := zi as QiPao
		if qi == null:
			continue
		qi.yi_dong_shi_jian += delta
		qi.position.y -= qi.shang_sheng_su_du * delta
		qi.position.x = qi.yuan_x + sin(
				qi.yi_dong_shi_jian * qi.bai_dong_pin_lv + qi.bai_dong_xiang_wei
		) * qi.bai_dong_fu_du
		if qi.position.y < ding_bu - LI_KAI_SHANG_FANG:
			qi.queue_free()


func sheng_cheng_yi_ge() -> AnimatedSprite2D:
	# 生成一个气泡（测试可直接调用；同屏上限由 _process 负责）
	var qu_yu := _ke_jian_qu_yu()
	var chu_sheng_wei_zhi := Vector2(
		randf_range(qu_yu.position.x, qu_yu.end.x),
		qu_yu.end.y + randf_range(CHU_SHENG_XIA_FANG_MIN, CHU_SHENG_XIA_FANG_MAX)
	)

	var qi := QiPao.new()
	qi.name = "QiPao"
	qi.sprite_frames = QI_PAO_ZHEN
	qi.z_index = -2  # 背景 -10 / 植物 -1 / 鱼 0：气泡压在植物和鱼后面
	qi.modulate = Color(1.0, 1.0, 1.0, randf_range(TOU_MING_MIN, TOU_MING_MAX))
	qi.scale = Vector2.ONE * randf_range(SUO_FANG_MIN, SUO_FANG_MAX)
	qi.position = to_local(chu_sheng_wei_zhi)
	qi.yuan_x = qi.position.x
	qi.shang_sheng_su_du = randf_range(SHANG_SHENG_MIN, SHANG_SHENG_MAX)
	qi.bai_dong_fu_du = randf_range(BAI_DONG_FU_DU_MIN, BAI_DONG_FU_DU_MAX)
	qi.bai_dong_pin_lv = randf_range(BAI_DONG_PIN_LV_MIN, BAI_DONG_PIN_LV_MAX)
	qi.bai_dong_xiang_wei = randf_range(0.0, TAU)
	qi.animation_finished.connect(qi.queue_free)  # 破裂帧播完即回收
	add_child(qi)
	qi.play(&"bao")
	return qi


func qing_kong() -> void:
	# 立即清空（测试/切场景用）：先摘出树，保证 get_child_count() 当场归零
	for qi in get_children():
		remove_child(qi)
		qi.queue_free()
	_ji_shi = 0.0


func _dang_qian_shu() -> int:
	# 只数还没被标记删除的气泡
	var shu := 0
	for qi in get_children():
		if not qi.is_queued_for_deletion():
			shu += 1
	return shu


func _ke_jian_qu_yu() -> Rect2:
	# 优先读当前 Camera2D 的可视世界矩形；没有相机就退回项目逻辑分辨率
	if not is_inside_tree():
		return Rect2(Vector2.ZERO, BEI_JING_MO_REN)
	var she_xiang_ji := get_viewport().get_camera_2d()
	if she_xiang_ji != null:
		var shi_ping := get_viewport().get_visible_rect().size
		var shi_jie_da_xiao := shi_ping / she_xiang_ji.zoom
		return Rect2(she_xiang_ji.get_screen_center_position() - shi_jie_da_xiao * 0.5,
				shi_jie_da_xiao)
	return Rect2(Vector2.ZERO, _shi_ping_da_xiao())


func _shi_ping_da_xiao() -> Vector2:
	# 无相机兜底：viewport 逻辑尺寸（项目为 1280×720）
	if not is_inside_tree():
		return BEI_JING_MO_REN
	var da_xiao := get_viewport().get_visible_rect().size
	return da_xiao if da_xiao != Vector2.ZERO else BEI_JING_MO_REN


func _ke_jian_ding_bu() -> float:
	# 当前可视顶边（局部坐标），用于越界回收
	var qu_yu := _ke_jian_qu_yu()
	return to_local(qu_yu.position).y
