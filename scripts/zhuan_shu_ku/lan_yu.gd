extends RefCounted
# 钻光鱼（lan_yu）专属技模块——3 分支 ×（1 主动 + 1 被动）
# 契约见 docs/专属技模块_开发契约.md：框架按技能 id 分派，本文件只由该鱼种实现者维护

const TE_XIAO := preload("res://scripts/te_xiao.gd")

const ZHU_DONG_IDS: Array[StringName] = [
	&"ying_ju_cheng_long",
	&"zu_zhou_bao_zi",
	&"deng_li_zi_qi_she",
]
const BEI_DONG_IDS: Array[StringName] = [
	&"ju_qun",
	&"xing_chuan_bo_san",
	&"ji_guang_gui_ji",
]

# ---- 行为常量（契约允许：节拍 / 数量 / 几何；数值一律从 NengLi 字段读）----
const YING_JU_FEN_SHEN_SHU := 5          # 萤聚成龙：5 个光点分身
const YING_JU_HUAN_RAO_SHEN_WEI := 2.0    # 环绕半径 2 身位
const YING_JU_XUAN_ZHUAN_SU_DU := 1.1     # 环绕角速度（弧度/秒，纯表现）
const YING_JU_ZI_HUI_KUAN_XIAN := 0.2     # 分身兜底计时器比技能持续多留的宽限（秒）
const SHE_XIAN_BAN_KUAN_SHEN_WEI := 0.5   # 等离子射线半宽 0.5 身位（总宽 1 身位）
const SHE_XIAN_SHAN_GUANG_MIAO := 0.25    # 射线闪光存留（秒）
const GUI_JI_BAN_KUAN_BEI := 0.5          # 极光路径半宽 = 数据里的总宽 ×0.5
const GUI_JI_TU_ZI_HUI_KUAN_XIAN := 0.2   # 极光路径视觉兜底计时器宽限（秒）
const JU_QUN_SHANG_XIAN := 5              # 聚群最多折算 5 条同种小鱼
const YUN_TU_ZI_HUI_KUAN_XIAN := 0.2      # 孢子云兜底计时器宽限（秒）

# ---- 玩家 meta 键（模块持久状态；契约禁止往 Yu 加成员变量）----
const MK_YING_JU_SHENG_YU := &"zs_lan_yu_ying_ju_sheng_yu"
const MK_YING_JU_SHI_JIAN := &"zs_lan_yu_ying_ju_shi_jian"
const MK_YING_JU_JI_SHI := &"zs_lan_yu_ying_ju_ji_shi"
const MK_YING_JU_FEN_SHEN := &"zs_lan_yu_ying_ju_fen_shen"

const MK_BAO_ZI_MU_ID := &"zs_lan_yu_bao_zi_mu_id"
const MK_BAO_ZI_MU_WEI := &"zs_lan_yu_bao_zi_mu_wei"
const MK_BAO_ZI_SHENG_YU := &"zs_lan_yu_bao_zi_sheng_yu"
const MK_BAO_ZI_JI_SHI := &"zs_lan_yu_bao_zi_ji_shi"

const MK_YUN_LIE := &"zs_lan_yu_xing_chuan_yun_lie"

const MK_GUI_JI_QI_DIAN := &"zs_lan_yu_gui_ji_qi_dian"
const MK_GUI_JI_ZHONG_DIAN := &"zs_lan_yu_gui_ji_zhong_dian"
const MK_GUI_JI_FANG := &"zs_lan_yu_gui_ji_fang"
const MK_GUI_JI_BAN_KUAN := &"zs_lan_yu_gui_ji_ban_kuan"
const MK_GUI_JI_SHENG_YU := &"zs_lan_yu_gui_ji_sheng_yu"
const MK_GUI_JI_JI_SHI := &"zs_lan_yu_gui_ji_ji_shi"
const MK_GUI_JI_TU := &"zs_lan_yu_gui_ji_tu"


static func guan_zhu_dong(bian_hao: StringName) -> bool:
	return ZHU_DONG_IDS.has(bian_hao)


