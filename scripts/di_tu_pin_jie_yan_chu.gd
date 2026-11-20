extends Node2D
class_name DiTuPinJieYanChu
# 人类战 · 九图拼合演出（TASK-028 重做：戴夫式慢推镜 / 显影 / 打字机 / 冷蓝船影）
# 只做演出层：不锁房间、不改刷怪规则。演出期间由 Main 锁输入、藏 HUD。
# 九块图由同一张 4128×2304 背景按 1376×768 切片，在各自最终位置错峰显影，
# 按行优先 1→2→…→9 一张一张拼下来；拼完后镜头轻推玩家、区域名打字机，
# 再回到全图看机械船用 4 帧动态船体从上方压入（冷蓝背光、无红闪/震屏），
# 最后回到玩家体型该有的镜头大小，交由 Main 生成真正的 Boss。

signal jie_shu  # 演出结束（自然结束或跳过都只发一次）

const DI_TU_CHI_CUN := Vector2(4128.0, 2304.0)  # 3×3 整图世界尺寸
const MEI_GE_CHI_CUN := Vector2(1376.0, 768.0)  # 单格尺寸（与 Main.DI_TU_MEI_GE 同源）
const GE_SHU := 9  # 九块图
const QUAN_TU_ZHONG_XIN := Vector2(2064.0, 1152.0)  # 整图中心
const FEI_RU_JU_LI := 1100.0  # 兼容旧静态契约；新演出不再飞入
const WAN_JIA_JU_JIAO := 0.88  # 玩家特写 zoom：1376×768 的一格图≈铺满 1280×720
const YAN_CHU_SHI_CHANG := 7.3  # 完整演出秒数（测试与文案引用）
const DI_TU_TIE_TU := preload("res://assets/sucai/shenhai_beijing/beijing_3x3.webp")
const CHUAN_TIE_TU := preload("res://assets/sucai/ji_qi_chuan/ji_qi_chuan.png")
const CHUAN_4ZHEN := preload("res://data/donghua/ji_qi_chuan_4zhen.tres")  # 4 帧动态船体
const TE_XIAO := preload("res://scripts/te_xiao.gd")  # 落点气泡复用既有特效
const REN_LEI_LUO_DIAN := Vector2(2064.0, 290.0)  # 4× 船体中心：船底到 906，压住地图上半
const ZHEN_DONG_FU := [
	Vector2(16.0, -9.0), Vector2(-14.0, 11.0), Vector2(12.0, 7.0),
	Vector2(-9.0, -12.0), Vector2(7.0, 9.0), Vector2(-5.0, -6.0),
]  # 旧定值抖动表保留兼容；TASK-028 新演出不使用震屏

# TASK-028 新分镜常量
const HEI_BIAN_GAO := 92.0  # 黑边合拢高度：接近 2.39:1
const XIAN_YING_JIAN_GE := 0.15  # 九格错峰显影间隔
const LUO_XIA_JU_LI := 20.0  # 每块从上方落下的距离
const BO_WEN_ZUI_DA_BAN_JING := 220.0  # 波纹圆环最大半径
const JIN_XIAN_ALPHA := 0.55  # 接缝金线最终亮度
const LENG_GUANG_YAN_SE := Color(0.58, 0.74, 0.92)  # 冷蓝背光
const LENG_GUANG_ZUI_DA := 0.12  # 冷蓝背光最高 alpha
const YA_AN_ZUI_DA := 0.12  # 全图整体压暗
const BIAO_TI_ZI_SHI_JIAN := 0.05  # 标题打字机：每字秒数

var _wan_jia: Yu = null
var _xiang_ji: Camera2D = null
var _wan_jia_qu_yu_ming := ""
var _wan_jia_pian := 4
var _wan_jia_yuan_wei := Vector2.ZERO
var _mo_biao_zoom := Vector2.ONE
var _quan_tu_bei := 0.31
var _tie_pian: Array[Sprite2D] = []
var _bo_wen: Array[Line2D] = []
var _feng_xian: Array[Line2D] = []
var _gao_liang: Line2D = null
var _ren_lei: Array[Node2D] = []
var _cang_deng: Array[ColorRect] = []
var _ceng: CanvasLayer = null
var _hei_bian_shang: ColorRect = null
var _hei_bian_xia: ColorRect = null
var _leng_guang: ColorRect = null
var _ya_an: ColorRect = null
var _biao_ti: Label = null
var _qu_yu_label: Label = null
var _fu_biao_ti: Label = null
var _tiao_guo_an_niu: Button = null
var _jie_shu_le := false
var _bu_zu: Array[Tween] = []


