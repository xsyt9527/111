extends SceneTree
# 账本纯逻辑测试（第 9 课 step-01 测试基建）
# 运行方式：Godot --headless --path . --script tests/ce_zhang_ben.gd
# --script 模式不加载 Autoload，被测账本不走全局 ZhangBen，
# 而是 load().new() 建独立实例——每个用例都从干净状态开始（测试独立性）。
# 纪律：全程禁用裸 assert()——失败会中断脚本，quit() 永不执行，进程挂死。
# 架构：等级 = 体型上限（只升不降）；当前体型 = 血量（受伤扣、吃东西回）

var passed := 0  # 通过计数（收卷用）
var failed := 0  # 失败计数（退出码的依据）
var si_wang_ci := 0  # si_wang 广播计数（死亡只报一次）


func _initialize() -> void:
	# ---- 用例 1：记账累加（不跨阈值，只加不升）----
	var zb: Node = load("res://scripts/zhang_ben.gd").new()  # load() 返回 Variant，必须显式类型标注
	zb.jia_jing_yan(2)
	zb.jia_jing_yan(1)
	assert_eq(zb.jing_yan, 3, "记账累加：2+1 应为 3")
	assert_eq(zb.deng_ji, 0, "开局 Lv.0，未跨阈值 4 不应升级")
	zb.free()  # 不入树的实例用完即弃，避免退出时报资源占用

	# ---- 用例 2：跨级升级扣减（余量带入下一级）----
	var zb2: Node = load("res://scripts/zhang_ben.gd").new()
	zb2.jia_jing_yan(13)  # Lv.0 阈值 10：13-10=3，余量带入 Lv.1
	assert_eq(zb2.deng_ji, 1, "灌 13 过阈值 10 应升到 Lv.1")
	assert_eq(zb2.jing_yan, 3, "升级应扣掉已用阈值（13-10=3）")
	zb2.jia_jing_yan(11)  # 3+11=14 过 Lv.1 阈值 12：14-12=2
	assert_eq(zb2.deng_ji, 2, "余 3 再灌 11 过阈值 12 应升到 Lv.2")
	assert_eq(zb2.jing_yan, 2, "扣减后余量 14-12=2")
	assert_float(zb2.dang_qian_ti_xing, 3.0, "升级回满血：Lv.2 上限 = 2+1 = 3.0")
	zb2.free()  # 不入树的实例用完即弃，避免退出时报资源占用

	# ---- 用例 3：倍率入账（照抄 yu_npc.gd 真实调用姿势）----
	var zb3: Node = load("res://scripts/zhang_ben.gd").new()
	zb3.deng_ji = 5  # 抬高等级避开阈值，单测“倍率”这一件事
	zb3.she_jing_yan_jia_cheng(1.5)  # 睿智卡：倍率的唯一所有者是账本
	zb3.jia_jing_yan(int(4 * zb3.jing_yan_jia_cheng))  # 倍率在调用方乘算，账本只收整数
	assert_eq(zb3.jing_yan, 6, "倍率入账：4 分 ×1.5 应记 6")
	zb3.free()  # 不入树的实例用完即弃，避免退出时报资源占用

	# ---- 用例 4：阈值曲线（10 × 1.2^等级，等级无上限也算得出）----
	var zb4: Node = load("res://scripts/zhang_ben.gd").new()
	assert_eq(zb4.dangqian_yuzhi(), 10, "Lv.0 阈值 = 10 × 1.2^0 = 10")
	zb4.deng_ji = 1  # 直接设等级，单测曲线这一件事
	assert_eq(zb4.dangqian_yuzhi(), 12, "Lv.1 阈值 = 10 × 1.2 = 12")
	zb4.deng_ji = 7
	assert_eq(zb4.dangqian_yuzhi(), 36, "Lv.7 阈值 ≈ 35.8，四舍五入 36")
	zb4.deng_ji = 9
	assert_eq(zb4.dangqian_yuzhi(), 52, "Lv.9 阈值 ≈ 51.6 → 52：越过旧上限仍有值")
	zb4.deng_ji = 20
	assert_eq(zb4.dangqian_yuzhi(), 383, "Lv.20 阈值 ≈ 383：固定表早就不够，曲线继续算")
	zb4.free()  # 不入树的实例用完即弃，避免退出时报资源占用

	# ---- 用例 5：体型上限 = 等级 + 1 ----
	var zb5: Node = load("res://scripts/zhang_ben.gd").new()
	assert_float(zb5.ti_xing_shang_xian(), 1.0, "Lv.0 上限 = 基础 1.0（0 级也要能玩）")
	assert_float(zb5.dang_qian_ti_xing, 1.0, "开局满血")
	zb5.deng_ji = 8
	assert_float(zb5.ti_xing_shang_xian(), 9.0, "满级 Lv.8 上限 = 8+1 = 9.0")
	zb5.free()

	# ---- 用例 6：受伤扣当前体型（血量），不动等级上限 ----
	var zb6: Node = load("res://scripts/zhang_ben.gd").new()
	zb6.si_wang.connect(_shu_si_wang)
	zb6.shou_shang()  # Lv.0 血量 1.0 - 1.0 = 0
	assert_float(zb6.dang_qian_ti_xing, 0.0, "Lv.0 挨一次扣 1.0 → 血量归零")
	assert_eq(zb6.deng_ji, 0, "受伤只扣血量，等级上限不动")
	assert_eq(si_wang_ci, 1, "血量归零应广播 si_wang 一次")
	zb6.shou_shang()  # 已死再挨打
	assert_eq(si_wang_ci, 1, "已归零后不重复广播 si_wang")
	assert_eq(int(zb6.dang_qian_ti_xing * 10.0), 0, "已归零后也不会扣成负数")
	zb6.free()

	# ---- 用例 7：回血（吃东西回，封顶在上限）----
	var zb7: Node = load("res://scripts/zhang_ben.gd").new()
	zb7.deng_ji = 5
	zb7.dang_qian_ti_xing = 6.0
	zb7.shou_shang()  # 6.0 - 1.0 = 5.0
	assert_float(zb7.dang_qian_ti_xing, 5.0, "Lv.5 受伤扣 1.0：6.0 → 5.0")
	assert_eq(zb7.deng_ji, 5, "受伤不降级")
	zb7.hui_ti_xing(0.25)  # 吃食物
	assert_float(zb7.dang_qian_ti_xing, 5.25, "吃食物回 0.25：5.0 → 5.25")
	zb7.hui_ti_xing(99.0)  # 灌一大口
	assert_float(zb7.dang_qian_ti_xing, 6.0, "回血封顶在当前等级上限（5+1=6.0）")
	zb7.free()

	# ---- 用例 8：饥饿下降与回饥饿（封顶 100）----
	var zb8: Node = load("res://scripts/zhang_ben.gd").new()
	assert_float(zb8.ji_e, 100.0, "开局饥饿满格 100")
	zb8.xia_jiang_ji_e(2.0)
	assert_float(zb8.ji_e, 95.0, "饥饿每秒降 2.5：2 秒后 95")
	zb8.hui_ji_e(10.0)
	assert_float(zb8.ji_e, 100.0, "吃一口回 10，封顶 100")
	zb8.ji_e = 50.0
	zb8.hui_ji_e(10.0)
	assert_float(zb8.ji_e, 60.0, "半饱吃一口：50 → 60")
	zb8.free()

	# ---- 用例 9：饥饿归零 → 每秒扣 0.1 当前体型，扣到 0 广播死亡 ----
	var zb9: Node = load("res://scripts/zhang_ben.gd").new()
	si_wang_ci = 0
	zb9.si_wang.connect(_shu_si_wang)
	zb9.ji_e = 0.0
	zb9.xia_jiang_ji_e(0.5)
	assert_float(zb9.dang_qian_ti_xing, 1.0, "归零不足 1 秒：先不扣体型")
	zb9.xia_jiang_ji_e(0.5)
	assert_float(zb9.dang_qian_ti_xing, 0.9, "归零满 1 秒：扣 0.1 当前体型")
	assert_eq(zb9.deng_ji, 0, "饿死也不掉等级")
	zb9.hui_ji_e(10.0)  # 吃一口，脱离饥饿
	zb9.ji_e = 0.0  # 再饿回去：计时器应已清零
	zb9.xia_jiang_ji_e(0.5)
	assert_float(zb9.dang_qian_ti_xing, 0.9, "吃东西后饿死计时重新攒：0.5 秒不扣")
	zb9.xia_jiang_ji_e(0.5)
	assert_float(zb9.dang_qian_ti_xing, 0.8, "重新攒满 1 秒才扣")
	zb9.dang_qian_ti_xing = 0.1  # 只剩最后一丝
	zb9.xia_jiang_ji_e(1.0)
	assert_float(zb9.dang_qian_ti_xing, 0.0, "饥饿扣到 0：死亡")
	assert_eq(si_wang_ci, 1, "饿死应广播 si_wang 一次")
	assert_eq(1 if not zb9.sheng_cun_zhong else 0, 1, "死亡后饥饿时钟停止")
	zb9.xia_jiang_ji_e(5.0)
	assert_float(zb9.dang_qian_ti_xing, 0.0, "死后不再扣体型")
	zb9.free()

	# ---- 用例 10：吃鱼回饥饿的档位（路人鱼 10 / 普通 8 / 鲸鲨 30）----
	var zb10: Node = load("res://scripts/zhang_ben.gd").new()
	assert_float(zb10.chi_yu_hui_ji_e(1), 10.0, "路人鱼（1 级）回 10 饥饿")
	assert_float(zb10.chi_yu_hui_ji_e(5), 8.0, "普通鱼回 8 饥饿")
	assert_float(zb10.chi_yu_hui_ji_e(10), 30.0, "鲸鲨回 30 饥饿")
	zb10.free()

	# ---- 用例 11：体型→像素曲线（等级无上限：高等级不能再线性放大）----
	var zb11: Node = load("res://scripts/zhang_ben.gd").new()
	assert_float(zb11.ti_xing_dao_chi_du(1.0), 0.32, "Lv.0（体型 1）显示缩放仍是 0.32")
	assert_eq(1 if zb11.ti_xing_dao_chi_du(9.0) < 9.0 * 0.32 else 0, 1, "高等级显示增长必须小于线性（否则 8 级撑爆屏幕）")
	assert_eq(1 if zb11.ti_xing_dao_chi_du(9.0) > zb11.ti_xing_dao_chi_du(8.0) else 0, 1, "曲线仍单调：体型越大看起来越大")
	zb11.free()

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
	# 血量是 float：浮点比较走 is_equal_approx，别拿 == 赌二进制精度
	if is_equal_approx(shi_ji, qi_wang):
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %.2f，实际 %.2f）" % [biao_qian, qi_wang, shi_ji])


func _shu_si_wang() -> void:
	# si_wang 接收器：只数次数，不碰被测对象
	si_wang_ci += 1