static func zhu_dong_ids() -> Array[StringName]:
	return ZHU_DONG_IDS


static func bei_dong_ids() -> Array[StringName]:
	return BEI_DONG_IDS


static func shi_fang(yu, neng: NengLi, dang: int) -> bool:
	# 主动释放：返回 true 才扣冷却/播音效；false = 空放
	if not _ke_yong(yu):
		return false
	match neng.bian_hao:
		&"ying_ju_cheng_long":
			_shi_fang_ying_ju(yu, neng, dang)
			return true  # 萤聚成龙没有目标也能放：光点先环绕，敌人靠近才啃
		&"zu_zhou_bao_zi":
			return _shi_fang_bao_zi(yu, neng, dang)
		&"deng_li_zi_qi_she":
			return _shi_fang_deng_li_zi(yu, neng, dang)
	return false


static func geng_xin(yu, neng: NengLi, delta: float) -> void:
	# 每帧：主动/被动都可能进来，按 id 分派各自的持续效果与节拍
	if not is_instance_valid(yu):
		return
	match neng.bian_hao:
		&"ying_ju_cheng_long":
			_geng_xin_ying_ju(yu, neng, delta)
		&"zu_zhou_bao_zi":
			_geng_xin_bao_zi(yu, neng, delta)
		&"deng_li_zi_qi_she":
			_geng_xin_deng_li_zi(yu, neng, delta)
		&"xing_chuan_bo_san":
			_geng_xin_yun(yu, neng, delta)
		&"ji_guang_gui_ji":
			_geng_xin_gui_ji(yu, neng, delta)


static func shi_jian(_yu, _neng: NengLi, _jian: StringName, _shu_ju: Dictionary) -> bool:
	# 本鱼种 6 条技能都不靠命中/受击事件触发（孢子由主动自身节拍结算）
	return false


static func wen(yu, neng: NengLi, jian: StringName, _shu_ju: Dictionary) -> float:
	# 聚群：2 身位内每有一条同种（钻光鱼）活 NPC，咬伤 ×1.3，最多折 5 条
	if neng == null or neng.bian_hao != &"ju_qun" or jian != &"yao_shang_bei":
		return 1.0
	if not _ke_yong(yu):
		return 1.0
	var ban := _dan_dang_zhi(neng, &"ban_jing") * _shen_wei(yu)
	var mei := _dan_dang_zhi(neng, &"shu_zhi")
	var shu := 0
	for node in yu.get_tree().get_nodes_in_group("yu_npc"):
		var npc := node as YuNpc
		if npc == null or npc.si_le or not is_instance_valid(npc):
			continue
		if npc.yu_zhong == null or npc.yu_zhong.bian_hao != &"lan_yu":
			continue
		if yu.global_position.distance_to(npc.global_position) <= ban:
			shu += 1
	return 1.0 + mei * float(mini(shu, JU_QUN_SHANG_XIAN))


# ---- 公共小工具 ----

static func _dan_dang_zhi(neng: NengLi, jian: StringName) -> float:
	# 专属技单档（数据保证 zui_da_dang = 1）：统一按 1 档读，数值全部来自 .tres
	return neng.dang_zhi(jian, 1)


static func _shen_wei(yu) -> float:
	return float(yu._shen_wei())


static func _ke_yong(yu) -> bool:
	# 有父节点才能挂召唤物/视觉节点；玩家本体必须已经在场
	return is_instance_valid(yu) and yu.is_inside_tree() and yu.get_parent() != null


static func _zui_jin_npc(yu, ban_jing: float, tiao_guo_boss := false) -> YuNpc:
	# 玩家周围最近的目标；孢子类技能按设计排除首领
	var zui: YuNpc = null
	var zui_ju := INF
	for node in yu.get_tree().get_nodes_in_group("yu_npc"):
		var npc := node as YuNpc
		if npc == null or npc.si_le or not is_instance_valid(npc):
			continue
		if tiao_guo_boss and npc.shi_boss:
			continue
		var ju: float = yu.global_position.distance_to(npc.global_position)
		if ju <= ban_jing and ju < zui_ju:
			zui_ju = ju
			zui = npc
	return zui


