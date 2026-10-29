extends Node2D
class_name YuNpc
# NPC 鱼：接收生成器注入的鱼种数据（yu_zhong），按数据随机外观，游出屏幕自动释放

@export var bianju := 80.0  # 屏幕外多远才算离开（像素）
const HONG_GUANG_FANG_DA := 1.5  # 红光层比本体大 50%：露在贴图外的部分才是那圈“红光”

var yu_zhong: YuZhong  # 鱼种数据（生成器在 add_child 前注入；_ready 里读它）
var tixing := 1  # 体型=鱼种等级：同种鱼统一大小，差异由鱼种表决定
var sudu := 100.0  # 游速（像素/秒），由生成器写入
var fangxiang := -1.0  # 1 向右，-1 向左，由生成器写入
var bei_xi: Yu = null  # 吸附目标（玩家 ChiQu 打的标记）：非空 = 被吸中，朝它游

var _hong_guang: Sprite2D  # 红光层：玩家吃得下我时亮，提示“这个是猎物”
var _wan_jia: Yu = null  # 玩家（靠 player 组找）：没有玩家（测试场景）就不亮
var _guang_shi_jian := 0.0  # 红光呼吸相位（秒）

@onready var rou_qu: Area2D = $RouQu  # 鱼肉区：NPC 也能吃鱼肉（策划案 8.1「任何鱼可进食」）


func _ready() -> void:
	# 体型直接取鱼种等级：同种鱼不再随机大小，玩家一眼能判断吃不吃得下
	tixing = yu_zhong.dengji if yu_zhong != null else 1
	scale = Vector2.ONE * ZhangBen.ti_xing_dao_chi_du(tixing)  # 与玩家共用同一条体型→像素曲线
	if yu_zhong != null and yu_zhong.tie_tu != null:
		$Sprite2D.texture = yu_zhong.tie_tu  # 贴图：鱼种定什么就长什么样
	$Sprite2D.flip_h = fangxiang < 0.0  # 贴图默认朝右，向左游时翻转
	_hong_guang = $HongGuang
	_hong_guang.texture = $Sprite2D.texture  # 与本体同一张贴图：不另做美术资源
	_hong_guang.scale = Vector2.ONE * HONG_GUANG_FANG_DA
	var cai: CanvasItemMaterial = CanvasItemMaterial.new()
	cai.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD  # 叠加发光：比半透明盖一层更像“光”
	_hong_guang.material = cai
	_hong_guang.visible = false


func _process(delta: float) -> void:
	if bei_xi != null:
		# 被吸中：朝玩家游（吸力略快于自身游速）；路自己走（设计决策 1A：NPC 自决）
		position = position.move_toward(bei_xi.global_position, sudu * 1.2 * delta)
		$Sprite2D.flip_h = bei_xi.global_position.x < position.x
	else:
		position.x += fangxiang * sudu * delta
		$Sprite2D.flip_h = fangxiang < 0.0  # 贴图默认朝右，向左游时翻转
	# 以相机可视矩形为边界：相机走到哪，鱼群就在哪一屏生成/回收
	var fan_wei := _shi_jiao_fan_wei()
	if position.x < fan_wei.position.x - bianju or position.x > fan_wei.end.x + bianju:
		queue_free()  # 游出当前镜头：释放节点，避免越积越多
	_chi_rou()
	_geng_xin_hong_guang(delta)


func _geng_xin_hong_guang(delta: float) -> void:
	# “玩家能不能吃我”与 yu.gd 嘴圈的判定共用同一常数 Yu.TUN_CHI_BEI_LV——两边永不分叉
	if _wan_jia == null:
		_wan_jia = get_tree().get_first_node_in_group("player") as Yu
	if _wan_jia == null or _wan_jia.tixing < float(tixing) * Yu.TUN_CHI_BEI_LV:
		_hong_guang.visible = false  # 吃不下 / 没有玩家：关灯，少画一层
		return
	_guang_shi_jian += delta
	_hong_guang.visible = true
	_hong_guang.flip_h = $Sprite2D.flip_h  # 跟着本体翻转，红光不会偏到一侧
	# 红通道给到 3.2（Color 分量可以 >1）：贴图多半偏暗，只乘 1 倍的红光根本看不清
	_hong_guang.modulate = Color(3.2, 0.1, 0.1, 0.5 + 0.18 * sin(_guang_shi_jian * 5.0))


func _chi_rou() -> void:
	# NPC 吃可食物：只清场不加经验（NPC 没有成长系统）；路过就吃，不主动追
	for qu in rou_qu.get_overlapping_areas():
		var wu := qu as KeChiWu
		if wu != null and wu.ke_chi:
			wu.bei_chi()


func bei_chi() -> void:
	# 被玩家吃掉的统一入口：先记账再释放（第 3 课挖好的挂钩点在此兑现）
	if yu_zhong != null:
		# 睿智卡的倍率在账本，记账时乘算（第 7 课 buff 生效）
		ZhangBen.jia_jing_yan(int(yu_zhong.fenzhi * ZhangBen.jing_yan_jia_cheng))  # 吃兜底鱼不给经验
	queue_free()


func _shi_jiao_fan_wei() -> Rect2:
	# 相机在世界里的可视矩形；没有相机（测试场景）时退回视口，保持旧行为
	var pingmu := get_viewport_rect().size
	var shi_jiao := get_viewport().get_camera_2d()
	if shi_jiao != null:
		return Rect2(shi_jiao.get_screen_center_position() - pingmu * 0.5, pingmu)
	return Rect2(Vector2.ZERO, pingmu)
