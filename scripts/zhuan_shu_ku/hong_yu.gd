extends RefCounted
# 铜眼鱼（hong_yu，工程显示名）专属技模块——3 分支 ×（1 主动 + 1 被动）
# H10 实装（2026-11-09）：
#   碧眼观星兽    观星 / 先见之明
#   深渊全视之眼  疯狂光线 / 邪神注视
#   激光矩阵鱼    激光矩阵 / 充能眼
# 契约见 docs/专属技模块_开发契约.md：框架按技能 id 分派，本文件只由该鱼种实现者维护
# 所有持续状态写 yu.get_meta / set_meta，不给 Yu 增加成员；临时视觉节点挂 yu.get_parent()

const ZHU_DONG_IDS: Array[StringName] = [&"guan_xing", &"feng_kuang_guang_xian", &"ji_guang_ju_zhen"]
const BEI_DONG_IDS: Array[StringName] = [&"xian_jian_zhi_ming", &"xie_shen_zhu_shi", &"chong_neng_yan"]

const TE := preload("res://scripts/te_xiao.gd")

# ---- 行为常量（契约允许模块放节拍 / 射线宽度这类表现参数）----
const SHE_XIAN_KUAN_SHEN_WEI := 1.0  # 疯狂光线：宽 1 身位
const JI_GUANG_JIE_PAI := 0.5  # 激光矩阵：每 0.5 秒一跳
const JI_GUANG_SHU_LIANG := 3  # 激光矩阵：最多锁定 3 个目标
const JING_ZHI_SU_DU := 5.0  # 充能眼：当前速度低于 5 像素/秒视为静止
const GUAN_XING_BEI_JI_SHU := 2.0  # 观星感知倍率的兜底（数据缺 shu_zhi 时用）

# ---- meta 键：每个持续状态一个键，避免跨形态串味 ----
const META_GUAN_XING_SHENG := &"zs_guan_xing_sheng_yu"
const META_XIAN_JIAN_SHENG := &"zs_xian_jian_zhi_ming_sheng_yu"
const META_CHONG_NENG_JING_ZHI := &"zs_chong_neng_yan_jing_zhi"
const META_CHONG_NENG_CENG := &"zs_chong_neng_yan_ceng"
const META_JI_GUANG_SHENG := &"zs_ji_guang_ju_zhen_sheng_yu"
const META_JI_GUANG_MU_BIAO := &"zs_ji_guang_ju_zhen_mu_biao"
const META_JI_GUANG_JI_SHI := &"zs_ji_guang_ju_zhen_ji_shi"
const META_JI_GUANG_CI_SHU := &"zs_ji_guang_ju_zhen_ci_shu"
const META_JI_GUANG_XIAN := &"zs_ji_guang_ju_zhen_xian"


static func guan_zhu_dong(bian_hao: StringName) -> bool:
	return ZHU_DONG_IDS.has(bian_hao)


static func zhu_dong_ids() -> Array[StringName]:
	return ZHU_DONG_IDS


static func bei_dong_ids() -> Array[StringName]:
	return BEI_DONG_IDS


static func shi_fang(yu, neng: NengLi, dang: int) -> bool:
	# 主动释放：返回 true 才扣冷却/播音效；false = 空放（条件不足）
	if yu == null or neng == null:
		return false
	match neng.bian_hao:
		&"guan_xing":
			return _shi_fang_guan_xing(yu, neng, dang)
		&"feng_kuang_guang_xian":
			return _shi_fang_feng_kuang(yu, neng, dang)
		&"ji_guang_ju_zhen":
			return _shi_fang_ji_guang(yu, neng, dang)
	return false


static func geng_xin(yu, neng: NengLi, delta: float) -> void:
	# 每帧：只对已装备技能调用（框架已过滤）；主动/被动都可能进来
	if yu == null or neng == null or delta < 0.0:
		return
	if neng.shi_zhu_dong():
		match neng.bian_hao:
			&"guan_xing":
				_geng_xin_guan_xing(yu, delta)
			&"ji_guang_ju_zhen":
				_geng_xin_ji_guang(yu, neng, delta)
	else:
		match neng.bian_hao:
			&"xian_jian_zhi_ming":
				_geng_xin_xian_jian(yu, delta)
			&"chong_neng_yan":
				_geng_xin_chong_neng(yu, neng, delta)


