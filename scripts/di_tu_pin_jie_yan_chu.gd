extends Node2D
class_name DiTuPinJieYanChu
# 人类战 · 九图拼合演出（2026-11-09 用户拍板 1A + 2A）
# 只做演出层：不锁房间、不改刷怪规则。演出期间由 Main 锁输入、藏 HUD；
# 九块图由同一张 4128×2304 背景按 1376×768 切片飞入，玩家所在格最后落位，
# 镜头俯冲到玩家（浮游望青天），再拉回全图看人类机器船从正上方降临，
# 最后回到玩家体型该有的镜头大小，交由 Main 生成真正的 Boss。

signal jie_shu  # 演出结束（自然结束或跳过都只发一次）

const DI_TU_CHI_CUN := Vector2(4128.0, 2304.0)  # 3×3 整图世界尺寸
const MEI_GE_CHI_CUN := Vector2(1376.0, 768.0)  # 单格尺寸（与 Main.DI_TU_MEI_GE 同源）
const GE_SHU := 9  # 九块图
const QUAN_TU_ZHONG_XIN := Vector2(2064.0, 1152.0)  # 整图中心
const FEI_RU_JU_LI := 1100.0  # 每块图从离落点 1100px 外飞入
const WAN_JIA_JU_JIAO := 0.88  # 玩家特写 zoom：1376×768 的一格图≈铺满 1280×720
const YAN_CHU_SHI_CHANG := 7.3  # 完整演出秒数（测试与文案引用）
const DI_TU_TIE_TU := preload("res://assets/sucai/shenhai_beijing/beijing_3x3.webp")
const CHUAN_TIE_TU := preload("res://assets/sucai/ji_qi_chuan/ji_qi_chuan.png")
const REN_LEI_LUO_DIAN := Vector2(2064.0, 290.0)  # 4× 船体中心：船底到 906，压住地图上半
const ZHEN_DONG_FU := [
	Vector2(16.0, -9.0), Vector2(-14.0, 11.0), Vector2(12.0, 7.0),
	Vector2(-9.0, -12.0), Vector2(7.0, 9.0), Vector2(-5.0, -6.0),
]  # 定值抖动：不污染全局随机数，测试也不受随机种子影响

var _wan_jia: Yu = null
var _xiang_ji: Camera2D = null
var _wan_jia_qu_yu_ming := ""
var _wan_jia_pian := 4
var _wan_jia_yuan_wei := Vector2.ZERO
var _mo_biao_zoom := Vector2.ONE
var _quan_tu_bei := 0.31
var _tie_pian: Array[Sprite2D] = []
var _feng_xian: Array[Line2D] = []
var _gao_liang: Line2D = null
var _ren_lei: Array[Sprite2D] = []
var _ceng: CanvasLayer = null
var _hei_bian_shang: ColorRect = null
var _hei_bian_xia: ColorRect = null
var _hong_guang: ColorRect = null
var _biao_ti: Label = null
var _qu_yu_label: Label = null
var _zhen_jing: Label = null
var _zhen_jing_wen: Label = null
var _tiao_guo_an_niu: Button = null
var _zhen_jing_ke_jian := false
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


static func pin_jie_shun_xu(wan_jia_pian_hao: int) -> Array[int]:
	# 拼合顺序：四角 → 四边 → 正中心 → 玩家所在格
	# 玩家格永远最后落位，才有“我的海域被拼上去”的那一拍
	# 优先表必须列全九格（含中心 4）：玩家不在中心时，中心格仍要按序入场
	var an_quan_pian := clampi(wan_jia_pian_hao, 0, GE_SHU - 1)
	var shun_xu: Array[int] = []
	var you_xian: Array[int] = [0, 2, 6, 8, 1, 3, 5, 7, 4]
	for pian in you_xian:
		if pian != an_quan_pian:
			shun_xu.append(pian)
	shun_xu.append(an_quan_pian)
	return shun_xu


static func fei_ru_qi_dian(pian: int) -> Vector2:
	# 飞入起点：沿“整图中心 → 该块中心”的方向往外推 1100px
	# 角落块会从画面外飞入；中心块方向为零时改为从正上方落下
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
	# 整图底板：未落位的格子先露出深海底色（默认清屏灰会在拼合过程中穿帮）
	var di_ban := ColorRect.new()
	di_ban.name = "DiBan"
	di_ban.color = Color(0.035, 0.075, 0.115, 1.0)
	di_ban.position = Vector2.ZERO
	di_ban.size = DI_TU_CHI_CUN
	di_ban.mouse_filter = Control.MOUSE_FILTER_IGNORE
	di_ban.z_index = -20
	add_child(di_ban)

	# 九块 Sprite2D 共用整张背景，用 region_rect 取各自 1376×768
	# region_filter_clip_enabled 防止线性采样吃到邻格像素（缝）
	for pian in GE_SHU:
		var jing := Sprite2D.new()
		jing.name = "Pian_%d" % pian
		jing.texture = DI_TU_TIE_TU
		jing.region_enabled = true
		jing.region_rect = ge_zi_qu(pian)
		jing.region_filter_clip_enabled = true
		jing.centered = true
		jing.position = fei_ru_qi_dian(pian)
		jing.scale = Vector2(0.90, 0.90)
		jing.modulate = Color(1.0, 1.0, 1.0, 0.0)
		jing.z_index = -10
		add_child(jing)
		_tie_pian.append(jing)

	# 内部接缝金线：横竖各两条，落位时亮起，把“九块拼起来”说清楚
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


