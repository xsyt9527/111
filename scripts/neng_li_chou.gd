extends RefCounted
class_name NengLiChou
# 升级三选一算法：纯函数 + 注入 RNG，测试可复现（不碰全局 randf / Array.shuffle）
# 规则（档位版）：候选池 = 未满档的能力——
#   主动没装 → 可首次入槽；已装未满档 → 可升档（不再简单排除）；满档主动排除
#   被动未满层保留（叠层）；满层被动排除（选了也无事发生）
# 50% 概率强制放入本局吃得最多的能力（最常吃已满档时自然落空，正常洗牌补满）；不足 3 个就返回全部；0 个返回空（弹窗自动关）

const QIANG_ZHI_GAI_LV := 0.5  # 强制出现「最常吃能力」的概率（用户调参入口）
const SAN_ZHANG := 3  # 每次弹窗给几张
# E2 保底用：进攻向主动技（造成伤害/控制/突进压制）。防御、位移闪避、召唤诱饵不在此列。
# 只用于「首次三选一必含 1 个进攻主动」，不改变常规抽卡概率。
const JIN_GONG_ZHU_DONG: Array[StringName] = [
	&"chang_mao_chuan_ci", &"chao_ya_shui_dao", &"dian_mai_chong", &"fang_dian_ma_bi",
	&"jiu_tou_dian_wang", &"ju_du_tu_ci", &"kong_jian_lie_feng", &"kuang_bao_si_yao",
	&"lei_bao_zhao_huan", &"luo_xuan_zuan_tu", &"man_li_chong_zhuang", &"po_kong_fu_chong",
	&"qian_fu_tu_xi", &"qiang_suan_pen_tu", &"shi_hua_zhi_tong", &"you_ling_qi_she",
	&"yu_lei_chong_ci", &"xuan_wo", &"xue_xing_kuang_re", &"ji_su_tu_jin",
]


static func ke_xuan_chi(quan_bu: Array[NengLi], zhu_dong_dang: Dictionary,
		bei_dong_ceng: Dictionary) -> Array[NengLi]:
	# 候选池：按档位账本过滤——主动查升档表、被动查叠层表（都按 bian_hao 比，不靠对象引用）
	# 全池满档后候选为空：弹窗自动关（不卡暂停），机制自洽
	var jie_guo: Array[NengLi] = []
	for neng in quan_bu:
		if neng == null:
			continue
		if neng.shi_zhuan_shu():
			continue  # 进化专属技：只随对应形态装配，永不参与升级三选一
		if neng.shi_zhu_dong():
			if int(zhu_dong_dang.get(neng.bian_hao, 0)) >= neng.zui_da_dang:
				continue  # 满档主动：升无可升
		else:
			if int(bei_dong_ceng.get(neng.bian_hao, 0)) >= neng.zui_da_dang:
				continue  # 满层被动：叠无可叠
		jie_guo.append(neng)
	return jie_guo


static func shi_fou_qiang_zhi(rng: RandomNumberGenerator) -> bool:
	# 是否触发「最常吃能力必出」：50% 概率
	return rng.randf() < QIANG_ZHI_GAI_LV


static func chou_san_zhang(ke_xuan: Array[NengLi], zui_duo_bian_hao: StringName,
		qiang_zhi: bool, rng: RandomNumberGenerator) -> Array[NengLi]:
	# 抽 3 张：强制项 → 洗剩余 → 补满 → 整体再洗（强制项不会永远第一张）
	var sheng: Array[NengLi] = []
	sheng.assign(ke_xuan)
	if sheng.is_empty():
		return []
	var jie_guo: Array[NengLi] = []
	if qiang_zhi and zui_duo_bian_hao != &"":
		for i in sheng.size():
			if sheng[i].bian_hao == zui_duo_bian_hao:
				jie_guo.append(sheng[i])
				sheng.remove_at(i)
				break
	_xi_pai(sheng, rng)
	while jie_guo.size() < SAN_ZHANG and not sheng.is_empty():
		jie_guo.append(sheng.pop_front())
	_xi_pai(jie_guo, rng)  # 再洗一次：强制项也有机会出现在任意卡位
	return jie_guo


static func you_jin_gong(ke_xuan: Array[NengLi]) -> bool:
	# E2：候选池里有没有进攻主动（一张都没有就别浪费保底）
	for neng in ke_xuan:
		if shi_jin_gong(neng):
			return true
	return false


static func shi_jin_gong(neng: NengLi) -> bool:
	return neng != null and neng.shi_zhu_dong() and JIN_GONG_ZHU_DONG.has(neng.bian_hao)


static func qiang_zhi_jin_gong(jie_guo: Array[NengLi],
		ke_xuan: Array[NengLi]) -> Array[NengLi]:
	# E2 保底：三选一结果里没有进攻主动时，用候选池里的进攻主动替换最后一张
	# 调用方先确认 ke_xuan 里确实有进攻主动，再消费存档里的欠账标记
	var jie_lun: Array[NengLi] = []
	jie_lun.assign(jie_guo)
	for neng in jie_lun:
		if shi_jin_gong(neng):
			return jie_lun
	var ti_huan: NengLi = null
	for neng in ke_xuan:
		if shi_jin_gong(neng) and not jie_lun.has(neng):
			ti_huan = neng
			break
	if ti_huan == null:
		return jie_lun
	if jie_lun.size() >= SAN_ZHANG:
		jie_lun[jie_lun.size() - 1] = ti_huan
	else:
		jie_lun.append(ti_huan)
	return jie_lun


static func _xi_pai(shu_zu: Array[NengLi], rng: RandomNumberGenerator) -> void:
	# Fisher-Yates：从后往前，每次和 [0, i] 的随机位置交换
	# 只认注入的 RNG——测试给固定种子就能复现同一组候选
	for i in range(shu_zu.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var lin_shi: NengLi = shu_zu[i]
		shu_zu[i] = shu_zu[j]
		shu_zu[j] = lin_shi
