extends CanvasLayer
# 设置面板（游戏内专用，挂在 Main 右上角）：暂停 / 继续 / 返回主界面并保存
# 主界面的"设置"是另一个面板（scripts/zhu_she_zhi.gd）：管音量与摇杆侧边，两者分工不同
# 打开面板即暂停全场：菜单期间世界必须冻结，否则点按钮的工夫玩家可能被咬死、饿死
# 根节点 process_mode=Always（与三选一弹窗同一套惯例）：暂停中按钮照点，
# 未暂停时右上角的"设置"入口也照点——WHEN_PAUSED 会让未暂停时点不动入口，不能那么设

var _ben_mian_zan_ting := false  # 暂停是否本面板所设：三选一弹窗先暂停时，"继续"只收面板、不解冻全场

# 「角色」能力一览：入口按钮与整块面板都用代码建，场景文件只保留原设置项
# 数据全部来自账本：主动读 zhu_dong_zu，被动读 bei_dong_ceng，NengLi 资源按 id 反查
var _jiao_se_an_niu: Button = null  # 设置主菜单里的「角色」入口
var _jiao_se_fu_ceng: Control = null  # 全屏遮罩层：挡住背后设置按钮，关掉后回到设置
var _jiao_se_guan_bi: Button = null  # 能力一览的关闭按钮
var _jiao_se_nei_lie: VBoxContainer = null  # 可滚动内容列：每次打开清空重建

@onready var she_zhi_an_niu: Button = $SheZhiAnNiu
@onready var mian_ban: PanelContainer = $SheZhiMianBan
@onready var mian_ban_lie: VBoxContainer = $SheZhiMianBan/MianBanLie
@onready var zan_ting: Button = $SheZhiMianBan/MianBanLie/ZanTing
@onready var ji_xu: Button = $SheZhiMianBan/MianBanLie/JiXu
@onready var fan_hui: Button = $SheZhiMianBan/MianBanLie/FanHui


func _ready() -> void:
	mian_ban.visible = false  # 平时藏着：点"设置"才现身
	mian_ban.offset_top = -164.0  # 多一个「角色」按钮：面板加高，避免第四行被裁掉
	mian_ban.offset_bottom = 164.0
	she_zhi_an_niu.pressed.connect(_on_she_zhi_an_niu)
	zan_ting.pressed.connect(_on_zan_ting_an_niu)
	ji_xu.pressed.connect(_on_ji_xu_an_niu)
	fan_hui.pressed.connect(_on_fan_hui_an_niu)
	_jian_jiao_se_ru_kou()
	_jian_jiao_se_mian_ban()


func _jian_jiao_se_ru_kou() -> void:
	# 在「继续」和「返回主界面并保存」之间插入「角色」：保持原按钮路径不变
	_jiao_se_an_niu = Button.new()
	_jiao_se_an_niu.name = "JiaoSe"
	_jiao_se_an_niu.text = "角色"
	_jiao_se_an_niu.custom_minimum_size = Vector2(0, 46)
	_jiao_se_an_niu.add_theme_font_size_override("font_size", 18)
	_jiao_se_an_niu.pressed.connect(_on_jiao_se_an_niu)
	mian_ban_lie.add_child(_jiao_se_an_niu)
	mian_ban_lie.move_child(_jiao_se_an_niu, fan_hui.get_index())  # 排在返回之前


