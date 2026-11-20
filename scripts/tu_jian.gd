extends CanvasLayer
# 图鉴（主界面入口）：抓鱼船 / 鱼 / 进化 / 主动技能 / 被动 五分类，只读展示
# 数据源：船与鱼走 .tres/动画资源；主动被动走 NengLiKu；进化走 JinHuaKu（显式注册表，导出后也能读）

const CHUAN_ZHAO_DONG_HUA := preload("res://data/donghua/chuan_zhao_4zhen.tres")
const CHUAN_DONG_HUA := preload("res://data/donghua/ji_qi_chuan_4zhen.tres")

const CHUAN_KA: Array[Dictionary] = [
	{"ming": "渔网", "tu": "chuan", "miao": "在玩家脚下画预警圈，0.45 秒后落网。圈内会被失控 1.5 秒，跑出去就能躲开。"},
	{"ming": "机械臂", "tu": "chuan", "miao": "从船底伸向放招瞬间的位置，0.45 秒后砸下，落点固定——持续走位即可躲开。"},
	{"ming": "深水炸弹", "tu": "shen_zha_dan", "miao": "0.5 秒预警后在目标位置爆炸，半径 240。对鲸鲨伤害 ×0.8，是船开局优先打鲸鲨的手段。"},
	{"ming": "船锚横扫", "tu": "chuan_mao", "miao": "朝目标方向横扫 150°：内径 100、外径 480。命中吃 0.7 伤害并被击退 440 像素。"},
	{"ming": "探照灯扫描", "tu": "tan_zhao", "miao": "1120 长、±18° 的光锥，无伤害；被照到移速降到 55%，离开后仍残留 0.4 秒。"},
	{"ming": "鱼叉齐射", "tu": "yu_cha", "miao": "三发鱼叉间隔 0.1 秒，射程 1300，会预判 0.15 秒后的位置；单发命中 0.6 伤害。"},
]

# 船四招 → v2 特效键（渔网/机械臂已退池，没有 v2 资源，不挂预览按钮）
const CHUAN_YU_LAN := {
	"深水炸弹": &"chuan_zha_dan",
	"船锚横扫": &"chuan_chuan_mao",
	"探照灯扫描": &"chuan_tan_zhao",
	"鱼叉齐射": &"chuan_yu_cha",
}

# 被动有可见触发点的 → 预览用特效键；没有表现层的被动不挂按钮
const BEI_DONG_YU_LAN := {
	&"ying_lin_fan_ji": &"fb_fan_shang",
	&"ning_jiao_tan_fu": &"fb_fan_shang_fen",
	&"bao_lie_ti_zhi": &"fb_bao_lie",
	&"dian_gan_shou_qi": &"jn_dian_gan",
	&"du_ji_hu_ti": &"jn_du_puddle",
	&"du_xian": &"jn_du_puddle",
	&"gong_sheng_hai_kui": &"jn_du_puddle",
	&"she_fa_pen_du": &"jn_du_puddle",
	&"xiu_lin": &"jn_dian_gan",
	&"bao_shi_lian_suo": &"fb_lian_suo",
	&"lie_kong_bu": &"jn_ni_liu",
	&"you_ling_chuan_hai": &"jn_ni_liu",
	&"wang_ling_gu_qu": &"fb_si_wang",
	&"xing_chuan_bo_san": &"zu_zhou",
	&"ji_guang_gui_ji": &"ji_guang",
	&"you_ming_ti": &"gui_huo",
	&"xing_zuo_yu_hui": &"xing_chen_po",
	&"shen_yuan_zhuang_jia": &"fb_fan_shang",
	&"xing_yu_ling_yu": &"tun_xing",
	&"lei_yan_suo_ding": &"lei_yan",
	&"shun_feng_yi": &"huan_feng",
	&"gu_zhi_zhong_jia": &"ji_guan",
	&"jue_jing_fan_yao": &"fb_fan_shang",
	&"si_lie_chi": &"fb_chi_rou",
}

