extends Node2D
# 鲸鲨（fen_yu）玩家形态专属技模块自测（场景模式）
# 覆盖：6 条 .tres 字段 / 3 个进化形态槽位 / 3 主动核心效果与冷却 /
#       3 被动核心断言（含 tun_men_kan、shou_shang_bei、暗场窗口内外）/ 形态不匹配与首领边界
# 运行：Godot --headless --path . res://tests/ce_zhuanshu_fen_yu_chang_jing.tscn --quit-after 600
# 纪律：禁用裸 assert()；失败只 print("FAIL: ...")；收卷打印 Results 后按失败数退出

const ZHUAN_SHU := preload("res://scripts/zhuan_shu_ku.gd")  # 专属技模块分派框架
const FEN_YU := preload("res://scripts/zhuan_shu_ku/fen_yu.gd")  # 被测模块
const XING_TAI_FEN_YU := preload("res://data/xingtai/fen_yu.tres")  # 鲸鲨基础形态
const YU_ZHONG_DENG_LONG := preload("res://data/yuzhong/ye_deng_long_yu.tres")  # 灯笼鱼
const YU_ZHONG_FEN_YU := preload("res://data/yuzhong/fen_yu.tres")  # 首领鲸鲨鱼种
const ROU_KUAI_CHANGJING := preload("res://scenes/RouKuai.tscn")  # 鱼肉块蓝图

var passed := 0  # 通过计数（收卷用）
var failed := 0  # 失败计数（退出码依据）
var yu: Yu  # 玩家：全局只造一个，用例间靠账本复位 + meta 清理


func _ready() -> void:
	var shu := get_tree()
	# 关掉账本饥饿时钟：本测试要精确断言体型数值，不能被每秒 −0.6 掺进来
	ZhangBen.process_mode = Node.PROCESS_MODE_DISABLED
	# 隔离成就永久解锁：真实存档里的通用技能会改变受伤/速度等倍率，污染精确断言
	CunDang.yong_jiu_neng_li.clear()
	_ce_shu_ju()
	_ce_jin_hua_cao()
	# 构造玩家（契约第 8 节）：先设鲸鲨基础形态与 Lv.6，再进树让 _ready 应用形态数值
	ZhangBen.chong_zhi()
	assert_eq(1 if ZhangBen.kai_ju_xing_tai(XING_TAI_FEN_YU) else 0, 1, "夹具：鲸鲨基础形态装配成功")
	ZhangBen.deng_ji = 6
	ZhangBen.dang_qian_ti_xing = ZhangBen.ti_xing_shang_xian()
	yu = load("res://scenes/Yu.tscn").instantiate()
	add_child(yu)
	yu.zi_dong_yao_ji = false  # 关掉自动咬击：靶鱼要按用例布置，不能被顺手咬死
	yu.scale = yu._ti_xing_vector()
	_ce_xing_tai_bu_pi_pei()
	_ce_kun_tun()
	_ce_xuan_wo()
	_ce_tun_xing()
	_ce_xian_shan()
	_ce_shen_yuan_zhuang_jia()
	_ce_xing_yu_ling_yu()
	print("Results: %d passed, %d failed" % [passed, failed])
	shu.quit(1 if failed > 0 else 0)


# ---- 数据与槽位 ----

