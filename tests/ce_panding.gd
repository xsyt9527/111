extends Node2D
# 判定集成测试（第 9 课 step-04：探针场景模式转正）
# 与前三个测试的区别：--script 模式不加载 Autoload，而 bei_chi 记账要 ZhangBen、
# 玩家 _ready 要连 ZhangBen 信号——所以走场景模式：起本场景 = 真引擎循环 + Autoload 全就位，
# Area2D 的 area_entered 由真物理帧触发（不是手动调函数）。
# 用例 0 九宫格区域名（纯函数）：3×3 大地图的坐标→区域映射，先于所有节点用例
# 架构：等级 = 体型上限（只升不降）；当前体型 = 血量（受伤扣、吃东西回）
# 运行：Godot --headless --path . res://tests/ce_panding_chang_jing.tscn --quit-after 480
# 纪律：禁用裸 assert()；死亡用例放最后并立即收卷（切结算页会拆掉测试场景）

var passed := 0  # 通过计数（收卷用）
var failed := 0  # 失败计数（退出码的依据）


func _ready() -> void:
	# 先抓住 SceneTree 引用：死亡用例会触发切场景，本节点被摘出树后 get_tree() 会是 null
	var shu := get_tree()
	# 关掉账本的饥饿时钟：集成测试要断言精确饥饿值，不能让被动下降掺进来
	ZhangBen.process_mode = Node.PROCESS_MODE_DISABLED
	# ---- 用例 0：九宫格区域名（纯函数，不入树）----
	var zhu: Node2D = load("res://scripts/main.gd").new()
	assert_eq_ming(zhu.qu_yu_ming(Vector2(0, 0)), "西北 · 沉船锚链悬崖", "左上角应映射西北")
	assert_eq_ming(zhu.qu_yu_ming(Vector2(4127, 2303)), "东南 · 远古祭坛地宫", "右下角应映射东南")
	assert_eq_ming(zhu.qu_yu_ming(Vector2(2064, 1152)), "正中 · 核心海山交汇大殿", "地图中心应映射正中")
	assert_eq_ming(zhu.qu_yu_ming(Vector2(1376, 768)), "正中 · 核心海山交汇大殿", "格边界应归入右下格")
	assert_eq_ming(zhu.qu_yu_ming(Vector2(-10, -10)), "西北 · 沉船锚链悬崖", "越界坐标应夹到边缘格")
	zhu.free()
	# ---- 搭台：玩家进树（先设位置再进——_ready 会拿 position 当游动目标点）----
	var yu: Yu = load("res://scenes/Yu.tscn").instantiate()
	yu.position = Vector2(400, 400)
	add_child(yu)
	await get_tree().physics_frame  # 等一帧：三个圈注册进物理世界
	assert_eq(_xiang_deng(zhang_ben_tixing(yu), 1.0), 1, "开局 Lv.0：当前体型（血量）应为基础 1.0")
	_she_deng_ji(3)  # 测试从 Lv.3 开始：血 4.0，方便做“吃小鱼 / 挨大鱼”两类用例

	# ---- 用例 0b：朝向死区（纯上下时 cos≈0，浮点符号不该把鱼头甩向左边）----
	var ti_pian: AnimatedSprite2D = yu.get_node("AnimatedSprite2D")
	yu.dang_qian_jiao = PI / 2.0  # 朝下：cos≈0，竖直游动
	yu._process(0.0)
	assert_eq(1 if not ti_pian.flip_h else 0, 1, "纯上下游动应保持原朝向（不默认翻左）")
	yu.dang_qian_jiao = PI  # 朝左：cos=-1，横向分量足够
	yu._process(0.0)
	assert_eq(1 if ti_pian.flip_h else 0, 1, "朝左时仍应翻面")
	yu.dang_qian_jiao = -PI / 2.0  # 朝上：应保留上一帧的“朝左”，不能弹回右边
	yu._process(0.0)
	assert_eq(1 if ti_pian.flip_h else 0, 1, "朝上时应保留上一帧朝向（死区不是复位）")
	yu.dang_qian_jiao = 0.0  # 复位朝右，后续用例按原朝向
	yu._process(0.0)
	assert_eq(1 if not ti_pian.flip_h else 0, 1, "朝右时应翻回右侧")

	# ---- 用例 1：小鱼进嘴圈 → 被吃 ----
	var xiao: YuNpc = _zao_yu(1)  # 比玩家（Lv.3，血 4.0）小
	xiao.position = yu.position  # 传送进玩家嘴里：三圈全重叠
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(1 if not is_instance_valid(xiao) else 0, 1, "小鱼进嘴圈应被吃（释放离场）")

	# ---- 用例 1b：吃鱼回血/回饥饿（受伤后有东西吃才补得回来）----
	ZhangBen.dang_qian_ti_xing = 3.0  # 先扣掉 1 点血
	ZhangBen.ji_e = 50.0  # 半饱下嘴，便于断言回饥饿
	var xiao2: YuNpc = _zao_yu(1)
	xiao2.position = yu.position
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 3.5), 1, "吃掉一条鱼应回半格血（3.0 → 3.5）")
	assert_eq(_xiang_deng(ZhangBen.ji_e, 60.0), 1, "吃掉路人鱼应回 10 饥饿（50 → 60）")

	# ---- 用例 2：大鱼进伤区 → 扣当前体型，不动等级 ----
	ZhangBen.dang_qian_ti_xing = 4.0  # 满血再受伤，便于断言一次扣 1 点
	var da: YuNpc = _zao_yu(5)  # 5 ≥ 4.0 × 1.1：够大才伤得到
	da.position = yu.position
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(1 if is_instance_valid(da) else 0, 1, "大鱼进嘴圈应无事（嘴圈只吃小的）")
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 3.0), 1, "受伤扣当前体型（血量）：4.0 → 3.0")
	assert_eq(ZhangBen.deng_ji, 3, "受伤不动等级上限（仍是 Lv.3）")
	assert_eq(1 if yu.wudi else 0, 1, "受伤后应进入无敌期")
	await get_tree().physics_frame
	await get_tree().physics_frame  # 大鱼还压在身上
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 3.0), 1, "无敌期内大鱼压着也不重复扣血")
	da.position = Vector2(400, 650)  # 大鱼撤走，给用例 3 腾地方
	await get_tree().physics_frame
	for r in get_tree().get_nodes_in_group("rou_kuai"):
		r.queue_free()  # 清掉受伤掉的肉：别让它在等无敌期时漂进嘴里，悄悄回血改断言
	await get_tree().process_frame

	# ---- 用例 3：同级中间带 → 不吃也不掉血（TASK-011 ×1.1 门槛）----
	await yu.wudi_dingshi.timeout  # 等无敌期真正结束（等信号，不等猜的秒数）
	assert_eq(1 if not yu.wudi else 0, 1, "无敌计时器到点应解除无敌")
	var tong: YuNpc = _zao_yu(3)  # 玩家血 3.0 与它同体型：不满足 ×1.1，既不吃也不伤
	tong.position = yu.position
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 3.0), 1, "同级中间带：不掉血")
	assert_eq(1 if is_instance_valid(tong) else 0, 1, "同级中间带：不被吃")

	# ---- 用例 4：贪食只放大嘴圈（走真实信号链：ZhangBen.xuan_ka → 信号 → match）----
	var tan_shi: QiangHuaKa = load("res://data/qianghua/tan_shi.tres")
	var zui_xing_zhuang: Node2D = yu.zui_qu.get_node("CollisionShape2D")
	var shang_xing_zhuang: Node2D = yu.shang_qu.get_node("CollisionShape2D")
	ZhangBen.xuan_ka(tan_shi)  # 真实入口：入账 + 广播 → 玩家 match 生效
	assert_eq(1 if is_equal_approx(zui_xing_zhuang.scale.x, 1.15) else 0, 1, "贪食后嘴圈形状应 ×1.15")
	assert_eq(1 if is_equal_approx(shang_xing_zhuang.scale.x, 1.0) else 0, 1, "贪食后伤区形状应纹丝不动（1.0）")

	# ---- 用例 5：门槛边界 → 比值 1.0 仍落在中间带（不吃也不伤）----
	_she_deng_ji(3)  # 回满血 4.0，便于对照 ×1.1
	var bian: YuNpc = _zao_yu(4)  # 4 < 4.0 × 1.1，也吃不下 4.0（4.0 < 4 × 1.1）
	bian.position = yu.position
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 4.0), 1, "比值 1.0 在中间带：不受伤")
	assert_eq(1 if is_instance_valid(bian) else 0, 1, "比值 1.0 在中间带：不被吃")
	bian.position = Vector2(400, 650)
	await get_tree().physics_frame

	# ---- 用例 5b：可吃的东西亮红光（本次新增的判定提示）----
	var gong: YuNpc = _zao_yu(1)  # 吃得下
	gong.position = Vector2(400, 650)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(1 if gong.get_node("HongGuang").visible else 0, 1, "吃得下的鱼应亮红光")
	var di: YuNpc = _zao_yu(5)  # 吃不下
	di.position = Vector2(400, 700)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(1 if di.get_node("HongGuang").visible else 0, 0, "吃不下的鱼不应亮红光")
	gong.queue_free()
	di.queue_free()
	await get_tree().physics_frame

	# ---- 用例 6：受伤掉肉 + 吃鱼肉回经验/回血（插课：策划案 8.1「受伤掉肉」）----
	ZhangBen.jing_yan = 0  # 从零记账，便于断言 +1
	ZhangBen.dang_qian_ti_xing = 3.0  # 留出回血空间
	ZhangBen.ji_e = 50.0  # 留出回饥饿空间
	var rou_qian := get_tree().get_nodes_in_group("rou_kuai").size()
	yu.diao_rou(2)
	await get_tree().process_frame
	assert_eq(get_tree().get_nodes_in_group("rou_kuai").size() - rou_qian, 2, "掉肉：一次应生成 2 块")
	var rou_z: RouKuai = get_tree().get_nodes_in_group("rou_kuai")[0]
	rou_z.ke_chi = true  # 跳过 0.4 秒保护期，直接测吃
	rou_z.global_position = yu.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(1 if not is_instance_valid(rou_z) else 0, 1, "玩家碰到鱼肉应吃掉")
	assert_eq(ZhangBen.jing_yan, 1, "吃一块鱼肉应 +1 经验")
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 3.25), 1, "吃一块鱼肉应回四分之一格血（3.0 → 3.25）")
	assert_eq(_xiang_deng(ZhangBen.ji_e, 55.0), 1, "吃一块鱼肉应回 5 饥饿（50 → 55）")
	for r in get_tree().get_nodes_in_group("rou_kuai"):
		r.queue_free()  # 清场：别让剩余鱼肉干扰死亡用例
	await get_tree().process_frame

	# ---- 用例 6b：吃海草/珊瑚 → 加经验与饥饿（植物也是体型来源）----
	var zhi: ZhiWu = load("res://scenes/ZhiWu.tscn").instantiate()
	zhi.get_node("Sprite2D").texture = load("res://assets/sucai/shenhai_zhuangshi/shanhu_01.png")
	zhi.jing_yan = 2  # 珊瑚收益高于海草（1）
	zhi.ji_e = 12.0  # 珊瑚回饥饿也高于海草（8）
	ZhangBen.ji_e = 50.0  # 重新压回半饱，便于断言
	zhi.position = yu.position
	add_child(zhi)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(ZhangBen.jing_yan, 3, "吃一株珊瑚应 +2 经验（此前吃鱼肉 +1）")
	assert_eq(_xiang_deng(ZhangBen.ji_e, 62.0), 1, "吃一株珊瑚应回 12 饥饿（50 → 62）")
	assert_eq(1 if not zhi.ke_chi else 0, 1, "植物被吃后应进入重生期（暂时不可再吃）")
	assert_eq(1 if zhi.get_node("Sprite2D").visible else 0, 0, "植物被吃后应隐藏等重生")

	# ---- 用例 6c：食物靠近才亮红光（离远了关灯，避免满屏红光）----
	var guang_zhi: ZhiWu = load("res://scenes/ZhiWu.tscn").instantiate()
	guang_zhi.get_node("Sprite2D").texture = load("res://assets/sucai/shenhai_zhuangshi/haicao_01.png")
	guang_zhi.position = yu.position + Vector2(100, 0)  # 100px：在 190px 提示圈内
	add_child(guang_zhi)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(1 if guang_zhi.get_node("HongGuang").visible else 0, 1, "玩家靠近可食物应亮红光")
	guang_zhi.position = yu.position + Vector2(400, 0)  # 400px：超出提示圈
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(1 if guang_zhi.get_node("HongGuang").visible else 0, 0, "玩家离远后红光应关闭")
	guang_zhi.queue_free()
	await get_tree().process_frame

	# ---- 用例 7：血量归零 → 死亡（放最后：切场景会拆掉本测试）----
	yu.wudi = false  # 清无敌，确保受伤入口真的执行
	ZhangBen.deng_ji = 1
	ZhangBen.dang_qian_ti_xing = 1.0  # Lv.1 上限 2.0，当前只有 1.0：一次受伤就归零
	yu._shoushang()  # 直接走受伤入口：比把大鱼传送进嘴更可控
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 0.0), 1, "血量归零即死亡（账本广播 si_wang）")
	assert_eq(ZhangBen.deng_ji, 1, "死亡时等级上限仍是 Lv.1（受伤从不掉级）")

	# ---- 收卷：退出码是唯一门禁语言 ----
	print("Results: %d passed, %d failed" % [passed, failed])
	shu.quit(1 if failed > 0 else 0)


