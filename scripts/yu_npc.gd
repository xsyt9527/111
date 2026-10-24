extends Node2D
class_name YuNpc
# NPC 鱼：接收生成器注入的鱼种数据（yu_zhong），按数据随机外观，游出屏幕自动释放

@export var bianju := 80.0  # 屏幕外多远才算离开（像素）

var yu_zhong: YuZhong  # 鱼种数据（生成器在 add_child 前注入；_ready 里读它）
var tixing := 1.0  # 实际体型系数（大小判定读这个值）
var sudu := 100.0  # 游速（像素/秒），由生成器写入
var fangxiang := -1.0  # 1 向右，-1 向左，由生成器写入
var bei_xi: Yu = null  # 吸附目标（玩家 ChiQu 打的标记）：非空 = 被吸中，朝它游


func _ready() -> void:
	# 体型范围来自鱼种表；没接到鱼种数据时用旧默认值兜底（过渡态）
	var fanwei := Vector2(0.6, 1.6) if yu_zhong == null else yu_zhong.tixing_fanwei
	tixing = randf_range(fanwei.x, fanwei.y)
	scale = Vector2.ONE * tixing
	if yu_zhong != null and yu_zhong.tie_tu != null:
		$Sprite2D.texture = yu_zhong.tie_tu  # 贴图：鱼种定什么就长什么样
	$Sprite2D.flip_h = fangxiang < 0.0  # 贴图默认朝右，向左游时翻转


func _process(delta: float) -> void:
	if bei_xi != null:
		# 被吸中：朝玩家游（吸力略快于自身游速）；路自己走（设计决策 1A：NPC 自决）
		position = position.move_toward(bei_xi.global_position, sudu * 1.2 * delta)
		$Sprite2D.flip_h = bei_xi.global_position.x < position.x
	else:
		position.x += fangxiang * sudu * delta
		$Sprite2D.flip_h = fangxiang < 0.0  # 贴图默认朝右，向左游时翻转
	# 用视口宽度做边界，不把 1280 写死
	var pingmu_kuan := get_viewport_rect().size.x
	if position.x < -bianju or position.x > pingmu_kuan + bianju:
		queue_free()  # 游出屏幕：释放节点，避免越积越多


func bei_chi() -> void:
	# 被玩家吃掉的统一入口：先记账再释放（第 3 课挖好的挂钩点在此兑现）
	if yu_zhong != null:
		# 睿智卡的倍率在账本，记账时乘算（第 7 课 buff 生效）
		ZhangBen.jia_jing_yan(int(yu_zhong.fenzhi * ZhangBen.jing_yan_jia_cheng))  # 吃兜底鱼不给经验
	queue_free()
