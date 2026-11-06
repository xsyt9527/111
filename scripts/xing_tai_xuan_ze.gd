extends CanvasLayer
# 形态选择页：启动第一站；每张卡由脚本动态生成，锁定卡禁用
# 12 种形态（玩家 + 10 NPC 鱼 + 鲸鲨）走 4 列网格 + 滚动，一屏放不下时可上下滑
# 选择流程：CunDang 记当前形态 → 账本复位并装形态 → 切 Main

@onready var ka_pian_zu: GridContainer = $KaPianZu/WangGe
@onready var fu_biao_ti: Label = $FuBiaoTi
@onready var ti_shi: Label = $TiShi
@onready var diao_shi_zu: HBoxContainer = $DiaoShiZu
@onready var fan_hui: Button = $FanHui


func _ready() -> void:
	get_tree().paused = false  # 从结算/暂停状态回来也能操作
	YinXiang.bo_bgm()  # 启动第一站就开始放：之后所有场景无缝续曲
	_shua_xin()
	fan_hui.pressed.connect(_on_fan_hui_pressed)
	if OS.has_feature("editor"):
		# 只在编辑器构建暴露调试按钮；导出包不出现
		_jian_diao_shi_an_niu()


func _shua_xin() -> void:
	# 立即移出旧卡再 queue_free：tests 调完马上数子节点也不会看到旧卡
	for zi in ka_pian_zu.get_children():
		ka_pian_zu.remove_child(zi)
		zi.queue_free()
	var quan_bu := CunDang.suo_you_xing_tai()
	var ke_xuan := CunDang.ke_xuan_xing_tai()
	fu_biao_ti.text = "已胜利 %d 次 · 解锁 %d/%d" % [
		CunDang.sheng_li_ci_shu, ke_xuan.size(), quan_bu.size(),
	]
	for xing_tai in quan_bu:
		ka_pian_zu.add_child(_jian_ka(xing_tai))