static func _zui_jin_npc_wei(yu, wei: Vector2, ban_jing: float, yi_yao: Dictionary) -> YuNpc:
	# 指定点周围最近、且本拍还没被别的光点咬过的目标
	var zui: YuNpc = null
	var zui_ju := INF
	for node in yu.get_tree().get_nodes_in_group("yu_npc"):
		var npc := node as YuNpc
		if npc == null or npc.si_le or not is_instance_valid(npc):
			continue
		if yi_yao.has(npc.get_instance_id()):
			continue
		var ju: float = wei.distance_to(npc.global_position)
		if ju <= ban_jing and ju < zui_ju:
			zui_ju = ju
			zui = npc
	return zui


# ---- 主动 1：萤聚成龙 ----

static func _shi_fang_ying_ju(yu, neng: NengLi, dang: int) -> void:
	# 召唤 5 个光点分身：挂在场景层（yu.get_parent()），每个都是一个 Sprite2D
	_qing_fen_shen(yu)
	var chi := maxf(0.1, neng.dang_zhi(&"chi_xu", dang))
	var huan := YING_JU_HUAN_RAO_SHEN_WEI * _shen_wei(yu)
	var tu := _fen_shen_tu(yu)
	var lie: Array = []
	for i in YING_JU_FEN_SHEN_SHU:
		var sp := Sprite2D.new()
		sp.name = "LanYuFenShen%d" % i
		sp.texture = tu
		sp.modulate = Color(0.55, 1.0, 1.0, 0.85)
		sp.z_index = yu.z_index + 1
		sp.scale = Vector2.ONE * maxf(0.3, yu.scale.x * 0.45)
		var cai := CanvasItemMaterial.new()
		cai.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD  # 发光叠加：光点不会像贴纸一样压暗
		sp.material = cai
		var jiao := TAU * float(i) / float(YING_JU_FEN_SHEN_SHU)
		sp.set_meta(&"lan_yu_jiao", jiao)
		yu.get_parent().add_child(sp)
		sp.global_position = yu.global_position + Vector2.RIGHT.rotated(jiao) * huan
		# 兜底计时器：玩家本体提前离场/模块没来得及收尾时，光点也能自己消失
		var ji_shi := Timer.new()
		ji_shi.wait_time = chi + YING_JU_ZI_HUI_KUAN_XIAN
		ji_shi.one_shot = true
		ji_shi.autostart = true
		ji_shi.timeout.connect(sp.queue_free)
		sp.add_child(ji_shi)
		lie.append(sp)
	yu.set_meta(MK_YING_JU_FEN_SHEN, lie)
	yu.set_meta(MK_YING_JU_SHENG_YU, chi)
	yu.set_meta(MK_YING_JU_SHI_JIAN, 0.0)
	yu.set_meta(MK_YING_JU_JI_SHI, maxf(0.05, neng.dang_zhi(&"nei_bu_leng_que", dang)))