func _ce_shu_ju() -> void:
	# 6 条能力：字段校验（id/名/描述/绑定形态/类型/单档/数值）
	var qi_wang := {
		&"kun_tun_tian_di": {
			"form": &"bei_ming_ju_kun", "lei": 0, "leng": 25.0,
			"chi": 3.0, "ban": 6.0, "shu": 7.0, "fu": 0.0, "shen_wei": true,
		},
		&"shen_yuan_xuan_wo": {
			"form": &"yuan_chu_li_wei_tan", "lei": 0, "leng": 24.0,
			"chi": 5.0, "ban": 8.0, "shu": 1.0, "fu": 0.0, "shen_wei": true,
		},
		&"tun_xing": {
			"form": &"xing_kong_tun_xing_shou", "lei": 0, "leng": 20.0,
			"chi": 5.0, "ban": 0.0, "shu": 0.2, "fu": 0.0, "shen_wei": false,
		},
		&"xian_shan_zhi_bei": {
			"form": &"bei_ming_ju_kun", "lei": 1, "leng": 0.0,
			"chi": 0.0, "ban": 0.0, "shu": 0.7, "fu": 1.5, "shen_wei": false,
		},
		&"shen_yuan_zhuang_jia": {
			"form": &"yuan_chu_li_wei_tan", "lei": 1, "leng": 0.0,
			"chi": 0.0, "ban": 1.0, "shu": 0.6, "fu": 5.0, "shen_wei": true,
		},
		&"xing_yu_ling_yu": {
			"form": &"xing_kong_tun_xing_shou", "lei": 1, "leng": 0.0,
			"chi": 0.0, "ban": 0.0, "shu": 0.2, "fu": 0.1, "shen_wei": false,
		},
	}
	for id in qi_wang:
		var q: Dictionary = qi_wang[id]
		var neng: NengLi = load("res://data/nengli/%s.tres" % String(id))
		assert_eq(1 if neng != null else 0, 1, "能力数据可加载: " + String(id))
		if neng == null:
			continue
		assert_ming(String(neng.bian_hao), String(id), "能力 id 必须等于文件名: " + String(id))
		assert_eq(1 if neng.ming_zi != "" else 0, 1, "技能名非空: " + String(id))
		assert_eq(1 if neng.miao_shu != "" and neng.miao_shu.length() <= 110 else 0, 1,
				"描述非空且 ≤110 字: " + String(id))
		assert_eq(1 if neng.lai_yuan != "" else 0, 1, "来源鱼名非空: " + String(id))
		assert_ming(String(neng.suoshu_xing_tai), String(q["form"]), "绑定形态正确: " + String(id))
		assert_eq(neng.lei_xing, int(q["lei"]), "主动/被动类型正确: " + String(id))
		assert_eq(neng.zui_da_dang, 1, "专属技单档不可升: " + String(id))
		assert_eq(1 if neng.dang_biao.is_empty() else 0, 1, "档位表必须留空: " + String(id))
		assert_eq(1 if neng.lei_bie.is_empty() else 0, 1, "本组技能无召唤/位移/隐身标签: " + String(id))
		assert_jin(neng.shu_zhi, float(q["shu"]), "主数值正确: " + String(id))
		assert_jin(neng.fu_shu_zhi, float(q["fu"]), "副数值正确: " + String(id))
		assert_eq(1 if neng.ban_jing_shen_wei == bool(q["shen_wei"]) else 0, 1,
				"半径单位标记正确: " + String(id))
		if neng.shi_zhu_dong():
			assert_jin(neng.leng_que, float(q["leng"]), "主动冷却正确: " + String(id))
			assert_jin(neng.chi_xu, float(q["chi"]), "主动持续正确: " + String(id))
			assert_jin(neng.ban_jing, float(q["ban"]), "主动半径正确: " + String(id))
		else:
			assert_jin(neng.leng_que, 0.0, "被动无冷却: " + String(id))


func _ce_jin_hua_cao() -> void:
	# 3 个形态槽位：主动/被动非空、id 对得上、其余字段未动
	var qi_wang := {
		&"bei_ming_ju_kun": [&"kun_tun_tian_di", &"xian_shan_zhi_bei"],
		&"yuan_chu_li_wei_tan": [&"shen_yuan_xuan_wo", &"shen_yuan_zhuang_jia"],
		&"xing_kong_tun_xing_shou": [&"tun_xing", &"xing_yu_ling_yu"],
	}
	for form_id in qi_wang:
		var form: JinHua = load("res://data/jinhua/%s.tres" % String(form_id))
		assert_eq(1 if form != null else 0, 1, "进化形态可加载: " + String(form_id))
		if form == null:
			continue
		assert_ming(String(form.ji_yu_bian_hao), "fen_yu", "形态仍归属鲸鲨: " + String(form_id))
		assert_eq(1 if form.ming_zi != "" else 0, 1, "形态名未丢: " + String(form_id))
		assert_eq(1 if form.wan_jia_ke_yong else 0, 1, "形态仍为玩家可用: " + String(form_id))
		assert_jin(form.shu_zhi_bei, 1.5, "形态数值倍率未动: " + String(form_id))
		var zd = form.zhuan_shu_zhu_dong
		var bd = form.zhuan_shu_bei_dong
		assert_eq(1 if zd != null else 0, 1, "专属主动槽已填: " + String(form_id))
		assert_eq(1 if bd != null else 0, 1, "专属被动槽已填: " + String(form_id))
		if zd != null:
			assert_ming(String(zd.bian_hao), String(qi_wang[form_id][0]), "主动槽 id 正确: " + String(form_id))
		if bd != null:
			assert_ming(String(bd.bian_hao), String(qi_wang[form_id][1]), "被动槽 id 正确: " + String(form_id))