static func shi_jian(yu, neng: NengLi, jian: StringName, shu_ju: Dictionary) -> bool:
	# 事件钩子：返回 true = 事件被吃掉（bei_yao 整口免伤）
	if yu == null or neng == null or neng.shi_zhu_dong():
		return false
	if neng.bian_hao == &"xian_jian_zhi_ming" and jian == &"bei_yao":
		return _xian_jian_chu_fa(yu, neng, shu_ju)
	return false


static func wen(yu, neng: NengLi, jian: StringName, _shu_ju: Dictionary) -> float:
	# 数值查询：返回倍率；没装备时框架直接不调用
	if yu == null or neng == null:
		return 1.0
	if neng.shi_zhu_dong():
		if neng.bian_hao == &"guan_xing":
			# 观星：5s 内 NPC 感知你 ×2.0（本作没有“现形”层，用“更显眼”换算反隐）
			if jian == &"gan_zhi_bei" and _sheng_yu(yu, META_GUAN_XING_SHENG) > 0.0:
				var bei := float(neng.dang_zhi(&"shu_zhi", 1))
				return bei if bei > 0.0 else GUAN_XING_BEI_JI_SHU
			# 原文提到的致命区高亮在伤害侧不额外加成：明确保持 ×1.0
			if jian == &"yao_shang_bei" and _sheng_yu(yu, META_GUAN_XING_SHENG) > 0.0:
				return 1.0
		return 1.0
	match neng.bian_hao:
		&"xian_jian_zhi_ming":
			# 闪避成功后的 1s 咬伤 +20%
			if jian == &"yao_shang_bei" and _sheng_yu(yu, META_XIAN_JIAN_SHENG) > 0.0:
				return 1.0 + maxf(0.0, float(neng.dang_zhi(&"shu_zhi", 1))) / 100.0
		&"xie_shen_zhu_shi":
			# 本作 wen(gan_zhi_bei) 拿不到 NPC：先统一 ×0.7（前方 90° 需要主线补钩子）
			if jian == &"gan_zhi_bei":
				var zhi := float(neng.dang_zhi(&"shu_zhi", 1))
				# 兼容策划按百分比写 70 的情况；本项目约定倍率写 0.7
				if zhi > 1.5:
					zhi /= 100.0
				return zhi
		&"chong_neng_yan":
			# 充能眼：激光每秒 +15%，按层数放大咬伤/激光灼烧
			if jian == &"yao_shang_bei":
				var ceng := _chong_neng_ceng(yu)
				return 1.0 + maxf(0.0, float(neng.dang_zhi(&"shu_zhi", 1))) / 100.0 * float(ceng)
	return 1.0


# ---- 观星 ----

static func _shi_fang_guan_xing(yu, neng: NengLi, dang: int) -> bool:
	# 观星：5s 全屏透视。本作没有“现形”层，语义换算为 NPC 感知你 ×2.0
	yu.set_meta(META_GUAN_XING_SHENG, maxf(0.0, float(neng.dang_zhi(&"chi_xu", dang))))
	# 声呐脉冲放大：表现“视野扫过全场”
	TE.sheng_na(yu.get_parent(), yu.global_position, 2.4)
	return true


static func _geng_xin_guan_xing(yu, delta: float) -> void:
	var sheng := maxf(0.0, _sheng_yu(yu, META_GUAN_XING_SHENG) - delta)
	yu.set_meta(META_GUAN_XING_SHENG, sheng)


# ---- 疯狂光线 ----

static func _shi_fang_feng_kuang(yu, neng: NengLi, dang: int) -> bool:
	# 疯狂光线：沿朝向 6 身位、宽 1 身位的直线，命中第一个 NPC → 疯狂 3s（boss 免疫）
	var fang: Vector2 = yu._chao_xiang_fang()
	var chang: float = yu.fan_wei_xiu_zheng(\
			maxf(0.0, float(neng.dang_zhi(&"ban_jing", dang))) * yu._shen_wei(), 1.5)
	var kuan: float = SHE_XIAN_KUAN_SHEN_WEI * yu._shen_wei()
	var mu := _zhao_she_xian_tou_biao(yu, fang, chang, kuan)
	if mu == null:
		return false  # 无目标：空放不扣冷却
	mu.jia_zhuang_tai(&"feng_kuang", maxf(0.0, float(neng.dang_zhi(&"chi_xu", dang))))
	TE.dian_gan(yu.get_parent(), mu.global_position, 1.0)
	_hua_she_xian(yu, fang, chang, kuan)
	return true  # 命中即消耗冷却；boss 免疫只影响状态本身


