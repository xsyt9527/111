extends CanvasLayer
# 三选一弹窗：听账本升级信号 → 冻结全场 → 抽 3 张卡 → 点选入账 → 恢复
# 根节点 process_mode=When Paused：全场暂停时唯我独醒（否则按钮点不动）

@export var ka_zu: Array[QiangHuaKa] = []  # 卡池注册表（场景里拖入 6 张 .tres，加卡零代码）

var dang_qian_san_zhang: Array[QiangHuaKa] = []  # 本次抽出的 3 张（按钮回调按序号对应）

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
	ZhangBen.sheng_ji.connect(_on_sheng_ji)  # sheng_ji 第三家听众（玩家/经验条之后）
	for i in ming_cheng.size():
		ming_cheng[i].pressed.connect(_on_ka_dian.bind(i))  # 按钮带序号回调（step-04 用）


func _on_sheng_ji(_xin_deng_ji: int) -> void:
	# 升级了：冻结全场 → 不放回抽 3 张 → 填按钮 → 现身
	get_tree().paused = true  # 引擎级暂停：玩家/鱼群/Timer 全停，唯 process_mode 非 Pausable 者独醒
	var dai_chou := ka_zu.duplicate()  # ① 复制：原注册表不动（卡池永远是 6 张）
	dai_chou.shuffle()                 # ② 洗牌：随机性来源
	dang_qian_san_zhang = dai_chou.slice(0, 3)  # ③ 取前 3：不放回，天然无重复
	for i in dang_qian_san_zhang.size():
		ming_cheng[i].text = dang_qian_san_zhang[i].ming_zi
		miao_shu[i].text = dang_qian_san_zhang[i].miao_shu
	visible = true


func _on_ka_dian(i: int) -> void:
	# 点了第 i 张卡：入账 → 解冻 → 藏起来（效果第 7 课由 ka_yi_xuan 回调生效）
	ZhangBen.xuan_ka(dang_qian_san_zhang[i])
	get_tree().paused = false
	visible = false
