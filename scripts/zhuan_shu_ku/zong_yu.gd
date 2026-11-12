extends RefCounted
# 大眼金枪鱼（zong_yu）专属技模块——3 分支 ×（1 主动 + 1 被动）
# 契约见 docs/专属技模块_开发契约.md：框架按技能 id 分派，本文件只由该鱼种实现者维护
# 数值一律从 NengLi 读（shu_zhi / chi_xu / ban_jing / npc_shu_zhi / fu_shu_zhi），本文件只留行为常量
# 模块持久状态一律存 yu 的 meta（键统一 zs_<id>_<字段>），不往 Yu 加成员变量

const ZHU_DONG_IDS: Array[StringName] = [
	&"liu_xing_yue",
	&"shen_ju_chong_feng",
	&"qian_yan_qi_she",
]
const BEI_DONG_IDS: Array[StringName] = [
	&"shun_feng_yi",
	&"gu_zhi_zhong_jia",
	&"lei_yan_suo_ding",
]

const TE_XIAO := preload("res://scripts/te_xiao.gd")

# 行为常量（不是数值表：原文固定的节奏 / 判定下限）
const LIU_XING_YAO_MIAO := 1.0       # 流星跃落地后咬伤加成窗口（策划原文固定 1 秒）
const SHEN_JU_SAO_MIAO_BI := 0.6     # 神驹冲锋命中判定的下限半径（身位）
const QIAN_YAN_MU_SHU := 3           # 千眼齐射最多锁几个目标（原文“最近 3 个”）

# meta 键：流星跃
const M_LIU_TIAO := &"zs_liu_xing_yue_tiao_sheng"        # 剩余滑翔秒
const M_LIU_YAO := &"zs_liu_xing_yue_yao_shang_sheng"    # 落地咬伤加成剩余秒
# meta 键：神驹冲锋
const M_SHEN_SHENG := &"zs_shen_ju_chong_feng_sheng_yu"  # 剩余冲刺秒
const M_SHEN_FANG := &"zs_shen_ju_chong_feng_fang"       # 冲刺方向
const M_SHEN_SU := &"zs_shen_ju_chong_feng_su_du"        # 冲刺速度（像素/秒）
const M_SHEN_MING := &"zs_shen_ju_chong_feng_ming_zhong" # 本次冲刺是否已命中
# meta 键：雷眼锁定
const M_LEI_MU := &"zs_lei_yan_suo_ding_mu"              # 锁定目标 instance_id（0=未锁）
const M_LEI_LENG := &"zs_lei_yan_suo_ding_leng_que"      # 重锁冷却剩余秒


static func guan_zhu_dong(bian_hao: StringName) -> bool:
	# 这条主动技归不归本模块管：框架 dispatcher 只问这一句
	return ZHU_DONG_IDS.has(bian_hao)


static func zhu_dong_ids() -> Array[StringName]:
	return ZHU_DONG_IDS


static func bei_dong_ids() -> Array[StringName]:
	return BEI_DONG_IDS


static func shi_fang(yu, neng: NengLi, dang: int) -> bool:
	# 主动释放：返回 true 才扣冷却/播音效/放虚影；false = 空放（条件不足，不扣冷却）
	match neng.bian_hao:
		&"liu_xing_yue":
			return _shi_fang_liu_xing_yue(yu, neng, dang)
		&"shen_ju_chong_feng":
			return _shi_fang_shen_ju_chong_feng(yu, neng, dang)
		&"qian_yan_qi_she":
			return _shi_fang_qian_yan_qi_she(yu, neng, dang)
	return false


static func geng_xin(yu, neng: NengLi, delta: float) -> void:
	# 每帧：只对「已装备」的技能调用；持续窗口/冲刺位移/锁敌节拍都在这里推进
	match neng.bian_hao:
		&"liu_xing_yue":
			_geng_xin_liu_xing_yue(yu, neng, delta)
		&"shen_ju_chong_feng":
			_geng_xin_shen_ju_chong_feng(yu, neng, delta)
		&"lei_yan_suo_ding":
			_geng_xin_lei_yan_suo_ding(yu, neng, delta)


static func shi_jian(yu, neng: NengLi, jian: StringName, shu_ju: Dictionary = {}) -> bool:
	# 事件钩子：骨质重甲只在“被咬”时反伤；不吃掉事件（减伤照常结算）
	if neng.bian_hao != &"gu_zhi_zhong_jia" or jian != &"bei_yao":
		return false
	return _fan_shang_gu_zhi_zhong_jia(yu, neng, shu_ju)


