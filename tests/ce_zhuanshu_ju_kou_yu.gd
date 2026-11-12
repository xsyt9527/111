extends Node2D
# 巨口鱼（ju_kou_yu）专属技自测（场景模式：Autoload 全就位，走正式装备/进化入口）
# 覆盖：6 条 .tres 字段 / 3 个进化形态槽位 / 3 条主动释放+冷却+核心效果
#       3 条被动核心断言 / 边界（形态不匹配、boss 免疫束缚与恐惧）
# 纪律：失败只 print("FAIL: ...")；收卷打印 Results 并 get_tree().quit(1 if failed > 0 else 0)
# 运行：Godot --headless --path . res://tests/ce_zhuanshu_ju_kou_yu_chang_jing.tscn --quit-after 600

var passed := 0
var failed := 0
var yu: Yu
var _npcs: Array[YuNpc] = []

const ZHUAN_SHU_KU := preload("res://scripts/zhuan_shu_ku.gd")
const JU_KOU_XING_TAI := preload("res://data/xingtai/ju_kou_yu.tres")

# 与模块一致的 meta 键：测试直接读窗口/记录表做断言
const META_TAO_TIE_SHENG := &"zs_tao_tie_ju_tun_sheng_yu"
const META_TAO_TIE_TU := &"zs_tao_tie_ju_tun_tu"
const META_LIE_KOU_SHENG := &"zs_lie_kou_xian_jing_sheng_yu"
const META_LIE_KOU_MU_BIAO := &"zs_lie_kou_xian_jing_mu_biao"
const META_LIE_KOU_TU := &"zs_lie_kou_xian_jing_tu"
const META_GANG_TIE_YAO_QIAN := &"zs_gang_tie_liao_ya_yao_qian"
const META_JI_CI_JI_SHI := &"zs_ji_ci_kou_nei_ji_shi"


func _ready() -> void:
	var shu := get_tree()
	# 饥饿时钟会干扰精确断言：账本整帧处理关掉，方法调用照常
	ZhangBen.process_mode = Node.PROCESS_MODE_DISABLED
	yu = load("res://scenes/Yu.tscn").instantiate()
	yu.position = Vector2(400.0, 640.0)
	add_child(yu)
	yu.set_process(false)  # 关闭玩家自动流程：测试手动调 _geng_xin_zhuan_shu，节拍完全可复现
	yu.zi_dong_yao_ji = false
	await get_tree().physics_frame
	await get_tree().physics_frame

	_ce_shu_ju()
	_ce_xing_tai()
	await _ce_tao_tie()
	_ce_lie_kou()
	_ce_she_hun()
	_ce_gang_tie()
	_ce_ji_ci()
	_ce_kong_ju()
	_ce_bian_jie()

	_qing_chang()
	_qing_meta()
	ZhangBen.chong_zhi()
	print("Results: %d passed, %d failed" % [passed, failed])
	shu.quit(1 if failed > 0 else 0)


# ---- 用例 1：6 条能力数据字段 ----

