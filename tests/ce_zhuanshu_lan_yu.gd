extends Node2D
# 钻光鱼（lan_yu）专属技自测：数据 / 形态槽位 / 3 主动 / 3 被动 / 边界
# 只跑本场景：godot --headless --path D:\新游戏001 res://tests/ce_zhuanshu_lan_yu_chang_jing.tscn

const LAN_YU := preload("res://scripts/zhuan_shu_ku/lan_yu.gd")
const ZHUAN_SHU_KU := preload("res://scripts/zhuan_shu_ku.gd")
const YU_CHANG_JING := preload("res://scenes/Yu.tscn")
const NPC_CHANG_JING := preload("res://scenes/YuNpc.tscn")
const LAN_YU_XING_TAI: XingTai = preload("res://data/xingtai/lan_yu.tres")
const LAN_YU_YU_ZHONG: YuZhong = preload("res://data/yuzhong/lan_yu.tres")
const BOSS_YU_ZHONG: YuZhong = preload("res://data/yuzhong/fen_yu.tres")

# 模块 meta 键（与 lan_yu.gd 保持一致：验证契约要求的「状态放 meta」）
const MK_YJ_SHENG := &"zs_lan_yu_ying_ju_sheng_yu"
const MK_YJ_LIST := &"zs_lan_yu_ying_ju_fen_shen"
const MK_BZ_MU := &"zs_lan_yu_bao_zi_mu_id"
const MK_BZ_SHENG := &"zs_lan_yu_bao_zi_sheng_yu"
const MK_YUN := &"zs_lan_yu_xing_chuan_yun_lie"
const MK_GJ_QI := &"zs_lan_yu_gui_ji_qi_dian"
const MK_GJ_ZHONG := &"zs_lan_yu_gui_ji_zhong_dian"
const MK_GJ_SHENG := &"zs_lan_yu_gui_ji_sheng_yu"
const MK_GJ_TU := &"zs_lan_yu_gui_ji_tu"

var passed := 0
var failed := 0
var yu: Yu


func _ready() -> void:
	var bao_cun: Array[StringName] = []
	for id in CunDang.yong_jiu_neng_li:
		bao_cun.append(id)
	CunDang.yong_jiu_neng_li.clear()

	ZhangBen.process_mode = Node.PROCESS_MODE_DISABLED  # 关饥饿：测试只关心技能本身
	yu = YU_CHANG_JING.instantiate()
	add_child(yu)
	yu.set_process(false)  # 玩家不自己跑 _process：冷却与模块 tick 全部手动推进
	yu.zui_qu.monitoring = false  # 关嘴圈：防止自动吞掉靶鱼
	yu.zi_dong_yao_ji = false
	yu.wudi = true

	_ce_shu_ju()
	_ce_xing_tai_cao_wei()
	_ce_ji_chu_bian_jie()
	_ce_ying_ju_cheng_long()
	_ce_zu_zhou_bao_zi()
	_ce_deng_li_zi_qi_she()
	_ce_ju_qun()
	_ce_xing_chuan_bo_san()
	_ce_ji_guang_gui_ji()

	_qing_chang()
	ZhangBen.chong_zhi()
	CunDang.yong_jiu_neng_li = bao_cun
	print("Results: %d passed, %d failed" % [passed, failed])
	# 技能释放会触发提示音：先掐掉所有声道，再按墙钟等一段（与 ce_panding 收尾同为 0.3 秒）。
	# 被 stop() 掐断的流要等音频线程异步释放，等 0.1 秒在快机器上仍可能报引擎级
	# resources still in use（见 scripts/yin_xiang.gd 的 _exit_tree 注释），不影响结果
	YinXiang.ting_bgm()
	YinXiang.quan_ting()
	await get_tree().create_timer(0.3).timeout
	get_tree().quit(1 if failed > 0 else 0)


# ---- 用例 1：6 个 .tres 的数据规范 ----

