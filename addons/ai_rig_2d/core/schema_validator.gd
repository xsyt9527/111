@tool
class_name AIRigSchemaValidator
extends RefCounted

## Validates declarative rig JSON files for AI 2D Rig Builder (v1.1).
## Supports both absolute keyframes (`v`) and rest-relative delta keyframes (`dp`, `drot_deg`, `dscale`)
## so AI coding agents (Claude) never break bone attachment chains by guessing absolute coordinates.

const SUPPORTED_VERSIONS := ["1.0", "1.1"]
const SUPPORTED_PROVIDERS := ["single_image", "layered_atlas"]
const SUPPORTED_DEFORM_MODES := ["mesh_weights", "rigid_parts"]


static func validate_json_file(json_path: String) -> Dictionary:
	var result := {
		"valid": true,
		"path": json_path,
		"errors": [] as Array[String],
		"warnings": [] as Array[String],
		"data": {}
	}
	if not FileAccess.file_exists(json_path):
		result.valid = false
		result.errors.append("JSON file not found: %s" % json_path)
		return result

	var raw_text := FileAccess.get_file_as_string(json_path)
	var json := JSON.new()
	var parse_err := json.parse(raw_text)
	if parse_err != OK:
		result.valid = false
		result.errors.append(
			"JSON syntax error at line %d: %s" % [json.get_error_line(), json.get_error_message()]
		)
		return result

	if typeof(json.data) != TYPE_DICTIONARY:
		result.valid = false
		result.errors.append("Root JSON element must be an object/dictionary.")
		return result

	result.data = json.data
	validate_dict(result.data, result)
	return result


static func validate_dict(data: Dictionary, result: Dictionary) -> void:
	var version: String = str(data.get("schema_version", "1.1"))
	if not SUPPORTED_VERSIONS.has(version):
		result.warnings.append(
			"Unknown schema_version '%s', expected one of %s." % [version, str(SUPPORTED_VERSIONS)]
		)

	var rig_name: String = str(data.get("rig_name", "")).strip_edges()
	if rig_name.is_empty():
		_add_err(result, "Missing required non-empty string field: 'rig_name'.")

	var provider: Variant = data.get("provider")
	if typeof(provider) != TYPE_DICTIONARY:
		_add_err(result, "Missing or invalid 'provider' object.")
	else:
		_validate_provider(provider as Dictionary, result)

	var render_settings: Dictionary = data.get("render_settings", {})
	if typeof(render_settings) != TYPE_DICTIONARY:
		_add_err(result, "'render_settings' must be a dictionary if provided.")
	else:
		_validate_render_settings(render_settings, result)

	var bones_var: Variant = data.get("bones")
	var bone_names := {}
	if typeof(bones_var) != TYPE_ARRAY or (bones_var as Array).is_empty():
		_add_err(result, "Field 'bones' must be a non-empty array of bone definitions.")
	else:
		_validate_bones(bones_var as Array, bone_names, render_settings, result)

	var deform_mode: String = str(render_settings.get("deform_mode", "mesh_weights"))
	if deform_mode == "rigid_parts" and data.has("parts"):
		var parts_var: Variant = data.get("parts")
		if typeof(parts_var) != TYPE_ARRAY:
			_add_err(result, "'parts' must be an array when provided.")
		else:
			_validate_parts(parts_var as Array, bone_names, result)

	if data.has("weights"):
		_validate_weights(data.get("weights"), bone_names, result)

	if data.has("animations"):
		var anims_var: Variant = data.get("animations")
		if typeof(anims_var) != TYPE_DICTIONARY:
			_add_err(result, "'animations' must be a dictionary mapping animation names to definitions.")
		else:
			_validate_animations(anims_var as Dictionary, bone_names, render_settings, result)