static func quan_tu_zoom(ping_mu: Vector2) -> float:
	# 整张 4128×2304 塞进屏幕：取横竖两个比例里更小的，保证整图都在画面内
	if ping_mu.x <= 0.0 or ping_mu.y <= 0.0:
		return 1.0
	return minf(ping_mu.x / DI_TU_CHI_CUN.x, ping_mu.y / DI_TU_CHI_CUN.y)


static func ge_zi_qu(pian: int) -> Rect2:
	# 第 pian 块图在整张背景里的源矩形（行优先 0..8）
	var pian_jia := clampi(pian, 0, GE_SHU - 1)
	var lie := pian_jia % 3
	var hang := int(floor(float(pian_jia) / 3.0))
	return Rect2(Vector2(float(lie) * MEI_GE_CHI_CUN.x, float(hang) * MEI_GE_CHI_CUN.y),
			MEI_GE_CHI_CUN)


static func ge_zi_zhong_xin(pian: int) -> Vector2:
	# 第 pian 块图的世界中心：Sprite2D 默认 centered=true，直接用它做落点
	return ge_zi_qu(pian).position + MEI_GE_CHI_CUN * 0.5


static func wan_jia_pian(shijie_wei: Vector2) -> int:
	# 世界坐标 → 九宫格编号；与 Main.qu_yu_ming 的夹边规则保持一致
	var ge_x := clampi(int(floor(shijie_wei.x / MEI_GE_CHI_CUN.x)), 0, 2)
	var ge_y := clampi(int(floor(shijie_wei.y / MEI_GE_CHI_CUN.y)), 0, 2)
	return ge_y * 3 + ge_x


static func pin_jie_shun_xu(_wan_jia_pian_hao: int) -> Array[int]:
	# TASK-028 用户追加口径：左上角起、行优先 1→2→…→9 一张一张拼下来
	# 参数保留是为了兼容旧调用与测试签名；顺序不再随玩家格变化，玩家格也不再固定最后
	var shun_xu: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8]
	return shun_xu


static func fei_ru_qi_dian(pian: int) -> Vector2:
	# 兼容静态契约保留；TASK-028 新演出改为原地显影 + 上方 20px 落下，运行时不调用
	var zhong_xin := ge_zi_zhong_xin(pian)
	var fang := zhong_xin - QUAN_TU_ZHONG_XIN
	if fang.length() < 0.001:
		fang = Vector2(0.0, -1.0)
	return zhong_xin + fang.normalized() * FEI_RU_JU_LI


func bo_fang(wan_jia: Yu, xiang_ji: Camera2D, qu_yu_ming: String,
		mo_biao_zoom: Vector2) -> void:
	# Main 在 add_child 之后调用；相机、玩家、收尾 zoom 都由 Main 注入
	_wan_jia = wan_jia
	_xiang_ji = xiang_ji
	_wan_jia_qu_yu_ming = qu_yu_ming
	_mo_biao_zoom = mo_biao_zoom
	_wan_jia_pian = wan_jia_pian(_wan_jia.global_position)
	_wan_jia_yuan_wei = _wan_jia.position
	_jian_di_tu()
	_jian_ren_lei()
	_jian_ui()
	_kai_shi()


