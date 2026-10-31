extends CanvasLayer
# 升级三选一能力弹窗：听账本升级信号 → 冻结全场 → 抽 3 个能力 → 点选入账 → 恢复
# 根节点 process_mode=When Paused：全场暂停时唯我独醒（否则按钮点不动）
# 与旧卡弹窗的区别：候选来自能力池、排除所有已装备主动、50% 强制出现本局最常吃的能力、连续升级排队

@export var neng_li_zu: Array[NengLi] = []  # 能力池注册表（场景里拖入 5 个 .tres，加能力零代码）

var dang_qian_san_zhang: Array[NengLi] = []  # 本次抽出的 3 个（按钮回调按序号对应）
var _rng := RandomNumberGenerator.new()  # 弹窗自己的随机源：测试不实例化弹窗，互不污染
var _dai_chu_ci_shu := 0  # 弹窗开着时又升级了几次：选完继续弹，不吞升级

@onready var ka_pian: Array = [
	$KaPianZu/Ka1,
	$KaPianZu/Ka2,
	$KaPianZu/Ka3,
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


func _ready() -> void:
	visible = false  # 平时藏着，升级才现身
	layer = 100  # 盖住技能按钮/摇杆/其他 UI
	_rng.randomize()
	ZhangBen.sheng_ji.connect(_on_sheng_ji)  # sheng_ji 第三家听众（玩家/经验条之后）
	for i in ming_cheng.size():
		ming_cheng[i].pressed.connect(_on_neng_li_dian.bind(i))  # 按钮带序号回调


func _on_sheng_ji(_xin_deng_ji: int) -> void:
	# 升级了：弹窗还开着就排队，选完再弹；否则立刻开下一轮
	if visible:
		_dai_chu_ci_shu += 1
		return
	_kai_shi()


func _kai_shi() -> void:
	# 开一轮三选一：先算候选（未满档能力：主动可升档、被动可叠层）→ 50% 决定强制项 → 抽 3 个
	var ke_xuan := NengLiChou.ke_xuan_chi(neng_li_zu, ZhangBen.zhu_dong_dang, ZhangBen.bei_dong_ceng)
	var qiang_zhi := NengLiChou.shi_fou_qiang_zhi(_rng)
	dang_qian_san_zhang = NengLiChou.chou_san_zhang(
			ke_xuan, ZhangBen.zui_duo_bian_hao, qiang_zhi, _rng)
	if dang_qian_san_zhang.is_empty():
		# 0 候选：绝不留在暂停里（防死锁）；还有排队的升级就继续尝试
		visible = false
		if _dai_chu_ci_shu > 0:
			_dai_chu_ci_shu -= 1
			_kai_shi()
		else:
			get_tree().paused = false
		return
	_xie_ti_shi(qiang_zhi, ke_xuan)
	for i in ka_pian.size():
		if i < dang_qian_san_zhang.size():
			ka_pian[i].visible = true
			var neng := dang_qian_san_zhang[i]
			ming_cheng[i].text = neng.ming_zi
			miao_shu[i].text = _miao_shu_wen_an(neng)
		else:
			ka_pian[i].visible = false  # 候选不足 3 个：藏掉多余卡位
	get_tree().paused = true  # 引擎级暂停：玩家/鱼群/Timer 全停
	visible = true
	YinXiang.fang(&"tan_chuang")  # 弹窗音：升级琶音（账本侧）之后紧跟“请做选择”


func _on_neng_li_dian(i: int) -> void:
	# 点了第 i 个能力：入账 → 藏起来 → 有排队就继续弹，没有就解冻
	if i < 0 or i >= dang_qian_san_zhang.size():
		return
	var neng := dang_qian_san_zhang[i]
	YinXiang.fang(&"an_niu")
	ZhangBen.xuan_neng_li(neng)  # 主动替换/被动叠层都由账本统一处理
	visible = false
	dang_qian_san_zhang = []
	if _dai_chu_ci_shu > 0:
		_dai_chu_ci_shu -= 1
		_kai_shi()  # 保持暂停，直接弹下一轮
		return
	get_tree().paused = false


func _xie_ti_shi(qiang_zhi: bool, ke_xuan: Array[NengLi]) -> void:
	# 顶部提示：本局最常吃哪种有能力鱼 + 本次是否锁定它
	# 锁定 id 被排除出候选池（已装备的主动）时不显示「已锁定」——落空的锁定只是没锁上
	var wen := ""
	if ZhangBen.zui_duo_bian_hao != &"":
		var zui_duo := _zhao_neng(ZhangBen.zui_duo_bian_hao)
		if zui_duo != null:
			wen = "本局最常吃：%s（50%% 概率出现）" % zui_duo.ming_zi
		else:
			wen = "本局最常吃的能力已不在池中"
	else:
		wen = "本局还没吃过带能力的鱼"
	if qiang_zhi and ZhangBen.zui_duo_bian_hao != &"":
		var suo_ding := false
		for neng in ke_xuan:
			if neng.bian_hao == ZhangBen.zui_duo_bian_hao:
				suo_ding = true  # 锁定的最常吃确实在候选池里才叫锁定；已装备被排除时不谎报
				break
		if suo_ding:
			wen += " · 本次已锁定"
	$TiShi.text = wen


func _miao_shu_wen_an(neng: NengLi) -> String:
	# 卡面：说明 + 来源 + 类型提示（被动叠层 / 主动冷却）
	var wen := neng.miao_shu
	if neng.lai_yuan != "":
		wen += "\n来源：" + neng.lai_yuan
	if neng.shi_zhu_dong():
		var dang := ZhangBen.dang_qian_zhu_dong_dang(neng.bian_hao)
		if dang > 0:
			wen += "\n主动 · 升到 %d/%d 档" % [dang + 1, neng.zui_da_dang]  # 已装备：这是升档卡
		else:
			wen += "\n主动 · 冷却 %.1f 秒" % neng.leng_que
	else:
		var ceng := ZhangBen.dang_qian_bei_dong_ceng(neng.bian_hao)
		wen += "\n被动 · 当前 ×%d → ×%d" % [ceng, ceng + 1]
	return wen


func _zhao_neng(bian_hao: StringName) -> NengLi:
	# 从能力池按 id 反查 Resource（提示行显示名字用）
	for neng in neng_li_zu:
		if neng != null and neng.bian_hao == bian_hao:
			return neng
	return null