func _jian_ren_lei() -> void:
	# 人类机器船剪影：当前没有“巨人”素材，先用机器船 4× 放大 + 暗色剪影 + 红色背光
	# 放在 z=-1：压住海图，但在玩家鱼/NPC 之下，玩家始终看得见自己
	var hong := Sprite2D.new()
	hong.texture = CHUAN_TIE_TU
	hong.scale = Vector2(4.15, 4.15)
	hong.position = Vector2(QUAN_TU_ZHONG_XIN.x, -780.0)
	hong.modulate = Color(1.0, 0.12, 0.10, 0.30)
	hong.z_index = -2
	add_child(hong)
	_ren_lei.append(hong)

	var chuan := Sprite2D.new()
	chuan.texture = CHUAN_TIE_TU
	chuan.scale = Vector2(4.0, 4.0)
	chuan.position = Vector2(QUAN_TU_ZHONG_XIN.x, -780.0)
	chuan.modulate = Color(0.10, 0.14, 0.20, 1.0)
	chuan.z_index = -1
	add_child(chuan)
	_ren_lei.append(chuan)


func _jian_ui() -> void:
	# 演出层（CanvasLayer 100）：红闪 → 黑边 → 标题 → 震惊气泡 → 跳过按钮
	# 全部是运行时创建，不往 Main.tscn 里塞节点，关卡逻辑场景保持干净
	var ping_mu := get_viewport_rect().size
	_ceng = CanvasLayer.new()
	_ceng.layer = 100
	add_child(_ceng)

	_hong_guang = ColorRect.new()
	_hong_guang.color = Color(0.82, 0.06, 0.06, 1.0)
	_hong_guang.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hong_guang.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_hong_guang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ceng.add_child(_hong_guang)

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

	_biao_ti = _xin_biao_qian("人类机器船降临！", 60, Color(1.0, 0.72, 0.24),
			Color(0.16, 0.04, 0.04), 14)
	_biao_ti.position = Vector2(0.0, 250.0)
	_biao_ti.size = Vector2(ping_mu.x, 120.0)
	_biao_ti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_biao_ti.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_qu_yu_label = _xin_biao_qian("", 24, Color(1.0, 0.84, 0.42),
			Color(0.10, 0.06, 0.02), 8)
	_qu_yu_label.position = Vector2(0.0, ping_mu.y - 128.0)
	_qu_yu_label.size = Vector2(ping_mu.x, 40.0)
	_qu_yu_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_zhen_jing = _xin_biao_qian("！", 78, Color(1.0, 1.0, 1.0),
			Color(0.62, 0.07, 0.07), 14)
	_zhen_jing.size = Vector2(200.0, 110.0)
	_zhen_jing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zhen_jing.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_zhen_jing_wen = _xin_biao_qian("浮游望青天", 26, Color(1.0, 0.95, 0.78),
			Color(0.10, 0.06, 0.02), 8)
	_zhen_jing_wen.size = Vector2(220.0, 40.0)
	_zhen_jing_wen.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

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
	biao.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_ceng.add_child(biao)
	return biao


