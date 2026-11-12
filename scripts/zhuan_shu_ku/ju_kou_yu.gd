extends RefCounted
# 巨口鱼（ju_kou_yu）专属技模块——3 分支 ×（1 主动 + 1 被动）
# 契约见 docs/专属技模块_开发契约.md：框架按技能 id 分派，本文件只由该鱼种实现者维护
# 东 饕餮吞海兽：饕餮巨吞（主动）/ 钢铁獠牙（被动）
# 西 深渊裂口怪：裂口陷阱（主动）/ 棘刺口内（被动）
# 异化 灵魂吸食者：摄魂（主动）/ 恐惧之口（被动）
# 状态一律走 yu 的 meta；临时视觉节点挂 yu.get_parent()，不往 Yu 加成员

const ZHU_DONG_IDS: Array[StringName] = [&"tao_tie_ju_tun", &"lie_kou_xian_jing", &"she_hun"]
const BEI_DONG_IDS: Array[StringName] = [&"gang_tie_liao_ya", &"ji_ci_kou_nei", &"kong_ju_zhi_kou"]

# meta 键统一 zs_<技能id>_<字段>：同一条玩家节点上多鱼种并存也不会串味
const META_TAO_TIE_SHENG := &"zs_tao_tie_ju_tun_sheng_yu"  # 饕餮窗口剩余秒
const META_TAO_TIE_TU := &"zs_tao_tie_ju_tun_tu"  # 饕餮窗口视觉节点
const META_LIE_KOU_SHENG := &"zs_lie_kou_xian_jing_sheng_yu"  # 裂口陷阱窗口剩余秒
const META_LIE_KOU_MU_BIAO := &"zs_lie_kou_xian_jing_mu_biao"  # 本次已咬住的实例 id 列表
const META_LIE_KOU_TU := &"zs_lie_kou_xian_jing_tu"  # 裂口陷阱视觉节点
const META_GANG_TIE_YAO_QIAN := &"zs_gang_tie_liao_ya_yao_qian"  # 咬前体型快照
const META_JI_CI_JI_SHI := &"zs_ji_ci_kou_nei_ji_shi"  # 棘刺节拍累计秒

const YUAN_DIAN_DUAN := 28  # 视觉圆的线段数（纯表现常量）


static func guan_zhu_dong(bian_hao: StringName) -> bool:
	return ZHU_DONG_IDS.has(bian_hao)


static func zhu_dong_ids() -> Array[StringName]:
	return ZHU_DONG_IDS


static func bei_dong_ids() -> Array[StringName]:
	return BEI_DONG_IDS


static func shi_fang(yu, neng: NengLi, dang: int) -> bool:
	# 主动释放：返回 true 才扣冷却/播音效；false = 空放
	match neng.bian_hao:
		&"tao_tie_ju_tun":
			return _fang_tao_tie(yu, neng, dang)
		&"lie_kou_xian_jing":
			return _fang_lie_kou(yu, neng, dang)
		&"she_hun":
			return _fang_she_hun(yu, neng, dang)
	return false


static func geng_xin(yu, neng: NengLi, delta: float) -> void:
	# 每帧：只对已装备技能调用；用技能 id 分流，主动/被动都可能进来
	match neng.bian_hao:
		&"tao_tie_ju_tun":
			_geng_tao_tie(yu, delta)
		&"lie_kou_xian_jing":
			_geng_lie_kou(yu, neng, delta)
		&"ji_ci_kou_nei":
			_geng_ji_ci(yu, neng, delta)


static func shi_jian(yu, neng: NengLi, jian: StringName, shu_ju: Dictionary) -> bool:
	# 事件钩子：本模块只接咬中事件，永远不吞事件（返回 false 让主流程继续）
	if jian == &"yao_zhong":
		match neng.bian_hao:
			&"gang_tie_liao_ya":
				_yao_zhong_gang_tie(yu, neng, shu_ju)
			&"kong_ju_zhi_kou":
				_yao_zhong_kong_ju(yu, neng, shu_ju)
	return false