func _jian_di_tu() -> void:
	# 整图底板：显影过程中先露出深海底色（默认清屏灰会在拼合过程中穿帮）
	var di_ban := ColorRect.new()
	di_ban.name = "DiBan"
	di_ban.color = Color(0.035, 0.075, 0.115, 1.0)
	di_ban.position = Vector2.ZERO
	di_ban.size = DI_TU_CHI_CUN
	di_ban.mouse_filter = Control.MOUSE_FILTER_IGNORE
	di_ban.z_index = -20
	add_child(di_ban)

	# 九块 Sprite2D 共用整张背景，用 region_rect 取各自 1376×768
	# 初始就在各自最终中心、scale=1、alpha=0：显影不是飞入（显影起点由 _kai_shi 到点再拨）
	# region_filter_clip_enabled 防止线性采样吃到邻格像素（缝）
	for pian in GE_SHU:
		var jing := Sprite2D.new()
		jing.name = "Pian_%d" % pian
		jing.texture = DI_TU_TIE_TU
		jing.region_enabled = true
		jing.region_rect = ge_zi_qu(pian)
		jing.region_filter_clip_enabled = true
		jing.centered = true
		jing.position = ge_zi_zhong_xin(pian)
		jing.scale = Vector2.ONE
		jing.modulate = Color(1.0, 1.0, 1.0, 0.0)
		jing.z_index = -10
		add_child(jing)
		_tie_pian.append(jing)

		# 每块一圈波纹：半径为 12→220 的圆环，随显影向外扩散淡出
		var bo := Line2D.new()
		bo.name = "BoWen_%d" % pian
		bo.points = _yuan_huan_dian(BO_WEN_ZUI_DA_BAN_JING)
		bo.width = 10.0
		bo.default_color = Color(1.0, 0.88, 0.52, 0.9)
		bo.modulate = Color(1.0, 1.0, 1.0, 0.0)
		bo.position = ge_zi_zhong_xin(pian)
		bo.scale = Vector2(12.0 / BO_WEN_ZUI_DA_BAN_JING, 12.0 / BO_WEN_ZUI_DA_BAN_JING)
		bo.z_index = -8
		add_child(bo)
		_bo_wen.append(bo)

	# 内部接缝金线：横竖各两条，随已拼好的边分段亮起
	for x in [MEI_GE_CHI_CUN.x, MEI_GE_CHI_CUN.x * 2.0]:
		var shu := Line2D.new()
		shu.points = PackedVector2Array([Vector2(x, 0.0), Vector2(x, DI_TU_CHI_CUN.y)])
		shu.width = 6.0
		shu.default_color = Color(1.0, 0.78, 0.28, 1.0)
		shu.modulate = Color(1.0, 1.0, 1.0, 0.0)
		shu.z_index = -9
		add_child(shu)
		_feng_xian.append(shu)
	for y in [MEI_GE_CHI_CUN.y, MEI_GE_CHI_CUN.y * 2.0]:
		var heng := Line2D.new()
		heng.points = PackedVector2Array([Vector2(0.0, y), Vector2(DI_TU_CHI_CUN.x, y)])
		heng.width = 6.0
		heng.default_color = Color(1.0, 0.78, 0.28, 1.0)
		heng.modulate = Color(1.0, 1.0, 1.0, 0.0)
		heng.z_index = -9
		add_child(heng)
		_feng_xian.append(heng)

	# 玩家格金色高亮框：四边内缩 3px，压在接缝线上、鱼的下方
	# 初始 alpha 0；2.5 秒玩家焦点时才亮起
	_gao_liang = Line2D.new()
	var ge := ge_zi_qu(_wan_jia_pian)
	var nei := ge.grow(-3.0)
	_gao_liang.points = PackedVector2Array([
		nei.position,
		Vector2(nei.end.x, nei.position.y),
		nei.end,
		Vector2(nei.position.x, nei.end.y),
		nei.position,
	])
	_gao_liang.width = 7.0
	_gao_liang.default_color = Color(1.0, 0.78, 0.28, 1.0)
	_gao_liang.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_gao_liang.z_index = -9
	add_child(_gao_liang)


func _yuan_huan_dian(ban_jing: float) -> PackedVector2Array:
	# 32 段圆环：Line2D 没有“画圆”，用点阵近似
	var dian := PackedVector2Array()
	for i in 33:
		var jiao := TAU * float(i) / 32.0
		dian.append(Vector2(cos(jiao), sin(jiao)) * ban_jing)
	return dian


