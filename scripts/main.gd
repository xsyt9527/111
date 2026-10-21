extends Node2D
# 主场景协调者：接收输入，告诉玩家鱼往哪游

@onready var yu: Yu = $Yu  # 玩家鱼实例


func _unhandled_input(event: InputEvent) -> void:
	# ScreenTouch.pressed：手指按下；ScreenDrag：按住期间移动
	if event is InputEventScreenTouch and event.pressed:
		_gengxin_mubiao(event.position)
	elif event is InputEventScreenDrag:
		_gengxin_mubiao(event.position)


func _gengxin_mubiao(pingmu_zuobiao: Vector2) -> void:
	# 更新目标点；本场景无相机，屏幕坐标即世界坐标
	yu.mubiao_dian = pingmu_zuobiao