func _she_deng_ji(deng_ji: int) -> void:
	# 测试专用：直接设等级并回满血（正式代码走 jia_jing_yan，不许绕后门）
	ZhangBen.deng_ji = deng_ji
	ZhangBen.dang_qian_ti_xing = ZhangBen.ti_xing_shang_xian()


func zhang_ben_tixing(yu: Yu) -> float:
	# 玩家的体型 getter 直接读账本：这里包一层，断言失败时能看清读的是谁
	return yu.tixing


func _zao_yu(tixing_zhi: int) -> YuNpc:
	# 造一条测试鱼：先定住再进树；add_child 当场跑 _ready（体型=鱼种等级），
	# 之后写 tixing 即覆盖——判定读的是这个值，物理侦测要等下一帧才发生，来得及
	var npc: YuNpc = load("res://scenes/YuNpc.tscn").instantiate()
	npc.sudu = 0.0  # 测试鱼定住不游走（先于 add_child 设——_ready 不重置 sudu）
	npc.position = Vector2(400, 650)  # 屏内但离玩家远：三圈全都够不着
	add_child(npc)
	npc.tixing = tixing_zhi  # 覆盖 _ready 的鱼种等级——测试体型可控
	return npc


func _xiang_deng(shu: float, qi_wang: float) -> int:
	# 浮点断言适配器：账本血量是 float，断言助手只认 int——相等给 1，否则 0
	return 1 if is_equal_approx(shu, qi_wang) else 0


func assert_eq(shi_ji, qi_wang: int, biao_qian: String) -> void:
	# 记账员：失败只记账不爆炸——对比裸 assert() 的挂死陷阱
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %d，实际 %d）" % [biao_qian, qi_wang, shi_ji])


func assert_eq_ming(shi_ji: String, qi_wang: String, biao_qian: String) -> void:
	# 区域名断言：字符串单独一份，避免把 String 塞进 int 断言
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %s，实际 %s）" % [biao_qian, qi_wang, shi_ji])