static func wen(yu, neng: NengLi, jian: StringName, shu_ju: Dictionary = {}) -> float:
	# 数值查询：框架把所有已装备技能的返回值连乘；返回 1.0 = 完全不影响
	match neng.bian_hao:
		&"liu_xing_yue":
			return _wen_liu_xing_yue(yu, neng, jian)
		&"shun_feng_yi":
			return _wen_shun_feng_yi(neng, jian)
		&"gu_zhi_zhong_jia":
			return _wen_gu_zhi_zhong_jia(neng, jian)
		&"lei_yan_suo_ding":
			return _wen_lei_yan_suo_ding(yu, neng, jian, shu_ju)
	return 1.0


# ---- 流星跃（wen_yao_zhan_wei）----

static func _shi_fang_liu_xing_yue(yu, neng: NengLi, dang: int) -> bool:
	# 跃出滑翔：起跳即开霸体窗口，到点由 geng_xin 结算落点冲击波
	var chi_xu := maxf(0.1, float(neng.dang_zhi(&"chi_xu", dang)))
	yu.set_meta(M_LIU_TIAO, chi_xu)
	yu.set_meta(M_LIU_YAO, 0.0)
	_kai_wu_di(yu, chi_xu)
	TE_XIAO.ni_liu(yu.get_parent(), yu.global_position, 1.2)
	return true


static func _geng_xin_liu_xing_yue(yu, neng: NengLi, delta: float) -> void:
	# 落地咬伤窗口独立倒计时（滑翔结束后仍继续走）
	var yao := maxf(0.0, float(yu.get_meta(M_LIU_YAO, 0.0)) - delta)
	yu.set_meta(M_LIU_YAO, yao)
	var tiao := float(yu.get_meta(M_LIU_TIAO, 0.0))
	if tiao <= 0.0:
		return
	yu.wudi = true  # 滑翔全程保持：防别的路径提前把 wudi 关掉
	tiao = maxf(0.0, tiao - delta)
	yu.set_meta(M_LIU_TIAO, tiao)
	if tiao > 0.0:
		return
	_luo_di_liu_xing_yue(yu, neng)


static func _luo_di_liu_xing_yue(yu, neng: NengLi) -> void:
	# 落点冲击波：半径内每个 NPC 吃 1 级等效伤害并被顶开；随后给 1 秒咬伤加成
	var dang := _dang_zhu_dong(neng)
	var ban_jing: float = yu.fan_wei_xiu_zheng(_ban_jing_shen_wei(neng, dang, yu), 0.5)
	var shang_hai := maxf(0.0, float(neng.dang_zhi(&"shu_zhi", dang)))
	var tui_ju := maxf(0.0, float(neng.dang_zhi(&"npc_shu_zhi", dang))) * _shen_wei(yu)
	for n in yu.get_tree().get_nodes_in_group("yu_npc"):
		var npc := n as YuNpc
		if not _ke_yong_mu_biao(npc):
			continue
		if yu.global_position.distance_to(npc.global_position) > ban_jing:
			continue
		npc.shou_dao_yao_ji(shang_hai, yu)
		if tui_ju > 0.0 and is_instance_valid(npc) and not npc.si_le:
			var fang: Vector2 = npc.global_position - yu.global_position
			if fang.length_squared() < 0.001:
				fang = Vector2.RIGHT.rotated(randf() * TAU)
			npc.tui_kai(fang.normalized(), tui_ju)
	yu.set_meta(M_LIU_YAO, LIU_XING_YAO_MIAO)
	TE_XIAO.xuan_wo(yu.get_parent(), yu.global_position, 1.5)
	_guan_wu_di(yu)


static func _wen_liu_xing_yue(yu, neng: NengLi, jian: StringName) -> float:
	# 咬伤加成只在落地后的窗口内生效
	if jian != &"yao_shang_bei":
		return 1.0
	if float(yu.get_meta(M_LIU_YAO, 0.0)) <= 0.0:
		return 1.0
	return 1.0 + maxf(0.0, float(neng.dang_zhi(&"fu_shu_zhi", _dang_zhu_dong(neng))) / 100.0)


# ---- 神驹冲锋（hai_shen_xun_yang_ju）----