const YU_KA: Array[Dictionary] = [
	{"ming": "钻光鱼", "id": &"lan_yu", "path": "res://data/yuzhong/lan_yu.tres"},
	{"ming": "电鳗", "id": &"lv_yu", "path": "res://data/yuzhong/lv_yu.tres"},
	{"ming": "狮子鱼（蓑鲉）", "id": &"cheng_yu", "path": "res://data/yuzhong/cheng_yu.tres"},
	{"ming": "大眼金枪鱼", "id": &"zong_yu", "path": "res://data/yuzhong/zong_yu.tres"},
	{"ming": "旗鱼", "id": &"qi_yu", "path": "res://data/yuzhong/qi_yu.tres"},
	{"ming": "剑鱼", "id": &"jian_yu", "path": "res://data/yuzhong/jian_yu.tres"},
	{"ming": "巨口鱼", "id": &"ju_kou_yu", "path": "res://data/yuzhong/ju_kou_yu.tres"},
	{"ming": "灯笼鱼", "id": &"ye_deng_long_yu", "path": "res://data/yuzhong/ye_deng_long_yu.tres"},
	{"ming": "鲸鲨", "id": &"fen_yu", "path": "res://data/yuzhong/fen_yu.tres"},
]

@onready var fan_hui: Button = $FanHui
@onready var wang_ge: GridContainer = $GunDong/WangGe
@onready var an_niu: Array[Button] = [$FenLei/Chuan, $FenLei/Yu, $FenLei/JinHua, $FenLei/ZhuDong, $FenLei/BeiDong]
@onready var xiang_qing_zhe: Control = $XiangQingZhe
@onready var xq_biao_ti: Label = $XiangQingZhe/MianBan/Lie/BiaoTi
@onready var xq_fu_biao_ti: Label = $XiangQingZhe/MianBan/Lie/FuBiaoTi
@onready var xq_zheng_wen: Label = $XiangQingZhe/MianBan/Lie/ZhengWen
@onready var xq_guan_bi: Button = $XiangQingZhe/MianBan/Lie/GuanBi

var _dang_qian := &"chuan"
var _dian_liang: Dictionary = {}  # 已点亮的进化 id 集合：进图鉴时读一次，不逐卡查存档

# —— 特效预览（TASK-031）：图鉴内直接播 pixelfx v2，不必进局升级抽卡 ——
var _yu_lan_zhe: Control  # 全屏遮罩（懒建：第一次点预览按钮才建）
var _yu_lan_tai: Node2D  # 舞台：特效全部播在这上面
var _yu_lan_huan: Line2D  # 椭圆参照环：宽度 = 当前目标像素宽
var _yu_lan_biao_ti: Label
var _yu_lan_ti_shi: Label
var _yu_lan_kuan_wen: Label
var _yu_lan_hua: HSlider
var _yu_lan_key: StringName = &""
var _yu_lan_kuan := 320.0  # 目标像素宽：拖动滑杆 80~560 演示体型缩放
var _yu_lan_ci := 0  # 重播令牌：旧定时器发现令牌变了就闭嘴，不叠播


func _ready() -> void:
	get_tree().paused = false
	_dian_liang = _du_dian_liang()  # 先读存档再建卡：灰显/点亮一次算好
	fan_hui.pressed.connect(_on_fan_hui_pressed)
	xiang_qing_zhe.visible = false  # 详情遮罩平时藏着
	xq_guan_bi.pressed.connect(_guan_xiang_qing)
	var biao: Array[StringName] = [&"chuan", &"yu", &"jin_hua", &"zhu_dong", &"bei_dong"]
	for i in range(an_niu.size()):
		var id := biao[i]
		an_niu[i].pressed.connect(func() -> void: _qie_huan(id))
	_qie_huan(&"chuan")


