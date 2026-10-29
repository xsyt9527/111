extends Node2D
class_name YuQun
# 鱼群生成器：按随机间隔从屏幕两侧生成 NPC 鱼

const YU_NPC_CHANGJING := preload("res://scenes/YuNpc.tscn")  # NPC 鱼蓝图

@export var zuixiao_jiange := 0.6  # 两次生成之间的最短间隔（秒）
@export var zuida_jiange := 1.8    # 两次生成之间的最长间隔（秒）
@export var zuida_shuliang := 14   # 同屏 NPC 鱼数量上限
@export var yu_zhong_zu: Array[YuZhong]  # 鱼种注册表：检查器拖入 .tres——加新鱼不改代码

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
	if not yu_zhong_zu.is_empty():
		# 抽一种鱼，把数据注入新鱼（必须在 add_child 前，_ready 要读它）
		var zhong: YuZhong = yu_zhong_zu.pick_random()
		xin_yu.yu_zhong = zhong
		xin_yu.sudu = randf_range(zhong.sudu_fanwei.x, zhong.sudu_fanwei.y)
	else:
		xin_yu.sudu = 100.0  # 没配鱼种表的兜底，不至于生成静止的鱼

	# 从当前镜头左右两侧外进入；有相机时按相机视野算，没有相机时退回视口
	var fan_wei := _shi_jiao_fan_wei()
	var gao := randf_range(fan_wei.position.y + 60.0, fan_wei.end.y - 60.0)  # 上下留 60 像素边距
	if randf() < 0.5:
		xin_yu.fangxiang = 1.0  # 从左边进，向右游
		xin_yu.position = Vector2(fan_wei.position.x - xin_yu.bianju, gao)
	else:
		xin_yu.fangxiang = -1.0  # 从右边进，向左游
		xin_yu.position = Vector2(fan_wei.end.x + xin_yu.bianju, gao)

	add_child(xin_yu)  # 进树：触发 NPC 的 _ready（随机外观）


func _pai_xia_yi_ci() -> void:
	# 随机间隔：每次重新抽一个等待时长，鱼群密度有起伏
	dingshi.wait_time = randf_range(zuixiao_jiange, zuida_jiange)
	dingshi.start()


func _shi_jiao_fan_wei() -> Rect2:
	# 相机在世界里的可视矩形；用 get_screen_center_position() 才能算上 limit 与平滑
	var pingmu := get_viewport_rect().size
	var shi_jiao := get_viewport().get_camera_2d()
	if shi_jiao != null:
		return Rect2(shi_jiao.get_screen_center_position() - pingmu * 0.5, pingmu)
	return Rect2(Vector2.ZERO, pingmu)