func _jian_ren_lei() -> void:
	# 人类机器船：优先 4 帧动态船体（TASK-028），静态贴图只作兜底
	# 放在 z=-1：压住海图，但在玩家鱼/NPC 之下，玩家始终看得见自己
	var chuan: Node2D = null
	if CHUAN_4ZHEN != null and CHUAN_4ZHEN is SpriteFrames:
		var dong := AnimatedSprite2D.new()
		dong.name = "RenLeiDongHua"
		dong.sprite_frames = CHUAN_4ZHEN
		dong.animation = &"dong"
		dong.play()
		dong.scale = Vector2(4.0, 4.0)
		dong.modulate = Color(0.10, 0.14, 0.20, 1.0)
		dong.position = Vector2(QUAN_TU_ZHONG_XIN.x, -780.0)
		dong.z_index = -1
		add_child(dong)
		chuan = dong
	else:
		var jing := Sprite2D.new()
		jing.name = "RenLeiJingTai"
		jing.texture = CHUAN_TIE_TU
		jing.scale = Vector2(4.0, 4.0)
		jing.modulate = Color(0.10, 0.14, 0.20, 1.0)
		jing.position = Vector2(QUAN_TU_ZHONG_XIN.x, -780.0)
		jing.z_index = -1
		add_child(jing)
		chuan = jing
	_ren_lei.append(chuan)

	# 船体舱灯：两枚小矩形，停驻时闪 2 次；self_modulate 不被船体暗色 modulate 乘暗
	for ce in [-1, 1]:
		var deng := ColorRect.new()
		deng.color = Color(1.0, 0.18, 0.12, 1.0)
		deng.size = Vector2(8.0, 5.0)
		deng.position = Vector2(150.0 * float(ce) - 4.0, 30.0)
		deng.self_modulate = Color(1.0, 1.0, 1.0, 0.15)
		deng.mouse_filter = Control.MOUSE_FILTER_IGNORE
		deng.z_index = 2
		chuan.add_child(deng)
		_cang_deng.append(deng)


func _jian_ui() -> void:
	# 演出层（CanvasLayer 100）：压暗 → 冷蓝 → 黑边 → 标题 → 区域名 → 跳过按钮
	# 全部是运行时创建，不往 Main.tscn 里塞节点，关卡逻辑场景保持干净
	var ping_mu := get_viewport_rect().size
	_ceng = CanvasLayer.new()
	_ceng.layer = 100
	add_child(_ceng)

	_ya_an = ColorRect.new()
	_ya_an.color = Color(0.0, 0.0, 0.0, 1.0)
	_ya_an.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ya_an.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_ya_an.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ceng.add_child(_ya_an)

	_leng_guang = ColorRect.new()
	_leng_guang.color = LENG_GUANG_YAN_SE
	_leng_guang.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_leng_guang.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_leng_guang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ceng.add_child(_leng_guang)

	_hei_bian_shang = ColorRect.new()
	_hei_bian_shang.color = Color(0.0, 0.0, 0.0, 1.0)
	_hei_bian_shang.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_hei_bian_shang.offset_bottom = 0.0
	_hei_bian_shang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ceng.add_child(_hei_bian_shang)

	_hei_bian_xia = ColorRect.new()
	_hei_bian_xia.color = Color(0.0, 0.0, 0.0, 1.0)
	_hei_bian_xia.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hei_bian_xia.offset_top = 0.0
	_hei_bian_xia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ceng.add_child(_hei_bian_xia)

	_biao_ti = _xin_biao_qian("人类机器船降临", 60, Color(0.86, 0.92, 1.0),
			Color(0.04, 0.08, 0.14), 14)
	_biao_ti.position = Vector2(0.0, 250.0)
	_biao_ti.size = Vector2(ping_mu.x, 120.0)
	_biao_ti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_biao_ti.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_biao_ti.visible_ratio = 0.0  # 打字机从 0 开始

	_qu_yu_label = _xin_biao_qian("", 30, Color(1.0, 0.84, 0.42),
			Color(0.10, 0.06, 0.02), 8)
	_qu_yu_label.position = Vector2(0.0, ping_mu.y - 150.0)
	_qu_yu_label.size = Vector2(ping_mu.x, 44.0)
	_qu_yu_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_qu_yu_label.visible_ratio = 0.0

	_fu_biao_ti = _xin_biao_qian("", 18, Color(0.82, 0.88, 0.92),
			Color(0.05, 0.08, 0.12), 6)
	_fu_biao_ti.position = Vector2(0.0, ping_mu.y - 104.0)
	_fu_biao_ti.size = Vector2(ping_mu.x, 30.0)
	_fu_biao_ti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fu_biao_ti.visible_ratio = 0.0

	_tiao_guo_an_niu = Button.new()
	_tiao_guo_an_niu.text = "跳过 ▶"
	_tiao_guo_an_niu.position = Vector2(ping_mu.x - 150.0, 70.0)
	_tiao_guo_an_niu.size = Vector2(126.0, 44.0)
	_tiao_guo_an_niu.focus_mode = Control.FOCUS_NONE
	_tiao_guo_an_niu.add_theme_font_size_override("font_size", 18)
	_tiao_guo_an_niu.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_tiao_guo_an_niu.pressed.connect(_tiao_guo)
	_ceng.add_child(_tiao_guo_an_niu)