static func _validate_provider(provider: Dictionary, result: Dictionary) -> void:
	var ptype: String = str(provider.get("type", "single_image"))
	if not SUPPORTED_PROVIDERS.has(ptype):
		_add_err(
			result,
			"Unsupported provider.type '%s'. Supported: %s" % [ptype, str(SUPPORTED_PROVIDERS)]
		)
		return

	if ptype == "layered_atlas":
		_add_err(
			result,
			"provider.type 'layered_atlas' is reserved for v2. Please use 'single_image' in v1."
		)
		return

	var tex_path: String = str(provider.get("texture_path", "")).strip_edges()
	if tex_path.is_empty():
		_add_err(result, "provider.texture_path is required for 'single_image' provider.")


static func _validate_render_settings(rs: Dictionary, result: Dictionary) -> void:
	var deform_mode: String = str(rs.get("deform_mode", "mesh_weights"))
	if not SUPPORTED_DEFORM_MODES.has(deform_mode):
		_add_err(
			result,
			"Unsupported render_settings.deform_mode '%s'. Must be one of %s."
			% [deform_mode, str(SUPPORTED_DEFORM_MODES)]
		)

	var pixel_art_mode: bool = bool(rs.get("pixel_art_mode", false))
	if pixel_art_mode and deform_mode == "mesh_weights":
		result.warnings.append(
			"pixel_art_mode is true while deform_mode is 'mesh_weights'. Free mesh deformation on low-res pixel art (e.g. 64x64) can cause non-integer pixel blurring! Consider setting deform_mode to 'rigid_parts'."
		)


static func _validate_bones(
	bones: Array, bone_names: Dictionary, _rs: Dictionary, result: Dictionary
) -> void:
	var parent_refs := {}
	for i in range(bones.size()):
		var b_var: Variant = bones[i]
		if typeof(b_var) != TYPE_DICTIONARY:
			_add_err(result, "bones[%d] must be a dictionary." % i)
			continue
		var b := b_var as Dictionary
		var bname: String = str(b.get("name", "")).strip_edges()
		if bname.is_empty():
			_add_err(result, "bones[%d] is missing a non-empty 'name'." % i)
			continue
		if bone_names.has(bname):
			_add_err(result, "Duplicate bone name '%s' at bones[%d]." % [bname, i])
			continue

		bone_names[bname] = b
		var parent_val: Variant = b.get("parent", null)
		if parent_val != null and str(parent_val).strip_edges() != "":
			parent_refs[bname] = str(parent_val).strip_edges()

		if not b.has("position") or not _is_vec2_array(b.get("position")):
			_add_err(
				result,
				"Bone '%s' must define 'position' as [x, y] number array." % bname
			)
		if b.has("scale") and not _is_vec2_array(b.get("scale")):
			_add_err(result, "Bone '%s' field 'scale' must be [sx, sy]." % bname)

	for child_name in parent_refs.keys():
		var p_name: String = parent_refs[child_name]
		if not bone_names.has(p_name):
			_add_err(
				result,
				"Bone '%s' references non-existent parent bone '%s'." % [child_name, p_name]
			)
			continue
		var visited := {child_name: true}
		var curr := p_name
		while curr != "":
			if visited.has(curr):
				_add_err(result, "Cyclic bone hierarchy detected involving bone '%s'." % child_name)
				break
			visited[curr] = true
			curr = parent_refs.get(curr, "")


static func _validate_parts(parts: Array, bone_names: Dictionary, result: Dictionary) -> void:
	for i in range(parts.size()):
		var p_var: Variant = parts[i]
		if typeof(p_var) != TYPE_DICTIONARY:
			_add_err(result, "parts[%d] must be a dictionary." % i)
			continue
		var part := p_var as Dictionary
		var pname: String = str(part.get("name", "part_%d" % i))
		var bname: String = str(part.get("bone", "")).strip_edges()
		if bname.is_empty() or not bone_names.has(bname):
			_add_err(
				result,
				"Part '%s' (parts[%d]) must reference a valid existing bone in 'bone' (got '%s')."
				% [pname, i, bname]
			)
		if part.has("region_rect"):
			var rr: Variant = part.get("region_rect")
			if typeof(rr) != TYPE_ARRAY or (rr as Array).size() != 4:
				_add_err(
					result,
					"Part '%s' field 'region_rect' must be [x, y, w, h]." % pname
				)


