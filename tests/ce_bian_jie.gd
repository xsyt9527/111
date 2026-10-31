extends SceneTree
# 边界测试（第 9 课 step-02：第 8 课两个一次性探针转正为常驻测试）
# 用例 1 等级无上限：分次喂到旧上限 Lv.8 之后仍能继续升 → 再灌一大口还能升
# 用例 2 chong_zhi 归零：弄脏账本各项 → 归零断言（Autoload 常驻者的复位义务）
# 纪律：禁用裸 assert()；不入树实例用完 free()（资源卫生）
# 注意：jia_jing_yan() 内是 if 不是 while——单次最多升一级，喂经验必须分次

var passed := 0  # 通过计数（收卷用）
var failed := 0  # 失败计数（退出码的依据）
var sheng_ji_ci := 0  # sheng_ji 广播计数（升级）
var shua_tiao_ci := 0  # jing_yan_bian_hua 广播计数（刷条）


func _initialize() -> void:
	# ---- 用例 1：等级无上限（曲线阈值 → 越过旧上限 Lv.8 继续升）----
	var zb: Node = load("res://scripts/zhang_ben.gd").new()
	zb.sheng_ji.connect(_shu_sheng_ji_ci)  # 接收器只做计数，不碰被测对象
	zb.jing_yan_bian_hua.connect(_shu_shua_tiao_ci)
	var lun := 0  # 喂食轮次保险（防死循环：异常时 100 轮内必停）
	while zb.deng_ji < 12 and lun < 100:
		zb.jia_jing_yan(200)  # 分次喂：每轮最多跨一道阈值
		lun += 1
	assert_eq(zb.deng_ji, 12, "分次喂 200 应越过旧上限 8，升到 Lv.12")
	assert_eq(sheng_ji_ci, 12, "升级广播恰好 12 次（Lv.1~12，开局 Lv.0）")
	assert_float(zb.dang_qian_ti_xing, 13.0, "Lv.12 当前体型回满到上限 13.0")
	zb.jia_jing_yan(100000)  # 无上限：再灌一大口
	assert_eq(zb.deng_ji, 13, "再灌 100000 仍能升到 Lv.13（不存在封顶）")
	assert_eq(sheng_ji_ci, 13, "超越 Lv.12 后仍会广播 sheng_ji")
	zb.free()

	# ---- 用例 2：chong_zhi 归零（独立实例——不接着用例 1 的脏状态）----
	var zb2: Node = load("res://scripts/zhang_ben.gd").new()
	var fang_dian: NengLi = load("res://data/nengli/fang_dian_ma_bi.tres")
	var du_ji: NengLi = load("res://data/nengli/du_ji_hu_ti.tres")
	var dian_yao: XingTai = load("res://data/xingtai/dian_yao.tres")
	zb2.jia_jing_yan(10)  # 弄脏 1：经验恰好用光 + 等级 Lv.1
	zb2.shou_shang()  # 弄脏 2：血量扣掉 1 点
	zb2.xuan_neng_li(fang_dian)  # 弄脏 3：主动一
	zb2.xuan_neng_li(load("res://data/nengli/ji_su_tu_jin.tres"))  # 弄脏 3b：主动二（多槽）
	zb2.xuan_neng_li(du_ji)  # 弄脏 4：被动
	zb2.ji_chi_yu(du_ji)  # 弄脏 5：食谱
	zb2.ji_e = 30.0  # 弄脏 6：饥饿
	zb2.dian_ma = 70.0  # 弄脏 7：电麻条
	zb2.du_yun = 40.0  # 弄脏 8：毒晕条
	zb2.yun_xuan_ji_shi = 1.5  # 弄脏 9：失控计时
	zb2.kai_ju_xing_tai(dian_yao)  # 弄脏 10：形态引用与应用标记
	assert_eq(zb2.deng_ji, 1, "脏状态预检：应已升到 Lv.1（10 恰达阈值 10）")
	assert_eq(1 if not zb2.zhu_dong_zu.is_empty() else 0, 1, "脏状态预检：应已装备主动")
	assert_eq(zb2.zhu_dong_zu.size(), 2, "脏状态预检：多槽应已装 2 个主动")
	assert_eq(zb2.dang_qian_bei_dong_ceng(&"du_ji_hu_ti"), 1, "脏状态预检：被动应 1 层")
	assert_eq(1 if zb2.dang_qian_xing_tai != null else 0, 1, "脏状态预检：应已装形态")
	zb2.chong_zhi()
	assert_eq(zb2.jing_yan, 0, "复位后经验归零")
	assert_eq(zb2.deng_ji, 0, "复位后等级归开局 Lv.0")
	assert_float(zb2.dang_qian_ti_xing, 1.0, "复位后当前体型归基础 1.0")
	assert_eq(1 if zb2.zhu_dong_zu.is_empty() else 0, 1, "复位后主动组清空（含多槽）")
	assert_eq(zb2.bei_dong_ceng.size(), 0, "复位后被动层数清空")
	assert_eq(zb2.yi_xuan_neng_li.size(), 0, "复位后获得历史清空")
	assert_eq(zb2.chi_yu_ji_lu.size(), 0, "复位后食谱清空")
	assert_eq(1 if zb2.zui_duo_bian_hao == &"" else 0, 1, "复位后最常吃 id 清空")
	assert_float(zb2.ji_e, 100.0, "复位后饥饿回满 100")
	assert_eq(1 if zb2.sheng_cun_zhong else 0, 1, "复位后饥饿时钟重新走")
	assert_float(zb2.dian_ma, 0.0, "复位后电麻条归零")
	assert_float(zb2.du_yun, 0.0, "复位后毒晕条归零")
	assert_float(zb2.yun_xuan_ji_shi, 0.0, "复位后失控计时归零")
	assert_eq(1 if zb2.dang_qian_xing_tai == null else 0, 1, "复位后形态引用清空")
	assert_eq(1 if not zb2.xing_tai_yi_ying_yong else 0, 1, "复位后形态应用标记清空")
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


func assert_float(shi_ji: float, qi_wang: float, biao_qian: String) -> void:
	# 血量是 float：浮点比较走 is_equal_approx
	if is_equal_approx(shi_ji, qi_wang):
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %.2f，实际 %.2f）" % [biao_qian, qi_wang, shi_ji])


func _shu_sheng_ji_ci(_xin_deng_ji: int) -> void:
	# sheng_ji 信号接收器：只数次数
	sheng_ji_ci += 1


func _shu_shua_tiao_ci(_jing_yan: int, _yuzhi: int) -> void:
	# jing_yan_bian_hua 信号接收器：只数次数
	shua_tiao_ci += 1