func _ce_shu_ju() -> void:
	var biao: Array[Dictionary] = [
		{"id": &"ying_ju_cheng_long", "ming": "萤聚成龙", "xing": &"shi_xing_ying_huo_chong",
			"zd": true, "cd": 20.0, "chi": 6.0, "ban": 1.5, "shu": 0.15, "fu": 10.0,
			"nbcd": 0.5, "tag": &"zhao_huan"},
		{"id": &"zu_zhou_bao_zi", "ming": "诅咒孢子", "xing": &"zu_zhou_xing_chen_chong",
			"zd": true, "cd": 18.0, "chi": 6.0, "ban": 6.0, "shu": 0.15, "fu": 0.15,
			"nbcd": 1.0, "tag": &""},
		{"id": &"deng_li_zi_qi_she", "ming": "等离子齐射", "xing": &"deng_li_zi_chuan_jia_yu",
			"zd": true, "cd": 26.0, "chi": 0.0, "ban": 7.0, "shu": 0.1, "fu": 0.0,
			"nbcd": 0.0, "tag": &"dan_dao"},
		{"id": &"ju_qun", "ming": "聚群", "xing": &"shi_xing_ying_huo_chong",
			"zd": false, "cd": 0.0, "chi": 0.0, "ban": 2.0, "shu": 0.3, "fu": 0.0,
			"nbcd": 0.0, "tag": &"zhao_huan"},
		{"id": &"xing_chuan_bo_san", "ming": "星传播散", "xing": &"zu_zhou_xing_chen_chong",
			"zd": false, "cd": 0.0, "chi": 4.0, "ban": 1.5, "shu": 10.0, "fu": 0.0,
			"nbcd": 0.5, "tag": &""},
		{"id": &"ji_guang_gui_ji", "ming": "极光轨迹", "xing": &"deng_li_zi_chuan_jia_yu",
			"zd": false, "cd": 0.0, "chi": 3.0, "ban": 1.0, "shu": 0.1, "fu": 0.0,
			"nbcd": 0.5, "tag": &""},
	]
	for d in biao:
		var id: StringName = d["id"]
		var neng: NengLi = load("res://data/nengli/%s.tres" % String(id)) as NengLi
		assert_eq(1 if neng != null else 0, 1, "%s：数据文件可加载" % String(id))
		if neng == null:
			continue
		assert_eq_ming(String(neng.bian_hao), String(id), "%s：bian_hao 与文件名一致" % String(id))
		assert_eq_ming(neng.ming_zi, String(d["ming"]), "%s：显示名" % String(id))
		assert_eq(1 if not neng.miao_shu.is_empty() and neng.miao_shu.length() <= 110 else 0, 1,
				"%s：描述非空且不超过 110 字" % String(id))
		assert_eq_ming(neng.lai_yuan, "钻光鱼", "%s：来源鱼名" % String(id))
		assert_eq(1 if neng.suoshu_xing_tai == d["xing"] else 0, 1,
				"%s：绑定形态正确" % String(id))
		assert_eq(neng.lei_xing, 0 if d["zd"] else 1, "%s：主动/被动类型正确" % String(id))
		assert_eq(neng.zui_da_dang, 1, "%s：专属技单档 zui_da_dang=1" % String(id))
		assert_eq(1 if neng.dang_biao.is_empty() else 0, 1, "%s：档位表留空" % String(id))
		if neng.shi_zhu_dong():
			assert_eq(1 if neng.tu_biao != null else 0, 1, "%s：主动图标已接入" % String(id))
		else:
			assert_eq(1 if neng.tu_biao == null else 0, 1, "%s：被动图标待补（留空）" % String(id))
		assert_eq(1 if neng.ban_jing_shen_wei else 0, 1, "%s：半径按身位计" % String(id))
		assert_eq(_jin_si(neng.leng_que, d["cd"]), 1, "%s：冷却 %s 秒" % [String(id), str(d["cd"])])
		assert_eq(_jin_si(neng.chi_xu, d["chi"]), 1, "%s：持续 %s 秒" % [String(id), str(d["chi"])])
		assert_eq(_jin_si(neng.ban_jing, d["ban"]), 1, "%s：半径 %s 身位" % [String(id), str(d["ban"])])
		assert_eq(_jin_si(neng.shu_zhi, d["shu"]), 1, "%s：主数值" % String(id))
		assert_eq(_jin_si(neng.fu_shu_zhi, d["fu"]), 1, "%s：副数值" % String(id))
		assert_eq(_jin_si(neng.nei_bu_leng_que, d["nbcd"]), 1, "%s：内部冷却" % String(id))
		assert_eq(neng.mei_ju_ci_shu, 0, "%s：每局次数不设限" % String(id))
		assert_eq(_jin_si(neng.npc_shu_zhi, 0.0), 1, "%s：NPC 覆写值留空" % String(id))
		assert_eq(_jin_si(neng.npc_jian_ge, 0.0), 1, "%s：NPC 间隔留空" % String(id))
		# 主动必须冷却/主值为正；被动必须主值为正（契约 6.1）
		if bool(d["zd"]):
			assert_eq(1 if neng.leng_que > 0.0 and neng.shu_zhi > 0.0 else 0, 1,
					"%s：主动冷却/主值为正" % String(id))
		else:
			assert_eq(1 if neng.shu_zhi > 0.0 else 0, 1, "%s：被动主值为正" % String(id))
		var tag: StringName = d["tag"]
		if tag == &"":
			assert_eq(1 if neng.lei_bie.is_empty() else 0, 1, "%s：分类标签留空" % String(id))
		else:
			assert_eq(1 if neng.lei_bie.has(tag) else 0, 1, "%s：分类标签含 %s" % [String(id), String(tag)])


