extends SceneTree
# 数据全键校验测试（TASK-014：能力池 + 坏能力红测 + 鱼种映射 + 三选一抽样）
# TASK-018：新增形态池校验 + 形态数据库红测
# 用例 1 能力池 101 个全过校验（DirAccess 遍历——通用能力池插课 21 个新能力自动被守护）
# 用例 2 红测×3：数值为负的坏能力 + 代码内空 bian_hao + 最大档位越界，校验器必须都抓到
# 用例 3 鱼种表字段校验 + 11 鱼种的能力映射（6 挂载 / 5 不挂载）
# 用例 4 三选一算法（档位版）：满档排除 / 未满档保留（升档）/ 满层被动排除 / 200 轮抽样 / 强制包含 / 不足 3 个 / 0 个 / 50% 概率
# 用例 5 形态池 12 个可玩形态全过校验 + 数值/解锁阈值 + 注册表唯一性 + 红测×5
# 纪律：禁用裸 assert()；不入树实例用完 free()（资源卫生）

const YU_NENG_LI := {
	"lv_yu.tres": &"fang_dian_ma_bi",
	"cheng_yu.tres": &"du_ji_hu_ti",
	"qi_yu.tres": &"ji_su_tu_jin",
	"zong_yu.tres": &"ruo_dian_dong_cha",
	"ju_kou_yu.tres": &"qian_fu_tu_xi",
	"jian_yu.tres": &"chang_mao_chuan_ci",
}  # 鱼种 → 能力映射：这 6 种有能力的鱼，其余 5 种必须为 null（含 Lv.8/9 高级鱼模板——纯数值白板，不挂能力）

var passed := 0  # 通过计数（收卷用）
var failed := 0  # 失败计数（退出码的依据）
var quan_bu_neng_li: Array[NengLi] = []  # 能力池（用例 1 装载，用例 4 复用）


