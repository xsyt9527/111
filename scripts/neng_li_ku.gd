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
	# 进化专属主动（2026-11-06，P0：凹凸蜗牛鱼 3 分支）——只在对应形态装配，不入通用池
	preload("res://data/nengli/tai_sui_ge_rou.tres"),
	preload("res://data/nengli/qiang_suan_pen_tu.tres"),
	preload("res://data/nengli/chao_ya_shui_dao.tres"),
	# 进化专属主动（2026-11-08，G T1：电鳗/旗鱼/剑鱼/蓑鲉 4 鱼种 ×3 分支）
	preload("res://data/nengli/lei_bao_zhao_huan.tres"),
	preload("res://data/nengli/jiu_tou_dian_wang.tres"),
	preload("res://data/nengli/ci_chang_hu_bi.tres"),
	preload("res://data/nengli/huan_feng.tres"),
	preload("res://data/nengli/you_ling_qi_she.tres"),
	preload("res://data/nengli/po_kong_fu_chong.tres"),
	preload("res://data/nengli/luo_xuan_zuan_tu.tres"),
	preload("res://data/nengli/ju_du_tu_ci.tres"),
	preload("res://data/nengli/kong_jian_lie_feng.tres"),
	preload("res://data/nengli/kong_que_huan_ying.tres"),
	preload("res://data/nengli/shi_hua_zhi_tong.tres"),
	preload("res://data/nengli/ji_guan_fan_jia.tres"),
	# 进化专属主动（2026-11-09，H 系列 6 鱼种 × 3 分支 = 18 条）
	# 大眼金枪鱼
	preload("res://data/nengli/liu_xing_yue.tres"),
	preload("res://data/nengli/shen_ju_chong_feng.tres"),
	preload("res://data/nengli/qian_yan_qi_she.tres"),
	# 灯笼鱼
	preload("res://data/nengli/gui_huo_yin_lu.tres"),
	preload("res://data/nengli/xing_chen_yin_xing.tres"),
	preload("res://data/nengli/lin_guang_bao_shan.tres"),
	# 鲸鲨
	preload("res://data/nengli/kun_tun_tian_di.tres"),
	preload("res://data/nengli/shen_yuan_xuan_wo.tres"),
	preload("res://data/nengli/tun_xing.tres"),
	# 巨口鱼
	preload("res://data/nengli/tao_tie_ju_tun.tres"),
	preload("res://data/nengli/lie_kou_xian_jing.tres"),
	preload("res://data/nengli/she_hun.tres"),
	# 铜眼鱼
	preload("res://data/nengli/guan_xing.tres"),
	preload("res://data/nengli/feng_kuang_guang_xian.tres"),
	preload("res://data/nengli/ji_guang_ju_zhen.tres"),
	# 钻光鱼
	preload("res://data/nengli/ying_ju_cheng_long.tres"),
	preload("res://data/nengli/zu_zhou_bao_zi.tres"),
	preload("res://data/nengli/deng_li_zi_qi_she.tres"),
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
	# 进化专属被动（2026-11-06，P0：凹凸蜗牛鱼 3 分支）
	preload("res://data/nengli/ning_jiao_tan_fu.tres"),
	preload("res://data/nengli/ji_yin_she_lu.tres"),
	preload("res://data/nengli/xie_ya_ji_dong.tres"),
	# 进化专属被动（2026-11-08，G T1：电鳗/旗鱼/剑鱼/蓑鲉 4 鱼种 ×3 分支）
	preload("res://data/nengli/ming_lei_lin.tres"),
	preload("res://data/nengli/duo_tou_rong_cuo.tres"),
	preload("res://data/nengli/jin_shu_chi_li.tres"),
	preload("res://data/nengli/ye_cha_fan.tres"),
	preload("res://data/nengli/you_ling_chuan_hai.tres"),
	preload("res://data/nengli/hua_xiang_yi.tres"),
	preload("res://data/nengli/po_jia_long_lin.tres"),
	preload("res://data/nengli/wang_ling_gu_qu.tres"),
	preload("res://data/nengli/lie_kong_bu.tres"),
	preload("res://data/nengli/jin_shen_ji_ma.tres"),
	preload("res://data/nengli/she_fa_pen_du.tres"),
	preload("res://data/nengli/gong_sheng_hai_kui.tres"),
	# 进化专属被动（2026-11-09，H 系列 6 鱼种 × 3 分支 = 18 条）
	# 大眼金枪鱼
	preload("res://data/nengli/shun_feng_yi.tres"),
	preload("res://data/nengli/gu_zhi_zhong_jia.tres"),
	preload("res://data/nengli/lei_yan_suo_ding.tres"),
	# 灯笼鱼
	preload("res://data/nengli/you_ming_ti.tres"),
	preload("res://data/nengli/xing_zuo_yu_hui.tres"),
	preload("res://data/nengli/bao_lie_ti_zhi.tres"),
	# 鲸鲨
	preload("res://data/nengli/xian_shan_zhi_bei.tres"),
	preload("res://data/nengli/shen_yuan_zhuang_jia.tres"),
	preload("res://data/nengli/xing_yu_ling_yu.tres"),
	# 巨口鱼
	preload("res://data/nengli/gang_tie_liao_ya.tres"),
	preload("res://data/nengli/ji_ci_kou_nei.tres"),
	preload("res://data/nengli/kong_ju_zhi_kou.tres"),
	# 铜眼鱼
	preload("res://data/nengli/xian_jian_zhi_ming.tres"),
	preload("res://data/nengli/xie_shen_zhu_shi.tres"),
	preload("res://data/nengli/chong_neng_yan.tres"),
	# 钻光鱼
	preload("res://data/nengli/ju_qun.tres"),
	preload("res://data/nengli/xing_chuan_bo_san.tres"),
	preload("res://data/nengli/ji_guang_gui_ji.tres"),
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
