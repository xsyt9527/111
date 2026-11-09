extends CanvasLayer
# 右下角主动技能按钮组：随账本 zhu_dong_zu 动态生成（装一个冒一个，多槽共存）
# 按钮文字自带「名称 + 冷却读数」，不做独立进度条——变暗 + 文字已够区分
# UI 不自己扣冷却、不自己判断效果——成功与否由 Yu.shi_fang_zhu_dong(neng) 决定
# 长按 0.25 秒看范围：范围由世界层 ji_neng_fan_wei.gd 画，松手/暂停/释放立即收起

const AN_NIU_KUAN := 210.0  # 按钮宽：与旧单按钮一致，右缘仍贴 1250
const AN_NIU_GAO := 64.0   # 按钮高
const AN_NIU_JIAN_JU := 8.0  # 按钮间距
const DI_BU_Y := 680.0     # 最底一个按钮的下缘（贴旧按钮位置）
const CHANG_AN_SHI_CHANG := 0.25  # 按住多久才显示范围（秒）：与短按释放区分开
const FAN_WEI_JIAO_BEN := preload("res://scripts/ji_neng_fan_wei.gd")  # 世界层范围指示：圆/扇形/箭头

var _an_niu_zu: Array[Button] = []  # 当前按钮组：与账本 zhu_dong_zu 下标一一对应
var _an_niu_x := 1250.0 - AN_NIU_KUAN  # 按钮列左缘 x：默认右侧（右缘贴 1250）；摇杆换到右手侧时整列换到左边
var _an_zhu: Array[bool] = []  # 每个按钮当前是否按住：多指同时按时只认最后一次按下
var _an_shi_jian: Array[float] = []  # 每个按钮已按住秒数：到 0.25 才显示范围
var _fan_wei_suo_yin := -1  # 正在显示范围的按钮下标；-1 = 当前没显示
var _fan_wei = null  # 范围指示节点（ji_neng_fan_wei.gd）：首次长按才创建，全局只建一个
var _ti_shi_mai_dong := 0.0  # 进化提示脉动相位：用正弦自己呼吸，不靠 Tween（暂停时不冻结）
var _shan_liang_sheng_yu := 0.0  # C 首局教学：第一个主动按钮高亮剩余秒数（金色，不改按钮逻辑）

@onready var bei_dong_label: Label = $BeiDongLabel
@onready var jin_hua_ti_shi: Button = $JinHuaTiShi  # 「进化待选择」脉动提示（策划案 v0.18 8.6）
@onready var diao_shi_sheng_ji: Button = $DiaoShiShengJi  # 开发测试用：局内直接升 1 级


func _ready() -> void:
	# 玩家可在主界面设置里把摇杆换到右手侧：技能按钮与被动标签跟着换边，别叠在摇杆上
	# 按路径找 CunDang：与 yao_gan.gd 同一套编译期零依赖惯例（--script 测试不注册 Autoload）
	var cd := get_node_or_null("/root/CunDang")
	if cd != null and String(cd.get("yao_gan_ce")) == "you":
		_an_niu_x = 30.0  # 对称位：左缘距屏 30（默认右缘 1250 = 距屏右 30）
		bei_dong_label.position.x = 30.0
		bei_dong_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT  # 换边后贴左缘
	# 死亡会立刻切结算场景，指示节点跟着释放；信号里再收一次，保证切场景前那一帧不残留
	ZhangBen.si_wang.connect(_on_si_wang)
	jin_hua_ti_shi.visible = false  # 平时藏着：只有点了「稍后再选」才脉动提醒
	jin_hua_ti_shi.pressed.connect(_on_jin_hua_ti_shi_pressed)
	# 测试升级按钮：编辑器 / debug 导出 / PC 测试版（ce_shi_ban 特性）可见，其余隐藏
	diao_shi_sheng_ji.visible = OS.is_debug_build() or OS.has_feature("ce_shi_ban")
	diao_shi_sheng_ji.pressed.connect(_on_diao_shi_sheng_ji_pressed)


func _process(delta: float) -> void:
	_shan_liang_sheng_yu = maxf(0.0, _shan_liang_sheng_yu - delta)
	var zu := ZhangBen.zhu_dong_zu
	var wan := get_tree().get_first_node_in_group("player") as Yu
	if _an_niu_zu.size() != zu.size():
		_tong_bu_an_niu(zu.size())  # 装备数变了才重建（free 旧的再 new）
	for i in _an_niu_zu.size():
		var neng := zu[i]
		var an := _an_niu_zu[i]
		if an.icon != neng.tu_biao:
			an.icon = neng.tu_biao  # 有图标就显示在文字左侧；为空时按钮自动回到纯文字
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
		# 可释放 = 玩家存在 + 该能力冷却好 + 没失控 + 没在施放中（释放互斥，跨能力生效）
		var ke_fang := wan != null and sheng <= 0.0 and not ZhangBen.zai_kong_zhi() \
				and not wan._zheng_zai_shi_fang()
		# 冷却中也必须能长按看范围：不再用 disabled 拦输入，只用变暗提示“此刻按了也放不出”；
		# 是否真的放得出仍由 Yu.shi_fang_zhu_dong 说了算（它自己会拒绝冷却/失控/施放中）
		an.disabled = wan == null
		an.modulate = Color.WHITE if ke_fang else Color(0.62, 0.62, 0.62, 0.85)
		if _shan_liang_sheng_yu > 0.0 and i == 0:
			an.modulate = Color(1.7, 1.35, 0.45)  # C 首局教学：首个技能按钮金色高亮 2 秒
	_geng_xin_chang_an(delta, wan)
	_geng_xin_bei_dong()
	_geng_xin_jin_hua_ti_shi(delta)