func _initialize() -> void:
	# ---- 用例 1：能力池 101 个全过校验（35 通用 + 66 进化专属）----
	var neng_wen_jian := DirAccess.get_files_at("res://data/nengli")
	var neng_shu := 0  # .tres 实际个数（跳过杂项文件）
	var bian_hao_ji := {}  # 能力 id 查重集合
	for wen_jian in neng_wen_jian:
		if not wen_jian.ends_with(".tres"):
			continue
		neng_shu += 1
		var neng: NengLi = load("res://data/nengli/" + wen_jian)
		assert_guo("能力: " + wen_jian, jiao_yan_neng_li(neng))
		if neng != null:
			bian_hao_ji[neng.bian_hao] = true
			quan_bu_neng_li.append(neng)
	assert_eq(neng_shu, 101, "能力池应恰好 101 个（35 通用/鱼种 + 66 进化专属）")
	assert_eq(bian_hao_ji.size(), 101, "101 个能力的 bian_hao 应互不重复")
	# 图标挂载契约（2026-11-10 更新）：35 个通用能力 + 33 条进化专属主动 = 68 条有图；
	# 33 条进化专属被动的美术尚未交付，暂用纯文字卡面（图标随形态绑定，后续补齐）
	var you_tu_biao := {
		&"ruan_lin": true, &"ling_min_wei_qi": true, &"shen_shang_xian": true,
		&"da_wei_wang": true, &"ji_e_nai_shou": true, &"yin_ni_qi_xi": true,
		&"si_lie_chi": true, &"lie_shou_zhi_jue": true, &"bao_shi_lian_suo": true,
		&"tan_shi_hui_fu": true, &"dian_gan_shou_qi": true, &"ying_lin_fan_ji": true,
		&"xuan_wo": true, &"yu_ni_dan": true, &"sheng_na_mai_chong": true,
		&"yu_lei_chong_ci": true, &"kuang_bao_si_yao": true, &"ni_liu_shan_bi": true,
		&"chang_mao_chuan_ci": true, &"ji_su_tu_jin": true, &"fang_dian_ma_bi": true,
		&"qian_fu_tu_xi": true, &"du_ji_hu_ti": true, &"du_xian": true,
		&"man_li_chong_zhuang": true, &"ruo_dian_dong_cha": true, &"shi_fu_zhe": true,
		&"ying_ke_hu_ti": true, &"dian_mai_chong": true, &"you_er_qi_pao": true,
		&"xue_xing_kuang_re": true, &"bei_ci_zhi_jue": true, &"jue_jing_fan_yao": true,
		&"xiu_lin": true, &"fu_rou_you_er": true,
		# 2026-11-10 P0 第一批：33 条进化专属主动图标接入
		&"chao_ya_shui_dao": true, &"ci_chang_hu_bi": true, &"deng_li_zi_qi_she": true,
		&"feng_kuang_guang_xian": true, &"guan_xing": true, &"gui_huo_yin_lu": true,
		&"huan_feng": true, &"ji_guan_fan_jia": true, &"ji_guang_ju_zhen": true,
		&"jiu_tou_dian_wang": true, &"ju_du_tu_ci": true, &"kong_jian_lie_feng": true,
		&"kong_que_huan_ying": true, &"kun_tun_tian_di": true, &"lei_bao_zhao_huan": true,
		&"lie_kou_xian_jing": true, &"lin_guang_bao_shan": true, &"liu_xing_yue": true,
		&"luo_xuan_zuan_tu": true, &"po_kong_fu_chong": true, &"qian_yan_qi_she": true,
		&"qiang_suan_pen_tu": true, &"she_hun": true, &"shen_ju_chong_feng": true,
		&"shen_yuan_xuan_wo": true, &"shi_hua_zhi_tong": true, &"tai_sui_ge_rou": true,
		&"tao_tie_ju_tun": true, &"tun_xing": true, &"xing_chen_yin_xing": true,
		&"ying_ju_cheng_long": true, &"you_ling_qi_she": true, &"zu_zhou_bao_zi": true,
	}
	var tu_biao_shu := 0
	for neng in quan_bu_neng_li:
		if not you_tu_biao.has(neng.bian_hao):
			continue
		tu_biao_shu += 1
		assert_guo("图标: " + String(neng.bian_hao), "" if neng.tu_biao != null else "缺少 tu_biao")
	assert_eq(tu_biao_shu, 68, "图标应恰好挂到 68 条（35 通用 + 33 进化专属主动）")

	# ---- 用例 2：红测——已知坏数据必须被校验器抓到 ----
	var huai: NengLi = load("res://tests/huai_neng_li.tres")  # 键合法、数值为负
	var huai_jie_guo := jiao_yan_neng_li(huai)
	if huai_jie_guo == "":
		failed += 1
		print("FAIL: 红测失守——坏能力没被校验器抓到（校验器自己才是坏的）")
	else:
		passed += 1
		print("红测命中: 坏能力 → " + huai_jie_guo)
	var cuo_neng := NengLi.new()  # 代码内空 id：模拟将来新增能力时漏填
	cuo_neng.ming_zi = "无 id"
	cuo_neng.lei_xing = NengLi.LeiXing.ZHU_DONG
	cuo_neng.leng_que = 6.0
	cuo_neng.shu_zhi = 1.0
	var cuo_jie_guo := jiao_yan_neng_li(cuo_neng)
	if cuo_jie_guo == "":
		failed += 1
		print("FAIL: 红测失守——空 bian_hao 没被抓到")
	else:
		passed += 1
		print("红测命中: 空 id → " + cuo_jie_guo)
	var huai_dang := NengLi.new()  # 最大档位越界：档位系统的新边界（合法范围 1~9）
	huai_dang.bian_hao = &"huai_dang"
	huai_dang.ming_zi = "坏档位"
	huai_dang.miao_shu = "夹具描述"
	huai_dang.lei_xing = NengLi.LeiXing.BEI_DONG
	huai_dang.shu_zhi = 1.0
	huai_dang.zui_da_dang = 0
	_zou_hong_ce_neng_li(huai_dang, "最大档位为 0")
	var huai_miao := NengLi.new()  # 超长描述：卡片描述区装不下（长度契约的新边界）
	huai_miao.bian_hao = &"huai_miao"
	huai_miao.ming_zi = "坏文案"
	huai_miao.miao_shu = "长".repeat(115)  # 115 字 > 110 上限
	huai_miao.lei_xing = NengLi.LeiXing.BEI_DONG
	huai_miao.shu_zhi = 1.0
	_zou_hong_ce_neng_li(huai_miao, "描述超长 115 字")
	# NengLi 是 Resource 不是 Node——引用计数自管，无需 free()

	# ---- 用例 3：鱼种表字段校验 + 能力映射 ----
	var yu_wen_jian := DirAccess.get_files_at("res://data/yuzhong")
	var yu_shu := 0
	for wen_jian in yu_wen_jian:
		if not wen_jian.ends_with(".tres"):
			continue
		yu_shu += 1
		var yu_zhong: YuZhong = load("res://data/yuzhong/" + wen_jian)
		assert_guo("鱼种: " + wen_jian, jiao_yan_yu_zhong(yu_zhong))
		var qi_wang: StringName = YU_NENG_LI.get(wen_jian, &"")
		if qi_wang == &"":
			assert_eq(1 if yu_zhong.neng_li == null else 0, 1,
					"鱼种 %s 不应挂能力（鲸鲨/路人鱼/Lv.8~9 高级鱼留空）" % wen_jian)
		else:
			assert_eq(1 if yu_zhong.neng_li != null else 0, 1, "鱼种 %s 应挂能力" % wen_jian)
			if yu_zhong.neng_li != null:
				assert_string(String(yu_zhong.neng_li.bian_hao), String(qi_wang),
						"鱼种 %s 的能力映射应为 %s" % [wen_jian, qi_wang])
	assert_eq(yu_shu, 11, "鱼种表应恰好 11 行（6 旧种换皮 + 旗鱼/剑鱼/巨口鱼 + Lv.8/9 高级鱼模板）")

	# Lv.8/9 高级鱼模板：数值是玩法承诺（游速快 + 反应快 + 分值高），逐项锁死；
	# 贴图是占位（顶玩家灯笼鱼/剑鱼现成资源），美术后补只换 tie_tu/dong_hua 两行
	var ye_deng: YuZhong = load("res://data/yuzhong/ye_deng_long_yu.tres")
	var an_ying: YuZhong = load("res://data/yuzhong/an_ying_jian_yu.tres")
	assert_eq(ye_deng.dengji, 8, "野灯笼鱼应为 Lv.8（填补等级空档）")
	assert_eq(an_ying.dengji, 9, "暗影剑鱼应为 Lv.9（填补等级空档）")
	assert_eq(ye_deng.fenzhi, 8, "野灯笼鱼分值 8（高经验回报）")
	assert_eq(an_ying.fenzhi, 10, "暗影剑鱼分值 10（高经验回报）")
	assert_float(ye_deng.sudu_fanwei.x, 170.0, "野灯笼鱼游速下限 170（比剑鱼快）")
	assert_float(ye_deng.sudu_fanwei.y, 220.0, "野灯笼鱼游速上限 220")
	assert_float(an_ying.sudu_fanwei.x, 185.0, "暗影剑鱼游速下限 185（全场最快野生鱼）")
	assert_float(an_ying.sudu_fanwei.y, 240.0, "暗影剑鱼游速上限 240")
	assert_float(ye_deng.fan_ying_shi_jian, 0.5, "野灯笼鱼反应 0.5 秒（反应快）")
	assert_float(an_ying.fan_ying_shi_jian, 0.4, "暗影剑鱼反应 0.4 秒（反应快）")
	assert_eq(1 if ye_deng.neng_li == null else 0, 1, "野灯笼鱼是纯数值白板：不挂能力")
	assert_eq(1 if an_ying.neng_li == null else 0, 1, "暗影剑鱼是纯数值白板：不挂能力")
	assert_eq(1 if ye_deng.shi_boss else 0, 0, "野灯笼鱼非首领（普通鱼群刷新）")
	assert_eq(1 if an_ying.shi_boss else 0, 0, "暗影剑鱼非首领（普通鱼群刷新）")
	assert_eq(1 if ye_deng.gong_ji_yu_wang else 0, 1, "野灯笼鱼有攻击欲望（主动咬玩家）")
	assert_eq(1 if an_ying.gong_ji_yu_wang else 0, 1, "暗影剑鱼有攻击欲望（主动咬玩家）")

	# 五鱼攻击帧（6 个鱼种共用 5 套 gong 动画）：咬中时临时替换游动帧，播完切回 you
	var gong_yu := {
		"jian_yu.tres": "jian_yu_gong",
		"an_ying_jian_yu.tres": "jian_yu_gong",
		"qi_yu.tres": "qi_yu_gong",
		"cheng_yu.tres": "shi_zi_yu_gong",
		"lv_yu.tres": "dian_yao_gong",
		"ju_kou_yu.tres": "ju_kou_yu_gong",
	}
	for wen_jian in gong_yu:
		var yz: YuZhong = load("res://data/yuzhong/" + wen_jian)
		assert_eq(1 if yz.gong_ji_dong_hua != null else 0, 1, "鱼种 %s 已接攻击动画" % wen_jian)
		if yz.gong_ji_dong_hua != null:
			assert_eq(1 if yz.gong_ji_dong_hua.has_animation(&"gong") else 0, 1,
					"鱼种 %s 攻击动画名为 gong" % wen_jian)
			assert_eq(yz.gong_ji_dong_hua.get_frame_count(&"gong"), 4, "鱼种 %s 攻击动画 4 帧" % wen_jian)
			assert_eq(1 if yz.gong_ji_dong_hua.get_frame_texture(&"gong", 0) != null else 0, 1,
					"鱼种 %s 攻击帧有贴图" % wen_jian)
	assert_eq(1 if ye_deng.gong_ji_dong_hua == null else 0, 1, "未配攻击帧的鱼种保持 null（回退游动帧）")
	assert_eq(NengLiKu.quan_bu().size(), 101, "能力总表 101 个（49 主动 + 52 被动：含 66 进化专属）")
	assert_eq(NengLiKu.tong_yong_chi().size(), 35, "通用池仍是 35 个：专属技永不流入三选一/成就")
	var zhu_dong_shu := 0
	var bei_dong_shu := 0
	var zhuan_shu_shu := 0
	for neng in NengLiKu.quan_bu():
		if neng.shi_zhu_dong():
			zhu_dong_shu += 1
		else:
			bei_dong_shu += 1
		if neng.shi_zhuan_shu():
			zhuan_shu_shu += 1
	assert_eq(zhu_dong_shu, 49, "主动能力 49 个（16 通用 + 33 专属）")
	assert_eq(bei_dong_shu, 52, "被动能力 52 个（19 通用 + 33 专属）")
	assert_eq(zhuan_shu_shu, 66, "进化专属能力 66 条（P0 6 + T1 24 + H 系列 36）")

	# ---- 用例 4：三选一算法（注入固定种子，可复现；档位版规则）----
	# 候选池 = 未满档能力：满档主动排除、未满档主动保留（可升档）、满层被动排除、未满层被动保留
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261030
	var quan_bu: Array[NengLi] = NengLiChou.ke_xuan_chi(quan_bu_neng_li, {}, {})
	assert_eq(quan_bu.size(), 35, "无装备时候选池 35 个（16 主动 + 19 被动；66 专属被过滤）")
	# 进化专属：带归属形态、永不进三选一（P0 6 条 + G T1 24 条 + H 系列 36 条）
	var zhuan_shu_id := [&"tai_sui_ge_rou", &"ning_jiao_tan_fu", &"qiang_suan_pen_tu",
			&"ji_yin_she_lu", &"chao_ya_shui_dao", &"xie_ya_ji_dong",
			&"lei_bao_zhao_huan", &"ming_lei_lin", &"jiu_tou_dian_wang", &"duo_tou_rong_cuo",
			&"ci_chang_hu_bi", &"jin_shu_chi_li", &"huan_feng", &"ye_cha_fan",
			&"you_ling_qi_she", &"you_ling_chuan_hai", &"po_kong_fu_chong", &"hua_xiang_yi",
			&"luo_xuan_zuan_tu", &"po_jia_long_lin", &"ju_du_tu_ci", &"wang_ling_gu_qu",
			&"kong_jian_lie_feng", &"lie_kong_bu", &"kong_que_huan_ying", &"jin_shen_ji_ma",
			&"shi_hua_zhi_tong", &"she_fa_pen_du", &"ji_guan_fan_jia", &"gong_sheng_hai_kui",
			# H 系列（2026-11-09）：大眼金枪鱼
			&"liu_xing_yue", &"shun_feng_yi", &"shen_ju_chong_feng", &"gu_zhi_zhong_jia",
			&"qian_yan_qi_she", &"lei_yan_suo_ding",
			# 灯笼鱼
			&"gui_huo_yin_lu", &"you_ming_ti", &"xing_chen_yin_xing", &"xing_zuo_yu_hui",
			&"lin_guang_bao_shan", &"bao_lie_ti_zhi",
			# 鲸鲨
			&"kun_tun_tian_di", &"xian_shan_zhi_bei", &"shen_yuan_xuan_wo", &"shen_yuan_zhuang_jia",
			&"tun_xing", &"xing_yu_ling_yu",
			# 巨口鱼
			&"tao_tie_ju_tun", &"gang_tie_liao_ya", &"lie_kou_xian_jing", &"ji_ci_kou_nei",
			&"she_hun", &"kong_ju_zhi_kou",
			# 铜眼鱼
			&"guan_xing", &"xian_jian_zhi_ming", &"feng_kuang_guang_xian", &"xie_shen_zhu_shi",
			&"ji_guang_ju_zhen", &"chong_neng_yan",
			# 钻光鱼
			&"ying_ju_cheng_long", &"ju_qun", &"zu_zhou_bao_zi", &"xing_chuan_bo_san",
			&"deng_li_zi_qi_she", &"ji_guang_gui_ji"]
	assert_eq(zhuan_shu_id.size(), 66, "专属能力 id 清单应补全 66 条")
	for id in zhuan_shu_id:
		var zhuan := NengLiKu.zhao(id)
		assert_eq(1 if zhuan != null else 0, 1, "专属能力必须注册: " + String(id))
		if zhuan != null:
			assert_eq(1 if zhuan.shi_zhuan_shu() else 0, 1, "专属能力必须带归属形态: " + String(id))
			assert_eq(1 if zhuan.suoshu_xing_tai != &"" else 0, 1, "专属归属不能为空: " + String(id))
			assert_eq(zhuan.zui_da_dang, 1, "专属技单档不可升级: " + String(id))
	assert_eq(quan_bu.size(), 35, "专属技不参与三选一（候选池不因新增 66 条而变大）")
	# 满档排除：放电麻痹 1 档即满——装上就从候选池消失
	var fang_dian := _zhao_neng(&"fang_dian_ma_bi")
	var ke_xuan := NengLiChou.ke_xuan_chi(quan_bu, {&"fang_dian_ma_bi": 1}, {})
	assert_eq(ke_xuan.size(), 34, "装满档主动（放电 1/1 档）后候选池剩 34")
	var han_dian := false
	for neng in ke_xuan:
		if neng.bian_hao == &"fang_dian_ma_bi":
			han_dian = true
	assert_eq(1 if han_dian else 0, 0, "候选池不应包含满档主动")
	# 升档保留：漩涡 3 档上限——1 档未满仍在候选池，抽中即升档（不再简单排除）
	var ke_sheng := NengLiChou.ke_xuan_chi(quan_bu, {&"xuan_wo": 1}, {})
	assert_eq(ke_sheng.size(), 35, "装未满档主动（漩涡 1/3 档）不再排除：候选池仍 35 个")
	var han_wo := false
	for neng in ke_sheng:
		if neng.bian_hao == &"xuan_wo":
			han_wo = true
	assert_eq(1 if han_wo else 0, 1, "未满档主动应留在候选池（可升档）")
	assert_eq(NengLiChou.ke_xuan_chi(quan_bu, {&"xuan_wo": 3}, {}).size(), 34, "漩涡 3/3 满档：升无可升被排除")
	# 被动层门：毒棘满层排除，未满层保留
	assert_eq(NengLiChou.ke_xuan_chi(quan_bu, {}, {&"du_ji_hu_ti": 3}).size(), 34, "毒棘 3/3 满层：候选池剩 34")
	assert_eq(NengLiChou.ke_xuan_chi(quan_bu, {}, {&"du_ji_hu_ti": 2}).size(), 35, "毒棘 2/3 未满层：仍在候选池可叠层")
	# 4 个旧主动全部 1 档即满：装满只排除这 4 个——新主动还能入槽、被动还能叠层
	var quan_zhuang_chi := NengLiChou.ke_xuan_chi(quan_bu,
			{&"fang_dian_ma_bi": 1, &"ji_su_tu_jin": 1, &"man_li_chong_zhuang": 1, &"qian_fu_tu_xi": 1}, {})
	assert_eq(quan_zhuang_chi.size(), 31, "4 旧主动全满档：剩 31（12 新主动 + 19 被动，三选一不枯竭）")
	assert_eq(NengLiChou.chou_san_zhang(quan_zhuang_chi, &"", false, rng).size(), 3, "31 个候选时抽牌给满 3 张")

	# 200 轮：恰 3 张、互不重复、每张都露过面
	var wei_gui := 0
	var chu_xian := {}
	for _lun in 200:
		var san := NengLiChou.chou_san_zhang(quan_bu, &"", false, rng)
		if san.size() != 3:
			wei_gui += 1
		var ben_lun := {}
		for neng in san:
			ben_lun[neng.bian_hao] = true
			chu_xian[neng.bian_hao] = true
		if ben_lun.size() != 3:
			wei_gui += 1
	assert_eq(wei_gui, 0, "200 轮抽样每轮应恰 3 张且互不重复")
	assert_eq(chu_xian.size(), 35, "200 轮后每个能力都该出现过（随机性覆盖）")

	# 强制包含：35 个通用 id 逐个测
	for neng in quan_bu:
		var san := NengLiChou.chou_san_zhang(quan_bu, neng.bian_hao, true, rng)
		var zhao_dao := false
		for xuan in san:
			if xuan.bian_hao == neng.bian_hao:
				zhao_dao = true
		assert_eq(1 if zhao_dao else 0, 1, "强制包含 %s" % neng.bian_hao)

	# 强制抽也不会把满档主动塞回来（锁定 id 已被排除出候选池 → 落空后正常洗牌补满）
	var pai_chu_chi := NengLiChou.ke_xuan_chi(quan_bu, {&"fang_dian_ma_bi": 1}, {})
	var san_pai := NengLiChou.chou_san_zhang(pai_chu_chi, &"fang_dian_ma_bi", true, rng)
	assert_eq(san_pai.size(), 3, "锁定 id 不在候选池（满档被排除）时正常补满 3 张")
	var you_dian := false
	for xuan in san_pai:
		if xuan.bian_hao == &"fang_dian_ma_bi":
			you_dian = true
	assert_eq(1 if you_dian else 0, 0, "强制抽也不会把已装备主动塞回来")

	# 不足 3 个 / 0 个
	var liang: Array[NengLi] = []
	liang.append(quan_bu_neng_li[0])
	liang.append(quan_bu_neng_li[1])
	assert_eq(NengLiChou.chou_san_zhang(liang, &"", false, rng).size(), 2, "池只有 2 个时返回 2 个")
	var kong: Array[NengLi] = []
	assert_eq(NengLiChou.chou_san_zhang(kong, &"", false, rng).size(), 0, "空池返回空（弹窗自动关）")

	# 50% 概率：1000 轮命中 400~600
	var ming_zhong := 0
	for _lun in 1000:
		if NengLiChou.shi_fou_qiang_zhi(rng):
			ming_zhong += 1
	assert_eq(1 if ming_zhong >= 400 and ming_zhong <= 600 else 0, 1,
			"50%% 概率 1000 轮应在 400~600 次（实际 %d）" % ming_zhong)

	# ---- 用例 5：形态池——玩家 + 10 NPC 鱼 + 鲸鲨（2026-11-04 选择角色扩展）----
	# data/xingtai 下仍保留 2 个旧形态文件（deng_long_yu/dian_yao），只作历史数据，不进注册表
	var xing_tai_wen_jian := DirAccess.get_files_at("res://data/xingtai")
	var xing_tai_shu := 0
	var xing_tai_ji := {}  # 形态 id 查重集合
	for wen_jian in xing_tai_wen_jian:
		if not wen_jian.ends_with(".tres"):
			continue
		xing_tai_shu += 1
		var xing_tai: XingTai = load("res://data/xingtai/" + wen_jian)
		assert_guo("形态: " + wen_jian, jiao_yan_xing_tai(xing_tai))
		if xing_tai != null:
			assert_eq(0 if xing_tai_ji.has(xing_tai.bian_hao) else 1, 1,
					"形态 bian_hao 重复: " + String(xing_tai.bian_hao))
			xing_tai_ji[xing_tai.bian_hao] = true
			assert_eq(1 if xing_tai.dong_hua != null and xing_tai.dong_hua.has_animation(&"you") else 0,
					1, "形态 %s 必须有 \"you\" 动画" % wen_jian)
	assert_eq(xing_tai_shu, 14, "形态资源 14 个都能加载（12 可玩 + 2 个旧形态历史数据）")
	assert_eq(xing_tai_ji.size(), 14, "14 个形态的 bian_hao 应互不重复")

	# 每个可玩形态都必须能对上进化注册表的一组 3 条（暗影剑鱼在形态侧映射到 jian_yu）
	for wen_jian in xing_tai_wen_jian:
		if not wen_jian.ends_with(".tres"):
			continue
		var xt: XingTai = load("res://data/xingtai/" + wen_jian)
		if xt == null or xt.bian_hao in [&"deng_long_yu", &"dian_yao"]:
			continue
		var yu_id := xt.yu_zhong_bian_hao()
		assert_eq(1 if yu_id != &"" else 0, 1, "形态鱼种 id 不能为空: " + wen_jian)
		assert_eq(JinHuaKu.wan_jia_fen_zhi(yu_id).size(), 3,
				"可玩形态必须对应 3 条进化分支: %s -> %s" % [wen_jian, String(yu_id)])

	# 默认主角：凹凸蜗牛鱼——数值是玩法承诺，逐项锁死
	var wo_niu: XingTai = load("res://data/xingtai/ao_tu_wo_niu_yu.tres")
	assert_string(String(wo_niu.bian_hao), "ao_tu_wo_niu_yu", "主角形态 id 固定为 ao_tu_wo_niu_yu")
	assert_eq(wo_niu.jie_suo_sheng_li_ci_shu, 0, "蜗牛鱼 0 胜解锁：默认角色开局即可选")
	assert_eq(wo_niu.pai_xu, 0, "蜗牛鱼排在选角页第一位")
	assert_eq(wo_niu.kai_ju_deng_ji, 1, "蜗牛鱼开局 Lv.1（统一开局等级）")
	assert_float(wo_niu.yi_dong_su_du, 300.0, "蜗牛鱼速度 300")
	assert_float(wo_niu.zui_ba, 1.0, "蜗牛鱼嘴巴 1.0")
	assert_float(wo_niu.zhuan_xiang_ji_su, 7.0, "蜗牛鱼转向 7.0")
	assert_eq(1 if wo_niu.kai_ju_neng_li == null else 0, 1, "蜗牛鱼无初始能力")
	assert_eq(1 if wo_niu.tie_tu != null else 0, 1, "主角有选择页预览贴图")
	assert_eq(1 if wo_niu.dong_hua != null and wo_niu.dong_hua.get_frame_count(&"you") == 4 else 0,
			1, "主角游动动画 4 帧")

	# 玩家形态注册表：12 个全开（CunDang 是 Autoload，--script 模式不加载，读脚本常量）
	var cun_dang_lei = load("res://scripts/cun_dang.gd")
	assert_eq(1 if cun_dang_lei != null else 0, 1, "CunDang 脚本必须可加载")
	if cun_dang_lei != null:
		var chang_liang: Dictionary = cun_dang_lei.get_script_constant_map()
		var zhu_ce: Array = chang_liang.get("XING_TAI_ZU", [])
		assert_eq(zhu_ce.size(), 12, "形态注册表 12 个：玩家 + 10 NPC 鱼 + 鲸鲨")
		assert_string(String(zhu_ce[0].bian_hao) if zhu_ce.size() > 0 else "",
				"ao_tu_wo_niu_yu", "注册表第一位是蜗牛鱼")
		assert_string(String(chang_liang.get("MO_REN_BIAN_HAO", &"")),
				"ao_tu_wo_niu_yu", "默认形态是蜗牛鱼")
		var zhu_ce_id_ji := {}
		for xt in zhu_ce:
			assert_eq(0 if zhu_ce_id_ji.has(xt.bian_hao) else 1, 1,
					"注册表形态 id 重复: " + String(xt.bian_hao))
			zhu_ce_id_ji[xt.bian_hao] = true
			assert_eq(0 if xt.bian_hao in [&"deng_long_yu", &"dian_yao"] else 1, 1,
					"旧形态不再是玩家选项: " + String(xt.bian_hao))
		assert_eq(zhu_ce_id_ji.size(), 12, "注册表 12 个形态 id 应互不重复")

	# ---- 用例 5 红测：坏形态必须被校验器抓到（红测失守 = 校验器自己坏了）----
	var huai_xing_tai: XingTai = load("res://tests/huai_xing_tai.tres")  # 负速度夹具
	var huai_xing_jie_guo := jiao_yan_xing_tai(huai_xing_tai)
	if huai_xing_jie_guo == "":
		failed += 1
		print("FAIL: 红测失守——负速度坏形态没被校验器抓到")
	else:
		passed += 1
		print("红测命中: 坏形态 → " + huai_xing_jie_guo)
	var kong_id := wo_niu.duplicate() as XingTai
	kong_id.bian_hao = &""
	_zou_hong_ce_xing_tai(kong_id, "空 bian_hao")
	var fu_su_du := wo_niu.duplicate() as XingTai
	fu_su_du.yi_dong_su_du = -1.0
	_zou_hong_ce_xing_tai(fu_su_du, "负移动速度")
	var wu_dong_hua := wo_niu.duplicate() as XingTai
	wu_dong_hua.dong_hua = null
	_zou_hong_ce_xing_tai(wu_dong_hua, "缺动画")
	var bei_dong := wo_niu.duplicate() as XingTai
	bei_dong.kai_ju_neng_li = load("res://data/nengli/du_ji_hu_ti.tres")
	_zou_hong_ce_xing_tai(bei_dong, "初始能力为被动")
	assert_string(String(ProjectSettings.get_setting("autoload/CunDang", "")),
			"*res://scripts/cun_dang.gd", "CunDang 必须注册为 Autoload")
	assert_string(String(ProjectSettings.get_setting("application/run/main_scene", "")),
			"res://scenes/ZhuJieMian.tscn", "启动主场景必须是主界面")
	# 音效管理器注册检查：只查 ProjectSettings（本测试是 --script 模式，
	# 编译期引用 YinXiang 会炸——音效表内容断言在场景模式的 ce_panding 里做）
	assert_string(String(ProjectSettings.get_setting("autoload/YinXiang", "")),
			"*res://scripts/yin_xiang.gd", "YinXiang 必须注册为 Autoload")

	# ---- 用例 6：装饰气泡资源契约（qi_pao_ceng.gd 的纯装饰生成器依赖）----
	var qi_pao_zhen: SpriteFrames = load("res://data/donghua/hai_di_qi_pao_4zhen.tres")
	assert_guo("气泡动画: hai_di_qi_pao_4zhen.tres",
			"" if qi_pao_zhen != null else "资源加载失败")
	if qi_pao_zhen != null:
		assert_eq(1 if qi_pao_zhen.has_animation(&"bao") else 0, 1, "气泡动画必须含 \"bao\"")
		assert_eq(qi_pao_zhen.get_frame_count(&"bao"), 4, "气泡动画应恰好 4 帧")
		assert_eq(1 if qi_pao_zhen.get_animation_loop(&"bao") else 0, 0,
				"气泡动画必须不循环（loop = false，播完自动结束）")

	# ---- 用例 7：12 套专属能力特效资源契约（te_xiao.gd 全部 preload）----
	# 防「素材做好但没接线」再次发生：资源本身必须存在、动画名/帧数/循环符合 te_xiao 的播放约定
	# 帧率按素材节奏单独锁：旧 8 套 12 fps；新 4 套 10/12/10/8（血腥狂热前两帧近似，放慢）
	var te_xiao_biao := [
		{"lu_jing": "res://data/donghua/xuan_wo_4zhen.tres", "fps": 12},
		{"lu_jing": "res://data/donghua/yu_ni_dan_4zhen.tres", "fps": 12},
		{"lu_jing": "res://data/donghua/sheng_na_mai_chong_4zhen.tres", "fps": 12},
		{"lu_jing": "res://data/donghua/yu_lei_chong_ci_4zhen.tres", "fps": 12},
		{"lu_jing": "res://data/donghua/kuang_bao_si_yao_4zhen.tres", "fps": 12},
		{"lu_jing": "res://data/donghua/ni_liu_shan_bi_4zhen.tres", "fps": 12},
		{"lu_jing": "res://data/donghua/ying_lin_fan_ji_4zhen.tres", "fps": 12},
		{"lu_jing": "res://data/donghua/dian_gan_shou_qi_4zhen.tres", "fps": 12},
		{"lu_jing": "res://data/donghua/ying_ke_hu_ti_4zhen.tres", "fps": 10},
		{"lu_jing": "res://data/donghua/dian_mai_chong_4zhen.tres", "fps": 12},
		{"lu_jing": "res://data/donghua/you_er_qi_pao_4zhen.tres", "fps": 10},
		{"lu_jing": "res://data/donghua/xue_xing_kuang_re_4zhen.tres", "fps": 8},
	]
	for xiang in te_xiao_biao:
		var lu_jing: String = xiang["lu_jing"]
		var qi_wang_fps: int = xiang["fps"]
		var te_xiao_kuang: SpriteFrames = load(lu_jing)
		assert_guo("专属特效: " + lu_jing, "" if te_xiao_kuang != null else "资源加载失败")
		if te_xiao_kuang == null:
			continue
		assert_eq(1 if te_xiao_kuang.has_animation(&"bao") else 0, 1, "特效动画名必须为 bao: " + lu_jing)
		assert_eq(te_xiao_kuang.get_frame_count(&"bao"), 4, "特效应恰好 4 帧: " + lu_jing)
		assert_eq(1 if te_xiao_kuang.get_animation_loop(&"bao") else 0, 0, "特效必须不循环: " + lu_jing)
		assert_eq(int(round(te_xiao_kuang.get_animation_speed(&"bao"))), qi_wang_fps, "特效帧率应为 %d fps: %s" % [qi_wang_fps, lu_jing])

	# ---- 用例 8：海草/珊瑚 4 帧摆动资源契约（ZhiWuQun 全部 preload）----
	# 植物不是静态图：4 帧、循环、5fps、四帧同尺寸（不同尺寸会让根部位移/播放抖动）
	var zhi_wu_lu_jing := [
		"res://data/donghua/hai_cao_4zhen.tres",
		"res://data/donghua/shan_hu_4zhen.tres",
	]
	for lu_jing in zhi_wu_lu_jing:
		var zhi_wu_kuang: SpriteFrames = load(lu_jing)
		assert_guo("植物摆动: " + lu_jing, "" if zhi_wu_kuang != null else "资源加载失败")
		if zhi_wu_kuang == null:
			continue
		assert_eq(1 if zhi_wu_kuang.has_animation(&"bai") else 0, 1, "植物动画名必须为 bai: " + lu_jing)
		assert_eq(zhi_wu_kuang.get_frame_count(&"bai"), 4, "植物应恰好 4 帧: " + lu_jing)
		assert_eq(1 if zhi_wu_kuang.get_animation_loop(&"bai") else 0, 1, "植物摆动必须循环: " + lu_jing)
		assert_eq(int(round(zhi_wu_kuang.get_animation_speed(&"bai"))), 5, "植物帧率应为 5 fps: " + lu_jing)
		var shou_zhen := zhi_wu_kuang.get_frame_texture(&"bai", 0)
		assert_eq(1 if shou_zhen != null else 0, 1, "植物首帧贴图不能为空: " + lu_jing)
		var tong_chi_cun := true
		if shou_zhen != null:
			for i in range(1, 4):
				var zhen := zhi_wu_kuang.get_frame_texture(&"bai", i)
				if zhen == null or zhen.get_size() != shou_zhen.get_size():
					tong_chi_cun = false
		assert_eq(1 if tong_chi_cun else 0, 1, "植物四帧必须同尺寸: " + lu_jing)

	# ---- 用例 9：进化形态数据契约（11 鱼种 × 3 分支 = 33）----
	# 素材 2026-11-03 批量导入；图鉴与进化三选一都直接读这张注册表，字段错一处就全错
	var jin_hua_quan := JinHuaKu.quan_bu()
	assert_eq(jin_hua_quan.size(), 33, "进化形态应恰好 33 个（11 鱼种 × 3 分支）")
	var jin_hua_id_ji := {}
	var zhuan_shu_cao := 0  # 已填的专属槽总数（33 分支 × 2 = 66）
	for jin_hua in jin_hua_quan:
		assert_eq(1 if jin_hua != null else 0, 1, "进化注册表不能有空项")
		if jin_hua == null:
			continue
		assert_eq(1 if String(jin_hua.bian_hao) != "" else 0, 1, "进化 id 不能为空")
		jin_hua_id_ji[jin_hua.bian_hao] = true
		assert_eq(1 if jin_hua.ming_zi != "" else 0, 1, "进化形态名不能为空: " + String(jin_hua.bian_hao))
		assert_eq(1 if jin_hua.ji_yu_ming != "" else 0, 1, "基础鱼种名不能为空: " + String(jin_hua.bian_hao))
		assert_eq(1 if jin_hua.miao_shu != "" else 0, 1, "形态设定不能为空: " + String(jin_hua.bian_hao))
		assert_float(jin_hua.shu_zhi_bei, 1.5, "进化倍率应为 ×1.5: " + String(jin_hua.bian_hao))
		assert_eq(1 if jin_hua.tie_tu != null and jin_hua.tie_tu.get_width() > 0 else 0, 1,
				"进化贴图必须可加载: " + String(jin_hua.bian_hao))
		# 6 帧游动动画（2026-11-04 接入）：不再用静态单帧兜底，六帧同宽同高
		assert_eq(1 if jin_hua.dong_hua != null else 0, 1,
				"进化形态必须有游动动画: " + String(jin_hua.bian_hao))
		if jin_hua.dong_hua != null:
			assert_eq(1 if jin_hua.dong_hua.has_animation(&"you") else 0, 1,
					"进化游动动画名必须为 you: " + String(jin_hua.bian_hao))
			assert_eq(jin_hua.dong_hua.get_frame_count(&"you"), 6,
					"进化游动动画应恰好 6 帧: " + String(jin_hua.bian_hao))
			assert_eq(1 if jin_hua.dong_hua.get_animation_loop(&"you") else 0, 1,
					"进化游动动画必须循环: " + String(jin_hua.bian_hao))
			var shou_zhen := jin_hua.dong_hua.get_frame_texture(&"you", 0)
			var tong_chi_cun := shou_zhen != null
			for i in range(1, 6):
				var zhen := jin_hua.dong_hua.get_frame_texture(&"you", i)
				if zhen == null or shou_zhen == null or zhen.get_size() != shou_zhen.get_size():
					tong_chi_cun = false
			assert_eq(1 if tong_chi_cun else 0, 1,
					"进化六帧必须同尺寸且可加载: " + String(jin_hua.bian_hao))
		# 全部 33 条分支都可被选（选角全开）
		assert_eq(1 if jin_hua.wan_jia_ke_yong else 0, 1,
				"进化分支必须对玩家开放: " + String(jin_hua.bian_hao))
		assert_eq(1 if JinHuaKu.zhao(jin_hua.bian_hao) == jin_hua else 0, 1,
				"按 id 反查必须命中同一个实例: " + String(jin_hua.bian_hao))
		# 专属技能/被动槽位：遗留给后续新分支的条目允许为空；填了就必须是能力池里的合法能力且归属本分支
		for zhuan_shu in [jin_hua.zhuan_shu_zhu_dong, jin_hua.zhuan_shu_bei_dong]:
			if zhuan_shu != null:
				zhuan_shu_cao += 1
				assert_eq(1 if NengLiKu.zhao(zhuan_shu.bian_hao) != null else 0, 1,
						"专属能力必须在能力池注册: " + String(zhuan_shu.bian_hao))
				assert_string(String(zhuan_shu.suoshu_xing_tai), String(jin_hua.bian_hao),
						"专属能力归属必须匹配分支: " + String(zhuan_shu.bian_hao))
	assert_eq(jin_hua_id_ji.size(), 33, "33 个进化 id 应互不重复")
	assert_eq(zhuan_shu_cao, 66, "专属技能/被动槽应填满 66 条（P0 6 + T1 24 + H 系列 36）")

	# 分组：11 组 × 每组 3 条，且每组正好覆盖东方/西方/异化各一条
	var jin_hua_zu := JinHuaKu.an_ji_yu()
	assert_eq(jin_hua_zu.size(), 11, "进化应覆盖 11 个基础鱼种分组")
	for yu_zhong_id in jin_hua_zu:
		var zu: Array = jin_hua_zu[yu_zhong_id]
		assert_eq(zu.size(), 3, "每个鱼种必须恰好 3 条分支: " + String(yu_zhong_id))
		var fen_zhi_ji := {}
		for jin_hua in zu:
			fen_zhi_ji[jin_hua.fen_zhi] = true
		assert_eq(fen_zhi_ji.size(), 3, "三条分支必须各占东方/西方/异化: " + String(yu_zhong_id))
		# 10 个 NPC 鱼种必须对应 data/yuzhong 的真实鱼种；玩家凹凸蜗牛鱼走形态表
		if yu_zhong_id != &"ao_tu_wo_niu_yu":
			assert_eq(1 if FileAccess.file_exists("res://data/yuzhong/%s.tres" % String(yu_zhong_id)) else 0,
					1, "进化所属鱼种必须是真实鱼种: " + String(yu_zhong_id))

	# 当前鱼种的候选（2026-11-04 全鱼种开放）：默认玩家 / 剑鱼 / 未知鱼种
	var wan_jia_fen_zhi := JinHuaKu.wan_jia_fen_zhi(&"ao_tu_wo_niu_yu")
	assert_eq(wan_jia_fen_zhi.size(), 3, "蜗牛鱼可选进化分支应恰好 3 条")
	for jin_hua in wan_jia_fen_zhi:
		assert_string(String(jin_hua.ji_yu_bian_hao), "ao_tu_wo_niu_yu",
				"蜗牛鱼候选只属于凹凸蜗牛鱼")
	assert_string(String(wan_jia_fen_zhi[0].ming_zi), "太岁肉灵芝兽", "第一条分支应为东方神话")
	assert_string(String(wan_jia_fen_zhi[1].ming_zi), "深海史莱姆女王", "第二条分支应为西方神话")
	assert_string(String(wan_jia_fen_zhi[2].ming_zi), "超压凝胶炮", "第三条分支应为能力异化")
	var jian_fen_zhi := JinHuaKu.wan_jia_fen_zhi(&"jian_yu")
	assert_eq(jian_fen_zhi.size(), 3, "剑鱼可选进化分支应恰好 3 条")
	for jin_hua in jian_fen_zhi:
		assert_string(String(jin_hua.ji_yu_bian_hao), "jian_yu", "剑鱼候选只属于剑鱼")
	assert_eq(JinHuaKu.wan_jia_fen_zhi(&"an_ying_jian_yu").size(), 0,
			"暗影剑鱼没有独立分支：形态侧映射到 jian_yu")
	assert_eq(JinHuaKu.wan_jia_fen_zhi(&"bu_cun_zai").size(), 0, "未知鱼种没有候选")
	for yu_zhong_id in jin_hua_zu:
		assert_eq(JinHuaKu.wan_jia_fen_zhi(yu_zhong_id).size(), 3,
				"每个进化分组都能取到 3 条候选: " + String(yu_zhong_id))
	assert_eq(1 if JinHuaKu.zhao(&"bu_cun_zai") == null else 0, 1, "未知进化 id 反查应返回 null")

	# 命名统一（策划案 v0.18）：显示名写「电鳗」，资源 id 仍为 dian_yao（旧档/动画映射兼容）
	var dian_yao_xt: XingTai = load("res://data/xingtai/dian_yao.tres")
	assert_string(String(dian_yao_xt.bian_hao), "dian_yao", "电鳗形态 id 保持 dian_yao")
	assert_string(String(dian_yao_xt.ming_zi), "电鳗", "电鳗形态显示名统一为「电鳗」")
	assert_string(String(NengLiKu.zhao(&"fang_dian_ma_bi").lai_yuan), "电鳗",
			"放电麻痹的来源显示「电鳗」")
	assert_string(String(JinHuaKu.zhao(&"lei_yuan_ming_she").ji_yu_ming), "电鳗",
			"电鳗进化分支的基础鱼种显示「电鳗」")

	# ---- 用例 10：scripts/ 下所有脚本都能编译 ----
	# 图鉴、设置、成就这些纯 UI 脚本没有任何测试场景加载，解析错误会静默溜过八步门禁
	# （2026-11-03 图鉴进化卡就吃过一次：一个 var miao := Variant 让整条脚本挂掉）
	var huai_jiao_ben: Array[String] = []
	for wen_jian in DirAccess.get_files_at("res://scripts"):
		if not wen_jian.ends_with(".gd"):
			continue
		# 解析失败的脚本 load() 仍返回对象（只打 ERROR 日志），靠基类名判真假：
		# 编译成功才有基类（Node/Resource/CanvasLayer…），失败返回空串
		var zi_ben = load("res://scripts/" + wen_jian)
		if zi_ben == null or String(zi_ben.get_instance_base_type()) == "":
			huai_jiao_ben.append(wen_jian)
	assert_eq(huai_jiao_ben.size(), 0, "scripts/ 下脚本都应能编译，坏的: %s" % ", ".join(huai_jiao_ben))

	# ---- 收卷：退出码是唯一门禁语言 ----
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _zhao_neng(bian_hao: StringName) -> NengLi:
	# 按 id 从能力池取一个（用例 4 用）
	for neng in quan_bu_neng_li:
		if neng.bian_hao == bian_hao:
			return neng
	return null