# ---- 用例 2：3 个进化形态的专属技槽位 ----

func _ce_xing_tai_cao_wei() -> void:
	var biao: Array[Dictionary] = [
		{"form": &"shi_xing_ying_huo_chong", "zd": &"ying_ju_cheng_long", "bd": &"ju_qun"},
		{"form": &"zu_zhou_xing_chen_chong", "zd": &"zu_zhou_bao_zi", "bd": &"xing_chuan_bo_san"},
		{"form": &"deng_li_zi_chuan_jia_yu", "zd": &"deng_li_zi_qi_she", "bd": &"ji_guang_gui_ji"},
	]
	for d in biao:
		var form: JinHua = load("res://data/jinhua/%s.tres" % String(d["form"])) as JinHua
		assert_eq(1 if form != null else 0, 1, "%s：形态文件可加载" % String(d["form"]))
		if form == null:
			continue
		assert_eq(1 if form.ji_yu_bian_hao == &"lan_yu" else 0, 1, "%s：仍属钻光鱼" % String(d["form"]))
		assert_eq(1 if form.wan_jia_ke_yong else 0, 1, "%s：玩家可用" % String(d["form"]))
		assert_eq(_jin_si(form.shu_zhi_bei, 1.5), 1, "%s：原有体型倍率未被改动" % String(d["form"]))
		assert_eq(1 if form.zhuan_shu_zhu_dong != null else 0, 1, "%s：主动槽非空" % String(d["form"]))
		assert_eq(1 if form.zhuan_shu_bei_dong != null else 0, 1, "%s：被动槽非空" % String(d["form"]))
		if form.zhuan_shu_zhu_dong != null:
			assert_eq(1 if form.zhuan_shu_zhu_dong.bian_hao == d["zd"] else 0, 1,
					"%s：主动槽 id 对得上" % String(d["form"]))
		if form.zhuan_shu_bei_dong != null:
			assert_eq(1 if form.zhuan_shu_bei_dong.bian_hao == d["bd"] else 0, 1,
					"%s：被动槽 id 对得上" % String(d["form"]))


# ---- 用例 3：基础形态 / 形态不匹配的边界 ----

func _ce_ji_chu_bian_jie() -> void:
	_kai_ji_chu()
	var ids: Array[StringName] = [
		&"ying_ju_cheng_long", &"zu_zhou_bao_zi", &"deng_li_zi_qi_she",
		&"ju_qun", &"xing_chuan_bo_san", &"ji_guang_gui_ji",
	]
	for id in ids:
		var neng: NengLi = load("res://data/nengli/%s.tres" % String(id)) as NengLi
		assert_eq(1 if ZhangBen.neng_li_ke_yong(neng) else 0, 0,
				"%s：未进化到绑定形态不放行" % String(id))
		if neng.shi_zhu_dong():
			assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 0, "%s：形态不匹配主动放不出" % String(id))
			assert_eq(_xiang_deng(yu.leng_que_sheng(id), 0.0), 1,
					"%s：形态不匹配空放不扣冷却" % String(id))
	# 已经在另一分支形态里：同一鱼种但形态不同，依然不放行
	_kai_form(&"shi_xing_ying_huo_chong")
	var bie_neng: NengLi = load("res://data/nengli/zu_zhou_bao_zi.tres") as NengLi
	assert_eq(1 if ZhangBen.neng_li_ke_yong(bie_neng) else 0, 0, "形态不匹配：其他分支主动不放行")
	assert_eq(1 if yu.shi_fang_zhu_dong(bie_neng) else 0, 0, "形态不匹配：其他分支主动按不出")


# ---- 用例 4：萤聚成龙 ----

