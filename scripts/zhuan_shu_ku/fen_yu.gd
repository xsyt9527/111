extends RefCounted
# 鲸鲨（fen_yu）专属技模块——3 分支 ×（1 主动 + 1 被动）
# 注意：这里只管「玩家选中鲸鲨形态」的专属技；敌方首领鲸鲨的 AI/霸体另在 yu_npc.gd
# 契约见 docs/专属技模块_开发契约.md：框架按技能 id 分派，本文件只由该鱼种实现者维护
# 数值一律从 NengLi 读；玩家持久状态用 meta，不往 Yu 加成员

const TE_XIAO := preload("res://scripts/te_xiao.gd")  # 一次性特效生成器（漩涡/电圈等），与 yu.gd 同款引用

const ZHU_DONG_IDS: Array[StringName] = [
	&"kun_tun_tian_di",
	&"shen_yuan_xuan_wo",
	&"tun_xing",
]
const BEI_DONG_IDS: Array[StringName] = [
	&"xian_shan_zhi_bei",
	&"shen_yuan_zhuang_jia",
	&"xing_yu_ling_yu",
]

# 行为节拍：策划原文写死的演出节奏；CD/持续/半径/倍率仍全部从 NengLi 字段读
const KUN_TUN_QIAN_YAO_MIAO := 2.0  # 鲲吞天地：蓄力 2 秒
const KUN_TUN_SAO_JIAN_GE := 0.5  # 吸水窗口：每 0.5 秒重扫一次目标
const KUN_TUN_XI_SU_SHEN_WEI := 2.5  # 吸水速度：每秒 2.5 身位（3 秒窗口内够到 6 身位边缘）

# 玩家身上的模块状态（meta 键）：换形态/重开时随玩家节点生命周期，不污染 Yu 成员
const META_KUN_QIAN_YAO := &"zs_kun_tun_tian_di_qian_yao"
const META_KUN_XI_SHUI := &"zs_kun_tun_tian_di_xi_shui"
const META_KUN_SAO_JIAN := &"zs_kun_tun_tian_di_sao_jian"
const META_KUN_MU_BIAO := &"zs_kun_tun_tian_di_mu_biao"
const META_XUAN_WO_SHENG_YU := &"zs_shen_yuan_xuan_wo_sheng_yu"
const META_TUN_XING_AN_CHANG := &"zs_tun_xing_an_chang_sheng_yu"

const DENG_LONG_YU_ID := &"ye_deng_long_yu"  # 灯笼鱼：吞星要吸的“发光体”


static func guan_zhu_dong(bian_hao: StringName) -> bool:
	# 这条主动技归不归本模块管：框架 dispatcher 只问这一句
	return ZHU_DONG_IDS.has(bian_hao)


static func zhu_dong_ids() -> Array[StringName]:
	return ZHU_DONG_IDS


static func bei_dong_ids() -> Array[StringName]:
	return BEI_DONG_IDS


static func shi_fang(yu, neng: NengLi, dang: int) -> bool:
	# 主动释放：成功 true（框架只在 true 时才扣冷却/播音效/放虚影）
	match neng.bian_hao:
		&"kun_tun_tian_di":
			return _shi_fang_kun_tun(yu, neng, dang)
		&"shen_yuan_xuan_wo":
			return _shi_fang_xuan_wo(yu, neng, dang)
		&"tun_xing":
			return _shi_fang_tun_xing(yu, neng, dang)
	return false


static func geng_xin(yu, neng: NengLi, delta: float) -> void:
	# 每帧更新：只对「已装备」的本鱼种专属技调用；持续窗口都在这里倒数
	match neng.bian_hao:
		&"kun_tun_tian_di":
			_geng_xin_kun_tun(yu, neng, delta)
		&"shen_yuan_xuan_wo":
			_geng_xin_xuan_wo(yu, neng, delta)
		&"tun_xing":
			_geng_xin_tun_xing(yu, delta)