static func _zhao_she_xian_tou_biao(yu, fang: Vector2, chang: float, kuan: float) -> YuNpc:
	# 射线命中：前向投影 0~射程，侧向偏移 ≤ 半宽；取投影最近的一个
	var zui_jin: YuNpc = null
	var zui_jin_qian := INF
	for node in yu.get_tree().get_nodes_in_group("yu_npc"):
		var npc := node as YuNpc
		if npc == null or npc.si_le:
			continue
		var cha: Vector2 = npc.global_position - yu.global_position
		var qian := cha.dot(fang)
		if qian < 0.0 or qian > chang:
			continue
		var ce := absf(cha.dot(Vector2(-fang.y, fang.x)))
		if ce > kuan * 0.5:
			continue
		if qian < zui_jin_qian:
			zui_jin_qian = qian
			zui_jin = npc
	return zui_jin


static func _hua_she_xian(yu, fang: Vector2, chang: float, kuan: float) -> void:
	# 一次性射线表现：挂场景层，淡出后自毁
	var gen: Node = yu.get_parent()
	if gen == null or not gen.is_inside_tree():
		return
	var xian := Line2D.new()
	xian.width = maxf(2.0, kuan)
	xian.default_color = Color(1.0, 0.32, 0.78, 0.85)
	xian.z_index = 6
	xian.points = PackedVector2Array([Vector2.ZERO, fang * chang])
	gen.add_child(xian)
	xian.global_position = yu.global_position
	var tw := xian.create_tween()
	tw.tween_property(xian, "modulate:a", 0.0, 0.35)
	tw.finished.connect(xian.queue_free)


# ---- 激光矩阵 ----

static func _shi_fang_ji_guang(yu, neng: NengLi, dang: int) -> bool:
	# 激光矩阵：锁定最近 3 个 NPC，各灼烧 3s，每 0.5s 直扣 0.15 级体型
	var mu_biao := _zhao_zui_jin_npc(yu, JI_GUANG_SHU_LIANG)
	if mu_biao.is_empty():
		return false  # 场上无目标：空放不扣冷却
	_qing_ji_guang_xian(yu)
	var ids: Array = []
	for npc in mu_biao:
		ids.append(npc.get_instance_id())
	var chi := maxf(0.0, float(neng.dang_zhi(&"chi_xu", dang)))
	# 伤害跳数按持续时间/节拍算整：3s / 0.5s = 6 跳（锁定后移动/死亡都不改跳数）
	var ci := int(round(chi / JI_GUANG_JIE_PAI))
	yu.set_meta(META_JI_GUANG_SHENG, chi)
	yu.set_meta(META_JI_GUANG_MU_BIAO, ids)
	yu.set_meta(META_JI_GUANG_JI_SHI, JI_GUANG_JIE_PAI)
	yu.set_meta(META_JI_GUANG_CI_SHU, ci)
	# 三条光束先画出来，geng_xin 里跟随目标位置
	var xian_zu: Array = []
	var gen: Node = yu.get_parent()
	for id_wen in ids:
		var mu = instance_from_id(int(id_wen))
		if mu == null or not (mu is Node2D):
			continue
		var xian := _sheng_cheng_xian(gen, yu.global_position,
				(mu as Node2D).global_position, 4.0, Color(0.35, 1.0, 0.55, 0.9))
		if xian != null:
			xian_zu.append(xian)
	yu.set_meta(META_JI_GUANG_XIAN, xian_zu)
	TE.dian_mai_chong(gen, yu.global_position, 1.1)
	return true