func _du_dian_liang() -> Dictionary:
	# 从局外存档读已点亮集合：图鉴是只读页，不写档；测试/独立场景没有 CunDang 时全部按未点亮
	var jie_guo := {}
	var cun_dang := get_node_or_null("/root/CunDang")
	if cun_dang == null:
		return jie_guo
	for id in cun_dang.yi_dian_liang_ming_dan():
		jie_guo[id] = true
	return jie_guo


func _qie_huan(id: StringName) -> void:
	_dang_qian = id
	_guan_xiang_qing()  # 切分类先收详情：别让上一类的形态介绍挂在新列表上
	var biao: Array[StringName] = [&"chuan", &"yu", &"jin_hua", &"zhu_dong", &"bei_dong"]
	for i in range(an_niu.size()):
		an_niu[i].button_pressed = biao[i] == id
		an_niu[i].modulate = Color.WHITE if biao[i] == id else Color(0.72, 0.8, 0.9)
	for zi in wang_ge.get_children():
		wang_ge.remove_child(zi)
		zi.queue_free()
	match id:
		&"chuan":
			_tian_chuan()
		&"yu":
			_tian_yu()
		&"jin_hua":
			_tian_jin_hua()
		&"zhu_dong":
			_tian_neng_li(true)
		&"bei_dong":
			_tian_neng_li(false)


func _tian_chuan() -> void:
	wang_ge.columns = 4
	for ka in CHUAN_KA:
		var tu: Texture2D = null
		if ka["tu"] == "chuan":
			tu = CHUAN_DONG_HUA.get_frame_texture(&"dong", 0)
		else:
			tu = CHUAN_ZHAO_DONG_HUA.get_frame_texture(StringName(ka["tu"]), 0)
		# 现存四招挂特效预览：点按钮直接播，不必开船进局等 CD
		var yu_lan_key: StringName = StringName(CHUAN_YU_LAN.get(String(ka["ming"]), ""))
		_jia_ka(String(ka["ming"]), "抓鱼船 · 攻击方式", String(ka["miao"]), tu,
				Color(0.55, 0.85, 1.0), {}, false, yu_lan_key)


func _tian_yu() -> void:
	wang_ge.columns = 4
	for ka in YU_KA:
		var yz: YuZhong = load(String(ka["path"]))
		var tu: Texture2D = yz.tie_tu if yz != null else null
		# 有进化分支的鱼：直接把三分支名字写在卡上，和「进化」分类互相呼应
		var fen_zhi := _jin_hua_fen_zhi_wen(ka["id"])
		var miao := "介绍待补充"
		if fen_zhi != "":
			miao = "进化分支：" + fen_zhi
		_jia_ka(String(ka["ming"]), "鱼 · 图鉴", miao, tu, Color(0.6, 0.95, 0.75))


func _tian_jin_hua() -> void:
	# 进化分类：一行 = 一条鱼的 3 条分支（东方 / 西方 / 异化），就是策划案里的分支树
	# 玩家凹凸蜗牛鱼排最前（玩家最关心；注册表按策划案顺序把玩家放最后）
	# 点亮规则（策划案 v0.18 8.6）：局内进化过 → 永久点亮；没点亮 → 灰剪影 + ？？？
	wang_ge.columns = 3
	var fen_zu := JinHuaKu.an_ji_yu()
	var shun_xu: Array = []
	for id in fen_zu:
		if id == &"ao_tu_wo_niu_yu":
			shun_xu.push_front(id)
		else:
			shun_xu.append(id)
	for id in shun_xu:
		for jin_hua in fen_zu[id]:
			var liang: bool = _dian_liang.has(jin_hua.bian_hao)
			if not liang:
				_jia_ka("？？？", "未点亮 · 局内进化后永久点亮",
						"在局内 Lv.6 进化成该形态，图鉴卡会永久点亮。", jin_hua.tie_tu,
						Color(0.45, 0.5, 0.58), _xiang_qing_shu_ju(jin_hua, false), true)
				continue
			var miao: String = jin_hua.miao_shu
			if jin_hua.wan_jia_ke_yong:
				miao += "\n可选进化：选中该鱼种后 Lv.6 三选一 · 全数值 ×1.5"
			_jia_ka(jin_hua.ming_zi, "%s · %s" % [jin_hua.ji_yu_ming, jin_hua.fen_zhi_ming()],
					miao, jin_hua.tie_tu, jin_hua.fen_zhi_se(),
					_xiang_qing_shu_ju(jin_hua, true), false)