func _xin_biao_qian(wen_ben: String, zi_hao: int, yan_se: Color,
		miao_bian_se: Color, miao_bian_kuan: int) -> Label:
	# 统一创建带描边的演出文字；初始全透明，由时间轴淡入
	var biao := Label.new()
	biao.text = wen_ben
	biao.add_theme_font_size_override("font_size", zi_hao)
	biao.add_theme_color_override("font_color", yan_se)
	biao.add_theme_color_override("font_outline_color", miao_bian_se)
	biao.add_theme_constant_override("outline_size", miao_bian_kuan)
	biao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	biao.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_ceng.add_child(biao)
	return biao


func _kai_shi() -> void:
	# 0.0~1.6 黑边合拢 + 镜头慢推到全图中心
	# 0.5~2.5 九格按 0..8 每 0.15 秒一块显影（alpha/scale/上方 20px 落下 + 波纹）
	# 1.2~2.2 接缝金线随已拼好的边分段亮起
	var ping_mu := get_viewport_rect().size
	_quan_tu_bei = quan_tu_zoom(ping_mu)

	if _xiang_ji != null:
		_xiang_ji.position_smoothing_enabled = false
		_xiang_ji.offset = Vector2.ZERO
		var kan := _zuo_tween()
		kan.set_parallel(true)
		kan.tween_property(_xiang_ji, "position", QUAN_TU_ZHONG_XIN, 1.6) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		kan.tween_property(_xiang_ji, "zoom", Vector2.ONE * _quan_tu_bei, 1.6) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 上下黑边：0.5 秒合拢到 92px
	var hei_shang := _zuo_tween()
	hei_shang.tween_property(_hei_bian_shang, "offset_bottom", HEI_BIAN_GAO, 0.5) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var hei_xia := _zuo_tween()
	hei_xia.tween_property(_hei_bian_xia, "offset_top", -HEI_BIAN_GAO, 0.5) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 跳过按钮：0.6 秒后出现，避免一开场就打断情绪
	var tiao_tw := _zuo_tween()
	tiao_tw.tween_interval(0.6)
	tiao_tw.tween_property(_tiao_guo_an_niu, "modulate:a", 1.0, 0.2)

	# 九块图：行优先 0..8，每块 0.15 秒错峰；玩家格不再固定最后
	var shun_xu := pin_jie_shun_xu(_wan_jia_pian)
	for i in shun_xu.size():
		var pian := shun_xu[i]
		var jing := _tie_pian[pian]
		var yan_shi := 0.5 + float(i) * XIAN_YING_JIAN_GE
		_tie_xian_ying(jing, _bo_wen[pian], pian, yan_shi)

	# 接缝金线：1.2 秒起按顺序分段亮到 0.55（不是一次性满亮）
	for i in _feng_xian.size():
		var xian := _feng_xian[i]
		var feng := _zuo_tween()
		feng.tween_interval(1.2 + float(i) * 0.1)
		feng.tween_property(xian, "modulate:a", JIN_XIAN_ALPHA, 0.5) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# 绝对时间轴：2.5 玩家焦点 → 3.6 回全图 → 4.5 船入场 → 5.9 停驻 → 6.6 收尾 → 7.3 交还 Main
	_ding_shi(2.5, _ju_jiao_wan_jia)
	_ding_shi(3.6, _hui_quan_tu)
	_ding_shi(4.5, _kai_shi_ren_lei)
	_ding_shi(5.9, _ting_zhu)
	_ding_shi(6.6, _shou_wei)
	_ding_shi(7.3, _jie_shu_yan_chu)