static func wen(yu, neng: NengLi, jian: StringName, shu_ju: Dictionary) -> float:
	# 数值查询：没装技能时框架不会调用，这里默认返回 1.0
	match neng.bian_hao:
		&"tao_tie_ju_tun":
			if jian == &"tun_men_kan" and _sheng_yu(yu, META_TAO_TIE_SHENG) > 0.0:
				# 原文「门槛 −0.3 / ×0.8」：等价于有效体型 ×1.3，覆盖 1.1 门槛的 25% 放宽
				return _zhi(neng, &"shu_zhi")
		&"lie_kou_xian_jing":
			if jian == &"su_du_bei" and _sheng_yu(yu, META_LIE_KOU_SHENG) > 0.0:
				var su := _zhi(neng, &"fu_shu_zhi")
				return su if su > 0.0 else 1.0
		&"gang_tie_liao_ya":
			if jian == &"yao_shang_bei":
				_ji_lu_yao_qian(yu, shu_ju)
				return 1.0 + _zhi(neng, &"shu_zhi") / 100.0
	return 1.0


# ---- 主动：饕餮巨吞 ----

static func _fang_tao_tie(yu, neng: NengLi, dang: int) -> bool:
	# 4 秒吞天门窗口：不挑目标，按下即成功
	var chi_xu := _zhi(neng, &"chi_xu", dang)
	yu.set_meta(META_TAO_TIE_SHENG, chi_xu)
	_free_tu(yu, META_TAO_TIE_TU)
	var ban := _shen_wei_jing(yu, 1.0)
	var tu := _shan_quan(yu, META_TAO_TIE_TU, ban, Color(1.0, 0.48, 0.18, 0.26), "JuKouTaoTieQuan")
	if tu != null:
		yu.set_meta(META_TAO_TIE_TU, tu)
	return true


static func _geng_tao_tie(yu, delta: float) -> void:
	var sheng := _sheng_yu(yu, META_TAO_TIE_SHENG)
	if sheng <= 0.0:
		return
	sheng = maxf(0.0, sheng - delta)
	yu.set_meta(META_TAO_TIE_SHENG, sheng)
	# 视觉圈跟着玩家走：窗口内大鱼嘴巴发光的直观提示
	var tu = yu.get_meta(META_TAO_TIE_TU) if yu.has_meta(META_TAO_TIE_TU) else null
	if tu != null and is_instance_valid(tu):
		tu.global_position = yu.global_position
		tu.scale = yu.scale
	if sheng <= 0.0:
		_free_tu(yu, META_TAO_TIE_TU)


# ---- 主动：裂口陷阱 ----

static func _fang_lie_kou(yu, neng: NengLi, dang: int) -> bool:
	# 原地张口 4 秒：没有目标也允许放（原文是原地布陷阱，不是锁定技）
	var chi_xu := _zhi(neng, &"chi_xu", dang)
	yu.set_meta(META_LIE_KOU_SHENG, chi_xu)
	yu.set_meta(META_LIE_KOU_MU_BIAO, [])
	_free_tu(yu, META_LIE_KOU_TU)
	var ban := _ban_jing_shijie(yu, neng, dang)
	var tu := _shan_quan(yu, META_LIE_KOU_TU, ban, Color(0.86, 0.28, 0.36, 0.22), "JuKouLieKouJing")
	if tu != null:
		yu.set_meta(META_LIE_KOU_TU, tu)
	return true


static func _geng_lie_kou(yu, neng: NengLi, delta: float) -> void:
	var sheng := _sheng_yu(yu, META_LIE_KOU_SHENG)
	if sheng <= 0.0:
		return
	sheng = maxf(0.0, sheng - delta)
	yu.set_meta(META_LIE_KOU_SHENG, sheng)
	if sheng <= 0.0:
		_free_tu(yu, META_LIE_KOU_TU)
		return
	var shu: SceneTree = yu.get_tree()
	if shu == null:
		return
	var ban := _ban_jing_shijie(yu, neng, 1)
	var shi := _zhi(neng, &"shu_zhi")  # 束缚时长（2 秒）
	var ji_lu: Array = yu.get_meta(META_LIE_KOU_MU_BIAO, [])
	for node in shu.get_nodes_in_group("yu_npc"):
		var mu := node as YuNpc
		if mu == null or not is_instance_valid(mu) or mu.si_le:
			continue
		var jian := mu.get_instance_id()
		if ji_lu.has(jian):
			continue  # 本次陷阱每条鱼只咬住一次：不被每帧刷新成无限束缚
		if yu.global_position.distance_to(mu.global_position) > ban:
			continue
		if mu.jia_zhuang_tai(&"shu_fu", shi):
			ji_lu.append(jian)  # boss 免疫会返回 false，自然不进记录
			yu.set_meta(META_LIE_KOU_MU_BIAO, ji_lu)


# ---- 主动：摄魂 ----

