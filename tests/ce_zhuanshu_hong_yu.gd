extends Node2D
# 铜眼鱼（hong_yu）H10 专属技模块自测（场景模式：Autoload 全就位）
# 覆盖：6 个 .tres 字段 / 3 个进化槽位 / 3 主动释放+冷却+核心效果 / 3 被动核心断言 / 边界
# 纪律：禁用裸 assert()；失败只 print("FAIL: ...")；收卷 Results + 退出码
# 运行：
# "D:\001\Godot_v4.7.2-stable_win64.exe" --headless --path "D:\新游戏001" \
#   res://tests/ce_zhuanshu_hong_yu_chang_jing.tscn --quit-after 600

const MO := preload("res://scripts/zhuan_shu_ku/hong_yu.gd")
const ZSK := preload("res://scripts/zhuan_shu_ku.gd")

var passed := 0
var failed := 0
var yu: Yu


func _ready() -> void:
	var shu := get_tree()
	# 关掉账本的饥饿/局内时钟：本测试只验证专属技，不让被动掉血掺进来
	ZhangBen.process_mode = Node.PROCESS_MODE_DISABLED
	# 玩家进树：先设位置/关自动咬击，避免测试靶鱼被嘴圈吞掉
	yu = load("res://scenes/Yu.tscn").instantiate()
	yu.position = Vector2(2000, 500)
	yu.zi_dong_yao_ji = false
	add_child(yu)
	_ce_shu_ju()
	_ce_xing_tai()
	_ce_guan_xing()
	_ce_feng_kuang()
	_ce_ji_guang()
	_ce_xian_jian()
	_ce_xie_shen()
	_ce_chong_neng()
	_ce_bian_jie()
	# 收卷：先停声，再等音频线程释放引用，最后按失败数给退出码
	ZhangBen.chong_zhi()
	YinXiang.quan_ting()
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.2).timeout
	shu.quit(1 if failed > 0 else 0)


func assert_eq(shi_ji, qi_wang: int, biao_qian: String) -> void:
	# 记账员：失败只记账不爆炸
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %d，实际 %d）" % [biao_qian, qi_wang, shi_ji])


func assert_eq_ming(shi_ji: String, qi_wang: String, biao_qian: String) -> void:
	# 字符串断言单独一份
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %s，实际 %s）" % [biao_qian, qi_wang, shi_ji])


func assert_jin(shi_ji: float, qi_wang: float, biao_qian: String) -> void:
	# 浮点断言：0.15×1.6 这类连乘留 0.001 容差
	if absf(shi_ji - qi_wang) < 0.001:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %s，实际 %s）" % [biao_qian, str(qi_wang), str(shi_ji)])


