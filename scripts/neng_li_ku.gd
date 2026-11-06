extends RefCounted
class_name NengLiKu
# 能力总表（显式注册表）：导出后 .tres 会变 .remap，DirAccess 列目录不可靠
# 图鉴 / 成就 / 永久开局技能 / 存档按 id 反查都从这里读，不再各自扫目录

const ZHU_DONG: Array[NengLi] = [
	preload("res://data/nengli/chang_mao_chuan_ci.tres"),
	preload("res://data/nengli/dian_mai_chong.tres"),
	preload("res://data/nengli/fang_dian_ma_bi.tres"),
	preload("res://data/nengli/ji_su_tu_jin.tres"),
	preload("res://data/nengli/kuang_bao_si_yao.tres"),
	preload("res://data/nengli/man_li_chong_zhuang.tres"),
	preload("res://data/nengli/ni_liu_shan_bi.tres"),
	preload("res://data/nengli/qian_fu_tu_xi.tres"),
	preload("res://data/nengli/ruo_dian_dong_cha.tres"),
	preload("res://data/nengli/sheng_na_mai_chong.tres"),
	preload("res://data/nengli/xuan_wo.tres"),
	preload("res://data/nengli/xue_xing_kuang_re.tres"),
	preload("res://data/nengli/ying_ke_hu_ti.tres"),
	preload("res://data/nengli/you_er_qi_pao.tres"),
	preload("res://data/nengli/yu_lei_chong_ci.tres"),
	preload("res://data/nengli/yu_ni_dan.tres"),
]

const BEI_DONG: Array[NengLi] = [
	preload("res://data/nengli/bao_shi_lian_suo.tres"),
	preload("res://data/nengli/bei_ci_zhi_jue.tres"),
	preload("res://data/nengli/da_wei_wang.tres"),
	preload("res://data/nengli/dian_gan_shou_qi.tres"),
	preload("res://data/nengli/du_ji_hu_ti.tres"),
	preload("res://data/nengli/du_xian.tres"),
	preload("res://data/nengli/fu_rou_you_er.tres"),
	preload("res://data/nengli/ji_e_nai_shou.tres"),
	preload("res://data/nengli/jue_jing_fan_yao.tres"),
	preload("res://data/nengli/lie_shou_zhi_jue.tres"),
	preload("res://data/nengli/ling_min_wei_qi.tres"),
	preload("res://data/nengli/ruan_lin.tres"),
	preload("res://data/nengli/shen_shang_xian.tres"),
	preload("res://data/nengli/shi_fu_zhe.tres"),
	preload("res://data/nengli/si_lie_chi.tres"),
	preload("res://data/nengli/tan_shi_hui_fu.tres"),
	preload("res://data/nengli/xiu_lin.tres"),
	preload("res://data/nengli/yin_ni_qi_xi.tres"),
	preload("res://data/nengli/ying_lin_fan_ji.tres"),
]


static func quan_bu() -> Array[NengLi]:
	# 图鉴/成就按“主动在前、被动在后”统一顺序展示
	var jie_guo: Array[NengLi] = []
	jie_guo.append_array(ZHU_DONG)
	jie_guo.append_array(BEI_DONG)
	return jie_guo


static func tong_yong_chi() -> Array[NengLi]:
	# 通用池：升级三选一与成就兑换只认这里——带 suoshu_xing_tai 的进化专属技永不流入
	# 专属技由 jin_hua_wei 在进化成对应形态时直接装配，不经过任何随机/兑换通道
	var jie_guo: Array[NengLi] = []
	for neng in quan_bu():
		if neng != null and not neng.shi_zhuan_shu():
			jie_guo.append(neng)
	return jie_guo


static func zhao(bian_hao: StringName) -> NengLi:
	# 按 id 反查资源；查不到返回 null（旧存档/坏档一律由调用方忽略）
	for neng in ZHU_DONG:
		if neng.bian_hao == bian_hao:
			return neng
	for neng in BEI_DONG:
		if neng.bian_hao == bian_hao:
			return neng
	return null
