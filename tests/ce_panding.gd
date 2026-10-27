extends Node2D
# 判定集成测试（第 9 课 step-04：探针场景模式转正）
# 与前三个测试的区别：--script 模式不加载 Autoload，而 bei_chi 记账要 ZhangBen、
# 玩家 _ready 要连 ZhangBen 信号——所以走场景模式：起本场景 = 真引擎循环 + Autoload 全就位，
# Area2D 的 area_entered 由真物理帧触发（不是手动调函数）。
# 运行：Godot --headless --path . res://tests/ce_panding_chang_jing.tscn --quit-after 360
# 纪律：禁用裸 assert()；玩家不吃到死（血 3 只扣 2，避免触发切结算页）

var passed := 0  # 通过计数（收卷用）
var failed := 0  # 失败计数（退出码的依据）


func _ready() -> void:
	# ---- 搭台：玩家进树（先设位置再进——_ready 会拿 position 当游动目标点）----
	var yu: Yu = load("res://scenes/Yu.tscn").instantiate()
	yu.position = Vector2(400, 400)
	add_child(yu)
	await get_tree().physics_frame  # 等一帧：三个圈注册进物理世界

	# ---- 用例 1：小鱼进嘴圈 → 被吃 ----
	var xiao: YuNpc = _zao_yu(0.5)  # 比玩家（tixing=1.0）小
	xiao.position = yu.position  # 传送进玩家嘴里：三圈全重叠
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(1 if not is_instance_valid(xiao) else 0, 1, "小鱼进嘴圈应被吃（释放离场）")

	# ---- 用例 2：大鱼进嘴圈无事 + 伤区掉血 + 无敌期不重复伤 ----
	var da: YuNpc = _zao_yu(2.0)  # 比玩家大
	da.position = yu.position
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(1 if is_instance_valid(da) else 0, 1, "大鱼进嘴圈应无事（嘴圈只吃小的）")
	assert_eq(yu.xue_liang, 2, "大鱼进伤区应掉 1 血（3→2）")
	assert_eq(1 if yu.wudi else 0, 1, "受伤后应进入无敌期")
	await get_tree().physics_frame
	await get_tree().physics_frame  # 大鱼还压在身上
	assert_eq(yu.xue_liang, 2, "无敌期内大鱼压着也不重复掉血")
	da.position = Vector2(400, 650)  # 大鱼撤走，给用例 3 腾地方
	await get_tree().physics_frame

	# ---- 用例 3：同体型 → 掉血但不被吃（吃是严格大于，伤是大于等于）----
	await yu.wudi_dingshi.timeout  # 等无敌期真正结束（等信号，不等猜的秒数）
	assert_eq(1 if not yu.wudi else 0, 1, "无敌计时器到点应解除无敌")
	var tong: YuNpc = _zao_yu(1.0)  # 与玩家同体型
	tong.position = yu.position
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(yu.xue_liang, 1, "同体型进伤区应掉血（≥ 判定，2→1）")
	assert_eq(1 if is_instance_valid(tong) else 0, 1, "同体型不应被吃（嘴圈是严格 > 判定）")

	# ---- 用例 4：贪食只放大嘴圈（走真实信号链：ZhangBen.xuan_ka → 信号 → match）----
	var tan_shi: QiangHuaKa = load("res://data/qianghua/tan_shi.tres")
	var zui_xing_zhuang: Node2D = yu.zui_qu.get_node("CollisionShape2D")
	var shang_xing_zhuang: Node2D = yu.shang_qu.get_node("CollisionShape2D")
	ZhangBen.xuan_ka(tan_shi)  # 真实入口：入账 + 广播 → 玩家 match 生效
	assert_eq(1 if is_equal_approx(zui_xing_zhuang.scale.x, 1.15) else 0, 1, "贪食后嘴圈形状应 ×1.15")
	assert_eq(1 if is_equal_approx(shang_xing_zhuang.scale.x, 1.0) else 0, 1, "贪食后伤区形状应纹丝不动（1.0）")

	# ---- 收卷：退出码是唯一门禁语言 ----
	print("Results: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)


func _zao_yu(tixing_zhi: float) -> YuNpc:
	# 造一条测试鱼：先定住再进树；add_child 当场跑 _ready（随机 tixing 已写入），
	# 之后写 tixing 即覆盖——判定读的是这个值，物理侦测要等下一帧才发生，来得及
	var npc: YuNpc = load("res://scenes/YuNpc.tscn").instantiate()
	npc.sudu = 0.0  # 测试鱼定住不游走（先于 add_child 设——_ready 不重置 sudu）
	npc.position = Vector2(400, 650)  # 屏内但离玩家 250px：三圈全都够不着
	add_child(npc)
	npc.tixing = tixing_zhi  # 覆盖 _ready 的随机体型——测试体型可控
	return npc


func assert_eq(shi_ji, qi_wang: int, biao_qian: String) -> void:
	# 记账员：失败只记账不爆炸——对比裸 assert() 的挂死陷阱
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %d，实际 %d）" % [biao_qian, qi_wang, shi_ji])
