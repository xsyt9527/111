extends CanvasLayer
# 结算页：读账本展示本局等级与 build（已选卡名列表）
# 账本是 Autoload 常驻——玩家死了场景销毁，数据还活着，这里见天日（第 6 课预埋数据首次展示）
# 「再来一次」按钮 step-04 接线：chong_zhi + 切回 Main（本步先摆着不接）

func _ready() -> void:
	$ChongKai.pressed.connect(_on_chong_kai_pressed)  # 先接线：空卡分支带 return，放后面会被跳过
	$DengJi.text = "Lv." + str(ZhangBen.deng_ji)
	if ZhangBen.yi_xuan_ka.is_empty():
		var kong := Label.new()
		kong.text = "（一张卡都没选）"
		$KaLieBiao.add_child(kong)
		return
	for ka in ZhangBen.yi_xuan_ka:
		var ming := Label.new()
		ming.text = ka.ming_zi
		$KaLieBiao.add_child(ming)


func _on_chong_kai_pressed() -> void:
	# 重开闭环：先账本归零（常驻者手动复位），再切回 Main（场景侧销毁重建自动全新）
	ZhangBen.chong_zhi()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
