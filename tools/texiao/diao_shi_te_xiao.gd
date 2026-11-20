extends SceneTree
# 特效显示问题定位：对指定 key 逐步打印 qu_lu/帧数/播放状态
# 用法：Godot控制台.exe --path D:\新游戏001 --script res://tools/texiao/diao_shi_te_xiao.gd

const WEN_TI := [
	"jn_yu_lei", "chuan_zha_dan", "kun_tun",
]


func _initialize() -> void:
	_run()


func _run() -> void:
	root.size = Vector2(1280, 720)
	var holder := Node2D.new()
	root.add_child(holder)
	await process_frame  # _initialize 阶段节点尚未进树，等一帧再播
	var zhong := root.size * 0.5
	for key in WEN_TI:
		var zi: Dictionary = TeXiaoKuZiYuan.ZI_YUAN.get(key, {})
		if zi.is_empty():
			print(key, " | ZI_YUAN MISS")
			continue
		var jie := XiangSuTeXiao.qu_lu(String(zi["lu"]))
		if jie.is_empty():
			print(key, " | qu_lu EMPTY  lu=", zi["lu"])
			continue
		var kuang: SpriteFrames = jie.get("kuang")
		var zhen := kuang.get_frame_count(&"bao") if kuang != null else -1
		var can_shu := {}
		if bool(zi["xun_huan"]):
			can_shu["chi_xu"] = 1.0
		print(key, " | gen_valid=", is_instance_valid(holder), " gen_in_tree=", holder.is_inside_tree(),
			" jie2_empty=", XiangSuTeXiao.qu_lu(String(zi["lu"])).is_empty(),
			" zhen=", zhen, " ke_jian_kuan=", snappedf(XiangSuTeXiao.ke_jian_kuan(jie), 0.1),
			" tex=", (load(String(zi["lu"]).get_basename() + ".png") as Texture2D).get_size())
		var fx := TeXiaoKu.bo_ming(StringName(key), holder, zhong, 150.0, can_shu)
		if fx == null:
			print(key, " | bo_ming NULL  ke_jian_kuan=", XiangSuTeXiao.ke_jian_kuan(jie))
			continue
		print(key, " | zhen=", zhen, " ke_jian_kuan=", snappedf(XiangSuTeXiao.ke_jian_kuan(jie), 0.1),
			" scale=", fx.scale, " playing=", fx.is_playing(), " offset=", fx.offset)
		for f in 9:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tools/texiao/jietu_diaoshi/%s_a.png" % key))
		print(key, " | 9帧后: valid=", is_instance_valid(fx), " playing=", (fx.is_playing() if is_instance_valid(fx) else false),
			" frame=", (fx.get_frame() if is_instance_valid(fx) else -1),
			" gpos=", (fx.global_position.snapped(Vector2(1, 1)) if is_instance_valid(fx) else Vector2.INF),
			" modulate.a=", (fx.modulate.a if is_instance_valid(fx) else -1.0))
		for f in 21:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tools/texiao/jietu_diaoshi/%s_b.png" % key))
		if is_instance_valid(fx):
			print(key, " | 30帧后: frame=", fx.get_frame(), " playing=", fx.is_playing())
		if is_instance_valid(fx):
			fx.queue_free()
		for f in 5:
			await process_frame
	print("DIAO_SHI_DONE")
	quit(0)
