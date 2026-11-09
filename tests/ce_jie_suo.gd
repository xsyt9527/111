extends SceneTree
# 局外存档测试（TASK-018；2026-11-08 D 选角解锁 + B1 成就值语义）
# 默认值 / D 四类解锁（mian 免费 / guang_gao 广告 / cheng_jiu 累计成就 / tong_guan 累计通关）
# / 选择 / 读写档 / 损坏回退 / 调试
# 当前注册表 12 个：凹凸蜗牛鱼 + 10 NPC 鱼 + 鲸鲨；0 胜只解锁默认免费的 ao_tu_wo_niu_yu
# 不上树裸实例：_init 只装形态表，_ready 才读正式存档并连 ZhangBen 信号
# 全程用临时存档路径，结束时删除；测试不得碰玩家的正式存档

const CUN_DANG_SCRIPT := preload("res://scripts/cun_dang.gd")
const ZHU_JUE := "ao_tu_wo_niu_yu"

var passed := 0
var failed := 0
var lu_jing := ""


func _initialize() -> void:
	lu_jing = "user://ce_jie_suo_%d_%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	_shan_chu()
	var cd = CUN_DANG_SCRIPT.new()
	cd.lu_jing = lu_jing
	cd.zai_ru()

	# ---- 用例 1：没存档时的默认值（12 形态，0 胜只解锁默认免费 1 个）----
	assert_eq(cd.sheng_li_ci_shu, 0, "默认胜场 0")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "默认形态是凹凸蜗牛鱼")
	assert_eq(cd.suo_you_xing_tai().size(), 12, "形态表 12 个：玩家 + 10 NPC 鱼 + 鲸鲨")
	assert_eq(cd.ke_xuan_xing_tai().size(), 1, "0 胜只解锁默认免费的蜗牛鱼")
	assert_bool(cd.shi_fou_jie_suo(&"ao_tu_wo_niu_yu"), true, "mian：蜗牛鱼默认解锁")
	assert_bool(cd.shi_fou_jie_suo(&"lan_yu"), false, "cheng_jiu：钻光鱼需累计成就 400")
	assert_bool(cd.shi_fou_jie_suo(&"hong_yu"), false, "cheng_jiu：红鱼需累计成就 100")
	assert_bool(cd.shi_fou_jie_suo(&"ju_kou_yu"), false, "cheng_jiu：巨口鱼需累计成就 200")
	assert_bool(cd.shi_fou_jie_suo(&"zong_yu"), false, "cheng_jiu：金枪鱼需累计成就 300")
	assert_bool(cd.shi_fou_jie_suo(&"cheng_yu"), false, "guang_gao：橙鱼未看广告锁定")
	assert_bool(cd.shi_fou_jie_suo(&"lv_yu"), false, "guang_gao：绿鱼未看广告锁定")
	assert_bool(cd.shi_fou_jie_suo(&"qi_yu"), false, "guang_gao：旗鱼未看广告锁定")
	assert_bool(cd.shi_fou_jie_suo(&"jian_yu"), false, "guang_gao：剑鱼未看广告锁定")
	assert_bool(cd.shi_fou_jie_suo(&"an_ying_jian_yu"), false, "tong_guan：暗影剑鱼需通关 3 次")
	assert_bool(cd.shi_fou_jie_suo(&"ye_deng_long_yu"), false, "tong_guan：夜灯龙鱼需通关 2 次")
	assert_bool(cd.shi_fou_jie_suo(&"fen_yu"), false, "tong_guan：鲸鲨需通关 1 次")
	assert_bool(cd.shi_fou_jie_suo(&"deng_long_yu"), false, "旧形态灯笼鱼不再是玩家选项")
	assert_bool(cd.shi_fou_jie_suo(&"dian_yao"), false, "旧形态电鳗不再是玩家选项")
	assert_bool(cd.shi_fou_jie_suo(&"bu_cun_zai"), false, "未知 id 视为未解锁")
	assert_string(String(cd.dang_qian_xing_tai().bian_hao), ZHU_JUE, "当前形态回默认")
	assert_bool(FileAccess.file_exists(lu_jing), false, "读档不得创建存档文件")

	# ---- 用例 2：首胜累计胜场，并解锁通关 1 次档的鲸鲨 ----
	# --script 无 /root/ZhangBen：ji_lu_sheng_li 走保底分支（每胜 +10 成就值，不叠 B1 的 +50）
	var xin: Array[XingTai] = cd.ji_lu_sheng_li()
	assert_eq(xin.size(), 1, "首胜解锁鲸鲨（tong_guan 1）")
	if xin.size() == 1:
		assert_string(String(xin[0].bian_hao), "fen_yu", "首胜解锁的正是鲸鲨")
	assert_eq(cd.sheng_li_ci_shu, 1, "首胜后累计 1")
	assert_eq(cd.cheng_jiu_zhi, 10, "首胜余额 +10（无账本保底）")
	assert_eq(cd.lei_ji_cheng_jiu_zhi, 10, "首胜累计成就 +10（无账本保底）")
	assert_eq(cd.ke_xuan_xing_tai().size(), 2, "1 胜时可选蜗牛鱼 + 鲸鲨 2 个")
	assert_bool(FileAccess.file_exists(lu_jing), true, "胜利瞬间写档")
	assert_eq(cd.shang_ci_xin_jie_suo.size(), 1, "新解锁提示入队 1 条")
	assert_eq(cd.qu_xin_jie_suo().size(), 1, "提示队列取出 1 条")
	assert_eq(cd.shang_ci_xin_jie_suo.size(), 0, "取出后提示队列清空")

	# ---- 用例 3：继续胜利按通关档解锁；旧形态不因胜场回到注册表 ----
	xin = cd.ji_lu_sheng_li()
	assert_eq(xin.size(), 1, "第二胜解锁夜灯龙鱼（tong_guan 2）")
	if xin.size() == 1:
		assert_string(String(xin[0].bian_hao), "ye_deng_long_yu", "第二胜解锁的正是夜灯龙鱼")
	assert_eq(cd.sheng_li_ci_shu, 2, "第二胜后累计 2")
	assert_bool(cd.shi_fou_jie_suo(&"dian_yao"), false, "2 胜也不会解锁旧电鳗形态")
	xin = cd.ji_lu_sheng_li()
	assert_eq(xin.size(), 1, "第三胜解锁暗影剑鱼（tong_guan 3）")
	if xin.size() == 1:
		assert_string(String(xin[0].bian_hao), "an_ying_jian_yu", "第三胜解锁的正是暗影剑鱼")
	assert_eq(cd.sheng_li_ci_shu, 3, "第三胜后累计 3")
	assert_eq(cd.ke_xuan_xing_tai().size(), 4, "三胜后可选蜗牛鱼 + 鲸鲨 + 夜灯龙鱼 + 暗影剑鱼")

	# ---- 用例 4：选择与重读（只允许已解锁形态）----
	assert_bool(cd.xuan_ze(&"ao_tu_wo_niu_yu"), true, "默认主角可选")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "选择后当前形态为蜗牛鱼")
	assert_bool(cd.xuan_ze(&"jian_yu"), false, "广告位剑鱼未看广告不可选")
	assert_bool(cd.xuan_ze(&"an_ying_jian_yu"), true, "通关 3 次解锁的暗影剑鱼可选")
	assert_string(String(cd.dang_qian_bian_hao), "an_ying_jian_yu", "选择后当前形态为暗影剑鱼")
	assert_bool(cd.xuan_ze(&"fen_yu"), true, "通关 1 次解锁的鲸鲨可选")
	assert_string(String(cd.dang_qian_bian_hao), "fen_yu", "选择后当前形态为鲸鲨")
	assert_bool(cd.xuan_ze(&"dian_yao"), false, "旧形态不可选")
	assert_bool(cd.xuan_ze(&"bu_cun_zai"), false, "未知 id 不可选")
	assert_bool(cd.xuan_ze(&"ao_tu_wo_niu_yu"), true, "切回蜗牛鱼")
	var cd2 = CUN_DANG_SCRIPT.new()
	cd2.lu_jing = lu_jing
	cd2.zai_ru()
	assert_eq(cd2.sheng_li_ci_shu, 3, "重读胜场保持 3")
	assert_string(String(cd2.dang_qian_bian_hao), ZHU_JUE, "重读当前形态保持蜗牛鱼")
	assert_eq(cd2.cheng_jiu_zhi, 30, "三胜累计成就值 30（每胜 +10）")
	cd2.free()

	# ---- 用例 4b：成就值购买永久开局技能 ----
	assert_eq(NengLiKu.quan_bu().size(), 65, "能力总表 65 个（35 通用 + 30 专属）")
	assert_eq(NengLiKu.quan_bu().size() - NengLiKu.tong_yong_chi().size(), 30,
			"专属技 30 个（65 总表 − 35 通用池）")
	assert_bool(NengLiKu.zhao(&"yu_lei_chong_ci") != null, true, "按 id 反查主动能力")
	assert_eq(cd.cheng_jiu_dai_jia(NengLiKu.zhao(&"yu_lei_chong_ci")), 30, "主动永久解锁 30 成就值")
	assert_eq(cd.cheng_jiu_dai_jia(NengLiKu.zhao(&"ruan_lin")), 20, "被动永久解锁 20 成就值")
	assert_bool(cd.you_yong_jiu(&"yu_lei_chong_ci"), false, "默认没有永久技能")
	assert_bool(cd.jie_suo_yong_jiu(&"yu_lei_chong_ci"), true, "30 成就值够解锁主动")
	assert_eq(cd.cheng_jiu_zhi, 0, "解锁后扣到 0")
	assert_bool(cd.you_yong_jiu(&"yu_lei_chong_ci"), true, "主动已永久解锁")
	assert_bool(cd.jie_suo_yong_jiu(&"yu_lei_chong_ci"), false, "重复解锁拒绝且不再扣分")
	assert_eq(cd.cheng_jiu_zhi, 0, "重复解锁不扣分")
	assert_bool(cd.jie_suo_yong_jiu(&"ruan_lin"), false, "0 成就值买不起被动")
	assert_eq(cd.yong_jiu_neng_li.size(), 1, "永久技能表只记 1 个")
	# 开局自动装配：主动装 1 档、被动装 1 层（用测试替身，不依赖 Autoload）
	var zb = preload("res://tests/ce_zhuang_bei_jia.gd").new()
	cd.ying_yong_yong_jiu(zb)
	assert_eq(zb.zhu_dong.size(), 1, "永久主动在开局自动装入主动组")
	assert_eq(zb.dang_qian_bei_dong_ceng(&"yu_lei_chong_ci"), 0, "主动不会进被动层数表")
	cd.tiao_shi_jia_cheng_jiu(100)
	cd.jie_suo_yong_jiu(&"ruan_lin")
	cd.ying_yong_yong_jiu(zb)
	assert_eq(zb.dang_qian_bei_dong_ceng(&"ruan_lin"), 1, "永久被动在开局自动叠 1 层")
	cd.ying_yong_yong_jiu(zb)  # 幂等：重复应用不重复叠层
	assert_eq(zb.dang_qian_bei_dong_ceng(&"ruan_lin"), 1, "重复应用不叠第二层")
	zb.free()
	# 重读：成就值与永久技能都落盘
	var cd4 = CUN_DANG_SCRIPT.new()
	cd4.lu_jing = lu_jing
	cd4.zai_ru()
	assert_eq(cd4.cheng_jiu_zhi, 80, "解锁主动 30 + 被动 20 后剩 80")
	assert_eq(cd4.yong_jiu_neng_li.size(), 2, "两个永久技能都落盘")
	assert_bool(cd4.you_yong_jiu(&"ruan_lin"), true, "被动永久解锁落盘")
	cd4.free()

	# ---- 用例 4b2：成就页重置——清技能并按原价返还，未花余额保留（用掉的 + 还没用的）----
	cd.dian_liang_jin_hua(&"tai_sui_rou_ling_zhi_shou")
	assert_eq(cd.cheng_jiu_zhi, 80, "重置前余额 80（130 总成就 − 已花 50）")
	cd.chong_zhi_cheng_jiu()
	assert_eq(cd.cheng_jiu_zhi, 130, "重置后总额 130 = 未花 80 + 已花 50 原价返还")
	assert_eq(cd.yong_jiu_neng_li.size(), 0, "重置成就清空已永久解锁的技能")
	assert_eq(cd.sheng_li_ci_shu, 3, "重置成就不影响胜场")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "重置成就不影响当前形态")
	assert_bool(cd.shi_fou_dian_liang(&"tai_sui_rou_ling_zhi_shou"), true,
			"重置成就不清图鉴点亮")
	var cd6 = CUN_DANG_SCRIPT.new()
	cd6.lu_jing = lu_jing
	cd6.zai_ru()
	assert_eq(cd6.cheng_jiu_zhi, 130, "重置后重读：130 总成就落盘")
	assert_eq(cd6.yong_jiu_neng_li.size(), 0, "重置后重读：永久技能仍为空")
	assert_eq(cd6.sheng_li_ci_shu, 3, "重置后重读：胜场保持 3")
	cd6.free()
	cd.chong_zhi_cheng_jiu()
	assert_eq(cd.cheng_jiu_zhi, 130, "已无已购技能时再重置，余额不变（不重复返还）")

	# ---- 用例 4b3：进化专属技不进通用池/成就兑换（策划案 v0.21 独占规则）----
	var zhuan := NengLi.new()
	zhuan.bian_hao = &"ce_zhuan_shu"
	zhuan.suoshu_xing_tai = &"lei_yuan_ming_she"
	assert_eq(1 if zhuan.shi_zhuan_shu() else 0, 1, "带归属形态的能力是专属技")
	assert_eq(NengLiKu.tong_yong_chi().size(), 35, "通用池 35 个（专属技已入库但不入池）")
	var chi_you_zhuan := 0
	for neng in NengLiKu.tong_yong_chi():
		if neng.shi_zhuan_shu():
			chi_you_zhuan += 1
	assert_eq(chi_you_zhuan, 0, "通用池绝不包含专属技")
	assert_bool(cd.ke_yong_jiu_dui_huan(zhuan), false, "专属技不可用成就值兑换")
	assert_bool(cd.ke_yong_jiu_dui_huan(NengLiKu.zhao(&"ruan_lin")), true, "通用技仍可兑换")
	var ce_chi: Array[NengLi] = [zhuan, NengLiKu.zhao(&"ruan_lin")]
	var chou_chi := NengLiChou.ke_xuan_chi(ce_chi, {}, {})
	assert_eq(chou_chi.size(), 1, "升级三选一候选必须滤掉专属技")
	assert_string(String(chou_chi[0].bian_hao), "ruan_lin", "留下的只有通用技")

	# ---- 用例 5：调试解锁全部 / 清空进度 ----
	# 调试解锁按 D 三类来源（通关/成就/广告）补满：通关档最高 3，已累计 3 胜就保持 3，主角仍可选
	cd.tiao_shi_jie_suo_quan_bu()
	assert_eq(cd.sheng_li_ci_shu, 3, "调试解锁不降已有胜场（通关档最高 3，保持 3）")
	assert_eq(cd.ke_xuan_xing_tai().size(), 12, "调试解锁后 12 个形态全可选")
	assert_eq(cd.lei_ji_cheng_jiu_zhi, 400, "调试解锁把累计成就抬到成就档最高 400")
	assert_eq(cd.cheng_jiu_zhi, 130, "调试解锁只抬累计成就，不动可消费余额")
	assert_bool(cd.shi_fou_jie_suo(&"lan_yu"), true, "调试解锁：成就档钻光鱼解锁")
	assert_bool(cd.shi_fou_guang_gao_jie_suo(&"qi_yu"), true, "调试解锁：广告位写入已看广告集合")
	var cd3 = CUN_DANG_SCRIPT.new()
	cd3.lu_jing = lu_jing
	cd3.zai_ru()
	assert_eq(cd3.sheng_li_ci_shu, 3, "调试解锁已落盘")
	assert_bool(cd3.shi_fou_jie_suo(&"lan_yu"), true, "调试解锁的成就档落盘")
	assert_bool(cd3.shi_fou_jie_suo(&"qi_yu"), true, "调试解锁的广告位落盘")
	cd3.free()
	cd.tiao_shi_qing_chu_jin_du()
	assert_eq(cd.sheng_li_ci_shu, 0, "调试清空后胜场 0")
	assert_eq(cd.cheng_jiu_zhi, 0, "调试清空同时清空成就值")
	assert_eq(cd.yong_jiu_neng_li.size(), 0, "调试清空同时清空永久技能")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "调试清空后仍是蜗牛鱼")
	assert_bool(cd.shi_fou_jie_suo(&"lan_yu"), false, "调试清空后成就档重新锁定")
	assert_bool(cd.xuan_ze(&"dian_yao"), false, "0 胜不能选旧电鳗形态")
	assert_eq(cd.qu_xin_jie_suo().size(), 0, "调试清空清掉提示")

	# ---- 用例 4c：图鉴点亮（策划案 v0.18）：新增 / 去重 / 未知 id 拒绝 / 落盘 / 旧档兼容 ----
	assert_bool(cd.shi_fou_dian_liang(&"tai_sui_rou_ling_zhi_shou"), false, "默认没有点亮的进化")
	assert_bool(cd.dian_liang_jin_hua(&"tai_sui_rou_ling_zhi_shou"), true, "第一次进化点亮图鉴")
	assert_bool(cd.shi_fou_dian_liang(&"tai_sui_rou_ling_zhi_shou"), true, "点亮后按 id 可查")
	assert_bool(cd.dian_liang_jin_hua(&"tai_sui_rou_ling_zhi_shou"), false, "重复点亮幂等拒绝")
	assert_eq(cd.yi_dian_liang_ming_dan().size(), 1, "点亮名单只记 1 条")
	assert_bool(cd.dian_liang_jin_hua(&"bu_cun_zai"), false, "未知形态 id 拒绝点亮")
	assert_eq(cd.yi_dian_liang_ming_dan().size(), 1, "拒绝不污染名单")
	var cd5 = CUN_DANG_SCRIPT.new()
	cd5.lu_jing = lu_jing
	cd5.zai_ru()
	assert_bool(cd5.shi_fou_dian_liang(&"tai_sui_rou_ling_zhi_shou"), true, "点亮落盘，重读仍在")
	assert_eq(cd5.yi_dian_liang_ming_dan().size(), 1, "重读后点亮名单仍是 1 条")
	cd5.free()
	# 旧档没有点亮字段：按“一个都没点亮”读（不因缺字段作废整份存档）
	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 1, \"dang_qian_xing_tai\": \"ao_tu_wo_niu_yu\"}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 1, "旧档胜场照常读")
	assert_eq(cd.yi_dian_liang_ming_dan().size(), 0, "缺少点亮字段：读到空名单")
	# 坏 id 混在列表里：只丢坏 id，好 id 照常点亮
	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 1, \"dang_qian_xing_tai\": \"ao_tu_wo_niu_yu\", "
			+ "\"yi_dian_liang_jin_hua\": [\"tai_sui_rou_ling_zhi_shou\", \"bu_cun_zai\", "
			+ "\"tai_sui_rou_ling_zhi_shou\"]}")
	cd.zai_ru()
	assert_eq(cd.yi_dian_liang_ming_dan().size(), 1, "坏 id 被过滤、重复 id 去重")
	assert_bool(cd.shi_fou_dian_liang(&"tai_sui_rou_ling_zhi_shou"), true, "好 id 正常点亮")

	# ---- 用例 6：坏存档只回退、不覆盖 ----
	_xie_wen("not json at all")
	var yuan := _du_wen()
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 0, "坏 JSON 回退 0 胜")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "坏 JSON 回退默认主角")
	assert_string(_du_wen(), yuan, "坏 JSON 加载后不得覆盖原文件")

	_xie_wen("[1, 2, 3]")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 0, "JSON 非字典回退 0 胜")

	_xie_wen("{\"ban_ben\": 99, \"sheng_li_ci_shu\": 2, \"dang_qian_xing_tai\": \"ao_tu_wo_niu_yu\"}")
	yuan = _du_wen()
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 0, "版本不符整体回退 0 胜")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "版本不符回退默认主角")
	assert_string(_du_wen(), yuan, "版本不符不得覆盖原文件")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": -5, \"dang_qian_xing_tai\": \"ao_tu_wo_niu_yu\"}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 0, "负胜场夹到 0")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "负胜场时默认形态保留")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 2, \"dang_qian_xing_tai\": \"bu_cun_zai\"}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 2, "未知形态 id 时保留胜场")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "未知形态 id 回退默认")

	# 旧版本存档里可能还记着灯笼鱼/电鳗：胜场保留，形态回默认主角
	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 2, \"dang_qian_xing_tai\": \"deng_long_yu\"}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 2, "旧形态 id 不影响胜场")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "旧形态 id 不再恢复，回退蜗牛鱼")

	# 旗鱼在 D 表里是广告位：形态已注册 ≠ 已解锁，没看广告的旧档不能直接恢复
	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 2, \"dang_qian_xing_tai\": \"qi_yu\"}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 2, "旗鱼旧档胜场保留")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "广告位未解锁：旧档当前形态回默认")

	# 旧档若已记录广告解锁集合，则恢复旗鱼
	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 2, \"dang_qian_xing_tai\": \"qi_yu\", \"yi_kan_guang_gao\": [\"qi_yu\"]}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 2, "旗鱼旧档胜场保留")
	assert_string(String(cd.dang_qian_bian_hao), "qi_yu", "已看广告：旗鱼当前形态恢复")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 0, \"dang_qian_xing_tai\": \"dian_yao\"}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 0, "旧形态记录不影响胜场")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "旧形态不可作为当前形态")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 1.0, \"dang_qian_xing_tai\": \"ao_tu_wo_niu_yu\"}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 1, "JSON 浮点胜场按整数读取")
	assert_bool(cd.shi_fou_jie_suo(&"ao_tu_wo_niu_yu"), true, "浮点胜场也认主角")
	assert_bool(cd.shi_fou_jie_suo(&"dian_yao"), false, "浮点胜场不会复活旧形态")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": \"2\", \"dang_qian_xing_tai\": \"ao_tu_wo_niu_yu\"}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 0, "字符串胜场视为非法回退 0")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 2, \"dang_qian_xing_tai\": 5}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 2, "非字符串当前形态保留胜场")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "非字符串当前形态回默认")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 2, \"dang_qian_xing_tai\": \"ao_tu_wo_niu_yu\"}")
	cd.zai_ru()
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "合法存档正常恢复蜗牛鱼")

	# ---- 收卷 ----
	cd.free()
	_shan_chu()
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _xie_wen(wen: String) -> void:
	var wen_jian := FileAccess.open(lu_jing, FileAccess.WRITE)
	if wen_jian == null:
		failed += 1
		print("FAIL: 无法写入临时存档 " + lu_jing)
		return
	wen_jian.store_string(wen)
	wen_jian.close()


func _du_wen() -> String:
	var wen_jian := FileAccess.open(lu_jing, FileAccess.READ)
	if wen_jian == null:
		return ""
	var wen := wen_jian.get_as_text()
	wen_jian.close()
	return wen


func _shan_chu() -> void:
	if FileAccess.file_exists(lu_jing):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(lu_jing))


func assert_eq(shi_ji, qi_wang: int, biao_qian: String) -> void:
	# 严格比较：类型也必须一致，防 bool == 1 之类的假绿
	if shi_ji == qi_wang and typeof(shi_ji) == typeof(qi_wang):
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %s，实际 %s）" % [biao_qian, str(qi_wang), str(shi_ji)])


func assert_bool(shi_ji: bool, qi_wang: bool, biao_qian: String) -> void:
	if typeof(shi_ji) == TYPE_BOOL and shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %s，实际 %s）" % [biao_qian, str(qi_wang), str(shi_ji)])


func assert_string(shi_ji: String, qi_wang: String, biao_qian: String) -> void:
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %s，实际 %s）" % [biao_qian, qi_wang, shi_ji])