func _jian_jiao_se_mian_ban() -> void:
	# 全屏遮罩 + 居中的可滚动面板：竖屏/横屏都用全屏锚点，内容超出就滚
	_jiao_se_fu_ceng = Control.new()
	_jiao_se_fu_ceng.name = "JiaoSeFuCeng"
	_jiao_se_fu_ceng.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_jiao_se_fu_ceng.mouse_filter = Control.MOUSE_FILTER_STOP  # 挡住背后的设置按钮
	_jiao_se_fu_ceng.visible = false
	add_child(_jiao_se_fu_ceng)

	var ban_di := ColorRect.new()
	ban_di.name = "BanDi"
	ban_di.color = Color(0, 0, 0, 0.72)
	ban_di.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ban_di.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_jiao_se_fu_ceng.add_child(ban_di)

	var mian: PanelContainer = PanelContainer.new()
	mian.name = "JiaoSeMianBan"
	mian.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# 留 24 边距：小屏也不贴边；横屏宽、竖屏窄，内容靠 ScrollContainer 自行换行滚动
	mian.offset_left = 24.0
	mian.offset_top = 24.0
	mian.offset_right = -24.0
	mian.offset_bottom = -24.0
	_jiao_se_fu_ceng.add_child(mian)

	var wai := VBoxContainer.new()
	wai.name = "WaiLie"
	wai.add_theme_constant_override("separation", 10)
	mian.add_child(wai)

	var biao_ti_lie := HBoxContainer.new()
	biao_ti_lie.name = "BiaoTiLie"
	biao_ti_lie.add_theme_constant_override("separation", 12)
	wai.add_child(biao_ti_lie)

	var biao_ti := Label.new()
	biao_ti.name = "BiaoTi"
	biao_ti.text = "当前角色"
	biao_ti.add_theme_font_size_override("font_size", 30)
	biao_ti.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	biao_ti.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	biao_ti_lie.add_child(biao_ti)

	_jiao_se_guan_bi = Button.new()
	_jiao_se_guan_bi.name = "GuanBi"
	_jiao_se_guan_bi.text = "关闭"
	_jiao_se_guan_bi.custom_minimum_size = Vector2(104, 44)
	_jiao_se_guan_bi.add_theme_font_size_override("font_size", 18)
	_jiao_se_guan_bi.pressed.connect(_on_jiao_se_guan_bi)
	biao_ti_lie.add_child(_jiao_se_guan_bi)

	var gun_dong := ScrollContainer.new()
	gun_dong.name = "GunDong"
	gun_dong.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gun_dong.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED  # 只竖滚，长描述强制换行
	wai.add_child(gun_dong)

	_jiao_se_nei_lie = VBoxContainer.new()
	_jiao_se_nei_lie.name = "NeiLie"
	_jiao_se_nei_lie.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_jiao_se_nei_lie.add_theme_constant_override("separation", 10)
	gun_dong.add_child(_jiao_se_nei_lie)


func _on_she_zhi_an_niu() -> void:
	# 打开面板即暂停：这是体验主路径，"暂停"按钮留给想明确操作一步的玩家
	YinXiang.fang(&"an_niu")
	_ben_mian_zan_ting = not get_tree().paused  # 打开前没暂停 → 这份暂停是本面板设的
	get_tree().paused = true
	mian_ban.visible = true
	if _jiao_se_fu_ceng != null:
		_jiao_se_fu_ceng.visible = false  # 每次从主设置进入都先收回能力页


func _on_jiao_se_an_niu() -> void:
	# 「角色」入口：设置面板已在暂停中，这里只补一次暂停保护，然后重建最新能力列表
	YinXiang.fang(&"an_niu")
	_ben_mian_zan_ting = _ben_mian_zan_ting or not get_tree().paused
	get_tree().paused = true
	mian_ban.visible = true
	_shua_xin_jiao_se()
	_jiao_se_fu_ceng.visible = true
	_jiao_se_fu_ceng.move_to_front()  # 确保盖在设置主面板上
	if _jiao_se_guan_bi != null:
		_jiao_se_guan_bi.grab_focus()  # 手柄/键盘可直接关闭


func _shua_xin_jiao_se() -> void:
	# 每次打开都从账本重建：本局中途获得能力后再进来，看到的是最新状态
	if _jiao_se_nei_lie == null:
		return
	for zi in _jiao_se_nei_lie.get_children():
		_jiao_se_nei_lie.remove_child(zi)  # 先摘再删：同一帧内不留旧卡片
		zi.queue_free()
	var zhu_dong_shu := 0
	for neng in ZhangBen.zhu_dong_zu:
		if neng != null:
			zhu_dong_shu += 1
	var bei_dong_shu := 0
	for bian_hao in ZhangBen.bei_dong_ceng:
		if int(ZhangBen.bei_dong_ceng[bian_hao]) > 0:
			bei_dong_shu += 1

	if zhu_dong_shu == 0 and bei_dong_shu == 0:
		_jiao_se_nei_lie.add_child(_zuo_kong_zhuang_tai())
		return

	# 主动区：数组本身就是当前装备组；档位从账本读（升过档显示 2/3 档）
	_jiao_se_nei_lie.add_child(_zuo_fen_qu_biao_ti("主动技能"))
	if zhu_dong_shu == 0:
		_jiao_se_nei_lie.add_child(_zuo_kong_wen_an("暂无主动技能"))
	else:
		for neng in ZhangBen.zhu_dong_zu:
			if neng == null:
				continue
			var dang := ZhangBen.dang_qian_zhu_dong_dang(neng.bian_hao)
			var lei_xing := "主动"
			if neng.zui_da_dang > 1:
				lei_xing += " · %d/%d 档" % [dang, neng.zui_da_dang]
			_jiao_se_nei_lie.add_child(_zuo_neng_li_ka(neng, lei_xing, false))

	# 被动区：账本只存 id → 层数，NengLi 资源从本局获得历史/数据目录反查
	_jiao_se_nei_lie.add_child(_zuo_fen_qu_biao_ti("被动能力"))
	if bei_dong_shu == 0:
		_jiao_se_nei_lie.add_child(_zuo_kong_wen_an("暂无被动能力"))
	else:
		for bian_hao in ZhangBen.bei_dong_ceng:
			var ceng := int(ZhangBen.bei_dong_ceng[bian_hao])
			if ceng <= 0:
				continue
			var neng := _zhao_bei_dong_neng(bian_hao)
			if neng == null:
				# 数据缺口兜底：至少让玩家看到「有这个能力」，不整条消失
				neng = NengLi.new()
				neng.bian_hao = bian_hao
				neng.ming_zi = String(bian_hao)
				neng.miao_shu = "（缺少能力数据）"
			var shang := maxi(1, neng.zui_da_dang)
			var lei_xing := "被动 · Lv.%d/%d" % [ceng, shang]
			_jiao_se_nei_lie.add_child(_zuo_neng_li_ka(neng, lei_xing, true))


