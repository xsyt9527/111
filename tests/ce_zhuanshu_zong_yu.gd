extends Node2D
# 大眼金枪鱼（zong_yu）专属技自测：6 条数据 + 3 个形态槽位 + 3 主动运行时 + 3 被动 + 边界
# 契约：docs/专属技模块_开发契约.md 第 8 节；失败只打印 FAIL 行，不裸 assert、不打印 ERROR
# 运行：Godot --headless --path . res://tests/ce_zhuanshu_zong_yu_chang_jing.tscn --quit-after 600

const ZHUAN_SHU := preload("res://scripts/zhuan_shu_ku.gd")
const SHU_ZHI := preload("res://scripts/shu_zhi.gd")

const ZHU_DONG_IDS := [&"liu_xing_yue", &"shen_ju_chong_feng", &"qian_yan_qi_she"]
const BEI_DONG_IDS := [&"shun_feng_yi", &"gu_zhi_zhong_jia", &"lei_yan_suo_ding"]
const FORM_IDS := {
	&"wen_yao_zhan_wei": [&"liu_xing_yue", &"shun_feng_yi"],
	&"hai_shen_xun_yang_ju": [&"shen_ju_chong_feng", &"gu_zhi_zhong_jia"],
	&"qian_yan_lei_po_yu": [&"qian_yan_qi_she", &"lei_yan_suo_ding"],
}

var passed := 0
var failed := 0
var yu: Yu
var _npc_lie: Array[YuNpc] = []