static func _geng_xin_ying_ju(yu, neng: NengLi, delta: float) -> void:
	var sheng := float(yu.get_meta(MK_YING_JU_SHENG_YU, 0.0))
	if sheng <= 0.0:
		var can_lie: Array = yu.get_meta(MK_YING_JU_FEN_SHEN, [])
		if not can_lie.is_empty():
			_qing_fen_shen(yu)  # 元数据残留兜底（换形态/本体离场）
		return
	sheng = maxf(0.0, sheng - delta)
	yu.set_meta(MK_YING_JU_SHENG_YU, sheng)
	if sheng <= 0.0:
		_qing_fen_shen(yu)  # 到期逐个 queue_free
		return
	var shi_jian := float(yu.get_meta(MK_YING_JU_SHI_JIAN, 0.0)) + delta
	yu.set_meta(MK_YING_JU_SHI_JIAN, shi_jian)
	var lie: Array = yu.get_meta(MK_YING_JU_FEN_SHEN, [])
	var huan := YING_JU_HUAN_RAO_SHEN_WEI * _shen_wei(yu)
	var ban: float = yu.fan_wei_xiu_zheng(neng.dang_zhi(&"ban_jing", 1) * _shen_wei(yu), 0.5)
	var shang := neng.dang_zhi(&"shu_zhi", 1)
	var dian := neng.dang_zhi(&"fu_shu_zhi", 1)
	var jian_ge := maxf(0.05, neng.dang_zhi(&"nei_bu_leng_que", 1))
	# 1) 每帧只更新环绕位置（纯表现）
	for node in lie:
		var sp := node as Sprite2D
		if sp == null or not is_instance_valid(sp):
			continue
		var jiao := float(sp.get_meta(&"lan_yu_jiao", 0.0)) + shi_jian * YING_JU_XUAN_ZHUAN_SU_DU
		sp.global_position = yu.global_position + Vector2.RIGHT.rotated(jiao) * huan
		sp.rotation = jiao + PI * 0.5
	# 2) 啃咬节拍：每个光点各找最近目标，同一拍对同一目标只咬一次
	var ji := float(yu.get_meta(MK_YING_JU_JI_SHI, jian_ge)) - delta
	while ji <= 0.0:
		ji += jian_ge
		var yi_yao := {}
		for node in lie:
			var sp := node as Sprite2D
			if sp == null or not is_instance_valid(sp):
				continue
			var mu := _zui_jin_npc_wei(yu, sp.global_position, ban, yi_yao)
			if mu == null:
				continue
			yi_yao[mu.get_instance_id()] = true
			# 契约：无视防御的直伤对首领减半
			mu.shou_zhi_jie_shang(shang * (0.5 if mu.shi_boss else 1.0))
			mu.jia_dian_ma(dian)
			TE_XIAO.fang_dian(yu.get_parent(), mu.global_position, 0.35)
	yu.set_meta(MK_YING_JU_JI_SHI, ji)


static func _qing_fen_shen(yu) -> void:
	# 光点到期/重放/换形态时统一清场
	var lie: Array = yu.get_meta(MK_YING_JU_FEN_SHEN, [])
	for node in lie:
		if is_instance_valid(node):
			node.queue_free()
	yu.set_meta(MK_YING_JU_FEN_SHEN, [])
	yu.set_meta(MK_YING_JU_SHENG_YU, 0.0)
	yu.set_meta(MK_YING_JU_JI_SHI, 0.0)


static func _fen_shen_tu(yu) -> Texture2D:
	# 光点外观 = 玩家当前游泳帧：进化后自动变成进化形态的贴图
	var ben := yu.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if ben != null and ben.sprite_frames != null and ben.sprite_frames.has_animation(&"you"):
		return ben.sprite_frames.get_frame_texture(&"you", 0)
	return null


# ---- 主动 2：诅咒孢子 ----

static func _shi_fang_bao_zi(yu, neng: NengLi, dang: int) -> bool:
	# 命中最近的非首领 NPC：meta 记目标实例 id + 位置 + 剩余时间
	_qing_bao_zi(yu)
	var ban: float = yu.fan_wei_xiu_zheng(neng.dang_zhi(&"ban_jing", dang) * _shen_wei(yu), 0.5)
	var mu := _zui_jin_npc(yu, ban, true)
	if mu == null:
		return false  # 没有可附着的目标：空放不扣冷却
	yu.set_meta(MK_BAO_ZI_MU_ID, mu.get_instance_id())
	yu.set_meta(MK_BAO_ZI_MU_WEI, mu.global_position)
	yu.set_meta(MK_BAO_ZI_SHENG_YU, maxf(0.1, neng.dang_zhi(&"chi_xu", dang)))
	yu.set_meta(MK_BAO_ZI_JI_SHI, maxf(0.05, neng.dang_zhi(&"nei_bu_leng_que", dang)))
	TE_XIAO.zhong_du(yu.get_parent(), mu.global_position, 0.7)
	return true