func _ce_shu_ju() -> void:
	var biao := [
		{
			"id": &"tao_tie_ju_tun", "xing": &"tao_tie_tun_hai_shou", "xing_lei": 0,
			"leng_que": 25.0, "chi_xu": 4.0, "ban_jing": 0.0, "shu_zhi": 1.3, "fu": 0.0,
			"shen_wei": false,
		},
		{
			"id": &"lie_kou_xian_jing", "xing": &"shen_yuan_lie_kou_guai", "xing_lei": 0,
			"leng_que": 22.0, "chi_xu": 4.0, "ban_jing": 1.0, "shu_zhi": 2.0, "fu": 0.7,
			"shen_wei": true,
		},
		{
			"id": &"she_hun", "xing": &"ling_hun_xi_shi_zhe", "xing_lei": 0,
			"leng_que": 15.0, "chi_xu": 0.0, "ban_jing": 5.0, "shu_zhi": 0.3, "fu": 10.0,
			"shen_wei": true,
		},
		{
			"id": &"gang_tie_liao_ya", "xing": &"tao_tie_tun_hai_shou", "xing_lei": 1,
			"leng_que": 0.0, "chi_xu": 0.0, "ban_jing": 0.0, "shu_zhi": 30.0, "fu": 0.2,
			"shen_wei": false,
		},
		{
			"id": &"ji_ci_kou_nei", "xing": &"shen_yuan_lie_kou_guai", "xing_lei": 1,
			"leng_que": 0.0, "chi_xu": 0.0, "ban_jing": 0.0, "shu_zhi": 0.1, "fu": 0.5,
			"shen_wei": false,
		},
		{
			"id": &"kong_ju_zhi_kou", "xing": &"ling_hun_xi_shi_zhe", "xing_lei": 1,
			"leng_que": 0.0, "chi_xu": 0.0, "ban_jing": 0.0, "shu_zhi": 2.0, "fu": 0.0,
			"shen_wei": false,
		},
	]
	for hang in biao:
		var bian: StringName = hang["id"]
		var neng: NengLi = load("res://data/nengli/%s.tres" % String(bian))
		_dui(neng != null, "%s：资源可加载" % String(bian))
		if neng == null:
			continue
		_dui(neng.bian_hao == bian, "%s：bian_hao 与文件名一致" % String(bian))
		_dui(neng.ming_zi != "", "%s：ming_zi 非空" % String(bian))
		_dui(neng.miao_shu != "" and neng.miao_shu.length() <= 110, "%s：miao_shu ≤110 字" % String(bian))
		_dui(neng.lai_yuan == "巨口鱼", "%s：lai_yuan=巨口鱼" % String(bian))
		_dui(neng.suoshu_xing_tai == hang["xing"], "%s：绑定形态正确" % String(bian))
		_dui(neng.lei_xing == int(hang["xing_lei"]), "%s：lei_xing 正确" % String(bian))
		_dui(neng.zui_da_dang == 1, "%s：zui_da_dang=1" % String(bian))
		_dui(neng.dang_biao.is_empty(), "%s：档位表留空" % String(bian))
		if neng.shi_zhu_dong():
			_dui(neng.tu_biao != null, "%s：主动图标已接入" % String(bian))
		else:
			_dui(neng.tu_biao == null, "%s：被动图标待补（留空）" % String(bian))
		_dui(_jin(neng.leng_que, float(hang["leng_que"])), "%s：leng_que 正确" % String(bian))
		_dui(_jin(neng.chi_xu, float(hang["chi_xu"])), "%s：chi_xu 正确" % String(bian))
		_dui(_jin(neng.ban_jing, float(hang["ban_jing"])), "%s：ban_jing 正确" % String(bian))
		_dui(_jin(neng.shu_zhi, float(hang["shu_zhi"])), "%s：shu_zhi 正确" % String(bian))
		_dui(_jin(neng.fu_shu_zhi, float(hang["fu"])), "%s：fu_shu_zhi 正确" % String(bian))
		_dui(neng.ban_jing_shen_wei == bool(hang["shen_wei"]), "%s：ban_jing_shen_wei 正确" % String(bian))
		if neng.shi_zhu_dong():
			_dui(neng.leng_que > 0.0 and neng.shu_zhi > 0.0, "%s：主动冷却/主值>0" % String(bian))
		else:
			_dui(neng.shu_zhi > 0.0, "%s：被动主值>0" % String(bian))


# ---- 用例 2：3 个进化形态槽位 ----