static func shi_jian(yu, neng: NengLi, jian: StringName, shu_ju: Dictionary) -> bool:
	# 事件钩子：返回 true = 这件事被吃掉；深渊装甲只弹开不免疫，永远返回 false
	if jian == &"bei_yao" and neng.bian_hao == &"shen_yuan_zhuang_jia":
		_bei_yao_shen_yuan_zhuang_jia(yu, neng, shu_ju)
	return false


static func wen(yu, neng: NengLi, jian: StringName, _shu_ju: Dictionary) -> float:
	# 数值查询：返回倍率（默认 1.0 = 不影响）；框架把所有已装备技能的倍率连乘
	match neng.bian_hao:
		&"xian_shan_zhi_bei":
			# 仙山之背：受伤 ×0.7（原案“只掉肉”在本作血量模型下的等效换算）；
			# 原文“吞噬门槛 ×1.5（更难吃别人）”——主流程把本倍率乘在“玩家有效体型”上，
			# 要更难就必须取倒数（1/1.5≈0.667）；直接返回 1.5 会反成更容易吞。
			if jian == &"shou_shang_bei":
				return neng.dang_zhi(&"shu_zhi", 1)
			if jian == &"tun_men_kan":
				var men := neng.dang_zhi(&"fu_shu_zhi", 1)
				return 1.0 / maxf(0.01, men)
		&"shen_yuan_zhuang_jia":
			# 深渊装甲：受伤 ×0.6
			if jian == &"shou_shang_bei":
				return neng.dang_zhi(&"shu_zhi", 1)
		&"xing_yu_ling_yu":
			# 星域领域：吞星后的暗场窗口内速度/咬伤 +20%；亮区受伤 +10%
			if float(yu.get_meta(META_TUN_XING_AN_CHANG, 0.0)) > 0.0:
				if jian == &"su_du_bei" or jian == &"yao_shang_bei":
					return 1.0 + neng.dang_zhi(&"shu_zhi", 1)
			elif jian == &"shou_shang_bei":
				return 1.0 + neng.dang_zhi(&"fu_shu_zhi", 1)
	return 1.0


# ---- 通用小工具（模块内共用，不暴露给主流程）----

static func _shen_wei(yu) -> float:
	# 一「身位」像素：跟玩家当前体型缩放走；拿不到玩家时退回贴图基准 100px
	if yu != null and is_instance_valid(yu) and yu.has_method("_shen_wei"):
		return maxf(0.01, float(yu._shen_wei()))
	return 100.0


static func _ke_chi(npc) -> bool:
	# 可整吞的鱼：有效、未死、非首领（首领只能咬死；吸卷也不整吞）
	if npc == null or not is_instance_valid(npc):
		return false
	var yu_npc := npc as YuNpc
	if yu_npc == null or yu_npc.si_le:
		return false
	# 直取属性而不是 get("shi_boss")：类型明确，也避免字典式读写的隐式转换
	return not yu_npc.shi_boss


static func _ke_la(npc) -> bool:
	# 可拉拽的鱼：有效且未死；首领也拉（但绝不整吞）
	if npc == null or not is_instance_valid(npc):
		return false
	var yu_npc := npc as YuNpc
	return yu_npc != null and not yu_npc.si_le


static func _bo_te_xiao(yu, ming: StringName, wei: Vector2, bi: float) -> void:
	# 特效统一挂到玩家父节点（场景层）：不跟着本体缩放，也不进玩家节点
	if yu == null or not is_instance_valid(yu) or not yu.is_inside_tree():
		return
	var gen = yu.get_parent()
	if gen == null:
		return
	match ming:
		&"xuan_wo":
			TE_XIAO.xuan_wo(gen, wei, bi)
		&"dian_gan":
			TE_XIAO.dian_gan(gen, wei, bi)
		&"ying_ke_hu_ti":
			TE_XIAO.ying_ke_hu_ti(gen, wei, bi)


# ---- 主动 1：鲲吞天地（北冥巨鲲）----

