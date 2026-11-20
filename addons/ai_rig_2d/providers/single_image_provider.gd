@tool
class_name AIRigSingleImageProvider
extends AIRigProviderBase

## v1 Default Provider: Single full-body sprite/illustration (`single_image`).
## Supports:
## 1. Automatic uniform/alpha-aware grid slicing for `mesh_weights` mode.
## 2. Integer-pixel snapping for `pixel_art_mode`.


func get_provider_type() -> String:
	return "single_image"


func build_mesh_data(
	provider_cfg: Dictionary, render_settings: Dictionary, allow_placeholder: bool = true
) -> MeshDataResult:
	var out := MeshDataResult.new()
	var tex_path: String = str(provider_cfg.get("texture_path", ""))
	var fallback_dim := Vector2i(64, 64)
	if provider_cfg.has("fallback_size") and (provider_cfg.get("fallback_size") as Array).size() == 2:
		var fs := provider_cfg.get("fallback_size") as Array
		fallback_dim = Vector2i(int(fs[0]), int(fs[1]))

	out.texture = load_or_create_texture(tex_path, fallback_dim, allow_placeholder)
	if out.texture != null:
		out.texture_size = out.texture.get_size()
	else:
		out.texture_size = Vector2(fallback_dim.x, fallback_dim.y)
		out.warnings.append("Texture '%s' could not be loaded; using fallback dimensions %s." % [tex_path, str(out.texture_size)])

	var grid_cols := 8
	var grid_rows := 8
	if provider_cfg.has("grid_size"):
		var gs := provider_cfg.get("grid_size") as Array
		grid_cols = clampi(int(gs[0]), 1, 128)
		grid_rows = clampi(int(gs[1]), 1, 128)

	var pixel_snap: bool = bool(
		render_settings.get("integer_pixel_snap", render_settings.get("pixel_art_mode", false))
	)
	var alpha_threshold: float = float(provider_cfg.get("alpha_threshold", 0.01))
	var cull_transparent_cells: bool = bool(provider_cfg.get("cull_transparent_cells", false))

	var img: Image = null
	if out.texture != null:
		img = out.texture.get_image()

	var w := out.texture_size.x
	var h := out.texture_size.y

	# In Godot Polygon2D, boundary vertices must come first in perimeter order if outline is used,
	# OR if internal_vertex_count == 0 and polygons are explicitly specified, Polygon2D renders
	# the explicit triangles directly from `polygon` + `uv` + `polygons`.
	# Building a structured grid of (grid_cols + 1) * (grid_rows + 1) vertices:
	var verts := PackedVector2Array()
	var uvs := PackedVector2Array()

	for r in range(grid_rows + 1):
		for c in range(grid_cols + 1):
			var u := float(c) / float(grid_cols)
			var v := float(r) / float(grid_rows)
			var px := u * w
			var py := v * h
			if pixel_snap:
				px = roundf(px)
				py = roundf(py)
			verts.append(Vector2(px, py))
			uvs.append(Vector2(px, py))

	var polys: Array[PackedInt32Array] = []
	var stride := grid_cols + 1
	for r in range(grid_rows):
		for c in range(grid_cols):
			if cull_transparent_cells and img != null:
				if _is_cell_transparent(img, c, r, grid_cols, grid_rows, alpha_threshold):
					continue
			var i0 := r * stride + c
			var i1 := i0 + 1
			var i2 := (r + 1) * stride + (c + 1)
			var i3 := (r + 1) * stride + c

			var tri1 := PackedInt32Array([i0, i1, i2])
			var tri2 := PackedInt32Array([i0, i2, i3])
			polys.append(tri1)
			polys.append(tri2)

	out.vertices = verts
	out.uvs = uvs
	out.polygons = polys
	out.internal_vertex_count = 0
	return out


func _is_cell_transparent(
	img: Image, col: int, row: int, cols: int, rows: int, threshold: float
) -> bool:
	var w := img.get_width()
	var h := img.get_height()
	var x0 := int(floor(float(col) * float(w) / float(cols)))
	var x1 := int(ceil(float(col + 1) * float(w) / float(cols)))
	var y0 := int(floor(float(row) * float(h) / float(rows)))
	var y1 := int(ceil(float(row + 1) * float(h) / float(rows)))
	for y in range(clampi(y0, 0, h - 1), clampi(y1, 1, h)):
		for x in range(clampi(x0, 0, w - 1), clampi(x1, 1, w)):
			if img.get_pixel(x, y).a > threshold:
				return false
	return true