static func _geng_xin_bao_zi(yu, neng: NengLi, delta: float) -> void:
	var mu_id := int(yu.get_meta(MK_BAO_ZI_MU_ID, 0))
	if mu_id == 0:
		return
	var sheng := float(yu.get_meta(MK_BAO_ZI_SHENG_YU, 0.0))
	if sheng <= 0.0:
		_qing_bao_zi(yu)
		return
	sheng = maxf(0.0, sheng - delta)
	yu.set_meta(MK_BAO_ZI_SHENG_YU, sheng)
	var mu := instance_from_id(mu_id) as YuNpc
	var mu_wei: Vector2 = yu.get_meta(MK_BAO_ZI_MU_WEI, yu.global_position)
	if mu == null or not is_instance_valid(mu) or mu.si_le or mu.shi_boss:
		# 目标死亡/失效：孢子立即结束。云只由「被孢子吸到最小体型」那条出口生成，
		# 别的死因不该算「吸死」，不触发星传播散
		_qing_bao_zi(yu)
		return
	if sheng <= 0.0:
		_qing_bao_zi(yu)
		return
	mu_wei = mu.global_position
	yu.set_meta(MK_BAO_ZI_MU_WEI, mu_wei)
	var ji_ge := maxf(0.05, neng.dang_zhi(&"nei_bu_leng_que", 1))
	var ji := float(yu.get_meta(MK_BAO_ZI_JI_SHI, ji_ge)) - delta
	var shang := neng.dang_zhi(&"shu_zhi", 1)
	var hui := neng.dang_zhi(&"fu_shu_zhi", 1)
	while ji <= 0.0:
		ji += ji_ge
		if not is_instance_valid(mu) or mu.si_le:
			break
		mu.shou_zhi_jie_shang(shang)
		ZhangBen.hui_ti_xing(hui)  # 吸血链：吸多少级就回多少级体型
		if not is_instance_valid(mu):
			_qing_bao_zi(yu)
			return
		if mu.si_le:
			_qing_bao_zi(yu)
			return
		if mu.tixing <= YuNpc.ZUI_XIAO_TI_XING + 0.0001:
			# 本作普通 NPC 直伤只会夹到最小体型；吸到最小即视为「被孢子吸死」，
			# 走无奖励离场出口，让被动「星传播散」能真正触发
			mu_wei = mu.global_position
			mu.bei_chi(false, null)
			_bao_zi_si_wang(yu, mu_wei)
			_qing_bao_zi(yu)
			return
	yu.set_meta(MK_BAO_ZI_JI_SHI, ji)


static func _qing_bao_zi(yu) -> void:
	# 不清 MK_BAO_ZI_MU_WEI：死亡瞬间还要拿最后位置
	yu.set_meta(MK_BAO_ZI_MU_ID, 0)
	yu.set_meta(MK_BAO_ZI_SHENG_YU, 0.0)
	yu.set_meta(MK_BAO_ZI_JI_SHI, 0.0)


static func _bao_zi_si_wang(yu, wei: Vector2) -> void:
	# 星传播散：把孢子吸死的位置追加进 meta 列表（云本体的结算在被动里）
	# 没装备这条被动就不留云：避免玩家只带「诅咒孢子」时白生成视觉节点
	if ZhangBen.dang_qian_bei_dong_ceng(&"xing_chuan_bo_san") <= 0:
		return
	var bei := ZhangBen.zhao_bei_dong(&"xing_chuan_bo_san")
	if bei == null:
		return
	var chi := maxf(0.1, bei.dang_zhi(&"chi_xu", 1))
	var jian := maxf(0.05, bei.dang_zhi(&"nei_bu_leng_que", 1))
	var ban := maxf(0.0, bei.dang_zhi(&"ban_jing", 1)) * _shen_wei(yu)
	var yun_lie: Array = yu.get_meta(MK_YUN_LIE, [])
	var tu := TE_XIAO.DU_TE_XIAO.get_frame_texture(&"bao", 0)
	var sp := Sprite2D.new()
	sp.name = "LanYuBaoZiYun"
	sp.texture = tu
	sp.global_position = wei
	sp.modulate = Color(0.55, 1.0, 0.55, 0.55)
	sp.z_index = 4
	if tu != null:
		sp.scale = Vector2.ONE * maxf(0.5, ban * 2.0 / float(maxi(tu.get_width(), 1)))
	var cai := CanvasItemMaterial.new()
	cai.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sp.material = cai
	yu.get_parent().add_child(sp)
	# 云自身也带兜底计时器：被动没装备/没来得及清时，视觉不会永久留场
	var ji_shi := Timer.new()
	ji_shi.wait_time = chi + YUN_TU_ZI_HUI_KUAN_XIAN
	ji_shi.one_shot = true
	ji_shi.autostart = true
	ji_shi.timeout.connect(sp.queue_free)
	sp.add_child(ji_shi)
	yun_lie.append({"wei": wei, "sheng_yu": chi, "ji_shi": jian, "tu": sp, "xin": true})
	yu.set_meta(MK_YUN_LIE, yun_lie)


