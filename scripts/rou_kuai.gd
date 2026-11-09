extends KeChiWu
class_name RouKuai
# 鱼肉块：鱼受伤时掉落的可进食物，漂浮一段时间后消失
# 策划案 8.1「受伤掉肉」+ 8.4「鱼肉」：伤害=掉肉量，任何鱼都能吃
# 美术：assets/sucai/shenhai_rou/rou_kuai_01~05.png（01=3 视图侧视，02~05=四帧姿态）
const TIE_TU_ZU: Array[Texture2D] = [
	preload("res://assets/sucai/shenhai_rou/rou_kuai_01.png"),
	preload("res://assets/sucai/shenhai_rou/rou_kuai_02.png"),
	preload("res://assets/sucai/shenhai_rou/rou_kuai_03.png"),
	preload("res://assets/sucai/shenhai_rou/rou_kuai_04.png"),
	preload("res://assets/sucai/shenhai_rou/rou_kuai_05.png"),
]  # 五种外观随机抽，避免一地鱼肉长得一模一样
const KE_CHI_YAN_CHI := 0.4  # 掉落后 0.4 秒才可被吃：防止掉落者原地瞬间吃回
const SHOU_MING := 12.0  # 存活 12 秒，最后 1 秒淡出
const SHU_ZHI := preload("res://scripts/shu_zhi.gd")  # A 核心数值表

var piao_su := Vector2.ZERO  # 漂浮速度（像素/秒）
var yi_cun_huo := 0.0  # 已存活时长（秒）
var fu_rou_you_er_sheng_yu := 0.0  # 腐肉诱饵剩余（秒）：>0 时发光并主动吸引附近 NPC
var xi_yin_ban_jing := 0.0  # 腐肉诱饵的吸引半径（世界像素）
var _you_er_guang_shi := 0.0  # 诱饵发光呼吸相位（秒）


func _ready() -> void:
	add_to_group("rou_kuai")  # 测试/清场按组找，不靠节点名
	ji_e = SHU_ZHI.ROU_HUI_JI_E  # A7：鱼肉回饥饿 8（原来硬编码 5）
	$Sprite2D.texture = TIE_TU_ZU.pick_random()
	# 随机方向漂出去：别让鱼肉叠在受伤者身上
	var jiao := randf_range(0.0, TAU)
	piao_su = Vector2(cos(jiao), sin(jiao)) * randf_range(18.0, 32.0) + Vector2(0.0, -12.0)
	rotation = randf_range(-0.25, 0.25)
	$KeChiDingshi.timeout.connect(_jie_chu_bao_hu)
	$KeChiDingshi.start()
	super._ready()  # 基类要读 $Sprite2D.texture 配红光层，必须等外观定下来再调


func _process(delta: float) -> void:
	yi_cun_huo += delta
	position += piao_su * delta
	piao_su = piao_su.move_toward(Vector2(0.0, -8.0), 12.0 * delta)  # 水的阻力：慢慢漂停
	rotation += sin(yi_cun_huo * 3.0) * 0.15 * delta
	if yi_cun_huo > SHOU_MING - 1.0:
		modulate.a = clampf(SHOU_MING - yi_cun_huo, 0.0, 1.0)  # 最后 1 秒淡出
	# 腐肉诱饵：还活着就金红呼吸发光——玩家和 NPC 都能一眼看到“这块肉在勾鱼”
	if fu_rou_you_er_sheng_yu > 0.0:
		fu_rou_you_er_sheng_yu = maxf(0.0, fu_rou_you_er_sheng_yu - delta)
		_you_er_guang_shi += delta
		var mai := 0.5 + 0.5 * sin(_you_er_guang_shi * 8.0)
		modulate = Color(1.0 + 0.45 * mai, 0.7 + 0.25 * mai, 0.35 + 0.2 * mai, modulate.a)
	elif modulate != Color.WHITE:
		modulate = Color(1.0, 1.0, 1.0, modulate.a)  # 诱饵到点：恢复本色，透明度保留淡出值
	if yi_cun_huo >= SHOU_MING:
		queue_free()
	super._process(delta)  # 基类管红光：子类覆写了 _process 就必须显式接力


func _jie_chu_bao_hu() -> void:
	ke_chi = true  # 保护期结束：任何鱼的 RouQu 都能吃它