static func _validate_weights(weights_var: Variant, bone_names: Dictionary, result: Dictionary) -> void:
	if typeof(weights_var) != TYPE_DICTIONARY:
		_add_err(result, "'weights' must be a dictionary.")
		return
	var w_dict := weights_var as Dictionary
	var mode: String = str(w_dict.get("mode", "auto_envelope"))
	if mode not in ["auto_envelope", "explicit", "hybrid"]:
		_add_err(
			result,
			"Unsupported weights.mode '%s'. Expected 'auto_envelope', 'explicit', or 'hybrid'." % mode
		)
	if w_dict.has("overrides"):
		var ov: Variant = w_dict.get("overrides")
		if typeof(ov) == TYPE_DICTIONARY:
			for bname in (ov as Dictionary).keys():
				if not bone_names.has(str(bname)):
					_add_err(
						result,
						"weights.overrides references unknown bone '%s'." % str(bname)
					)


static func _validate_animations(
	anims: Dictionary, bone_names: Dictionary, rs: Dictionary, result: Dictionary
) -> void:
	var pixel_art_mode: bool = bool(rs.get("pixel_art_mode", false))
	for anim_name in anims.keys():
		var anim_var: Variant = anims[anim_name]
		if typeof(anim_var) != TYPE_DICTIONARY:
			_add_err(result, "Animation '%s' must be a dictionary." % str(anim_name))
			continue
		var anim := anim_var as Dictionary
		var length: float = float(anim.get("length", 1.0))
		if length <= 0.0:
			_add_err(result, "Animation '%s' length must be > 0." % str(anim_name))

		var is_loop: bool = bool(anim.get("loop", false))
		var tracks_var: Variant = anim.get("tracks", {})
		if typeof(tracks_var) != TYPE_DICTIONARY:
			_add_err(result, "Animation '%s' field 'tracks' must be a dictionary keyed by bone name." % str(anim_name))
			continue

		var tracks := tracks_var as Dictionary
		for bname in tracks.keys():
			if not bone_names.has(str(bname)):
				_add_err(
					result,
					"Animation '%s' track references unknown bone '%s'." % [str(anim_name), str(bname)]
				)
				continue
			var bdef: Dictionary = bone_names[str(bname)]
			var rest_pos_arr: Array = bdef.get("position", [0.0, 0.0])
			var rest_pos := Vector2(float(rest_pos_arr[0]), float(rest_pos_arr[1]))
			var b_len := float(bdef.get("length", 16.0))

			var btrack_var: Variant = tracks[bname]
			if typeof(btrack_var) != TYPE_DICTIONARY:
				_add_err(
					result,
					"Animation '%s' track for bone '%s' must be a dictionary." % [str(anim_name), str(bname)]
				)
				continue
			var btrack := btrack_var as Dictionary
			for prop in btrack.keys():
				var prop_str := str(prop)
				if prop_str not in ["position", "rotation_deg", "scale"]:
					_add_err(
						result,
						"Animation '%s' -> bone '%s' has unsupported track property '%s' (supported: 'position', 'rotation_deg', 'scale')."
						% [str(anim_name), str(bname), prop_str]
					)
					continue
				var kf_list: Variant = btrack[prop]
				if typeof(kf_list) != TYPE_ARRAY or (kf_list as Array).is_empty():
					_add_err(
						result,
						"Animation '%s' -> '%s.%s' must be a non-empty array of keyframes."
						% [str(anim_name), str(bname), prop_str]
					)
					continue

				var kfs := kf_list as Array
				for k_idx in range(kfs.size()):
					var kf_var: Variant = kfs[k_idx]
					if typeof(kf_var) != TYPE_DICTIONARY or not (kf_var as Dictionary).has("t"):
						_add_err(
							result,
							"Animation '%s' -> '%s.%s'[%d] must be a dictionary with 't'."
							% [str(anim_name), str(bname), prop_str, k_idx]
						)
						continue
					var kf := kf_var as Dictionary
					var has_v := kf.has("v")
					var has_delta := kf.has("dp") or kf.has("drot_deg") or kf.has("dscale")
					if not has_v and not has_delta:
						_add_err(
							result,
							"Animation '%s' -> '%s.%s'[%d] must specify either 'v' (absolute) or 'dp'/'drot_deg'/'dscale' (relative to rest pose)."
							% [str(anim_name), str(bname), prop_str, k_idx]
						)
						continue

					# Sanity warnings for unnatural AI keyframes
					if prop_str == "position":
						var target_vec := rest_pos
						if kf.has("dp") and _is_vec2_array(kf["dp"]):
							var dp: Array = kf["dp"]
							target_vec = rest_pos + Vector2(float(dp[0]), float(dp[1]))
						elif kf.has("v") and _is_vec2_array(kf["v"]):
							var vv: Array = kf["v"]
							target_vec = Vector2(float(vv[0]), float(vv[1]))
							# Detect classic AI bug: writing [0, 0] on a child bone whose rest position is non-zero
							if target_vec == Vector2.ZERO and rest_pos.length() > 4.0:
								result.warnings.append(
									"SANITY_WARN: Animation '%s' -> '%s.position'[%d] sets absolute position [0, 0], which collapses the bone onto its parent (rest is [%s, %s]). Use 'dp': [dx, dy] for relative motion!"
									% [str(anim_name), str(bname), k_idx, str(rest_pos.x), str(rest_pos.y)]
								)
						var delta_dist := target_vec.distance_to(rest_pos)
						if delta_dist > maxf(32.0, b_len * 2.0):
							result.warnings.append(
								"SANITY_WARN: Animation '%s' -> '%s.position'[%d] moves %.1f px away from rest pose (bone length %.1f px). Check for detached limb!"
								% [str(anim_name), str(bname), k_idx, delta_dist, b_len]
							)

					elif prop_str == "rotation_deg":
						var deg_val := float(kf.get("drot_deg", kf.get("v", 0.0)))
						if pixel_art_mode and absf(deg_val) > 0.01 and absf(deg_val) < 90.0:
							result.warnings.append(
								"PIXEL_ART_WARN: Animation '%s' -> '%s.rotation_deg'[%d] uses %.1f deg rotation in pixel_art_mode. Small non-90deg rotations cause pixel staircase shearing on 64x64 sprites; prefer 1-3px 'dp' translation offsets instead!"
								% [str(anim_name), str(bname), k_idx, deg_val]
							)

				# Loop closure check
				if is_loop and kfs.size() >= 2:
					var first_kf := kfs[0] as Dictionary
					var last_kf := kfs[kfs.size() - 1] as Dictionary
					if JSON.stringify(first_kf.get("v", first_kf.get("dp", first_kf.get("drot_deg")))) != JSON.stringify(last_kf.get("v", last_kf.get("dp", last_kf.get("drot_deg")))):
						result.warnings.append(
							"LOOP_WARN: Animation '%s' -> '%s.%s' is looped, but first and last keyframe values differ (will cause visible snap at loop boundary)."
							% [str(anim_name), str(bname), prop_str]
						)


static func _is_vec2_array(val: Variant) -> bool:
	if typeof(val) != TYPE_ARRAY:
		return false
	var arr := val as Array
	if arr.size() != 2:
		return false
	return typeof(arr[0]) in [TYPE_INT, TYPE_FLOAT] and typeof(arr[1]) in [TYPE_INT, TYPE_FLOAT]


static func _add_err(result: Dictionary, msg: String) -> void:
	result.valid = false
	result.errors.append(msg)