static func _geng_xin_ji_guang(yu, neng: NengLi, delta: float) -> void:
	var sheng := _sheng_yu(yu, META_JI_GUANG_SHENG)
	if sheng <= 0.0:
		return
	sheng = maxf(0.0, sheng - delta)
	yu.set_meta(META_JI_GUANG_SHENG, sheng)
	var ji := float(yu.get_meta(META_JI_GUANG_JI_SHI, JI_GUANG_JIE_PAI)) - delta
	var ci := int(yu.get_meta(META_JI_GUANG_CI_SHU, 0))
	var ids: Array = yu.get_meta(META_JI_GUANG_MU_BIAO, [])
	while ji <= 0.0 and ci > 0:
		ji += JI_GUANG_JIE_PAI
		ci -= 1
		_ji_guang_jie_suan(yu, neng, ids)
	yu.set_meta(META_JI_GUANG_JI_SHI, ji)
	yu.set_meta(META_JI_GUANG_CI_SHU, ci)
	_geng_xin_ji_guang_xian(yu, ids)
	if sheng <= 0.0 or ci <= 0:
		_qing_ji_guang_xian(yu)
		yu.set_meta(META_JI_GUANG_MU_BIAO, [])
		yu.set_meta(META_JI_GUANG_SHENG, 0.0)


static func _ji_guang_jie_suan(yu, neng: NengLi, ids: Array) -> void:
	# 单跳：无视防御直扣，跳过减伤/反甲/记仇；目标死亡或失效则跳过
	var shang := maxf(0.0, float(neng.dang_zhi(&"shu_zhi", 1)))
	# 充能眼层数：模块内互通，同一个 meta 键；按被动每层 +15%
	shang *= 1.0 + _chong_neng_mei_ceng() * float(_chong_neng_ceng(yu))
	for id_wen in ids:
		var mu = instance_from_id(int(id_wen))
		if mu == null or not is_instance_valid(mu) or not (mu is YuNpc):
			continue
		var npc := mu as YuNpc
		if npc.si_le:
			continue
		# 契约：无视防御的直伤对首领减半（状态免疫只挡状态，不挡伤害）
		npc.shou_zhi_jie_shang(shang * (0.5 if npc.shi_boss else 1.0))


static func _geng_xin_ji_guang_xian(yu, ids: Array) -> void:
	# 光束跟随：目标移动不脱靶；目标死亡则熄灭
	var xian_zu: Array = yu.get_meta(META_JI_GUANG_XIAN, [])
	for i in xian_zu.size():
		var xian := xian_zu[i] as Line2D
		if xian == null or not is_instance_valid(xian):
			continue
		var mu = instance_from_id(int(ids[i])) if i < ids.size() else null
		if mu != null and is_instance_valid(mu) and mu is Node2D:
			xian.global_position = yu.global_position
			xian.points = PackedVector2Array([Vector2.ZERO,
					(mu as Node2D).global_position - yu.global_position])
		else:
			xian.modulate.a = 0.0


static func _sheng_cheng_xian(gen: Node, qi: Vector2, zhong: Vector2,
		kuan: float, yan_se: Color) -> Line2D:
	if gen == null or not gen.is_inside_tree():
		return null
	var xian := Line2D.new()
	xian.width = maxf(1.0, kuan)
	xian.default_color = yan_se
	xian.z_index = 6
	xian.points = PackedVector2Array([Vector2.ZERO, zhong - qi])
	gen.add_child(xian)
	xian.global_position = qi
	return xian


static func _qing_ji_guang_xian(yu) -> void:
	# 清掉上一轮光束（重放/到期/切形态）
	var xian_zu: Array = yu.get_meta(META_JI_GUANG_XIAN, [])
	for xian in xian_zu:
		if is_instance_valid(xian):
			xian.queue_free()
	yu.set_meta(META_JI_GUANG_XIAN, [])