static func _shi_fang_shen_ju_chong_feng(yu, neng: NengLi, dang: int) -> bool:
	# 直线冲刺：方向/速度/窗口一次性写进 meta，位移与命中扫描交给每帧 geng_xin
	var chi_xu := maxf(0.05, float(neng.dang_zhi(&"chi_xu", dang)))
	var ju_li: float = yu.fan_wei_xiu_zheng(_ban_jing_shen_wei(neng, dang, yu), 1.5)  # ban_jing 语义是冲刺距离（身位）
	var fang: Vector2 = yu._chao_xiang_fang()
	yu.set_meta(M_SHEN_SHENG, chi_xu)
	yu.set_meta(M_SHEN_FANG, fang)
	yu.set_meta(M_SHEN_SU, ju_li / chi_xu)
	yu.set_meta(M_SHEN_MING, false)
	_kai_wu_di(yu, chi_xu)
	TE_XIAO.yu_lei(yu.get_parent(), yu.global_position, 1.1)
	return true


static func _geng_xin_shen_ju_chong_feng(yu, neng: NengLi, delta: float) -> void:
	# 冲刺推进：按本帧线段做“首目标”扫描，撞到就停；窗口用尽自动结束
	var sheng := float(yu.get_meta(M_SHEN_SHENG, 0.0))
	if sheng <= 0.0:
		return
	var bu := minf(delta, sheng)
	var fang: Vector2 = yu.get_meta(M_SHEN_FANG, Vector2.RIGHT)
	var su := float(yu.get_meta(M_SHEN_SU, 0.0))
	var qi: Vector2 = yu.global_position
	var mo: Vector2 = qi + fang * su * bu
	yu.position += fang * su * bu
	yu._xian_zhi_zai_di_tu_nei()
	mo = yu.global_position  # 出界被拉回：线段扫描终点以实际位移为准，避免隔墙命中
	# 线段扫描：本次位移路径上先撞到谁，就停在哪里
	var mu := _sao_miao_shou_mu_biao(yu, qi, mo)
	if mu != null:
		_ming_zhong_shen_ju_chong_feng(yu, neng, mu)
		yu.set_meta(M_SHEN_SHENG, 0.0)
		yu.set_meta(M_SHEN_MING, true)
		_guan_wu_di(yu)
		return
	sheng = maxf(0.0, sheng - bu)
	yu.set_meta(M_SHEN_SHENG, sheng)
	if sheng <= 0.0:
		_guan_wu_di(yu)


static func _ming_zhong_shen_ju_chong_feng(yu, neng: NengLi, mu: YuNpc) -> void:
	# 首目标结算：1.5 级等效伤害 + 1 秒束缚（boss 只吃伤害，jia_zhuang_tai 内部挡状态）
	var dang := _dang_zhu_dong(neng)
	var shang_hai := maxf(0.0, float(neng.dang_zhi(&"shu_zhi", dang)))
	var shu_fu_miao := maxf(0.0, float(neng.dang_zhi(&"fu_shu_zhi", dang)))
	mu.shou_dao_yao_ji(shang_hai, yu)
	if shu_fu_miao > 0.0 and is_instance_valid(mu) and not mu.si_le:
		mu.jia_zhuang_tai(&"shu_fu", shu_fu_miao)
	TE_XIAO.ying_lin(yu.get_parent(), mu.global_position, 1.0)


# ---- 千眼齐射（qian_yan_lei_po_yu）----

static func _shi_fang_qian_yan_qi_she(yu, neng: NengLi, dang: int) -> bool:
	# 复眼电击：最近 3 个不同目标，各吃 0.3 级直伤 + 40% 电麻；一个目标都没有 = 空放
	var ban_jing: float = yu.fan_wei_xiu_zheng(_ban_jing_shen_wei(neng, dang, yu), 0.5)
	var mu_lie := _zhao_zui_jin_mu_biao(yu, ban_jing, QIAN_YAN_MU_SHU)
	if mu_lie.is_empty():
		return false
	var shang_hai := maxf(0.0, float(neng.dang_zhi(&"shu_zhi", dang)))
	var dian_ma := maxf(0.0, float(neng.dang_zhi(&"fu_shu_zhi", dang)))
	for npc in mu_lie:
		if not _ke_yong_mu_biao(npc) or not npc.has_method(&"shou_zhi_jie_shang"):
			continue
		npc.shou_zhi_jie_shang(shang_hai * (0.5 if npc.shi_boss else 1.0))
		if is_instance_valid(npc) and not npc.si_le and npc.has_method(&"jia_dian_ma"):
			npc.jia_dian_ma(dian_ma)
			TE_XIAO.fang_dian(yu.get_parent(), npc.global_position, 0.6)
	return true


# ---- 顺风翼（被动）----

