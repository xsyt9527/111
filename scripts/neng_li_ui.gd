extends CanvasLayer
# 右下角主动技能按钮组：随账本 zhu_dong_zu 动态生成（装一个冒一个，多槽共存）
# 按钮文字自带「名称 + 冷却读数」，不做独立进度条——disabled 变灰已够区分
# UI 不自己扣冷却、不自己判断效果——成功与否由 Yu.shi_fang_zhu_dong(neng) 决定

const AN_NIU_KUAN := 210.0  # 按钮宽：与旧单按钮一致，右缘仍贴 1250
const AN_NIU_GAO := 64.0   # 按钮高
const AN_NIU_JIAN_JU := 8.0  # 按钮间距
const DI_BU_Y := 680.0     # 最底一个按钮的下缘（贴旧按钮位置）

var _an_niu_zu: Array[Button] = []  # 当前按钮组：与账本 zhu_dong_zu 下标一一对应
var _an_niu_x := 1250.0 - AN_NIU_KUAN  # 按钮列左缘 x：默认右侧（右缘贴 1250）；摇杆换到右手侧时整列换到左边

@onready var bei_dong_label: Label = $BeiDongLabel


func _ready() -> void:
	# 玩家可在主界面设置里把摇杆换到右手侧：技能按钮与被动标签跟着换边，别叠在摇杆上
	# 按路径找 CunDang：与 yao_gan.gd 同一套编译期零依赖惯例（--script 测试不注册 Autoload）
	var cd := get_node_or_null("/root/CunDang")
	if cd != null and String(cd.get("yao_gan_ce")) == "you":
		_an_niu_x = 30.0  # 对称位：左缘距屏 30（默认右缘 1250 = 距屏右 30）
		bei_dong_label.position.x = 30.0
		bei_dong_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT  # 换边后贴左缘


func _process(_delta: float) -> void:
	var zu := ZhangBen.zhu_dong_zu
	var wan := get_tree().get_first_node_in_group("player") as Yu
	if _an_niu_zu.size() != zu.size():
		_tong_bu_an_niu(zu.size())  # 装备数变了才重建（free 旧的再 new）
	for i in _an_niu_zu.size():
		var neng := zu[i]
		var an := _an_niu_zu[i]
		var sheng := wan.leng_que_sheng(neng.bian_hao) if wan != null else 0.0
		# 升过档的主动在名字后缀档位（·2/·3）：一眼看出“这是升过级的技能”
		var hou_zhui := ""
		var dang_hao := ZhangBen.dang_qian_zhu_dong_dang(neng.bian_hao)
		if dang_hao > 1:
			hou_zhui = " ·%d" % dang_hao
		if sheng <= 0.0:
			an.text = neng.ming_zi + hou_zhui + "\n就绪"
		else:
			an.text = neng.ming_zi + hou_zhui + "\n冷却 %.1fs" % sheng
		# 可按下 = 玩家存在 + 该能力冷却好 + 没失控 + 没在施放中（释放互斥，跨能力生效）
		an.disabled = wan == null or sheng > 0.0 or ZhangBen.zai_kong_zhi() \
				or wan._zheng_zai_shi_fang()
	_geng_xin_bei_dong()


func _tong_bu_an_niu(shu: int) -> void:
	# 重建按钮组：竖排右下、自下而上（第 0 个在底位，后装的往上摞）
	for an in _an_niu_zu:
		an.queue_free()
	_an_niu_zu.clear()
	for i in shu:
		var an := Button.new()
		# 代码生成的按钮默认 FOCUS_ALL：必须显式关掉，否则空格/回车会误触发技能
		an.focus_mode = Control.FOCUS_NONE
		an.add_theme_font_size_override("font_size", 22)
		var shang_yuan := DI_BU_Y - AN_NIU_GAO - (AN_NIU_GAO + AN_NIU_JIAN_JU) * i
		an.position = Vector2(_an_niu_x, shang_yuan)
		an.size = Vector2(AN_NIU_KUAN, AN_NIU_GAO)
		an.pressed.connect(_on_an_niu_pressed.bind(i))
		add_child(an)
		_an_niu_zu.append(an)


func _on_an_niu_pressed(i: int) -> void:
	# 点击第 i 个按钮：点击瞬间按序号回查账本（槽只增不减，序号在两帧之间稳定）
	var wan := get_tree().get_first_node_in_group("player") as Yu
	if wan == null or i >= ZhangBen.zhu_dong_zu.size():
		return
	wan.shi_fang_zhu_dong(ZhangBen.zhu_dong_zu[i])


func _geng_xin_bei_dong() -> void:
	# 被动列表：读账本层数，从本局获得历史反查名字（被动不可替换，只会越叠越高）
	var wen := ""
	for bian_hao in ZhangBen.bei_dong_ceng:
		var ceng := int(ZhangBen.bei_dong_ceng[bian_hao])
		if ceng <= 0:
			continue
		var ming := _zhao_ming(bian_hao)
		if ming == "":
			continue
		if wen != "":
			wen += "  "
		wen += "%s ×%d" % [ming, ceng]
	bei_dong_label.visible = wen != ""
	bei_dong_label.text = wen


func _zhao_ming(bian_hao: StringName) -> String:
	for neng in ZhangBen.yi_xuan_neng_li:
		if neng != null and neng.bian_hao == bian_hao:
			return neng.ming_zi
	return ""