func _ce_xing_tai() -> void:
	var biao := [
		{"form": &"tao_tie_tun_hai_shou", "zhu": &"tao_tie_ju_tun", "bei": &"gang_tie_liao_ya"},
		{"form": &"shen_yuan_lie_kou_guai", "zhu": &"lie_kou_xian_jing", "bei": &"ji_ci_kou_nei"},
		{"form": &"ling_hun_xi_shi_zhe", "zhu": &"she_hun", "bei": &"kong_ju_zhi_kou"},
	]
	for hang in biao:
		var form: JinHua = load("res://data/jinhua/%s.tres" % String(hang["form"]))
		_dui(form != null, "%s：形态资源可加载" % String(hang["form"]))
		if form == null:
			continue
		_dui(form.zhuan_shu_zhu_dong != null, "%s：专属主动槽非空" % String(hang["form"]))
		_dui(form.zhuan_shu_bei_dong != null, "%s：专属被动槽非空" % String(hang["form"]))
		if form.zhuan_shu_zhu_dong != null:
			_dui(form.zhuan_shu_zhu_dong.bian_hao == hang["zhu"], "%s：主动槽 id 对上" % String(hang["form"]))
		if form.zhuan_shu_bei_dong != null:
			_dui(form.zhuan_shu_bei_dong.bian_hao == hang["bei"], "%s：被动槽 id 对上" % String(hang["form"]))
		_dui(form.ji_yu_bian_hao == &"ju_kou_yu", "%s：仍属巨口鱼" % String(hang["form"]))


# ---- 用例 3：饕餮巨吞（主动）----

func _ce_tao_tie() -> void:
	_kai_form(&"tao_tie_tun_hai_shou")
	var neng: NengLi = load("res://data/nengli/tao_tie_ju_tun.tres")
	_dui(ZhangBen.zhuang_lei(&"tao_tie_ju_tun"), "进化后自动装备饕餮巨吞")
	_dui(ZhangBen.dang_qian_bei_dong_ceng(&"gang_tie_liao_ya") == 1, "进化后自动装备钢铁獠牙")

	# 两条靶鱼对比 1.1 门槛：9 级原本就能吞，11.5 级原本吞不下
	var xiao := _zao_yu(9.0, Vector2(1000.0, 1000.0))
	var da := _zao_yu(11.5, Vector2(1000.0, 300.0))
	_dui(_jin(ZHUAN_SHU_KU.wen(yu, &"tun_men_kan", {"mu": da}), 1.0), "窗口外：吞噬倍率 1.0")
	_dui(_neng_tun(xiao, 1.0), "窗口外：9 级鱼在门槛内")
	_dui(not _neng_tun(da, 1.0), "窗口外：11.5 级鱼超出 1.1 门槛")

	# 让大鱼进嘴圈，先确认窗口外吞不下（真实物理重叠）
	da.global_position = yu.global_position + Vector2(12.0, 0.0)
	yu.wudi = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	yu._chi_zui_bian()
	_dui(is_instance_valid(da) and not da.si_le, "窗口外：嘴圈里的大鱼吞不下")

	_dui(yu.shi_fang_zhu_dong(neng), "饕餮巨吞释放成功")
	_dui(_jin(yu.leng_que_sheng(&"tao_tie_ju_tun"), 25.0), "饕餮巨吞冷却 25 秒")
	var bei1 := ZHUAN_SHU_KU.wen(yu, &"tun_men_kan", {"mu": da})
	_dui(_jin(bei1, 1.3), "窗口内：吞噬倍率 1.3")
	_dui(_neng_tun(da, bei1), "窗口内：11.5 级大鱼进入放宽门槛")
	_dui(_neng_tun(xiao, bei1), "窗口内：9 级小鱼仍可吞")

	yu._chi_zui_bian()
	_dui(is_instance_valid(da) and da.si_le, "窗口内：嘴圈里的大鱼被整吞")
	yu._geng_xin_zhuan_shu(4.1)
	_dui(_jin(ZHUAN_SHU_KU.wen(yu, &"tun_men_kan", {"mu": xiao}), 1.0), "4 秒后窗口结束：倍率回 1.0")
	yu.wudi = false


