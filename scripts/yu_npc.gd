extends Node2D
class_name YuNpc
# NPC 鱼：进入场景树时随机外观，之后沿直线游动，游出屏幕自动释放

@export var tie_tu_shu_zu: Array[Texture2D]  # 候选贴图（检查器里拖入多种鱼）
@export var tixing_fanwei := Vector2(0.6, 1.6)  # 体型系数随机范围：0.6 小 ~ 1.6 大
@export var bianju := 80.0  # 屏幕外多远才算离开（像素）

var tixing := 1.0  # 实际体型系数（第 3 课大小判定会读这个值）
var sudu := 100.0  # 游速（像素/秒），由生成器写入
var fangxiang := -1.0  # 1 向右，-1 向左，由生成器写入


func _ready() -> void:
	# 随机体型与贴图；Godot 4 启动时自动播种随机数，不需要 randomize()
	tixing = randf_range(tixing_fanwei.x, tixing_fanwei.y)
	scale = Vector2.ONE * tixing
	if not tie_tu_shu_zu.is_empty():
		$Sprite2D.texture = tie_tu_shu_zu.pick_random()
	$Sprite2D.flip_h = fangxiang < 0.0  # 贴图默认朝右，向左游时翻转


func _process(delta: float) -> void:
	position.x += fangxiang * sudu * delta
	# 用视口宽度做边界，不把 1280 写死
	var pingmu_kuan := get_viewport_rect().size.x
	if position.x < -bianju or position.x > pingmu_kuan + bianju:
		queue_free()  # 游出屏幕：释放节点，避免越积越多