func _tie_xian_ying(jing: Sprite2D, bo: Line2D, pian: int, yan_shi: float) -> void:
	# 一块图的显影：原地 alpha 0→1、scale 0.96→1，并从上方 20px 落下
	# 到点才把 position/scale 拨到显影起点：保证 bo_fang() 返回时九块仍是「最终中心、scale=1、alpha=0」
	# 从上方落下而不是飞入：无重叠、无回弹
	var zhong_xin := ge_zi_zhong_xin(pian)
	var qi_dian := zhong_xin + Vector2(0.0, -LUO_XIA_JU_LI)

	var wei := _zuo_tween()
	wei.tween_interval(yan_shi)
	wei.tween_callback(_she_wei_zhi.bind(jing, qi_dian))
	wei.tween_property(jing, "position", zhong_xin, 0.35) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var liang := _zuo_tween()
	liang.tween_interval(yan_shi)
	liang.tween_property(jing, "modulate:a", 1.0, 0.4) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var suo := _zuo_tween()
	suo.tween_interval(yan_shi)
	suo.tween_callback(_she_suo_fang.bind(jing, Vector2(0.96, 0.96)))
	suo.tween_property(jing, "scale", Vector2.ONE, 0.45) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# 波纹：半径 12→220，透明度先亮后淡出
	var bo_liang := _zuo_tween()
	bo_liang.tween_interval(yan_shi)
	bo_liang.tween_property(bo, "modulate:a", 0.55, 0.10)
	bo_liang.tween_property(bo, "modulate:a", 0.0, 0.60)

	var bo_suo := _zuo_tween()
	bo_suo.tween_interval(yan_shi)
	bo_suo.tween_property(bo, "scale", Vector2.ONE, 0.70) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _she_wei_zhi(jing: Sprite2D, wei_zhi: Vector2) -> void:
	# Tween 回调：显影到点才把图挪到「上方 20px」的起点
	jing.position = wei_zhi


func _she_suo_fang(jing: Sprite2D, bi_li: Vector2) -> void:
	# Tween 回调：显影到点才收小到 0.96，再缓回 1（不做回弹）
	jing.scale = bi_li


func _ju_jiao_wan_jia() -> void:
	# 2.5 秒：玩家格金框亮起 + 镜头轻推近玩家 0.6 秒 + 区域名/水位小字打字机
	if _jie_shu_le:
		return
	YinXiang.fang(&"sheng_ji")

	var gao := _zuo_tween()
	gao.tween_property(_gao_liang, "modulate:a", 1.0, 0.3) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if _xiang_ji != null and is_instance_valid(_wan_jia):
		var kan := _zuo_tween()
		kan.set_parallel(true)
		kan.tween_property(_xiang_ji, "position", _wan_jia.global_position, 0.6) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		kan.tween_property(_xiang_ji, "zoom", Vector2.ONE * WAN_JIA_JU_JIAO, 0.6) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	_qu_yu_label.text = _wan_jia_qu_yu_ming
	_fu_biao_ti.text = "第 1 天 · 水位线 −12m"
	var qu := _zuo_tween()
	qu.tween_interval(0.1)
	qu.tween_property(_qu_yu_label, "visible_ratio", 1.0, 0.8) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var fu := _zuo_tween()
	fu.tween_interval(0.3)
	fu.tween_property(_fu_biao_ti, "visible_ratio", 1.0, 0.6) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _hui_quan_tu() -> void:
	# 3.6 秒：镜头缓回全图、区域名淡出、留白呼吸（玩家不再上浮/翘头）
	if _jie_shu_le:
		return
	if _xiang_ji != null:
		var kan := _zuo_tween()
		kan.set_parallel(true)
		kan.tween_property(_xiang_ji, "position", QUAN_TU_ZHONG_XIN, 0.6) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		kan.tween_property(_xiang_ji, "zoom", Vector2.ONE * _quan_tu_bei, 0.6) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var qu := _zuo_tween()
	qu.tween_property(_qu_yu_label, "modulate:a", 0.0, 0.4)
	var fu := _zuo_tween()
	fu.tween_property(_fu_biao_ti, "modulate:a", 0.0, 0.4)


func _kai_shi_ren_lei() -> void:
	# 4.5 秒：警报 + 决战曲 + 4 帧船体 1.4 秒从画面上缘压入
	# 冷蓝背光 + 全图压暗 12% + 标题打字机 0.05 秒/字；无红闪、无震屏
	if _jie_shu_le:
		return
	YinXiang.fang(&"jing_bao")
	YinXiang.bo_bgm(&"jue_zhan")

	for ren in _ren_lei:
		var jiang := _zuo_tween()
		jiang.tween_property(ren, "position", REN_LEI_LUO_DIAN, 1.4) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var leng := _zuo_tween()
	leng.tween_property(_leng_guang, "modulate:a", LENG_GUANG_ZUI_DA, 0.8) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var ya := _zuo_tween()
	ya.tween_property(_ya_an, "modulate:a", YA_AN_ZUI_DA, 0.8) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var biao := _zuo_tween()
	biao.tween_interval(0.5)
	biao.tween_property(_biao_ti, "visible_ratio", 1.0,
			BIAO_TI_ZI_SHI_JIAN * float(_biao_ti.text.length())) \
			.set_trans(Tween.TRANS_LINEAR)


