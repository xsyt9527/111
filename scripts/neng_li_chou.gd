extends RefCounted
class_name NengLiChou
# 升级三选一算法：纯函数 + 注入 RNG，测试可复现（不碰全局 randf / Array.shuffle）
# 规则（档位版）：候选池 = 未满档的能力——
#   主动没装 → 可首次入槽；已装未满档 → 可升档（不再简单排除）；满档主动排除
#   被动未满层保留（叠层）；满层被动排除（选了也无事发生）
# 50% 概率强制放入本局吃得最多的能力（最常吃已满档时自然落空，正常洗牌补满）；不足 3 个就返回全部；0 个返回空（弹窗自动关）

const QIANG_ZHI_GAI_LV := 0.5  # 强制出现「最常吃能力」的概率（用户调参入口）
const SAN_ZHANG := 3  # 每次弹窗给几张


static func ke_xuan_chi(quan_bu: Array[NengLi], zhu_dong_dang: Dictionary,
		bei_dong_ceng: Dictionary) -> Array[NengLi]:
	# 候选池：按档位账本过滤——主动查升档表、被动查叠层表（都按 bian_hao 比，不靠对象引用）
	# 全池满档后候选为空：弹窗自动关（不卡暂停），机制自洽
	var jie_guo: Array[NengLi] = []
	for neng in quan_bu:
		if neng == null:
			continue
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


static func _xi_pai(shu_zu: Array[NengLi], rng: RandomNumberGenerator) -> void:
	# Fisher-Yates：从后往前，每次和 [0, i] 的随机位置交换
	# 只认注入的 RNG——测试给固定种子就能复现同一组候选
	for i in range(shu_zu.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var lin_shi: NengLi = shu_zu[i]
		shu_zu[i] = shu_zu[j]
		shu_zu[j] = lin_shi