# ---- 边界：形态不匹配 ----

func _ce_xing_tai_bu_pi_pei() -> void:
	# 还没进化到鲸鲨分支：专属主动既不能放，也不能被装备
	var kun: NengLi = load("res://data/nengli/kun_tun_tian_di.tres")
	var xian: NengLi = load("res://data/nengli/xian_shan_zhi_bei.tres")
	assert_eq(1 if ZhangBen.neng_li_ke_yong(kun) else 0, 0, "未进化：鲲吞天地不放行")
	assert_eq(1 if yu.shi_fang_zhu_dong(kun) else 0, 0, "未进化：主动释放被主入口拒绝")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"kun_tun_tian_di"), 0.0), 1, "被拒的释放不写冷却")
	ZhangBen.xuan_neng_li(kun)
	assert_eq(1 if ZhangBen.zhuang_lei(&"kun_tun_tian_di") else 0, 0, "未进化：主动装备入口拒绝入槽")
	assert_eq(1 if ZhangBen.neng_li_ke_yong(xian) else 0, 0, "未进化：仙山之背不放行")
	assert_eq(_xiang_deng(ZHUAN_SHU.wen(yu, &"shou_shang_bei", {}), 1.0), 1,
			"未装备仙山之背：受伤倍率保持 1.0")


# ---- 主动 1：鲲吞天地 ----

func _ce_kun_tun() -> void:
	var form := _qie_huan(&"bei_ming_ju_kun")
	var neng: NengLi = load("res://data/nengli/kun_tun_tian_di.tres")
	assert_eq(1 if form != null and neng != null else 0, 1, "鲲吞天地用例：形态与数据就位")
	if form == null or neng == null:
		return
	# 空放：场上无鱼
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 0, "鲲吞天地：无目标空放返回 false")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"kun_tun_tian_di"), 0.0), 1, "空放不扣冷却")
	var sw: float = yu._shen_wei()
	var ke_chi := _zao_npc(5.0, yu.position + Vector2(sw * 4.0, 0.0))
	var jin_kou := _zao_npc(3.0, yu.position + Vector2(sw * 0.5, 0.0))
	var da_yu := _zao_npc(9.0, yu.position + Vector2(sw * 3.0, 60.0))
	var yuan_yu := _zao_npc(5.0, yu.position + Vector2(sw * 8.0, 0.0))
	var boss := _zao_npc(3.0, yu.position + Vector2(sw * 2.0, 80.0), YU_ZHONG_FEN_YU)
	assert_eq(1 if boss.shi_boss else 0, 1, "夹具：首领鲸鲨标记生效")
	var boss_qian: Vector2 = boss.global_position
	var da_qian: Vector2 = da_yu.global_position
	var yuan_qian: Vector2 = yuan_yu.global_position
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 1, "鲲吞天地：有目标释放成功")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"kun_tun_tian_di"), 25.0), 1, "鲲吞天地冷却写入 25 秒")
	assert_eq(_xiang_deng(float(yu.get_meta(FEN_YU.META_KUN_QIAN_YAO, 0.0)), 2.0), 1, "蓄力 2 秒开始")
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 0, "冷却中重复释放被拒")
	# 蓄力 1 秒：尚未开吸水
	ZHUAN_SHU.geng_xin(yu, 1.0)
	assert_eq(_xiang_deng(float(yu.get_meta(FEN_YU.META_KUN_QIAN_YAO, 0.0)), 1.0), 1, "蓄力剩 1 秒")
	assert_eq(_xiang_deng(float(yu.get_meta(FEN_YU.META_KUN_XI_SHUI, 0.0)), 0.0), 1, "蓄力中不开吸水")
	# 再 1 秒：蓄力结束，吸水窗口开启，同帧扫目标并拉拽
	var ju_0: float = yu.global_position.distance_to(ke_chi.global_position)
	ZHUAN_SHU.geng_xin(yu, 1.0)
	assert_eq(_xiang_deng(float(yu.get_meta(FEN_YU.META_KUN_QIAN_YAO, 0.0)), 0.0), 1, "蓄力归零")
	assert_eq(_xiang_deng(float(yu.get_meta(FEN_YU.META_KUN_XI_SHUI, 0.0)), 3.0), 1, "吸水窗口 3 秒")
	assert_eq(1 if jin_kou.si_le else 0, 1, "进入 1 身位的鱼被整吞（无视门槛）")
	var ju_1: float = yu.global_position.distance_to(ke_chi.global_position)
	assert_eq(1 if ju_1 < ju_0 else 0, 1, "4 身位内的目标被拉向玩家")
	# 非目标：体型 >7 / 6 身位外 / 首领
	assert_eq(_xiang_deng(da_yu.global_position.x, da_qian.x), 1, "体型 9 的鱼不被鲲吞锁定")
	assert_eq(_xiang_deng(yuan_yu.global_position.x, yuan_qian.x), 1, "6 身位外的鱼不被锁定")
	assert_eq(_xiang_deng(boss.global_position.x, boss_qian.x), 1, "首领不被鲲吞拉拽")
	assert_eq(1 if boss.si_le else 0, 0, "首领不会被整吞")
	# 再 0.5 秒：被拉到嘴边后整吞
	ZHUAN_SHU.geng_xin(yu, 0.5)
	assert_eq(1 if ke_chi.si_le else 0, 1, "拉入 1 身位后整吞成功")
	assert_eq(1 if ZhangBen.ben_ju_tun_chi_shu >= 2 else 0, 1, "鲲吞的整吞计入本局吞噬数")
	assert_eq(_xiang_deng(float(yu.get_meta(FEN_YU.META_KUN_XI_SHUI, 0.0)), 2.5), 1, "吸水窗口正常倒数")
	_qing_che()