func _ce_ying_ju_cheng_long() -> void:
	_kai_form(&"shi_xing_ying_huo_chong")
	assert_eq(1 if ZhangBen.zhuang_lei(&"ying_ju_cheng_long") else 0, 1, "萤聚成龙已进主动槽")
	assert_eq(ZhangBen.dang_qian_bei_dong_ceng(&"ju_qun"), 1, "聚群已叠 1 层")
	var neng: NengLi = ZhangBen.zhao_zhu_dong(&"ying_ju_cheng_long")
	var sw := yu._shen_wei()
	# 没有敌人也能放：光点先环绕，靠近才啃
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 1, "萤聚成龙：没有目标也能释放")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"ying_ju_cheng_long"), 20.0), 1, "萤聚成龙：冷却写入 20 秒")
	assert_eq(_jin_si(float(yu.get_meta(MK_YJ_SHENG, 0.0)), 6.0), 1, "萤聚成龙：持续 6 秒")
	var lie: Array = yu.get_meta(MK_YJ_LIST, [])
	assert_eq(lie.size(), 5, "萤聚成龙：召唤 5 个光点分身")
	if lie.is_empty():
		return
	var huan := 2.0 * sw
	for node in lie:
		var sp := node as Sprite2D
		assert_eq(1 if sp != null else 0, 1, "萤聚成龙：分身是 Sprite2D")
		if sp == null:
			continue
		assert_eq(1 if sp.get_parent() == yu.get_parent() else 0, 1, "萤聚成龙：分身挂场景层")
		assert_eq(1 if sp.texture != null else 0, 1, "萤聚成龙：分身有贴图")
		assert_eq(1 if sp.is_in_group("yu_npc") else 0, 0, "萤聚成龙：分身不进 NPC 组")
		assert_eq(1 if sp.is_in_group("player") else 0, 0, "萤聚成龙：分身不进玩家组")
		var you_area := false
		for c in sp.get_children():
			if c is Area2D:
				you_area = true
				break
		assert_eq(1 if not you_area else 0, 1, "萤聚成龙：分身不挂 Area2D（不可选中）")
		assert_eq(_jin_si(sp.global_position.distance_to(yu.global_position), huan), 1,
				"萤聚成龙：分身距玩家 2 身位")
	# 靶鱼放在第一个光点初始位置：每帧环绕后仍落在 1.5 身位啃咬圈内
	var npc := _zao_yu(10.0)
	var jiao0 := float(lie[0].get_meta(&"lan_yu_jiao", 0.0))
	npc.position = yu.position + Vector2.RIGHT.rotated(jiao0) * huan
	var ti0 := npc.tixing
	var dm0 := npc.dian_ma
	yu._geng_xin_zhu_dong(0.4)
	assert_eq(_jin_si(ti0, npc.tixing), 1, "萤聚成龙：内部节拍未到不啃咬")
	assert_eq(_jin_si(dm0, npc.dian_ma), 1, "萤聚成龙：内部节拍未到不电麻")
	yu._geng_xin_zhu_dong(0.11)
	assert_eq(_jin_si(ti0 - npc.tixing, 0.15), 1, "萤聚成龙：光点啃咬掉肉 0.15 级")
	assert_eq(_jin_si(npc.dian_ma - dm0, 10.0), 1, "萤聚成龙：光点啃咬电麻 10")
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 0, "萤聚成龙：冷却中按不出")
	# 到期：剩余时间推完 → 5 个光点全部移除
	var sheng := float(yu.get_meta(MK_YJ_SHENG, 0.0))
	yu._geng_xin_zhu_dong(maxf(0.0, sheng - 0.01))
	assert_eq(_jin_si(float(yu.get_meta(MK_YJ_SHENG, 0.0)), 0.01), 1, "萤聚成龙：到期前仍在场上")
	yu._geng_xin_zhu_dong(0.02)
	assert_eq(_jin_si(float(yu.get_meta(MK_YJ_SHENG, 0.0)), 0.0), 1, "萤聚成龙：持续时间归零")
	assert_eq((yu.get_meta(MK_YJ_LIST, []) as Array).size(), 0, "萤聚成龙：到期光点全部离场")
	assert_eq(1 if (lie[0] as Node).is_queued_for_deletion() else 0, 1, "萤聚成龙：到期光点请求释放")


# ---- 用例 5：诅咒孢子（主动）----