func _zhao_bei_dong_neng(bian_hao: StringName) -> NengLi:
	# 先查本局获得历史（与 neng_li_ui 同一套口径），再回退到 data/nengli 按 id 载入
	var neng := ZhangBen.zhao_bei_dong(bian_hao)
	if neng != null:
		return neng
	var lu_jing := "res://data/nengli/%s.tres" % String(bian_hao)
	if ResourceLoader.exists(lu_jing):
		var zi_yuan := load(lu_jing)
		if zi_yuan is NengLi:
			return zi_yuan
	return null


func _zuo_neng_li_ka(neng: NengLi, lei_xing_wen: String, shi_bei_dong: bool) -> PanelContainer:
	# 单条能力卡：左图标（无图给文字占位）+ 右名称/类型/数值/长描述自动换行
	var ka := PanelContainer.new()
	ka.name = "KaPian_%s" % String(neng.bian_hao)
	ka.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var heng := HBoxContainer.new()
	heng.add_theme_constant_override("separation", 14)
	ka.add_child(heng)
	heng.add_child(_zuo_tu_biao_kuai(neng))

	var wen_zi := VBoxContainer.new()
	wen_zi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wen_zi.add_theme_constant_override("separation", 6)
	heng.add_child(wen_zi)

	var tou := HBoxContainer.new()
	tou.add_theme_constant_override("separation", 10)
	wen_zi.add_child(tou)
	var ming := Label.new()
	ming.text = neng.ming_zi if neng.ming_zi != "" else String(neng.bian_hao)
	ming.add_theme_font_size_override("font_size", 24)
	ming.add_theme_color_override("font_color", Color(0.93, 0.97, 1, 1))
	ming.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tou.add_child(ming)
	var lei := Label.new()
	lei.text = lei_xing_wen
	lei.add_theme_font_size_override("font_size", 16)
	lei.add_theme_color_override("font_color",
			Color(0.76, 1, 0.82, 0.95) if shi_bei_dong else Color(1.0, 0.86, 0.35, 0.95))
	lei.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tou.add_child(lei)

	var shu_zhi_wen := "" if shi_bei_dong else _zuo_shu_zhi_wen_an(neng)
	if shu_zhi_wen != "":
		var shu_zhi := Label.new()
		shu_zhi.text = shu_zhi_wen
		shu_zhi.add_theme_font_size_override("font_size", 16)
		shu_zhi.add_theme_color_override("font_color", Color(0.72, 0.86, 1, 0.95))
		shu_zhi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		shu_zhi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wen_zi.add_child(shu_zhi)

	var miao := Label.new()
	miao.text = neng.miao_shu if neng.miao_shu != "" else "（暂无描述）"
	miao.add_theme_font_size_override("font_size", 16)
	miao.add_theme_color_override("font_color", Color(0.82, 0.87, 0.93, 0.95))
	miao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	miao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wen_zi.add_child(miao)
	return ka


func _zuo_shu_zhi_wen_an(neng: NengLi) -> String:
	# 主动数值行：只拼有值的项，避免出现「持续 0 秒」这种噪声
	var fen := PackedStringArray()
	if neng.leng_que > 0.0:
		fen.append("冷却 %.1f 秒" % neng.leng_que)
	if neng.chi_xu > 0.0:
		fen.append("持续 %.1f 秒" % neng.chi_xu)
	if neng.ban_jing > 0.0:
		fen.append("半径 %d" % int(round(neng.ban_jing)))
	return " · ".join(fen)