func _ce_shu_ju() -> void:
	# 6 条 .tres：id / 名 / 描述 / 归属形态 / 类型 / 档位 / 主数值 / 冷却 / 持续 / 身位
	var biao := [
		[&"guan_xing", "观星", &"bi_yan_guan_xing_shou", 0, 26.0, 5.0, 2.0, 0.0, false],
		[&"feng_kuang_guang_xian", "疯狂光线", &"shen_yuan_quan_shi_zhi_yan", 0, 25.0, 3.0, 3.0, 6.0, true],
		[&"ji_guang_ju_zhen", "激光矩阵", &"ji_guang_ju_zhen_yu", 0, 22.0, 3.0, 0.15, 0.0, false],
		[&"xian_jian_zhi_ming", "先见之明", &"bi_yan_guan_xing_shou", 1, 0.0, 1.0, 20.0, 0.5, true],
		[&"xie_shen_zhu_shi", "邪神注视", &"shen_yuan_quan_shi_zhi_yan", 1, 0.0, 0.0, 0.7, 0.0, false],
		[&"chong_neng_yan", "充能眼", &"ji_guang_ju_zhen_yu", 1, 0.0, 1.0, 15.0, 0.0, false],
	]
	for hang in biao:
		var id: StringName = hang[0]
		var qi_ming: String = hang[1]
		var qi_xing_tai: StringName = hang[2]
		var qi_lei: int = hang[3]
		var neng: NengLi = load("res://data/nengli/%s.tres" % String(id))
		assert_eq(1 if neng != null else 0, 1, "能力 %s 可加载" % String(id))
		if neng == null:
			continue
		assert_eq_ming(String(neng.bian_hao), String(id), "id = 文件名: " + String(id))
		assert_eq_ming(neng.ming_zi, qi_ming, "技能名: " + String(id))
		assert_eq(1 if neng.miao_shu != "" else 0, 1, "描述非空: " + String(id))
		assert_eq(1 if neng.miao_shu.length() <= 110 else 0, 1,
				"描述 ≤110 字: %s（实际 %d）" % [String(id), neng.miao_shu.length()])
		assert_eq(1 if neng.lai_yuan != "" else 0, 1, "来源非空: " + String(id))
		assert_eq_ming(String(neng.suoshu_xing_tai), String(qi_xing_tai),
				"归属形态: " + String(id))
		assert_eq(neng.lei_xing, qi_lei, "主动0/被动1: " + String(id))
		assert_eq(1 if neng.shi_zhu_dong() == (qi_lei == 0) else 0, 1,
				"shi_zhu_dong 与 lei_xing 一致: " + String(id))
		assert_eq(neng.zui_da_dang, 1, "单档不可升: " + String(id))
		assert_eq(1 if neng.dang_biao.is_empty() else 0, 1, "档位表留空: " + String(id))
		assert_eq(1 if neng.shu_zhi > 0.0 else 0, 1, "主数值为正: " + String(id))
		assert_jin(neng.leng_que, float(hang[4]), "冷却: " + String(id))
		assert_jin(neng.chi_xu, float(hang[5]), "持续: " + String(id))
		assert_jin(neng.shu_zhi, float(hang[6]), "主数值: " + String(id))
		assert_jin(neng.ban_jing, float(hang[7]), "半径/身位: " + String(id))
		assert_eq(1 if neng.ban_jing_shen_wei == bool(hang[8]) else 0, 1,
				"半径以身位计: " + String(id))
		if qi_lei == 0:
			assert_eq(1 if neng.leng_que > 0.0 else 0, 1, "主动冷却 >0: " + String(id))
		# 两条射线类主动必须打弹道标签
		if id == &"feng_kuang_guang_xian" or id == &"ji_guang_ju_zhen":
			assert_eq(1 if neng.lei_bie.has(&"dan_dao") else 0, 1,
					"射线类打 dan_dao: " + String(id))
	# 先见之明内部 CD / 充能眼每层与上限（专项字段）
	var xian: NengLi = load("res://data/nengli/xian_jian_zhi_ming.tres")
	assert_jin(xian.nei_bu_leng_que, 6.0, "先见之明内部 CD=6s")
	var chong: NengLi = load("res://data/nengli/chong_neng_yan.tres")
	assert_jin(chong.fu_shu_zhi, 4.0, "充能眼最大 4 层")
	assert_jin(chong.shu_zhi, 15.0, "充能眼每层 +15%")


func _ce_xing_tai() -> void:
	# 3 个进化形态：两个专属槽位必须非空且 id 对得上
	var biao := [
		[&"bi_yan_guan_xing_shou", &"guan_xing", &"xian_jian_zhi_ming"],
		[&"shen_yuan_quan_shi_zhi_yan", &"feng_kuang_guang_xian", &"xie_shen_zhu_shi"],
		[&"ji_guang_ju_zhen_yu", &"ji_guang_ju_zhen", &"chong_neng_yan"],
	]
	for hang in biao:
		var form_id: StringName = hang[0]
		var zhu_id: StringName = hang[1]
		var bei_id: StringName = hang[2]
		var jin: JinHua = load("res://data/jinhua/%s.tres" % String(form_id))
		assert_eq(1 if jin != null else 0, 1, "形态 %s 可加载" % String(form_id))
		if jin == null:
			continue
		assert_eq_ming(String(jin.ji_yu_bian_hao), "hong_yu", "形态归属铜眼鱼: " + String(form_id))
		assert_eq(1 if jin.zhuan_shu_zhu_dong != null else 0, 1,
				"专属主动槽非空: " + String(form_id))
		assert_eq(1 if jin.zhuan_shu_bei_dong != null else 0, 1,
				"专属被动槽非空: " + String(form_id))
		if jin.zhuan_shu_zhu_dong != null:
			assert_eq_ming(String(jin.zhuan_shu_zhu_dong.bian_hao), String(zhu_id),
					"形态主动槽 id: " + String(form_id))
		if jin.zhuan_shu_bei_dong != null:
			assert_eq_ming(String(jin.zhuan_shu_bei_dong.bian_hao), String(bei_id),
					"形态被动槽 id: " + String(form_id))