func jiao_yan_neng_li(neng: NengLi) -> String:
	# 能力校验器：返回空串=通过；返回文字=问题（红测靠它抓坏数据）
	# 规矩来源：主动必须有冷却和正主值；被动必须有正主值；所有数值不能为负
	if neng == null:
		return "能力为空"
	if neng.bian_hao == &"":
		return "bian_hao 不能为空"
	if neng.ming_zi == "":
		return "能力名不能为空"
	if neng.miao_shu == "":
		return "描述不能为空（三选一卡片要显示）"
	# 描述长度契约：卡片描述区预算 16 号字 15 字/行 × 9 行 ≈ 135 字（含后缀 2 行），
	# 描述本体留 110 字上限——超了手机上会竖向溢出卡底（2026-10-31 试玩实锤）
	if neng.miao_shu.length() > 110:
		return "描述超长（%d 字 > 110 上限，卡片会溢出）" % neng.miao_shu.length()
	if neng.shu_zhi < 0.0:
		return "主数值不能为负: " + str(neng.shu_zhi)
	if neng.npc_shu_zhi < 0.0:
		return "NPC 覆写不能为负: " + str(neng.npc_shu_zhi)
	if neng.ban_jing < 0.0:
		return "半径不能为负: " + str(neng.ban_jing)
	if neng.leng_que < 0.0:
		return "冷却不能为负: " + str(neng.leng_que)
	if neng.chi_xu < 0.0:
		return "持续时间不能为负: " + str(neng.chi_xu)
	if neng.npc_jian_ge < 0.0:
		return "NPC 间隔不能为负: " + str(neng.npc_jian_ge)
	if neng.ceng_jia < 0.0:
		return "每层增量不能为负: " + str(neng.ceng_jia)
	if neng.zui_da_dang < 1 or neng.zui_da_dang > 9:
		return "最大档位应在 1~9: " + str(neng.zui_da_dang)
	if neng.lei_xing == NengLi.LeiXing.ZHU_DONG:
		if neng.leng_que <= 0.0:
			return "主动能力必须有正冷却"
		if neng.shu_zhi <= 0.0:
			return "主动能力主数值应为正数"
	else:
		if neng.shu_zhi <= 0.0:
			return "被动能力主数值应为正数"
	return ""


