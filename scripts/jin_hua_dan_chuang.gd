extends CanvasLayer
# 进化三选一弹窗：账本升到 Lv.6 → 冻结全场 → 展示玩家 3 条进化分支 → 选定入账 → 解冻
# 根节点 process_mode=Always：全场暂停时唯我独醒
# 与升级三选一的分工：进化是「质变」（每局一次、全数值 ×1.5、专属技能/被动），
# 升到 6 级时升级三选一先排队，进化选完/演出结束后再由它接着弹（NengLiDanChuang 负责排队）

@onready var ka_pian: Array = [
	$KaPianZu/Ka1,
	$KaPianZu/Ka2,
	$KaPianZu/Ka3,
]
@onready var tu: Array = [
	$KaPianZu/Ka1/KaZhong1/Tu,
	$KaPianZu/Ka2/KaZhong2/Tu,
	$KaPianZu/Ka3/KaZhong3/Tu,
]
@onready var fen_zhi_biao: Array = [
	$KaPianZu/Ka1/KaZhong1/FenZhi,
	$KaPianZu/Ka2/KaZhong2/FenZhi,
	$KaPianZu/Ka3/KaZhong3/FenZhi,
]
@onready var ming_cheng: Array = [
	$KaPianZu/Ka1/KaZhong1/MingCheng,
	$KaPianZu/Ka2/KaZhong2/MingCheng,
	$KaPianZu/Ka3/KaZhong3/MingCheng,
]
@onready var miao_shu: Array = [
	$KaPianZu/Ka1/KaZhong1/MiaoShu,
	$KaPianZu/Ka2/KaZhong2/MiaoShu,
	$KaPianZu/Ka3/KaZhong3/MiaoShu,
]

var dang_qian_san_zhang: Array[JinHua] = []  # 本次展示的 3 条分支（按钮回调按序号对应）

@onready var shao_hou: Button = $ShaoHou  # 「稍后再选」：暂缓不打断战斗（策划案 v0.18 8.6）
@onready var yan_chu_dingshi: Timer = $YanChuDingshi  # 进化演出计时：结束才让升级三选一补弹


func _ready() -> void:
	visible = false  # 平时藏着，到 6 级才现身
	layer = 110  # 盖住升级三选一（100）
	add_to_group(&"jin_hua_dan_chuang")  # HUD 提示按组找弹窗，不写死节点路径
	# 登记“进化弹窗在场”：升级三选一据此决定 6 级时先让位；测试场景没有本弹窗，就不会被拖住
	ZhangBen.jin_hua_dan_chuang_zai_chang = true
	ZhangBen.sheng_ji.connect(_on_sheng_ji)
	for i in ming_cheng.size():
		ming_cheng[i].pressed.connect(_on_fen_zhi_dian.bind(i))
	shao_hou.pressed.connect(_on_shao_hou)
	yan_chu_dingshi.timeout.connect(_on_yan_chu_jie_shu)
	# 继续游戏：账本可能已经是 Lv.6 且还没进化 → 进场景补弹一次（已暂缓则不自动打断）
	if ZhangBen.ke_yi_jin_hua() and not ZhangBen.jin_hua_zan_huan:
		_kai_shi.call_deferred()


func _exit_tree() -> void:
	# 离开主场景（结算/重开）：撤销登记，别让下一局的升级三选一白白排队
	ZhangBen.jin_hua_dan_chuang_zai_chang = false
	ZhangBen.jin_hua_zan_huan = false  # 暂缓不跨场景：回主界面不挂着“待选择”
	if ZhangBen.jin_hua_yan_chu_zhong:
		ZhangBen.jie_shu_jin_hua_yan_chu()  # 演出中被迫离场：必须清免伤标志，否则永久无敌


func _on_sheng_ji(_xin_deng_ji: int) -> void:
	# 只在第一次达到门槛时弹；已进化/等级不到 6 → ke_yi_jin_hua 为 false，什么都不做
	# 已暂缓：不自动打断玩家战斗，等 HUD 提示点了再开
	if visible or ZhangBen.jin_hua_zan_huan or not ZhangBen.ke_yi_jin_hua():
		return
	_kai_shi()


func zai_kai() -> void:
	# HUD「进化待选择」点回来：公开入口，外部不直接碰私有 _kai_shi
	if not visible and ZhangBen.ke_yi_jin_hua():
		_kai_shi()


func _kai_shi() -> void:
	# 开一次三选一：候选 = 当前鱼种的 3 条分支（蜗牛鱼/NPC 鱼/鲸鲨各用各的）
	if visible:
		return  # 已经开着：HUD 连点不重入
	dang_qian_san_zhang = JinHuaKu.wan_jia_fen_zhi(ZhangBen.dang_qian_yu_zhong())
	if dang_qian_san_zhang.is_empty():
		return  # 没有可用分支：绝不留在暂停里（防死锁）
	ZhangBen.jin_hua_zan_huan = false  # 重新打开即取消暂缓，HUD 脉动提示随之隐藏
	for i in ka_pian.size():
		if i < dang_qian_san_zhang.size():
			ka_pian[i].visible = true
			var jin_hua := dang_qian_san_zhang[i]
			tu[i].texture = jin_hua.tie_tu
			fen_zhi_biao[i].text = jin_hua.fen_zhi_ming()
			fen_zhi_biao[i].add_theme_color_override("font_color", _fen_zhi_se(jin_hua))
			ming_cheng[i].text = jin_hua.ming_zi
			miao_shu[i].text = jin_hua.miao_shu
		else:
			ka_pian[i].visible = false  # 分支不足 3 条：藏掉多余卡位
	get_tree().paused = true  # 引擎级暂停：玩家/鱼群/Timer 全停
	visible = true
	YinXiang.fang(&"tan_chuang")  # 与升级三选一共用弹窗音


func _on_shao_hou() -> void:
	# 稍后再选：解冻、收起，只置暂缓标志；升级三选一收到信号会立刻补弹当级欠账
	get_tree().paused = false
	visible = false
	dang_qian_san_zhang = []
	YinXiang.fang(&"an_niu")
	ZhangBen.zan_huan_jin_hua()  # 失败（理论上不会）时也不解冻卡死：上面已解冻


func _on_fen_zhi_dian(i: int) -> void:
	# 点了第 i 条分支：先解冻再入账——入账会广播 jin_hua_wan_cheng，
	# 演出期间升级三选一只欠账不弹，演出结束信号到了才补弹，避免暂停盖住演出
	if i < 0 or i >= dang_qian_san_zhang.size():
		return
	var xuan_ze := dang_qian_san_zhang[i]
	get_tree().paused = false
	visible = false
	YinXiang.fang(&"an_niu")
	ZhangBen.kai_shi_jin_hua_yan_chu()  # 先立演出标志，再入账：监听者据此先不弹升级窗
	if not ZhangBen.jin_hua_wei(xuan_ze):
		ZhangBen.jie_shu_jin_hua_yan_chu()  # 理论上不会失败；失败也要清标志，别永久免伤
		return
	dang_qian_san_zhang = []
	yan_chu_dingshi.start(ZhangBen.jin_hua_yan_chu_shi_chang)


func _on_yan_chu_jie_shu() -> void:
	# 演出结束：清免伤标志 + 广播，升级三选一这时才补弹
	ZhangBen.jie_shu_jin_hua_yan_chu()


func _fen_zhi_se(jin_hua: JinHua) -> Color:
	# 分支配色：统一取 JinHua 资源方法（弹窗/图鉴/演出共用一份，避免三处各写一套）
	return jin_hua.fen_zhi_se()
