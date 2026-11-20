extends AnimatedSprite2D
class_name TeXiaoGenSui
# 跟随特效：每帧贴到 mu_biao 当前位置 + 生成时的偏移量（pian_yi）。
# 用途：罩在鱼身上的持续光环（狂暴/硬壳/血腥/磁场）、套在目标头顶的标记（弱点洞察）。
# 目标失效（死亡/出屏回收）时特效就地自毁，避免飘在空气里。

var mu_biao: Node2D
var pian_yi := Vector2.ZERO


func _process(_delta: float) -> void:
	if mu_biao == null or not is_instance_valid(mu_biao):
		queue_free()
		return
	global_position = mu_biao.global_position + pian_yi