func jiao_yan_yu_zhong(yu_zhong: YuZhong) -> String:
	# 鱼种校验器：返回空串=通过；返回文字=问题
	if yu_zhong.tie_tu == null:
		return "缺静态贴图"
	if yu_zhong.dong_hua == null:
		return "缺游动动画"
	if not yu_zhong.dong_hua.has_animation(&"you"):
		return "游动动画必须含 \"you\""
	if yu_zhong.dong_hua.get_frame_count(&"you") < 4:
		return "游动动画至少 4 帧"
	if yu_zhong.dong_hua.get_frame_texture(&"you", 0) == null:
		return "游动动画首帧贴图为空"
	if yu_zhong.dengji < 1 or yu_zhong.dengji > 10:
		return "等级应在 1~10"
	if yu_zhong.fenzhi < 1:
		return "分值应 ≥1"
	if yu_zhong.zui_ba <= 0.0:
		return "嘴巴系数应 >0"
	if yu_zhong.fan_ying_shi_jian < 0.0:
		return "反应时间不能为负"
	if yu_zhong.sudu_fanwei.x <= 0.0 or yu_zhong.sudu_fanwei.y < yu_zhong.sudu_fanwei.x:
		return "游速范围非法（x 应 >0 且 y ≥ x）"
	if yu_zhong.neng_li != null:
		var neng_jie_guo := jiao_yan_neng_li(yu_zhong.neng_li)
		if neng_jie_guo != "":
			return "能力非法: " + neng_jie_guo
	return ""


