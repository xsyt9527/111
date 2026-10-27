extends SceneTree
# 数据全键校验测试（第 9 课 step-03：白名单 + 坏卡红测 + 鱼种表 + 抽样性质）
# 用例 1 卡池六张全过校验（DirAccess 遍历——将来加第 7 张卡自动被守护，拼错键当场现形）
# 用例 2 红测×2：学生亲手建的坏卡（数值为负）+ 代码内拼错键卡，校验器必须都抓到
#        ——校验器自己也要被测：抓不到已知坏数据，说明校验器才是坏的
# 用例 3 鱼种表字段校验（贴图/等级/分值/两个随机范围的合法性）
# 用例 4 抽样性质：弹窗卡池注册 6 张互不重复 + 复刻"复制→洗牌→取前3"跑 200 轮验不放回
# 纪律：禁用裸 assert()；不入树实例用完 free()（资源卫生）

const BAI_MING_DAN := [
	"yidong_sudu",       # 迅捷
	"mei_ji_tixing",      # 催肥
	"tun_shi_fanwei",    # 贪食
	"wudi_shi_chang",     # 活力
	"jing_yan_jia_cheng", # 睿智
	"ci_xi_fanwei",       # 磁吸
]  # 六键白名单：与 yu.gd match 分支一一对应——键是字符串无编译期校验，拼错静默失效最难查

var passed := 0  # 通过计数（收卷用）
var failed := 0  # 失败计数（退出码的依据）


