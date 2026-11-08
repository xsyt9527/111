extends Node2D
# 玩家头顶体型血条：红色填充 + 深色底槽
# Main 挂上时设 top_level = true：脱离玩家鱼的根缩放，屏幕恒定大小；
# 每帧贴到鱼头顶（鱼基准身位 100px × 根缩放，条悬在其上方），血量比读账本（体型=血量）

var mu_biao: Node2D = null  # 跟随的玩家鱼
var kuan := 52.0
var gao := 7.0
var bi_li := 1.0  # 当前血量比：当前体型/上限


func _process(_delta: float) -> void:
	if mu_biao == null or not is_instance_valid(mu_biao):
		return
	bi_li = clampf(ZhangBen.dang_qian_ti_xing / maxf(ZhangBen.ti_xing_shang_xian(), 0.01), 0.0, 1.0)
	# 鱼头顶世界位：基准贴图高 100px × 根缩放的 0.62（身高占比），再悬空 16px
	global_position = mu_biao.global_position + Vector2(0, -(100.0 * mu_biao.scale.y * 0.62 + 16.0))
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-kuan * 0.5 - 1.5, -gao - 1.5, kuan + 3.0, gao + 3.0), Color(0.05, 0.07, 0.11, 0.85))
	draw_rect(Rect2(-kuan * 0.5, -gao, kuan, gao), Color(0.3, 0.33, 0.4, 0.9))  # 底槽
	if bi_li > 0.0:
		draw_rect(Rect2(-kuan * 0.5, -gao, kuan * bi_li, gao), Color(0.95, 0.25, 0.25))  # 红血条