static func _you_kun_mu_biao(yu, ban_ju: float, zui_da_ti: float) -> bool:
	# 空放判定：6 身位内至少要有一条体型 ≤7 的非首领鱼
	if yu == null or not is_instance_valid(yu) or not yu.is_inside_tree():
		return false
	for node in yu.get_tree().get_nodes_in_group("yu_npc"):
		var npc := node as YuNpc
		if not _ke_chi(npc):
			continue
		if npc.tixing > zui_da_ti:
			continue
		if yu.global_position.distance_to(npc.global_position) <= ban_ju:
			return true
	return false


static func _shi_fang_kun_tun(yu, neng: NengLi, dang: int) -> bool:
	# 鲲吞天地：先蓄力 2 秒，再开 3 秒吸水窗口；窗口内每 0.5 秒重扫
	var ban_ju: float = yu.fan_wei_xiu_zheng(\
			neng.dang_zhi(&"ban_jing", dang) * _shen_wei(yu), 0.5)
	var zui_da_ti: float = neng.dang_zhi(&"shu_zhi", dang)
	if not _you_kun_mu_biao(yu, ban_ju, zui_da_ti):
		return false  # 视野内没有能吸的鱼：空放不扣冷却
	yu.set_meta(META_KUN_QIAN_YAO, KUN_TUN_QIAN_YAO_MIAO)
	yu.set_meta(META_KUN_XI_SHUI, 0.0)
	yu.set_meta(META_KUN_SAO_JIAN, KUN_TUN_SAO_JIAN_GE)
	yu.set_meta(META_KUN_MU_BIAO, [])
	_bo_te_xiao(yu, &"dian_gan", yu.global_position, 0.9)
	return true


static func _geng_xin_kun_tun(yu, neng: NengLi, delta: float) -> void:
	if yu == null or not is_instance_valid(yu) or not yu.is_inside_tree():
		return
	var qian := float(yu.get_meta(META_KUN_QIAN_YAO, 0.0))
	var xi := float(yu.get_meta(META_KUN_XI_SHUI, 0.0))
	var ben_ci_kai_chuang := false
	if qian > 0.0:
		qian = maxf(0.0, qian - delta)
		yu.set_meta(META_KUN_QIAN_YAO, qian)
		if qian <= 0.0:
			xi = maxf(0.0, neng.dang_zhi(&"chi_xu", 1))
			yu.set_meta(META_KUN_XI_SHUI, xi)
			yu.set_meta(META_KUN_SAO_JIAN, KUN_TUN_SAO_JIAN_GE)
			_sao_kun_mu_biao(yu, neng)
			_bo_te_xiao(yu, &"xuan_wo", yu.global_position, 1.4)
			ben_ci_kai_chuang = true
	if xi <= 0.0:
		return
	var yong := delta
	if not ben_ci_kai_chuang:
		# 窗口最后一帧只结算剩余的那一点时间，不白送一整帧
		yong = minf(maxf(0.0, delta), xi)
		xi = maxf(0.0, xi - yong)
		yu.set_meta(META_KUN_XI_SHUI, xi)
	if yong <= 0.0:
		return
	var sao := float(yu.get_meta(META_KUN_SAO_JIAN, 0.0))
	if not ben_ci_kai_chuang:
		sao -= yong
	if sao <= 0.0:
		sao = KUN_TUN_SAO_JIAN_GE
		_sao_kun_mu_biao(yu, neng)
	yu.set_meta(META_KUN_SAO_JIAN, sao)
	_la_kun_mu_biao(yu, yong)


static func _sao_kun_mu_biao(yu, neng: NengLi) -> void:
	# 吸水窗口重扫：把 6 身位内、体型 ≤7、非首领的鱼记成 instance_id 列表
	var ban_ju: float = yu.fan_wei_xiu_zheng(neng.dang_zhi(&"ban_jing", 1) * _shen_wei(yu), 0.5)
	var zui_da_ti: float = neng.dang_zhi(&"shu_zhi", 1)
	var ids: Array = []
	for node in yu.get_tree().get_nodes_in_group("yu_npc"):
		var npc := node as YuNpc
		if not _ke_chi(npc):
			continue
		if npc.tixing > zui_da_ti:
			continue
		if yu.global_position.distance_to(npc.global_position) <= ban_ju:
			ids.append(npc.get_instance_id())
	yu.set_meta(META_KUN_MU_BIAO, ids)