func _ce_zu_zhou_bao_zi() -> void:
	_kai_form(&"zu_zhou_xing_chen_chong")
	assert_eq(1 if ZhangBen.zhuang_lei(&"zu_zhou_bao_zi") else 0, 1, "诅咒孢子已进主动槽")
	assert_eq(ZhangBen.dang_qian_bei_dong_ceng(&"xing_chuan_bo_san"), 1, "星传播散已叠 1 层")
	var neng: NengLi = ZhangBen.zhao_zhu_dong(&"zu_zhou_bao_zi")
	var sw := yu._shen_wei()
	# 空场空放
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 0, "诅咒孢子：没有目标空放")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"zu_zhou_bao_zi"), 0.0), 1, "诅咒孢子：空放不扣冷却")
	# 只有首领：跳过不附着
	var boss := _zao_yu(8.0, BOSS_YU_ZHONG)
	boss.position = yu.position + Vector2(sw * 3.0, 0.0)
	assert_eq(1 if boss.shi_boss else 0, 1, "夹具：鲸鲨是首领")
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 0, "诅咒孢子：首领不吃孢子，空放")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"zu_zhou_bao_zi"), 0.0), 1, "诅咒孢子：boss 空放不扣冷却")
	assert_eq(int(yu.get_meta(MK_BZ_MU, 0)), 0, "诅咒孢子：boss 不附着")
	_shan_yu(boss)
	# 正常目标：附着 6 秒，每秒吸 0.15 级并回给玩家
	var npc := _zao_yu(10.0)
	npc.position = yu.position + Vector2(sw * 2.0, sw * 0.5)
	var ti0 := npc.tixing
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 1, "诅咒孢子：有目标释放成功")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"zu_zhou_bao_zi"), 18.0), 1, "诅咒孢子：冷却写入 18 秒")
	assert_eq(int(yu.get_meta(MK_BZ_MU, 0)), npc.get_instance_id(), "诅咒孢子：meta 记录目标实例 id")
	assert_eq(_jin_si(float(yu.get_meta(MK_BZ_SHENG, 0.0)), 6.0), 1, "诅咒孢子：持续 6 秒")
	ZhangBen.dang_qian_ti_xing = 4.0
	yu._geng_xin_zhu_dong(0.9)
	assert_eq(_jin_si(ti0, npc.tixing), 1, "诅咒孢子：内部 CD 未到不吸取")
	assert_eq(_jin_si(ZhangBen.dang_qian_ti_xing, 4.0), 1, "诅咒孢子：内部 CD 未到不回体型")
	yu._geng_xin_zhu_dong(0.11)
	assert_eq(_jin_si(ti0 - npc.tixing, 0.15), 1, "诅咒孢子：每秒吸 0.15 级")
	assert_eq(_jin_si(ZhangBen.dang_qian_ti_xing, 4.15), 1, "诅咒孢子：吸到的体型转给玩家")
	# 目标死亡立即结束（普通死因不留云）
	npc.bei_chi(false, null)
	assert_eq(1 if npc.si_le else 0, 1, "夹具：靶鱼被整吞")
	yu._geng_xin_zhu_dong(0.1)
	assert_eq(int(yu.get_meta(MK_BZ_MU, 0)), 0, "诅咒孢子：目标死亡立即结束")
	assert_eq((yu.get_meta(MK_YUN, []) as Array).size(), 0, "星传播散：普通死亡不留孢子云")


# ---- 用例 6：等离子齐射（主动）----

func _ce_deng_li_zi_qi_she() -> void:
	_kai_form(&"deng_li_zi_chuan_jia_yu")
	assert_eq(1 if ZhangBen.zhuang_lei(&"deng_li_zi_qi_she") else 0, 1, "等离子齐射已进主动槽")
	assert_eq(ZhangBen.dang_qian_bei_dong_ceng(&"ji_guang_gui_ji"), 1, "极光轨迹已叠 1 层")
	var neng: NengLi = ZhangBen.zhao_zhu_dong(&"deng_li_zi_qi_she")
	var sw := yu._shen_wei()
	# 射线上没有任何目标：空放
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 0, "等离子齐射：没有目标空放")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"deng_li_zi_qi_she"), 0.0), 1, "等离子齐射：空放不扣冷却")
	# 射线上的两个普通鱼 + 一个首领；轴外一条不受击
	var a := _zao_yu(10.0)
	a.position = yu.position + Vector2(sw * 3.0, 0.0)
	var b := _zao_yu(10.0)
	b.position = yu.position + Vector2(sw * 5.0, sw * 0.4)
	var boss := _zao_yu(10.0, BOSS_YU_ZHONG)
	boss.position = yu.position + Vector2(sw * 6.0, -sw * 0.2)
	var c := _zao_yu(10.0)
	c.position = yu.position + Vector2(sw * 3.0, sw * 1.5)
	var a0 := a.tixing
	var b0 := b.tixing
	var boss0 := boss.tixing
	var c0 := c.tixing
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 1, "等离子齐射：释放成功")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"deng_li_zi_qi_she"), 26.0), 1, "等离子齐射：冷却写入 26 秒")
	assert_eq(_jin_si(a0 - a.tixing, 0.1), 1, "等离子齐射：轴上第一个目标直扣 0.1 级")
	assert_eq(_jin_si(b0 - b.tixing, 0.1), 1, "等离子齐射：贯穿第二个目标不停车")
	assert_eq(_jin_si(boss0 - boss.tixing, 0.05), 1, "等离子齐射：首领无视防御减半为 0.05")
	assert_eq(_jin_si(c0, c.tixing), 1, "等离子齐射：轴外目标不受击")
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 0, "等离子齐射：冷却中按不出")