func jiao_yan_xing_tai(xing_tai: XingTai) -> String:
	# 形态校验器：返回空串=通过；返回文字=问题（红测靠它抓坏数据）
	# 规矩来源：所有形态必须有 "you" 动画；数值为正；初始能力只能是主动能力
	if xing_tai == null:
		return "形态为空"
	if xing_tai.bian_hao == &"":
		return "bian_hao 不能为空"
	if xing_tai.ming_zi == "":
		return "形态名不能为空"
	if xing_tai.miao_shu == "":
		return "形态说明不能为空"
	if xing_tai.tie_tu == null:
		return "缺静态预览贴图"
	if xing_tai.dong_hua == null:
		return "缺动画"
	if not xing_tai.dong_hua.has_animation(&"you"):
		return "动画必须含 \"you\""
	if xing_tai.dong_hua.get_frame_count(&"you") <= 0:
		return "动画 \"you\" 至少 1 帧"
	if xing_tai.dong_hua.get_frame_texture(&"you", 0) == null:
		return "动画首帧贴图为空"
	if xing_tai.kai_ju_deng_ji < 0 or xing_tai.kai_ju_deng_ji > 10:
		return "开局等级应在 0~10: " + str(xing_tai.kai_ju_deng_ji)
	if xing_tai.yi_dong_su_du <= 0.0:
		return "移动速度应 >0: " + str(xing_tai.yi_dong_su_du)
	if xing_tai.zui_ba <= 0.0:
		return "嘴巴系数应 >0: " + str(xing_tai.zui_ba)
	if xing_tai.zhuan_xiang_ji_su <= 0.0:
		return "转向速率应 >0: " + str(xing_tai.zhuan_xiang_ji_su)
	if xing_tai.jie_suo_sheng_li_ci_shu < 0:
		return "解锁胜场不能为负: " + str(xing_tai.jie_suo_sheng_li_ci_shu)
	if xing_tai.kai_ju_neng_li != null:
		if not xing_tai.kai_ju_neng_li.shi_zhu_dong():
			return "初始能力必须是主动能力"
		var neng_jie_guo := jiao_yan_neng_li(xing_tai.kai_ju_neng_li)
		if neng_jie_guo != "":
			return "初始能力非法: " + neng_jie_guo
	return ""