func _kai_shi() -> void:
	# 0.0 相机拉远到全图；九块图从 0.45 秒起每 0.17 秒飞入一块
	# 玩家格永远第 9 块，落位（≈2.33 秒）触发特写
	var ping_mu := get_viewport_rect().size
	_quan_tu_bei = quan_tu_zoom(ping_mu)

	if _xiang_ji != null:
		_xiang_ji.position_smoothing_enabled = false
		_xiang_ji.offset = Vector2.ZERO
		var kan := _zuo_tween()
		kan.set_parallel(true)
		kan.tween_property(_xiang_ji, "position", QUAN_TU_ZHONG_XIN, 1.15) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		kan.tween_property(_xiang_ji, "zoom", Vector2.ONE * _quan_tu_bei, 1.15) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 上下黑边
	var hei_shang := _zuo_tween()
	hei_shang.tween_property(_hei_bian_shang, "offset_bottom", 56.0, 0.35) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var hei_xia := _zuo_tween()
	hei_xia.tween_property(_hei_bian_xia, "offset_top", -56.0, 0.35) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 跳过按钮：1 秒后才出现，避免一开场就打断情绪
	var tiao_tw := _zuo_tween()
	tiao_tw.tween_interval(0.9)
	tiao_tw.tween_property(_tiao_guo_an_niu, "modulate:a", 1.0, 0.2)

	# 九块图：位置/透明度/缩放各一条 Tween，同一起始延迟并联
	var shun_xu := pin_jie_shun_xu(_wan_jia_pian)
	for i in shun_xu.size():
		var pian := shun_xu[i]
		var jing := _tie_pian[pian]
		var yan_shi := 0.45 + float(i) * 0.17
		_tie_fei_xing(jing, pian, yan_shi)
		if pian == _wan_jia_pian:
			var luo := _zuo_tween()
			luo.tween_interval(yan_shi + 0.52)
			luo.tween_callback(_on_wan_jia_pian_luo_di)

	# 接缝金线：随拼合亮起
	for xian in _feng_xian:
		var feng := _zuo_tween()
		feng.tween_interval(0.8)
		feng.tween_property(xian, "modulate:a", 0.9, 1.5) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# 人类登场（4.5 秒）与收尾（7.3 秒）都走绝对时间轴
	_ding_shi(4.5, _kai_shi_ren_lei)
	_ding_shi(7.3, _jie_shu_yan_chu)


func _tie_fei_xing(jing: Sprite2D, pian: int, yan_shi: float) -> void:
	# 一块图的飞入：从画面外滑到落点、从 0.9 放大回 1.0、淡入
	var wei := _zuo_tween()
	wei.tween_interval(yan_shi)
	wei.tween_property(jing, "position", ge_zi_zhong_xin(pian), 0.52) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var liang := _zuo_tween()
	liang.tween_interval(yan_shi)
	liang.tween_property(jing, "modulate:a", 1.0, 0.30)

	var suo := _zuo_tween()
	suo.tween_interval(yan_shi)
	suo.tween_property(jing, "scale", Vector2.ONE, 0.52) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_wan_jia_pian_luo_di() -> void:
	# 玩家所在格落位：金框亮、镜头俯冲到玩家、鱼上浮翘头、弹“！”气泡
	if _jie_shu_le:
		return
	YinXiang.fang(&"sheng_ji")

	var gao := _zuo_tween()
	gao.tween_property(_gao_liang, "modulate:a", 1.0, 0.25)

	var kan := _zuo_tween()
	kan.set_parallel(true)
	kan.tween_property(_xiang_ji, "position", _wan_jia.global_position, 0.55) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	kan.tween_property(_xiang_ji, "zoom", Vector2.ONE * WAN_JIA_JU_JIAO, 0.55) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	var fu := _zuo_tween()
	fu.set_parallel(true)
	fu.tween_property(_wan_jia, "position", _wan_jia_yuan_wei + Vector2(0.0, -90.0), 0.45) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fu.tween_property(_wan_jia, "rotation", -0.35, 0.45) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_zhen_jing_ke_jian = true
	var zhen := _zuo_tween()
	zhen.tween_interval(0.35)
	zhen.tween_property(_zhen_jing, "modulate:a", 1.0, 0.2)
	var zhen_wen := _zuo_tween()
	zhen_wen.tween_interval(0.35)
	zhen_wen.tween_property(_zhen_jing_wen, "modulate:a", 1.0, 0.2)

	_qu_yu_label.text = "「%s」拼合完成" % _wan_jia_qu_yu_ming
	var qu := _zuo_tween()
	qu.tween_interval(0.45)
	qu.tween_property(_qu_yu_label, "modulate:a", 1.0, 0.25)

	# 特写停留 0.9 秒再拉回全图
	var hui := _zuo_tween()
	hui.tween_interval(1.42)
	hui.tween_callback(_cong_te_xie_hui_quan_tu)


func _cong_te_xie_hui_quan_tu() -> void:
	# 特写结束：镜头拉回全图，鱼落回原位、摆正，气泡与区域字淡出
	if _jie_shu_le:
		return
	var kan := _zuo_tween()
	kan.set_parallel(true)
	kan.tween_property(_xiang_ji, "position", QUAN_TU_ZHONG_XIN, 0.55) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	kan.tween_property(_xiang_ji, "zoom", Vector2.ONE * _quan_tu_bei, 0.55) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var luo := _zuo_tween()
	luo.set_parallel(true)
	luo.tween_property(_wan_jia, "position", _wan_jia_yuan_wei, 0.45) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	luo.tween_property(_wan_jia, "rotation", 0.0, 0.35) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_zhen_jing_ke_jian = false
	var zhen := _zuo_tween()
	zhen.tween_property(_zhen_jing, "modulate:a", 0.0, 0.20)
	var zhen_wen := _zuo_tween()
	zhen_wen.tween_property(_zhen_jing_wen, "modulate:a", 0.0, 0.20)
	var qu := _zuo_tween()
	qu.tween_property(_qu_yu_label, "modulate:a", 0.0, 0.25)