# ---- 用例 7：聚群（被动）----

func _ce_ju_qun() -> void:
	_kai_form(&"shi_xing_ying_huo_chong")
	var neng: NengLi = ZhangBen.zhao_bei_dong(&"ju_qun")
	var sw := yu._shen_wei()
	assert_eq(1 if neng != null else 0, 1, "聚群已装备")
	assert_eq(_jin_si(LAN_YU.wen(yu, neng, &"yao_shang_bei", {}), 1.0), 1, "聚群：没有同种时 ×1.0")
	assert_eq(_jin_si(ZHUAN_SHU_KU.wen(yu, &"yao_shang_bei", {}), 1.0), 1, "聚群：框架连乘入口同值")
	assert_eq(_jin_si(LAN_YU.wen(yu, neng, &"shou_shang_bei", {}), 1.0), 1, "聚群：别的数值点不生效")
	# 2 条同种在 2 身位内 → ×1.6
	var n1 := _zao_yu(2.0, LAN_YU_YU_ZHONG)
	n1.position = yu.position + Vector2(sw * 0.5, 0.0)
	var n2 := _zao_yu(2.0, LAN_YU_YU_ZHONG)
	n2.position = yu.position + Vector2(-sw * 0.5, sw * 0.3)
	assert_eq(_jin_si(LAN_YU.wen(yu, neng, &"yao_shang_bei", {}), 1.6), 1, "聚群：2 条同种 ×1.6")
	# 再加 4 条 → 6 条，上限按 5 条：×2.5
	for i in 4:
		var n := _zao_yu(2.0, LAN_YU_YU_ZHONG)
		n.position = yu.position + Vector2(sw * (1.0 + 0.05 * float(i)), sw * 0.2)
	assert_eq(_jin_si(LAN_YU.wen(yu, neng, &"yao_shang_bei", {}), 2.5), 1, "聚群：6 条同种按上限 5 条 ×2.5")
	# 清场后单独验证「远处同种」「异种」都不计入
	for n in [n1, n2]:
		_shan_yu(n)
	for node in get_tree().get_nodes_in_group("yu_npc"):
		_shan_yu(node as YuNpc)
	var jin := _zao_yu(2.0, LAN_YU_YU_ZHONG)
	jin.position = yu.position + Vector2(sw * 0.4, 0.0)
	var yuan := _zao_yu(2.0, LAN_YU_YU_ZHONG)
	yuan.position = yu.position + Vector2(sw * 3.0, 0.0)
	var yi_zhong := _zao_yu(2.0)
	yi_zhong.position = yu.position + Vector2(0.0, sw * 0.4)
	assert_eq(_jin_si(LAN_YU.wen(yu, neng, &"yao_shang_bei", {}), 1.3), 1,
			"聚群：远处同种与异种都不计入，仅 1 条 ×1.3")


# ---- 用例 8：星传播散（被动）：孢子吸死留云、毒晕 ----

