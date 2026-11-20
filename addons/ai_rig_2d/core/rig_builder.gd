@tool
class_name AIRigBuilder
extends RefCounted

## Core scene and animation builder for AI 2D Rig Builder (v1.1, Godot 4.x / 4.7.2).
## Supports:
## - Relative delta keyframes (`dp`, `drot_deg`, `dscale`) AND absolute keyframes (`v`).
## - Automatic pivot centering (`centered: true` or auto-computed `offset`) in `rigid_parts` mode
##   so limbs/heads rotate around their joint rather than top-left corner.


class BuildResult extends RefCounted:
	var success: bool = false
	var root_node: Node2D = null
	var packed_scene: PackedScene = null
	var animation_library: AnimationLibrary = null
	var scene_output_path: String = ""
	var anim_lib_output_path: String = ""
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var stats: Dictionary = {}


static func build_from_json_file(
	json_path: String, save_outputs: bool = true, allow_placeholder_texture: bool = true
) -> BuildResult:
	var res := BuildResult.new()
	var val := AIRigSchemaValidator.validate_json_file(json_path)
	res.warnings.append_array(val.warnings)
	if not val.valid:
		res.errors.append_array(val.errors)
		return res

	return build_from_dict(val.data, json_path, save_outputs, allow_placeholder_texture, res)


