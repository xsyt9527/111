extends Area2D
class_name KeChiWu
# 可食物基类：鱼肉块与海草/珊瑚共用的契约
# 玩家与 NPC 的 RouQu 只认 KeChiWu——加新的可食物不用再改吃的代码
# ke_chi = 此刻能不能吃（鱼肉有保护期，植物被吃后进重生期）；jing_yan = 吃到的经验
# 红光：玩家靠近 + 此刻能吃 → 亮一圈红晕，提示“这个能吃”（细节见 _geng_xin_hong_guang）

const HONG_GUANG_BAN_JING := 190.0  # 玩家进这个距离才亮：远处不亮，免得满屏红光
const HONG_GUANG_BEICHENG := 1.55   # 红光层比本体大 55%：贴图外露出的一圈才是可见的“红光”

var ke_chi := false  # 是否能被吃：子类自己决定何时翻真/翻假
var jing_yan := 1    # 吃到的经验（玩家独享；NPC 只清场不加经验）
var ji_e := 8.0      # 吃到的饥饿（玩家独享；植物/鱼肉在生成时覆写）

var _hong_guang: Sprite2D = null  # 红光层（子场景可选）：没有就跳过，不影响可食物契约
var _wan_jia: Node2D = null       # 玩家（靠 player 组找）：没有玩家（测试场景）就不亮
var _guang_shi_jian := 0.0        # 红光呼吸相位（秒）


func _ready() -> void:
	# 子类在 _ready 里会注入贴图/显示比例，所以必须 super._ready() 放到最后调用
	_wan_jia = get_tree().get_first_node_in_group("player") as Node2D
	_hong_guang = get_node_or_null("HongGuang") as Sprite2D
	if _hong_guang == null:
		return
	var tie: Texture2D = $Sprite2D.texture
	if tie != null:
		_hong_guang.texture = tie  # 与本体同一张贴图：不用另画美术资源
		_hong_guang.scale = $Sprite2D.scale * HONG_GUANG_BEICHENG  # 跟着本体的显示比例走
	var cai: CanvasItemMaterial = CanvasItemMaterial.new()
	cai.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD  # 叠加发光：比半透明盖一层更像“光”
	_hong_guang.material = cai
	_hong_guang.visible = false


func _process(delta: float) -> void:
	_geng_xin_hong_guang(delta)


func _geng_xin_hong_guang(delta: float) -> void:
	# 判定：此刻能吃 + 玩家在范围内 → 亮；越近越亮，并带呼吸闪
	# 复用的是“可食物”这一层契约：以后加新的食物，场景里挂个 HongGuang 就自动有红光
	if _hong_guang == null:
		return
	if not ke_chi or _wan_jia == null:
		_hong_guang.visible = false
		return
	var ju_li := global_position.distance_to(_wan_jia.global_position)
	if ju_li > HONG_GUANG_BAN_JING:
		_hong_guang.visible = false
		return
	_guang_shi_jian += delta
	_hong_guang.visible = true
	var jin_bi := 1.0 - ju_li / HONG_GUANG_BAN_JING  # 0=圈边 1=贴脸
	var tou_ming := 0.55 + 0.3 * jin_bi
	tou_ming *= 0.75 + 0.25 * sin(_guang_shi_jian * 6.0)  # 呼吸：静止食物也能一眼看到
	# 红通道给到 2.8（Color 分量可以 >1）：素材偏暗，1 倍红的叠加几乎看不见
	_hong_guang.modulate = Color(2.8, 0.12, 0.12, tou_ming)


func bei_chi() -> void:
	# 被吃掉的统一入口：谁吃谁负责奖励，这里只管自己退场（子类按需覆写）
	queue_free()