func _jian_ka(xing_tai: XingTai) -> PanelContainer:
	# 一张形态卡：预览图 + 名称 + 说明 + 数值 + 状态 + 按钮
	var jie_suo := CunDang.shi_fou_jie_suo(xing_tai.bian_hao)
	var dang_qian := xing_tai.bian_hao == CunDang.dang_qian_bian_hao
	var ka := PanelContainer.new()
	ka.name = "Ka_" + String(xing_tai.bian_hao)
	ka.custom_minimum_size = Vector2(268, 350)
	var yang_shi := StyleBoxFlat.new()
	yang_shi.bg_color = Color(0.08, 0.15, 0.23, 0.98)
	yang_shi.content_margin_left = 12.0
	yang_shi.content_margin_right = 12.0
	yang_shi.content_margin_top = 12.0
	yang_shi.content_margin_bottom = 12.0
	yang_shi.corner_radius_top_left = 12
	yang_shi.corner_radius_top_right = 12
	yang_shi.corner_radius_bottom_left = 12
	yang_shi.corner_radius_bottom_right = 12
	for ce in ["left", "right", "top", "bottom"]:
		yang_shi.set("border_width_" + ce, 3)
	if dang_qian:
		yang_shi.border_color = Color(1.0, 0.84, 0.32)
	elif jie_suo:
		yang_shi.border_color = Color(0.35, 0.85, 0.78)
	else:
		yang_shi.border_color = Color(0.28, 0.33, 0.39)
	ka.add_theme_stylebox_override("panel", yang_shi)

	var lie := VBoxContainer.new()
	lie.add_theme_constant_override("separation", 6)
	ka.add_child(lie)

	var yu_lan := TextureRect.new()
	yu_lan.custom_minimum_size = Vector2(0, 84)
	yu_lan.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	yu_lan.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if xing_tai.tie_tu != null:
		yu_lan.texture = xing_tai.tie_tu  # 优先用 3 视图静态侧视：选择页不播动画，姿态更清楚
	elif xing_tai.dong_hua != null and xing_tai.dong_hua.has_animation(&"you"):
		yu_lan.texture = xing_tai.dong_hua.get_frame_texture(&"you", 0)
	lie.add_child(yu_lan)

	var ming := Label.new()
	ming.text = xing_tai.ming_zi
	ming.add_theme_font_size_override("font_size", 24)
	ming.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lie.add_child(ming)

	var miao := Label.new()
	miao.text = xing_tai.miao_shu
	miao.custom_minimum_size = Vector2(0, 44)
	miao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	miao.add_theme_font_size_override("font_size", 13)
	miao.add_theme_color_override("font_color", Color(0.76, 0.84, 0.9, 0.95))
	lie.add_child(miao)

	var shu := Label.new()
	var neng_ming := "无" if xing_tai.kai_ju_neng_li == null else xing_tai.kai_ju_neng_li.ming_zi
	shu.text = "Lv.%d  速度 %d\n嘴巴 %.2f  转向 %.1f\n初始能力：%s" % [
		xing_tai.kai_ju_deng_ji, int(xing_tai.yi_dong_su_du),
		xing_tai.zui_ba, xing_tai.zhuan_xiang_ji_su, neng_ming,
	]
	shu.add_theme_font_size_override("font_size", 13)
	shu.add_theme_color_override("font_color", Color(0.68, 0.8, 0.88, 0.95))
	lie.add_child(shu)

	var kong := Control.new()
	kong.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lie.add_child(kong)

	var zhuang_tai := Label.new()
	zhuang_tai.name = "ZhuangTai"
	zhuang_tai.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zhuang_tai.add_theme_font_size_override("font_size", 13)
	if dang_qian:
		zhuang_tai.text = "当前形态"
		zhuang_tai.add_theme_color_override("font_color", Color(1.0, 0.84, 0.32))
	elif jie_suo:
		zhuang_tai.text = "已解锁"
		zhuang_tai.add_theme_color_override("font_color", Color(0.45, 0.9, 0.7))
	else:
		zhuang_tai.text = "胜利 %d 次解锁（当前 %d 次）" % [
			xing_tai.jie_suo_sheng_li_ci_shu, CunDang.sheng_li_ci_shu,
		]
		zhuang_tai.add_theme_color_override("font_color", Color(0.55, 0.6, 0.66))
	lie.add_child(zhuang_tai)

	var an_niu := Button.new()
	an_niu.name = "AnNiu"
	an_niu.custom_minimum_size = Vector2(0, 38)
	an_niu.add_theme_font_size_override("font_size", 17)
	if not jie_suo:
		an_niu.text = "未解锁"
		an_niu.disabled = true
	elif dang_qian:
		an_niu.text = "当前形态 · 出发"
	else:
		an_niu.text = "选择并出发"
	an_niu.pressed.connect(_on_ka_pian_an_niu.bind(xing_tai))
	lie.add_child(an_niu)
	return ka


func _on_ka_pian_an_niu(xing_tai: XingTai) -> void:
	YinXiang.fang(&"an_niu")
	if not CunDang.xuan_ze(xing_tai.bian_hao):
		ti_shi.text = "这个形态还没解锁"
		return
	ZhangBen.chong_zhi()  # 形态必须在切 Main 前装好：Yu._ready 第一时间读取
	if not ZhangBen.kai_ju_xing_tai(xing_tai):
		ti_shi.text = "形态应用失败"
		return
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_fan_hui_pressed() -> void:
	# 返回主界面：选择页不写任何局内状态，直接切回（中途存档保持原样）
	YinXiang.fang(&"an_niu")
	get_tree().change_scene_to_file("res://scenes/ZhuJieMian.tscn")


func _jian_diao_shi_an_niu() -> void:
	var jie_suo_an := Button.new()
	jie_suo_an.text = "调试：解锁全部形态"
	jie_suo_an.pressed.connect(_on_tiao_shi_jie_suo)
	diao_shi_zu.add_child(jie_suo_an)
	var qing_chu_an := Button.new()
	qing_chu_an.text = "调试：清空进度"
	qing_chu_an.pressed.connect(_on_tiao_shi_qing_chu)
	diao_shi_zu.add_child(qing_chu_an)


func _on_tiao_shi_jie_suo() -> void:
	CunDang.tiao_shi_jie_suo_quan_bu()
	ti_shi.text = "调试：已解锁全部形态"
	_shua_xin()


func _on_tiao_shi_qing_chu() -> void:
	CunDang.tiao_shi_qing_chu_jin_du()
	ti_shi.text = "调试：进度已清空"
	_shua_xin()