static func _wen_shun_feng_yi(neng: NengLi, jian: StringName) -> float:
	# 游速 +20%；主动冷却 -15%。
	# 契约允许“只对 lei_bie 含 chong_ci 的主动”或“对全部主动”二选一：
	# 现有通用冲刺数据没有打 chong_ci 标签，而主框架数据不许本任务改，故选“全部主动”兜底，
	# 保证被动在文鳐形态（与神驹冲锋不同形态）也能实际生效；报告里已写明这一取舍。
	if jian == &"su_du_bei":
		var su_bei := float(neng.dang_zhi(&"shu_zhi", 1))
		return su_bei if su_bei > 0.0 else 1.0
	if jian == &"leng_que_bei":
		var jian_mian := clampf(float(neng.dang_zhi(&"fu_shu_zhi", 1)) / 100.0, 0.0, 0.9)
		return 1.0 - jian_mian
	return 1.0


# ---- 骨质重甲（被动）----

static func _wen_gu_zhi_zhong_jia(neng: NengLi, jian: StringName) -> float:
	# 受到的掉肉伤害 -25%
	if jian != &"shou_shang_bei":
		return 1.0
	return clampf(float(neng.dang_zhi(&"shu_zhi", 1)), 0.1, 1.0)


static func _fan_shang_gu_zhi_zhong_jia(yu, neng: NengLi, shu_ju: Dictionary) -> bool:
	# 被咬时把该次伤害的 10% 弹回咬击者；只反弹给“有受伤入口且不是自己”的有效来源
	var lai_yuan = shu_ju.get("lai_yuan", null)
	var shang_hai := float(shu_ju.get("shang_hai", 0.0))
	if lai_yuan == null or not is_instance_valid(lai_yuan) or lai_yuan == yu:
		return false
	if not lai_yuan.has_method(&"shou_dao_yao_ji") or shang_hai <= 0.0:
		return false
	var fan_bi := maxf(0.0, float(neng.dang_zhi(&"fu_shu_zhi", 1))) / 100.0
	if fan_bi <= 0.0:
		return false
	lai_yuan.shou_dao_yao_ji(shang_hai * fan_bi, yu)
	var wei: Vector2 = yu.global_position
	if lai_yuan is Node2D:
		wei = (lai_yuan as Node2D).global_position
	TE_XIAO.ying_lin(yu.get_parent(), wei, 0.8)
	return false  # 不吃掉事件：玩家的减伤/扣血照常走完


# ---- 雷眼锁定（被动）----

static func _geng_xin_lei_yan_suo_ding(yu, neng: NengLi, delta: float) -> void:
	# 每帧维护“最远目标”锁：目标失效清锁；换锁后有 1 秒静默期，期内不重锁
	var leng := maxf(0.0, float(yu.get_meta(M_LEI_LENG, 0.0)) - delta)
	yu.set_meta(M_LEI_LENG, leng)
	var suo_id := int(yu.get_meta(M_LEI_MU, 0))
	var suo := _zhao_yi_id(yu, suo_id)
	if suo == null:
		yu.set_meta(M_LEI_MU, 0)
		suo_id = 0
		if leng > 0.0:
			return  # 旧目标刚失效但静默期未过：这 1 秒内保持无锁，不立刻换人
	var zui_yuan := _zhao_zui_yuan_mu_biao(yu)
	if zui_yuan == null:
		return
	var zui_id := int(zui_yuan.get_instance_id())
	if zui_id == suo_id:
		return
	if suo != null and leng > 0.0:
		return  # 旧锁还有效且仍在静默期：新的更远目标先不抢锁
	yu.set_meta(M_LEI_MU, zui_id)
	yu.set_meta(M_LEI_LENG, maxf(0.0, float(neng.dang_zhi(&"fu_shu_zhi", 1))))


static func _wen_lei_yan_suo_ding(yu, neng: NengLi, jian: StringName, shu_ju: Dictionary) -> float:
	# 只对“当前锁定的最远目标”加咬伤；没锁/目标不匹配一律 1.0
	if jian != &"yao_shang_bei":
		return 1.0
	var mu = shu_ju.get("mu", null)
	if mu == null or not is_instance_valid(mu) or not mu is Node:
		return 1.0
	if int((mu as Node).get_instance_id()) != int(yu.get_meta(M_LEI_MU, 0)):
		return 1.0
	return 1.0 + maxf(0.0, float(neng.dang_zhi(&"shu_zhi", 1)) / 100.0)


# ---- 通用小工具 ----

static func _shen_wei(yu) -> float:
	# 一「身位」像素；下限保护：极端缩放下也按 1 像素算，避免除零
	return maxf(0.01, float(yu._shen_wei()))