func _jin_hua_fen_zhi_wen(yu_zhong_id: StringName) -> String:
	# 某鱼种的三条分支名（「鱼」分类卡面用）；没有进化的鱼返回空串
	var zu: Array = JinHuaKu.an_ji_yu().get(yu_zhong_id, [])
	var ming: Array[String] = []
	for jin_hua in zu:
		ming.append(jin_hua.ming_zi)
	return " / ".join(ming)


func _fen_zhi_se(jin_hua: JinHua) -> Color:
	# 分支配色：统一取 JinHua 资源方法（与进化弹窗/演出同一份，不再各写一套）
	return jin_hua.fen_zhi_se()


func _xiang_qing_shu_ju(jin_hua: JinHua, liang: bool) -> Dictionary:
	# 详情面板要显示的全部内容：点卡时直接取这份，不再反查资源
	if jin_hua == null:
		return {}
	if not liang:
		return {
			"biao_ti": "？？？",
			"fu_biao_ti": "尚未点亮的进化形态",
			"zheng_wen": "在局内升到 Lv.6 并选择这条分支完成进化后，这张图鉴会永久点亮。\n\n图鉴进度：%d / %d" % [
					_dian_liang.size(), JinHuaKu.quan_bu().size()],
			"yan_se": Color(0.62, 0.7, 0.8),
		}
	var wen := "基础鱼种：%s\n分支：%s\n\n%s\n\n" % [
			jin_hua.ji_yu_ming, jin_hua.fen_zhi_ming(), jin_hua.miao_shu]
	wen += "专属主动：%s\n" % _neng_li_wen(jin_hua.zhuan_shu_zhu_dong)
	wen += "专属被动：%s\n" % _neng_li_wen(jin_hua.zhuan_shu_bei_dong)
	wen += "\n局内规则：选中该鱼种后 Lv.6 三选一 · 每局一次 · 全数值 ×1.5"
	return {
		"biao_ti": jin_hua.ming_zi,
		"fu_biao_ti": "%s · %s" % [jin_hua.ji_yu_ming, jin_hua.fen_zhi_ming()],
		"zheng_wen": wen,
		"yan_se": jin_hua.fen_zhi_se(),
	}


func _neng_li_wen(neng: NengLi) -> String:
	# 专属技能槽：内容没填时明确写“待定”，不假装已实装
	if neng == null:
		return "待定（槽位已留，填表即生效）"
	return "%s —— %s" % [neng.ming_zi, neng.miao_shu]


func _kai_xiang_qing(shu_ju: Dictionary) -> void:
	if shu_ju.is_empty():
		return
	xq_biao_ti.text = String(shu_ju.get("biao_ti", ""))
	xq_biao_ti.add_theme_color_override("font_color", shu_ju.get("yan_se", Color.WHITE))
	xq_fu_biao_ti.text = String(shu_ju.get("fu_biao_ti", ""))
	xq_zheng_wen.text = String(shu_ju.get("zheng_wen", ""))
	xiang_qing_zhe.visible = true
	YinXiang.fang(&"an_niu")


func _guan_xiang_qing() -> void:
	xiang_qing_zhe.visible = false