# ---- 用例 4：裂口陷阱（主动）----

func _ce_lie_kou() -> void:
	_kai_form(&"shen_yuan_lie_kou_guai")
	var neng: NengLi = load("res://data/nengli/lie_kou_xian_jing.tres")
	_dui(ZhangBen.zhuang_lei(&"lie_kou_xian_jing"), "进化后自动装备裂口陷阱")
	_dui(ZhangBen.dang_qian_bei_dong_ceng(&"ji_ci_kou_nei") == 1, "进化后自动装备棘刺口内")

	# 空场也允许放：原地张口不是锁定技
	_dui(yu.shi_fang_zhu_dong(neng), "裂口陷阱无目标也可释放")
	_dui(_jin(yu.leng_que_sheng(&"lie_kou_xian_jing"), 22.0), "裂口陷阱冷却 22 秒")

	yu.zhu_dong_leng_que.clear()
	var npc := _zao_yu(3.0, yu.global_position + Vector2(60.0, 0.0))
	_dui(yu.shi_fang_zhu_dong(neng), "裂口陷阱再次释放")
	yu._geng_xin_zhuan_shu(0.0)
	_dui(npc.you_zhuang_tai(&"shu_fu"), "1 身位内 NPC 被咬住束缚")
	_dui(_jin(npc.zhuang_tai_sheng_yu(&"shu_fu"), 2.0), "束缚时长 2 秒")
	var ji_lu: Array = yu.get_meta(META_LIE_KOU_MU_BIAO, [])
	_dui(ji_lu.has(npc.get_instance_id()), "被束缚目标记入 meta")
	_dui(_jin(ZHUAN_SHU_KU.wen(yu, &"su_du_bei", {}), 0.7), "张口期间游速倍率 0.7")

	npc._zou_zhuang_tai(2.05)
	_dui(not npc.you_zhuang_tai(&"shu_fu"), "束缚 2 秒后自然解除")
	yu._geng_xin_zhuan_shu(2.1)
	_dui(_jin(ZHUAN_SHU_KU.wen(yu, &"su_du_bei", {}), 0.7), "4 秒窗口内已解绑仍降速")
	yu._geng_xin_zhuan_shu(2.0)
	_dui(_jin(ZHUAN_SHU_KU.wen(yu, &"su_du_bei", {}), 1.0), "窗口结束游速恢复")

	# boss 免疫束缚：状态层内部挡下
	_qing_chang()
	yu.zhu_dong_leng_que.clear()
	var boss := _zao_yu(5.0, yu.global_position + Vector2(60.0, 0.0))
	boss.shi_boss = true
	_dui(yu.shi_fang_zhu_dong(neng), "裂口陷阱在 boss 场景仍可释放")
	yu._geng_xin_zhuan_shu(0.0)
	_dui(not boss.you_zhuang_tai(&"shu_fu"), "boss 免疫束缚")
	_dui(_jin(ZHUAN_SHU_KU.wen(yu, &"su_du_bei", {}), 0.7), "对 boss 释放仍进入减速窗口")
	yu._geng_xin_zhuan_shu(4.1)


# ---- 用例 5：摄魂（主动）----

