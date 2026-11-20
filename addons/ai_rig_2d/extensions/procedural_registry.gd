@tool
class_name AIRigProceduralRegistry
extends RefCounted

## Extension Hook Registry for v2 Procedural Animation Presets & 2D IK Chains.
## In v1, core bone/FK animation data stays clean in `bones` and `animations`, while optional
## `procedural` (breathing sine, hit shake, swim wave) and `ik_chains` blocks are preserved
## on the root node metadata so v2 modules or game runtime scripts can read them without breaking schema.

const META_PROCEDURAL_KEY := "ai_rig_procedural_presets"
const META_IK_CHAINS_KEY := "ai_rig_ik_chains"


static func attach_extension_metadata(root_node: Node, rig_data: Dictionary) -> void:
	if rig_data.has("procedural") and typeof(rig_data["procedural"]) == TYPE_DICTIONARY:
		root_node.set_meta(META_PROCEDURAL_KEY, rig_data["procedural"].duplicate(true))

	if rig_data.has("ik_chains") and typeof(rig_data["ik_chains"]) == TYPE_ARRAY:
		root_node.set_meta(META_IK_CHAINS_KEY, rig_data["ik_chains"].duplicate(true))