static func _fang_she_hun(yu, neng: NengLi, dang: int) -> bool:
	# 吸 5 身位内最近的非首领：目标掉体型、玩家回体型 + 固定经验
	var ban := _ban_jing_shijie(yu, neng, dang)
	var mu := _zhao_zui_jin(yu, ban, true)
	if mu == null:
		return false  # 没有可吸目标：空放不扣冷却
	var kou := _zhi(neng, &"shu_zhi", dang)
	var jing := int(round(_zhi(neng, &"fu_shu_zhi", dang)))
	mu.shou_zhi_jie_shang(kou)
	ZhangBen.hui_ti_xing(kou)
	ZhangBen.jia_jing_yan(jing)
	_shan_xi_hun_xian(yu, mu)
	return true


# ---- 被动：钢铁獠牙 ----

static func _ji_lu_yao_qian(yu, shu_ju: Dictionary) -> void:
	# 咬伤倍率查询在扣血之前：趁这一刻记下目标咬前体型，供 yao_zhong 补差
	var mu := shu_ju.get("mu") as YuNpc
	if mu == null or not is_instance_valid(mu) or mu.si_le:
		return
	var biao: Dictionary = yu.get_meta(META_GANG_TIE_YAO_QIAN, {})
	if biao.size() > 128:
		biao.clear()  # 极限兜底：不让快照表随着一局无限增长
	biao[mu.get_instance_id()] = float(mu.tixing)
	yu.set_meta(META_GANG_TIE_YAO_QIAN, biao)


static func _yao_zhong_gang_tie(yu, neng: NengLi, shu_ju: Dictionary) -> void:
	var mu := shu_ju.get("mu") as YuNpc
	if mu == null or not is_instance_valid(mu) or mu.si_le:
		return
	var biao: Dictionary = yu.get_meta(META_GANG_TIE_YAO_QIAN, {})
	var jian := mu.get_instance_id()
	if not biao.has(jian):
		return  # 没有咬前快照（非咬击来源）：不补，避免二次扣血误伤
	var qian := float(biao[jian])
	biao.erase(jian)
	yu.set_meta(META_GANG_TIE_YAO_QIAN, biao)
	var yi_diao := qian - float(mu.tixing)
	var zui_shao := _zhi(neng, &"fu_shu_zhi")  # 每次至少 0.2 级
	if yi_diao + 0.0001 < zui_shao:
		# 只补差额：咬得狠的照原伤害，bite 不够 0.2 的补到 0.2；boss 也照补（掉肉不整吞）
		mu.shou_zhi_jie_shang(zui_shao - yi_diao)


# ---- 被动：棘刺口内 ----

static func _geng_ji_ci(yu, neng: NengLi, delta: float) -> void:
	var jian_ge := _zhi(neng, &"fu_shu_zhi")
	if jian_ge <= 0.0:
		jian_ge = 0.5  # 表里没填时退回设计节拍，保证被动不会静默
	var ji := _sheng_yu(yu, META_JI_CI_JI_SHI) + delta
	while ji >= jian_ge:
		ji -= jian_ge
		_ji_ci_sun_xie(yu, neng)
	yu.set_meta(META_JI_CI_JI_SHI, ji)


static func _ji_ci_sun_xie(yu, neng: NengLi) -> void:
	# 每拍对「被玩家束缚」的目标额外直伤：裂口陷阱记录表 + 全场 shu_fu 状态扫描
	var shu: SceneTree = yu.get_tree()
	if shu == null:
		return
	var mu_biao := {}
	var ji_lu: Array = yu.get_meta(META_LIE_KOU_MU_BIAO, [])
	for jian in ji_lu:
		var dong = instance_from_id(int(jian))
		if dong is YuNpc and is_instance_valid(dong) and not dong.si_le \
				and dong.you_zhuang_tai(&"shu_fu"):
			mu_biao[jian] = dong
	for node in shu.get_nodes_in_group("yu_npc"):
		var mu := node as YuNpc
		if mu == null or not is_instance_valid(mu) or mu.si_le:
			continue
		if mu.you_zhuang_tai(&"shu_fu"):
			mu_biao[mu.get_instance_id()] = mu
	var liang := _zhi(neng, &"shu_zhi")  # 每 0.5 秒 0.1 级，即每秒 0.2
	for jian in mu_biao:
		var mu = mu_biao[jian]
		if is_instance_valid(mu) and not mu.si_le:
			mu.shou_zhi_jie_shang(liang)


# ---- 被动：恐惧之口 ----