func _ce_guan_xing() -> void:
	_jin_hua(&"bi_yan_guan_xing_shou")
	var neng: NengLi = load("res://data/nengli/guan_xing.tres")
	assert_eq(1 if ZhangBen.neng_li_ke_yong(neng) else 0, 1, "观星：当前形态可用")
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 1, "观星释放成功")
	assert_jin(yu.leng_que_sheng(&"guan_xing"), 26.0, "观星写入 26s 冷却")
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 0, "观星冷却中不可再放")
	# 核心：5s 内 NPC 感知玩家 ×2.0；咬伤不额外加成
	assert_jin(MO.wen(yu, neng, &"gan_zhi_bei", {}), 2.0, "观星：gan_zhi_bei ×2.0")
	assert_jin(ZSK.wen(yu, &"gan_zhi_bei", {}), 2.0, "观星框架连乘 ×2.0")
	assert_jin(MO.wen(yu, neng, &"yao_shang_bei", {}), 1.0, "观星：咬伤 ×1.0（无额外加成）")
	MO.geng_xin(yu, neng, 5.1)
	assert_jin(MO.wen(yu, neng, &"gan_zhi_bei", {}), 1.0, "观星 5s 后感知倍率恢复 1.0")


func _ce_feng_kuang() -> void:
	_jin_hua(&"shen_yuan_quan_shi_zhi_yan")
	var neng: NengLi = load("res://data/nengli/feng_kuang_guang_xian.tres")
	# 先测空放：场上无目标 → false，且不写冷却
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 0, "疯狂光线无目标空放")
	assert_jin(yu.leng_que_sheng(&"feng_kuang_guang_xian"), 0.0, "空放不写冷却")
	# 最近目标在射线内、远处目标也在射线内：只命中第一个
	var jin := _zao_yu(5.0, Vector2(2150, 500))
	var yuan := _zao_yu(5.0, Vector2(2400, 500))
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 1, "疯狂光线命中目标释放成功")
	assert_jin(yu.leng_que_sheng(&"feng_kuang_guang_xian"), 25.0, "疯狂光线写入 25s 冷却")
	assert_eq(1 if jin.you_zhuang_tai(&"feng_kuang") else 0, 1, "首个目标进入疯狂")
	assert_jin(jin.zhuang_tai_sheng_yu(&"feng_kuang"), 3.0, "疯狂持续 3s")
	assert_eq(1 if yuan.you_zhuang_tai(&"feng_kuang") else 0, 0, "射线只命中第一个目标")
	# 背后目标：射线朝向为右，身后不算命中
	_qing_ju()
	var bei := _zao_yu(5.0, Vector2(1850, 500))
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 0, "背后目标不算命中")
	assert_eq(1 if bei.you_zhuang_tai(&"feng_kuang") else 0, 0, "背后目标不疯狂")
	# boss 免疫疯狂：射线命中仍算释放（吃冷却），状态不生效
	_qing_ju()
	var boss := _zao_yu(10.0, Vector2(2150, 500), true)
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 1, "射线命中 boss 仍算有效释放")
	assert_jin(yu.leng_que_sheng(&"feng_kuang_guang_xian"), 25.0, "boss 场景照常吃冷却")
	assert_eq(1 if boss.you_zhuang_tai(&"feng_kuang") else 0, 0, "boss 免疫疯狂")


