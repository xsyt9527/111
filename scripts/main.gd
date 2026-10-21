extends Node2D
# 主场景协调者：接收输入，告诉玩家鱼往哪游
# Coordinator: receives input, tells the player fish where to go

@onready var yu: Yu = $Yu  # player fish instance


func _unhandled_input(event: InputEvent) -> void:
	# ScreenTouch.pressed: finger went down; ScreenDrag: finger moved while held
	if event is InputEventScreenTouch and event.pressed:
		_gengxin_mubiao(event.position)
	elif event is InputEventScreenDrag:
		_gengxin_mubiao(event.position)


func _gengxin_mubiao(pingmu_zuobiao: Vector2) -> void:
	# update target point; no camera in this scene, so screen coords == world coords
	yu.mubiao_dian = pingmu_zuobiao
	print("mubiao_dian = ", yu.mubiao_dian)  # debug output, remove before course 2