static func build_from_dict(
	data: Dictionary,
	source_json_path: String = "",
	save_outputs: bool = true,
	allow_placeholder_texture: bool = true,
	existing_result: BuildResult = null
) -> BuildResult:
	var res := existing_result if existing_result != null else BuildResult.new()

	var rig_name: String = str(data.get("rig_name", "CharacterRig")).strip_edges()
	var provider_cfg: Dictionary = data.get("provider", {})
	var render_settings: Dictionary = data.get("render_settings", {})

	var pixel_art_mode: bool = bool(render_settings.get("pixel_art_mode", false))
	var integer_pixel_snap: bool = bool(render_settings.get("integer_pixel_snap", pixel_art_mode))
	var nearest_neighbor: bool = bool(render_settings.get("nearest_neighbor", pixel_art_mode))
	var deform_mode: String = str(
		render_settings.get("deform_mode", "rigid_parts" if pixel_art_mode else "mesh_weights")
	)

	var root := Node2D.new()
	root.name = rig_name
	root.set_meta("ai_rig_source_json", source_json_path)
	root.set_meta("ai_rig_schema_version", str(data.get("schema_version", "1.1")))
	root.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST if nearest_neighbor else CanvasItem.TEXTURE_FILTER_LINEAR
	)

	AIRigProceduralRegistry.attach_extension_metadata(root, data)

	var provider: AIRigProviderBase = null
	var ptype: String = str(provider_cfg.get("type", "single_image"))
	if ptype == "single_image":
		provider = AIRigSingleImageProvider.new()
	else:
		provider = AIRigLayeredAtlasProvider.new()

	var mesh_data := provider.build_mesh_data(provider_cfg, render_settings, allow_placeholder_texture)
	res.warnings.append_array(mesh_data.warnings)

	var visuals := Node2D.new()
	visuals.name = "Visuals"
	root.add_child(visuals)
	visuals.owner = root

	var skeleton := Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	root.add_child(skeleton)
	skeleton.owner = root

	var bones_arr: Array = data.get("bones", [])
	var bone_nodes := {}
	var bone_defs := {}
	var bone_rel_paths := {}

	var pending := bones_arr.duplicate()
	var safety_counter := 0
	while not pending.is_empty() and safety_counter <= bones_arr.size() * 2:
		safety_counter += 1
		var next_pending: Array = []
		for b_var in pending:
			var b: Dictionary = b_var
			var bname: String = str(b.get("name")).strip_edges()
			var parent_val: Variant = b.get("parent", null)
			var parent_name: String = "" if parent_val == null else str(parent_val).strip_edges()

			if not parent_name.is_empty() and not bone_nodes.has(parent_name):
				next_pending.append(b)
				continue

			var bone := Bone2D.new()
			bone.name = bname
			bone.set_autocalculate_length_and_angle(false)

			var pos_arr: Array = b.get("position", [0.0, 0.0])
			var px := float(pos_arr[0])
			var py := float(pos_arr[1])
			if integer_pixel_snap:
				px = roundf(px)
				py = roundf(py)
			bone.position = Vector2(px, py)
			bone.rotation_degrees = float(b.get("rotation_deg", 0.0))

			var scale_arr: Array = b.get("scale", [1.0, 1.0])
			bone.scale = Vector2(float(scale_arr[0]), float(scale_arr[1]))
			bone.set_length(maxf(1.0, float(b.get("length", 16.0))))
			if b.has("bone_angle_deg"):
				bone.set_bone_angle(deg_to_rad(float(b.get("bone_angle_deg", 0.0))))

			if parent_name.is_empty():
				skeleton.add_child(bone)
			else:
				var p_node: Bone2D = bone_nodes[parent_name]
				p_node.add_child(bone)

			bone.owner = root
			bone_nodes[bname] = bone
			bone_defs[bname] = b
		pending = next_pending

	for bname in bone_nodes.keys():
		var bone: Bone2D = bone_nodes[bname]
		bone.rest = bone.transform
		bone_rel_paths[bname] = skeleton.get_path_to(bone)

	if deform_mode == "mesh_weights":
		var poly := Polygon2D.new()
		poly.name = "BodyMesh"
		poly.texture = mesh_data.texture
		poly.polygon = mesh_data.vertices
		poly.uv = mesh_data.uvs
		poly.polygons = mesh_data.polygons
		poly.internal_vertex_count = mesh_data.internal_vertex_count
		if nearest_neighbor:
			poly.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

		visuals.add_child(poly)
		poly.owner = root
		poly.skeleton = poly.get_path_to(skeleton)

		var bone_segments: Array[Dictionary] = []
		for bname in bone_nodes.keys():
			var bone: Bone2D = bone_nodes[bname]
			var bdef: Dictionary = bone_defs[bname]
			var g_start := _get_bone_rest_global_pos(bone, skeleton)
			var g_angle := _get_bone_rest_global_rot(bone, skeleton) + bone.get_bone_angle()
			var g_end := g_start + Vector2.RIGHT.rotated(g_angle) * bone.get_length()
			bone_segments.append({
				"name": bname,
				"global_start": g_start,
				"global_end": g_end,
				"envelope_radius": float(bdef.get("envelope_radius", maxf(12.0, bone.get_length() * 0.85)))
			})

		var weights_cfg: Dictionary = data.get("weights", {"mode": "auto_envelope"})
		var computed_weights := AIRigWeightCalculator.compute_bone_weights(
			mesh_data.vertices, bone_segments, weights_cfg
		)

		poly.clear_bones()
		for bname in bone_nodes.keys():
			var rel_path: NodePath = bone_rel_paths[bname]
			var w_arr: PackedFloat32Array = computed_weights.get(bname, PackedFloat32Array())
			poly.add_bone(rel_path, w_arr)

	elif deform_mode == "rigid_parts":
		var parts_arr: Array = data.get("parts", [])
		if parts_arr.is_empty() and not bone_nodes.is_empty():
			var first_bone_name: String = str((bones_arr[0] as Dictionary).get("name"))
			var first_bone: Bone2D = bone_nodes[first_bone_name]
			var g_pos := _get_bone_rest_global_pos(first_bone, skeleton)
			parts_arr = [{
				"name": "BodySprite",
				"bone": first_bone_name,
				"region_rect": [0, 0, int(mesh_data.texture_size.x), int(mesh_data.texture_size.y)],
				"offset": [-g_pos.x, -g_pos.y],
				"centered": false
			}]

		for p_var in parts_arr:
			var p_cfg: Dictionary = p_var
			var pname: String = str(p_cfg.get("name", "PartSprite"))
			var target_bone_name: String = str(p_cfg.get("bone", ""))
			if not bone_nodes.has(target_bone_name):
				continue
			var parent_bone: Bone2D = bone_nodes[target_bone_name]
			var bone_global := _get_bone_rest_global_pos(parent_bone, skeleton)
			var sp := Sprite2D.new()
			sp.name = pname
			sp.texture = mesh_data.texture
			sp.centered = bool(p_cfg.get("centered", false))
			if nearest_neighbor:
				sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var rr_vec := Rect2(0, 0, mesh_data.texture_size.x, mesh_data.texture_size.y)
			if p_cfg.has("region_rect"):
				var rr: Array = p_cfg["region_rect"]
				rr_vec = Rect2(float(rr[0]), float(rr[1]), float(rr[2]), float(rr[3]))
				sp.region_enabled = true
				sp.region_rect = rr_vec

			# Auto-align part to its exact pixel position on the original sprite sheet
			# if `offset` is omitted or set to "auto"!
			if p_cfg.has("offset") and typeof(p_cfg["offset"]) == TYPE_ARRAY:
				var off: Array = p_cfg["offset"]
				var ox := float(off[0])
				var oy := float(off[1])
				if integer_pixel_snap:
					ox = roundf(ox)
					oy = roundf(oy)
				sp.offset = Vector2(ox, oy)
			else:
				# Default automatic alignment: place region_rect at [rr.x, rr.y] in character global space
				var auto_ox := rr_vec.position.x - bone_global.x
				var auto_oy := rr_vec.position.y - bone_global.y
				if integer_pixel_snap:
					auto_ox = roundf(auto_ox)
					auto_oy = roundf(auto_oy)
				sp.offset = Vector2(auto_ox, auto_oy)

			if p_cfg.has("z_index"):
				sp.z_index = int(p_cfg["z_index"])
			parent_bone.add_child(sp)
			sp.owner = root

	var anim_player := AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	root.add_child(anim_player)
	anim_player.owner = root

	var anim_lib := _build_animation_library(
		data.get("animations", {}),
		bone_nodes,
		bone_rel_paths,
		render_settings
	)
	anim_player.add_animation_library("", anim_lib)

	res.root_node = root
	res.animation_library = anim_lib
	res.stats = {
		"rig_name": rig_name,
		"deform_mode": deform_mode,
		"pixel_art_mode": pixel_art_mode,
		"bone_count": bone_nodes.size(),
		"vertex_count": mesh_data.vertices.size() if deform_mode == "mesh_weights" else 0,
		"polygon_count": mesh_data.polygons.size() if deform_mode == "mesh_weights" else 0,
		"animation_count": anim_lib.get_animation_list().size()
	}

	var packed := PackedScene.new()
	var pack_err := packed.pack(root)
	if pack_err != OK:
		res.errors.append("Failed to pack generated Node2D scene (error %d)." % pack_err)
		return res
	res.packed_scene = packed

	if save_outputs:
		var out_cfg: Dictionary = data.get("output", {})
		var default_scene_path := "res://rigs/generated/%s.tscn" % rig_name
		var scene_path: String = str(out_cfg.get("scene_path", default_scene_path)).strip_edges()
		var anim_lib_path: String = str(out_cfg.get("anim_library_path", "")).strip_edges()

		if not scene_path.is_empty():
			_ensure_dir_for_file(scene_path)
			var s_err := ResourceSaver.save(packed, scene_path)
			if s_err != OK:
				res.errors.append("Failed to save PackedScene to '%s' (error %d)." % [scene_path, s_err])
				return res
			res.scene_output_path = scene_path

		if not anim_lib_path.is_empty():
			_ensure_dir_for_file(anim_lib_path)
			var a_err := ResourceSaver.save(anim_lib, anim_lib_path)
			if a_err != OK:
				res.errors.append("Failed to save AnimationLibrary to '%s' (error %d)." % [anim_lib_path, a_err])
				return res
			res.anim_lib_output_path = anim_lib_path

	res.success = res.errors.is_empty()
	return res