func shan_liang_di_yi_ge(shi_chang := 2.0) -> void:
	# C 首局教学：把第一个主动按钮点亮一小会儿（只改 modulate，不动按钮状态机）
	_shan_liang_sheng_yu = maxf(_shan_liang_sheng_yu, shi_chang)


func _geng_xin_jin_hua_ti_shi(delta: float) -> void:
	# 进化待选择：账本读数决定显隐；显示时字号/透明度正弦脉动，提醒玩家点回来选
	var dai_xuan := ZhangBen.jin_hua_dai_xuan()
	jin_hua_ti_shi.visible = dai_xuan
	if not dai_xuan:
		_ti_shi_mai_dong = 0.0  # 归零：下次暂缓从最亮开始，不接着上次相位
		return
	_ti_shi_mai_dong += delta
	var liang := 0.55 + 0.45 * (0.5 + 0.5 * sin(_ti_shi_mai_dong * 5.0))
	jin_hua_ti_shi.modulate = Color(1.0, 0.95, 0.8, liang)


func _on_jin_hua_ti_shi_pressed() -> void:
	# 点提示 = 重新打开进化三选一：按组找弹窗，不写死节点路径（与 JinHuaDanChuang 自登记对应）
	var dan_chuang := get_tree().get_first_node_in_group(&"jin_hua_dan_chuang")
	if dan_chuang != null:
		dan_chuang.zai_kai()


func _on_diao_shi_sheng_ji_pressed() -> void:
	# 开发测试按钮：不可见构建里不响应；这里再挡一层，防误触发
	if not (OS.is_debug_build() or OS.has_feature("ce_shi_ban")):
		return
	ZhangBen.tiao_shi_sheng_yi_ji()


func _tong_bu_an_niu(shu: int) -> void:
	# 重建按钮组：竖排右下、自下而上（第 0 个在底位，后装的往上摞）
	for an in _an_niu_zu:
		an.queue_free()
	_an_niu_zu.clear()
	# 槽位换了：正在显示的范围与所有长按计时一起作废，避免旧下标指到新按钮
	_qing_chu_chang_an()
	_yin_cang_fan_wei()
	_an_zhu.resize(shu)
	_an_zhu.fill(false)
	_an_shi_jian.resize(shu)
	_an_shi_jian.fill(0.0)
	for i in shu:
		var an := Button.new()
		# 代码生成的按钮默认 FOCUS_ALL：必须显式关掉，否则空格/回车会误触发技能
		an.focus_mode = Control.FOCUS_NONE
		an.add_theme_font_size_override("font_size", 22)
		an.add_theme_constant_override("icon_max_width", 44)  # 图标源 128：按钮里压到 44，不挤两行文字
		an.expand_icon = true  # 只有开启扩展，icon_max_width 才生效（Godot 的 Button 约定）
		var shang_yuan := DI_BU_Y - AN_NIU_GAO - (AN_NIU_GAO + AN_NIU_JIAN_JU) * i
		an.position = Vector2(_an_niu_x, shang_yuan)
		an.size = Vector2(AN_NIU_KUAN, AN_NIU_GAO)
		# 长按看范围只加 button_down/up：短按/长按松手的释放语义仍由 pressed 负责，不重复调用
		an.button_down.connect(_on_an_niu_down.bind(i))
		an.button_up.connect(_on_an_niu_up.bind(i))
		an.pressed.connect(_on_an_niu_pressed.bind(i))
		add_child(an)
		_an_niu_zu.append(an)


func _on_an_niu_pressed(i: int) -> void:
	# 点击第 i 个按钮：点击瞬间按序号回查账本（槽只增不减，序号在两帧之间稳定）
	# 松手释放技能时顺手收掉范围；长按期间只显示范围，不在这里提前释放
	_yin_cang_fan_wei()
	if i >= 0 and i < _an_zhu.size():
		_an_zhu[i] = false
		_an_shi_jian[i] = 0.0
	if _fan_wei_suo_yin == i:
		_fan_wei_suo_yin = -1
	var wan := get_tree().get_first_node_in_group("player") as Yu
	if wan == null or i >= ZhangBen.zhu_dong_zu.size():
		return
	wan.shi_fang_zhu_dong(ZhangBen.zhu_dong_zu[i])


