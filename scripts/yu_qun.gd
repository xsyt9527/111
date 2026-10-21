extends Node2D
class_name YuQun
# 鱼群生成器：按随机间隔从屏幕两侧生成 NPC 鱼

const YU_NPC_CHANGJING := preload("res://scenes/YuNpc.tscn")  # NPC 鱼蓝图

@export var zuixiao_jiange := 0.6  # 两次生成之间的最短间隔（秒）
@export var zuida_jiange := 1.8    # 两次生成之间的最长间隔（秒）
@export var zuida_shuliang := 14   # 同屏 NPC 鱼数量上限
@export var sudu_fanwei := Vector2(60.0, 160.0)  # 游速随机范围（像素/秒）

@onready var dingshi: Timer = $Dingshi  # 定时器子节点


func _ready() -> void:
	# 定时器到点 → 生成一条鱼；只连接一次
	dingshi.timeout.connect(_on_dingshi_timeout)
	dingshi.start()


func _on_dingshi_timeout() -> void:
	# 没到上限才生成；无论是否生成，都安排下一次
	if _dangqian_yu_shu() < zuida_shuliang:
		_shengcheng_yi_tiao()
	_pai_xia_yi_ci()


func _dangqian_yu_shu() -> int:
	# 只数 YuNpc 子节点（Dingshi 也是子节点，不能直接用 get_child_count）
	var shu := 0
	for zi in get_children():
		if zi is YuNpc:
			shu += 1
	return shu


func _shengcheng_yi_tiao() -> void:
	var xin_yu: YuNpc = YU_NPC_CHANGJING.instantiate()
	xin_yu.sudu = randf_range(sudu_fanwei.x, sudu_fanwei.y)

	# 随机从左或右屏幕外进入；本场景无相机，视口坐标即世界坐标
	var pingmu := get_viewport_rect().size
	var gao := randf_range(60.0, pingmu.y - 60.0)  # 上下留 60 像素边距
	if randf() < 0.5:
		xin_yu.fangxiang = 1.0  # 从左边进，向右游
		xin_yu.position = Vector2(-xin_yu.bianju, gao)
	else:
		xin_yu.fangxiang = -1.0  # 从右边进，向左游
		xin_yu.position = Vector2(pingmu.x + xin_yu.bianju, gao)

	add_child(xin_yu)  # 进树：触发 NPC 的 _ready（随机外观）


func _pai_xia_yi_ci() -> void:
	# 随机间隔：每次重新抽一个等待时长，鱼群密度有起伏
	dingshi.wait_time = randf_range(zuixiao_jiange, zuida_jiange)
	dingshi.start()
