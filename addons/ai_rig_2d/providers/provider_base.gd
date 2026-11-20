@tool
class_name AIRigProviderBase
extends RefCounted

## Abstract Provider interface for AI 2D Rig Builder.
## v1 implements SingleImageProvider (`single_image`).
## v2 will implement LayeredAtlasProvider (`layered_atlas`) without changing downstream builders.


class MeshDataResult extends RefCounted:
	var texture: Texture2D = null
	var texture_size: Vector2 = Vector2(64, 64)
	var vertices: PackedVector2Array = PackedVector2Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var polygons: Array[PackedInt32Array] = []
	var internal_vertex_count: int = 0
	var warnings: Array[String] = []


func get_provider_type() -> String:
	return "base"


func build_mesh_data(
	_provider_cfg: Dictionary, _render_settings: Dictionary, _allow_placeholder: bool = true
) -> MeshDataResult:
	push_error("AIRigProviderBase.build_mesh_data must be overridden by subclass.")
	return MeshDataResult.new()


static func load_or_create_texture(
	tex_path: String, fallback_size: Vector2i = Vector2i(64, 64), allow_placeholder: bool = true
) -> Texture2D:
	if not tex_path.is_empty() and ResourceLoader.exists(tex_path):
		var res := ResourceLoader.load(tex_path)
		if res is Texture2D:
			return res as Texture2D

	if not tex_path.is_empty() and FileAccess.file_exists(tex_path):
		var img := Image.load_from_file(tex_path)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)

	if not allow_placeholder:
		return null

	# Generate a crisp checkerboard + silhouette placeholder texture for headless CI validation
	var w := maxi(8, fallback_size.x)
	var h := maxi(8, fallback_size.y)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(h):
		for x in range(w):
			# Draw a humanoid/creature silhouette inside 15%..85% bounds
			var nx := float(x) / float(w)
			var ny := float(y) / float(h)
			if nx >= 0.15 and nx <= 0.85 and ny >= 0.08 and ny <= 0.92:
				var c := Color(0.25, 0.72, 0.95, 1.0) if ((x / 4 + y / 4) % 2 == 0) else Color(0.18, 0.55, 0.82, 1.0)
				img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)
