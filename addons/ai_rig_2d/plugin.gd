@tool
extends EditorPlugin

## EditorPlugin entry point for AI 2D Rig Builder.
## Mounts the `AIRigDock` panel in the right-hand dock slot so developers can
## one-click sync or auto-watch `res://rigs/*.json` modified by Claude.

var _dock: AIRigDock = null


func _enter_tree() -> void:
	_dock = AIRigDock.new()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)


func _exit_tree() -> void:
	if _dock != null:
		remove_control_from_docks(_dock)
		_dock.free()
		_dock = null