# ---- 主动 2：深渊漩涡 ----

func _ce_xuan_wo() -> void:
	var form := _qie_huan(&"yuan_chu_li_wei_tan")
	var neng: NengLi = load("res://data/nengli/shen_yuan_xuan_wo.tres")
	assert_eq(1 if form != null and neng != null else 0, 1, "深渊漩涡用例：形态与数据就位")
	if form == null or neng == null:
		return
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 0, "深渊漩涡：无目标空放返回 false")
	var sw: float = yu._shen_wei()
	var npc := _zao_npc(8.0, yu.position + Vector2(sw * 5.0, 0.0))
	var boss := _zao_npc(10.0, yu.position + Vector2(-sw * 6.0, 0.0), YU_ZHONG_FEN_YU)
	var npc_ju_0: float = yu.global_position.distance_to(npc.global_position)
	var boss_ju_0: float = yu.global_position.distance_to(boss.global_position)
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 1, "深渊漩涡释放成功")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"shen_yuan_xuan_wo"), 24.0), 1, "深渊漩涡冷却写入 24 秒")
	assert_eq(_xiang_deng(float(yu.get_meta(FEN_YU.META_XUAN_WO_SHENG_YU, 0.0)), 5.0), 1, "漩涡持续 5 秒")
	# 1 秒：5 身位 → 4 身位（1 身位/秒）
	ZHUAN_SHU.geng_xin(yu, 1.0)
	assert_eq(_xiang_deng(float(yu.get_meta(FEN_YU.META_XUAN_WO_SHENG_YU, 0.0)), 4.0), 1, "漩涡窗口倒数")
	assert_jin(npc_ju_0 - yu.global_position.distance_to(npc.global_position), sw, "普通鱼被拉近 1 身位/秒")
	assert_jin(boss_ju_0 - yu.global_position.distance_to(boss.global_position), sw, "首领也被拉近 1 身位/秒")
	# 不吞：整场漩涡都不走 _chi_diao
	assert_eq(1 if npc.si_le else 0, 0, "漩涡只拉不吞（普通鱼仍在场）")
	assert_eq(1 if boss.si_le else 0, 0, "漩涡不把首领拖进嘴")
	assert_eq(_xiang_deng(ZHUAN_SHU.wen(yu, &"su_du_bei", {}), 1.0), 1, "漩涡不给玩家加减速")
	# 剩余 4 秒走完：窗口归零，鱼仍不被技能吞掉
	ZHUAN_SHU.geng_xin(yu, 4.0)
	assert_eq(_xiang_deng(float(yu.get_meta(FEN_YU.META_XUAN_WO_SHENG_YU, 0.0)), 0.0), 1, "漩涡 5 秒到点结束")
	assert_eq(1 if boss.si_le else 0, 0, "窗口结束首领仍未被整吞")
	_qing_che()


