extends SceneTree

## 试点 rig 视觉截图：实例化生成的 .tscn，播放 you_yong 动画，抓 4 个时刻的真实渲染画面

var rig: Node
var times := [0.0, 0.2, 0.4, 0.6]
var idx := 0
var phase := 0
var wait := 0

func _initialize() -> void:
	var ps: PackedScene = load("res://rigs/generated/WoNiuYuShiDian.tscn")
	rig = ps.instantiate()
	root.add_child(rig)
	var ap: AnimationPlayer = rig.get_node("AnimationPlayer")
	ap.play("you_yong")

func _process(_delta: float) -> bool:
	wait += 1
	if wait < 10:
		return false
	var ap: AnimationPlayer = rig.get_node("AnimationPlayer")
	if phase == 0:
		ap.seek(times[idx], true)
		phase = 1
		wait = 0
		return false
	elif phase == 1:
		var img: Image = root.get_texture().get_image()
		var path := "res://rigs/previews/visual_f%d.png" % idx
		img.save_png(ProjectSettings.globalize_path(path))
		print("saved ", path, " size=", img.get_size())
		idx += 1
		phase = 0
		wait = 0
		if idx >= times.size():
			return true
	return false