func _tian_neng_li(zhu_dong: bool) -> void:
	wang_ge.columns = 4
	for neng in NengLiKu.quan_bu():
		if neng.shi_zhu_dong() != zhu_dong:
			continue
		var lei := "主动技能" if zhu_dong else "被动能力"
		if zhu_dong:
			lei += " · 冷却 %.1f 秒" % neng.leng_que
		else:
			lei += " · 最多 %d 层" % neng.zui_da_dang
		# 主动全走注册表；被动只给“有可见触发点”的那些挂预览（没有表现层的被动不装按钮）
		var yu_lan_key: StringName = &""
		if zhu_dong:
			yu_lan_key = TeXiaoKu.ji_neng_key(neng.bian_hao)
		else:
			yu_lan_key = BEI_DONG_YU_LAN.get(neng.bian_hao, &"")
		_jia_ka(neng.ming_zi, lei, neng.miao_shu, neng.tu_biao,
				Color(1.0, 0.82, 0.45) if zhu_dong else Color(0.65, 0.8, 1.0),
				{}, false, yu_lan_key)


func _jia_ka(ti_ming: String, fu_ming: String, miao: String,
		tu: Texture2D, qiang_diao: Color, xiang_qing: Dictionary = {},
		tu_hui := false, yu_lan_key: StringName = &"") -> void:
	# 一张卡：图 + 标题 + 分类小字 + 介绍；太长的介绍自动换行，卡片高度自适应
	# 传了 xiang_qing 就可点：点击弹详情（进化分类用）；tu_hui = 未点亮，贴图压暗成剪影
	# yu_lan_key 非空 → 卡底加「预览特效」按钮：图鉴里直接播 v2 特效，不必进局升级抽卡
	var ka := PanelContainer.new()
	ka.custom_minimum_size = Vector2(272, 0)
	var yang_shi := StyleBoxFlat.new()
	yang_shi.bg_color = Color(0.045, 0.11, 0.18, 0.9)
	yang_shi.set_corner_radius_all(10)
	yang_shi.set_border_width_all(1)
	yang_shi.border_color = Color(0.25, 0.45, 0.6, 0.55)
	yang_shi.content_margin_left = 10
	yang_shi.content_margin_right = 10
	yang_shi.content_margin_top = 10
	yang_shi.content_margin_bottom = 10
	ka.add_theme_stylebox_override("panel", yang_shi)
	wang_ge.add_child(ka)

	var lie := VBoxContainer.new()
	lie.add_theme_constant_override("separation", 6)
	lie.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 子控件不抢点击：整张卡统一收 gui_input
	ka.add_child(lie)

	var tu_kuang := TextureRect.new()
	tu_kuang.custom_minimum_size = Vector2(248, 150)
	tu_kuang.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tu_kuang.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tu_kuang.texture = tu
	if tu_hui:
		tu_kuang.modulate = Color(0.28, 0.34, 0.42, 0.9)  # 灰剪影：看得出轮廓，看不出细节
	lie.add_child(tu_kuang)

	var ming := Label.new()
	ming.text = ti_ming
	ming.add_theme_font_size_override("font_size", 21)
	ming.add_theme_color_override("font_color", qiang_diao)
	lie.add_child(ming)

	var fu := Label.new()
	fu.text = fu_ming
	fu.add_theme_font_size_override("font_size", 14)
	fu.add_theme_color_override("font_color", Color(0.6, 0.7, 0.82))
	lie.add_child(fu)

	var jie_shao := Label.new()
	jie_shao.text = miao
	jie_shao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	jie_shao.add_theme_font_size_override("font_size", 15)
	jie_shao.add_theme_color_override("font_color", Color(0.82, 0.88, 0.95))
	jie_shao.custom_minimum_size = Vector2(248, 72)
	lie.add_child(jie_shao)

	if String(yu_lan_key) != "" and TeXiaoKu.you(yu_lan_key):
		# 预览按钮：只挂有 v2 资源的卡；子控件默认 STOP，父容器 IGNORE 不影响它收点击
		var yu_lan := Button.new()
		yu_lan.text = "预览特效 ＞"
		yu_lan.custom_minimum_size = Vector2(0, 36)
		yu_lan.add_theme_font_size_override("font_size", 16)
		yu_lan.add_theme_color_override("font_color", Color(0.72, 0.92, 1.0))
		yu_lan.pressed.connect(_on_yu_lan_pressed.bind(yu_lan_key, ti_ming))
		lie.add_child(yu_lan)

	if not xiang_qing.is_empty():
		# 可点卡：底部给一行“查看详情”，点击整张卡（含图/字）都算
		var dian := Label.new()
		dian.text = "查看详情 ＞"
		dian.add_theme_font_size_override("font_size", 13)
		dian.add_theme_color_override("font_color", Color(0.55, 0.78, 0.95))
		dian.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lie.add_child(dian)
		for zi in lie.get_children():
			zi.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ka.mouse_filter = Control.MOUSE_FILTER_STOP
		ka.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		ka.gui_input.connect(_on_ka_gui_input.bind(xiang_qing))