# ---- 主动 3：等离子齐射 ----

static func _shi_fang_deng_li_zi(yu, neng: NengLi, dang: int) -> bool:
	# 沿朝向贯穿射线：先扫全场，没有命中就返回 false（空放不扣冷却）
	var qi: Vector2 = yu.global_position
	var fang: Vector2 = yu._chao_xiang_fang()
	var chang: float = yu.fan_wei_xiu_zheng(neng.dang_zhi(&"ban_jing", dang) * _shen_wei(yu), 1.5)
	var ban_kuan := SHE_XIAN_BAN_KUAN_SHEN_WEI * _shen_wei(yu)
	var shang := neng.dang_zhi(&"shu_zhi", dang)
	var mu_lie := _she_xian_ming_zhong(yu, qi, fang, chang, ban_kuan)
	if mu_lie.is_empty():
		return false
	for node in mu_lie:
		var mu := node as YuNpc
		if mu == null or mu.si_le:
			continue
		# 无视减伤/反甲直扣；首领减半（契约：boss 免疫状态、无视防御类减半）
		mu.shou_zhi_jie_shang(shang * (0.5 if mu.shi_boss else 1.0))
	_she_xian_biao_yan(yu, qi, fang, chang, ban_kuan)
	_ji_lu_gui_ji(yu, qi, fang, chang, ban_kuan)
	return true


static func _she_xian_ming_zhong(yu, qi: Vector2, fang: Vector2, chang: float, ban_kuan: float) -> Array:
	# 点到线段的矩形判定：前向投影在射程内 + 侧向偏移在射线半宽内
	var jie: Array = []
	var ce := Vector2(-fang.y, fang.x)
	for node in yu.get_tree().get_nodes_in_group("yu_npc"):
		var npc := node as YuNpc
		if npc == null or npc.si_le or not is_instance_valid(npc):
			continue
		var cha := npc.global_position - qi
		var qian := cha.dot(fang)
		if qian < 0.0 or qian > chang:
			continue
		if absf(cha.dot(ce)) > ban_kuan:
			continue
		jie.append(npc)
	return jie


static func _geng_xin_deng_li_zi(yu, _neng: NengLi, delta: float) -> void:
	# 主动只负责极光路径的寿命；路径伤害结算在被动「极光轨迹」里
	var sheng := float(yu.get_meta(MK_GUI_JI_SHENG_YU, 0.0))
	if sheng <= 0.0:
		return
	sheng = maxf(0.0, sheng - delta)
	yu.set_meta(MK_GUI_JI_SHENG_YU, sheng)
	if sheng <= 0.0:
		_gui_ji_qing_li(yu)


static func _she_xian_biao_yan(yu, qi: Vector2, fang: Vector2, chang: float, ban_kuan: float) -> void:
	# 瞬发射线的亮光：Sprite2D 沿射线拉伸，0.25 秒淡出后自毁
	var sp := _zuo_she_xian_tu(yu, qi, fang, chang, ban_kuan, &"LanYuSheXianShan", 0.9)
	if sp == null:
		return
	var tw := sp.create_tween()
	tw.tween_property(sp, "modulate:a", 0.0, SHE_XIAN_SHAN_GUANG_MIAO)
	tw.tween_callback(sp.queue_free)


