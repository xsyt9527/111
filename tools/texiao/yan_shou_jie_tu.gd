extends SceneTree
# 特效验收巡礼：逐键播放全部 v2 特效并截图到 tools/texiao/jietu/。
# 用法（必须带窗口跑，不能 headless）：
# Godot控制台.exe --path D:\新游戏001 --script res://tools/texiao/yan_shou_jie_tu.gd

const YU_TU := "res://assets/sucai/shenhai_yu/ao_tu_wo_niu_yu.png"
const CHU_KOU := "res://tools/texiao/jietu"

var _yu: Sprite2D
var _holder: Node2D
var _wei: Vector2


func _initialize() -> void:
	_run()


func _run() -> void:
	root.size = Vector2(1280, 720)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.11, 0.20)
	bg.size = root.size
	root.add_child(bg)
	_wei = root.size * 0.5
	_holder = Node2D.new()
	root.add_child(_holder)
	_yu = Sprite2D.new()
	_yu.texture = load(YU_TU)
	_yu.position = _wei
	root.add_child(_yu)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CHU_KOU))
	await process_frame  # _initialize 阶段节点尚未进树，先等一帧再开始播
	var keys: Array = TeXiaoKuZiYuan.ZI_YUAN.keys()
	keys.sort()
	var i := 0
	for key in keys:
		i += 1
		for c in _holder.get_children():
			c.queue_free()
		# 屏幕层 TeXiaoUI 也要清，否则全屏特效残影串进后面的格子
		var ceng := root.get_node_or_null(^"TeXiaoUI") as CanvasLayer
		if ceng != null:
			for c in ceng.get_children():
				c.queue_free()
		var zi: Dictionary = TeXiaoKuZiYuan.ZI_YUAN[key]
		var can_shu := {}
		var lu_jing: String = zi["lu"]
		if key.begins_with("zt_"):
			# gua_zhuang_tai 第一参数是状态名（去掉 zt_ 前缀），不是资源键
			TeXiaoKu.gua_zhuang_tai(StringName(key.trim_prefix("zt_")), _yu, 1.2)
		elif lu_jing.contains("fb_jing_sha") or lu_jing.contains("zhuan_chang"):
			# bo_jie_mian 第一参数是界面名（jing_sha / zhuan_chang）
			TeXiaoKu.bo_jie_mian(StringName(key.trim_prefix("fb_").trim_prefix("sys_")))
		else:
			if zi["xun_huan"]:
				can_shu["chi_xu"] = maxf(zi["chi_xu"], 0.8)
			TeXiaoKu.bo_ming(key, _holder, _wei, 150.0, can_shu)
		# 双时机截图：9 帧（约0.15s）捕快速单发峰值，30 帧再补一张看持续/尾声
		for f in 9:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path("%s/%02d_%s.png" % [CHU_KOU, i, key]))
		for f in 21:
			await process_frame
		await RenderingServer.frame_post_draw
		img = root.get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path("%s/%02d_%s__2.png" % [CHU_KOU, i, key]))
		for f in 12:
			await process_frame
	print("YAN_SHOU_DONE ", i)
	quit(0)