func _initialize() -> void:
	# ---- 用例 1：卡池六张全过校验 ----
	var ka_wen_jian := DirAccess.get_files_at("res://data/qianghua")
	var ka_shu := 0  # .tres 实际张数（跳过杂项文件）
	for wen_jian in ka_wen_jian:
		if not wen_jian.ends_with(".tres"):
			continue
		ka_shu += 1
		var ka: Resource = load("res://data/qianghua/" + wen_jian)
		assert_guo("卡池: " + ka.ming_zi, jiao_yan_ka(ka))
	assert_eq(ka_shu, 6, "卡池应恰好 6 张（坏卡夹具若混进 data/ 数量会变 7）")

	# ---- 用例 2：红测——已知坏数据必须被校验器抓到 ----
	var huai: Resource = load("res://tests/huai_ka.tres")  # 学生亲手建的坏卡（键合法、数值为负）
	assert_eq(1 if BAI_MING_DAN.has(huai.xiao_guo) else 0, 1, "坏卡的键 yidong_sudu 本身合法（坏在数值——检验校验器第二条规矩）")
	var huai_jie_guo := jiao_yan_ka(huai)
	if huai_jie_guo == "":
		failed += 1
		print("FAIL: 红测失守——坏卡没被校验器抓到（校验器自己才是坏的）")
	else:
		passed += 1
		print("红测命中: 坏卡 → " + huai_jie_guo)
	var cuo_ka := QiangHuaKa.new()  # 代码内拼错键卡：模拟将来加新卡时手滑
	cuo_ka.ming_zi = "拼错键"
	cuo_ka.xiao_guo = "yidong_sudu2"  # 拼错的迅捷键
	cuo_ka.shu_zhi = 0.1
	var cuo_jie_guo := jiao_yan_ka(cuo_ka)
	if cuo_jie_guo == "":
		failed += 1
		print("FAIL: 红测失守——拼错键没被抓到（静默失效防线告破）")
	else:
		passed += 1
		print("红测命中: 拼错键 → " + cuo_jie_guo)
	# QiangHuaKa 是 Resource 不是 Node——引用计数自管，无需 free()

	# ---- 用例 3：鱼种表字段校验 ----
	var yu_wen_jian := DirAccess.get_files_at("res://data/yuzhong")
	var yu_shu := 0
	for wen_jian in yu_wen_jian:
		if not wen_jian.ends_with(".tres"):
			continue
		yu_shu += 1
		var yu_zhong: Resource = load("res://data/yuzhong/" + wen_jian)
		assert_guo("鱼种: " + wen_jian, jiao_yan_yu_zhong(yu_zhong))
	assert_eq(yu_shu, 6, "鱼种表应恰好 6 行")

	# ---- 用例 4：抽样性质（三选一不放回）----
	var chuang: CanvasLayer = load("res://scenes/QiangHuaDanChuang.tscn").instantiate()
	# instantiate() 只建节点不进树：_ready 不跑（就不会碰 Autoload），导出属性 ka_zu 已就位
	assert_eq(chuang.ka_zu.size(), 6, "弹窗卡池应注册 6 张")
	var ming_ji := {}  # 卡名集合（查重）
	for ka in chuang.ka_zu:
		ming_ji[ka.ming_zi] = true
		assert_guo("弹窗卡池: " + ka.ming_zi, jiao_yan_ka(ka))
	assert_eq(ming_ji.size(), 6, "卡池 6 张应互不重复（按卡名查重）")
	# 弹窗三步（复制→洗牌→取前3）在 _on_sheng_ji 里要 Autoload+节点接线，--script 模式测不了接线，
	# 这里复刻三步验算法性质：每轮恰 3 张互不重复；200 轮每张卡都该露过面
	var wei_gui := 0
	var chu_xian := {}
	for _lun in 200:
		var dai_chou: Array = chuang.ka_zu.duplicate()  # ① 复制：原注册表不动
		dai_chou.shuffle()                             # ② 洗牌：随机性来源
		var san_zhang: Array = dai_chou.slice(0, 3)     # ③ 取前 3：不放回
		if san_zhang.size() != 3:
			wei_gui += 1
		var ben_lun_ming := {}
		for ka in san_zhang:
			ben_lun_ming[ka.ming_zi] = true
			chu_xian[ka.ming_zi] = true
		if ben_lun_ming.size() != 3:
			wei_gui += 1
	assert_eq(wei_gui, 0, "200 轮抽样每轮应恰 3 张且互不重复")
	assert_eq(chu_xian.size(), 6, "200 轮后每张卡都该出现过（随机性覆盖）")
	chuang.free()  # instantiate 出来不入树——谁创建谁负责 free

	# ---- 收卷：退出码是唯一门禁语言 ----
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func jiao_yan_ka(ka: Resource) -> String:
	# 卡片校验器：返回空串=通过；返回文字=问题（红测靠它抓坏卡）
	if not BAI_MING_DAN.has(ka.xiao_guo):
		return "未知效果键: " + ka.xiao_guo
	if ka.shu_zhi <= 0.0:
		return "效果数值应为正数: " + str(ka.shu_zhi)
	return ""


func jiao_yan_yu_zhong(yu_zhong: Resource) -> String:
	# 鱼种校验器：返回空串=通过；返回文字=问题
	if yu_zhong.tie_tu == null:
		return "缺贴图"
	if yu_zhong.dengji < 1:
		return "等级应 ≥1"
	if yu_zhong.fenzhi < 1:
		return "分值应 ≥1"
	if yu_zhong.sudu_fanwei.x <= 0.0 or yu_zhong.sudu_fanwei.y < yu_zhong.sudu_fanwei.x:
		return "游速范围非法（x 应 >0 且 y ≥ x）"
	if yu_zhong.tixing_fanwei.x <= 0.0 or yu_zhong.tixing_fanwei.y < yu_zhong.tixing_fanwei.x:
		return "体型范围非法（x 应 >0 且 y ≥ x）"
	return ""


func assert_eq(shi_ji, qi_wang: int, biao_qian: String) -> void:
	# 记账员：失败只记账不爆炸——对比裸 assert() 的挂死陷阱
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %d，实际 %d）" % [biao_qian, qi_wang, shi_ji])


func assert_guo(biao_qian: String, jie_guo: String) -> void:
	# 断言校验结果为通过（空串）：失败时把校验器的报错原文打出来
	if jie_guo == "":
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（%s）" % [biao_qian, jie_guo])