static func _la_kun_mu_biao(yu, delta: float) -> void:
	# 逐帧把锁定目标拉向口中；进入 1 身位立刻整吞（无视吞噬门槛）
	var ids = yu.get_meta(META_KUN_MU_BIAO, [])
	if ids == null or ids.is_empty():
		return
	var shen := _shen_wei(yu)
	var su := KUN_TUN_XI_SU_SHEN_WEI * shen * delta
	for jian in ids:
		var npc := instance_from_id(int(jian)) as YuNpc
		if not _ke_chi(npc):
			continue
		var cha: Vector2 = yu.global_position - npc.global_position
		var ju := cha.length()
		if ju <= shen:
			_zheng_tun(yu, npc)
			continue
		# 只拉到「半身位外」就停，下一帧交给整吞判定；避免直接叠到玩家身上
		var bu := minf(su, ju - shen * 0.5)
		npc.global_position += cha.normalized() * bu
		if yu.global_position.distance_to(npc.global_position) <= shen:
			_zheng_tun(yu, npc)


static func _zheng_tun(yu, npc) -> void:
	# 整吞前一帧的统一体检：有效 / 未死 / 非首领 / 方法存在
	if not _ke_chi(npc):
		return
	if not yu.has_method("_chi_diao"):
		return
	yu._chi_diao(npc)


# ---- 主动 2：深渊漩涡（原初利维坦）----

static func _you_xuan_wo_mu_biao(yu, ban_ju: float) -> bool:
	# 空放判定：8 身位内没有任何鱼（首领也算，只是拉不吞）
	if yu == null or not is_instance_valid(yu) or not yu.is_inside_tree():
		return false
	for node in yu.get_tree().get_nodes_in_group("yu_npc"):
		var npc := node as YuNpc
		if not _ke_la(npc):
			continue
		if yu.global_position.distance_to(npc.global_position) <= ban_ju:
			return true
	return false


static func _shi_fang_xuan_wo(yu, neng: NengLi, dang: int) -> bool:
	# 深渊漩涡：5 秒内每帧把 8 身位内所有鱼朝玩家拉 1 身位/秒（首领也拉，但不吞）
	var ban_ju: float = yu.fan_wei_xiu_zheng(\
			neng.dang_zhi(&"ban_jing", dang) * _shen_wei(yu), 0.5)
	if not _you_xuan_wo_mu_biao(yu, ban_ju):
		return false  # 附近没有鱼：空放不扣冷却
	yu.set_meta(META_XUAN_WO_SHENG_YU, maxf(0.0, neng.dang_zhi(&"chi_xu", dang)))
	_bo_te_xiao(yu, &"xuan_wo", yu.global_position, 1.6)
	return true


static func _geng_xin_xuan_wo(yu, neng: NengLi, delta: float) -> void:
	if yu == null or not is_instance_valid(yu) or not yu.is_inside_tree():
		return
	var sheng := float(yu.get_meta(META_XUAN_WO_SHENG_YU, 0.0))
	if sheng <= 0.0:
		return
	# 最后一帧只结算剩余时间：漩涡到点不会多拖一段
	var yong := minf(maxf(0.0, delta), sheng)
	sheng = maxf(0.0, sheng - yong)
	yu.set_meta(META_XUAN_WO_SHENG_YU, sheng)
	if yong <= 0.0:
		return
	var ban_ju: float = yu.fan_wei_xiu_zheng(neng.dang_zhi(&"ban_jing", 1) * _shen_wei(yu), 0.5)
	var su: float = maxf(0.0, neng.dang_zhi(&"shu_zhi", 1)) * _shen_wei(yu) * yong
	for node in yu.get_tree().get_nodes_in_group("yu_npc"):
		var npc := node as YuNpc
		if not _ke_la(npc):
			continue
		var cha: Vector2 = yu.global_position - npc.global_position
		var ju := cha.length()
		if ju <= 0.001 or ju > ban_ju:
			continue
		# 玩家自己不给减速/加速：这里只推 NPC，反方向满速即可维持距离
		npc.global_position += cha.normalized() * minf(su, ju)