func _on_ka_gui_input(shi_jian: InputEvent, shu_ju: Dictionary) -> void:
	# 只认左键按下：滚轮/右键交给 ScrollContainer 照常滚，不吞事件
	if shi_jian is InputEventMouseButton and shi_jian.pressed \
			and shi_jian.button_index == MOUSE_BUTTON_LEFT:
		_kai_xiang_qing(shu_ju)


func _on_fan_hui_pressed() -> void:
	YinXiang.fang(&"an_niu")
	get_tree().change_scene_to_file("res://scenes/ZhuJieMian.tscn")


func _jian_yu_lan() -> void:
	# 懒建全屏预览遮罩：半透明黑底 + 中央舞台 + 目标像素宽滑杆 + 重播/关闭
	# 舞台在 CanvasLayer 坐标系里，不受世界相机影响；全屏技也按普通尺寸播（图鉴只看表现）
	if _yu_lan_zhe != null:
		return
	_yu_lan_zhe = Control.new()
	_yu_lan_zhe.name = "TeXiaoYuLan"
	_yu_lan_zhe.mouse_filter = Control.MOUSE_FILTER_STOP  # 盖住底下的卡片/滚动
	_yu_lan_zhe.visible = false
	add_child(_yu_lan_zhe)
	_yu_lan_zhe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_yu_lan_zhe.move_to_front()

	var di := ColorRect.new()
	di.color = Color(0.01, 0.035, 0.06, 0.92)
	di.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 背板不吃事件，交给遮罩统一拦
	_yu_lan_zhe.add_child(di)
	di.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_yu_lan_biao_ti = Label.new()
	_yu_lan_biao_ti.position = Vector2(48, 26)
	_yu_lan_biao_ti.add_theme_font_size_override("font_size", 30)
	_yu_lan_biao_ti.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0))
	_yu_lan_zhe.add_child(_yu_lan_biao_ti)

	_yu_lan_ti_shi = Label.new()
	_yu_lan_ti_shi.position = Vector2(48, 72)
	_yu_lan_ti_shi.add_theme_font_size_override("font_size", 16)
	_yu_lan_ti_shi.add_theme_color_override("font_color", Color(0.6, 0.75, 0.88))
	_yu_lan_ti_shi.text = "拖动滑杆：特效随目标像素宽等比放大 · 自动循环预览"
	_yu_lan_zhe.add_child(_yu_lan_ti_shi)

	var guan := Button.new()
	guan.text = "关闭预览"
	guan.add_theme_font_size_override("font_size", 17)
	guan.anchor_left = 1.0
	guan.anchor_right = 1.0
	guan.offset_left = -184.0
	guan.offset_right = -24.0
	guan.offset_top = 26.0
	guan.offset_bottom = 72.0
	guan.pressed.connect(_guan_yu_lan)
	_yu_lan_zhe.add_child(guan)

	_yu_lan_tai = Node2D.new()
	_yu_lan_tai.name = "WuTai"
	_yu_lan_tai.position = Vector2(640, 300)
	_yu_lan_zhe.add_child(_yu_lan_tai)

	_yu_lan_huan = Line2D.new()
	_yu_lan_huan.width = 2.0
	_yu_lan_huan.default_color = Color(0.35, 0.65, 0.85, 0.4)
	_yu_lan_huan.z_index = -1  # 环在特效下面，当尺子用
	_yu_lan_huan.closed = true
	_yu_lan_tai.add_child(_yu_lan_huan)

	var kuan_biao := Label.new()
	kuan_biao.text = "特效目标宽"
	kuan_biao.add_theme_font_size_override("font_size", 16)
	kuan_biao.add_theme_color_override("font_color", Color(0.7, 0.82, 0.94))
	kuan_biao.anchor_left = 0.5
	kuan_biao.anchor_right = 0.5
	kuan_biao.anchor_top = 1.0
	kuan_biao.anchor_bottom = 1.0
	kuan_biao.offset_left = -316.0
	kuan_biao.offset_right = -206.0
	kuan_biao.offset_top = -97.0
	kuan_biao.offset_bottom = -66.0
	_yu_lan_zhe.add_child(kuan_biao)

	_yu_lan_hua = HSlider.new()
	_yu_lan_hua.min_value = 80.0
	_yu_lan_hua.max_value = 560.0
	_yu_lan_hua.step = 10.0
	_yu_lan_hua.value = _yu_lan_kuan
	_yu_lan_hua.anchor_left = 0.5
	_yu_lan_hua.anchor_right = 0.5
	_yu_lan_hua.anchor_top = 1.0
	_yu_lan_hua.anchor_bottom = 1.0
	_yu_lan_hua.offset_left = -196.0
	_yu_lan_hua.offset_right = 196.0
	_yu_lan_hua.offset_top = -100.0
	_yu_lan_hua.offset_bottom = -66.0
	_yu_lan_hua.value_changed.connect(_on_yu_lan_chi_cun)
	_yu_lan_zhe.add_child(_yu_lan_hua)

	_yu_lan_kuan_wen = Label.new()
	_yu_lan_kuan_wen.text = "%d px" % int(_yu_lan_kuan)
	_yu_lan_kuan_wen.add_theme_font_size_override("font_size", 16)
	_yu_lan_kuan_wen.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	_yu_lan_kuan_wen.anchor_left = 0.5
	_yu_lan_kuan_wen.anchor_right = 0.5
	_yu_lan_kuan_wen.anchor_top = 1.0
	_yu_lan_kuan_wen.anchor_bottom = 1.0
	_yu_lan_kuan_wen.offset_left = 206.0
	_yu_lan_kuan_wen.offset_right = 320.0
	_yu_lan_kuan_wen.offset_top = -97.0
	_yu_lan_kuan_wen.offset_bottom = -66.0
	_yu_lan_zhe.add_child(_yu_lan_kuan_wen)

	var chong := Button.new()
	chong.text = "重播"
	chong.add_theme_font_size_override("font_size", 16)
	chong.anchor_left = 0.5
	chong.anchor_right = 0.5
	chong.anchor_top = 1.0
	chong.anchor_bottom = 1.0
	chong.offset_left = -80.0
	chong.offset_right = 80.0
	chong.offset_top = -60.0
	chong.offset_bottom = -16.0
	chong.pressed.connect(_chong_bo_yu_lan)
	_yu_lan_zhe.add_child(chong)