func _zuo_tu_biao_kuai(neng: NengLi) -> Control:
	# 图标块固定 96×96：有图用 TextureRect，无图用深色方块 +「无图」文字，绝不报错
	var kuang := Control.new()
	kuang.custom_minimum_size = Vector2(96, 96)
	kuang.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if neng.tu_biao != null:
		var tu := TextureRect.new()
		tu.texture = neng.tu_biao
		tu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tu.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tu.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		kuang.add_child(tu)
	else:
		var di := PanelContainer.new()
		var yang_shi := StyleBoxFlat.new()
		yang_shi.bg_color = Color(0.12, 0.2, 0.3, 0.9)
		yang_shi.set_corner_radius_all(8)
		di.add_theme_stylebox_override("panel", yang_shi)
		di.mouse_filter = Control.MOUSE_FILTER_IGNORE
		di.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		kuang.add_child(di)
		var zhan := Label.new()
		zhan.text = "无图"
		zhan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		zhan.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		zhan.add_theme_font_size_override("font_size", 15)
		zhan.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 0.9))
		zhan.mouse_filter = Control.MOUSE_FILTER_IGNORE
		di.add_child(zhan)
	return kuang


func _zuo_fen_qu_biao_ti(wen: String) -> Label:
	# 分区标题：主动/被动各一行，和卡面浅蓝文字同一视觉语言
	var biao := Label.new()
	biao.text = wen
	biao.add_theme_font_size_override("font_size", 22)
	biao.add_theme_color_override("font_color", Color(0.78, 0.9, 1, 0.95))
	return biao


func _zuo_kong_wen_an(wen: String) -> Label:
	# 分区为空时的小字提示（另一个区还有内容时使用）
	var biao := Label.new()
	biao.text = wen
	biao.add_theme_font_size_override("font_size", 18)
	biao.add_theme_color_override("font_color", Color(0.72, 0.8, 0.88, 0.9))
	biao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	biao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return biao


func _zuo_kong_zhuang_tai() -> Control:
	# 全局空状态：主动、被动都没有时只显示这一块
	var kuang := VBoxContainer.new()
	kuang.name = "KongZhuangTai"
	kuang.custom_minimum_size = Vector2(0, 220)
	kuang.alignment = BoxContainer.ALIGNMENT_CENTER
	kuang.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var zhu := Label.new()
	zhu.name = "KongZhu"
	zhu.text = "本局还没有获得能力"
	zhu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zhu.add_theme_font_size_override("font_size", 24)
	kuang.add_child(zhu)
	var ci := Label.new()
	ci.text = "升级后从三选一里选一个能力，这里会随本局进度更新。"
	ci.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ci.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ci.add_theme_font_size_override("font_size", 16)
	ci.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 0.9))
	kuang.add_child(ci)
	return kuang


func _on_jiao_se_guan_bi() -> void:
	# 关闭能力页：只收这一层，设置主面板留在背后，暂停状态不在这里解除
	YinXiang.fang(&"an_niu")
	if _jiao_se_fu_ceng != null:
		_jiao_se_fu_ceng.visible = false
	if _jiao_se_an_niu != null:
		_jiao_se_an_niu.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	# Android 返回键 / Esc：能力页开着时先收能力页，回到设置主面板
	if _jiao_se_fu_ceng != null and _jiao_se_fu_ceng.visible \
			and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_jiao_se_guan_bi()


func _on_zan_ting_an_niu() -> void:
	# 暂停按钮：幂等——面板打开时通常已在暂停中，这里是明确的"停"语义（任务要求的独立按钮）
	YinXiang.fang(&"an_niu")
	_ben_mian_zan_ting = _ben_mian_zan_ting or not get_tree().paused
	get_tree().paused = true


func _on_ji_xu_an_niu() -> void:
	# 继续：收起面板；只有本面板设的暂停才解除——
	# 若三选一弹窗正冻结全场，解除暂停会让世界在选卡期间继续跑（鱼还在咬人），绝不能误开
	YinXiang.fang(&"an_niu")
	if _jiao_se_fu_ceng != null:
		_jiao_se_fu_ceng.visible = false  # 防御：能力页开着时也一并收起
	mian_ban.visible = false
	if _ben_mian_zan_ting:
		get_tree().paused = false
	_ben_mian_zan_ting = false


func _on_fan_hui_an_niu() -> void:
	# 返回主界面并保存：先写中途存档（此刻账本状态稳定），再解冻、切主界面
	# 写档失败（磁盘异常）也照切：回主界面总比卡死好，只是这一局没得继续
	YinXiang.fang(&"an_niu")
	CunDang.xie_zhong_tu()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ZhuJieMian.tscn")