func _ce_xing_chuan_bo_san() -> void:
	_kai_form(&"zu_zhou_xing_chen_chong")
	var zd: NengLi = ZhangBen.zhao_zhu_dong(&"zu_zhou_bao_zi")
	var sw := yu._shen_wei()
	var npc := _zao_yu(0.6)
	npc.position = yu.position + Vector2(sw * 2.0, 0.0)
	assert_eq(1 if yu.shi_fang_zhu_dong(zd) else 0, 1, "星传播散夹具：孢子附着")
	ZhangBen.dang_qian_ti_xing = 4.0
	yu._geng_xin_zhu_dong(1.01)
	assert_eq(1 if npc.si_le else 0, 1, "星传播散：目标被吸到最小体型后离场")
	var yun_lie: Array = yu.get_meta(MK_YUN, [])
	assert_eq(yun_lie.size(), 1, "星传播散：死亡位置留下 1 朵孢子云")
	if yun_lie.is_empty():
		return
	var yun: Dictionary = yun_lie[0]
	assert_eq(_jin_si((yun["wei"] as Vector2).distance_to(npc.global_position), 0.0), 1,
			"星传播散：云在死亡位置")
	assert_eq(1 if is_instance_valid(yun.get("tu")) and (yun.get("tu") as Node) is Sprite2D else 0, 1,
			"星传播散：云视觉节点已生成")
	assert_eq(_jin_si(float(yun["sheng_yu"]), 4.0), 1, "星传播散：云持续 4 秒（出生帧不计时）")
	# 云内靶鱼：每 0.5s +10 毒晕（每秒 +20%）
	var yun_npc := _zao_yu(10.0)
	yun_npc.position = (yun["wei"] as Vector2) + Vector2(sw * 0.5, 0.0)
	var du0 := yun_npc.du_yun
	yu._geng_xin_zhu_dong(0.4)
	assert_eq(_jin_si(du0, yun_npc.du_yun), 1, "星传播散：内部节拍未到不叠毒晕")
	yu._geng_xin_zhu_dong(0.11)
	assert_eq(_jin_si(yun_npc.du_yun - du0, 10.0), 1, "星传播散：每 0.5s +10（每秒 +20%）")
	yu._geng_xin_zhu_dong(0.5)
	assert_eq(_jin_si(yun_npc.du_yun - du0, 20.0), 1, "星传播散：再一拍累计 20 毒晕")
	var sheng := float(yun["sheng_yu"])
	yu._geng_xin_zhu_dong(sheng + 0.01)
	assert_eq((yu.get_meta(MK_YUN, []) as Array).size(), 0, "星传播散：4 秒到期云移除")
	assert_eq(1 if is_instance_valid(yun.get("tu")) and (yun.get("tu") as Node).is_queued_for_deletion() else 0, 1,
			"星传播散：到期云视觉请求释放")


# ---- 用例 9：极光轨迹（被动）：路径 3 秒、每 0.5s 掉肉 0.1 ----

func _ce_ji_guang_gui_ji() -> void:
	_kai_form(&"deng_li_zi_chuan_jia_yu")
	var neng: NengLi = ZhangBen.zhao_zhu_dong(&"deng_li_zi_qi_she")
	var sw := yu._shen_wei()
	var npc := _zao_yu(10.0)
	npc.position = yu.position + Vector2(sw * 3.0, 0.0)
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 1, "极光轨迹夹具：等离子齐射释放")
	var qi: Vector2 = yu.get_meta(MK_GJ_QI, Vector2.ZERO)
	var zhong: Vector2 = yu.get_meta(MK_GJ_ZHONG, Vector2.ZERO)
	assert_eq(_jin_si(qi.distance_to(yu.position), 0.0), 1, "极光轨迹：meta 记录射线起点")
	assert_eq(_jin_si(zhong.distance_to(yu.position + Vector2(sw * 7.0, 0.0)), 0.0), 1,
			"极光轨迹：meta 记录射线终点 7 身位")
	assert_eq(_jin_si(float(yu.get_meta(MK_GJ_SHENG, 0.0)), 3.0), 1, "极光轨迹：路径持续 3 秒")
	var guang: Node = yu.get_meta(MK_GJ_TU, null)
	assert_eq(1 if guang is Sprite2D else 0, 1, "极光轨迹：路径视觉节点已生成")
	assert_eq(1 if guang != null and guang.get_parent() == yu.get_parent() else 0, 1,
			"极光轨迹：路径视觉挂场景层")
	var ti0 := npc.tixing
	yu._geng_xin_zhu_dong(0.4)
	assert_eq(_jin_si(ti0, npc.tixing), 1, "极光轨迹：内部节拍未到不掉肉")
	yu._geng_xin_zhu_dong(0.11)
	assert_eq(_jin_si(ti0 - npc.tixing, 0.1), 1, "极光轨迹：穿过路径每 0.5s 掉肉 0.1 级")
	# 3 秒到期：路径清空、后续不再掉肉
	var sheng := float(yu.get_meta(MK_GJ_SHENG, 0.0))
	yu._geng_xin_zhu_dong(sheng + 0.01)
	assert_eq(_jin_si(float(yu.get_meta(MK_GJ_SHENG, 0.0)), 0.0), 1, "极光轨迹：3 秒到期")
	assert_eq(1 if not yu.has_meta(MK_GJ_TU) else 0, 1, "极光轨迹：到期清掉路径视觉引用")
	assert_eq(1 if guang != null and guang.is_queued_for_deletion() else 0, 1,
			"极光轨迹：到期路径视觉请求释放")
	var ti1 := npc.tixing
	yu._geng_xin_zhu_dong(0.5)
	assert_eq(_jin_si(ti1, npc.tixing), 1, "极光轨迹：到期后不再掉肉")


