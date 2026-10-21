extends Node2D
class_name Yu
# 玩家鱼：移动规则全部在这里（The player fish: all movement rules live here）

@export var yidong_sudu := 300.0  # move speed, pixels per second

var mubiao_dian: Vector2  # move target (world coords), written by Main


func _ready() -> void:
	mubiao_dian = position  # start standing still