func _zou_hong_ce_neng_li(neng: NengLi, biao_qian: String) -> void:
	# 红测助手：坏能力必须被校验器拒绝；拒绝失败才记 FAIL
	var jie_guo := jiao_yan_neng_li(neng)
	if jie_guo == "":
		failed += 1
		print("FAIL: 红测失守——%s 没被校验器抓到" % biao_qian)
	else:
		passed += 1
		print("红测命中: %s → %s" % [biao_qian, jie_guo])


func _zou_hong_ce_xing_tai(xing_tai: XingTai, biao_qian: String) -> void:
	# 红测助手：坏形态必须被校验器拒绝；拒绝失败才记 FAIL
	var jie_guo := jiao_yan_xing_tai(xing_tai)
	if jie_guo == "":
		failed += 1
		print("FAIL: 红测失守——%s 没被校验器抓到" % biao_qian)
	else:
		passed += 1
		print("红测命中: %s → %s" % [biao_qian, jie_guo])


func assert_float(shi_ji: float, qi_wang: float, biao_qian: String) -> void:
	# 浮点断言：形态数值用近似相等，避免 0.85 这类十进制误差
	if is_equal_approx(shi_ji, qi_wang):
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %s，实际 %s）" % [biao_qian, str(qi_wang), str(shi_ji)])


func assert_eq(shi_ji, qi_wang: int, biao_qian: String) -> void:
	# 记账员：失败只记账不爆炸——对比裸 assert() 的挂死陷阱
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %d，实际 %d）" % [biao_qian, qi_wang, shi_ji])


func assert_string(shi_ji: String, qi_wang: String, biao_qian: String) -> void:
	# 文本断言：能力 id 映射必须一字不差
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %s，实际 %s）" % [biao_qian, qi_wang, shi_ji])


func assert_guo(biao_qian: String, jie_guo: String) -> void:
	# 断言校验结果为通过（空串）：失败时把校验器的报错原文打出来
	if jie_guo == "":
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（%s）" % [biao_qian, jie_guo])