static func _build_animation_library(
	anims_dict: Dictionary,
	bone_nodes: Dictionary,
	bone_rel_paths: Dictionary,
	render_settings: Dictionary
) -> AnimationLibrary:
	var lib := AnimationLibrary.new()
	var pixel_art_mode: bool = bool(render_settings.get("pixel_art_mode", false))
	var integer_pixel_snap: bool = bool(render_settings.get("integer_pixel_snap", pixel_art_mode))

	var reset_anim := Animation.new()
	reset_anim.length = 0.001
	for bname in bone_nodes.keys():
		var bone: Bone2D = bone_nodes[bname]
		var rel_path := String(bone_rel_paths[bname])
		var base_np := "Skeleton2D/" + rel_path

		var t_pos := reset_anim.add_track(Animation.TYPE_VALUE)
		reset_anim.track_set_path(t_pos, NodePath(base_np + ":position"))
		reset_anim.track_insert_key(t_pos, 0.0, bone.position)

		var t_rot := reset_anim.add_track(Animation.TYPE_VALUE)
		reset_anim.track_set_path(t_rot, NodePath(base_np + ":rotation"))
		reset_anim.track_insert_key(t_rot, 0.0, bone.rotation)

		var t_scale := reset_anim.add_track(Animation.TYPE_VALUE)
		reset_anim.track_set_path(t_scale, NodePath(base_np + ":scale"))
		reset_anim.track_insert_key(t_scale, 0.0, bone.scale)

	lib.add_animation("RESET", reset_anim)

	for anim_name in anims_dict.keys():
		var anim_cfg: Dictionary = anims_dict[anim_name]
		var anim := Animation.new()
		anim.length = maxf(0.01, float(anim_cfg.get("length", 1.0)))
		anim.step = float(anim_cfg.get("step", 0.05))
		var is_loop: bool = bool(anim_cfg.get("loop", false))
		anim.loop_mode = Animation.LOOP_LINEAR if is_loop else Animation.LOOP_NONE

		var default_interp_str: String = str(
			anim_cfg.get("interpolation", "nearest" if pixel_art_mode else "linear")
		)
		var default_interp := _parse_interp_mode(default_interp_str)

		var tracks_cfg: Dictionary = anim_cfg.get("tracks", {})
		for bname in tracks_cfg.keys():
			if not bone_nodes.has(str(bname)):
				continue
			var bone: Bone2D = bone_nodes[str(bname)]
			var rest_pos := bone.position
			var rest_rot_deg := bone.rotation_degrees
			var rest_scale := bone.scale

			var rel_path := String(bone_rel_paths[str(bname)])
			var base_np := "Skeleton2D/" + rel_path
			var btrack: Dictionary = tracks_cfg[bname]

			# 1. Position track (supports `dp`: [dx, dy] relative to rest_pos OR `v`: [x, y] absolute)
			if btrack.has("position"):
				var t_idx := anim.add_track(Animation.TYPE_VALUE)
				anim.track_set_path(t_idx, NodePath(base_np + ":position"))
				anim.track_set_interpolation_type(t_idx, default_interp)
				anim.value_track_set_update_mode(
					t_idx,
					Animation.UPDATE_DISCRETE if default_interp == Animation.INTERPOLATION_NEAREST else Animation.UPDATE_CONTINUOUS
				)
				for kf in btrack["position"]:
					var t_val := float(kf["t"])
					var vx := rest_pos.x
					var vy := rest_pos.y
					if kf.has("dp"):
						var dp_arr: Array = kf["dp"]
						vx = rest_pos.x + float(dp_arr[0])
						vy = rest_pos.y + float(dp_arr[1])
					elif kf.has("v"):
						var v_arr: Array = kf["v"]
						vx = float(v_arr[0])
						vy = float(v_arr[1])
					if integer_pixel_snap:
						vx = roundf(vx)
						vy = roundf(vy)
					var ease_val := float(kf.get("ease", 1.0))
					anim.track_insert_key(t_idx, t_val, Vector2(vx, vy), ease_val)

			# 2. Rotation track (supports `drot_deg`: delta degrees relative to rest_rot_deg OR `v`: absolute degrees)
			if btrack.has("rotation_deg"):
				var t_idx := anim.add_track(Animation.TYPE_VALUE)
				anim.track_set_path(t_idx, NodePath(base_np + ":rotation"))
				anim.track_set_interpolation_type(t_idx, default_interp)
				anim.value_track_set_update_mode(
					t_idx,
					Animation.UPDATE_DISCRETE if default_interp == Animation.INTERPOLATION_NEAREST else Animation.UPDATE_CONTINUOUS
				)
				for kf in btrack["rotation_deg"]:
					var t_val := float(kf["t"])
					var deg_val := rest_rot_deg
					if kf.has("drot_deg"):
						deg_val = rest_rot_deg + float(kf["drot_deg"])
					elif kf.has("v"):
						deg_val = float(kf["v"])
					var ease_val := float(kf.get("ease", 1.0))
					anim.track_insert_key(t_idx, t_val, deg_to_rad(deg_val), ease_val)

			# 3. Scale track (supports `dscale`: [mx, my] multiplier relative to rest_scale OR `v`: [sx, sy] absolute)
			if btrack.has("scale"):
				var t_idx := anim.add_track(Animation.TYPE_VALUE)
				anim.track_set_path(t_idx, NodePath(base_np + ":scale"))
				anim.track_set_interpolation_type(t_idx, default_interp)
				anim.value_track_set_update_mode(
					t_idx,
					Animation.UPDATE_DISCRETE if default_interp == Animation.INTERPOLATION_NEAREST else Animation.UPDATE_CONTINUOUS
				)
				for kf in btrack["scale"]:
					var t_val := float(kf["t"])
					var sx := rest_scale.x
					var sy := rest_scale.y
					if kf.has("dscale"):
						var ds_arr: Array = kf["dscale"]
						sx = rest_scale.x * float(ds_arr[0])
						sy = rest_scale.y * float(ds_arr[1])
					elif kf.has("v"):
						var s_arr: Array = kf["v"]
						sx = float(s_arr[0])
						sy = float(s_arr[1])
					var ease_val := float(kf.get("ease", 1.0))
					anim.track_insert_key(t_idx, t_val, Vector2(sx, sy), ease_val)

		lib.add_animation(StringName(str(anim_name)), anim)

	return lib


static func _parse_interp_mode(mode_str: String) -> Animation.InterpolationType:
	match mode_str.to_lower():
		"nearest", "step", "discrete":
			return Animation.INTERPOLATION_NEAREST
		"cubic":
			return Animation.INTERPOLATION_CUBIC
		_:
			return Animation.INTERPOLATION_LINEAR


static func _get_bone_rest_global_pos(bone: Bone2D, skeleton: Skeleton2D) -> Vector2:
	var xf := Transform2D.IDENTITY
	var curr: Node = bone
	var chain: Array[Bone2D] = []
	while curr != null and curr != skeleton:
		if curr is Bone2D:
			chain.push_front(curr as Bone2D)
		curr = curr.get_parent()
	for b in chain:
		xf = xf * b.transform
	return xf.origin


static func _get_bone_rest_global_rot(bone: Bone2D, skeleton: Skeleton2D) -> float:
	var rot := 0.0
	var curr: Node = bone
	while curr != null and curr != skeleton:
		if curr is Bone2D:
			rot += (curr as Bone2D).rotation
		curr = curr.get_parent()
	return rot


static func _ensure_dir_for_file(res_path: String) -> void:
	var dir_path := res_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
