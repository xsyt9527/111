@tool
class_name AIRigLayeredAtlasProvider
extends AIRigProviderBase

## v2 Reserved Stub: Layered Atlas Provider (`layered_atlas`).
## Allows independent head/torso/limb PNGs or AtlasTexture regions to be attached
## directly to Bone2D nodes or assigned localized Polygon2D meshes.


func get_provider_type() -> String:
	return "layered_atlas"


func build_mesh_data(
	_provider_cfg: Dictionary, _render_settings: Dictionary, _allow_placeholder: bool = true
) -> MeshDataResult:
	var out := MeshDataResult.new()
	out.warnings.append("LayeredAtlasProvider is a v2 stub. Use 'single_image' in v1.")
	return out