# ---- 主动 3：吞星（星空吞星兽）----

static func _shi_lantern(npc) -> bool:
	# 发光体判定：灯笼鱼（鱼种 id 锁定），首领不参与
	if not _ke_chi(npc):
		return false
	var yu_npc := npc as YuNpc
	if yu_npc.yu_zhong == null:
		return false
	return yu_npc.yu_zhong.bian_hao == DENG_LONG_YU_ID


static func _shi_fang_tun_xing(yu, neng: NengLi, dang: int) -> bool:
	# 吞星：吸收全场发光体（灯笼鱼 + 鱼肉块），每处回 0.2 级体型；同时开 5 秒暗场窗口
	var hui_liang: float = maxf(0.0, neng.dang_zhi(&"shu_zhi", dang))
	var mu_biao: Array = []
	if yu != null and is_instance_valid(yu) and yu.is_inside_tree():
		for node in yu.get_tree().get_nodes_in_group("yu_npc"):
			if _shi_lantern(node):
				mu_biao.append(node)
		for node in yu.get_tree().get_nodes_in_group("rou_kuai"):
			if node != null and is_instance_valid(node) and not node.is_queued_for_deletion():
				mu_biao.append(node)
	if mu_biao.is_empty():
		return false  # 场上没有发光体：空放不扣冷却
	for wu in mu_biao:
		# 每处独立回体型：三处 = +0.6（走账本唯一回血入口，不直接改字段）
		ZhangBen.hui_ti_xing(hui_liang)
		if wu is YuNpc:
			var npc := wu as YuNpc
			npc.si_le = true  # 先立死旗：同一帧后续扫描/其它系统不再碰它
			npc.queue_free()
		else:
			wu.queue_free()
	yu.set_meta(META_TUN_XING_AN_CHANG, maxf(0.0, neng.dang_zhi(&"chi_xu", dang)))
	_bo_te_xiao(yu, &"dian_gan", yu.global_position, 1.5)
	return true


static func _geng_xin_tun_xing(yu, delta: float) -> void:
	# 暗场窗口倒数：只给 xing_yu_ling_yu 读，窗口归零即回亮区
	if yu == null or not is_instance_valid(yu) or not yu.is_inside_tree():
		return
	var sheng := float(yu.get_meta(META_TUN_XING_AN_CHANG, 0.0))
	if sheng <= 0.0:
		return
	yu.set_meta(META_TUN_XING_AN_CHANG, maxf(0.0, sheng - maxf(0.0, delta)))


# ---- 被动 1：仙山之背（北冥巨鲲）----
# 数值全部在 wen 钩子里：受伤 ×0.7、吞噬门槛 ×1.5（详见 .tres 字段语义与最终报告）


# ---- 被动 2：深渊装甲（原初利维坦）----

static func _bei_yao_shen_yuan_zhuang_jia(yu, neng: NengLi, shu_ju: Dictionary) -> void:
	# 被咬事件：体型 <5 的鱼咬我，被朝「远离玩家」的方向弹开 1 身位；伤害照常结算（返回 false）
	var lai_yuan = shu_ju.get("lai_yuan")
	if not (lai_yuan is YuNpc):
		return
	var npc := lai_yuan as YuNpc
	if npc == null or npc.si_le:
		return
	var ti_yu: float = neng.dang_zhi(&"fu_shu_zhi", 1)
	if npc.tixing >= ti_yu:
		return
	var cha: Vector2 = npc.global_position - yu.global_position
	var fang := cha.normalized() if cha.length_squared() > 0.001 \
			else Vector2.RIGHT.rotated(randf() * TAU)
	var ju: float = neng.dang_zhi(&"ban_jing", 1) * _shen_wei(yu)
	npc.tui_kai(fang, ju)
	_bo_te_xiao(yu, &"ying_ke_hu_ti", npc.global_position, 0.9)


# ---- 被动 3：星域领域（星空吞星兽）----
# 数值全部在 wen 钩子里：暗场窗口内速度/咬伤 ×1.2；窗口外受伤 ×1.1（详见 .tres 字段语义）