func _kai_shi_ren_lei() -> void:
	# 4.5 秒：警报 + 决战曲 + 人类机器船从正上方压下来 + 红闪 + 标题 + 震屏
	if _jie_shu_le:
		return
	YinXiang.fang(&"jing_bao")
	YinXiang.bo_bgm(&"jue_zhan")

	for ren in _ren_lei:
		var jiang := _zuo_tween()
		jiang.tween_property(ren, "position", REN_LEI_LUO_DIAN, 1.0) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var hong := _zuo_tween()
	hong.tween_property(_hong_guang, "modulate:a", 0.32, 0.22)
	hong.tween_interval(0.85)
	hong.tween_property(_hong_guang, "modulate:a", 0.0, 0.8)

	var biao := _zuo_tween()
	biao.tween_property(_biao_ti, "modulate:a", 1.0, 0.30)
	biao.tween_interval(1.25)
	biao.tween_property(_biao_ti, "modulate:a", 0.0, 0.50)

	_ding_shi(5.15, _zhen_dong)
	_ding_shi(6.6, _shou_wei)


func _zhen_dong() -> void:
	# 定值震屏：6 拍抖动后归零，不影响相机位置 tween
	if _jie_shu_le or _xiang_ji == null:
		return
	var zhen := _zuo_tween()
	for fu in ZHEN_DONG_FU:
		zhen.tween_property(_xiang_ji, "offset", fu, 0.045)
	zhen.tween_property(_xiang_ji, "offset", Vector2.ZERO, 0.12)


func _shou_wei() -> void:
	# 6.6 秒：人类淡出、黑边收、金线/高亮收、镜头俯冲回玩家；7.3 秒交还 Main
	if _jie_shu_le:
		return
	var tiao := _zuo_tween()
	tiao.tween_property(_tiao_guo_an_niu, "modulate:a", 0.0, 0.2)

	var hei_shang := _zuo_tween()
	hei_shang.tween_property(_hei_bian_shang, "offset_bottom", 0.0, 0.45) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	var hei_xia := _zuo_tween()
	hei_xia.tween_property(_hei_bian_xia, "offset_top", 0.0, 0.45) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	for ren in _ren_lei:
		var rong := _zuo_tween()
		rong.tween_property(ren, "modulate:a", 0.0, 0.45)

	for xian in _feng_xian:
		var xian_tw := _zuo_tween()
		xian_tw.tween_property(xian, "modulate:a", 0.0, 0.30)
	var gao := _zuo_tween()
	gao.tween_property(_gao_liang, "modulate:a", 0.0, 0.30)

	var kan := _zuo_tween()
	kan.set_parallel(true)
	kan.tween_property(_xiang_ji, "position", _wan_jia.global_position, 0.65) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	kan.tween_property(_xiang_ji, "zoom", _mo_biao_zoom, 0.65) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func _tiao_guo() -> void:
	# 跳过按钮：直接收尾并让 Main 生成 Boss；只生效一次
	_jie_shu_yan_chu()


func _jie_shu_yan_chu() -> void:
	# 唯一收尾入口：杀所有 tween、还原玩家姿态、广播、自毁
	if _jie_shu_le:
		return
	_jie_shu_le = true
	for tw in _bu_zu:
		if tw != null and tw.is_valid():
			tw.kill()
	_bu_zu.clear()
	_zhen_jing_ke_jian = false
	if is_instance_valid(_wan_jia):
		_wan_jia.position = _wan_jia_yuan_wei
		_wan_jia.rotation = 0.0
	if is_instance_valid(_xiang_ji):
		_xiang_ji.offset = Vector2.ZERO
	jie_shu.emit()
	queue_free()


func _process(_delta: float) -> void:
	# 震惊气泡贴在玩家屏幕位置：相机无论 zoom 0.88 还是 0.31 都跟得住
	if not _zhen_jing_ke_jian:
		return
	if not is_instance_valid(_wan_jia) or not is_instance_valid(_xiang_ji):
		return
	var ping_mu := get_viewport_rect().size
	var ping_mu_zhong_xin := ping_mu * 0.5
	var wan_jia_ping := (_wan_jia.global_position - _xiang_ji.get_screen_center_position()) \
			* _xiang_ji.zoom + ping_mu_zhong_xin
	_zhen_jing.position = wan_jia_ping + Vector2(-100.0, -168.0)
	_zhen_jing_wen.position = wan_jia_ping + Vector2(-110.0, -88.0)


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
