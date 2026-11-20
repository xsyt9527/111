@tool
class_name AIRigDock
extends VBoxContainer

## Editor Dock Panel for AI 2D Rig Builder.
## Provides:
## - "Sync All Rigs Now" button (scans `res://rigs/` and builds `.tscn` / `.tres`)
## - "Validate Selected JSON" button
## - Auto-Watch `res://rigs/` toggle (polls file modification timestamps every 1.5s)
## - Clean diagnostic log output for manual inspection in Godot Editor.

signal request_open_scene(scene_path: String)

const DEFAULT_RIGS_DIR := "res://rigs"

var _watch_dir_edit: LineEdit
var _auto_watch_check: CheckBox
var _log_label: RichTextLabel
var _file_mtimes := {}
var _poll_accum := 0.0


func _init() -> void:
	name = "AI Rig 2D"
	custom_minimum_size = Vector2(260, 220)
	_build_ui()


func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if _auto_watch_check == null or not _auto_watch_check.button_pressed:
		return
	_poll_accum += delta
	if _poll_accum >= 1.5:
		_poll_accum = 0.0
		_check_directory_changes()


func _build_ui() -> void:
	var title := Label.new()
	title.text = "AI 2D Rig Builder (v1.0)"
	title.add_theme_font_size_override("font_size", 15)
	add_child(title)

	var dir_row := HBoxContainer.new()
	var dir_lbl := Label.new()
	dir_lbl.text = "Rigs Dir:"
	dir_row.add_child(dir_lbl)

	_watch_dir_edit = LineEdit.new()
	_watch_dir_edit.text = DEFAULT_RIGS_DIR
	_watch_dir_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dir_row.add_child(_watch_dir_edit)
	add_child(dir_row)

	_auto_watch_check = CheckBox.new()
	_auto_watch_check.text = "Auto-Watch JSON Changes (1.5s)"
	_auto_watch_check.button_pressed = true
	add_child(_auto_watch_check)

	var btn_row := HBoxContainer.new()
	var sync_btn := Button.new()
	sync_btn.text = "Sync All Rigs Now"
	sync_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sync_btn.pressed.connect(_on_sync_all_pressed)
	btn_row.add_child(sync_btn)

	var val_btn := Button.new()
	val_btn.text = "Validate Only"
	val_btn.pressed.connect(_on_validate_all_pressed)
	btn_row.add_child(val_btn)
	add_child(btn_row)

	_log_label = RichTextLabel.new()
	_log_label.bbcode_enabled = true
	_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_label.scroll_following = true
	add_child(_log_label)

	_append_log("[color=gray]Ready. Place Claude rig JSON files in %s.[/color]" % DEFAULT_RIGS_DIR)


func _on_sync_all_pressed() -> void:
	var dir_path := _watch_dir_edit.text.strip_edges()
	var json_files := _scan_json_files(dir_path)
	if json_files.is_empty():
		_append_log("[color=yellow]No .json files found in %s[/color]" % dir_path)
		return

	var ok_count := 0
	for jf in json_files:
		_file_mtimes[jf] = FileAccess.get_modified_time(jf)
		var res := AIRigBuilder.build_from_json_file(jf, true, true)
		if res.success:
			ok_count += 1
			_append_log(
				"[color=green][OK][/color] Built [b]%s[/b] -> %s (%d bones, %d anims)"
				% [
					res.stats.get("rig_name", ""),
					res.scene_output_path,
					res.stats.get("bone_count", 0),
					res.stats.get("animation_count", 0)
				]
			)
			for w in res.warnings:
				_append_log("  [color=yellow]WARN:[/color] %s" % w)
		else:
			_append_log("[color=red][FAIL][/color] %s" % jf)
			for e in res.errors:
				_append_log("  [color=red]ERR:[/color] %s" % e)

	if Engine.is_editor_hint() and EditorInterface.get_resource_filesystem() != null:
		EditorInterface.get_resource_filesystem().scan()
	_append_log("[b]Sync finished: %d / %d succeeded.[/b]" % [ok_count, json_files.size()])


func _on_validate_all_pressed() -> void:
	var dir_path := _watch_dir_edit.text.strip_edges()
	var json_files := _scan_json_files(dir_path)
	if json_files.is_empty():
		_append_log("[color=yellow]No .json files found in %s[/color]" % dir_path)
		return

	for jf in json_files:
		var val := AIRigSchemaValidator.validate_json_file(jf)
		if val.valid:
			_append_log("[color=cyan][VALID][/color] %s" % jf)
		else:
			_append_log("[color=red][INVALID][/color] %s" % jf)
			for e in val.errors:
				_append_log("  [color=red]ERR:[/color] %s" % e)
		for w in val.warnings:
			_append_log("  [color=yellow]WARN:[/color] %s" % w)


func _check_directory_changes() -> void:
	var dir_path := _watch_dir_edit.text.strip_edges()
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	var json_files := _scan_json_files(dir_path)
	var changed_files: Array[String] = []
	for jf in json_files:
		var mtime := FileAccess.get_modified_time(jf)
		if not _file_mtimes.has(jf) or _file_mtimes[jf] != mtime:
			_file_mtimes[jf] = mtime
			changed_files.append(jf)

	if changed_files.is_empty():
		return

	for jf in changed_files:
		var res := AIRigBuilder.build_from_json_file(jf, true, true)
		if res.success:
			_append_log(
				"[color=green][Auto-Sync][/color] Updated %s -> %s"
				% [jf.get_file(), res.scene_output_path]
			)
		else:
			_append_log("[color=red][Auto-Sync ERR][/color] %s: %s" % [jf.get_file(), "; ".join(res.errors)])

	if Engine.is_editor_hint() and EditorInterface.get_resource_filesystem() != null:
		EditorInterface.get_resource_filesystem().scan()


static func _scan_json_files(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	if not DirAccess.dir_exists_absolute(dir_path):
		return out
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".json"):
			out.append(dir_path.path_join(fname))
		fname = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out


func _append_log(bbcode_line: String) -> void:
	if _log_label != null:
		_log_label.append_text(bbcode_line + "\n")
