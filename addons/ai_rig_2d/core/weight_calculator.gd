@tool
class_name AIRigWeightCalculator
extends RefCounted

## Calculates vertex bone weights for Godot 4 Polygon2D meshes.
## Supports:
## - `auto_envelope`: Inverse-distance falloff to bone segments (capsule envelope) with top-K normalization.
## - `explicit`: Full manual vertex weight dictionary from JSON.
## - `hybrid`: `auto_envelope` base + JSON `overrides` per bone/vertex.


static func compute_bone_weights(
	vertices: PackedVector2Array,
	bones_Global_segments: Array[Dictionary],
	weights_cfg: Dictionary
) -> Dictionary:
	# Returns Dictionary: { bone_name: PackedFloat32Array (size == vertices.size()) }
	var v_count := vertices.size()
	var bone_weights := {}
	for b_info in bones_Global_segments:
		var bname: String = b_info["name"]
		var arr := PackedFloat32Array()
		arr.resize(v_count)
		arr.fill(0.0)
		bone_weights[bname] = arr

	var mode: String = str(weights_cfg.get("mode", "auto_envelope"))
	var falloff_power: float = clampf(float(weights_cfg.get("falloff_power", 2.5)), 0.5, 8.0)
	var max_influences: int = clampi(int(weights_cfg.get("max_influences", 3)), 1, 8)
	var epsilon: float = 0.0001

	if mode == "auto_envelope" or mode == "hybrid":
		for vi in range(v_count):
			var v_pos := vertices[vi]
			var raw_scores: Array[Dictionary] = []

			for b_info in bones_Global_segments:
				var bname: String = b_info["name"]
				var seg_a: Vector2 = b_info["global_start"]
				var seg_b: Vector2 = b_info["global_end"]
				var radius: float = maxf(1.0, float(b_info.get("envelope_radius", 24.0)))

				var closest := Geometry2D.get_closest_point_to_segment(v_pos, seg_a, seg_b)
				var dist := v_pos.distance_to(closest)

				# Smooth inverse distance weighted by envelope radius
				var normalized_d := dist / radius
				var score := 1.0 / pow(maxf(normalized_d, 0.05), falloff_power)
				raw_scores.append({"bone": bname, "score": score})

			# Sort descending by score and keep top `max_influences`
			raw_scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
			var keep_count := mini(max_influences, raw_scores.size())
			var sum_score := 0.0
			for k in range(keep_count):
				sum_score += float(raw_scores[k]["score"])

			if sum_score > epsilon:
				for k in range(keep_count):
					var bname: String = raw_scores[k]["bone"]
					var norm_w := float(raw_scores[k]["score"]) / sum_score
					# PackedFloat32Array 是值类型：必须取出、修改、存回
					var w_arr := bone_weights[bname] as PackedFloat32Array
					w_arr[vi] = norm_w
					bone_weights[bname] = w_arr

	if mode == "explicit" or mode == "hybrid":
		var overrides: Dictionary = weights_cfg.get("overrides", {})
		if mode == "explicit":
			# Zero out first（值类型：取出、填充、存回）
			for bname in bone_weights.keys():
				var z_arr := bone_weights[bname] as PackedFloat32Array
				z_arr.fill(0.0)
				bone_weights[bname] = z_arr

		for bname in overrides.keys():
			if not bone_weights.has(str(bname)):
				continue
			var v_map: Variant = overrides[bname]
			if typeof(v_map) == TYPE_DICTIONARY:
				for v_idx_str in (v_map as Dictionary).keys():
					var vi := int(str(v_idx_str))
					if vi >= 0 and vi < v_count:
						var w_val := clampf(float((v_map as Dictionary)[v_idx_str]), 0.0, 1.0)
						var o_arr := bone_weights[str(bname)] as PackedFloat32Array
						o_arr[vi] = w_val
						bone_weights[str(bname)] = o_arr

		# Re-normalize vertices touched by overrides if normalize_overrides is true
		if bool(weights_cfg.get("normalize", true)):
			for vi in range(v_count):
				var total := 0.0
				for bname in bone_weights.keys():
					total += (bone_weights[bname] as PackedFloat32Array)[vi]
				if total > epsilon:
					for bname in bone_weights.keys():
						var n_arr := bone_weights[bname] as PackedFloat32Array
						n_arr[vi] /= total
						bone_weights[bname] = n_arr

	return bone_weights