static func _zhao_zui_jin_npc(yu, shu_liang: int) -> Array[YuNpc]:
	# 选择排序取最近 N 个（场上 NPC 数量不大，不引入额外依赖）
	var dou: Array[YuNpc] = []
	for node in yu.get_tree().get_nodes_in_group("yu_npc"):
		var npc := node as YuNpc
		if npc == null or npc.si_le:
			continue
		dou.append(npc)
	var jie_guo: Array[YuNpc] = []
	while jie_guo.size() < shu_liang and not dou.is_empty():
		var zui_jin_i := 0
		var zui_jin_ju := INF
		for i in dou.size():
			var ju: float = yu.global_position.distance_squared_to(dou[i].global_position)
			if ju < zui_jin_ju:
				zui_jin_ju = ju
				zui_jin_i = i
		jie_guo.append(dou[zui_jin_i])
		dou.remove_at(zui_jin_i)
	return jie_guo


# ---- 先见之明 ----

static func _xian_jian_chu_fa(yu, neng: NengLi, shu_ju: Dictionary) -> bool:
	# 被咬瞬间：内部 CD 6s 内不重复；侧移 0.5 身位（垂直攻击方向随机一侧），整口免伤
	if yu.nei_bu_leng_que_sheng(neng.bian_hao) > 0.0:
		return false
	var fang := Vector2.RIGHT.rotated(yu.dang_qian_jiao)
	var lai = shu_ju.get("lai_yuan")
	if lai != null and is_instance_valid(lai) and lai is Node2D:
		var cha: Vector2 = yu.global_position - (lai as Node2D).global_position
		if cha.length_squared() > 0.0001:
			fang = cha.normalized()
	var ce := Vector2(-fang.y, fang.x)
	if randf() < 0.5:
		ce = -ce
	var ju: float = maxf(0.0, float(neng.dang_zhi(&"ban_jing", 1))) * yu._shen_wei()
	yu.position += ce * ju
	if yu.has_method("_xian_zhi_zai_di_tu_nei"):
		yu._xian_zhi_zai_di_tu_nei()
	# 闪避成功：1s 内咬伤 +20%
	yu.set_meta(META_XIAN_JIAN_SHENG, maxf(0.0, float(neng.dang_zhi(&"chi_xu", 1))))
	yu._dong_nei_bu_leng_que(neng.bian_hao, neng.nei_bu_leng_que)
	TE.ni_liu(yu.get_parent(), yu.global_position, 0.6)
	return true  # 免掉这一口


static func _geng_xin_xian_jian(yu, delta: float) -> void:
	var sheng := maxf(0.0, _sheng_yu(yu, META_XIAN_JIAN_SHENG) - delta)
	yu.set_meta(META_XIAN_JIAN_SHENG, sheng)


# ---- 充能眼 ----

static func _geng_xin_chong_neng(yu, neng: NengLi, delta: float) -> void:
	# 静止 ≥1s 后，激光每秒 +15%，最多 4 层；移动（速度 ≥5）清零
	var jing := float(yu.get_meta(META_CHONG_NENG_JING_ZHI, 0.0))
	if absf(float(yu.dang_qian_su_du)) < JING_ZHI_SU_DU:
		jing += maxf(0.0, delta)
	else:
		jing = 0.0
	var men := maxf(0.01, float(neng.dang_zhi(&"chi_xu", 1)))
	var zui_da := maxi(1, int(neng.dang_zhi(&"fu_shu_zhi", 1)))
	var ceng := 0
	if jing >= men:
		ceng = mini(zui_da, 1 + int(floor((jing - men) / men)))
	yu.set_meta(META_CHONG_NENG_JING_ZHI, jing)
	yu.set_meta(META_CHONG_NENG_CENG, ceng)


static func _chong_neng_ceng(yu) -> int:
	# 只有当前装着充能眼才认层数：防止跨形态残留
	if ZhangBen.dang_qian_bei_dong_ceng(&"chong_neng_yan") <= 0:
		return 0
	return maxi(0, int(yu.get_meta(META_CHONG_NENG_CENG, 0)))


static func _chong_neng_mei_ceng() -> float:
	# 激光结算需要被动每层数值（主动自己不知道），从账本已装备被动读
	var bei_neng: NengLi = ZhangBen.zhao_bei_dong(&"chong_neng_yan")
	if bei_neng == null:
		return 0.0
	return maxf(0.0, float(bei_neng.dang_zhi(&"shu_zhi", 1))) / 100.0


static func _sheng_yu(yu, jian: StringName) -> float:
	return maxf(0.0, float(yu.get_meta(jian, 0.0)))
