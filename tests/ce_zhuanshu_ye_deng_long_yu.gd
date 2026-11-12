extends Node2D
# 灯笼鱼（ye_deng_long_yu）专属技自测：场景模式
# 覆盖：6 条 .tres 字段合规 / 3 个进化形态槽位 / 3 主动核心效果 / 3 被动核心断言 /
# 空放、冷却、boss 状态免疫、内部冷却、形态不匹配。
# 断言失败只记账打印 FAIL，不裸 assert；收卷打印 Results 并按 failed 退出。

const ZHUAN_SHU_KU := preload("res://scripts/zhuan_shu_ku.gd")
const YE_DENG_MO := preload("res://scripts/zhuan_shu_ku/ye_deng_long_yu.gd")
const XING_TAI_LU_JING := "res://data/xingtai/ye_deng_long_yu.tres"

const META_GUI_HUO := &"zs_gui_huo_yin_lu_huo"
const META_YIN_SHEN := &"zs_xing_chen_yin_xing"
const META_LIN_GUANG := &"zs_lin_guang_bao_shan"

const FORM_YOU := &"you_ming_yin_lu_deng"
const FORM_XING := &"xing_luo_you_hun"
const FORM_BAO := &"bao_lie_lin_guang_shou"

# 6 条技能期望：形态 / 类型 / 冷却 / 主值 / 标签
const SHU_JU_QI_WANG := {
	&"gui_huo_yin_lu": {"xing_tai": &"you_ming_yin_lu_deng", "lei": 0, "leng": 20.0, "shu": 6.0, "biao": [&"zhao_huan"]},
	&"xing_chen_yin_xing": {"xing_tai": &"xing_luo_you_hun", "lei": 0, "leng": 25.0, "shu": 1.5, "biao": [&"yin_shen"]},
	&"lin_guang_bao_shan": {"xing_tai": &"bao_lie_lin_guang_shou", "lei": 0, "leng": 18.0, "shu": 50.0, "biao": [&"dian_xi"]},
	&"you_ming_ti": {"xing_tai": &"you_ming_yin_lu_deng", "lei": 1, "leng": 0.0, "shu": 0.75, "biao": []},
	&"xing_zuo_yu_hui": {"xing_tai": &"xing_luo_you_hun", "lei": 1, "leng": 0.0, "shu": 1.0, "biao": []},
	&"bao_lie_ti_zhi": {"xing_tai": &"bao_lie_lin_guang_shou", "lei": 1, "leng": 0.0, "shu": 0.3, "biao": [&"dian_xi"]},
}

const SAN_ZHI_XING_TAI := [
	[&"you_ming_yin_lu_deng", &"gui_huo_yin_lu", &"you_ming_ti"],
	[&"xing_luo_you_hun", &"xing_chen_yin_xing", &"xing_zuo_yu_hui"],
	[&"bao_lie_lin_guang_shou", &"lin_guang_bao_shan", &"bao_lie_ti_zhi"],
]

var passed := 0
var failed := 0
var yu: Yu = null