# ---- 主动 3：吞星 + 被动 3：星域领域 ----

func _ce_tun_xing() -> void:
	var form := _qie_huan(&"xing_kong_tun_xing_shou")
	var neng: NengLi = load("res://data/nengli/tun_xing.tres")
	assert_eq(1 if form != null and neng != null else 0, 1, "吞星用例：形态与数据就位")
	if form == null or neng == null:
		return
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 0, "吞星：场上无发光体空放返回 false")
	var sw: float = yu._shen_wei()
	var deng := _zao_npc(8.0, yu.position + Vector2(sw * 6.0, 0.0), YU_ZHONG_DENG_LONG)
	var pu_tong := _zao_npc(6.0, yu.position + Vector2(sw * 3.0, 30.0))
	var rou_1 := _zao_rou(yu.position + Vector2(-sw * 2.0, 0.0))
	var rou_2 := _zao_rou(yu.position + Vector2(-sw * 3.0, 40.0))
	assert_eq(get_tree().get_nodes_in_group("rou_kuai").size(), 2, "夹具：场上恰有两块鱼肉")
	ZhangBen.dang_qian_ti_xing = 8.0  # 低于上限（10.5）：回体型有可见空间
	var ti_0: float = ZhangBen.dang_qian_ti_xing
	assert_eq(1 if yu.shi_fang_zhu_dong(neng) else 0, 1, "吞星释放成功")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"tun_xing"), 20.0), 1, "吞星冷却写入 20 秒")
	assert_eq(_xiang_deng(float(yu.get_meta(FEN_YU.META_TUN_XING_AN_CHANG, 0.0)), 5.0), 1, "暗场窗口 5 秒")
	assert_jin(ZhangBen.dang_qian_ti_xing - ti_0, 0.6, "三处发光体各回 0.2 级（共 +0.6）")
	assert_eq(1 if deng.si_le else 0, 1, "灯笼鱼被吸收并立死旗")
	assert_eq(1 if deng.is_queued_for_deletion() else 0, 1, "灯笼鱼节点已 queue_free")
	assert_eq(1 if rou_1.is_queued_for_deletion() else 0, 1, "鱼肉块 1 已 queue_free")
	assert_eq(1 if rou_2.is_queued_for_deletion() else 0, 1, "鱼肉块 2 已 queue_free")
	assert_eq(1 if pu_tong.si_le else 0, 0, "普通鱼不是发光体，不受吞星影响")
	# 暗场窗口内：速度 ×1.2 / 咬伤 ×1.2；受伤不加不减
	assert_jin(ZHUAN_SHU.wen(yu, &"su_du_bei", {}), 1.2, "暗场：游速倍率 1.2")
	assert_jin(ZHUAN_SHU.wen(yu, &"yao_shang_bei", {}), 1.2, "暗场：咬伤倍率 1.2")
	assert_jin(ZHUAN_SHU.wen(yu, &"shou_shang_bei", {}), 1.0, "暗场：受伤倍率 1.0")
	# 5 秒走完：回亮区
	ZHUAN_SHU.geng_xin(yu, 5.0)
	assert_eq(_xiang_deng(float(yu.get_meta(FEN_YU.META_TUN_XING_AN_CHANG, 0.0)), 0.0), 1, "暗场窗口到点归零")
	assert_jin(ZHUAN_SHU.wen(yu, &"su_du_bei", {}), 1.0, "亮区：游速倍率 1.0")
	assert_jin(ZHUAN_SHU.wen(yu, &"yao_shang_bei", {}), 1.0, "亮区：咬伤倍率 1.0")
	assert_jin(ZHUAN_SHU.wen(yu, &"shou_shang_bei", {}), 1.1, "亮区：受伤倍率 1.1")
	_qing_che()


