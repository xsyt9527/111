extends CanvasLayer
# 进化演出层（策划案 v0.18 8.6）：全屏白闪 → 分支主题色铺屏 → 形态名浮现，约 1.7 秒收尾
# 不做暂停/慢放（项目从未用 Engine.time_scale，且会拖住计时器与测试）：
# 世界继续跑、玩家在这 1.7 秒里免伤（Yu.jin_ru_wudi），演出只是盖在世界之上的一张光
# 根节点 process_mode=Always：即使升级三选一在演出末尾弹出暂停，光也能自己走完

@onready var bai_shan: ColorRect = $BaiShan
@onready var fen_zhi_guang: ColorRect = $FenZhiGuang
@onready var ming_zi: Label = $MingZi


func _ready() -> void:
	_jin_zhi()  # 平时全透明：这是一张“没人进化就看不见”的图层
	ZhangBen.jin_hua_wan_cheng.connect(_on_jin_hua_wan_cheng)


func _jin_zhi() -> void:
	bai_shan.modulate.a = 0.0
	fen_zhi_guang.modulate.a = 0.0
	ming_zi.modulate.a = 0.0


func _on_jin_hua_wan_cheng(jin_hua: JinHua) -> void:
	if jin_hua != null:
		bo(jin_hua)


func bo(jin_hua: JinHua) -> void:
	# 播一次演出：公开入口，测试可直接调用（不依赖等真实信号）
	if jin_hua == null:
		return
	_jin_zhi()
	# 白闪：一帧亮起，0.35 秒退干净——先“晃眼”再上主题色
	bai_shan.modulate.a = 0.85
	var bai := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	bai.tween_property(bai_shan, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
	# 分支光：东方金 / 西方紫 / 异化青，铺满全屏后随演出一起淡出
	var guang := jin_hua.fen_zhi_guang_se()
	fen_zhi_guang.color = Color(guang.r, guang.g, guang.b, 1.0)
	fen_zhi_guang.modulate.a = guang.a
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(fen_zhi_guang, "modulate:a", 0.0, ZhangBen.jin_hua_yan_chu_shi_chang) \
			.set_trans(Tween.TRANS_QUAD)
	# 形态名浮现：0.2 秒亮起 → 停留 1 秒 → 0.5 秒淡出
	ming_zi.text = "进化 · " + jin_hua.ming_zi
	ming_zi.add_theme_color_override("font_color", jin_hua.fen_zhi_se())
	var ming := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	ming.tween_property(ming_zi, "modulate:a", 1.0, 0.2)
	ming.tween_interval(1.0)
	ming.tween_property(ming_zi, "modulate:a", 0.0, 0.5)
