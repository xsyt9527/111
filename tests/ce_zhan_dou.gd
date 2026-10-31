extends SceneTree
# 咬击纯逻辑测试（TASK-012）：伤害公式 × 嘴巴系数、致命区 ≥、无咬击资格
# 运行：Godot --headless --path . --script tests/ce_zhan_dou.gd --quit-after 360
# 数值出处：策划案 8.1（致命区 ≥）/ 8.4（嘴巴决定咬速）；函数是玩家/NPC 共用的唯一出口
# 纪律：禁用裸 assert()——失败会中断脚本，quit() 永不执行，进程挂死

const ZD = preload("res://scripts/zhan_dou.gd")

var passed := 0  # 通过计数（收卷用）
var failed := 0  # 失败计数（退出码的依据）


func _initialize() -> void:
	# ---- 用例 1：咬击伤害 =（0.15 × 攻击者体型 + 0.05）× 嘴巴系数 ----
	assert_xiang_deng(ZD.yao_ji_shang_hai(1.0), 0.2, "1 级普通嘴咬一口 0.2")
	assert_xiang_deng(ZD.yao_ji_shang_hai(3.0), 0.5, "3 级普通嘴咬一口 0.5")
	assert_xiang_deng(ZD.yao_ji_shang_hai(10.0), 1.55, "10 级（鲸鲨）普通嘴咬一口 1.55")
	assert_xiang_deng(ZD.yao_ji_shang_hai(4.0, 1.5), 0.975, "巨口鱼（嘴巴 1.5）咬一口 0.975")
	assert_xiang_deng(ZD.yao_ji_shang_hai(1.0, 0.5), 0.1, "嘴巴 0.5 的鱼咬一口只有 0.1")
	assert_xiang_deng(ZD.yao_ji_shang_hai(10.0, 2.0), 3.1, "鲸鲨（嘴巴 2.0）咬一口 3.1")

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