# ---- 被动 1：仙山之背 ----

func _ce_xian_shan() -> void:
	var form := _qie_huan(&"bei_ming_ju_kun")
	var bei: NengLi = load("res://data/nengli/xian_shan_zhi_bei.tres")
	assert_eq(1 if form != null and bei != null else 0, 1, "仙山之背用例：形态与数据就位")
	if form == null or bei == null:
		return
	assert_eq(ZhangBen.dang_qian_bei_dong_ceng(&"xian_shan_zhi_bei"), 1, "仙山之背已叠 1 层")
	# 数值钩子
	assert_jin(ZHUAN_SHU.wen(yu, &"shou_shang_bei", {}), 0.7, "仙山之背：受伤倍率 0.7")
	assert_jin(ZHUAN_SHU.wen(yu, &"tun_men_kan", {"mu": null}), 1.0 / 1.5,
			"仙山之背：吞噬门槛 ×1.5 换算成有效体型 0.667（更难吞别人）")
	# 实际门槛换算：6 点体型吞 8 级鱼基准不可吞；门槛 ×1.5 后有效体型 4.0，仍然不可吞
	var ti_ji_gong := 6.0
	ZhangBen.dang_qian_ti_xing = ti_ji_gong
	assert_eq(1 if ZhanDou.zhi_ming_ke_sha(ti_ji_gong, 8.0) else 0, 0, "基准：6 体型吞不下 8 级鱼")
	var you_xiao: float = ti_ji_gong * ZHUAN_SHU.wen(yu, &"tun_men_kan", {"mu": null})
	assert_eq(1 if ZhanDou.zhi_ming_ke_sha(you_xiao, 8.0) else 0, 0,
			"门槛 ×1.5 后 6 体型更吞不下 8 级鱼")
	# 受伤结算：−30% 掉体型，但仍按伤害掉肉
	var gong := _zao_npc(3.0, yu.position + Vector2(yu._shen_wei() * 3.0, 0.0))
	ZhangBen.dang_qian_ti_xing = ZhangBen.ti_xing_shang_xian()
	yu.wudi = false
	yu._ni_liu_sheng_yu = 0.0
	var ti_0: float = ZhangBen.dang_qian_ti_xing
	yu.shou_dao_yao_ji(1.0, gong)
	assert_jin(ti_0 - ZhangBen.dang_qian_ti_xing, 0.7, "仙山之背：受 1 点伤只掉 0.7 体型")
	assert_eq(1 if get_tree().get_nodes_in_group("rou_kuai").size() >= 1 else 0, 1,
			"仍按伤害掉肉（“只掉肉不掉体型”在本作血量模型下的换算）")
	_qing_che()


# ---- 被动 2：深渊装甲 ----

func _ce_shen_yuan_zhuang_jia() -> void:
	var form := _qie_huan(&"yuan_chu_li_wei_tan")
	var bei: NengLi = load("res://data/nengli/shen_yuan_zhuang_jia.tres")
	assert_eq(1 if form != null and bei != null else 0, 1, "深渊装甲用例：形态与数据就位")
	if form == null or bei == null:
		return
	assert_eq(ZhangBen.dang_qian_bei_dong_ceng(&"shen_yuan_zhuang_jia"), 1, "深渊装甲已叠 1 层")
	assert_jin(ZHUAN_SHU.wen(yu, &"shou_shang_bei", {}), 0.6, "深渊装甲：受伤倍率 0.6")
	var sw: float = yu._shen_wei()
	# 体型 <5 的咬击者：伤害照常（不免疫），但被弹开 1 身位
	var xiao := _zao_npc(3.0, yu.position + Vector2(sw * 2.0, 0.0))
	var xiao_0: Vector2 = xiao.global_position
	ZhangBen.dang_qian_ti_xing = ZhangBen.ti_xing_shang_xian()
	yu.wudi = false
	yu._ni_liu_sheng_yu = 0.0
	var ti_0: float = ZhangBen.dang_qian_ti_xing
	yu.shou_dao_yao_ji(1.0, xiao)
	assert_jin(ti_0 - ZhangBen.dang_qian_ti_xing, 0.6, "深渊装甲：受 1 点伤掉 0.6 体型（并非免伤）")
	assert_jin(xiao.global_position.distance_to(xiao_0), sw, "体型<5 的咬击者被弹开 1 身位")
	# 体型 ≥5 的咬击者：不弹开，伤害仍按 0.6
	var da := _zao_npc(6.0, yu.position + Vector2(-sw * 2.0, 0.0))
	var da_0: Vector2 = da.global_position
	ZhangBen.dang_qian_ti_xing = ZhangBen.ti_xing_shang_xian()
	yu.wudi = false
	yu._ni_liu_sheng_yu = 0.0
	var ti_1: float = ZhangBen.dang_qian_ti_xing
	yu.shou_dao_yao_ji(1.0, da)
	assert_jin(ti_1 - ZhangBen.dang_qian_ti_xing, 0.6, "深渊装甲：大体型咬击伤害同样 ×0.6")
	assert_jin(da.global_position.distance_to(da_0), 0.0, "体型≥5 的咬击者不触发弹开")
	_qing_che()


