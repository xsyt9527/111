extends SceneTree
# 摇杆纯逻辑测试（TASK-011 step-04）
# 运行方式：Godot --headless --path . --script tests/ce_yao_gan.gd
# 只测"方向怎么算"：限幅、归一化、死区、松手归零、多点触控不串手。
# 纪律：禁用裸 assert()；不入树的 Control 用完即 free()。

var passed := 0  # 通过计数（收卷用）
var failed := 0  # 失败计数（退出码的依据）


func _initialize() -> void:
	var yg: YaoGan = load("res://scripts/yao_gan.gd").new()
	yg.zhong_xin = Vector2(180.0, 540.0)  # 不入树，_ready 不跑，手动给中心点

	# ---- 用例 1：拖出半径 → 偏移限幅在 BAN_JING，方向仍是单位向量 ----
	yg._geng_xin_pian_yi(Vector2(680.0, 540.0))  # 向右拖 500px，远超半径 120
	assert_eq(1 if is_equal_approx(yg._pian_yi.length(), 120.0) else 0, 1, "偏移应被限幅在半径 120")
	assert_eq(1 if yg.fang_xiang.is_equal_approx(Vector2(1.0, 0.0)) else 0, 1, "向右拖应得到方向 (1,0)")

	# ---- 用例 2：斜向拖动 → 方向长度恒为 1（速度不随拖多远变）----
	yg._geng_xin_pian_yi(Vector2(480.0, 840.0))  # 右下 45°，距离超半径
	assert_eq(1 if is_equal_approx(yg.fang_xiang.length(), 1.0) else 0, 1, "归一化后方向长度应为 1")

	# ---- 用例 3：死区 → 手指微抖不算输入 ----
	yg._geng_xin_pian_yi(Vector2(185.0, 540.0))  # 只偏 5px，小于死区 15
	assert_eq(1 if yg.fang_xiang == Vector2.ZERO else 0, 1, "死区内方向应为零向量")

	# ---- 用例 4：松手 → 方向与偏移一起归零 ----
	yg._geng_xin_pian_yi(Vector2(180.0, 300.0))  # 先向上推
	yg._song_shou()
	assert_eq(1 if yg.fang_xiang == Vector2.ZERO else 0, 1, "松手后方向应归零")
	assert_eq(1 if yg._pian_yi == Vector2.ZERO else 0, 1, "松手后摇杆头应回中心")

	# ---- 用例 5：多点触控 → 别的手指松开不许打断当前操作 ----
	var an_xia := InputEventScreenTouch.new()
	an_xia.index = 0
	an_xia.pressed = true
	an_xia.position = Vector2(180.0, 400.0)  # 0 号手指向上推（距中心 140，在按下判定范围内）
	yg._unhandled_input(an_xia)
	var bie_de_song := InputEventScreenTouch.new()
	bie_de_song.index = 1
	bie_de_song.pressed = false  # 1 号手指松开：与当前操作无关
	bie_de_song.position = Vector2(600.0, 300.0)
	yg._unhandled_input(bie_de_song)
	assert_eq(1 if yg.fang_xiang.is_equal_approx(Vector2(0.0, -1.0)) else 0, 1, "别的手指松开不应打断摇杆")
	var zi_ji_song := InputEventScreenTouch.new()
	zi_ji_song.index = 0
	zi_ji_song.pressed = false  # 操作手指自己松开才算数
	zi_ji_song.position = Vector2(180.0, 300.0)
	yg._unhandled_input(zi_ji_song)
	assert_eq(1 if yg.fang_xiang == Vector2.ZERO else 0, 1, "操作手指松开后方向归零")

	yg.free()  # 不入树的实例用完即弃

	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func assert_eq(shi_ji, qi_wang: int, biao_qian: String) -> void:
	# 记账员：失败只记账不爆炸——对比裸 assert() 的挂死陷阱
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %d，实际 %d）" % [biao_qian, qi_wang, shi_ji])
