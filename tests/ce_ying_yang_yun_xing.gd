extends Node2D
# 隐藏营养值系统·运行时集成测试（2026-11-20）
# 场景模式（extends Node2D + _ready）：--script 模式不加载 Autoload，而满营养成长/掉肉要读 ZhangBen，
# 所以走 .tscn 场景模式——起本场景 = 真引擎循环 + Autoload 全就位。
# 运行：Godot --headless --path . res://tests/ce_ying_yang_yun_xing.tscn --quit-after 120
# 覆盖：出生营养字段、满营养营养值、信号、静默成长、营养肉块掉落路径不报错。
const YU_NPC_CHANGJING := preload("res://scenes/YuNpc.tscn")
const YING_YANG := preload("res://scripts/ying_yang.gd")

var passed := 0
var failed := 0
var gen: Node = null


func _ready() -> void:
	gen = Node.new()
	add_child(gen)
	var shu := get_tree()

	# ---- 用例 1：新鱼出生营养字段落在合理区间 ----
	var zhong: YuZhong = load("res://data/yuzhong/lan_yu.tres")  # 1 档钻光鱼
	var yu: YuNpc = YU_NPC_CHANGJING.instantiate()
	yu.yu_zhong = zhong
	yu.ai_kai_qi = false
	gen.add_child(yu)
	var qu := YING_YANG.qu_jian(zhong.ying_yang_dang)
	assert_guo_c(yu.ying_yang_zhi >= qu.x - 0.001 and yu.ying_yang_zhi <= qu.y * 2.0 + 0.001,
			true, "出生营养值落在合理区间（普通或满营养上沿）")

	# ---- 用例 2：强制满营养 → 营养值 = 档位上限×1.33、信号点亮、静默成长推进不报错 ----
	var man: YuNpc = YU_NPC_CHANGJING.instantiate()
	man.yu_zhong = zhong
	man.ai_kai_qi = false
	gen.add_child(man)
	man.man_yang_pin = true
	man.ying_yang_zhi = YING_YANG.man_yang_ying_yang(1)
	man.geng_xin_ying_yang_xin_hao()
	assert_jin(man.ying_yang_zhi, 0.9 * 1.33, 0.001, "满营养营养值 ≈1.197")
	var deng_qian := man.deng_ji_nei
	# 直接推静默成长：把累计时间喂满一个节拍（绕过 120 秒开局冻结需设局内时钟）
	var jiu_shi := ZhangBen.ju_nei_shi_jian
	ZhangBen.ju_nei_shi_jian = 200.0  # 越过开局保护
	man._zou_man_yang_cheng_zhang(SHU_ZHI_CHENG_ZHANG_JIAN_GE)
	ZhangBen.ju_nei_shi_jian = jiu_shi
	assert_guo_c(man.deng_ji_nei > deng_qian, true, "满营养鱼满 20 秒静默成长 → 隐藏等级 +1")

	# ---- 用例 3：满营养鱼死亡掉营养肉块（走 bei_chi 路径）----
	var si: YuNpc = YU_NPC_CHANGJING.instantiate()
	si.yu_zhong = zhong
	si.ai_kai_qi = false
	gen.add_child(si)
	si.man_yang_pin = true
	si.ying_yang_zhi = 1.6
	var rou_qian := _rou_shu()
	si.bei_chi(false, null)  # NPC 被吃路径：触发掉营养肉块（非物理帧 add_child 同步落地）
	var rou_hou := _rou_shu()
	assert_guo_c(rou_hou >= rou_qian + 1, true, "满营养鱼死亡掉 1 块营养肉块")

	# ---- 用例 4：A 方案出生锁 1 级（普通鱼 1 级、首领保留鱼种等级）----
	var yi_ban: YuNpc = YU_NPC_CHANGJING.instantiate()
	yi_ban.yu_zhong = load("res://data/yuzhong/qi_yu.tres")  # 旗鱼鱼种 Lv.6
	yi_ban.ai_kai_qi = false
	yi_ban.chu_sheng_suo_ding = true  # 刷怪管线注入
	gen.add_child(yi_ban)
	assert_eq(yi_ban.deng_ji_nei, 1, "出生锁：旗鱼(Lv.6鱼种)实际出生隐藏等级 1")
	assert_guo_c(is_equal_approx(yi_ban.tixing, 1.0), true, "出生锁：体型 1.0")

	# ---- 用例 5：互吃成长 = 对方等级 ×0.5（普通鱼走直接加级）----
	var chi_zhe: YuNpc = YU_NPC_CHANGJING.instantiate()
	chi_zhe.yu_zhong = zhong
	chi_zhe.ai_kai_qi = false
	chi_zhe.chu_sheng_suo_ding = true
	gen.add_child(chi_zhe)
	var bei_tun: YuNpc = YU_NPC_CHANGJING.instantiate()
	bei_tun.yu_zhong = zhong
	bei_tun.ai_kai_qi = false
	gen.add_child(bei_tun)
	bei_tun.deng_ji_nei = 4  # 被吞方 4 级 → 吃方 +2.0 级（add_child 后设，避开 _ready 出生锁覆盖）
	var deng_qian_chi := chi_zhe.deng_ji_nei
	var zeng_liang := YING_YANG.hu_chi_cheng_zhang_lian(bei_tun.deng_ji_nei)
	chi_zhe.jia_deng_ji_zhi_jie(zeng_liang)
	assert_eq(chi_zhe.deng_ji_nei, deng_qian_chi + 2, "互吃 4 级鱼 → 吃方隐藏等级 +2")

	# ---- 用例 6：饵料鱼层节点可创建、被吃回调 +0.2 级 ----
	var er: Node2D = load("res://scripts/er_liao_yu.gd").new()
	gen.add_child(er)
	assert_guo_c(er.is_in_group("er_liao_yu"), true, "饵料鱼进 er_liao_yu 组")
	var er_qian_deng := chi_zhe._deng_ji_yu_liang
	er.bei_chi(chi_zhe)
	assert_jin(chi_zhe._deng_ji_yu_liang, er_qian_deng + 0.2, 0.001, "吃饵料鱼 → 成长余量 +0.2")

	# ---- 用例 7：埋点三条接口可调用、计数正确 ----
	var qian_jian := int(ZhangBen.mai_dian_tun_zong)
	ZhangBen.ji_mai_dian_tun(true)
	assert_eq(ZhangBen.mai_dian_tun_zong, qian_jian + 1, "埋点②：吞鱼计数 +1")
	ZhangBen.ji_mai_dian_chu_sheng(3, true)
	assert_guo_c(int(ZhangBen.mai_dian_ying_yang_qu_jian.get("满营养", 0)) >= 1,
			true, "埋点①：出生分布记录满营养")

	# ---- 收卷 ----
	print("[ce_ying_yang_yun_xing] passed=%d failed=%d" % [passed, failed])
	print("结论：%s" % ("全绿：营养值运行时链路通过" if failed == 0 else "有失败：需修复"))
	shu.quit(1 if failed > 0 else 0)


const SHU_ZHI_CHENG_ZHANG_JIAN_GE := 20.0  # 与 shu_zhi.MAN_YANG_CHENG_ZHANG_JIAN_GE 一致


func _rou_shu() -> int:
	var shu := 0
	for zi in gen.get_children():
		if zi is RouKuai and zi.ying_yang_rou:
			shu += 1
	return shu


func assert_guo_c(shi_ji: bool, qi_wang: bool, biao_qian: String) -> void:
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %s，实际 %s）" % [biao_qian, qi_wang, shi_ji])


func assert_eq(shi_ji, qi_wang, biao_qian: String) -> void:
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %s，实际 %s）" % [biao_qian, str(qi_wang), str(shi_ji)])


func assert_jin(shi_ji: float, qi_wang: float, rong_cha: float, biao_qian: String) -> void:
	if absf(shi_ji - qi_wang) <= rong_cha:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %.4f±%.4f，实际 %.4f）" % [biao_qian, qi_wang, rong_cha, shi_ji])
