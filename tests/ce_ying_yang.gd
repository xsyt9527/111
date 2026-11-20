extends SceneTree
# 隐藏营养值系统纯逻辑测试（2026-11-20 提案·A 方案核心闭环）
# 用例 1 三档营养区间 + 越级夹取
# 用例 2 roll 区间内线性取值 + 下限兜底（不白吃）
# 用例 3 满营养概率判定 + 满营养营养值 = 档位上限×1.33
# 用例 4 玩家吃鱼经验乘算（四舍五入、下限 1、基础 0 不给）
# 用例 5 高营养信号（区间上 1/3）
# 用例 6 满营养成长上限 min(玩家+4, 6) + 开局 120 秒冻结
# 纪律：禁用裸 assert()；只调用纯函数，不入树、不造节点。

const YING_YANG := preload("res://scripts/ying_yang.gd")
const SHU_ZHI := preload("res://scripts/shu_zhi.gd")

var passed := 0
var failed := 0


func _initialize() -> void:
	# ---- 用例 1：三档区间 + 越级夹取 ----
	assert_jin(YING_YANG.qu_jian(1).x, 0.6, 0.001, "1档下限 0.6")
	assert_jin(YING_YANG.qu_jian(1).y, 0.9, 0.001, "1档上限 0.9")
	assert_jin(YING_YANG.qu_jian(2).x, 0.8, 0.001, "2档下限 0.8")
	assert_jin(YING_YANG.qu_jian(2).y, 1.2, 0.001, "2档上限 1.2")
	assert_jin(YING_YANG.qu_jian(3).x, 1.2, 0.001, "3档下限 1.2")
	assert_jin(YING_YANG.qu_jian(3).y, 1.6, 0.001, "3档上限 1.6")
	assert_jin(YING_YANG.qu_jian(0).x, 0.6, 0.001, "越级 0 夹到 1 档下限")
	assert_jin(YING_YANG.qu_jian(9).y, 1.6, 0.001, "越级 9 夹到 3 档上限")

	# ---- 用例 2：roll 线性取值 + 下限兜底 ----
	assert_jin(YING_YANG.roll_ying_yang(1, 0.0), 0.6, 0.001, "1档 suiji=0 → 0.6")
	assert_jin(YING_YANG.roll_ying_yang(1, 1.0), 0.9, 0.001, "1档 suiji=1 → 0.9")
	assert_jin(YING_YANG.roll_ying_yang(2, 0.5), 1.0, 0.001, "2档 suiji=0.5 → 1.0")
	assert_jin(YING_YANG.roll_ying_yang(3, 0.0), 1.2, 0.001, "3档 suiji=0 → 1.2")
	assert_jin(YING_YANG.roll_ying_yang(1, -0.5), 0.6, 0.001, "suiji 负值夹到下限")
	assert_jin(YING_YANG.roll_ying_yang(1, 2.0), 0.9, 0.001, "suiji 超 1 夹到上限")
	assert_jin(YING_YANG.roll_ying_yang(1, 0.5), 0.75, 0.001, "1档中值 0.75")

	# ---- 用例 3：满营养判定 + 满营养营养值 ----
	assert_guo_c(YING_YANG.shi_man_yang(0.0), true, "suiji=0 → 满营养命中")
	assert_guo_c(YING_YANG.shi_man_yang(0.029), true, "suiji=0.029 < 3% → 命中")
	assert_guo_c(YING_YANG.shi_man_yang(0.03), false, "suiji=0.03 = 3% → 不命中")
	assert_guo_c(YING_YANG.shi_man_yang(0.5), false, "suiji=0.5 → 不命中")
	# 满营养营养值 = 档位上限 ×1.33
	assert_jin(YING_YANG.man_yang_ying_yang(1), 0.9 * 1.33, 0.001, "1档满营养 ≈1.197")
	assert_jin(YING_YANG.man_yang_ying_yang(3), 1.6 * 1.33, 0.001, "3档满营养 ≈2.128")

	# ---- 用例 4：经验乘算 ----
	assert_eq(YING_YANG.jing_yan_cheng_shu(10, 1.0), 10, "营养 1.0 → 10 不变")
	assert_eq(YING_YANG.jing_yan_cheng_shu(10, 1.5), 15, "营养 1.5 → 15（挑肥鱼赚）")
	assert_eq(YING_YANG.jing_yan_cheng_shu(10, 0.6), 6, "营养 0.6 → 6（下限不白吃）")
	assert_eq(YING_YANG.jing_yan_cheng_shu(3, 1.33), 4, "3×1.33=3.99 四舍五入 → 4")
	assert_eq(YING_YANG.jing_yan_cheng_shu(1, 0.6), 1, "下限保障：基础1×0.6 也至少 1")
	assert_eq(YING_YANG.jing_yan_cheng_shu(0, 2.0), 0, "基础 0 → 不白送经验")
	assert_eq(YING_YANG.jing_yan_cheng_shu(10, 0.0), 6, "营养 0 兜底到下限 0.6 → 6")

	# ---- 用例 5：高营养信号（上 1/3）----
	# 1 档区间 0.6~0.9，上 1/3 起点 = 0.6 +(0.9-0.6)*(1-1/3)=0.8
	assert_guo_c(YING_YANG.shi_gao_ying_yang(1, 0.85), true, "1档 0.85 → 高营养信号")
	assert_guo_c(YING_YANG.shi_gao_ying_yang(1, 0.75), false, "1档 0.75 → 普通")
	assert_guo_c(YING_YANG.shi_gao_ying_yang(1, 0.9), true, "1档 0.9 顶格 → 高营养")

	# ---- 用例 6：成长上限 + 冻结 ----
	assert_eq(YING_YANG.man_yang_cheng_zhang_shang_xian(0), 4, "玩家0级 → 上限4")
	assert_eq(YING_YANG.man_yang_cheng_zhang_shang_xian(2), 6, "玩家2级 → 上限6")
	assert_eq(YING_YANG.man_yang_cheng_zhang_shang_xian(9), 6, "玩家9级 → 封顶6（不超模）")
	assert_guo_c(YING_YANG.ke_cheng_zhang(1, 2, 119.9), false, "119.9 秒 < 120 → 冻结")
	assert_guo_c(YING_YANG.ke_cheng_zhang(1, 2, 120.0), true, "120 秒整 → 可成长")
	assert_guo_c(YING_YANG.ke_cheng_zhang(6, 9, 300.0), false, "已满 6 级 → 不再成长")
	assert_guo_c(YING_YANG.ke_cheng_zhang(5, 9, 300.0), true, "5 级未封顶 → 可成长")

	# ---- 收卷 ----
	print("[ce_ying_yang] passed=%d failed=%d" % [passed, failed])
	print("结论：%s" % ("全绿：营养值系统纯逻辑通过" if failed == 0 else "有失败：需修复"))
	quit(1 if failed > 0 else 0)


func assert_eq(shi_ji, qi_wang: int, biao_qian: String) -> void:
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %d，实际 %d）" % [biao_qian, qi_wang, shi_ji])


func assert_jin(shi_ji: float, qi_wang: float, rong_cha: float, biao_qian: String) -> void:
	if absf(shi_ji - qi_wang) <= rong_cha:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %.4f±%.4f，实际 %.4f）" % [biao_qian, qi_wang, rong_cha, shi_ji])


func assert_guo_c(shi_ji: bool, qi_wang: bool, biao_qian: String) -> void:
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %s，实际 %s）" % [biao_qian, qi_wang, shi_ji])
