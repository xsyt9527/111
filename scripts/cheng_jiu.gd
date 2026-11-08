extends CanvasLayer
# 成就页（主界面入口）：显示成就值 + 全部主动/被动，花成就值永久解锁开局技能
# 价格与解锁逻辑全在 CunDang（唯一数据源）；本页只做展示与调用，不自己记状态

@onready var fan_hui: Button = $FanHui
@onready var chong_zhi: Button = $ChongZhi
@onready var que_ren: ConfirmationDialog = $QueRen
@onready var cheng_jiu_zhi: Label = $ChengJiuZhi
@onready var shuo_ming: Label = $ShuoMing
@onready var diao_shi: Button = $DiaoShi
@onready var wang_ge: GridContainer = $GunDong/WangGe


func _ready() -> void:
	get_tree().paused = false
	fan_hui.pressed.connect(_on_fan_hui_pressed)
	chong_zhi.pressed.connect(_on_chong_zhi_pressed)
	que_ren.confirmed.connect(_on_chong_zhi_que_ren)
	diao_shi.visible = OS.is_debug_build() or OS.has_feature("ce_shi_ban")  # 调试按钮：编辑器 + 测试版导出包
	diao_shi.pressed.connect(_on_diao_shi_pressed)
	_shua_xin()


func _shua_xin() -> void:
	cheng_jiu_zhi.text = "成就值：%d" % CunDang.cheng_jiu_zhi
	var yi_jie := CunDang.yong_jiu_neng_li.size()
	var chi := NengLiKu.tong_yong_chi()
	shuo_ming.text = "每次通关 +10。已永久解锁 %d / %d。解锁的技能每局开局自动装配（主动 1 档 / 被动 1 层）。" \
			% [yi_jie, chi.size()]
	for zi in wang_ge.get_children():
		wang_ge.remove_child(zi)
		zi.queue_free()
	for neng in chi:
		_jia_ka(neng)


func _jia_ka(neng: NengLi) -> void:
	var ka := PanelContainer.new()
	ka.custom_minimum_size = Vector2(370, 0)
	var yang_shi := StyleBoxFlat.new()
	yang_shi.bg_color = Color(0.045, 0.11, 0.18, 0.92)
	yang_shi.set_corner_radius_all(10)
	yang_shi.set_border_width_all(1)
	yang_shi.border_color = Color(0.25, 0.45, 0.6, 0.5)
	yang_shi.content_margin_left = 10
	yang_shi.content_margin_right = 10
	yang_shi.content_margin_top = 8
	yang_shi.content_margin_bottom = 8
	ka.add_theme_stylebox_override("panel", yang_shi)
	wang_ge.add_child(ka)

	var hang := HBoxContainer.new()
	hang.add_theme_constant_override("separation", 10)
	ka.add_child(hang)

	var tu := TextureRect.new()
	tu.custom_minimum_size = Vector2(88, 88)
	tu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tu.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tu.texture = neng.tu_biao
	hang.add_child(tu)

	var you := VBoxContainer.new()
	you.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	you.add_theme_constant_override("separation", 3)
	hang.add_child(you)

	var ming := Label.new()
	ming.text = neng.ming_zi
	ming.add_theme_font_size_override("font_size", 20)
	ming.add_theme_color_override("font_color",
			Color(1.0, 0.82, 0.45) if neng.shi_zhu_dong() else Color(0.65, 0.85, 1.0))
	you.add_child(ming)

	var jia := CunDang.cheng_jiu_dai_jia(neng)
	var yi_jie := CunDang.you_yong_jiu(neng.bian_hao)
	var lei := "主动" if neng.shi_zhu_dong() else "被动"
	var zhuang := "已永久解锁" if yi_jie else "%s · %d 成就值" % [lei, jia]
	var zi := Label.new()
	zi.text = zhuang
	zi.add_theme_font_size_override("font_size", 14)
	zi.add_theme_color_override("font_color",
			Color(0.45, 0.95, 0.6) if yi_jie else Color(0.7, 0.78, 0.9))
	you.add_child(zi)

	var miao := Label.new()
	miao.text = neng.miao_shu
	miao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	miao.add_theme_font_size_override("font_size", 13)
	miao.add_theme_color_override("font_color", Color(0.78, 0.85, 0.93))
	miao.custom_minimum_size = Vector2(250, 52)
	you.add_child(miao)

	var an_niu := Button.new()
	an_niu.custom_minimum_size = Vector2(0, 32)
	an_niu.add_theme_font_size_override("font_size", 15)
	if yi_jie:
		an_niu.text = "已解锁"
		an_niu.disabled = true
		an_niu.modulate = Color(0.65, 1.0, 0.7)
	else:
		an_niu.text = "解锁（%d）" % jia
		an_niu.disabled = CunDang.cheng_jiu_zhi < jia
		if an_niu.disabled:
			an_niu.tooltip_text = "成就值不足：还差 %d" % (jia - CunDang.cheng_jiu_zhi)
	an_niu.pressed.connect(func() -> void: _jie_suo(neng.bian_hao))
	you.add_child(an_niu)


func _jie_suo(bian_hao: StringName) -> void:
	if not CunDang.jie_suo_yong_jiu(bian_hao):
		return
	YinXiang.fang(&"an_niu")
	_shua_xin()


func _on_chong_zhi_pressed() -> void:
	# 重置是破坏性操作：先弹确认，避免误触把攒的成就值清空
	YinXiang.fang(&"an_niu")
	que_ren.popup_centered()


func _on_chong_zhi_que_ren() -> void:
	# 真正的清账在 CunDang：本页只负责调用与刷新（数据源唯一）
	CunDang.chong_zhi_cheng_jiu()
	YinXiang.fang(&"an_niu")
	_shua_xin()


func _on_diao_shi_pressed() -> void:
	# 仅编辑器：快速攒成就值试玩（导出包不显示这个按钮）
	CunDang.tiao_shi_jia_cheng_jiu(100)
	_shua_xin()


func _on_fan_hui_pressed() -> void:
	YinXiang.fang(&"an_niu")
	get_tree().change_scene_to_file("res://scenes/ZhuJieMian.tscn")
