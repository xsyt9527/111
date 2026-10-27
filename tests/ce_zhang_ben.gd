extends SceneTree
# 账本纯逻辑测试（第 9 课 step-01 测试基建）
# 运行方式：Godot --headless --path . --script tests/ce_zhang_ben.gd
# --script 模式不加载 Autoload，被测账本不走全局 ZhangBen，
# 而是 load().new() 建独立实例——每个用例都从干净状态开始（测试独立性）。
# 纪律：全程禁用裸 assert()——失败会中断脚本，quit() 永不执行，进程挂死。

var passed := 0  # 通过计数（收卷用）
var failed := 0  # 失败计数（退出码的依据）


func _initialize() -> void:
	# ---- 用例 1：记账累加（不跨阈值，只加不升）----
	var zb: Node = load("res://scripts/zhang_ben.gd").new()  # load() 返回 Variant，必须显式类型标注
	zb.jia_jing_yan(2)
	zb.jia_jing_yan(3)
	assert_eq(zb.jing_yan, 5, "记账累加：2+3 应为 5")
	assert_eq(zb.deng_ji, 1, "未跨阈值不应升级")
	zb.free()  # 不入树的实例用完即弃，避免退出时报资源占用

	# ---- 用例 2：跨级升级扣减（余量带入下一级）----
	var zb2: Node = load("res://scripts/zhang_ben.gd").new()
	zb2.jia_jing_yan(10)  # Lv.1 阈值 8：10-8=2，余量带入 Lv.2
	assert_eq(zb2.deng_ji, 2, "灌 10 过阈值 8 应升到 Lv.2")
	assert_eq(zb2.jing_yan, 2, "升级应扣掉已用阈值（10-8=2）")
	zb2.jia_jing_yan(20)  # 2+20=22 过 Lv.2 阈值 20：22-20=2
	assert_eq(zb2.deng_ji, 3, "余 2 再灌 20 过阈值 20 应升到 Lv.3")
	assert_eq(zb2.jing_yan, 2, "扣减后余量 22-20=2")
	zb2.free()  # 不入树的实例用完即弃，避免退出时报资源占用

	# ---- 用例 3：倍率入账（照抄 yu_npc.gd 真实调用姿势）----
	var zb3: Node = load("res://scripts/zhang_ben.gd").new()
	zb3.she_jing_yan_jia_cheng(1.5)  # 睿智卡：倍率的唯一所有者是账本
	zb3.jia_jing_yan(int(4 * zb3.jing_yan_jia_cheng))  # 倍率在调用方乘算，账本只收整数
	assert_eq(zb3.jing_yan, 6, "倍率入账：4 分 ×1.5 应记 6")
	zb3.free()  # 不入树的实例用完即弃，避免退出时报资源占用

	# ---- 用例 4：阈值读表（等级换挡，数值出自 sheng_ji_biao.tres）----
	var zb4: Node = load("res://scripts/zhang_ben.gd").new()
	assert_eq(zb4.dangqian_yuzhi(), 8, "Lv.1 阈值应读表首 8")
	zb4.deng_ji = 3  # 直接设等级，单测读表这一件事
	assert_eq(zb4.dangqian_yuzhi(), 35, "Lv.3 阈值应读表第三项 35")
	zb4.free()  # 不入树的实例用完即弃，避免退出时报资源占用

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