# ---- 夹具 ----

func _kai_ji_chu() -> void:
	# 清场 → 钻光鱼基础形态 → Lv.6；后续用例再走 jin_hua_wei 进进化形态
	_qing_chang()
	ZhangBen.chong_zhi()
	assert_eq(1 if ZhangBen.kai_ju_xing_tai(LAN_YU_XING_TAI) else 0, 1,
			"夹具：钻光鱼基础形态装配成功")
	_she_deng_ji(6)
	yu.scale = yu._ti_xing_vector()


func _kai_form(form_id: StringName) -> JinHua:
	_kai_ji_chu()
	var form := JinHuaKu.zhao(form_id)
	assert_eq(1 if ZhangBen.jin_hua_wei(form) else 0, 1,
			"夹具：进化 %s 装配成功" % String(form_id))
	yu.scale = yu._ti_xing_vector()
	return form


func _she_deng_ji(deng_ji: int) -> void:
	ZhangBen.deng_ji = deng_ji
	ZhangBen.dang_qian_ti_xing = ZhangBen.ti_xing_shang_xian()


func _zao_yu(tixing_zhi: float, zhong: YuZhong = null) -> YuNpc:
	# 定住的靶鱼：进树前关 AI，进树后覆盖体型；时序与 ce_panding 的 _zao_yu 一致
	var npc: YuNpc = NPC_CHANG_JING.instantiate()
	npc.sudu = 0.0
	npc.ai_kai_qi = false
	npc.yu_zhong = zhong
	npc.position = Vector2(1000, 1000)
	add_child(npc)
	npc.tixing = tixing_zhi
	npc._ying_she_ti_xing()
	npc.set_process(false)
	return npc


func _shan_yu(npc: YuNpc) -> void:
	# 同步移除一条靶鱼：本场景在 _ready 里一口气跑完，queue_free 要等帧末
	if npc == null or not is_instance_valid(npc):
		return
	if npc.is_in_group("yu_npc"):
		npc.remove_from_group("yu_npc")
	if npc.get_parent() == self:
		remove_child(npc)
	npc.queue_free()


func _qing_chang() -> void:
	# 清空上一用例的靶鱼 / 光点 / 射线 / 孢子云与模块 meta，避免串场
	for node in get_tree().get_nodes_in_group("yu_npc"):
		_shan_yu(node as YuNpc)
	for child in get_children():
		if child == yu:
			continue
		if String(child.name).begins_with("LanYu"):
			remove_child(child)
			child.queue_free()
	if is_instance_valid(yu):
		for k in yu.get_meta_list():
			if String(k).begins_with("zs_lan_yu_"):
				yu.remove_meta(k)
		yu.zhu_dong_leng_que.clear()
		yu._nei_bu_leng_que.clear()
		yu._mei_ju_yong_ci.clear()
		yu.wudi = true
		yu._ni_liu_sheng_yu = 0.0
		yu._su_du_sheng_yu = 0.0
		yu._chong_zhuang_sheng_yu = 0.0
		yu._yin_shen_sheng_yu = 0.0
		yu._fu_chong_sheng_yu = 0.0
		yu._fu_chong_li_chang = false
		yu._duo_tou_chuang_kou = 0.0
		yu.dang_qian_su_du = 0.0
		yu.dang_qian_jiao = 0.0
		yu.fang_xiang = Vector2.RIGHT
		yu.position = Vector2(2000, 500)
		yu.scale = Vector2.ONE


func _xiang_deng(shu: float, qi_wang: float) -> int:
	return 1 if is_equal_approx(shu, qi_wang) else 0


func _jin_si(shu: float, qi_wang: float) -> int:
	return 1 if absf(shu - qi_wang) < 0.001 else 0


func assert_eq(shi_ji, qi_wang: int, biao_qian: String) -> void:
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %d，实际 %d）" % [biao_qian, qi_wang, shi_ji])


func assert_eq_ming(shi_ji: String, qi_wang: String, biao_qian: String) -> void:
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %s，实际 %s）" % [biao_qian, qi_wang, shi_ji])