static func _yao_zhong_kong_ju(_yu, neng: NengLi, shu_ju: Dictionary) -> void:
	var mu := shu_ju.get("mu") as YuNpc
	if mu == null or not is_instance_valid(mu) or mu.si_le:
		return
	# 恐惧 2 秒：AI 反向逃窜；boss 免疫由 jia_zhuang_tai 内部挡住
	mu.jia_zhuang_tai(&"kong_ju", _zhi(neng, &"shu_zhi"))


# ---- 公共小工具 ----

static func _zhi(neng: NengLi, jian: StringName, dang := 1) -> float:
	# 专属技单档：统一从 NengLi 字段读，档位表留空
	return neng.dang_zhi(jian, dang)


static func _sheng_yu(yu, jian: StringName) -> float:
	return float(yu.get_meta(jian, 0.0))


static func _ban_jing_shijie(yu, neng: NengLi, dang := 1) -> float:
	# ban_jing_shen_wei = true 时把「身位」换算成世界像素；最后统一套体长视觉下限
	var ban := _zhi(neng, &"ban_jing", dang)
	if neng.ban_jing_shen_wei:
		ban *= yu._shen_wei()
	return float(yu.fan_wei_xiu_zheng(ban, 0.5))


static func _shen_wei_jing(yu, bei: float) -> float:
	return yu._shen_wei() * bei


static func _zhao_zui_jin(yu, ban_jing: float, tiao_boss: bool) -> YuNpc:
	# 最近的存活 NPC：摄魂用，boss 跳过
	var shu: SceneTree = yu.get_tree()
	if shu == null:
		return null
	var zui: YuNpc = null
	var zui_ju := INF
	for node in shu.get_nodes_in_group("yu_npc"):
		var mu := node as YuNpc
		if mu == null or not is_instance_valid(mu) or mu.si_le:
			continue
		if tiao_boss and mu.shi_boss:
			continue
		var ju: float = yu.global_position.distance_to(mu.global_position)
		if ju <= ban_jing and ju < zui_ju:
			zui_ju = ju
			zui = mu
	return zui


static func _yuan_polygon(ban_jing: float) -> PackedVector2Array:
	# 圆环多边形：Polygon2D 没有原生圆，用分段近似
	var dian := PackedVector2Array()
	for i in YUAN_DIAN_DUAN:
		var jiao := TAU * float(i) / float(YUAN_DIAN_DUAN)
		dian.append(Vector2(cos(jiao), sin(jiao)) * ban_jing)
	return dian


static func _shan_quan(yu, jian: StringName, ban_jing_shijie: float,
		yan_se: Color, ming: String) -> Node2D:
	# 临时光圈：挂到父场景，不挂玩家本体；半径按玩家当前视觉缩放换算
	var fu: Node = yu.get_parent()
	if fu == null or not yu.is_inside_tree():
		return null
	var gen := Node2D.new()
	gen.name = ming
	var quan := Polygon2D.new()
	var ban_ju := ban_jing_shijie / maxf(yu.scale.x, 0.01)
	quan.polygon = _yuan_polygon(ban_ju)
	quan.color = yan_se
	var cai := CanvasItemMaterial.new()
	cai.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	quan.material = cai
	gen.add_child(quan)
	fu.add_child(gen)
	gen.global_position = yu.global_position
	gen.scale = yu.scale
	gen.z_index = yu.z_index - 1
	return gen


static func _shan_xi_hun_xian(yu, mu: YuNpc) -> void:
	# 摄魂连线：从玩家嘴到目标，0.35 秒淡出；父场景节点自毁
	var fu: Node = yu.get_parent()
	if fu == null or not yu.is_inside_tree() or not is_instance_valid(mu):
		return
	var xian := Line2D.new()
	xian.name = "JuKouSheHunXian"
	xian.width = 5.0
	xian.default_color = Color(0.55, 0.95, 1.0, 0.85)
	xian.add_point(Vector2.ZERO)
	xian.add_point(mu.global_position - yu.global_position)
	fu.add_child(xian)
	xian.global_position = yu.global_position
	xian.z_index = yu.z_index + 1
	var tw := xian.create_tween()
	tw.tween_property(xian, "modulate:a", 0.0, 0.35)
	tw.finished.connect(xian.queue_free)


static func _free_tu(yu, jian: StringName) -> void:
	var tu = yu.get_meta(jian) if yu.has_meta(jian) else null
	if tu != null and is_instance_valid(tu):
		tu.queue_free()
	yu.set_meta(jian, null)