func _ready() -> void:
	ZhangBen.process_mode = Node.PROCESS_MODE_DISABLED  # 停饥饿/局内时钟，只测技能
	_ce_shu_ju()
	_ce_jin_hua()
	await _ce_xing_wei()
	ZhangBen.chong_zhi()
	print("Results: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)


func _ce_shu_ju() -> void:
	# 1) 6 条 .tres 能加载，字段符合契约 6.1
	for id in SHU_JU_QI_WANG:
		var qi_wang: Dictionary = SHU_JU_QI_WANG[id]
		var neng: NengLi = load("res://data/nengli/%s.tres" % String(id))
		assert_true(neng != null, "%s 数据可加载" % String(id))
		if neng == null:
			continue
		assert_true(neng.bian_hao == id, "%s bian_hao 等于文件名" % String(id))
		assert_true(neng.ming_zi != "", "%s 名称非空" % String(id))
		assert_true(neng.lai_yuan == "灯笼鱼", "%s 来源为灯笼鱼" % String(id))
		assert_true(neng.miao_shu != "" and neng.miao_shu.length() <= 110,
				"%s 描述非空且不超过110字" % String(id))
		if neng.shi_zhu_dong():
			assert_true(neng.tu_biao != null, "%s 主动图标已接入" % String(id))
		else:
			assert_true(neng.tu_biao == null, "%s 被动图标待补（留空）" % String(id))
		assert_true(neng.suoshu_xing_tai == qi_wang["xing_tai"], "%s 绑定形态正确" % String(id))
		assert_eq(neng.lei_xing, int(qi_wang["lei"]), "%s 主动/被动类型正确" % String(id))
		assert_eq(neng.zui_da_dang, 1, "%s 单档/单层" % String(id))
		assert_true(neng.dang_biao.is_empty(), "%s 档位表留空" % String(id))
		assert_zhi(neng.leng_que, float(qi_wang["leng"]), "%s 冷却数值正确" % String(id))
		assert_zhi(neng.shu_zhi, float(qi_wang["shu"]), "%s 主数值正确" % String(id))
		if neng.shi_zhu_dong():
			assert_true(neng.leng_que > 0.0 and neng.shu_zhi > 0.0,
					"%s 主动冷却与主值均为正" % String(id))
		else:
			assert_true(neng.shu_zhi > 0.0, "%s 被动主值为正" % String(id))
		# 所有数值字段非负
		for jian in [&"leng_que", &"chi_xu", &"ban_jing", &"shu_zhi", &"npc_shu_zhi",
				&"fu_shu_zhi", &"npc_jian_ge", &"ceng_jia", &"nei_bu_leng_que", &"mei_ju_ci_shu"]:
			var zhi = neng.get(String(jian))
			assert_true(zhi != null and float(zhi) >= 0.0,
					"%s 字段 %s 非负" % [String(id), String(jian)])
		# 标签
		var biao: Array = qi_wang["biao"]
		for b in biao:
			assert_true(neng.lei_bie.has(b), "%s 含标签 %s" % [String(id), String(b)])
		# 关键字段额外校验：鬼火寿命、隐身时长、爆闪半径按身位、爆裂内部 CD
		match id:
			&"gui_huo_yin_lu":
				assert_zhi(neng.chi_xu, 3.0, "鬼火魅惑 3s")
				assert_zhi(neng.fu_shu_zhi, 4.0, "鬼火寿命 4s")
			&"xing_chen_yin_xing":
				assert_zhi(neng.chi_xu, 4.0, "星辰隐形 4s")
			&"lin_guang_bao_shan":
				assert_zhi(neng.chi_xu, 3.0, "磷光爆闪致盲 3s")
				assert_zhi(neng.ban_jing, 3.0, "磷光爆闪半径 3")
				assert_true(neng.ban_jing_shen_wei, "磷光爆闪半径以身位计")
				assert_zhi(neng.fu_shu_zhi, 0.5, "磷光爆闪掉肉 0.5")
			&"bao_lie_ti_zhi":
				assert_zhi(neng.chi_xu, 1.0, "爆裂体质致盲 1s")
				assert_zhi(neng.fu_shu_zhi, 20.0, "爆裂体质电麻 20")
				assert_zhi(neng.nei_bu_leng_que, 3.0, "爆裂体质内部 CD 3s")


func _ce_jin_hua() -> void:
	# 2) 3 个进化形态的两个专属槽位非空、id 对得上
	for san in SAN_ZHI_XING_TAI:
		var form_id: StringName = san[0]
		var zhu_id: StringName = san[1]
		var bei_id: StringName = san[2]
		var form: JinHua = load("res://data/jinhua/%s.tres" % String(form_id))
		assert_true(form != null, "%s 形态可加载" % String(form_id))
		if form == null:
			continue
		assert_true(form.zhuan_shu_zhu_dong != null, "%s 主动槽非空" % String(form_id))
		assert_true(form.zhuan_shu_bei_dong != null, "%s 被动槽非空" % String(form_id))
		if form.zhuan_shu_zhu_dong != null:
			assert_true(form.zhuan_shu_zhu_dong.bian_hao == zhu_id,
					"%s 主动槽 id 正确" % String(form_id))
		if form.zhuan_shu_bei_dong != null:
			assert_true(form.zhuan_shu_bei_dong.bian_hao == bei_id,
					"%s 被动槽 id 正确" % String(form_id))


func _ce_xing_wei() -> void:
	# 3) 行为用例：先造一个正式玩家（照契约第 8 节）
	yu = load("res://scenes/Yu.tscn").instantiate()
	yu.position = Vector2(2000, 1200)
	yu.zi_dong_yao_ji = false
	add_child(yu)
	await get_tree().physics_frame
	yu.set_process(false)  # 只由测试手动驱动技能更新，避免自动咬击/移动干扰
	# 断开除技能外的进化演出信号：只测专属技，不让 ×1.5 数值与演出无敌污染断言
	if ZhangBen.jin_hua_wan_cheng.is_connected(Callable(yu, "_on_jin_hua_wan_cheng")):
		ZhangBen.jin_hua_wan_cheng.disconnect(Callable(yu, "_on_jin_hua_wan_cheng"))
	if ZhangBen.ti_xing_bian_hua.is_connected(Callable(yu, "_on_ti_xing_bian_hua")):
		ZhangBen.ti_xing_bian_hua.disconnect(Callable(yu, "_on_ti_xing_bian_hua"))

	await _ce_you_ming()
	await _ce_gui_huo()
	await _ce_xing_chen()
	await _ce_xing_zuo_bei_dong()
	await _ce_lin_guang()
	await _ce_bao_lie()
	await _ce_xing_tai_bu_pi_pei()
	await _qing_npc()


# ---- 各用例 ----

func _ce_you_ming() -> void:
	await _qing_npc()
	var arr := _zhun_bei(FORM_YOU, &"gui_huo_yin_lu", &"you_ming_ti")
	if arr[0] == null or arr[1] == null:
		return
	# 幽冥体：NPC 看玩家感知 ×0.75（主动鬼火不参与 gan_zhi）
	assert_zhi(ZHUAN_SHU_KU.wen(yu, &"gan_zhi_bei", {}), 0.75, "幽冥体感知倍率 0.75")
	assert_zhi(ZHUAN_SHU_KU.wen(yu, &"yao_shang_bei", {"bu": "shen"}), 1.0,
			"幽冥体不影响咬伤")


func _ce_gui_huo() -> void:
	await _qing_npc()
	var arr := _zhun_bei(FORM_YOU, &"gui_huo_yin_lu", &"you_ming_ti")
	var neng: NengLi = arr[0]
	if neng == null:
		return
	# 空放：场上无鱼 → false，不扣冷却
	yu.zhu_dong_leng_que.clear()
	assert_true(not yu.shi_fang_zhu_dong(neng), "鬼火引路无目标空放返回 false")
	assert_zhi(yu.leng_que_sheng(&"gui_huo_yin_lu"), 0.0, "鬼火引路空放不扣冷却")
	# 两个目标：应选最近
	var jin := _zao_yu(3.0, yu.position + Vector2(120, 0))
	var yuan := _zao_yu(3.0, yu.position + Vector2(360, 0))
	yu.zhu_dong_leng_que.clear()
	assert_true(yu.shi_fang_zhu_dong(neng), "鬼火引路有目标施放成功")
	assert_zhi(yu.leng_que_sheng(&"gui_huo_yin_lu"), 20.0, "鬼火引路写入 20s 冷却")
	var zhuang = yu.get_meta(META_GUI_HUO, null)
	assert_true(zhuang is Dictionary, "鬼火引路生成鬼火状态")
	if zhuang is Dictionary:
		assert_true(zhuang.get("mu", null) == jin, "鬼火引路锁定最近 NPC")
		var huo := zhuang.get("huo", null) as Node2D
		assert_true(huo != null and is_instance_valid(huo), "鬼火视觉节点存在")
		if huo != null and is_instance_valid(huo):
			assert_true(huo.name == StringName(YE_DENG_MO.GUI_HUO_ZHEN_MING), "鬼火节点名正确")
			var timer := huo.get_node_or_null(YE_DENG_MO.GUI_HUO_ZI_HUI_JIE_DIAN) as Timer
			assert_true(timer != null and is_equal_approx(timer.wait_time, 4.0), "鬼火 4s 自毁计时")
			var ju_0 := huo.global_position.distance_to(jin.global_position)
			ZHUAN_SHU_KU.geng_xin(yu, 0.05)
			assert_true(is_instance_valid(huo), "鬼火推进后仍存在")
			if is_instance_valid(huo):
				var ju_1 := huo.global_position.distance_to(jin.global_position)
				assert_true(ju_1 < ju_0, "鬼火每帧向目标推进")
			for i in range(8):
				if not yu.has_meta(META_GUI_HUO):
					break
				ZHUAN_SHU_KU.geng_xin(yu, 0.05)
	assert_true(jin.you_zhuang_tai(&"mei_huo"), "鬼火命中最近目标魅惑")
	assert_zhi(jin.zhuang_tai_sheng_yu(&"mei_huo"), 3.0, "魅惑持续 3s")
	assert_true(not yuan.you_zhuang_tai(&"mei_huo"), "非最近目标不被魅惑")
	assert_true(not yu.has_meta(META_GUI_HUO), "命中后鬼火状态清理")
	# boss 免疫魅惑（仍会飞过去命中，但状态挂不上）
	jin.position = yu.position + Vector2(600, 0)
	yuan.position = yu.position + Vector2(100, 0)
	yuan.shi_boss = true
	yu.zhu_dong_leng_que.clear()
	assert_true(yu.shi_fang_zhu_dong(neng), "鬼火引路对 boss 仍可施放")
	for i in range(8):
		if not yu.has_meta(META_GUI_HUO):
			break
		ZHUAN_SHU_KU.geng_xin(yu, 0.05)
	assert_true(not yuan.you_zhuang_tai(&"mei_huo"), "boss 免疫魅惑")
	assert_true(not yu.has_meta(META_GUI_HUO), "boss 命中后鬼火状态清理")


func _ce_xing_chen() -> void:
	await _qing_npc()
	var arr := _zhun_bei(FORM_XING, &"xing_chen_yin_xing", &"xing_zuo_yu_hui")
	var neng: NengLi = arr[0]
	var bei: NengLi = arr[1]
	if neng == null or bei == null:
		return
	var npc := _zao_yu(3.0, yu.position + Vector2(200, 0))
	yu.zhu_dong_leng_que.clear()
	assert_true(yu.shi_fang_zhu_dong(neng), "星辰隐形施放成功")
	assert_zhi(yu.leng_que_sheng(&"xing_chen_yin_xing"), 25.0, "星辰隐形写入 25s 冷却")
	assert_true(yu.has_meta(META_YIN_SHEN), "星辰隐形状态存在")
	assert_true(yu.wudi, "星辰隐形开启 wudi")
	assert_zhi(yu._ni_liu_sheng_yu, 4.0, "星辰隐形覆盖 4s 逆流无敌")
	# 完全隐身：感知倍率 0（NPC 彻底失去目标）
	assert_zhi(ZHUAN_SHU_KU.wen(yu, &"gan_zhi_bei", {}), 0.0, "隐身后感知倍率为 0")
	# 首次致命区 +50%：普通部位不消耗，致命区只吃一次
	assert_zhi(ZHUAN_SHU_KU.wen(yu, &"yao_shang_bei", {"bu": "shen"}), 1.0,
			"隐身首次普通部位不加伤")
	assert_zhi(ZHUAN_SHU_KU.wen(yu, &"yao_shang_bei", {"bu": "zhi_ming"}), 1.5,
			"隐身首次致命区 +50%")
	assert_zhi(ZHUAN_SHU_KU.wen(yu, &"yao_shang_bei", {"bu": "zhi_ming"}), 1.0,
			"致命区加成只生效一次")
	# 4s 内真实受击被无敌挡下（连续覆盖）
	var ti_0 := yu.tixing
	yu.shou_dao_yao_ji(10.0, npc, "shen")
	assert_zhi(yu.tixing, ti_0, "隐身期间受击不掉体型")
	# 攻击破隐：返回 false（不吃事件），同时星座余晖给 1s
	yu._ni_liu_sheng_yu = 0.0
	yu.wudi = false
	var chi := ZHUAN_SHU_KU.shi_jian(yu, &"yao_zhong", {"mu": npc, "bu": "shen", "shang_hai": 1.0})
	assert_true(not chi, "咬中事件不被吃掉")
	assert_true(not yu.has_meta(META_YIN_SHEN), "攻击破隐清理状态")
	assert_zhi(yu._ni_liu_sheng_yu, 1.0, "攻击破隐后星座余晖 1s")
	assert_zhi(ZHUAN_SHU_KU.wen(yu, &"gan_zhi_bei", {}), 1.0, "破隐后感知倍率恢复")
	# 受击破隐：同样返回 false，只给无敌
	yu.zhu_dong_leng_que.clear()
	yu._ni_liu_sheng_yu = 0.0
	assert_true(yu.shi_fang_zhu_dong(neng), "再次施放星辰隐形")
	yu._ni_liu_sheng_yu = 0.0
	var bei_chi := ZHUAN_SHU_KU.shi_jian(yu, &"bei_yao",
			{"lai_yuan": npc, "shang_hai": 10.0, "bu": "shen"})
	assert_true(not bei_chi, "受击事件不被吃掉（只给无敌不整口免伤）")
	assert_true(not yu.has_meta(META_YIN_SHEN), "受击破隐清理状态")
	assert_zhi(yu._ni_liu_sheng_yu, 1.0, "受击破隐后星座余晖 1s")
	# 自然到期：手动推进 4.1s，结束也触发星座余晖
	yu.zhu_dong_leng_que.clear()
	yu._ni_liu_sheng_yu = 0.0
	yu.wudi = false
	assert_true(yu.shi_fang_zhu_dong(neng), "第三次施放星辰隐形")
	yu._ni_liu_sheng_yu = 0.0  # 把施放时的 4s 清零，单独验证自然结束给的 1s
	ZHUAN_SHU_KU.geng_xin(yu, 4.1)
	assert_true(not yu.has_meta(META_YIN_SHEN), "4s 自然到期清理状态")
	assert_zhi(yu._ni_liu_sheng_yu, 1.0, "隐身自然结束触发星座余晖 1s")


func _ce_xing_zuo_bei_dong() -> void:
	# 星座余晖直连被动钩子：只给 1s、返回 false，不整口免伤
	await _qing_npc()
	var arr := _zhun_bei(FORM_XING, &"xing_chen_yin_xing", &"xing_zuo_yu_hui")
	var bei: NengLi = arr[1]
	if bei == null:
		return
	var npc := _zao_yu(3.0, yu.position + Vector2(100, 0))
	yu.set_meta(META_YIN_SHEN, {"sheng_yu": 2.0, "shou_ci": true})
	yu._ni_liu_sheng_yu = 0.0
	var fan := YE_DENG_MO.shi_jian(yu, bei, &"bei_yao",
			{"lai_yuan": npc, "shang_hai": 10.0, "bu": "shen"})
	assert_true(not fan, "星座余晖被动返回 false")
	assert_true(not yu.has_meta(META_YIN_SHEN), "星座余晖被动清隐身状态")
	assert_zhi(yu._ni_liu_sheng_yu, 1.0, "星座余晖被动给 1s 无敌")


func _ce_lin_guang() -> void:
	await _qing_npc()
	var arr := _zhun_bei(FORM_BAO, &"lin_guang_bao_shan", &"bao_lie_ti_zhi")
	var neng: NengLi = arr[0]
	if neng == null:
		return
	var ban_jing := yu._shen_wei() * 3.0
	var nei := _zao_yu(5.0, yu.position + Vector2(ban_jing - 4.0, 0.0))
	var wai := _zao_yu(5.0, yu.position + Vector2(ban_jing + 12.0, 0.0))
	var boss := _zao_yu(10.0, yu.position + Vector2(0.0, ban_jing - 4.0), true)
	var si := _zao_yu(5.0, yu.position + Vector2(40.0, 40.0))
	si.si_le = true
	yu.zhu_dong_leng_que.clear()
	assert_true(yu.shi_fang_zhu_dong(neng), "磷光爆闪施放成功")
	assert_zhi(yu.leng_que_sheng(&"lin_guang_bao_shan"), 18.0, "磷光爆闪写入 18s 冷却")
	assert_true(yu.has_meta(META_LIN_GUANG), "磷光爆闪进入前摇状态")
	assert_zhi(float(yu.get_meta(META_LIN_GUANG).get("qian_yao", 0.0)), 0.5,
			"磷光爆闪前摇 0.5s")
	assert_true(not yu._zheng_zai_shi_fang(), "前摇期间玩家不被锁动作")
	assert_true(not nei.you_zhuang_tai(&"zhi_mang"), "前摇 0.3s 时尚未致盲")
	ZHUAN_SHU_KU.geng_xin(yu, 0.3)
	assert_true(not nei.you_zhuang_tai(&"zhi_mang"), "累计 0.3s 仍在前摇")
	ZHUAN_SHU_KU.geng_xin(yu, 0.3)
	assert_true(nei.you_zhuang_tai(&"zhi_mang"), "前摇结束致盲半径内目标")
	assert_zhi(nei.zhuang_tai_sheng_yu(&"zhi_mang"), 3.0, "致盲持续 3s")
	assert_zhi(nei.dian_ma, 50.0, "目标电麻 +50")
	assert_zhi(nei.tixing, 4.5, "目标掉肉 0.5")
	assert_true(not wai.you_zhuang_tai(&"zhi_mang"), "半径外目标不致盲")
	assert_zhi(wai.dian_ma, 0.0, "半径外目标不电麻")
	assert_zhi(wai.tixing, 5.0, "半径外目标不掉肉")
	assert_true(not boss.you_zhuang_tai(&"zhi_mang"), "boss 免疫致盲状态")
	assert_zhi(boss.dian_ma, 50.0, "boss 仍吃电麻 +50")
	assert_zhi(boss.tixing, 9.75, "boss 无视防御直伤减半为 0.25")
	assert_true(not si.you_zhuang_tai(&"zhi_mang"), "跳过 si_le 目标状态")
	assert_zhi(si.tixing, 5.0, "跳过 si_le 目标直伤")
	assert_zhi(ZHUAN_SHU_KU.wen(yu, &"yao_shang_bei", {"bu": "zhi_ming"}), 0.75,
			"自身反致盲期间咬伤 ×0.75")
	ZHUAN_SHU_KU.geng_xin(yu, 1.1)
	assert_true(not yu.has_meta(META_LIN_GUANG), "反致盲 1s 后状态清理")
	assert_zhi(ZHUAN_SHU_KU.wen(yu, &"yao_shang_bei", {"bu": "zhi_ming"}), 1.0,
			"反致盲结束后咬伤恢复")


func _ce_bao_lie() -> void:
	await _qing_npc()
	var arr := _zhun_bei(FORM_BAO, &"lin_guang_bao_shan", &"bao_lie_ti_zhi")
	var bei: NengLi = arr[1]
	if bei == null:
		return
	var npc := _zao_yu(3.0, yu.position + Vector2(100, 0))
	yu._nei_bu_leng_que.clear()
	var chu_fa := false
	for i in range(300):
		_chong_zhi_mu_biao(npc)
		ZHUAN_SHU_KU.shi_jian(yu, &"bei_yao", {"lai_yuan": npc, "shang_hai": 1.0, "bu": "shen"})
		if npc.you_zhuang_tai(&"zhi_mang"):
			chu_fa = true
			break
	assert_true(chu_fa, "爆裂体质 300 次内至少触发一次")
	assert_true(yu.nei_bu_leng_que_sheng(&"bao_lie_ti_zhi") > 0.0, "爆裂体质触发后进入内部 CD")
	assert_zhi(yu.nei_bu_leng_que_sheng(&"bao_lie_ti_zhi"), 3.0, "内部 CD 为 3s")
	assert_zhi(npc.dian_ma, 20.0, "爆裂体质电麻 +20")
	assert_zhi(npc.zhuang_tai_sheng_yu(&"zhi_mang"), 1.0, "爆裂体质致盲 1s")
	# 内部 CD 期间即使必触发也不再生效
	_chong_zhi_mu_biao(npc)
	for i in range(100):
		ZHUAN_SHU_KU.shi_jian(yu, &"bei_yao", {"lai_yuan": npc, "shang_hai": 1.0, "bu": "shen"})
	assert_zhi(npc.dian_ma, 0.0, "内部 CD 期间不再电麻")
	assert_true(not npc.you_zhuang_tai(&"zhi_mang"), "内部 CD 期间不再致盲")
	# 清掉内部 CD 后可再次触发
	yu._nei_bu_leng_que.clear()
	var zai_ci := false
	for i in range(300):
		_chong_zhi_mu_biao(npc)
		ZHUAN_SHU_KU.shi_jian(yu, &"bei_yao", {"lai_yuan": npc, "shang_hai": 1.0, "bu": "shen"})
		if npc.you_zhuang_tai(&"zhi_mang"):
			zai_ci = true
			break
	assert_true(zai_ci, "内部 CD 清除后可再次触发")
	# 不整口免伤：钩子返回 false
	assert_true(not ZHUAN_SHU_KU.shi_jian(yu, &"bei_yao",
			{"lai_yuan": npc, "shang_hai": 10.0, "bu": "shen"}), "爆裂体质不吞受击事件")
	# boss 状态免疫；电麻与内部 CD 仍生效（用 duplicated 100% 概率资源直测模块）
	var boss := _zao_yu(10.0, yu.position + Vector2(0.0, 100.0), true)
	var neng_quan: NengLi = bei.duplicate()
	neng_quan.shu_zhi = 1.0
	yu._nei_bu_leng_que.clear()
	boss._zhuang_tai_sheng_yu.clear()
	boss.dian_ma = 0.0
	var fan := YE_DENG_MO.shi_jian(yu, neng_quan, &"bei_yao",
			{"lai_yuan": boss, "shang_hai": 1.0, "bu": "shen"})
	assert_true(not fan, "爆裂体质对 boss 仍返回 false")
	assert_true(not boss.you_zhuang_tai(&"zhi_mang"), "boss 免疫爆裂体质致盲")
	assert_zhi(boss.dian_ma, 20.0, "boss 仍吃爆裂体质电麻")
	assert_zhi(yu.nei_bu_leng_que_sheng(&"bao_lie_ti_zhi"), 3.0, "boss 触发也写入内部 CD")
	# si_le 目标跳过
	var si := _zao_yu(3.0, yu.position + Vector2(-100.0, 0.0))
	si.si_le = true
	yu._nei_bu_leng_que.clear()
	var fan_si := YE_DENG_MO.shi_jian(yu, neng_quan, &"bei_yao",
			{"lai_yuan": si, "shang_hai": 1.0, "bu": "shen"})
	assert_true(not fan_si, "爆裂体质跳过 si_le 目标")
	assert_zhi(si.dian_ma, 0.0, "si_le 目标不电麻")


func _ce_xing_tai_bu_pi_pei() -> void:
	# 形态不匹配：当前幽冥引路灯形态下，星辰隐形不可用、放不出、不写冷却
	await _qing_npc()
	var arr := _zhun_bei(FORM_YOU, &"gui_huo_yin_lu", &"you_ming_ti")
	if arr[0] == null:
		return
	var bie := load("res://data/nengli/xing_chen_yin_xing.tres") as NengLi
	assert_true(not ZhangBen.neng_li_ke_yong(bie), "跨形态主动归属校验为 false")
	assert_true(not yu.shi_fang_zhu_dong(bie), "跨形态主动放不出")
	assert_zhi(yu.leng_que_sheng(&"xing_chen_yin_xing"), 0.0, "跨形态主动不写冷却")


# ---- 夹具 ----

func _zhun_bei(form_id: StringName, zhu_id: StringName, bei_id: StringName) -> Array:
	# 清玩家侧旧状态 → 走正式开局/进化入口 → 校验两个专属槽自动装备
	_qing_ben_mo()
	ZhangBen.chong_zhi()
	var xt: XingTai = load(XING_TAI_LU_JING)
	assert_true(ZhangBen.kai_ju_xing_tai(xt), "灯笼鱼基础形态装配成功")
	if xt != null:
		yu.ying_yong_xing_tai(xt)  # 重置速度/嘴巴/转向，避免跨用例累积
	_she_deng_ji(6)
	var form: JinHua = JinHuaKu.zhao(form_id)
	if form == null:
		assert_true(false, "%s 形态资源存在" % String(form_id))
		return [null, null]
	if not ZhangBen.jin_hua_wei(form):
		assert_true(false, "%s 进化入口返回 true" % String(form_id))
		return [null, null]
	var zhu: NengLi = load("res://data/nengli/%s.tres" % String(zhu_id))
	var bei: NengLi = load("res://data/nengli/%s.tres" % String(bei_id))
	assert_true(ZhangBen.zhuang_lei(zhu_id), "%s 主动进入主动槽" % String(zhu_id))
	assert_true(ZhangBen.dang_qian_bei_dong_ceng(bei_id) > 0, "%s 被动进入被动层" % String(bei_id))
	yu.scale = yu._ti_xing_vector()
	yu.wudi = false
	yu.wudi_dingshi.stop()
	yu._ni_liu_sheng_yu = 0.0
	yu.dang_qian_su_du = 0.0
	return [zhu, bei]


func _she_deng_ji(n: int) -> void:
	ZhangBen.deng_ji = n
	ZhangBen.dang_qian_ti_xing = ZhangBen.ti_xing_shang_xian()


func _zao_yu(ti: float, wei: Vector2, boss := false) -> YuNpc:
	var npc: YuNpc = load("res://scenes/YuNpc.tscn").instantiate()
	npc.sudu = 0.0
	npc.ai_kai_qi = false
	npc.position = wei
	add_child(npc)
	npc.tixing = ti
	npc.tixing_chu_shi = ti
	npc.shi_boss = boss
	npc._ying_she_ti_xing()
	return npc


func _chong_zhi_mu_biao(npc: YuNpc) -> void:
	# 概率用例每轮把靶鱼状态清零，避免上一次触发的致盲/电麻污染判定
	npc._zhuang_tai_sheng_yu.clear()
	npc.dian_ma = 0.0
	npc._yun_xuan_ji_shi = 0.0


func _qing_ben_mo() -> void:
	if yu == null or not is_instance_valid(yu):
		return
	yu.remove_meta(META_GUI_HUO)
	yu.remove_meta(META_YIN_SHEN)
	yu.remove_meta(META_LIN_GUANG)
	yu.wudi = false
	if yu.wudi_dingshi != null:
		yu.wudi_dingshi.stop()
	yu._ni_liu_sheng_yu = 0.0
	yu._nei_bu_leng_que.clear()
	yu.zhu_dong_leng_que.clear()
	yu._mei_ju_yong_ci.clear()
	yu._su_du_sheng_yu = 0.0
	yu._chong_zhuang_sheng_yu = 0.0
	yu._yin_shen_sheng_yu = 0.0
	yu._xuan_wo_sheng_yu = 0.0
	yu._kuang_bao_sheng_yu = 0.0
	yu._ying_ke_sheng_yu = 0.0
	yu._xue_xing_sheng_yu = 0.0
	yu._shui_dao_sheng_yu = 0.0
	yu._dian_wang_sheng_yu = 0.0
	yu._shi_hua_qian_yao = 0.0
	yu._fu_chong_sheng_yu = 0.0
	yu._zuan_tu_sheng_yu = 0.0
	yu.dang_qian_su_du = 0.0
	yu.dang_qian_jiao = 0.0
	yu.fang_xiang = Vector2.RIGHT
	yu.position = Vector2(2000, 1200)
	var ben := yu.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if ben != null:
		ben.modulate.a = 1.0
	# 清掉上一轮遗留的鬼火视觉节点
	for child in get_children():
		if String(child.name).begins_with(YE_DENG_MO.GUI_HUO_ZHEN_MING):
			child.queue_free()


func _qing_npc() -> void:
	for node in get_tree().get_nodes_in_group(&"yu_npc"):
		var npc := node as YuNpc
		if npc != null and is_instance_valid(npc):
			npc.queue_free()
	await get_tree().process_frame


# ---- 断言记账 ----

func assert_true(tiao_jian: bool, biao_qian: String) -> void:
	if tiao_jian:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s" % biao_qian)


func assert_eq(shi_ji: int, qi_wang: int, biao_qian: String) -> void:
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %d，实际 %d）" % [biao_qian, qi_wang, shi_ji])


func assert_zhi(shi_ji: float, qi_wang: float, biao_qian: String) -> void:
	if is_equal_approx(shi_ji, qi_wang):
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %.4f，实际 %.4f）" % [biao_qian, qi_wang, shi_ji])