func _bo_yu_lan(key: StringName, ming: String) -> void:
	# 开预览：记下键与标题，滑杆尺寸沿用上次
	if _yu_lan_zhe == null:
		_jian_yu_lan()
	_yu_lan_key = key
	_yu_lan_biao_ti.text = "特效预览 · %s" % ming
	_yu_lan_zhe.visible = true
	_yu_lan_zhe.move_to_front()
	_geng_xin_yu_lan_huan()
	_chong_bo_yu_lan()


func _guan_yu_lan() -> void:
	# 关预览：令牌 +1 让排队中的自动重播全部作废，再清舞台
	_yu_lan_ci += 1
	_yu_lan_key = &""
	if _yu_lan_zhe != null:
		_yu_lan_zhe.visible = false
		_qing_yu_lan_tai()


func _qing_yu_lan_tai() -> void:
	# 只清 v2 特效节点；参照环不是 xiang_su_te_xiao 组成员，留着下次继续当尺子
	if _yu_lan_tai == null:
		return
	for zi in _yu_lan_tai.get_children():
		if zi.is_in_group(&"xiang_su_te_xiao"):
			zi.queue_free()


func _geng_xin_yu_lan_huan() -> void:
	# 椭圆环：宽 = 目标像素宽，高 = 0.42 倍（多数特效横向铺开），给“随体型变大”一把尺子
	if _yu_lan_huan == null:
		return
	var dian := PackedVector2Array()
	var ban := maxf(_yu_lan_kuan, 1.0) * 0.5
	for i in 48:
		var jiao := TAU * float(i) / 48.0
		dian.append(Vector2(cos(jiao) * ban, sin(jiao) * ban * 0.42))
	_yu_lan_huan.points = dian