# ---- 被动 3：星域领域（真实速度入口）----

func _ce_xing_yu_ling_yu() -> void:
	var form := _qie_huan(&"xing_kong_tun_xing_shou")
	var bei: NengLi = load("res://data/nengli/xing_yu_ling_yu.tres")
	assert_eq(1 if form != null and bei != null else 0, 1, "星域领域用例：形态与数据就位")
	if form == null or bei == null:
		return
	assert_eq(ZhangBen.dang_qian_bei_dong_ceng(&"xing_yu_ling_yu"), 1, "星域领域已叠 1 层")
	# 亮区基线
	assert_jin(ZHUAN_SHU.wen(yu, &"su_du_bei", {}), 1.0, "亮区：游速倍率 1.0")
	assert_jin(ZHUAN_SHU.wen(yu, &"shou_shang_bei", {}), 1.1, "亮区：受伤倍率 1.1")
	var su_ji_0: float = yu._ti_xing_su_du_bi()
	# 手动置暗场：验证真实速度入口也吃到 ×1.2
	yu.set_meta(FEN_YU.META_TUN_XING_AN_CHANG, 5.0)
	assert_jin(ZHUAN_SHU.wen(yu, &"su_du_bei", {}), 1.2, "暗场：游速倍率 1.2")
	assert_jin(ZHUAN_SHU.wen(yu, &"yao_shang_bei", {}), 1.2, "暗场：咬伤倍率 1.2")
	assert_jin(ZHUAN_SHU.wen(yu, &"shou_shang_bei", {}), 1.0, "暗场：受伤倍率 1.0")
	var su_ji_1: float = yu._ti_xing_su_du_bi()
	assert_jin(su_ji_1 / su_ji_0, 1.2, "暗场：真实游速入口比值 1.2")
	# 窗口走完回亮区
	ZHUAN_SHU.geng_xin(yu, 5.0)
	assert_eq(_xiang_deng(float(yu.get_meta(FEN_YU.META_TUN_XING_AN_CHANG, 0.0)), 0.0), 1, "暗场归零")
	assert_jin(ZHUAN_SHU.wen(yu, &"su_du_bei", {}), 1.0, "亮区：游速回 1.0")
	assert_jin(ZHUAN_SHU.wen(yu, &"yao_shang_bei", {}), 1.0, "亮区：咬伤回 1.0")
	assert_jin(ZHUAN_SHU.wen(yu, &"shou_shang_bei", {}), 1.1, "亮区：受伤回 1.1")
	_qing_che()


# ---- 夹具 ----

