extends SceneTree
# 咬击纯逻辑测试（TASK-012）：A2 掉目标当前体型 3%、嘴巴系数、A4 致命区 ×3、一击必杀
# 运行：Godot --headless --path . --script tests/ce_zhan_dou.gd --quit-after 360
# 数值出处：2026-11-08 A 核心数值表（shu_zhi.gd）；函数是玩家/NPC 共用的唯一出口
# 纪律：禁用裸 assert()——失败会中断脚本，quit() 永不执行，进程挂死

const ZD = preload("res://scripts/zhan_dou.gd")

var passed := 0  # 通过计数（收卷用）
var failed := 0  # 失败计数（退出码的依据）


func _initialize() -> void:
	# ---- 用例 1：普通咬击 = 目标当前体型 ×3% × 嘴巴系数（A2；保底 0.01）----
	# 第二参是防御方体型；不传时按攻击者体型估算（同体型近似）
	assert_xiang_deng(ZD.yao_ji_shang_hai(1.0), 0.03, "1 级普通嘴咬同体型：3% → 0.03")
	assert_xiang_deng(ZD.yao_ji_shang_hai(3.0), 0.09, "3 级普通嘴咬同体型：3% → 0.09")
	assert_xiang_deng(ZD.yao_ji_shang_hai(10.0), 0.3, "10 级（鲸鲨）咬同体型：3% → 0.30")
	assert_xiang_deng(ZD.yao_ji_shang_hai(4.0, 4.0, 1.5), 0.18,
			"巨口鱼（嘴巴 1.5）咬 4 级鱼：4×3%×1.5 = 0.18")
	assert_xiang_deng(ZD.yao_ji_shang_hai(1.0, 0.5), 0.015,
			"1 级鱼咬 0.5 体型：只掉 0.5×3% = 0.015")
	assert_xiang_deng(ZD.yao_ji_shang_hai(10.0, 2.0), 0.06,
			"10 级鱼咬 2 体型：只掉 2×3% = 0.06（按目标体型，不看攻击者）")
	assert_xiang_deng(ZD.yao_ji_shang_hai(1.0, 0.01), 0.01,
			"A2 保底：目标体型趋零时每口仍保底 0.01")

	# ---- 用例 1b：致命区 = 普通咬 ×3（A4）----
	assert_xiang_deng(ZD.zhi_ming_shang_hai(5.0, 5.0), 0.45,
			"A4 致命区：同级 5 体型普通咬 0.15 → 致命区 0.45")
	assert_xiang_deng(ZD.zhi_ming_shang_hai(3.0, 10.0), 0.9,
			"A4 致命区按目标体型：10×3%×3 = 0.9")

	# ---- 用例 2：致命区 —— 攻击者体型 ≥ 目标（策划案 8.1）----
	assert_eq(1 if ZD.zhi_ming_ke_sha(11.0, 10.0) else 0, 1, "11 对 10：更大，可一击必杀")
	assert_eq(1 if ZD.zhi_ming_ke_sha(10.0, 10.0) else 0, 1, "10 对 10：同级咬头也致命")
	assert_eq(1 if ZD.zhi_ming_ke_sha(4.0, 4.0) else 0, 1, "同级咬头必杀（咬大鱼的小门槛）")
	assert_eq(1 if ZD.zhi_ming_ke_sha(9.9, 10.0) else 0, 0, "9.9 对 10：差一点，只是普通咬击")
	assert_eq(1 if ZD.zhi_ming_ke_sha(0.5, 1.0) else 0, 0, "小鱼咬大鱼头：也咬不死")

	# ---- 收卷：退出码是唯一门禁语言 ----
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func assert_eq(shi_ji: int, qi_wang: int, biao_qian: String) -> void:
	# 记账员：失败只记账不爆炸——对比裸 assert() 的挂死陷阱
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %d，实际 %d）" % [biao_qian, qi_wang, shi_ji])


func assert_xiang_deng(shi_ji: float, qi_wang: float, biao_qian: String) -> void:
	# 浮点断言适配器：伤害是 float，断言助手只认 int
	assert_eq(1 if is_equal_approx(shi_ji, qi_wang) else 0, 1, biao_qian)
