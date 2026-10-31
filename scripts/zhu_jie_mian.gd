extends CanvasLayer
# 主界面（v0.3 起的启动第一站）：开始 / 继续 / 设置 / 退出
# 场景流变化：ZhuJieMian（本页）→ 开始 → XingTaiXuanZe → Main → JieSuan
# 中途存档生命周期：开始游戏清档（开新局不留旧档）；继续游戏载档直达 Main；
# "返回主界面并保存"由游戏内设置面板写入（scripts/she_zhi.gd）

const BAN_BEN_WEN_BEN := "v0.3-原型"  # 左上角版本号：原型阶段手写，不做自动版本管理

@onready var ban_ben: Label = $BanBen
@onready var kai_shi: Button = $AnNiuZu/KaiShi
@onready var ji_xu: Button = $AnNiuZu/JiXu
@onready var she_zhi: Button = $AnNiuZu/SheZhi
@onready var tui_chu: Button = $AnNiuZu/TuiChu
@onready var zhu_she_zhi_mian_ban: CanvasLayer = $ZhuSheZhiMianBan  # 主界面设置面板：音量+摇杆侧边（scripts/zhu_she_zhi.gd）


func _ready() -> void:
	get_tree().paused = false  # 从游戏内暂停状态切回来也能操作（与选择页/结算页同一道保险）
	YinXiang.bo_bgm()  # 启动第一站就放：之后所有场景无缝续曲
	ban_ben.text = BAN_BEN_WEN_BEN
	ji_xu.visible = CunDang.you_zhong_tu()  # 继续游戏按钮显隐 = 是否存在中途存档（生命周期规则④）
	kai_shi.pressed.connect(_on_kai_shi_pressed)
	ji_xu.pressed.connect(_on_ji_xu_pressed)
	she_zhi.pressed.connect(_on_she_zhi_pressed)
	tui_chu.pressed.connect(_on_tui_chu_pressed)
	_gua_gao_liang_yang_shi()


func _gua_gao_liang_yang_shi() -> void:
	# 悬停/聚焦给一条浅底横带（参考稿的交互样式；样式简洁，后续美化只动这里）
	for an_niu: Button in [kai_shi, ji_xu, she_zhi, tui_chu]:
		var gao_liang := StyleBoxFlat.new()
		gao_liang.bg_color = Color(0.85, 0.93, 1.0, 0.22)
		gao_liang.set_corner_radius_all(6)
		an_niu.add_theme_stylebox_override("hover", gao_liang)
		an_niu.add_theme_stylebox_override("focus", gao_liang)


func _on_kai_shi_pressed() -> void:
	# 开始游戏 = 开新局：进形态选择页前先清中途存档（生命周期规则②：新局不留旧档）
	YinXiang.fang(&"an_niu")
	CunDang.qing_chu_zhong_tu()
	get_tree().change_scene_to_file("res://scenes/XingTaiXuanZe.tscn")


func _on_ji_xu_pressed() -> void:
	# 继续游戏：读中途存档 → 写回账本 → 直达 Main（鱼位置/NPC 不恢复，场景重新生成）
	YinXiang.fang(&"an_niu")
	var shu_ju := CunDang.du_zhong_tu()
	if shu_ju.is_empty():
		ji_xu.visible = false  # 档在列目录后被删/损坏：按钮当场藏掉，别给玩家一个空点击
		return
	var xing_tai := CunDang.an_bian_hao_zhao_xing_tai(StringName(String(shu_ju.get("xing_tai", ""))))
	if xing_tai == null:
		# 形态 id 认不出来（版本改动/数据缺失）：档作废，回退到"没有存档"的状态
		CunDang.qing_chu_zhong_tu()
		ji_xu.visible = false
		return
	if not ZhangBen.zai_ru_zhong_tu(shu_ju, xing_tai):
		return
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_she_zhi_pressed() -> void:
	# 主界面设置 = 游戏外设置：音量滑条 + 摇杆侧边（不含暂停——主界面没有一局在跑）
	YinXiang.fang(&"an_niu")
	zhu_she_zhi_mian_ban.da_kai()


func _on_tui_chu_pressed() -> void:
	get_tree().quit()
