extends Area2D
class_name KeChiWu
# 可食物基类：鱼肉块与海草/珊瑚共用的契约
# 玩家与 NPC 的 RouQu 只认 KeChiWu——加新的可食物不用再改吃的代码
# ke_chi = 此刻能不能吃（鱼肉有保护期，植物被吃后进重生期）；jing_yan = 吃到的经验
# 红光：玩家靠近 + 此刻能吃 → 亮一圈红晕，提示“这个能吃”（细节见 _geng_xin_hong_guang）

const HONG_GUANG_BAN_JING := 190.0  # 玩家进这个距离才亮：远处不亮，免得满屏红光
const HONG_GUANG_BEICHENG := 1.8    # 红光层比本体大 80%：TASK-019 放大可吃提示，判定圈不变

var ke_chi := false  # 是否能被吃：子类自己决定何时翻真/翻假
var jing_yan := 1    # 吃到的经验（玩家独享；NPC 只清场不加经验）
var ji_e := 8.0      # 吃到的饥饿（玩家独享；植物/鱼肉在生成时覆写）
var ti_xing_liang := 0.0  # 吃到的体型量：鱼肉按伤害折算，植物为 0（策划案 8.6.2：只有鱼/肉回体型）
var zi_shi_chi_bei := 1.0  # 自己吃回的结算倍率：太岁割肉的诱饵肉 = 2.0（1 块按 2 块）


func chi_shi_ti_xing() -> float:
	# 玩家吃它时实际结算的体型量：普通鱼肉 1.0 倍，专属诱饵肉按 2 块算
	return ti_xing_liang * zi_shi_chi_bei

var _hong_guang: Sprite2D = null  # 红光层（子场景可选）：没有就跳过，不影响可食物契约
var _wan_jia: Node2D = null       # 玩家（靠 player 组找）：没有玩家（测试场景）就不亮
var _ben_ti: Node2D = null        # 本体显示节点：鱼肉用 Sprite2D，植物用 AnimatedSprite2D
var _guang_shi_jian := 0.0        # 红光呼吸相位（秒）


func _ready() -> void:
	# 子类在 _ready 里会注入贴图/显示比例，所以必须 super._ready() 放到最后调用
	_wan_jia = get_tree().get_first_node_in_group("player") as Node2D
	_hong_guang = get_node_or_null("HongGuang") as Sprite2D
	if _hong_guang == null:
		return
	# 两种本体都认：旧鱼肉/单帧食物是 Sprite2D，新的海草/珊瑚是 AnimatedSprite2D
	_ben_ti = get_node_or_null("AnimatedSprite2D") as Node2D
	if _ben_ti == null:
		_ben_ti = get_node_or_null("Sprite2D") as Node2D
	if _ben_ti == null:
		return
	var tie := _dang_qian_tie_tu()
	if tie != null:
		_hong_guang.texture = tie  # 与本体同一张贴图：不用另画美术资源
		_hong_guang.scale = _ben_ti.scale * HONG_GUANG_BEICHENG  # 跟着本体的显示比例走
	var cai: CanvasItemMaterial = CanvasItemMaterial.new()
	cai.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD  # 叠加发光：比半透明盖一层更像“光”
	_hong_guang.material = cai
	_hong_guang.visible = false


func _dang_qian_tie_tu() -> Texture2D:
	# 动画本体取「当前帧」贴图：植物会摆，红光必须跟着帧走，否则两张图会错位
	if _ben_ti is AnimatedSprite2D:
		var dong := _ben_ti as AnimatedSprite2D
		if dong.sprite_frames == null:
			return null
		if not dong.sprite_frames.has_animation(dong.animation):
			return null
		return dong.sprite_frames.get_frame_texture(dong.animation, dong.frame)
	if _ben_ti is Sprite2D:
		return (_ben_ti as Sprite2D).texture
	return null


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
	# 同步当前帧：植物每帧在摆，红光贴图要跟着换（仅换引用，不复制像素）
	var tie := _dang_qian_tie_tu()
	if tie != null and _hong_guang.texture != tie:
		_hong_guang.texture = tie
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
