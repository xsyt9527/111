extends SceneTree

## Headless CLI validator, builder, and preview frame exporter for Claude.
## Usage examples:
## 1) Validate + Build .tscn / .tres:
##    godot --headless --path . -s addons/ai_rig_2d/validate_rig.gd -- res://rigs/hero.json --build
##
## 2) Validate only (JSON output for Claude parsing):
##    godot --headless --path . -s addons/ai_rig_2d/validate_rig.gd -- res://rigs/hero.json
##
## 3) Validate + Build + Export animation pose snapshots (works even in headless via software Image blit):
##    godot --headless --path . -s addons/ai_rig_2d/validate_rig.gd -- res://rigs/hero.json --build --export-frames res://rigs/previews/ --anim idle --fps 8


func _init() -> void:
	var user_args := OS.get_cmdline_user_args()
	if user_args.is_empty():
		_print_usage()
		quit(1)
		return

	var json_files: Array[String] = []
	var do_build := false
	var export_dir := ""
	var target_anim := ""
	var export_fps := 8

	var i := 0
	while i < user_args.size():
		var arg := user_args[i]
		match arg:
			"--build", "-b":
				do_build = true
			"--export-frames":
				if i + 1 < user_args.size():
					i += 1
					export_dir = user_args[i]
			"--anim":
				if i + 1 < user_args.size():
					i += 1
					target_anim = user_args[i]
			"--fps":
				if i + 1 < user_args.size():
					i += 1
					export_fps = maxi(1, int(user_args[i]))
			"--help", "-h":
				_print_usage()
				quit(0)
				return
			_:
				if arg.ends_with(".json"):
					json_files.append(arg)
				elif DirAccess.dir_exists_absolute(arg):
					for f in AIRigDock._scan_json_files(arg):
						json_files.append(f)
		i += 1

	if json_files.is_empty():
		printerr("[AI_RIG_CLI] Error: No .json file or directory specified.")
		_print_usage()
		quit(1)
		return

	var all_ok := true
	var summary_reports := []

	for jf in json_files:
		var report := _process_single_file(jf, do_build, export_dir, target_anim, export_fps)
		summary_reports.append(report)
		if not bool(report.get("valid", false)):
			all_ok = false

	print("=== AI_RIG_CLI_REPORT_BEGIN ===")
	print(JSON.stringify({"all_valid": all_ok, "results": summary_reports}, "  "))
	print("=== AI_RIG_CLI_REPORT_END ===")

	quit(0 if all_ok else 2)


func _process_single_file(
	json_path: String,
	do_build: bool,
	export_dir: String,
	target_anim: String,
	export_fps: int
) -> Dictionary:
	var val := AIRigSchemaValidator.validate_json_file(json_path)
	var out := {
		"file": json_path,
		"valid": val.valid,
		"errors": val.errors,
		"warnings": val.warnings,
		"built": false,
		"scene_path": "",
		"anim_library_path": "",
		"stats": {},
		"exported_frames": []
	}

	if not val.valid:
		return out

	if do_build or not export_dir.is_empty():
		var build_res := AIRigBuilder.build_from_dict(
			val.data, json_path, do_build, true
		)
		out["warnings"].append_array(build_res.warnings)
		if not build_res.success:
			out["valid"] = false
			out["errors"].append_array(build_res.errors)
			return out

		out["built"] = do_build
		out["scene_path"] = build_res.scene_output_path
		out["anim_library_path"] = build_res.anim_lib_output_path
		out["stats"] = build_res.stats

		if not export_dir.is_empty() and build_res.root_node != null:
			var frames := _export_Diagnostic_frames_headless(
				build_res.root_node, val.data, export_dir, target_anim, export_fps
			)
			out["exported_frames"] = frames

		if build_res.root_node != null:
			build_res.root_node.free()

	return out


