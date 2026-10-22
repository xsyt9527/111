extends Node2D
class_name Yu
# 玩家鱼：移动规则 + 大吃小判定都在这里

@export var yidong_sudu := 300.0  # 移动速度，像素/秒

const TINGZHI_JULI := 5.0  # 到达判定距离（像素）：离目标点这么近就算到了
var mubiao_dian: Vector2  # 游动目标点（世界坐标），由 Main 写入

var tixing := 1.0  # 玩家体型系数（第 5 课成长会增大它，能吃的鱼随之变多）
var wudi := false  # 受伤后的短暂无敌标记

@onready var panding_qu: Area2D = $PandingQu  # 判定区：监视鱼群
@onready var wudi_dingshi: Timer = $WudiDingshi  # 无敌计时器


func _ready() -> void:
	mubiao_dian = position  # 开局原地不动
	panding_qu.area_entered.connect(_on_panding_qu_entered)
	wudi_dingshi.timeout.connect(_jiechu_wudi)


func _process(delta: float) -> void:
	# 已经到达目标点：原地不动
	if position.distance_to(mubiao_dian) <= TINGZHI_JULI:
		return
	# 朝目标点前进：速度 × delta 保证不同帧率下游速一致
	position = position.move_toward(mubiao_dian, yidong_sudu * delta)
	# 鱼头朝向游动方向（贴图默认朝右，目标在左侧时水平翻转）
	$Sprite2D.flip_h = mubiao_dian.x < position.x


func _on_panding_qu_entered(qu: Area2D) -> void:
	# 闯进判定区的是 NPC 的 Area2D；它的父节点才是 YuNpc 本体
	var yu_npc := qu.get_parent() as YuNpc
	if yu_npc == null:
		return  # 不是鱼群（将来可能有别的区域闯进来），直接忽略
	if tixing > yu_npc.tixing:
		yu_npc.bei_chi()  # 我比它大：吃（无敌期照样能吃）
	elif not wudi:
		_shoushang()  # 它比我大：受伤（无敌期内跳过，不重复伤）


func _shoushang() -> void:
	# 受伤统一入口：第 8 课血量/死亡系统在这里挂钩
	wudi = true
	modulate = Color(1.0, 0.4, 0.4)  # 闪红示警
	wudi_dingshi.start()


func _jiechu_wudi() -> void:
	wudi = false
	modulate = Color.WHITE  # 恢复原色