func _ready() -> void:
	# 场景模式：照契约第 8 节构造玩家；关掉账本饥饿/局内时钟，避免 _process 背景干扰
	yu = load("res://scenes/Yu.tscn").instantiate()
	yu.zi_dong_yao_ji = false
	yu.position = Vector2(600, 600)
	add_child(yu)
	ZhangBen.process_mode = Node.PROCESS_MODE_DISABLED
	_ce_shu_ju()
	_ce_xing_tai()
	_ce_bian_jie()
	_ce_liu_xing_yue()
	_ce_shen_ju_chong_feng()
	_ce_qian_yan_qi_she()
	_ce_shun_feng_yi()
	_ce_gu_zhi_zhong_jia()
	_ce_lei_yan_suo_ding()
	YinXiang.quan_ting()
	ZhangBen.chong_zhi()  # 收尾复位
	print("Results: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)


# ---- 记账 ----

func _ce(biao_qian: String, tiao_jian: bool) -> void:
	# 记账员：失败只记账不爆炸——对比裸 assert() 的挂死陷阱
	if tiao_jian:
		passed += 1
	else:
		failed += 1
		print("FAIL: " + biao_qian)


func _ce_xiang(biao_qian: String, shu: float, qi_wang: float) -> void:
	# 浮点断言：打印期望/实际，调参时一眼看出差多少
	if is_equal_approx(shu, qi_wang):
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %s，实际 %s）" % [biao_qian, str(qi_wang), str(shu)])


# ---- 数据与槽位 ----

func _ce_shu_ju() -> void:
	for id in ZHU_DONG_IDS:
		_ce_neng_li(id, true)
	for id in BEI_DONG_IDS:
		_ce_neng_li(id, false)


func _ce_neng_li(id: StringName, zhu_dong: bool) -> void:
	var lu: String = "res://data/nengli/%s.tres" % String(id)
	var neng: NengLi = load(lu)
	_ce("数据：%s 可加载" % String(id), neng != null)
	if neng == null:
		return
	_ce("数据：%s 文件名=bian_hao" % String(id), neng.bian_hao == id)
	_ce("数据：%s 名称非空" % String(id), not neng.ming_zi.is_empty())
	_ce("数据：%s 描述非空且≤110字" % String(id),
			not neng.miao_shu.is_empty() and neng.miao_shu.length() <= 110)
	_ce("数据：%s 来源非空" % String(id), not neng.lai_yuan.is_empty())
	_ce("数据：%s 类型正确" % String(id),
			neng.lei_xing == (NengLi.LeiXing.ZHU_DONG if zhu_dong else NengLi.LeiXing.BEI_DONG))
	_ce("数据：%s 主动/被动口径" % String(id), neng.shi_zhu_dong() == zhu_dong)
	_ce("数据：%s 单档" % String(id), neng.zui_da_dang == 1)
	_ce("数据：%s 档位表留空" % String(id), neng.dang_biao.is_empty())
	_ce("数据：%s 主值>0" % String(id), neng.shu_zhi > 0.0)
	if zhu_dong:
		_ce("数据：%s 冷却>0" % String(id), neng.leng_que > 0.0)
	_ce("数据：%s 绑定形态" % String(id), neng.suoshu_xing_tai == _zhao_form(id))
	for jian in [&"leng_que", &"chi_xu", &"ban_jing", &"shu_zhi", &"npc_shu_zhi", \
			&"fu_shu_zhi", &"npc_jian_ge", &"ceng_jia", &"nei_bu_leng_que"]:
		_ce("数据：%s %s 非负" % [String(id), String(jian)], neng.dang_zhi(jian, 1) >= 0.0)
	_ce("数据：%s 每局次数非负" % String(id), neng.mei_ju_ci_shu >= 0)


func _zhao_form(id: StringName) -> StringName:
	# 这条技能按分派表应该绑哪个形态
	for form_id in FORM_IDS:
		if (FORM_IDS[form_id] as Array).has(id):
			return form_id
	return &""


func _ce_xing_tai() -> void:
	for form_id in FORM_IDS:
		var form: JinHua = JinHuaKu.zhao(form_id)
		_ce("形态：%s 可加载" % String(form_id), form != null)
		if form == null:
			continue
		_ce("形态：%s 属于大眼金枪鱼" % String(form_id), form.ji_yu_bian_hao == &"zong_yu")
		_ce("形态：%s 玩家可用" % String(form_id), form.wan_jia_ke_yong)
		var zhu_dong: NengLi = form.zhuan_shu_zhu_dong
		var bei_dong: NengLi = form.zhuan_shu_bei_dong
		_ce("形态：%s 主动槽非空且 id 对" % String(form_id),
				zhu_dong != null and zhu_dong.bian_hao == FORM_IDS[form_id][0])
		_ce("形态：%s 被动槽非空且 id 对" % String(form_id),
				bei_dong != null and bei_dong.bian_hao == FORM_IDS[form_id][1])
		# 直接 load 磁盘文件：验证槽位路径本身没有写错（不依赖 JinHuaKu 缓存）
		var cong_pan: JinHua = load("res://data/jinhua/%s.tres" % String(form_id))
		_ce("形态：%s 磁盘文件可加载" % String(form_id), cong_pan != null)
		if cong_pan != null:
			_ce("形态：%s 磁盘主动槽非空" % String(form_id), cong_pan.zhuan_shu_zhu_dong != null)
			_ce("形态：%s 磁盘被动槽非空" % String(form_id), cong_pan.zhuan_shu_bei_dong != null)


# ---- 夹具 ----

func _kai_form(form_id: StringName) -> JinHua:
	# 清场 → 大眼金枪鱼开局 → Lv.6 → 目标进化形态（走账本正式入口）
	_qing_chi()
	ZhangBen.chong_zhi()
	_ce("夹具：%s 开局形态装配" % String(form_id),
			ZhangBen.kai_ju_xing_tai(load("res://data/xingtai/zong_yu.tres")))
	ZhangBen.deng_ji = 6
	ZhangBen.dang_qian_ti_xing = ZhangBen.ti_xing_shang_xian()
	var form: JinHua = JinHuaKu.zhao(form_id)
	_ce("夹具：%s 进化装配" % String(form_id), ZhangBen.jin_hua_wei(form))
	yu.scale = yu._ti_xing_vector()
	# 进化演出 1.7 秒无敌会干扰断言：测试专用，立刻收掉
	yu.wudi_dingshi.stop()
	yu.wudi = false
	yu._ni_liu_sheng_yu = 0.0
	yu.fang_xiang = Vector2.RIGHT
	yu.dang_qian_jiao = 0.0
	yu.position = Vector2(600, 600)
	return form


func _qing_chi() -> void:
	# 清掉上一用例的靶鱼、玩家计时/冷却与本模块 meta：用例互不串场
	for npc in _npc_lie:
		if is_instance_valid(npc):
			npc.free()
	_npc_lie.clear()
	if yu == null:
		return
	yu.zhu_dong_leng_que.clear()
	yu._nei_bu_leng_que.clear()
	yu._mei_ju_yong_ci.clear()
	yu.wudi_dingshi.stop()
	yu.wudi = false
	yu._ni_liu_sheng_yu = 0.0
	yu._tui_kai_sheng_yu = 0.0
	yu._su_du_sheng_yu = 0.0
	yu._chong_zhuang_sheng_yu = 0.0
	yu.dang_qian_su_du = 0.0
	yu.dang_qian_jiao = 0.0
	yu.fang_xiang = Vector2.ZERO
	yu.position = Vector2(600, 600)
	yu.set_meta(&"zs_liu_xing_yue_tiao_sheng", 0.0)
	yu.set_meta(&"zs_liu_xing_yue_yao_shang_sheng", 0.0)
	yu.set_meta(&"zs_shen_ju_chong_feng_sheng_yu", 0.0)
	yu.set_meta(&"zs_shen_ju_chong_feng_fang", Vector2.RIGHT)
	yu.set_meta(&"zs_shen_ju_chong_feng_su_du", 0.0)
	yu.set_meta(&"zs_shen_ju_chong_feng_ming_zhong", false)
	yu.set_meta(&"zs_lei_yan_suo_ding_mu", 0)
	yu.set_meta(&"zs_lei_yan_suo_ding_leng_que", 0.0)


func _zao_yu(ti: int) -> YuNpc:
	# 造一条站着不动的靶鱼：先定住再进树；_ready 之后覆盖体型并同步视觉/判定圈
	var npc: YuNpc = load("res://scenes/YuNpc.tscn").instantiate()
	npc.sudu = 0.0
	npc.ai_kai_qi = false
	npc.position = Vector2(2000, 2000)
	add_child(npc)
	npc.tixing = ti
	npc._ying_she_ti_xing()
	_npc_lie.append(npc)
	return npc


# ---- 边界 ----

func _ce_bian_jie() -> void:
	# 形态不匹配：基础形态（未进化）下专属主动不可用、放不出、不写冷却
	_qing_chi()
	ZhangBen.chong_zhi()
	_ce("边界：大眼金枪鱼开局形态装配", ZhangBen.kai_ju_xing_tai(load("res://data/xingtai/zong_yu.tres")))
	ZhangBen.deng_ji = 6
	ZhangBen.dang_qian_ti_xing = ZhangBen.ti_xing_shang_xian()
	yu.scale = yu._ti_xing_vector()
	var neng: NengLi = load("res://data/nengli/liu_xing_yue.tres")
	_ce("边界：基础形态能力归属不可用", not ZhangBen.neng_li_ke_yong(neng))
	_ce("边界：基础形态主动放不出", not yu.shi_fang_zhu_dong(neng))
	_ce_xiang("边界：空放不扣冷却", yu.leng_que_sheng(&"liu_xing_yue"), 0.0)
	# 千眼空放：形态正确但视野里没有目标 → false，不扣冷却
	_kai_form(&"qian_yan_lei_po_yu")
	var qian: NengLi = load("res://data/nengli/qian_yan_qi_she.tres")
	_ce("边界：千眼无目标空放", not yu.shi_fang_zhu_dong(qian))
	_ce_xiang("边界：千眼空放不扣冷却", yu.leng_que_sheng(&"qian_yan_qi_she"), 0.0)


# ---- 主动 1：流星跃 ----

func _ce_liu_xing_yue() -> void:
	_kai_form(&"wen_yao_zhan_wei")
	var neng: NengLi = load("res://data/nengli/liu_xing_yue.tres")
	ZhangBen.xuan_neng_li(neng)
	var sw := yu._shen_wei()
	var npc := _zao_yu(5)
	npc.position = yu.position + Vector2(sw, 0.0)
	npc._ying_she_ti_xing()
	var ti0 := npc.tixing
	_ce("流星跃：释放成功", yu.shi_fang_zhu_dong(neng))
	_ce_xiang("流星跃：冷却=20×0.85", yu.leng_que_sheng(&"liu_xing_yue"), 17.0)
	_ce_xiang("流星跃：滑翔 1.5 秒", float(yu.get_meta(&"zs_liu_xing_yue_tiao_sheng", 0.0)), neng.chi_xu)
	_ce("流星跃：滑翔期霸体", yu.wudi)
	_ce("流星跃：滑翔期逆流无敌覆盖", yu._ni_liu_sheng_yu >= neng.chi_xu - 0.0001)
	_ce("流星跃：冷却中不可再放", not yu.shi_fang_zhu_dong(neng))
	yu._geng_xin_zhuan_shu(neng.chi_xu)
	_ce_xiang("流星跃：冲击波掉肉 1 级", ti0 - npc.tixing, neng.shu_zhi)
	_ce_xiang("流星跃：击退 2 身位（1→3）", yu.global_position.distance_to(npc.global_position),
			sw * (1.0 + neng.npc_shu_zhi))
	_ce("流星跃：落地解除霸体", not yu.wudi)
	_ce_xiang("流星跃：落地咬伤窗 1 秒", float(yu.get_meta(&"zs_liu_xing_yue_yao_shang_sheng", 0.0)), 1.0)
	_ce_xiang("流星跃：落地咬伤 +25%", ZHUAN_SHU.wen(yu, &"yao_shang_bei", {"mu": npc, "bu": "shen"}),
			1.0 + neng.fu_shu_zhi / 100.0)
	yu._geng_xin_zhuan_shu(1.0)
	_ce_xiang("流星跃：1 秒后咬伤回落", ZHUAN_SHU.wen(yu, &"yao_shang_bei", {"mu": npc, "bu": "shen"}), 1.0)


# ---- 主动 2：神驹冲锋 ----

func _ce_shen_ju_chong_feng() -> void:
	_kai_form(&"hai_shen_xun_yang_ju")
	var neng: NengLi = load("res://data/nengli/shen_ju_chong_feng.tres")
	ZhangBen.xuan_neng_li(neng)
	var sw := yu._shen_wei()
	var npc := _zao_yu(5)
	npc.position = yu.position + Vector2(sw * 2.0, 0.0)
	npc._ying_she_ti_xing()
	var ti0 := npc.tixing
	var qi := yu.position
	yu.fang_xiang = Vector2.RIGHT
	_ce("神驹：释放成功", yu.shi_fang_zhu_dong(neng))
	_ce_xiang("神驹：冷却 18", yu.leng_que_sheng(&"shen_ju_chong_feng"), neng.leng_que)
	_ce("神驹：冲刺霸体", yu.wudi)
	_ce_xiang("神驹：冲刺窗口 0.35", float(yu.get_meta(&"zs_shen_ju_chong_feng_sheng_yu", 0.0)), neng.chi_xu)
	yu._geng_xin_zhuan_shu(0.4)
	_ce_xiang("神驹：首目标 1.5 级伤害", ti0 - npc.tixing, neng.shu_zhi)
	_ce("神驹：首目标束缚", npc.you_zhuang_tai(&"shu_fu"))
	_ce_xiang("神驹：束缚 1 秒", npc.zhuang_tai_sheng_yu(&"shu_fu"), neng.fu_shu_zhi)
	_ce_xiang("神驹：冲刺 3 身位", qi.distance_to(yu.position), sw * neng.ban_jing)
	_ce("神驹：撞停后霸体解除", not yu.wudi)
	_ce_xiang("神驹：冲刺结束清零", float(yu.get_meta(&"zs_shen_ju_chong_feng_sheng_yu", 0.0)), 0.0)
	# 首领子用例：吃伤害但不吃束缚
	_qing_chi()
	yu.scale = yu._ti_xing_vector()
	yu.position = Vector2(600, 600)
	yu.fang_xiang = Vector2.RIGHT
	var boss := _zao_yu(5)
	boss.shi_boss = true
	boss.position = yu.position + Vector2(yu._shen_wei() * 1.5, 0.0)
	boss._ying_she_ti_xing()
	var bti := boss.tixing
	_ce("神驹：BOSS 场景释放", yu.shi_fang_zhu_dong(neng))
	yu._geng_xin_zhuan_shu(0.4)
	_ce_xiang("神驹：BOSS 吃 1.5 级伤害", bti - boss.tixing, neng.shu_zhi)
	_ce("神驹：BOSS 免疫束缚", not boss.you_zhuang_tai(&"shu_fu"))


# ---- 主动 3：千眼齐射 ----

func _ce_qian_yan_qi_she() -> void:
	_kai_form(&"qian_yan_lei_po_yu")
	var neng: NengLi = load("res://data/nengli/qian_yan_qi_she.tres")
	ZhangBen.xuan_neng_li(neng)
	var sw := yu._shen_wei()
	var npc1 := _zao_yu(6)
	npc1.position = yu.position + Vector2(sw * 1.0, 0.0)
	var npc2 := _zao_yu(6)
	npc2.position = yu.position + Vector2(sw * 2.0, 0.0)
	var npc3 := _zao_yu(6)
	npc3.position = yu.position + Vector2(sw * 3.0, 0.0)
	var npc4 := _zao_yu(6)
	npc4.position = yu.position + Vector2(sw * 4.0, 0.0)
	for npc in [npc1, npc2, npc3, npc4]:
		npc._ying_she_ti_xing()
	var ti1 := npc1.tixing
	var ti2 := npc2.tixing
	var ti3 := npc3.tixing
	var ti4 := npc4.tixing
	_ce("千眼：释放成功", yu.shi_fang_zhu_dong(neng))
	_ce_xiang("千眼：冷却 22", yu.leng_que_sheng(&"qian_yan_qi_she"), neng.leng_que)
	_ce_xiang("千眼：最近目标掉肉 0.3", ti1 - npc1.tixing, neng.shu_zhi)
	_ce_xiang("千眼：第二目标掉肉 0.3", ti2 - npc2.tixing, neng.shu_zhi)
	_ce_xiang("千眼：第三目标掉肉 0.3", ti3 - npc3.tixing, neng.shu_zhi)
	_ce_xiang("千眼：第四目标不受伤", npc4.tixing, ti4)
	_ce_xiang("千眼：目标一电麻 40", npc1.dian_ma, neng.fu_shu_zhi)
	_ce_xiang("千眼：目标二电麻 40", npc2.dian_ma, neng.fu_shu_zhi)
	_ce_xiang("千眼：目标三电麻 40", npc3.dian_ma, neng.fu_shu_zhi)
	_ce_xiang("千眼：第四目标不电麻", npc4.dian_ma, 0.0)
	# 首领按普通 NPC 处理：掉肉 + 电麻
	_qing_chi()
	yu.scale = yu._ti_xing_vector()
	yu.position = Vector2(600, 600)
	var boss := _zao_yu(7)
	boss.shi_boss = true
	boss.position = yu.position + Vector2(yu._shen_wei(), 0.0)
	boss._ying_she_ti_xing()
	var bt := boss.tixing
	_ce("千眼：BOSS 场景释放", yu.shi_fang_zhu_dong(neng))
	# 契约：无视防御的直伤对首领减半——0.3 × 0.5 = 0.15
	_ce_xiang("千眼：BOSS 掉肉 0.15（首领减半）", bt - boss.tixing, neng.shu_zhi * 0.5)
	_ce_xiang("千眼：BOSS 电麻 40", boss.dian_ma, neng.fu_shu_zhi)


# ---- 被动 1：顺风翼 ----

func _ce_shun_feng_yi() -> void:
	_kai_form(&"wen_yao_zhan_wei")
	var neng: NengLi = load("res://data/nengli/shun_feng_yi.tres")
	ZhangBen.xuan_neng_li(neng)
	_ce("顺风翼：被动叠 1 层", ZhangBen.dang_qian_bei_dong_ceng(&"shun_feng_yi") == 1)
	_ce_xiang("顺风翼：游速 ×1.2", ZHUAN_SHU.wen(yu, &"su_du_bei", {}), neng.shu_zhi)
	var ji := maxf(SHU_ZHI.SU_DU_ZUI_DI_BI,
			1.0 - SHU_ZHI.MEI_JI_JIAN_SU * float(maxi(ZhangBen.deng_ji, 0)))
	_ce_xiang("顺风翼：速度倍率入口叠加", yu._ti_xing_su_du_bi(), ji * neng.shu_zhi)
	var zd: NengLi = load("res://data/nengli/liu_xing_yue.tres")
	_ce_xiang("顺风翼：主动冷却 ×0.85", ZHUAN_SHU.wen(yu, &"leng_que_bei", {"neng": zd}),
			1.0 - neng.fu_shu_zhi / 100.0)


# ---- 被动 2：骨质重甲 ----

func _ce_gu_zhi_zhong_jia() -> void:
	_kai_form(&"hai_shen_xun_yang_ju")
	var neng: NengLi = load("res://data/nengli/gu_zhi_zhong_jia.tres")
	ZhangBen.xuan_neng_li(neng)
	_ce("骨质重甲：被动叠 1 层", ZhangBen.dang_qian_bei_dong_ceng(&"gu_zhi_zhong_jia") == 1)
	_ce_xiang("骨质重甲：受伤 ×0.75",
			ZHUAN_SHU.wen(yu, &"shou_shang_bei", {"lai_yuan": null, "shang_hai": 10.0, "bu": "shen"}),
			neng.shu_zhi)
	var npc := _zao_yu(5)
	npc.position = yu.position + Vector2(yu._shen_wei() * 1.5, 0.0)
	npc._ying_she_ti_xing()
	var ti0 := npc.tixing
	# 真实受击入口：10 伤害 → 减伤后 7.5 → 反弹 0.75 给咬击者
	yu.shou_dao_yao_ji(10.0, npc, "shen")
	_ce_xiang("骨质重甲：反弹 10% 给咬击者", ti0 - npc.tixing,
			10.0 * neng.shu_zhi * (neng.fu_shu_zhi / 100.0))
	# 来源是自己：不反弹（避免自己打自己死循环）
	_qing_chi()
	yu.scale = yu._ti_xing_vector()
	yu.position = Vector2(600, 600)
	ZhangBen.hui_ti_xing(ZhangBen.ti_xing_shang_xian())
	var npc2 := _zao_yu(5)
	npc2.position = yu.position + Vector2(yu._shen_wei() * 1.5, 0.0)
	npc2._ying_she_ti_xing()
	var ti2 := npc2.tixing
	yu.shou_dao_yao_ji(10.0, yu, "shen")
	_ce_xiang("骨质重甲：来源为自己不反弹", npc2.tixing, ti2)


# ---- 被动 3：雷眼锁定 ----

func _ce_lei_yan_suo_ding() -> void:
	_kai_form(&"qian_yan_lei_po_yu")
	var neng: NengLi = load("res://data/nengli/lei_yan_suo_ding.tres")
	ZhangBen.xuan_neng_li(neng)
	_ce("雷眼：被动叠 1 层", ZhangBen.dang_qian_bei_dong_ceng(&"lei_yan_suo_ding") == 1)
	var sw := yu._shen_wei()
	var jin := _zao_yu(5)
	jin.position = yu.position + Vector2(sw * 2.0, 0.0)
	jin._ying_she_ti_xing()
	var yuan := _zao_yu(5)
	yuan.position = yu.position + Vector2(sw * 6.0, 0.0)
	yuan._ying_she_ti_xing()
	yu._geng_xin_zhuan_shu(0.1)
	_ce("雷眼：锁定最远目标",
			int(yu.get_meta(&"zs_lei_yan_suo_ding_mu", 0)) == int(yuan.get_instance_id()))
	_ce_xiang("雷眼：最远目标 +25%",
			ZHUAN_SHU.wen(yu, &"yao_shang_bei", {"mu": yuan, "bu": "shen"}),
			1.0 + neng.shu_zhi / 100.0)
	_ce_xiang("雷眼：近目标不加成",
			ZHUAN_SHU.wen(yu, &"yao_shang_bei", {"mu": jin, "bu": "shen"}), 1.0)
	# 目标互换位置：1 秒静默期内仍锁旧目标
	jin.position = yu.position + Vector2(sw * 10.0, 0.0)
	yuan.position = yu.position + Vector2(sw * 1.0, 0.0)
	yu._geng_xin_zhuan_shu(0.1)
	_ce("雷眼：1 秒内不重锁",
			int(yu.get_meta(&"zs_lei_yan_suo_ding_mu", 0)) == int(yuan.get_instance_id()))
	_ce_xiang("雷眼：静默期仍按旧锁生效",
			ZHUAN_SHU.wen(yu, &"yao_shang_bei", {"mu": yuan, "bu": "shen"}),
			1.0 + neng.shu_zhi / 100.0)
	# 静默期结束：改锁新的最远目标（jin 现在最远）
	yu._geng_xin_zhuan_shu(1.0)
	_ce("雷眼：1 秒后改锁新最远",
			int(yu.get_meta(&"zs_lei_yan_suo_ding_mu", 0)) == int(jin.get_instance_id()))
	_ce_xiang("雷眼：新锁 +25%",
			ZHUAN_SHU.wen(yu, &"yao_shang_bei", {"mu": jin, "bu": "shen"}),
			1.0 + neng.shu_zhi / 100.0)
	_ce_xiang("雷眼：旧目标回落",
			ZHUAN_SHU.wen(yu, &"yao_shang_bei", {"mu": yuan, "bu": "shen"}), 1.0)
