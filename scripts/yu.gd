extends Node2D
class_name Yu
# 玩家鱼：移动规则全部在这里

@export var yidong_sudu := 300.0  # 移动速度，像素/秒

var mubiao_dian: Vector2  # 游动目标点（世界坐标），由 Main 写入


func _ready() -> void:
	mubiao_dian = position  # 开局原地不动
