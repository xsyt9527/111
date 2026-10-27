extends SceneTree
# 边界测试（第 9 课 step-02：第 8 课两个一次性探针转正为常驻测试）
# 用例 1 满级封顶：分次喂到 Lv.7 → 再灌 500，等级不动、经验钉满格、sheng_ji 恰好 6 次
# 用例 2 chong_zhi 归零：弄脏账本四项 → 归零断言（Autoload 常驻者的复位义务）
# 纪律：禁用裸 assert()；不入树实例用完 free()（资源卫生）
# 注意：jia_jing_yan() 内是 if 不是 while——单次最多升一级，喂经验必须分次

var passed := 0  # 通过计数（收卷用）
var failed := 0  # 失败计数（退出码的依据）
var sheng_ji_ci := 0  # sheng_ji 广播计数（升级）
var shua_tiao_ci := 0  # jing_yan_bian_hua 广播计数（刷条）


func _initialize() -> void:
	# ---- 用例 1：满级封顶（表 6 道阈值 → 封顶 Lv.7）----
	var zb: Node = load("res://scripts/zhang_ben.gd").new()
	zb.sheng_ji.connect(_shu_sheng_ji_ci)  # 接收器只做计数，不碰被测对象
	zb.jing_yan_bian_hua.connect(_shu_shua_tiao_ci)
	var lun := 0  # 喂食轮次保险（防死循环：异常时 100 轮内必停）
	while zb.deng_ji < 7 and lun < 100:
		zb.jia_jing_yan(60)  # 分次喂：每轮恰好跨一道阈值
		lun += 1
	assert_eq(zb.deng_ji, 7, "分次喂 60 应到封顶 Lv.7")
	assert_eq(sheng_ji_ci, 6, "升级广播恰好 6 次（Lv.2~7）")
	var shua_tiao_qian := shua_tiao_ci  # 记住灌 500 前的刷条数
	zb.jia_jing_yan(500)  # 满级后一口闷 500
	assert_eq(zb.deng_ji, 7, "满级后再灌 500 等级不动")
	assert_eq(zb.jing_yan, 110, "经验钉在表尾阈值满格（110）")
	assert_eq(sheng_ji_ci, 6, "封顶后不再广播 sheng_ji")
	assert_eq(shua_tiao_ci - shua_tiao_qian, 1, "封顶后仍广播 jing_yan_bian_hua 刷条恰 1 次")
	zb.free()

	# ---- 用例 2：chong_zhi 归零（独立实例——不接着用例 1 的脏状态）----
	var zb2: Node = load("res://scripts/zhang_ben.gd").new()
	zb2.jia_jing_yan(30)  # 弄脏 1：经验 22 + 等级 Lv.2
	zb2.she_jing_yan_jia_cheng(2.0)  # 弄脏 2：倍率
	zb2.xuan_ka(load("res://data/qianghua/ci_xi.tres"))  # 弄脏 3：入账一张卡
	assert_eq(zb2.deng_ji, 2, "脏状态预检：应已升到 Lv.2（30 过阈值 8）")
	zb2.chong_zhi()
	assert_eq(zb2.jing_yan, 0, "复位后经验归零")
	assert_eq(zb2.deng_ji, 1, "复位后等级归 1")
	assert_eq(int(zb2.jing_yan_jia_cheng * 10.0), 10, "复位后倍率归 1.0（×10 取整断言避开浮点比较）")
	assert_eq(zb2.yi_xuan_ka.size(), 0, "复位后已选卡清空")
	zb2.free()

	# ---- 收卷：退出码是唯一门禁语言 ----
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func assert_eq(shi_ji, qi_wang: int, biao_qian: String) -> void:
	# 记账员：失败只记账不爆炸——对比裸 assert() 的挂死陷阱
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %d，实际 %d）" % [biao_qian, qi_wang, shi_ji])


func _shu_sheng_ji_ci(_xin_deng_ji: int) -> void:
	# sheng_ji 信号接收器：只数次数
	sheng_ji_ci += 1


func _shu_shua_tiao_ci(_jing_yan: int, _yuzhi: int) -> void:
	# jing_yan_bian_hua 信号接收器：只数次数
	shua_tiao_ci += 1