static func _ban_jing_shen_wei(neng: NengLi, dang: int, yu) -> float:
	# 读 ban_jing；数据标了 ban_jing_shen_wei 就按身位换算（本鱼种三条主动都标了）
	var ban := maxf(0.0, float(neng.dang_zhi(&"ban_jing", dang)))
	if neng.ban_jing_shen_wei:
		return ban * _shen_wei(yu)
	return ban


static func _dang_zhu_dong(neng: NengLi) -> int:
	# 主动当前档位：专属技只有 1 档，装备中读账本，未装备也按 1 兜底
	return maxi(1, ZhangBen.dang_qian_zhu_dong_dang(neng.bian_hao))


static func _ke_yong_mu_biao(npc: YuNpc) -> bool:
	# 有效 NPC：实例有效、在树内、没死；召唤/视觉/伤害都只对有效目标
	return npc != null and is_instance_valid(npc) and npc.is_inside_tree() and not npc.si_le


static func _kai_wu_di(yu, chi_xu: float) -> void:
	# 霸体窗口：wudi 立即开；同时把逆流无敌秒数抬到窗口长度——
	# 玩家受伤入口同时看 wudi 与 _ni_liu_sheng_yu，双保险避免窗口末尾一帧漏挡
	yu.wudi = true
	yu._ni_liu_sheng_yu = maxf(float(yu._ni_liu_sheng_yu), maxf(0.01, chi_xu))


static func _guan_wu_di(yu) -> void:
	# 只在无敌计时器没在跑时清 wudi：别误清受击/进化无敌，也别留下永久无敌
	var ding = yu.get_node_or_null("WudiDingshi")
	if ding != null and float(ding.time_left) > 0.0:
		return
	yu.wudi = false


static func _zhao_zui_jin_mu_biao(yu, ban_jing: float, shu: int) -> Array[YuNpc]:
	# 半径内最近的 shu 个有效 NPC（插入排序，只保留最近的一小撮）
	var jie_guo: Array[YuNpc] = []
	for n in yu.get_tree().get_nodes_in_group("yu_npc"):
		var npc := n as YuNpc
		if not _ke_yong_mu_biao(npc):
			continue
		var ju: float = yu.global_position.distance_to(npc.global_position)
		if ju > ban_jing:
			continue
		var wei := jie_guo.size()
		while wei > 0 and yu.global_position.distance_to(jie_guo[wei - 1].global_position) > ju:
			wei -= 1
		jie_guo.insert(wei, npc)
		if jie_guo.size() > shu:
			jie_guo.pop_back()
	return jie_guo


static func _zhao_zui_yuan_mu_biao(yu) -> YuNpc:
	# 全场最远的有效 NPC（雷眼锁定用）；没有目标返回 null
	var zui: YuNpc = null
	var zui_ju := -1.0
	for n in yu.get_tree().get_nodes_in_group("yu_npc"):
		var npc := n as YuNpc
		if not _ke_yong_mu_biao(npc):
			continue
		var ju: float = yu.global_position.distance_to(npc.global_position)
		if ju > zui_ju:
			zui_ju = ju
			zui = npc
	return zui


static func _zhao_yi_id(yu, id: int) -> YuNpc:
	# 按 instance_id 找回锁定目标：死亡/被释放后返回 null（下一帧重新选最远）
	if id == 0:
		return null
	for n in yu.get_tree().get_nodes_in_group("yu_npc"):
		var npc := n as YuNpc
		if _ke_yong_mu_biao(npc) and int(npc.get_instance_id()) == id:
			return npc
	return null


static func _sao_miao_shou_mu_biao(yu, qi: Vector2, mo: Vector2) -> YuNpc:
	# 线段（本帧冲刺路径）上的首目标：命中半径取咬击圈与 0.6 身位的较大者；
	# 多个目标同时命中时取离起点最近的那个（冲刺“先撞到谁”）
	var ban := maxf(float(yu.yao_ji_ban_jing()), SHEN_JU_SAO_MIAO_BI * _shen_wei(yu))
	var fang := mo - qi
	var chang_kuan := fang.length_squared()
	var zui_t := INF
	var zui: YuNpc = null
	for n in yu.get_tree().get_nodes_in_group("yu_npc"):
		var npc := n as YuNpc
		if not _ke_yong_mu_biao(npc):
			continue
		var cha: Vector2 = npc.global_position - qi
		var t := 0.0 if chang_kuan <= 0.0001 else clampf(cha.dot(fang) / chang_kuan, 0.0, 1.0)
		var dian: Vector2 = qi + fang * t
		if dian.distance_to(npc.global_position) > ban:
			continue
		if t < zui_t:
			zui_t = t
			zui = npc
	return zui