func _on_an_niu_down(i: int) -> void:
	# 按下开始计时；多指同时按时只认最后一次按下（旧计时作废，避免两个范围来回闪）
	if i < 0 or i >= _an_zhu.size():
		return
	for j in _an_zhu.size():
		if j != i:
			_an_zhu[j] = false
			_an_shi_jian[j] = 0.0
	_an_zhu[i] = true
	_an_shi_jian[i] = 0.0
	if _fan_wei_suo_yin != -1 and _fan_wei_suo_yin != i:
		_fan_wei_suo_yin = -1
		_yin_cang_fan_wei()


func _on_an_niu_up(i: int) -> void:
	# 松手立即藏范围；短按没到阈值就什么也没显示，仍按原语义在 pressed 里释放
	if i < 0 or i >= _an_zhu.size():
		return
	_an_zhu[i] = false
	_an_shi_jian[i] = 0.0
	if _fan_wei_suo_yin == i:
		_fan_wei_suo_yin = -1
		_yin_cang_fan_wei()


func _geng_xin_chang_an(delta: float, wan: Yu) -> void:
	# 每帧推进长按计时；到 0.25 秒仍按住就显示，并持续跟随玩家位置与朝向
	if wan == null or not is_instance_valid(wan):
		_qing_chu_chang_an()
		_yin_cang_fan_wei()
		return
	for i in _an_zhu.size():
		if _an_zhu[i]:
			_an_shi_jian[i] += delta
	var xuan := -1
	if _fan_wei_suo_yin >= 0 and _fan_wei_suo_yin < _an_zhu.size() \
			and _an_zhu[_fan_wei_suo_yin] \
			and _an_shi_jian[_fan_wei_suo_yin] >= CHANG_AN_SHI_CHANG:
		xuan = _fan_wei_suo_yin  # 已显示的那个优先，别被另一根手指抢走
	else:
		for i in _an_zhu.size():
			if _an_zhu[i] and _an_shi_jian[i] >= CHANG_AN_SHI_CHANG:
				xuan = i
				break
	if xuan >= 0:
		_xian_shi_fan_wei(xuan, wan)
	else:
		_fan_wei_suo_yin = -1
		_yin_cang_fan_wei()


func _xian_shi_fan_wei(i: int, wan: Yu) -> void:
	# 按按钮序号回查账本拿当前技能（可能刚升过档），再交给世界层指示节点画
	if i < 0 or i >= ZhangBen.zhu_dong_zu.size():
		_fan_wei_suo_yin = -1
		_yin_cang_fan_wei()
		return
	var jie_dian = _que_bao_fan_wei(wan)
	if jie_dian == null:
		_fan_wei_suo_yin = -1
		return
	var fang := wan.fang_xiang
	if fang.length_squared() < 0.0001:
		fang = Vector2.RIGHT.rotated(wan.dang_qian_jiao)  # 松杆时沿当前朝向，与冲撞施放同一兜底
	jie_dian.xian_shi(ZhangBen.zhu_dong_zu[i], wan.global_position, fang)
	_fan_wei_suo_yin = i


func _que_bao_fan_wei(wan: Yu):
	# 懒创建：第一次长按才建，全局只建一个；挂世界层（玩家父节点）而不是 UI CanvasLayer，
	# 这样范围随相机缩放、坐标就是世界像素，也不用改 Main.tscn
	# 返回不写 Node2D 类型：新脚本方法 xian_shi/yin_cang 是脚本层方法，避免静态类型误报
	if _fan_wei != null and is_instance_valid(_fan_wei):
		return _fan_wei
	if wan == null or not is_instance_valid(wan):
		return null
	var fu: Node = wan.get_parent()
	if fu == null:
		fu = get_tree().current_scene
	if fu == null:
		return null
	_fan_wei = FAN_WEI_JIAO_BEN.new()
	_fan_wei.name = "JiNengFanWei"
	fu.add_child(_fan_wei)
	return _fan_wei


func _yin_cang_fan_wei() -> void:
	if _fan_wei != null and is_instance_valid(_fan_wei):
		_fan_wei.yin_cang()


func _qing_chu_chang_an() -> void:
	# 清空所有按钮的按住状态与计时：重建按钮、暂停、死亡时统一走这里
	for i in _an_zhu.size():
		_an_zhu[i] = false
		_an_shi_jian[i] = 0.0
	_fan_wei_suo_yin = -1


func _on_si_wang() -> void:
	# 死亡：切结算页前先收掉范围，避免世界层残留一帧
	_qing_chu_chang_an()
	_yin_cang_fan_wei()


func _notification(what: int) -> void:
	# 暂停/恢复时清空长按：设置面板、三选一弹窗冻结全场，范围绝不能在暂停里挂着
	# （指示节点自己是 Always，会在暂停瞬间再把可见性收一次，双保险）
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_UNPAUSED:
		_qing_chu_chang_an()
		_yin_cang_fan_wei()


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