func _ting_zhu() -> void:
	# 5.9 秒：船停驻空镜；舱灯小面积闪 2 次；落点一次可控气泡
	if _jie_shu_le:
		return
	for deng in _cang_deng:
		var shan := _zuo_tween()
		for i in 2:
			shan.tween_property(deng, "self_modulate:a", 1.0, 0.12)
			shan.tween_property(deng, "self_modulate:a", 0.15, 0.18)

	TE_XIAO.you_er_qi_pao(self, Vector2(REN_LEI_LUO_DIAN.x, 900.0), 2.2)


func _shou_wei() -> void:
	# 6.6 秒：黑边展开、九图/船/冷蓝/压暗/文字淡出、镜头缓慢收回玩家；7.3 秒交还 Main
	if _jie_shu_le:
		return
	TeXiaoKu.zhuan_chang()  # v2 章节转场：全屏像素溶解盖在收尾段（挂根节点，不随演出层淡出）
	var tiao := _zuo_tween()
	tiao.tween_property(_tiao_guo_an_niu, "modulate:a", 0.0, 0.2)

	var hei_shang := _zuo_tween()
	hei_shang.tween_property(_hei_bian_shang, "offset_bottom", 0.0, 0.45) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	var hei_xia := _zuo_tween()
	hei_xia.tween_property(_hei_bian_xia, "offset_top", 0.0, 0.45) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	var leng := _zuo_tween()
	leng.tween_property(_leng_guang, "modulate:a", 0.0, 0.45)
	var ya := _zuo_tween()
	ya.tween_property(_ya_an, "modulate:a", 0.0, 0.45)

	for ren in _ren_lei:
		var rong := _zuo_tween()
		rong.tween_property(ren, "modulate:a", 0.0, 0.45)
	for jing in _tie_pian:
		var rong := _zuo_tween()
		rong.tween_property(jing, "modulate:a", 0.0, 0.45)

	var biao := _zuo_tween()
	biao.tween_property(_biao_ti, "modulate:a", 0.0, 0.35)

	for xian in _feng_xian:
		var xian_tw := _zuo_tween()
		xian_tw.tween_property(xian, "modulate:a", 0.0, 0.30)
	var gao := _zuo_tween()
	gao.tween_property(_gao_liang, "modulate:a", 0.0, 0.30)

	if _xiang_ji != null and is_instance_valid(_wan_jia):
		var kan := _zuo_tween()
		kan.set_parallel(true)
		kan.tween_property(_xiang_ji, "position", _wan_jia.global_position, 0.65) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		kan.tween_property(_xiang_ji, "zoom", _mo_biao_zoom, 0.65) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func _tiao_guo() -> void:
	# 跳过按钮 / ESC：直接走同一收尾入口，只生效一次
	_jie_shu_yan_chu()


func _unhandled_input(event: InputEvent) -> void:
	# TASK-028：ESC 跳过与按钮走同一路径；收尾后不再吃输入
	if _jie_shu_le:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_tiao_guo()


func _jie_shu_yan_chu() -> void:
	# 唯一收尾入口：杀所有 tween、还原玩家姿态与相机 offset、广播、自毁
	# 一次性守卫保证自然结束与跳过不会重复 emit（Main 靠它只生成一条船）
	if _jie_shu_le:
		return
	_jie_shu_le = true
	for tw in _bu_zu:
		if tw != null and tw.is_valid():
			tw.kill()
	_bu_zu.clear()
	if is_instance_valid(_wan_jia):
		_wan_jia.position = _wan_jia_yuan_wei
		_wan_jia.rotation = 0.0
	if is_instance_valid(_xiang_ji):
		_xiang_ji.offset = Vector2.ZERO
	jie_shu.emit()
	queue_free()


func _zuo_tween() -> Tween:
	# 统一登记 tween：跳过时一次性 kill，避免回调在收尾后继续改节点
	var tw := create_tween()
	_bu_zu.append(tw)
	return tw


func _ding_shi(shi_jian: float, hui_diao: Callable) -> void:
	# 绝对时间轴：从演出开始算，到点执行一次
	var tw := _zuo_tween()
	tw.tween_interval(shi_jian)
	tw.tween_callback(hui_diao)