func _ce_she_hun() -> void:
	_kai_form(&"ling_hun_xi_shi_zhe")
	var neng: NengLi = load("res://data/nengli/she_hun.tres")
	_dui(ZhangBen.zhuang_lei(&"she_hun"), "进化后自动装备摄魂")
	_dui(ZhangBen.dang_qian_bei_dong_ceng(&"kong_ju_zhi_kou") == 1, "进化后自动装备恐惧之口")

	_dui(not yu.shi_fang_zhu_dong(neng), "摄魂无目标时空放失败")
	_dui(_jin(yu.leng_que_sheng(&"she_hun"), 0.0), "空放不扣冷却")

	# 玩家先放低体型，才能观察到 0.3 级回复
	ZhangBen.dang_qian_ti_xing = ZhangBen.ti_xing_shang_xian() - 1.0
	var npc := _zao_yu(3.0, yu.global_position + Vector2(yu._shen_wei() * 2.0, 0.0))
	var xp_qian := ZhangBen.jing_yan
	var ti_qian := ZhangBen.dang_qian_ti_xing
	_dui(yu.shi_fang_zhu_dong(neng), "摄魂释放成功")
	_dui(_jin(yu.leng_que_sheng(&"she_hun"), 15.0), "摄魂冷却 15 秒")
	_dui(_jin(npc.tixing, 2.7), "目标掉 0.3 级体型")
	_dui(_jin(ZhangBen.dang_qian_ti_xing, ti_qian + 0.3), "玩家回 0.3 级体型")
	_dui(ZhangBen.jing_yan == xp_qian + 10, "玩家获得固定 10 点经验")

	# boss 跳过：范围内只剩 boss 时放不出
	_qing_chang()
	yu.zhu_dong_leng_que.clear()
	var boss := _zao_yu(5.0, yu.global_position + Vector2(100.0, 0.0))
	boss.shi_boss = true
	var boss_ti := boss.tixing
	_dui(not yu.shi_fang_zhu_dong(neng), "范围内只有 boss：摄魂空放")
	_dui(_jin(boss.tixing, boss_ti), "boss 未被摄魂")


# ---- 用例 6：钢铁獠牙（被动）----

func _ce_gang_tie() -> void:
	_kai_form(&"tao_tie_tun_hai_shou")
	var npc := _zao_yu(3.0, Vector2(1000.0, 1000.0))
	_dui(_jin(ZHUAN_SHU_KU.wen(yu, &"yao_shang_bei", {"mu": npc, "bu": "shen"}), 1.3),
			"钢铁獠牙：咬伤倍率 1.3")

	# 复现真实咬击顺序：倍率查询（记咬前体型）→ 扣血 → yao_zhong 事件
	npc.shou_dao_yao_ji(0.09, yu, "shen")
	_dui(_jin(npc.tixing, 2.91), "轻咬先按原伤害扣 0.09")
	ZHUAN_SHU_KU.shi_jian(yu, &"yao_zhong", {"mu": npc, "bu": "shen", "shang_hai": 0.09})
	_dui(_jin(npc.tixing, 2.8), "补足到每次至少掉 0.2 级")

	# 咬得够狠：不额外补刀（避免二次扣血）
	var npc2 := _zao_yu(3.0, Vector2(1000.0, 800.0))
	_dui(_jin(ZHUAN_SHU_KU.wen(yu, &"yao_shang_bei", {"mu": npc2, "bu": "shen"}), 1.3),
			"钢铁獠牙：对第二条鱼仍 1.3 倍")
	npc2.shou_dao_yao_ji(0.5, yu, "shen")
	ZHUAN_SHU_KU.shi_jian(yu, &"yao_zhong", {"mu": npc2, "bu": "shen", "shang_hai": 0.5})
	_dui(_jin(npc2.tixing, 2.5), "重咬 0.5 不额外补刀")

	# boss 也可补足：掉肉不整吞
	var boss := _zao_yu(3.0, Vector2(1000.0, 600.0))
	boss.shi_boss = true
	_dui(_jin(ZHUAN_SHU_KU.wen(yu, &"yao_shang_bei", {"mu": boss, "bu": "shen"}), 1.3),
			"钢铁獠牙：对 boss 咬伤仍 1.3 倍")
	boss.shou_dao_yao_ji(0.09, yu, "shen")
	ZHUAN_SHU_KU.shi_jian(yu, &"yao_zhong", {"mu": boss, "bu": "shen", "shang_hai": 0.09})
	_dui(_jin(boss.tixing, 2.8), "boss 也补足 0.2 级掉肉")


# ---- 用例 7：棘刺口内（被动）----