func _qie_huan(fen_id: StringName) -> JinHua:
	# 用例夹具：清场/清 meta/复位账本 → 鲸鲨基础形态 Lv.6 → 进化到目标分支
	_qing_che()
	_qing_meta()
	yu.zi_dong_yao_ji = false
	yu.wudi = false
	yu._ni_liu_sheng_yu = 0.0
	yu.zhu_dong_leng_que.clear()
	yu._nei_bu_leng_que.clear()
	yu._mei_ju_yong_ci.clear()
	ZhangBen.chong_zhi()
	assert_eq(1 if ZhangBen.kai_ju_xing_tai(XING_TAI_FEN_YU) else 0, 1, "夹具：鲸鲨基础形态")
	ZhangBen.deng_ji = 6
	ZhangBen.dang_qian_ti_xing = ZhangBen.ti_xing_shang_xian()
	var form: JinHua = JinHuaKu.zhao(fen_id)
	assert_eq(1 if form != null else 0, 1, "夹具：找到进化形态 " + String(fen_id))
	if form == null:
		return null
	assert_eq(1 if ZhangBen.jin_hua_wei(form) else 0, 1, "夹具：进化到 " + String(form.ming_zi))
	yu.scale = yu._ti_xing_vector()
	# 进化演出自带 1.7 秒无敌：测试要真结算伤害/拉拽，先关掉
	yu.wudi = false
	yu._ni_liu_sheng_yu = 0.0
	var zd = form.zhuan_shu_zhu_dong
	var bd = form.zhuan_shu_bei_dong
	assert_eq(1 if zd != null else 0, 1, "夹具：专属主动槽非空")
	assert_eq(1 if bd != null else 0, 1, "夹具：专属被动槽非空")
	if zd != null:
		assert_eq(1 if ZhangBen.zhuang_lei(zd.bian_hao) else 0, 1, "夹具：专属主动已进槽")
	if bd != null:
		assert_eq(ZhangBen.dang_qian_bei_dong_ceng(bd.bian_hao), 1, "夹具：专属被动已叠 1 层")
	return form


func _zao_npc(tixing_zhi: float, wei: Vector2, zhong: YuZhong = null) -> YuNpc:
	# 造一条测试鱼：定住、关 AI、进树后再写体型（判定读这个值，物理侦测要下一帧才发生）
	var npc: YuNpc = load("res://scenes/YuNpc.tscn").instantiate()
	npc.sudu = 0.0
	npc.ai_kai_qi = false
	npc.yu_zhong = zhong  # 必须在 add_child 前注入：_ready 要读鱼种表（首领标记也靠它）
	npc.position = wei
	add_child(npc)
	npc.tixing = tixing_zhi
	npc._ying_she_ti_xing()
	return npc


func _zao_rou(wei: Vector2) -> RouKuai:
	# 造一块鱼肉：RouKuai._ready 会自动进 "rou_kuai" 组
	var rou: RouKuai = ROU_KUAI_CHANGJING.instantiate()
	rou.ti_xing_liang = 0.2
	rou.position = wei
	add_child(rou)
	return rou


func _qing_meta() -> void:
	# 清掉模块在玩家身上留的窗口状态：用例之间不许把蓄力/暗场带进下一段
	for k in [FEN_YU.META_KUN_QIAN_YAO, FEN_YU.META_KUN_XI_SHUI, FEN_YU.META_KUN_SAO_JIAN,
			FEN_YU.META_KUN_MU_BIAO, FEN_YU.META_XUAN_WO_SHENG_YU, FEN_YU.META_TUN_XING_AN_CHANG]:
		if yu.has_meta(k):
			yu.remove_meta(k)


func _qing_che() -> void:
	# 清场：立即 free 掉靶鱼与鱼肉（同帧 queue_free 不会真出树，会污染下一用例的组扫描）
	var sha: Array[Node] = []
	for n in get_tree().get_nodes_in_group("yu_npc"):
		sha.append(n)
	for n in get_tree().get_nodes_in_group("rou_kuai"):
		sha.append(n)
	for n in sha:
		if is_instance_valid(n) and n.is_inside_tree():
			n.free()


# ---- 断言 ----

func assert_eq(shi_ji, qi_wang: int, biao_qian: String) -> void:
	# 记账员：失败只记账不爆炸——对比裸 assert() 的挂死陷阱
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %d，实际 %d）" % [biao_qian, qi_wang, shi_ji])


func assert_ming(shi_ji: String, qi_wang: String, biao_qian: String) -> void:
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %s，实际 %s）" % [biao_qian, qi_wang, shi_ji])


func assert_jin(shi_ji: float, qi_wang: float, biao_qian: String) -> void:
	# 浮点断言：容差 0.01（足够盖住连乘尾差，又能抓住真实的数值错误）
	if absf(shi_ji - qi_wang) <= 0.01:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %.3f，实际 %.3f）" % [biao_qian, qi_wang, shi_ji])


func _xiang_deng(shu: float, qi_wang: float) -> int:
	return 1 if is_equal_approx(shu, qi_wang) else 0