static func _ji_lu_gui_ji(yu, qi: Vector2, fang: Vector2, chang: float, she_xian_ban_kuan: float) -> void:
	# 极光轨迹：释放时把起点/终点/方向/半宽/结束时间写入 meta，并留一条路径视觉。
	# 这条路径本身是被动效果：没装备「极光轨迹」就不留、也不结算
	_gui_ji_qing_li(yu)
	var bei := ZhangBen.zhao_bei_dong(&"ji_guang_gui_ji")
	if bei == null:
		return
	var chi := maxf(0.1, bei.dang_zhi(&"chi_xu", 1))
	var jian := maxf(0.05, bei.dang_zhi(&"nei_bu_leng_que", 1))
	# 被动数据里的 ban_jing 是路径总宽（身位），模块取一半做线段判定的半宽
	var ban_kuan := maxf(0.05, bei.dang_zhi(&"ban_jing", 1) * _shen_wei(yu) * GUI_JI_BAN_KUAN_BEI)
	yu.set_meta(MK_GUI_JI_QI_DIAN, qi)
	yu.set_meta(MK_GUI_JI_ZHONG_DIAN, qi + fang * chang)
	yu.set_meta(MK_GUI_JI_FANG, fang)
	yu.set_meta(MK_GUI_JI_BAN_KUAN, ban_kuan)
	yu.set_meta(MK_GUI_JI_SHENG_YU, chi)
	yu.set_meta(MK_GUI_JI_JI_SHI, jian)
	var sp := _zuo_she_xian_tu(yu, qi, fang, chang, ban_kuan, &"LanYuGuiJiGuang", 0.30)
	yu.set_meta(MK_GUI_JI_TU, sp)
	if sp != null:
		# 兜底计时器：玩家中途离场/脚本停止 tick 时，路径视觉也能自己消失
		var ji_shi := Timer.new()
		ji_shi.wait_time = chi + GUI_JI_TU_ZI_HUI_KUAN_XIAN
		ji_shi.one_shot = true
		ji_shi.autostart = true
		ji_shi.timeout.connect(sp.queue_free)
		sp.add_child(ji_shi)


static func _zuo_she_xian_tu(yu, qi: Vector2, fang: Vector2, chang: float, ban_kuan: float,
		ming: StringName, tou_ming: float) -> Sprite2D:
	# 用现有电脉冲帧当光束贴图：横向拉长成射线，纵向压到半宽两倍
	var tu := TE_XIAO.DIAN_MAI_TE_XIAO.get_frame_texture(&"bao", 0)
	if tu == null or yu.get_parent() == null:
		return null
	var sp := Sprite2D.new()
	sp.name = ming
	sp.texture = tu
	sp.global_position = qi + fang * (chang * 0.5)
	sp.rotation = fang.angle()
	sp.scale = Vector2(
			maxf(1.0, chang) / float(maxi(tu.get_width(), 1)),
			maxf(1.0, ban_kuan * 2.0) / float(maxi(tu.get_height(), 1)))
	sp.modulate = Color(0.5, 1.0, 1.0, tou_ming)
	sp.z_index = 6
	var cai := CanvasItemMaterial.new()
	cai.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sp.material = cai
	yu.get_parent().add_child(sp)
	return sp


static func _geng_xin_gui_ji(yu, neng: NengLi, delta: float) -> void:
	# 极光轨迹：路径存续期内每 0.5 秒对线段附近 NPC 直扣 0.1 级
	if not yu.has_meta(MK_GUI_JI_SHENG_YU):
		return
	if float(yu.get_meta(MK_GUI_JI_SHENG_YU, 0.0)) <= 0.0:
		return
	var qi: Vector2 = yu.get_meta(MK_GUI_JI_QI_DIAN, yu.global_position)
	var zhong: Vector2 = yu.get_meta(MK_GUI_JI_ZHONG_DIAN, qi)
	var fang: Vector2 = yu.get_meta(MK_GUI_JI_FANG, Vector2.RIGHT)
	var ban_kuan := float(yu.get_meta(MK_GUI_JI_BAN_KUAN, 0.0))
	var chang := qi.distance_to(zhong)
	var ji_ge := maxf(0.05, neng.dang_zhi(&"nei_bu_leng_que", 1))
	var ji := float(yu.get_meta(MK_GUI_JI_JI_SHI, ji_ge)) - delta
	var shang := neng.dang_zhi(&"shu_zhi", 1)
	while ji <= 0.0:
		ji += ji_ge
		_gui_ji_shang(yu, qi, fang, chang, ban_kuan, shang)
	yu.set_meta(MK_GUI_JI_JI_SHI, ji)


