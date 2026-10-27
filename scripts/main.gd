extends Node2D
# 主场景协调者：读摇杆方向，交给玩家鱼（输入层与运动层分离）

@onready var yu: Yu = $Yu  # 玩家鱼实例
@onready var yao_gan: YaoGan = $UI/YaoGan  # 虚拟摇杆（只给方向，不给速度）
@onready var ti_xing_label: Label = $TiXingUI/TiXingLabel  # 体型数字（替代退役的血条）


func _process(_delta: float) -> void:
	# 每帧只转发方向：转多快、游多快由鱼按体型自己算，Main 不掺和运动细节
	yu.fang_xiang = _du_qu_fang_xiang()
	# 体型即血量：数字就是玩家的生命值，保留两位小数便于看清每次 ×0.85
	ti_xing_label.text = "体型 %.2f" % yu.tixing


func _du_qu_fang_xiang() -> Vector2:
	# 调试用键盘：仅 debug 构建生效，方便桌面测试；导出后的正式版仍只认摇杆
	if OS.is_debug_build():
		var jian_pan := Vector2(
			(1.0 if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) else 0.0)
			- (1.0 if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) else 0.0),
			(1.0 if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) else 0.0)
			- (1.0 if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) else 0.0)
		)
		if jian_pan.length() > 0.0:
			return jian_pan.normalized()  # 键盘优先：按下时覆盖摇杆，松开回到摇杆
	return yao_gan.fang_xiang