func _ce_ji_guang() -> void:
	_jin_hua(&"ji_guang_ju_zhen_yu")
	var neng: NengLi = load("res://data/nengli/ji_guang_ju_zhen.tres")
	# 无目标空放 → false
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 0, "激光矩阵无目标空放")
	assert_jin(yu.leng_que_sheng(&"ji_guang_ju_zhen"), 0.0, "空放不写冷却")
	var a := _zao_yu(10.0, Vector2(2100, 500))
	var b := _zao_yu(10.0, Vector2(2200, 500))
	var c := _zao_yu(10.0, Vector2(2300, 500))
	var d := _zao_yu(10.0, Vector2(2400, 500))
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 1, "激光矩阵释放成功")
	assert_jin(yu.leng_que_sheng(&"ji_guang_ju_zhen"), 22.0, "激光矩阵写入 22s 冷却")
	# 第一跳：最近 3 个各掉 0.15，第 4 个未锁定
	var a0 := a.tixing
	var b0 := b.tixing
	var c0 := c.tixing
	MO.geng_xin(yu, neng, 0.5)
	assert_jin(a.tixing, a0 - 0.15, "激光第 1 跳：目标 A 掉 0.15")
	assert_jin(b.tixing, b0 - 0.15, "激光第 1 跳：目标 B 掉 0.15")
	assert_jin(c.tixing, c0 - 0.15, "激光第 1 跳：目标 C 掉 0.15")
	assert_jin(d.tixing, 10.0, "最近 3 个之外的第 4 个不锁定")
	# 锁定后目标移动：靠实例 id 仍结算
	var b1 := b.tixing
	b.position = Vector2(2000, 900)
	MO.geng_xin(yu, neng, 0.5)
	assert_jin(b.tixing, b1 - 0.15, "锁定的目标移动后仍被灼烧")
	# 目标死亡：跳过，其余目标照常
	var c1 := c.tixing
	c.si_le = true
	MO.geng_xin(yu, neng, 0.5)
	assert_jin(c.tixing, c1, "死亡目标跳过结算")
	assert_jin(a.tixing, a0 - 0.15 * 3.0, "目标 A 连续三跳（第 3 跳时 C 已死，A 照常）")
	# 走完 3s：共 6 跳后停手
	MO.geng_xin(yu, neng, 10.0)
	assert_jin(a.tixing, a0 - 0.15 * 6.0, "3s 共 6 跳：目标 A 掉 0.9")
	assert_jin(yu.get_meta(MO.META_JI_GUANG_SHENG, 0.0), 0.0, "激光矩阵持续时间归零")
	# 充能眼 4 层：激光每跳 ×1.6 = 0.24
	_qing_ju()
	var chong: NengLi = load("res://data/nengli/chong_neng_yan.tres")
	yu.dang_qian_su_du = 0.0
	for i in 4:
		MO.geng_xin(yu, chong, 1.0)
	assert_eq(int(yu.get_meta(MO.META_CHONG_NENG_CENG, 0)), 4, "充能眼静止 4s 叠满 4 层")
	assert_jin(MO.wen(yu, chong, &"yao_shang_bei", {}), 1.6, "充能眼 4 层：咬伤 ×1.6")
	var e := _zao_yu(10.0, Vector2(2100, 500))
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 1, "4 层充能下激光矩阵可释放")
	MO.geng_xin(yu, neng, 0.5)
	assert_jin(e.tixing, 10.0 - 0.24, "充能眼 4 层：激光每跳 0.15×1.6=0.24")
	MO.geng_xin(yu, neng, 10.0)


