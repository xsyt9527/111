extends Node2D
class_name Yu
# 玩家鱼：移动规则全部在这里

@export var yidong_sudu := 300.0  # 移动速度，像素/秒

const TINGZHI_JULI := 5.0  # 到达判定距离（像素）：离目标点这么近就算到了

var mubiao_dian: Vector2  # 游动目标点（世界坐标），由 Main 写入


func _ready() -> void:
	mubiao_dian = position  # 开局原地不动


func _process(delta: float) -> void:
	# 已经到达目标点：原地不动
	if position.distance_to(mubiao_dian) <= TINGZHI_JULI:
		return
	# 朝目标点前进：速度 × delta 保证不同帧率下游速一致
	position = position.move_toward(mubiao_dian, yidong_sudu * delta)
	# 鱼头朝向游动方向（贴图默认朝右，目标在左侧时水平翻转）
	$Sprite2D.flip_h = mubiao_dian.x < position.x