static func _gui_ji_shang(yu, qi: Vector2, fang: Vector2, chang: float, ban_kuan: float, shang: float) -> void:
	# 与主动射线同一套线段判定：穿过路径的都要掉肉
	var ce := Vector2(-fang.y, fang.x)
	for node in yu.get_tree().get_nodes_in_group("yu_npc"):
		var npc := node as YuNpc
		if npc == null or npc.si_le or not is_instance_valid(npc):
			continue
		var cha := npc.global_position - qi
		var qian := cha.dot(fang)
		if qian < 0.0 or qian > chang:
			continue
		if absf(cha.dot(ce)) > ban_kuan:
			continue
		# 契约：无视防御的直伤对首领减半
		npc.shou_zhi_jie_shang(shang * (0.5 if npc.shi_boss else 1.0))


static func _gui_ji_qing_li(yu) -> void:
	# 路径到期/重放/换形态：视觉节点与计时一并清理
	if yu.has_meta(MK_GUI_JI_TU):
		var tu = yu.get_meta(MK_GUI_JI_TU)
		if is_instance_valid(tu):
			tu.queue_free()
		yu.remove_meta(MK_GUI_JI_TU)
	yu.set_meta(MK_GUI_JI_SHENG_YU, 0.0)
	yu.set_meta(MK_GUI_JI_JI_SHI, 0.0)


# ---- 被动 2：星传播散 ----

static func _geng_xin_yun(yu, neng: NengLi, delta: float) -> void:
	# 孢子云：每朵云独立计时，存续期内每 0.5 秒给半径内 NPC 叠毒晕
	var yun_lie: Array = yu.get_meta(MK_YUN_LIE, [])
	if yun_lie.is_empty():
		return
	var ban := neng.dang_zhi(&"ban_jing", 1) * _shen_wei(yu)
	var du := neng.dang_zhi(&"shu_zhi", 1)
	var ji_ge := maxf(0.05, neng.dang_zhi(&"nei_bu_leng_que", 1))
	var xin_lie: Array = []
	for yun_bi in yun_lie:
		var yun: Dictionary = yun_bi
		if bool(yun.get("xin", false)):
			# 刚生成的云：本帧只登记不算时间——主动先 tick、被动后 tick，
			# 同一帧扣两次会让「持续 4 秒」变短
			yun["xin"] = false
			xin_lie.append(yun)
			continue
		yun["sheng_yu"] = float(yun.get("sheng_yu", 0.0)) - delta
		if float(yun["sheng_yu"]) <= 0.0:
			var tu = yun.get("tu")
			if is_instance_valid(tu):
				tu.queue_free()
			continue  # 到期移除
		yun["ji_shi"] = float(yun.get("ji_shi", ji_ge)) - delta
		while float(yun["ji_shi"]) <= 0.0:
			yun["ji_shi"] = float(yun["ji_shi"]) + ji_ge
			_yun_du(yu, yun["wei"], ban, du)
		xin_lie.append(yun)
	yu.set_meta(MK_YUN_LIE, xin_lie)


static func _yun_du(yu, wei: Vector2, ban: float, du: float) -> void:
	for node in yu.get_tree().get_nodes_in_group("yu_npc"):
		var npc := node as YuNpc
		if npc == null or npc.si_le or not is_instance_valid(npc):
			continue
		if wei.distance_to(npc.global_position) <= ban:
			npc.jia_du_yun(du)
