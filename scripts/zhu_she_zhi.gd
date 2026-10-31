extends CanvasLayer
# 主界面设置面板（游戏外）：调音量 + 调游玩 UI 布局（摇杆侧边）
# 分工：游戏内右上角的 SheZhi 面板管暂停/继续/返回主界面并保存（scripts/she_zhi.gd）；
# 本面板管"游戏怎么顺手"——音量两个滑条 + 摇杆左手/右手切换
# 主界面没有一局在跑：打开本面板不碰 paused；音量拖动即时生效（主界面 BGM 正在放，拖着就能听出大小）
# 按路径找 CunDang/YinXiang：与 yao_gan.gd 同一套编译期零依赖惯例（--script 测试不注册 Autoload）

@onready var mian_ban: PanelContainer = $SheZhiMianBan
@onready var yin_xiao_hua: HSlider = $SheZhiMianBan/MianBanLie/YinXiaoLie/YinXiaoHua
@onready var bgm_hua: HSlider = $SheZhiMianBan/MianBanLie/BgmLie/BgmHua
@onready var yao_gan_an_niu: Button = $SheZhiMianBan/MianBanLie/YaoGanAnNiu
@onready var guan_bi: Button = $SheZhiMianBan/MianBanLie/GuanBi


func _ready() -> void:
	mian_ban.visible = false  # 平时藏着：主界面点"设置"才现身
	yin_xiao_hua.value_changed.connect(_on_yin_liang_bian.bind(&"yin_xiao"))
	bgm_hua.value_changed.connect(_on_yin_liang_bian.bind(&"bgm"))
	# 滑条松手才落盘：拖动过程连发几十次 value_changed，不能每格都写文件
	yin_xiao_hua.drag_ended.connect(func(_gai_dong: bool) -> void: _bao_cun_she_zhi())
	bgm_hua.drag_ended.connect(func(_gai_dong: bool) -> void: _bao_cun_she_zhi())
	yao_gan_an_niu.pressed.connect(_on_yao_gan_an_niu)
	guan_bi.pressed.connect(_on_guan_bi)


func da_kai() -> void:
	# 打开面板：从设置缓存同步控件状态（上次保存的音量/侧边）；set_value_no_signal 不反触发回调
	var cd := get_node_or_null("/root/CunDang")
	if cd != null:
		yin_xiao_hua.set_value_no_signal(float(cd.get("yin_xiao_yin_liang")))
		bgm_hua.set_value_no_signal(float(cd.get("bgm_yin_liang")))
		yao_gan_an_niu.text = "摇杆位置：右下" if String(cd.get("yao_gan_ce")) == "you" \
				else "摇杆位置：左下"
	mian_ban.visible = true


func _on_yin_liang_bian(zhi: float, na_zhong: StringName) -> void:
	# 拖动即时生效：写 CunDang 缓存字段（下次启动的来源）+ 推给 YinXiang（当场听感）
	var cd := get_node_or_null("/root/CunDang")
	if cd == null:
		return
	var yx := get_node_or_null("/root/YinXiang")
	if na_zhong == &"yin_xiao":
		cd.set("yin_xiao_yin_liang", zhi)
		if yx != null:
			yx.set("yin_xiao_yin_liang", zhi)
	else:
		cd.set("bgm_yin_liang", zhi)
		if yx != null:
			yx.set("bgm_yin_liang", zhi)


func _on_yao_gan_an_niu() -> void:
	# 切换摇杆侧边：只写设置，下次进战斗生效（战斗场景此时不在树上，无可即时挪动的控件）
	var cd := get_node_or_null("/root/CunDang")
	if cd == null:
		return
	var huan_cheng_you := String(cd.get("yao_gan_ce")) != "you"
	cd.set("yao_gan_ce", "you" if huan_cheng_you else "zuo")
	yao_gan_an_niu.text = "摇杆位置：右下" if huan_cheng_you else "摇杆位置：左下"
	cd.call("xie_she_zhi")


func _bao_cun_she_zhi() -> void:
	var cd := get_node_or_null("/root/CunDang")
	if cd != null:
		cd.call("xie_she_zhi")


func _on_guan_bi() -> void:
	mian_ban.visible = false
