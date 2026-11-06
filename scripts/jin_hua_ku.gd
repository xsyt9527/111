extends RefCounted
class_name JinHuaKu
# 进化形态总表（显式注册表）：导出后 .tres 会变 .remap，DirAccess 列目录不可靠
# 图鉴「进化」分类、进化 3 选 1、测试按 id 反查都从这里读
# 顺序 = 策划案第十章进化图鉴顺序（1~10 NPC 鱼种，11 玩家凹凸蜗牛鱼）；每组内东方/西方/异化

const QUAN_BU: Array[JinHua] = [
	# 1 大眼金枪鱼
	preload("res://data/jinhua/wen_yao_zhan_wei.tres"),
	preload("res://data/jinhua/hai_shen_xun_yang_ju.tres"),
	preload("res://data/jinhua/qian_yan_lei_po_yu.tres"),
	# 2 灯笼鱼
	preload("res://data/jinhua/you_ming_yin_lu_deng.tres"),
	preload("res://data/jinhua/xing_luo_you_hun.tres"),
	preload("res://data/jinhua/bao_lie_lin_guang_shou.tres"),
	# 3 电鳗（素材包写作「电鳗」）
	preload("res://data/jinhua/lei_yuan_ming_she.tres"),
	preload("res://data/jinhua/lei_ting_hai_de_la.tres"),
	preload("res://data/jinhua/ci_bao_shen_yuan_chong.tres"),
	# 4 剑鱼
	preload("res://data/jinhua/po_lang_du_jiao_jiao.tres"),
	preload("res://data/jinhua/shen_yuan_chuan_ci_zhe.tres"),
	preload("res://data/jinhua/kong_jian_lie_ren_yu.tres"),
	# 5 鲸鲨（二阶段/隐藏 boss 设定保留，实装暂缓）
	preload("res://data/jinhua/bei_ming_ju_kun.tres"),
	preload("res://data/jinhua/yuan_chu_li_wei_tan.tres"),
	preload("res://data/jinhua/xing_kong_tun_xing_shou.tres"),
	# 6 巨口鱼
	preload("res://data/jinhua/tao_tie_tun_hai_shou.tres"),
	preload("res://data/jinhua/shen_yuan_lie_kou_guai.tres"),
	preload("res://data/jinhua/ling_hun_xi_shi_zhe.tres"),
	# 7 旗鱼
	preload("res://data/jinhua/feng_fan_xun_hai_ye_cha.tres"),
	preload("res://data/jinhua/you_ling_hai_dao_fan.tres"),
	preload("res://data/jinhua/lie_kong_fei_yu.tres"),
	# 8 蓑鲉
	preload("res://data/jinhua/jiu_wei_du_yu_yao.tres"),
	preload("res://data/jinhua/mei_du_sha_du_guan.tres"),
	preload("res://data/jinhua/shan_hu_ji_guan_shou.tres"),
	# 9 桶眼鱼（游戏内鱼种叫铜眼鱼）
	preload("res://data/jinhua/bi_yan_guan_xing_shou.tres"),
	preload("res://data/jinhua/shen_yuan_quan_shi_zhi_yan.tres"),
	preload("res://data/jinhua/ji_guang_ju_zhen_yu.tres"),
	# 10 钻光鱼
	preload("res://data/jinhua/shi_xing_ying_huo_chong.tres"),
	preload("res://data/jinhua/zu_zhou_xing_chen_chong.tres"),
	preload("res://data/jinhua/deng_li_zi_chuan_jia_yu.tres"),
	# 11 凹凸蜗牛鱼（玩家默认角色）：三类特殊分支，同样走三选一
	preload("res://data/jinhua/tai_sui_rou_ling_zhi_shou.tres"),
	preload("res://data/jinhua/shen_hai_shi_lai_mu_nv_wang.tres"),
	preload("res://data/jinhua/chao_ya_ning_jiao_pao.tres"),
]


static func quan_bu() -> Array[JinHua]:
	# 图鉴按策划案顺序展示；调用方不要原地排序这个数组
	return QUAN_BU


static func zhao(bian_hao: StringName) -> JinHua:
	# 按 id 反查资源；查不到返回 null（旧存档/坏档一律由调用方忽略）
	for jin_hua in QUAN_BU:
		if jin_hua.bian_hao == bian_hao:
			return jin_hua
	return null


static func wan_jia_fen_zhi(yu_zhong_bian_hao: StringName) -> Array[JinHua]:
	# 当前鱼种的可选分支：33 条全部开放，按 ji_yu_bian_hao 精确过滤
	# 暗影剑鱼没有独立分支，数据里映射到剑鱼组，所以这里也能拿到剑鱼 3 条
	var jie_guo: Array[JinHua] = []
	for jin_hua in QUAN_BU:
		if jin_hua.wan_jia_ke_yong and jin_hua.ji_yu_bian_hao == yu_zhong_bian_hao:
			jie_guo.append(jin_hua)
	return jie_guo


static func an_ji_yu() -> Dictionary:
	# 按基础鱼种分组：ji_yu_bian_hao -> Array[JinHua]（图鉴「一行 = 一条鱼的三分支」用）
	# Dictionary 保留首次插入顺序：分组展示顺序与策划案一致
	var fen_zu := {}
	for jin_hua in QUAN_BU:
		var zu: Array = fen_zu.get(jin_hua.ji_yu_bian_hao, [])
		zu.append(jin_hua)
		fen_zu[jin_hua.ji_yu_bian_hao] = zu
	return fen_zu