func _export_Diagnostic_frames_headless(
	rig_root: Node2D,
	rig_data: Dictionary,
	export_dir: String,
	target_anim: String,
	fps: int
) -> Array[String]:
	# Renders deterministic bone & part pose diagnostic PNGs in pure CPU Image space
	# so `--headless` (which uses the Dummy renderer in Godot 4) always outputs valid PNGs!
	var exported: Array[String] = []
	if not DirAccess.dir_exists_absolute(export_dir):
		DirAccess.make_dir_recursive_absolute(export_dir)

	var anim_player: AnimationPlayer = rig_root.get_node_or_null("AnimationPlayer")
	var skeleton: Skeleton2D = rig_root.get_node_or_null("Skeleton2D")
	if anim_player == null or skeleton == null:
		return exported

	var anim_names: PackedStringArray = anim_player.get_animation_list()
	var to_render: Array[String] = []
	if not target_anim.is_empty() and anim_names.has(target_anim):
		to_render.append(target_anim)
	else:
		for aname in anim_names:
			if aname != "RESET":
				to_render.append(aname)

	var rig_name: String = str(rig_data.get("rig_name", "rig"))
	var canvas_size := Vector2i(128, 128)
	var offset_center := Vector2(32, 32)

	for aname in to_render:
		var anim := anim_player.get_animation(aname)
		if anim == null:
			continue
		var total_frames := maxi(1, int(ceil(anim.length * float(fps))))
		for f_idx in range(total_frames):
			var t := float(f_idx) / float(fps)
			_apply_animation_pose_at_time(anim, rig_root, t)

			var img := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
			img.fill(Color(0.08, 0.09, 0.12, 1.0))

			# Draw each bone segment on the diagnostic image
			for b_node in _collect_bones(skeleton):
				var g_start := AIRigBuilder._get_bone_rest_global_pos(b_node, skeleton) + offset_center
				var g_angle := AIRigBuilder._get_bone_rest_global_rot(b_node, skeleton) + b_node.get_bone_angle()
				var g_end := g_start + Vector2.RIGHT.rotated(g_angle) * b_node.get_length()
				_draw_line_on_image(img, g_start, g_end, Color(0.2, 0.95, 0.55, 1.0))
				_draw_joint_dot(img, g_start, Color(1.0, 0.85, 0.2, 1.0))

			var out_file := export_dir.path_join("%s_%s_f%02d.png" % [rig_name, aname, f_idx])
			img.save_png(out_file)
			exported.append(out_file)

	return exported


func _apply_animation_pose_at_time(anim: Animation, rig_root: Node2D, t: float) -> void:
	for ti in range(anim.get_track_count()):
		var np := anim.track_get_path(ti)
		var node_path_str := "%s/%s" % [np.get_concatenated_names(), ""]
		node_path_str = String(np).get_slice(":", 0)
		var prop_str := String(np).get_slice(":", 1)
		var target_node := rig_root.get_node_or_null(node_path_str)
		if target_node == null:
			continue
		var val: Variant = anim.value_track_interpolate(ti, t)
		match prop_str:
			"position":
				target_node.set("position", val)
			"rotation":
				target_node.set("rotation", val)
			"scale":
				target_node.set("scale", val)


func _collect_bones(parent: Node) -> Array[Bone2D]:
	var list: Array[Bone2D] = []
	for ch in parent.get_children():
		if ch is Bone2D:
			list.append(ch as Bone2D)
		list.append_array(_collect_bones(ch))
	return list


func _draw_line_on_image(img: Image, p0: Vector2, p1: Vector2, col: Color) -> void:
	var steps := maxi(1, int(ceil(p0.distance_to(p1))))
	var w := img.get_width()
	var h := img.get_height()
	for s in range(steps + 1):
		var p := p0.lerp(p1, float(s) / float(steps))
		var ix := int(roundf(p.x))
		var iy := int(roundf(p.y))
		if ix >= 0 and ix < w and iy >= 0 and iy < h:
			img.set_pixel(ix, iy, col)


func _draw_joint_dot(img: Image, center: Vector2, col: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var cx := int(roundf(center.x))
	var cy := int(roundf(center.y))
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var px := cx + dx
			var py := cy + dy
			if px >= 0 and px < w and py >= 0 and py < h:
				img.set_pixel(px, py, col)


func _print_usage() -> void:
	print("Usage: godot --headless --path . -s addons/ai_rig_2d/validate_rig.gd -- <path/to/rig.json|dir> [--build] [--export-frames <dir>] [--anim <name>] [--fps <int>]")
