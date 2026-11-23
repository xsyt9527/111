extends Node2D
class_name ErLiaoYu
# 饵料鱼层（浮游小鱼，A 方案生态死锁防护·提案 2/3.2）：1 级 NPC 互吃不过 1.1 门槛，
# 没有这层基础食物谁也长不大。它是「不变」的背景食物，不参与营养 roll、不进图鉴、不进 YuNpc 索敌组。
# 只负责：活着、缓慢漂、被 NPC 吃掉时回调加成长。刷新/回收由 YuQun 统一管理。
const TIE_TU := preload("res://assets/sucai/shenhai_yu/zuan_guang_yu.png")  # 复用钻光鱼贴图（最小可见鱼）
const SHU_ZHI := preload("res://scripts/shu_zhi.gd")

var tixing := SHU_ZHI.ER_LIAO_TI_XING  # 体型远小于 1 级 NPC：1.0 ≥ 0.4×1.1 保证 1 级鱼吃得到
var sudu := 30.0  # 漂移速度（像素/秒）：比 NPC 慢得多，像浮游生物
var fangxiang := -1.0  # 1 向右 / -1 向左
var bei_chi_le := false  # 防止同帧被多条鱼重复吃

var _ti: Sprite2D


func _ready() -> void:
	add_to_group("er_liao_yu")  # NPC 按组找，不靠节点名
	z_index = -2  # 压在 NPC/玩家下面：背景食物层
	_ti = Sprite2D.new()
	_ti.texture = TIE_TU
	# 缩到约 0.4 体型的视觉大小（基准贴图约 152px 宽 → 目标 ~50px）
	_ti.scale = Vector2.ONE * 0.32
	_ti.flip_h = fangxiang < 0.0
	_ti.modulate = Color(0.75, 0.85, 0.95, 0.85)  # 淡蓝半透明：与真正的 NPC 小鱼区分
	add_child(_ti)


func _process(delta: float) -> void:
	position.x += fangxiang * sudu * delta
	_ti.flip_h = fangxiang < 0.0
	# 游出当前房间一定距离就回收（YuQun 会补新的）：房间矩形通过元信息注入
	var qu: Rect2 = get_meta("fang_jian_qu", Rect2())
	if qu.size.x > 0.0 and (position.x < qu.position.x - 80.0 or position.x > qu.end.x + 80.0):
		queue_free()


func bei_chi(chi_zhe = null) -> void:
	# 被 NPC 吃掉：对方走「吃饵料 +0.2 级」的直接成长（提案 3.2 的成长来源）
	if bei_chi_le:
		return
	bei_chi_le = true
	if chi_zhe != null and chi_zhe.has_method("jia_deng_ji_zhi_jie"):
		chi_zhe.call("jia_deng_ji_zhi_jie", 0.2)
	queue_free()