func _on_yu_lan_chi_cun(zhi: float) -> void:
	# 滑杆每动一步：更新环 + 字，并立刻按新宽度重播——所见即所得
	_yu_lan_kuan = zhi
	if _yu_lan_kuan_wen != null:
		_yu_lan_kuan_wen.text = "%d px" % int(zhi)
	_geng_xin_yu_lan_huan()
	_chong_bo_yu_lan()


func _chong_bo_yu_lan() -> void:
	# 播一帧预览：chi_xu=0 交给重播定时器接管，循环特效不会自己淡出
	if _yu_lan_zhe == null or not _yu_lan_zhe.visible:
		return
	_yu_lan_ci += 1
	_qing_yu_lan_tai()
	if String(_yu_lan_key) == "":
		return
	var fx := TeXiaoKu.bo_ming(_yu_lan_key, _yu_lan_tai, _yu_lan_tai.global_position,
			_yu_lan_kuan, {"chi_xu": 0.0})
	if fx == null:
		_yu_lan_ti_shi.text = "资源缺失：%s" % _yu_lan_key
		return
	var xun_huan := fx.sprite_frames.get_animation_loop(&"bao")
	var zhen := fx.sprite_frames.get_frame_count(&"bao")
	var fps := fx.sprite_frames.get_animation_speed(&"bao")
	var shi := float(zhen) / maxf(fps, 1.0)
	_yu_lan_ti_shi.text = "拖动滑杆：特效随目标像素宽等比放大 · %s · 自动循环预览" % (
			"循环" if xun_huan else "单次")
	# 单次播完停半秒再重播；循环播两轮再重播（确保看到完整节奏）
	var deng := shi * 2.0 + 0.2 if xun_huan else shi + 0.5
	var shu := get_tree()
	if shu == null:
		return
	var ci := _yu_lan_ci
	var ruan: WeakRef = weakref(self)
	shu.create_timer(maxf(deng, 0.6)).timeout.connect(func() -> void:
		var zhu = ruan.get_ref()
		if zhu != null and is_instance_valid(zhu):
			zhu._zi_dong_chong_bo(ci))


func _zi_dong_chong_bo(ci: int) -> void:
	# 定时器回来时先验令牌：换过技能/关过预览/拖过滑杆，这次就作废
	if _yu_lan_zhe != null and _yu_lan_zhe.visible and _yu_lan_ci == ci:
		_chong_bo_yu_lan()


func _on_yu_lan_pressed(key: StringName, ming: String) -> void:
	YinXiang.fang(&"an_niu")
	_bo_yu_lan(key, ming)


func _unhandled_input(shi_jian: InputEvent) -> void:
	# Esc 也能关：手机上关按钮，桌面上顺手按 Esc
	if _yu_lan_zhe != null and _yu_lan_zhe.visible \
			and shi_jian.is_action_pressed(&"ui_cancel"):
		_guan_yu_lan()
		get_viewport().set_input_as_handled()