func _ce_ji_ci() -> void:
	_kai_form(&"shen_yuan_lie_kou_guai")
	_dui(ZhangBen.dang_qian_bei_dong_ceng(&"ji_ci_kou_nei") == 1, "棘刺口内已装备")
	var npc := _zao_yu(3.0, Vector2(900.0, 900.0))
	var npc2 := _zao_yu(3.0, Vector2(900.0, 300.0))
	_dui(npc.jia_zhuang_tai(&"shu_fu", 2.0), "靶鱼进入束缚状态")

	yu._geng_xin_zhuan_shu(0.25)
	yu._geng_xin_zhuan_shu(0.25)
	_dui(_jin(npc.tixing, 2.9), "0.5 秒节拍到：被束缚目标掉 0.1")
	_dui(_jin(npc2.tixing, 3.0), "未被束缚目标不掉肉")

	yu._geng_xin_zhuan_shu(0.25)
	yu._geng_xin_zhuan_shu(0.25)
	_dui(_jin(npc.tixing, 2.8), "再过 0.5 秒再掉 0.1（每秒 0.2）")

	npc._zou_zhuang_tai(2.05)
	yu._geng_xin_zhuan_shu(0.5)
	_dui(not npc.you_zhuang_tai(&"shu_fu"), "束缚计时已结束")
	_dui(_jin(npc.tixing, 2.8), "束缚结束后不再掉肉")


# ---- 用例 8：恐惧之口（被动）----

func _ce_kong_ju() -> void:
	_kai_form(&"ling_hun_xi_shi_zhe")
	_dui(ZhangBen.dang_qian_bei_dong_ceng(&"kong_ju_zhi_kou") == 1, "恐惧之口已装备")
	var npc := _zao_yu(3.0, Vector2(900.0, 900.0))
	var chi_diao := ZHUAN_SHU_KU.shi_jian(yu, &"yao_zhong", {"mu": npc, "bu": "shen", "shang_hai": 0.3})
	_dui(not chi_diao, "恐惧之口不吃掉咬中事件")
	_dui(npc.you_zhuang_tai(&"kong_ju"), "被命中目标进入恐惧")
	_dui(_jin(npc.zhuang_tai_sheng_yu(&"kong_ju"), 2.0), "恐惧持续 2 秒")

	var boss := _zao_yu(3.0, Vector2(900.0, 300.0))
	boss.shi_boss = true
	ZHUAN_SHU_KU.shi_jian(yu, &"yao_zhong", {"mu": boss, "bu": "shen", "shang_hai": 0.3})
	_dui(not boss.you_zhuang_tai(&"kong_ju"), "boss 免疫恐惧")


# ---- 用例 9：边界（形态不匹配 / 被动不串味）----

func _ce_bian_jie() -> void:
	_kai_form(&"tao_tie_tun_hai_shou")
	var lie: NengLi = load("res://data/nengli/lie_kou_xian_jing.tres")
	_dui(not ZhangBen.neng_li_ke_yong(lie), "形态不匹配：裂口陷阱不可用")
	_dui(not yu.shi_fang_zhu_dong(lie), "形态不匹配：主动放不出")
	ZhangBen.xuan_neng_li(lie)
	_dui(not ZhangBen.zhuang_lei(&"lie_kou_xian_jing"), "形态不匹配：装不进主动槽")

	var kong: NengLi = load("res://data/nengli/kong_ju_zhi_kou.tres")
	_dui(not ZhangBen.neng_li_ke_yong(kong), "形态不匹配：恐惧之口不可用")
	ZhangBen.xuan_neng_li(kong)
	_dui(ZhangBen.dang_qian_bei_dong_ceng(&"kong_ju_zhi_kou") == 0, "形态不匹配：装不进被动层")

	# 未装备钢铁獠牙时咬伤倍率保持 1.0（不同形态不串味）
	_kai_form(&"ling_hun_xi_shi_zhe")
	var npc := _zao_yu(3.0, Vector2(900.0, 900.0))
	_dui(_jin(ZHUAN_SHU_KU.wen(yu, &"yao_shang_bei", {"mu": npc, "bu": "shen"}), 1.0),
			"灵魂形态下无钢铁獠牙：咬伤倍率 1.0")