func _ce_xian_jian() -> void:
	_jin_hua(&"bi_yan_guan_xing_shou")
	var neng: NengLi = load("res://data/nengli/xian_jian_zhi_ming.tres")
	var gong := _zao_yu(5.0, Vector2(2200, 500))
	var wei_0 := yu.position
	var shu_ju := {"lai_yuan": gong, "shang_hai": 3.0, "bu": "shen"}
	assert_eq(1 if MO.shi_jian(yu, neng, &"bei_yao", shu_ju) else 0, 1,
			"先见之明触发：返回 true 整口免伤")
	var ju := yu.position.distance_to(wei_0)
	assert_jin(ju, 0.5 * yu._shen_wei(), "先见之明：侧移 0.5 身位")
	assert_jin(yu.nei_bu_leng_que_sheng(&"xian_jian_zhi_ming"), 6.0,
			"先见之明：内部 CD 写入 6s")
	assert_jin(MO.wen(yu, neng, &"yao_shang_bei", {}), 1.2, "先见之明：1s 咬伤 ×1.2")
	assert_eq(1 if MO.shi_jian(yu, neng, &"bei_yao", shu_ju) else 0, 0,
			"内部 CD 内第二次被咬不再免伤")
	MO.geng_xin(yu, neng, 1.1)
	assert_jin(MO.wen(yu, neng, &"yao_shang_bei", {}), 1.0, "先见之明 1s 后咬伤加成结束")


func _ce_xie_shen() -> void:
	_jin_hua(&"shen_yuan_quan_shi_zhi_yan")
	var neng: NengLi = load("res://data/nengli/xie_shen_zhu_shi.tres")
	assert_eq(1 if ZhangBen.neng_li_ke_yong(neng) else 0, 1, "邪神注视：当前形态可用")
	assert_jin(MO.wen(yu, neng, &"gan_zhi_bei", {}), 0.7, "邪神注视：感知 ×0.7")
	assert_jin(ZSK.wen(yu, &"gan_zhi_bei", {}), 0.7, "邪神注视框架连乘 ×0.7")
	# 本作拿不到 NPC 方位：背后目标也只能按全局 ×0.7（报告已列为主线待补钩子）
	var bei := _zao_yu(5.0, Vector2(1800, 500))
	assert_jin(ZSK.wen(yu, &"gan_zhi_bei", {}), 0.7, "无方位钩子时统一 ×0.7")
	assert_eq(1 if bei.si_le else 0, 0, "背面目标仍在场（仅作方位语义占位）")


func _ce_chong_neng() -> void:
	_jin_hua(&"ji_guang_ju_zhen_yu")
	var neng: NengLi = load("res://data/nengli/chong_neng_yan.tres")
	yu.dang_qian_su_du = 0.0
	MO.geng_xin(yu, neng, 1.0)
	assert_eq(int(yu.get_meta(MO.META_CHONG_NENG_CENG, 0)), 1, "充能眼静止 1s：1 层")
	assert_jin(MO.wen(yu, neng, &"yao_shang_bei", {}), 1.15, "1 层：咬伤 ×1.15")
	MO.geng_xin(yu, neng, 1.0)
	assert_eq(int(yu.get_meta(MO.META_CHONG_NENG_CENG, 0)), 2, "静止 2s：2 层")
	assert_jin(MO.wen(yu, neng, &"yao_shang_bei", {}), 1.3, "2 层：咬伤 ×1.3")
	MO.geng_xin(yu, neng, 1.0)
	assert_eq(int(yu.get_meta(MO.META_CHONG_NENG_CENG, 0)), 3, "静止 3s：3 层")
	MO.geng_xin(yu, neng, 1.0)
	assert_eq(int(yu.get_meta(MO.META_CHONG_NENG_CENG, 0)), 4, "静止 4s：4 层")
	assert_jin(MO.wen(yu, neng, &"yao_shang_bei", {}), 1.6, "4 层：咬伤 ×1.6")
	MO.geng_xin(yu, neng, 1.0)
	assert_eq(int(yu.get_meta(MO.META_CHONG_NENG_CENG, 0)), 4, "超过 4 层封顶不再涨")
	# 移动清零
	yu.dang_qian_su_du = 30.0
	MO.geng_xin(yu, neng, 0.1)
	assert_eq(int(yu.get_meta(MO.META_CHONG_NENG_CENG, 0)), 0, "移动后层数清零")
	assert_jin(MO.wen(yu, neng, &"yao_shang_bei", {}), 1.0, "移动清零后咬伤 ×1.0")
	assert_jin(yu.get_meta(MO.META_CHONG_NENG_JING_ZHI, 0.0), 0.0, "移动后静止计时清零")


