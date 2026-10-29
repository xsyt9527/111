extends Node2D
class_name ZhiWuQun
# 可食用植物生成器：按九宫格每格撒几株海草/珊瑚（策划案第十章）
# 体型来源之一——玩家吃了加经验，和吃鱼、吃鱼肉同一条成长通道
# 位置在 _ready 里随机撒一次，之后固定：植物被吃只是隐藏，株位不变

const ZHI_WU_CHANGJING := preload("res://scenes/ZhiWu.tscn")  # 植物蓝图（Area2D + 重生计时器）

const HAI_CAO_TIE_TU: Array[Texture2D] = [
	preload("res://assets/sucai/shenhai_zhuangshi/haicao_01.png"),
	preload("res://assets/sucai/shenhai_zhuangshi/haicao_02.png"),
	preload("res://assets/sucai/shenhai_zhuangshi/haicao_03.png"),
]
const SHAN_HU_TIE_TU: Array[Texture2D] = [
	preload("res://assets/sucai/shenhai_zhuangshi/shanhu_01.png"),
	preload("res://assets/sucai/shenhai_zhuangshi/shanhu_02.png"),
	preload("res://assets/sucai/shenhai_zhuangshi/shanhu_03.png"),
]

const HAI_CAO_JING_YAN := 1  # 海草：到处都是，收益低（等同一块鱼肉）
const SHAN_HU_JING_YAN := 2  # 珊瑚：长在地貌区，收益高一点，值得绕路
const HAI_CAO_JI_E := 8.0    # 海草回饥饿：和鱼肉一个档
const SHAN_HU_JI_E := 12.0   # 珊瑚更顶饱：值得为它绕路
const GE_KUAN := 1376.0      # 单格宽（九宫格 3×3，总图 4128×2304）
const GE_GAO := 768.0
const BIAN_JU := 120.0       # 格内留边：别贴着格子边界长
const CHU_SHENG_AN_QUAN := 240.0  # 出生点周围不种：开局身边不该堆着食物

@export var mei_ge_qu := 3  # 每格几株（中心格多 2 株，玩家活动最频繁）
@export var chu_sheng_dian := Vector2(2064, 1152)


func _ready() -> void:
	z_index = -1  # 压在鱼下面：鱼从植物前面游过，不会被挡住
	for hang in 3:
		for lie in 3:
			var shu := mei_ge_qu + (2 if hang == 1 and lie == 1 else 0)
			for i in shu:
				var wei_zhi := _sui_ji_wei_zhi(lie, hang)
				if wei_zhi.x < 0.0:
					continue  # 抽不到不撞出生点的位置就少种一株，不硬塞
				_zhong_yi_zhu(wei_zhi)


func _sui_ji_wei_zhi(lie: int, hang: int) -> Vector2:
	# 格内随机取点；撞到出生安全区就重抽，抽 10 次仍不合适就放弃
	for i in 10:
		var p := Vector2(
			lie * GE_KUAN + randf_range(BIAN_JU, GE_KUAN - BIAN_JU),
			hang * GE_GAO + randf_range(BIAN_JU, GE_GAO - BIAN_JU)
		)
		if p.distance_to(chu_sheng_dian) > CHU_SHENG_AN_QUAN:
			return p
	return Vector2(-1.0, -1.0)


func _zhong_yi_zhu(wei_zhi: Vector2) -> void:
	var zhu: ZhiWu = ZHI_WU_CHANGJING.instantiate()
	# 先注入贴图与经验，再进树：植物 _ready 要按贴图尺寸算碰撞半径
	if randf() < 0.55:  # 海草略多于珊瑚（食物链底层该更常见）
		zhu.get_node("Sprite2D").texture = HAI_CAO_TIE_TU.pick_random()
		zhu.jing_yan = HAI_CAO_JING_YAN
		zhu.ji_e = HAI_CAO_JI_E
	else:
		zhu.get_node("Sprite2D").texture = SHAN_HU_TIE_TU.pick_random()
		zhu.jing_yan = SHAN_HU_JING_YAN
		zhu.ji_e = SHAN_HU_JI_E
	zhu.position = wei_zhi
	add_child(zhu)