# ---- 夹具与小工具 ----

func _kai_form(form_id: StringName) -> JinHua:
	# 清场 → 复位账本 → 巨口鱼开局 → Lv.6 满体型 → 走正式进化入口（自动装两条专属技）
	_qing_chang()
	_qing_meta()
	ZhangBen.chong_zhi()
	_dui(ZhangBen.kai_ju_xing_tai(JU_KOU_XING_TAI), "开局装配巨口鱼形态")
	ZhangBen.deng_ji = 6
	ZhangBen.dang_qian_ti_xing = ZhangBen.ti_xing_shang_xian()
	var form: JinHua = JinHuaKu.zhao(form_id)
	_dui(form != null, "进化形态存在：%s" % String(form_id))
	if form == null:
		return null
	_dui(ZhangBen.jin_hua_wei(form), "进化到 %s" % String(form_id))
	yu.scale = yu._ti_xing_vector()  # 跳过 0.25 秒缩放补间：测试要立刻读身位
	yu.zhu_dong_leng_que.clear()
	yu._nei_bu_leng_que.clear()
	yu._mei_ju_yong_ci.clear()
	yu.wudi = false
	return form


func _zao_yu(ti_xing: float, wei: Vector2) -> YuNpc:
	# 造一条站桩靶鱼：关 AI、零速、体型可控（与 ce_panding 夹具同口径）
	var npc: YuNpc = load("res://scenes/YuNpc.tscn").instantiate()
	npc.sudu = 0.0
	npc.ai_kai_qi = false
	npc.position = wei
	add_child(npc)
	npc.tixing = ti_xing
	npc._ying_she_ti_xing()
	_npcs.append(npc)
	return npc


func _qing_chang() -> void:
	# 清掉本用例造的所有靶鱼：先立死旗/退组，避免延迟释放期间被全场扫描读到
	for npc in _npcs:
		if is_instance_valid(npc):
			npc.si_le = true
			npc.remove_from_group("yu_npc")
			npc.queue_free()
	_npcs.clear()


func _qing_meta() -> void:
	# 复位模块 meta：窗口/节拍/快照/记录表全部归零，视觉节点顺手释放
	for jian in [META_TAO_TIE_TU, META_LIE_KOU_TU]:
		var tu = yu.get_meta(jian) if yu.has_meta(jian) else null
		if tu != null and is_instance_valid(tu):
			tu.queue_free()
	for jian in [META_TAO_TIE_SHENG, META_TAO_TIE_TU, META_LIE_KOU_SHENG,
			META_LIE_KOU_MU_BIAO, META_LIE_KOU_TU, META_GANG_TIE_YAO_QIAN, META_JI_CI_JI_SHI]:
		if yu.has_meta(jian):
			yu.remove_meta(jian)


func _neng_tun(npc: YuNpc, bei: float) -> bool:
	# 主流程同款吞噬门槛：玩家有效体型 ≥ 目标体型 ×1.1
	return yu.tixing * bei >= npc.tixing * Yu.TUN_CHI_BEI_LV


func _jin(shu: float, qi_wang: float, wu_cha := 0.001) -> bool:
	# 浮点断言：账本/体型都是 float，允许极小尾差
	return absf(shu - qi_wang) <= wu_cha


func _dui(tiao_jian: bool, biao_qian: String) -> void:
	# 记账员：失败只 print，不裸 assert()，不打印 ERROR 字样
	if tiao_jian:
		passed += 1
	else:
		failed += 1
		print("FAIL: " + biao_qian)