func _ce_bian_jie() -> void:
	# 形态不匹配：碧眼观星兽放不出深渊全视之眼的主动
	_jin_hua(&"bi_yan_guan_xing_shou")
	var feng: NengLi = load("res://data/nengli/feng_kuang_guang_xian.tres")
	assert_eq(1 if ZhangBen.neng_li_ke_yong(feng) else 0, 0, "形态不匹配：碧眼放不出疯狂光线")
	assert_eq(1 if yu.shi_fang_zhu_dong(feng) else 0, 0, "形态不匹配：主入口也拒绝")
	# 反向：激光矩阵鱼放不出观星
	_jin_hua(&"ji_guang_ju_zhen_yu")
	var guan: NengLi = load("res://data/nengli/guan_xing.tres")
	assert_eq(1 if ZhangBen.neng_li_ke_yong(guan) else 0, 0, "形态不匹配：激光鱼放不出观星")
	assert_eq(1 if yu.shi_fang_zhu_dong(guan) else 0, 0, "形态不匹配：观星被主入口拒绝")


func _jin_hua(form_id: StringName) -> void:
	# 夹具：清场 → 铜眼鱼基础形态 → Lv.6 → 进化到目标分支（专属技走正式装配入口）
	_qing_ju()
	ZhangBen.chong_zhi()
	var xt: XingTai = load("res://data/xingtai/hong_yu.tres")
	assert_eq(1 if ZhangBen.kai_ju_xing_tai(xt) else 0, 1, "夹具：铜眼鱼基础形态装配")
	ZhangBen.deng_ji = 6
	ZhangBen.dang_qian_ti_xing = ZhangBen.ti_xing_shang_xian()
	var form: JinHua = JinHuaKu.zhao(form_id)
	assert_eq(1 if form != null else 0, 1, "夹具：%s 存在" % String(form_id))
	assert_eq(1 if ZhangBen.jin_hua_wei(form) else 0, 1, "夹具：进化到 %s" % String(form_id))
	# 测试同步无 Tween：手动把体型缩放对齐账本，让 _shen_wei() 读到的身位可信
	yu.scale = yu._ti_xing_vector()
	yu.position = Vector2(2000, 500)
	yu.dang_qian_su_du = 0.0
	yu.fang_xiang = Vector2.ZERO
	yu.dang_qian_jiao = 0.0


func _qing_ju() -> void:
	# 清场：NPC、专属技 meta/光束、玩家冷却与位置
	MO._qing_ji_guang_xian(yu)
	_qing_npc()
	yu.set_meta(MO.META_GUAN_XING_SHENG, 0.0)
	yu.set_meta(MO.META_XIAN_JIAN_SHENG, 0.0)
	yu.set_meta(MO.META_CHONG_NENG_JING_ZHI, 0.0)
	yu.set_meta(MO.META_CHONG_NENG_CENG, 0)
	yu.set_meta(MO.META_JI_GUANG_SHENG, 0.0)
	yu.set_meta(MO.META_JI_GUANG_MU_BIAO, [])
	yu.set_meta(MO.META_JI_GUANG_JI_SHI, 0.0)
	yu.set_meta(MO.META_JI_GUANG_CI_SHU, 0)
	yu.zhu_dong_leng_que.clear()
	yu._nei_bu_leng_que.clear()
	yu.wudi = false
	yu.dang_qian_su_du = 0.0
	yu.fang_xiang = Vector2.ZERO
	yu.dang_qian_jiao = 0.0
	yu.position = Vector2(2000, 500)


func _qing_npc() -> void:
	for node in get_tree().get_nodes_in_group("yu_npc"):
		var npc := node as YuNpc
		if npc != null:
			npc.free()


func _zao_yu(ti_xing: float, wei: Vector2, boss := false) -> YuNpc:
	# 测试靶鱼：定住、关 AI；先入树再覆盖体型（_ready 会按默认鱼种设 1 级）
	var npc: YuNpc = load("res://scenes/YuNpc.tscn").instantiate()
	npc.sudu = 0.0
	npc.ai_kai_qi = false
	npc.position = wei
	add_child(npc)
	npc.tixing = ti_xing
	npc.shi_boss = boss
	npc._ying_she_ti_xing()
	return npc
