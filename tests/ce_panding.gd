extends Node2D
# 判定集成测试（第 9 课 step-04：探针场景模式转正）
# 与前三个测试的区别：--script 模式不加载 Autoload，而 bei_chi 记账要 ZhangBen、
# 玩家 _ready 要连 ZhangBen 信号——所以走场景模式：起本场景 = 真引擎循环 + Autoload 全就位，
# Area2D 的 area_entered 由真物理帧触发（不是手动调函数）。
# 用例 0 九宫格区域名（纯函数）：3×3 大地图的坐标→区域映射，先于所有节点用例
# 架构：等级 = 体型上限（只升不降）；当前体型 = 血量（受伤扣、吃东西回）
# 运行：Godot --headless --path . res://tests/ce_panding_chang_jing.tscn --quit-after 960
# 纪律：禁用裸 assert()；死亡用例放最后并立即收卷（切结算页会拆掉测试场景）

var passed := 0  # 通过计数（收卷用）
var failed := 0  # 失败计数（退出码的依据）
var ji_bai_ci := 0  # 机器船 bei_ji_bai 广播计数（信号接收器只能改成员变量）
var jing_sha_ci := 0  # 鲸鲨 bei_ji_bai 广播计数


func _ready() -> void:
	# 先抓住 SceneTree 引用：死亡用例会触发切场景，本节点被摘出树后 get_tree() 会是 null
	var shu := get_tree()
	# 关掉账本的饥饿时钟：集成测试要断言精确饥饿值，不能让被动下降掺进来
	ZhangBen.process_mode = Node.PROCESS_MODE_DISABLED
	# 唯一主角（2026-11-02）：账本 _ready 自带蜗牛鱼，直接启动 Main/测试不经过选择页也不会空形态
	assert_eq_ming(String(ZhangBen.dang_qian_xing_tai.bian_hao) if ZhangBen.dang_qian_xing_tai else "",
			"ao_tu_wo_niu_yu", "账本默认装配凹凸蜗牛鱼")
	# ---- 用例 0y：音效管理器（headless 是 Dummy 音频驱动：播放调用必须安全）----
	YinXiang.fang(&"chi")
	YinXiang.fang(&"yao")
	YinXiang.fang(&"mei_you_zhe_ge_yin")  # 未知名字：只 push_warning，不能炸
	var you_bo := false
	for bo in YinXiang._chi:
		if bo.playing:
			you_bo = true
	assert_eq(1 if you_bo else 0, 1, "播放器池有播放器在响（fang 出声）")
	YinXiang.bo_bgm()
	YinXiang.bo_bgm()  # 连调两次：已在播就不重头
	assert_eq(1 if YinXiang._bgm.playing else 0, 1, "BGM 常驻播放器已启动且不重播")
	# 音效表内容：11 条全部有真资源（本测试是场景模式，Autoload 全就位，编译期引用安全）
	assert_eq(YinXiang.YIN_XIAO_BIAO.size(), 11, "音效表应有 11 条（吞/咬/伤/升级/失控/弹窗/能力/胜/败/死/按钮）")
	for yin_bian_hao in YinXiang.YIN_XIAO_BIAO:
		assert_eq(1 if YinXiang.YIN_XIAO_BIAO[yin_bian_hao] is AudioStream else 0, 1,
				"音效 %s 必须是 AudioStream" % String(yin_bian_hao))
	assert_eq(1 if YinXiang.BGM_SHEN_HAI is AudioStream else 0, 1, "BGM 资源必须可加载")
	# ---- 用例 0：九宫格区域名（纯函数，不入树）----
	var zhu: Node2D = load("res://scripts/main.gd").new()
	assert_eq_ming(zhu.qu_yu_ming(Vector2(0, 0)), "西北 · 沉船锚链悬崖", "左上角应映射西北")
	assert_eq_ming(zhu.qu_yu_ming(Vector2(4127, 2303)), "东南 · 远古祭坛地宫", "右下角应映射东南")
	assert_eq_ming(zhu.qu_yu_ming(Vector2(2064, 1152)), "正中 · 核心海山交汇大殿", "地图中心应映射正中")
	assert_eq_ming(zhu.qu_yu_ming(Vector2(1376, 768)), "正中 · 核心海山交汇大殿", "格边界应归入右下格")
	assert_eq_ming(zhu.qu_yu_ming(Vector2(-10, -10)), "西北 · 沉船锚链悬崖", "越界坐标应夹到边缘格")
	# ---- 用例 0a：镜头视野倍率（每级 +10%，Lv.10 封顶 2.0×）----
	ZhangBen.deng_ji = 0
	assert_eq(_xiang_deng(zhu._shi_jiao_bei(), 1.0), 1, "Lv.0 视野 1.0×（开局不拉远）")
	ZhangBen.deng_ji = 5
	assert_eq(_xiang_deng(zhu._shi_jiao_bei(), 1.5), 1, "Lv.5 视野 1.5×（每级 +10%）")
	ZhangBen.deng_ji = 10
	assert_eq(_xiang_deng(zhu._shi_jiao_bei(), 2.0), 1, "Lv.10 视野 2.0×")
	ZhangBen.deng_ji = 20
	assert_eq(_xiang_deng(zhu._shi_jiao_bei(), 2.0), 1, "Lv.20 仍 2.0×：等级无上限，镜头必须封顶")
	ZhangBen.deng_ji = 0
	zhu.free()
	# ---- 用例 0c：刷新节奏（持续刷新；每 20 秒上一档，体型分布右移，低等级鱼逐档退场）----
	# 放场景模式测：--script 模式不注册 Autoload，加载 YuQun 会连带编译依赖 ZhangBen 的 yu_npc.gd
	var qun: YuQun = load("res://scripts/yu_qun.gd").new()
	assert_eq(qun.shua_xin_shang_xian(0), 2, "开局（第 0 档）只能刷到 2 级鱼")
	assert_eq(qun.shua_xin_shang_xian(3), 5, "第 3 档（60 秒）刷新上限 5 级")
	assert_eq(qun.shua_xin_shang_xian(8), 10, "第 8 档（160 秒）刷新上限 10 级")
	assert_eq(qun.shua_xin_shang_xian(20), 10, "再往后封顶 10 级，不会无限刷")
	assert_eq(qun.shua_xin_shang_xian(-3), 2, "异常负档数按第 0 档处理")
	# 最低刷新等级（2026-11-02 拍板）：每 20 秒抬 1 级，封顶 4 级——小鱼逐档退场
	assert_eq(qun.shua_xin_zui_di(0), 1, "第 0 档最低 1 级：小孩鱼还在")
	assert_eq(qun.shua_xin_zui_di(1), 2, "第 1 档（20 秒）最低 2 级：1 级小孩鱼退场")
	assert_eq(qun.shua_xin_zui_di(3), 4, "第 3 档（60 秒）最低 4 级")
	assert_eq(qun.shua_xin_zui_di(9), 4, "最低等级封顶 4 级：不会一路抬到上限")
	assert_eq(qun.shua_xin_zui_di(-3), 1, "异常负档数按第 0 档处理")
	# 决战期停刷（2026-11-02 拍板）：开关一开，后续补鱼/铺屏/生成入口全部拒绝，存量不清
	assert_eq(1 if qun.shua_xin_ting_zhi else 0, 0, "开局默认在刷：停刷开关关闭")
	qun.ting_zhi_shua_xin()
	assert_eq(1 if qun.shua_xin_ting_zhi else 0, 1, "机器船降临：停刷开关打开")
	assert_eq(qun.get_child_count(), 0, "停刷不清场：原有子节点一个不动")
	assert_eq(1 if qun._shengcheng_yi_tiao() else 0, 0, "停刷后生成入口拒绝新增")
	qun._on_dingshi_timeout()  # 定时器到点也不补
	assert_eq(qun.get_child_count(), 0, "停刷后定时器不会偷偷补鱼")
	# 最低等级鱼占比：开局七成，一档后明显变少，局末有下限
	assert_eq(_jin_si(qun.lu_ren_bi_li(0), 0.7), 1, "第 0 档七成是最低等级鱼（此时是 1 级）")
	assert_eq(_jin_si(qun.lu_ren_bi_li(1), 0.56), 1, "第 1 档（20 秒）最低等级鱼占比降到 56%")
	assert_eq(1 if qun.lu_ren_bi_li(1) < qun.lu_ren_bi_li(0) else 0, 1, "超过一档后最低等级鱼变少")
	assert_eq(_jin_si(qun.lu_ren_bi_li(9), 0.2), 1, "局末最低等级鱼占比守住下限 20%（不会绝迹）")
	# 档位由账本局内时钟换算：61 秒 = 第 3 档（用户要求每 20 秒一档）
	ZhangBen.ju_nei_shi_jian = 61.0
	qun._process(0.0)
	assert_eq(qun._dang, 3, "局内 61 秒应换算成第 3 档（每 20 秒一档）")
	ZhangBen.ju_nei_shi_jian = 0.0
	qun._process(0.0)
	# 体型概率表：总和为 1；第 1 档开始出现 3 级「青少年」
	var biao_0 := qun.deng_ji_gai_lv(0)
	var biao_1 := qun.deng_ji_gai_lv(1)
	var biao_8 := qun.deng_ji_gai_lv(8)
	assert_eq(_jin_si(_biao_he(biao_0), 1.0), 1, "第 0 档体型概率表总和应为 1")
	assert_eq(_jin_si(_biao_he(biao_8), 1.0), 1, "第 8 档体型概率表总和应为 1")
	assert_eq(_jin_si(biao_0[3], 0.0), 1, "第 0 档刷不出 3 级鱼（上限只有 2）")
	assert_eq(1 if biao_1[3] > 0.0 else 0, 1, "第 1 档开始刷出 3 级「青少年」")
	assert_eq(_jin_si(biao_1[1], 0.0), 1, "第 1 档 1 级概率归零：最低刷 2 级")
	assert_eq(_jin_si(biao_8[3], 0.0), 1, "第 8 档 1~3 级彻底不刷（最低 4 级）")
	assert_eq(1 if biao_8[4] > 0.0 else 0, 1, "第 8 档只剩 4 级及以上的鱼（4 级接手「垫底」位）")
	# 期望体型（平均值）随档位单调变大 = 用户要的「刷新出来的鱼越来越大」
	var ping_0 := _biao_qi_wang(biao_0)
	var ping_1 := _biao_qi_wang(biao_1)
	var ping_8 := _biao_qi_wang(biao_8)
	assert_eq(1 if ping_1 > ping_0 else 0, 1, "第 1 档的平均体型应大于开局")
	assert_eq(1 if ping_8 > ping_1 else 0, 1, "第 8 档的平均体型应大于第 1 档")
	# 局末垫底鱼是 4 级、不再是 1 级——这条语义已由上面 biao_8[3]==0 / biao_8[4]>0 覆盖
	qun.free()
	# ---- 用例 0d：长按主动技能的范围指示（ji_neng_fan_wei：三类画法 + 半径兜底）----
	var zhi_shi = load("res://scripts/ji_neng_fan_wei.gd").new()
	add_child(zhi_shi)
	var n_xuan: NengLi = load("res://data/nengli/xuan_wo.tres")
	zhi_shi.xian_shi(n_xuan, Vector2(300, 400), Vector2.RIGHT)
	assert_eq(1 if zhi_shi.visible else 0, 1, "范围指示：调用 xian_shi 后可见")
	assert_eq(zhi_shi._lei_xing, 0, "漩涡是范围型：以玩家为圆心画整圆")
	assert_eq(_xiang_deng(zhi_shi._ban_jing, 180.0), 1, "漩涡 1 档半径 180（读当前档覆盖值）")
	assert_eq(_xiang_deng(zhi_shi.global_position.x, 300.0), 1, "范围圆跟随玩家世界坐标")
	zhi_shi.yin_cang()
	assert_eq(1 if zhi_shi.visible else 0, 0, "松手 yin_cang：指示立即隐藏")
	var n_lei: NengLi = load("res://data/nengli/yu_lei_chong_ci.tres")
	zhi_shi.xian_shi(n_lei, Vector2.ZERO, Vector2.DOWN)
	assert_eq(zhi_shi._lei_xing, 1, "鱼雷冲刺是突进型：朝向前方画扇形")
	assert_eq(_xiang_deng(zhi_shi._ban_jing, 320.0), 1, "突进型没写半径：兜底 320")
	assert_eq(_xiang_deng(zhi_shi._fang_xiang.y, 1.0), 1, "扇形朝向跟随玩家输入方向")
	var n_kuang: NengLi = load("res://data/nengli/kuang_bao_si_yao.tres")
	zhi_shi.xian_shi(n_kuang, Vector2.ZERO, Vector2.RIGHT)
	assert_eq(zhi_shi._lei_xing, 2, "狂暴撕咬是自身型：玩家周围小圆")
	assert_eq(_xiang_deng(zhi_shi._ban_jing, 70.0), 1, "自身型没写半径：兜底 70")
	zhi_shi.yin_cang()
	zhi_shi.free()
	# ---- 搭台：玩家进树（先设位置再进——_ready 会拿 position 当游动目标点）----
	var yu: Yu = load("res://scenes/Yu.tscn").instantiate()
	yu.position = Vector2(400, 400)
	yu.zi_dong_yao_ji = false  # 旧用例按“站桩靶鱼”写：先关自动咬击，咬击用例自己打开
	add_child(yu)
	await get_tree().physics_frame  # 等一帧：三个圈注册进物理世界
	assert_eq(1 if yu.get_node("AnimatedSprite2D").sprite_frames == load("res://data/donghua/ao_tu_wo_niu_yu_4zhen.tres") else 0,
			1, "玩家默认外观是凹凸蜗牛鱼 4 帧动画")
	assert_eq(_xiang_deng(zhang_ben_tixing(yu), 2.0), 1, "开局统一 Lv.1：当前体型（血量）应为 2.0")
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
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 3.0 + (1.0 / 1.5) * 1.2), 1, "吃掉一条 1 级鱼应回 0.8 格血（1÷1.5×1.2 加成，3.0 → 3.8）")
	assert_eq(_xiang_deng(ZhangBen.ji_e, 60.0), 1, "吃掉路人鱼应回 10 饥饿（50 → 60）")

	# ---- 用例 2：大鱼进伤区 → 扣当前体型，不动等级 ----
	ZhangBen.dang_qian_ti_xing = 4.0  # 满血再受伤，便于断言接触伤害
	var da: YuNpc = _zao_yu(5)  # 5 ≥ 4.0 × 1.1：够大才伤得到
	da.position = yu.position
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(1 if is_instance_valid(da) else 0, 1, "大鱼进嘴圈应无事（嘴圈只吃小的）")
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 3.2), 1, "接触伤害按攻击者体型：(0.15×5+0.05)=0.8，4.0 → 3.2")
	assert_eq(ZhangBen.deng_ji, 3, "受伤不动等级上限（仍是 Lv.3）")
	assert_eq(1 if yu.wudi else 0, 1, "受伤后应进入无敌期")
	await get_tree().physics_frame
	await get_tree().physics_frame  # 大鱼还压在身上
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 3.2), 1, "无敌期内大鱼压着也不重复扣血")
	da.position = Vector2(400, 650)  # 大鱼撤走，给用例 3 腾地方
	await get_tree().physics_frame
	for r in get_tree().get_nodes_in_group("rou_kuai"):
		r.queue_free()  # 清掉受伤掉的肉：别让它在等无敌期时漂进嘴里，悄悄回血改断言
	await get_tree().process_frame

	# ---- 用例 3：同级中间带 → 不吃也不掉血（TASK-011 ×1.1 门槛）----
	await yu.wudi_dingshi.timeout  # 等无敌期真正结束（等信号，不等猜的秒数）
	assert_eq(1 if not yu.wudi else 0, 1, "无敌计时器到点应解除无敌")
	ZhangBen.dang_qian_ti_xing = 3.0  # 压回 3.0：与下面的 3 级鱼同体型，便于对照 ×1.1
	var tong: YuNpc = _zao_yu(3)  # 玩家血 3.0 与它同体型：不满足 ×1.1，既不吃也不伤
	tong.position = yu.position
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 3.0), 1, "同级中间带：不掉血")
	assert_eq(1 if is_instance_valid(tong) else 0, 1, "同级中间带：不被吃")

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
	yu._xiao_hua.clear()  # 清掉前面吞下的鱼：消化完会悄悄加经验，干扰下面 +1 的断言
	yu.xiao_hua_jin_du = 0.0
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
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 3.0 + 0.5 / 1.5), 1, "吃一块鱼肉应按 0.5÷1.5 回血（3.0 → 3.33）")
	assert_eq(_xiang_deng(ZhangBen.ji_e, 55.0), 1, "吃一块鱼肉应回 5 饥饿（50 → 55）")
	for r in get_tree().get_nodes_in_group("rou_kuai"):
		r.queue_free()  # 清场：别让剩余鱼肉干扰死亡用例
	await get_tree().process_frame

	# ---- 用例 6b：吃海草/珊瑚 → 加经验与饥饿；植物不回体型（策划案 8.6.2）----
	var zhi: ZhiWu = load("res://scenes/ZhiWu.tscn").instantiate()
	var zhi_dong := zhi.get_node("AnimatedSprite2D") as AnimatedSprite2D
	zhi_dong.sprite_frames = load("res://data/donghua/shan_hu_4zhen.tres")
	zhi.xian_shi_bi = 0.38  # 与生成器注入的珊瑚比例一致
	zhi.jing_yan = 2  # 珊瑚收益高于海草（1）
	zhi.ji_e = 12.0  # 珊瑚回饥饿也高于海草（8）
	ZhangBen.ji_e = 50.0  # 重新压回半饱，便于断言
	zhi.position = yu.position
	add_child(zhi)
	# 4 帧摆动契约：资源挂上即播、循环、红光层跟当前帧（植物不再是一张静态图）
	assert_eq(1 if zhi_dong.sprite_frames != null and zhi_dong.sprite_frames.has_animation(&"bai") else 0,
			1, "珊瑚应挂 4 帧摆动动画 \"bai\"")
	assert_eq(zhi_dong.sprite_frames.get_frame_count(&"bai") if zhi_dong.sprite_frames != null else 0,
			4, "珊瑚摆动动画应恰好 4 帧")
	assert_eq(1 if zhi_dong.sprite_frames != null and zhi_dong.sprite_frames.get_animation_loop(&"bai") else 0,
			1, "珊瑚摆动应循环播放")
	assert_eq(1 if zhi_dong.is_playing() else 0, 1, "珊瑚进树后应自动播放摆动")
	assert_eq(1 if zhi.get_node("HongGuang").texture == zhi_dong.sprite_frames.get_frame_texture(&"bai", zhi_dong.frame) else 0,
			1, "红光层应使用当前动画帧贴图")
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(ZhangBen.jing_yan, 3, "吃一株珊瑚应 +2 经验（此前吃鱼肉 +1）")
	assert_eq(_xiang_deng(ZhangBen.ji_e, 62.0), 1, "吃一株珊瑚应回 12 饥饿（50 → 62）")
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 3.0 + 0.5 / 1.5), 1, "吃植物不回体型：体型仍是 3.33")
	assert_eq(1 if not zhi.ke_chi else 0, 1, "植物被吃后应进入重生期（暂时不可再吃）")
	assert_eq(1 if zhi_dong.visible else 0, 0, "植物被吃后应隐藏等重生")
	assert_eq(1 if zhi_dong.is_playing() else 0, 0, "植物隐身期间摆动应暂停（不空转）")

	# ---- 用例 6c：食物靠近才亮红光（离远了关灯，避免满屏红光）----
	var guang_zhi: ZhiWu = load("res://scenes/ZhiWu.tscn").instantiate()
	var guang_dong := guang_zhi.get_node("AnimatedSprite2D") as AnimatedSprite2D
	guang_dong.sprite_frames = load("res://data/donghua/hai_cao_4zhen.tres")
	guang_zhi.position = yu.position + Vector2(100, 0)  # 100px：在 190px 提示圈内
	add_child(guang_zhi)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(1 if guang_zhi.get_node("HongGuang").visible else 0, 1, "玩家靠近可食物应亮红光")
	assert_eq(1 if guang_zhi.get_node("HongGuang").texture == guang_dong.sprite_frames.get_frame_texture(&"bai", guang_dong.frame) else 0,
			1, "海草红光应跟随当前摆动帧")
	guang_zhi.position = yu.position + Vector2(400, 0)  # 400px：超出提示圈
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(1 if guang_zhi.get_node("HongGuang").visible else 0, 0, "玩家离远后红光应关闭")
	guang_zhi.queue_free()
	await get_tree().process_frame

	# ---- 用例 6d：咬击（TASK-012）——咬得动的大鱼先掉体型，不整吞 ----
	for n in get_tree().get_nodes_in_group("yu_npc"):
		n.queue_free()  # 清掉前面用例的靶鱼：它们还压在玩家身上，会干扰嘴圈/咬击区
	await get_tree().process_frame
	await get_tree().physics_frame
	_she_deng_ji(5)  # Lv.5：上限 6.0
	await get_tree().create_timer(0.3).timeout  # 等上一步吃肉的体型 Tween 收尾，别让它把 6d 的缩放拉回去
	ZhangBen.dang_qian_ti_xing = 5.0  # 留半格空间，断言“吞掉后回血”
	yu.scale = yu._ti_xing_vector()
	ZhangBen.ji_e = 50.0
	yu.zi_dong_yao_ji = true  # 本用例才打开自动咬击
	yu.wudi = true  # 免疫接触伤：本用例只测“咬”，不让同一条大鱼顺手撞我一下
	var yao_yu: YuNpc = _zao_yu(6)  # 6 > 5：吞不下，但咬击没有资格门槛，照样能咬
	yao_yu.position = yu.position + Vector2(85, 0)  # 咬击圈内、撞伤圈外
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame  # 多等一个空闲帧：process_frame 信号在 _process 之前发，自动咬击要下一帧才落地
	assert_eq(_xiang_deng(yao_yu.tixing, 5.2), 1, "咬一口应掉 0.15×5+0.05=0.8（6.0 → 5.2）")
	assert_eq(1 if is_instance_valid(yao_yu) else 0, 1, "体型没咬到可吞线：鱼还在")
	# 冷却清零手动再咬：5.2 → 4.4；4.4×1.1=4.84 < 5，这一口之后就能吞
	yu._yao_ji_leng_que = 0.0
	yu._chang_shi_yao_ji()
	for _r in 3:  # 给物理帧时间把“咬小后的圈”刷新出来，嘴圈每帧补吞
		await get_tree().physics_frame
		await get_tree().process_frame
	assert_eq(1 if not is_instance_valid(yao_yu) else 0, 1, "把大鱼咬小后再吞：鱼应被吃掉")
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 6.0), 1, "吞掉 4.4 的鱼回 4.4÷1.5 血：直接回满上限 6.0")
	assert_eq(_xiang_deng(ZhangBen.ji_e, 58.0), 1, "回饥饿按被吃时的体型分档（4.4 → 普通鱼 8）")

	# ---- 用例 6e：致命区（咬头）——体型 ≥ 目标时一口带走（策划案 8.1：同级咬头也致命）----
	await get_tree().create_timer(0.3).timeout  # 6d 吞鱼的回血 Tween 收尾
	ZhangBen.dang_qian_ti_xing = 5.0
	yu.scale = yu._ti_xing_vector()
	ZhangBen.ji_e = 50.0
	yu.wudi = true  # 同级大鱼贴得近：免疫接触伤，只测致命区这一口
	var zhi_yu: YuNpc = _zao_yu(5)  # 与玩家同体型：不再是 ×1.1，按文档 ≥ 就该必杀
	zhi_yu.position = yu.position + Vector2(0, 120)  # 从鱼头顶靠近：头/致命点比嘴更近
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame  # 让咬击区的重叠列表先刷新出来
	yu._yao_ji_leng_que = 0.0  # 6d 那一口还在冷却：测试里直接清零，不空等 0.5 秒
	yu._chang_shi_yao_ji()
	await get_tree().process_frame
	assert_eq(1 if not is_instance_valid(zhi_yu) else 0, 1, "锁到致命区且体型 ≥ 目标：一击必杀")
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 6.0), 1, "致命区击杀 5 级鱼回 5÷1.5 血：回满上限 6.0")
	assert_eq(_xiang_deng(ZhangBen.ji_e, 58.0), 1, "致命区击杀照常回饥饿（5 级鱼回 8）")

	# ---- 用例 6f：NPC 索敌与受击反应（策划案 8.5：优先级 + 打不过就跑）----
	yu.zi_dong_yao_ji = false  # 后续交给 NPC 自己动，玩家别插手
	ZhangBen.dang_qian_ti_xing = 5.0
	yu.scale = yu._ti_xing_vector()
	yu.wudi = false  # 6e 的免伤只服务于那一次断言
	var sou: YuNpc = _zao_yu(1)  # 1 级小鱼：玩家比它大得多，它也该敢动手（小挑战）
	sou.position = yu.position + Vector2(150, 0)
	await get_tree().physics_frame
	sou.ai_kai_qi = true
	sou._si_kao()
	assert_eq(1 if sou._mu_biao == yu else 0, 1, "感知范围内没有更小的鱼：NPC 应把玩家当目标")
	sou.shou_dao_yao_ji(0.1, yu)  # 玩家咬它：记仇 + 逃跑
	assert_eq(1 if sou._chou_hen == yu else 0, 1, "被咬应记住仇人（复仇优先的数据基础）")
	assert_eq(1 if sou._tao_pao_ji_shi > 0.0 else 0, 1, "被更大的鱼咬：进入逃跑状态")
	sou.queue_free()

	# ---- 用例 6g：NPC 互吃（生态闭环：鱼群自己也在吃）----
	ZhangBen.jing_yan = 0
	var shi_zhe: YuNpc = _zao_yu(5)
	shi_zhe.position = Vector2(900, 600)
	var shi_wu: YuNpc = _zao_yu(1)
	shi_wu.position = Vector2(900, 620)
	await get_tree().physics_frame
	shi_zhe.ai_kai_qi = true
	shi_zhe._si_kao()
	shi_zhe._xing_dong(0.016)
	await get_tree().process_frame
	assert_eq(1 if not is_instance_valid(shi_wu) else 0, 1, "大鱼应把身边的小鱼吃掉")
	assert_eq(ZhangBen.jing_yan, 0, "NPC 互吃不给玩家记经验（玩家没参与）")
	shi_zhe.queue_free()
	await get_tree().process_frame

	# ---- 用例 6h：NPC 不惹大太多（同类体型差 2 倍以上不追）——鲸鲨保护 ----
	var xiao_npc: YuNpc = _zao_yu(1)
	xiao_npc.position = Vector2(1200, 700)
	var da_npc: YuNpc = _zao_yu(10)
	da_npc.position = Vector2(1210, 700)
	await get_tree().physics_frame
	xiao_npc.ai_kai_qi = true
	xiao_npc.shou_dao_yao_ji(0.1, da_npc)  # 被鲸鲨咬：记仇会记，但打不过
	xiao_npc._tao_pao_ji_shi = 0.0  # 跳过逃跑期，直接看索敌会不会去送死
	xiao_npc._si_kao()
	assert_eq(1 if xiao_npc._mu_biao == null else 0, 1, "体型差超过 2 倍：NPC 不追复仇目标（不惹鲸鲨）")
	xiao_npc.queue_free()
	da_npc.queue_free()
	await get_tree().physics_frame

	# ---- 用例 6i：小鱼也敢咬玩家（取消咬击资格后的“小挑战”）----
	await get_tree().create_timer(0.3).timeout  # 等前面的缩放 Tween 收尾
	ZhangBen.deng_ji = 0
	ZhangBen.dang_qian_ti_xing = 1.0
	yu.scale = yu._ti_xing_vector()
	yu.wudi = false
	ZhangBen.ji_e = 100.0
	yu.position = Vector2(400, 400)
	var xiao_yao: YuNpc = _zao_yu(1)
	xiao_yao.position = yu.position + Vector2(40, 0)  # 咬击圈内、接触伤圈外
	await get_tree().physics_frame
	xiao_yao.ai_kai_qi = true
	xiao_yao._si_kao()
	assert_eq(1 if xiao_yao._mu_biao == yu else 0, 1, "体型远小于玩家：小鱼也把玩家当目标")
	xiao_yao._xing_dong(0.016)
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 0.8), 1, "1 级小鱼咬 1.0 血的玩家：掉 0.2")
	assert_eq(1 if yu.wudi else 0, 1, "被咬后玩家进入短暂无敌")
	xiao_yao.queue_free()
	await get_tree().process_frame

	# ---- 用例 6j：消化槽（吞下去不等于拿到手：消化完才记经验）----
	for n in get_tree().get_nodes_in_group("yu_npc"):
		n.queue_free()  # 清场：别让前面的靶鱼干扰嘴圈
	await get_tree().process_frame
	await get_tree().physics_frame
	_she_deng_ji(5)  # 回满 Lv.5（上限 6.0），下面把血压到 4.0 留出空间
	ZhangBen.dang_qian_ti_xing = 4.0
	yu.scale = yu._ti_xing_vector()
	ZhangBen.jing_yan = 0
	ZhangBen.ji_e = 100.0
	yu.wudi = true  # 只测消化：不让接触伤插进来
	yu.zi_dong_yao_ji = false
	var lan_zhong: YuZhong = load("res://data/yuzhong/lan_yu.tres")
	var can: YuNpc = _zao_yu(1, lan_zhong)
	can.position = yu.position
	yu._chi_diao(can)  # 直接调吞吃业务函数：嘴圈重叠依赖物理时序（负载下偶发漏检），消化链才是本用例要测的
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(1 if not is_instance_valid(can) else 0, 1, "消化用例：小鱼应被吞掉")
	assert_eq(ZhangBen.jing_yan, 0, "刚吞下不记经验：要等消化完")
	assert_eq(1 if yu.xiao_hua_jin_du > 0.0 else 0, 1, "消化槽应有进度")
	yu._xiao_hua[0]["sheng_yu"] = -1.0  # 快进到“这一帧一过就消化完”（无头模式 delta 极小，别指望两帧跑完 3 秒）
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(ZhangBen.jing_yan, lan_zhong.fenzhi, "消化完成才把经验记进账本（1 级鱼 +1）")
	assert_eq(1 if yu.xiao_hua_jin_du == 0.0 else 0, 1, "消化完槽应清空")

	# ---- 用例 6j2：吃 NPC 鱼体型收益 +20%（缺口 28，2026-11-03 拍板；鱼肉块不在此列）----
	ZhangBen.dang_qian_ti_xing = 1.0  # 压到 1.0：吃一口 2 级鱼（÷1.5×1.2=1.6）不会撞到 Lv.5 的 6.0 上限
	ZhangBen.ji_e = 100.0
	yu.zi_dong_yao_ji = false
	yu.wudi = true
	var chi_zhong: YuZhong = load("res://data/yuzhong/cheng_yu.tres")
	var chi_can: YuNpc = _zao_yu(2, chi_zhong)
	chi_can.position = yu.position + Vector2(400, 0)  # 远离嘴圈：只测吞吃业务，不让物理时序插一脚
	await get_tree().physics_frame
	var chi_ti := chi_can.tixing
	var qi_wang_hui := ZhangBen.chi_wu_hui_ti_xing(chi_ti) * Yu.CHI_YU_TI_XING_BEI
	assert_eq(_xiang_deng(qi_wang_hui, ZhangBen.chi_wu_hui_ti_xing(chi_ti) * 1.2), 1,
			"加成幅度 = 基础体型收益 ×1.2（+20%）")
	yu._chi_diao(chi_can)
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 1.0 + qi_wang_hui), 1,
			"吃 NPC 鱼：体型收益按 +20% 结算")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(1 if not is_instance_valid(chi_can) else 0, 1, "吞鱼收益用例：目标应被吃掉")
	yu._xiao_hua.clear()  # 清掉这一口的消化槽：别让后面的用例白捡经验

	# ---- 用例 6k：控制条（电麻/毒晕满 100 → 失控 2 秒）----
	ZhangBen.dian_ma = 0.0
	ZhangBen.du_yun = 0.0
	ZhangBen.yun_xuan_ji_shi = 0.0
	ZhangBen.jia_dian_ma(60.0)
	ZhangBen.jia_dian_ma(30.0)
	assert_eq(_xiang_deng(ZhangBen.dian_ma, 90.0), 1, "电麻条应累加（60 + 30 = 90）")
	assert_eq(1 if not ZhangBen.zai_kong_zhi() else 0, 1, "没满 100 不该失控")
	ZhangBen.jia_dian_ma(10.0)
	assert_eq(1 if ZhangBen.zai_kong_zhi() else 0, 1, "电麻条满 100 → 失控")
	assert_eq(_xiang_deng(ZhangBen.dian_ma, 0.0), 1, "触发后电麻条清零（不连环晕）")
	ZhangBen.geng_xin_kong_zhi(2.1)
	assert_eq(1 if not ZhangBen.zai_kong_zhi() else 0, 1, "满 2 秒后解除失控")
	ZhangBen.jia_du_yun(100.0)
	assert_eq(1 if ZhangBen.zai_kong_zhi() else 0, 1, "毒晕条满同样失控")
	# 失控时玩家不能游：直接喂大 delta，看位移有没有变化
	yu.fang_xiang = Vector2.RIGHT
	yu.dang_qian_su_du = 300.0
	var wei_qian := yu.position
	yu._process(0.5)
	assert_eq(_xiang_deng(yu.position.x, wei_qian.x), 1, "失控中不能游动")
	ZhangBen.yun_xuan_ji_shi = 0.0  # 放出来，后面的用例还要正常跑
	yu.fang_xiang = Vector2.ZERO
	assert_eq(1 if not ZhangBen.zai_kong_zhi() else 0, 1, "清空失控计时即可恢复")

	# ---- 用例 6l：蓑鲉毒人 / 电鳗电人 / NPC 自己也会失控 ----
	ZhangBen.du_yun = 0.0
	ZhangBen.dian_ma = 0.0
	var shi_zi: YuNpc = _zao_yu(2, load("res://data/yuzhong/cheng_yu.tres"))
	shi_zi.position = yu.position + Vector2(120, 0)
	await get_tree().physics_frame
	# 五鱼攻击帧：咬中同帧换成 gong 四帧，0.4 秒后自动切回 you
	var shi_ti: AnimatedSprite2D = shi_zi.get_node("AnimatedSprite2D")
	assert_eq(1 if shi_ti.sprite_frames.has_animation(&"you") else 0, 1, "蓑鲉默认播游动动画")
	shi_zi.set_process(false)  # 等动画期间冻住它的 AI：别让 0.5 秒自然巡游干扰后续断言
	yu.set_process(false)  # 玩家也冻住：否则这 0.5 秒里可能自动放漩涡，把靶鱼吸走
	shi_zi._bo_gong_ji()
	await get_tree().process_frame
	assert_eq(1 if shi_ti.sprite_frames.has_animation(&"gong") else 0, 1, "咬击触发：切到 gong 攻击帧")
	assert_eq(1 if shi_zi._zai_gong_ji else 0, 1, "攻击帧播放中：红光层让位")
	await get_tree().create_timer(0.5).timeout
	assert_eq(1 if shi_ti.sprite_frames.has_animation(&"you") else 0, 1, "0.4 秒后切回 you 游动帧")
	assert_eq(1 if not shi_zi._zai_gong_ji else 0, 1, "攻击帧结束：红光层恢复")
	shi_zi.set_process(true)
	yu.set_process(true)
	shi_zi.shou_dao_yao_ji(0.1, yu)  # 玩家咬它一口：蓑鲉反毒
	assert_eq(_xiang_deng(ZhangBen.du_yun, 45.0), 1, "咬蓑鲉一口：毒晕条 +45")
	shi_zi.bei_xi = null  # 清掉可能残留的漩涡吸力：本用例只测直线巡游
	var shi_zhi := shi_zi.position
	shi_zi.sudu = 50.0
	shi_zi.fangxiang = 1.0
	shi_zi.ai_kai_qi = false  # 只测直线巡游有没有被失控打断
	shi_zi.jia_du_yun(100.0)
	assert_eq(1 if shi_zi.zai_kong_zhi() else 0, 1, "NPC 毒晕条满也会失控")
	shi_zi._process(0.1)
	assert_eq(_xiang_deng(shi_zi.position.x, shi_zhi.x), 1, "失控的 NPC 不能巡游")
	shi_zi._yun_xuan_ji_shi = 0.0  # 手动解除
	shi_zi._process(0.1)
	assert_eq(1 if shi_zi.position.x > shi_zhi.x else 0, 1, "解除失控后恢复巡游")
	shi_zi.queue_free()
	# 电鳗放电半径 90：玩家先缩到 1.0（嘴圈够不着），站在 70 像素处挨电
	ZhangBen.dang_qian_ti_xing = 1.0
	yu.scale = yu._ti_xing_vector()
	var dian_yao: YuNpc = _zao_yu(3, load("res://data/yuzhong/lv_yu.tres"))
	dian_yao.position = yu.position + Vector2(70, 0)
	dian_yao._dian_ji_ji_shi = 999.0  # 关掉自然放电：本用例只手动放一次，便于断言数值
	await get_tree().physics_frame
	ZhangBen.dian_ma = 0.0
	dian_yao._dian_ji_ji_shi = 0.0
	dian_yao._fang_dian(0.0)
	assert_eq(_xiang_deng(ZhangBen.dian_ma, 55.0), 1, "电鳗放电：玩家电麻条 +55")
	dian_yao.queue_free()
	ZhangBen.dian_ma = 0.0
	ZhangBen.du_yun = 0.0
	ZhangBen.yun_xuan_ji_shi = 0.0
	await get_tree().process_frame

	# ---- 用例 6m：机器船（TASK-017）——玩家用同一套自动咬击打 Boss ----
	for n in get_tree().get_nodes_in_group("yu_npc"):
		n.queue_free()  # 清场：只留玩家和船，免得咬击锁到别的鱼
	await get_tree().process_frame
	await get_tree().physics_frame
	_she_deng_ji(8)
	ZhangBen.dang_qian_ti_xing = 9.0
	yu.scale = yu._ti_xing_vector()
	yu.fang_xiang = Vector2.ZERO
	yu.position = Vector2(2064, 1152)
	yu.zi_dong_yao_ji = false  # 手动调 _chang_shi_yao_ji：每口之间不必空等 0.5 秒冷却
	yu.wudi = true  # 只测咬船：不让别的伤害插进来
	var chuan: JiQiChuan = load("res://scenes/JiQiChuan.tscn").instantiate()
	chuan.wan_jia = yu
	chuan.position = yu.position + Vector2(0, -240)  # 船吊在玩家上方
	add_child(chuan)
	await get_tree().physics_frame
	chuan.set_process(false)  # 定住船：本用例只测咬击与两招，不让跟随每帧改坐标
	chuan._gong_ji_dingshi.stop()  # 关掉自动出招：招式由用例逐个手动放
	assert_eq(_xiang_deng(chuan.xue, 360.0), 1, "机器船满血 360（2026-11-02 再拍板：180→360）")
	assert_eq(_xiang_deng(JiQiChuan.GONG_JI_JIAN_GE, 1.0), 1, "机器船攻击间隔 9.0→1.0：1 秒一击")
	assert_eq(_xiang_deng(JiQiChuan.ZHA_DAN_BAN_JING, 240.0), 1, "深水炸弹半径 240（120 × 2）")
	assert_eq(_xiang_deng(JiQiChuan.MAO_WAI_BAN_JING, 480.0), 1, "船锚外径 480（240 × 2）")
	assert_eq(_xiang_deng(JiQiChuan.TAN_ZHAO_CHANG, 1120.0), 1, "探照灯长度 1120（560 × 2）")
	assert_eq(_xiang_deng(JiQiChuan.YU_CHA_SHE_CHENG, 1300.0), 1, "鱼叉射程 1300（650 × 2）")
	assert_eq(JiQiChuan.ZHAO_QUAN_BU.size(), 4, "机器船四招齐备：探照灯/船锚/深水炸弹/鱼叉")
	assert_eq(1 if JiQiChuan.ZHAO_QUAN_BU.has(JiQiChuan.ZHAO_TAN_ZHAO) \
			and JiQiChuan.ZHAO_QUAN_BU.has(JiQiChuan.ZHAO_CHUAN_MAO) \
			and JiQiChuan.ZHAO_QUAN_BU.has(JiQiChuan.ZHAO_ZHA_DAN) \
			and JiQiChuan.ZHAO_QUAN_BU.has(JiQiChuan.ZHAO_YU_CHA) else 0, 1,
			"四招就是素材包里的四招，不再有渔网/机械臂")
	assert_eq(_xiang_deng(chuan._chuan_ti.scale.x, 3.0), 1, "整船视觉 ×3")
	var she_ding: CollisionShape2D = chuan.get_node("SheDingQu/CollisionShape2D")
	var chuan_qu: CollisionShape2D = chuan.get_node("ChuanTiQu/CollisionShape2D")
	assert_eq(_xiang_deng(she_ding.shape.radius, 180.0), 1, "弱点判定半径 ×3（60 → 180）")
	assert_eq(_xiang_deng(chuan_qu.shape.radius, 450.0), 1, "船体判定半径 ×3（150 → 450）")
	assert_eq(1 if chuan._zhao_ti.sprite_frames.has_animation(&"chuan_mao") \
			and chuan._zhao_ti.sprite_frames.has_animation(&"tan_zhao") \
			and chuan._zhao_ti.sprite_frames.has_animation(&"shen_zha_dan") \
			and chuan._zhao_ti.sprite_frames.has_animation(&"yu_cha") else 0, 1,
			"整船招式动画已接入四条，与四招一一对应")
	assert_eq(1 if yu._yao_ji_mu_biao() == chuan else 0, 1, "鸭子类型：船没有继承鱼，但玩家咬击照样能锁定它")
	# 从下方咬：离船体底部最近 → 普通伤害 ×1（1.4）
	await get_tree().physics_frame
	yu._yao_ji_leng_que = 0.0
	yu._chang_shi_yao_ji()
	assert_eq(_xiang_deng(chuan.xue, 360.0 - 1.4), 1, "咬船体：0.15×9+0.05=1.4（360 → 358.6），不乘倍率")
	# 绕到正面咬玻璃舱：弱点 ×3（4.2）
	yu.position = chuan.position + Vector2(0, -10)
	await get_tree().physics_frame
	await get_tree().physics_frame
	yu._yao_ji_leng_que = 0.0
	yu._chang_shi_yao_ji()
	assert_eq(_xiang_deng(chuan.xue, 358.6 - 4.2), 1, "咬玻璃舱（弱点）：1.4×3=4.2（358.6 → 354.4）")
	assert_eq(_xiang_deng(chuan.tixing, 99.0), 1, "机器船体型 99：玩家永远吞不掉，只能咬沉")
	# 失控保护：1 秒节拍 + 控制会接成「控住→下一招必中」，失控期间整拍必须跳过
	ZhangBen.yun_xuan_ji_shi = 1.5
	chuan._zui_jin.clear()
	var lun_zhi_qian := chuan._gong_ji_lun
	chuan._on_gong_ji_timeout()
	assert_eq(chuan._gong_ji_lun, lun_zhi_qian, "失控保护：玩家失控时本拍跳过，不推进轮次")
	assert_eq(1 if chuan._zui_jin.is_empty() else 0, 1, "失控保护不会偷偷出招")
	ZhangBen.yun_xuan_ji_shi = 0.0  # 放开，别影响后面的用例
	chuan._gong_ji_dingshi.stop()  # 失控保护测试启动过定时器：停掉，避免 1 秒后自动出招干扰后续步骤
	# 深水炸弹：预警后落在目标位置，范围内玩家吃 1.0 伤害
	ZhangBen.dang_qian_ti_xing = 9.0
	yu.wudi = false
	yu._ni_liu_sheng_yu = 0.0
	yu._ying_ke_sheng_yu = 0.0
	chuan._kai_shi_shen_zha_dan()
	chuan._jie_suan_zha_dan()
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 8.0), 1, "深水炸弹命中：掉 1.0 当前体型（9.0 → 8.0）")
	# 船锚横扫：300 像素处在内径 100 / 外径 480 之间 → 吃 0.7 并被击退
	ZhangBen.dang_qian_ti_xing = 9.0
	yu.wudi = false
	yu._ni_liu_sheng_yu = 0.0
	yu.position = chuan.position + Vector2(300, 0)
	chuan._kai_shi_chuan_mao()
	chuan._jie_suan_chuan_mao()
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 8.3), 1, "船锚命中：掉 0.7 当前体型（9.0 → 8.3）")
	assert_eq(_xiang_deng(yu._tui_kai_sheng_yu, 0.25), 1, "船锚击退：持续 0.25 秒")
	assert_eq(_xiang_deng(yu._tui_kai_su_du, 1760.0), 1, "船锚击退：440 像素 ÷ 0.25 秒 = 1760 像素/秒")
	assert_eq(1 if chuan._mao_ming_zhong else 0, 1, "船锚命中标记：下一拍不出炸弹")
	# 探照灯：无伤害，只减速到 55%
	yu.position = chuan.position + Vector2(300, 0)
	chuan._kai_shi_tan_zhao()
	chuan._geng_xin_tan_zhao(0.1)
	assert_eq(_xiang_deng(yu._wai_bu_jian_su_bei, 0.55), 1, "探照灯照到：移速 ×0.55")
	assert_eq(_xiang_deng(yu._wai_bu_jian_su_sheng_yu, 0.4), 1, "探照灯减速残留 0.4 秒")
	# 鱼叉：单发命中 0.6，并标记“下一拍不出船锚”
	ZhangBen.dang_qian_ti_xing = 9.0
	yu.wudi = false
	yu._ni_liu_sheng_yu = 0.0
	yu._ying_ke_sheng_yu = 0.0
	yu.position = chuan.position + Vector2(400, 0)
	chuan._yu_chas.append({"pos": yu.global_position - Vector2(10, 0), "fang": Vector2.RIGHT, "fei": 0.0})
	chuan._geng_xin_yu_chas(0.01)
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 8.4), 1, "鱼叉命中：掉 0.6 当前体型（9.0 → 8.4）")
	assert_eq(1 if chuan._cha_ming_zhong else 0, 1, "鱼叉命中标记：下一拍不出船锚")
	# 开局优先打鲸鲨：有鲸鲨且窗口未清零 → 目标切到鲸鲨，且只出炸弹/鱼叉
	var sha: YuNpc = load("res://scenes/YuNpc.tscn").instantiate()
	sha.yu_zhong = load("res://data/yuzhong/fen_yu.tres")
	sha.ai_kai_qi = false  # 手动测目标选择：不让首领 AI 游走干扰坐标
	sha.position = Vector2(2064, 900)
	add_child(sha)
	chuan.jing_sha = sha
	chuan._xian_da_jing_sha = 9.0
	chuan._leng_que.clear()
	chuan._zui_jin.clear()
	assert_eq(1 if chuan._mu_biao() == sha else 0, 1, "开局窗口内：机器船目标锁定鲸鲨")
	var jing_zhao_ok := true
	for i in range(30):
		var z := chuan._ke_xuan_zhao()
		if z != JiQiChuan.ZHAO_ZHA_DAN and z != JiQiChuan.ZHAO_YU_CHA:
			jing_zhao_ok = false
	assert_eq(1 if jing_zhao_ok else 0, 1, "打鲸鲨阶段只出深水炸弹/鱼叉")
	# 玩家咬船一口 → 立即转仇：窗口清零、目标回到玩家
	chuan.shou_dao_yao_ji(0.1, yu, "shen")
	assert_eq(_xiang_deng(chuan._xian_da_jing_sha, 0.0), 1, "玩家咬船：鲸鲨优先窗口立即清零")
	assert_eq(1 if chuan._mu_biao() == yu else 0, 1, "转仇后目标回到玩家")
	chuan._gang_shou_ji = false  # 这一口可能触发连续受击保护，先清掉：下面单独测
	chuan._shou_ji_lian_xu = 0
	# 无阶段限制：满血 + 非鲸鲨窗口，四招都可能被抽到（2026-11-05 取消阶段解锁）
	chuan.xue = chuan.zui_da_xue
	chuan._zui_jin.clear()
	chuan._leng_que.clear()
	chuan._mao_ming_zhong = false
	chuan._cha_ming_zhong = false
	var man_xue_chu := {}
	for i in range(400):
		var z := chuan._ke_xuan_zhao()
		if z != &"":
			man_xue_chu[z] = true
	assert_eq(man_xue_chu.size(), 4, "满血开局四招都可能出现（实测 %d 种）" % man_xue_chu.size())
	# 硬规则：不连续 3 拍伤害——最近两拍都是伤害 → 第三拍只能控制/跳过
	chuan._zui_jin.assign([JiQiChuan.ZHAO_ZHA_DAN, JiQiChuan.ZHAO_YU_CHA])
	chuan._leng_que.clear()
	var z3 := chuan._ke_xuan_zhao()
	assert_eq(1 if z3 == &"" or not JiQiChuan.SHANG_HAI_ZHAO.has(z3) else 0, 1,
			"连续两拍伤害后：第三拍只能出控制招或跳过")
	# 硬规则：连续受击保护——下一拍只从控制招里出（唯一控制招是探照灯）
	chuan.xue = chuan.zui_da_xue
	chuan._zui_jin.clear()
	chuan._leng_que.clear()
	chuan._gang_shou_ji = true
	assert_eq(1 if chuan._ke_xuan_zhao() == JiQiChuan.ZHAO_TAN_ZHAO else 0, 1,
			"连续受击：下一拍只出控制招（探照灯）")
	chuan._gang_shou_ji = false
	# 回归：硬规则互相锁死 → 船彻底停手（2026-11-06 实机反馈「打 2 下就不动了」）
	# A. 受击保护只许探照灯，但探照灯刚出过且还在冷却 → 必须放宽，不能返回空
	chuan._zui_jin.assign([JiQiChuan.ZHAO_TAN_ZHAO])
	chuan._leng_que[JiQiChuan.ZHAO_TAN_ZHAO] = 3.0
	chuan._gang_shou_ji = true
	assert_eq(1 if chuan._ke_xuan_zhao() != &"" else 0, 1,
			"锁死回归 A：受击保护撞上探照灯冷却时仍然出招，不停手")
	chuan._leng_que.clear()
	chuan._gang_shou_ji = false
	# B. 鲸鲨窗口只有两招伤害，打满 2 拍后被“不连续 3 拍伤害”卡死 → 提前结束窗口回玩家
	chuan._xian_da_jing_sha = 9.0
	chuan._zui_jin.assign([JiQiChuan.ZHAO_ZHA_DAN, JiQiChuan.ZHAO_YU_CHA])
	chuan._leng_que.clear()
	assert_eq(1 if chuan._ke_xuan_zhao() != &"" else 0, 1,
			"锁死回归 B：鲸鲨窗口打满 2 拍后也不会停手")
	assert_eq(1 if chuan._xian_da_jing_sha == 0.0 else 0, 1,
			"打不出鲸鲨的招时提前结束优先窗口，目标回到玩家")
	# C. 连续 60 拍都触发受击保护：每拍都必须有招可出（冷却不参与，只看规则互锁）
	chuan._zui_jin.clear()
	chuan._leng_que.clear()
	var kong_pai := 0
	for i in range(60):
		chuan._gang_shou_ji = true
		var zp := chuan._ke_xuan_zhao()
		if zp == &"":
			kong_pai += 1
		else:
			chuan._ji_lu_chu_zhao(zp)
			chuan._leng_que[zp] = 0.0  # 只测规则互锁：把刚出的招的冷却归零
	assert_eq(kong_pai, 0, "连续受击 60 拍：每拍都有招可出（实测空拍 %d）" % kong_pai)
	sha.queue_free()
	await get_tree().process_frame
	chuan.jing_sha = null
	yu.position = chuan.position + Vector2(0, -10)
	await get_tree().physics_frame
	# 打沉：血量归零 → bei_ji_bai，船关闭碰撞不再被锁定
	ji_bai_ci = 0
	chuan.bei_ji_bai.connect(_shu_ji_bai)
	chuan.xue = 1.0
	yu._yao_ji_leng_que = 0.0
	yu._chang_shi_yao_ji()  # 弱点 ×3 > 1.0：一口打沉
	assert_eq(1 if chuan.si_le else 0, 1, "船血量归零：标记死亡")
	assert_eq(ji_bai_ci, 1, "船被打沉应广播 bei_ji_bai 一次")
	assert_eq(1 if yu._yao_ji_mu_biao() == null else 0, 1, "沉船不再是可咬目标")
	chuan.queue_free()
	await get_tree().process_frame

	# ---- 用例 6n：祭坛首领鲸鲨——打残 = 击败；四处巡逻 + 8 秒追击 + 随时间升级 ----
	for n in get_tree().get_nodes_in_group("yu_npc"):
		n.queue_free()
	await get_tree().process_frame
	await get_tree().physics_frame
	jing_sha_ci = 0
	var jing_sha: YuNpc = load("res://scenes/YuNpc.tscn").instantiate()
	jing_sha.yu_zhong = load("res://data/yuzhong/fen_yu.tres")
	jing_sha.position = Vector2(3440, 1920)
	jing_sha.ai_kai_qi = false  # 手动调首领方法：不让自动 AI 干扰
	add_child(jing_sha)
	jing_sha.bei_ji_bai.connect(_shu_jing_sha_bai)
	assert_eq(1 if jing_sha.shi_boss else 0, 1, "鱼种表 shi_boss = true：鲸鲨是首领")
	# 4 帧美术：NPC 本体与红光层都用鱼种表里的 SpriteFrames，不再是一张静态图
	var boss_ti: AnimatedSprite2D = jing_sha.get_node("AnimatedSprite2D")
	assert_eq(1 if boss_ti.sprite_frames != null and boss_ti.sprite_frames.has_animation(&"you") else 0, 1,
			"首领本体播放 \"you\" 4 帧游动动画")
	assert_eq(boss_ti.sprite_frames.get_frame_count(&"you"), 4, "首领动画应为 4 帧")
	assert_eq(1 if boss_ti.is_playing() else 0, 1, "首领进树后动画已在播放")
	assert_eq(1 if jing_sha.get_node("HongGuang") is AnimatedSprite2D else 0, 1, "红光层同步为 AnimatedSprite2D")
	# 推挤层：只有首领开 monitoring，重叠的 NPC 会被顶开
	assert_eq(1 if jing_sha.get_node("BossPengZhuangQu").monitoring else 0, 1,
			"首领开启 BossPengZhuangQu：可以碰到并推开 NPC")
	jing_sha.position = Vector2(400, 400)  # 先挪进视口：测试场景没相机，出屏的普通鱼会被回收
	var peng_yu: YuNpc = _zao_yu(1)
	peng_yu.position = Vector2(440, 400)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(1 if jing_sha.get_node("BossPengZhuangQu").get_overlapping_areas().size() > 0 else 0, 1,
			"首领推挤层能感知到叠在身上的 NPC")
	var peng_qian_x := peng_yu.position.x
	jing_sha._tui_kai_zhou_wei(0.1)
	assert_eq(1 if peng_yu.position.x > peng_qian_x else 0, 1, "重叠 NPC 被首领沿远离方向顶开")
	peng_yu.queue_free()
	await get_tree().process_frame
	jing_sha.position = Vector2(3440, 1920)  # 挪回祭坛：后面巡逻/追击用例按这个坐标设计
	assert_eq(_xiang_deng(jing_sha.tixing, 10.0), 1, "首领开局体型 10（鱼种表）")
	assert_eq(_xiang_deng(jing_sha.fan_ying_shi_jian, 1.5), 1, "首领也读反应时间表（鲸鲨 1.5 秒）")
	# 咬击判定区：首领走玩家同款曲线，开局与视觉等大——不再是 195px 大圈
	var kai_ju_yao_ju := jing_sha._yao_ji_ju_li()
	assert_eq(_xiang_deng(kai_ju_yao_ju, 55.0 * ZhangBen.ti_xing_dao_chi_du(10.0)), 1,
			"首领咬击判定走玩家曲线（55×体型像素）")
	assert_eq(1 if kai_ju_yao_ju < 55.0 + 14.0 * 10.0 else 0, 1,
			"开局判定区小于旧线性公式（195px）：路过祭坛不再被隔空咬死")
	jing_sha.bei_chi(true, yu)
	assert_eq(1 if is_instance_valid(jing_sha) else 0, 1, "首领不可整吞：bei_chi 直接拒绝")
	# 巡逻：到点 → 停 2 秒 → 换下一个点；没到点就朝它游
	jing_sha.xun_luo_dian.assign([Vector2(3440, 1920), Vector2(3640, 1920)])
	jing_sha._boos_xun_luo(0.1)
	assert_eq(jing_sha._xun_luo_suo_yin, 1, "到巡逻点：下标切到下一个点")
	assert_eq(1 if jing_sha._xun_luo_ting_liu > 0.0 else 0, 1, "到点后停留几秒再走")
	jing_sha._boos_xun_luo(2.1)  # 停留结束
	jing_sha._boos_xun_luo(1.0)
	assert_eq(1 if jing_sha.position.x > 3440.0 else 0, 1, "停留结束后朝下一个巡逻点游")
	# 看见玩家：追 8 秒；玩家在正上方时不能左右疯狂摆头
	jing_sha.gan_zhi = 800.0
	jing_sha.position = Vector2(3440, 1920)
	yu.position = Vector2(3440, 1420)  # 正上方 500 像素：x 完全相同
	jing_sha.get_node("AnimatedSprite2D").flip_h = false
	jing_sha._boos_xing_dong(0.1)
	assert_eq(1 if jing_sha._boos_zhu_ji_ji_shi > 7.0 else 0, 1, "看见玩家：进入 8 秒追击窗口")
	assert_eq(1 if jing_sha.zhuang_tai == YuNpc.ZhuangTai.ZHUI_ZHU else 0, 1, "追击时状态切到 ZHUI_ZHU")
	assert_eq(1 if jing_sha.position.y < 1920.0 else 0, 1, "追击：朝玩家方向移动")
	assert_eq(1 if not jing_sha.get_node("AnimatedSprite2D").flip_h else 0, 1, "玩家在正上方时保持朝向（不每帧翻面摆头）")
	jing_sha._boos_xing_dong(8.1)  # 8 秒窗口跑完
	assert_eq(_xiang_deng(jing_sha._boos_zhu_ji_ji_shi, 0.0), 1, "8 秒后追击结束")
	assert_eq(1 if jing_sha._boos_leng_que_ji_shi > 0.0 else 0, 1, "追击结束后进入冷却（给玩家脱战窗口）")
	jing_sha._boos_xing_dong(0.1)
	assert_eq(_xiang_deng(jing_sha._boos_zhu_ji_ji_shi, 0.0), 1, "冷却期间玩家还在附近也不重新上头")
	# 升级：每 30 秒长 2 级（体型=血量，升级会回血）
	jing_sha.position = Vector2(3440, 1920)
	jing_sha.shou_dao_yao_ji(7.5, yu)  # 10 → 2.5
	assert_eq(1 if jing_sha._tao_pao_ji_shi == 0.0 else 0, 1, "首领被咬不逃跑（站着挨打才打得动）")
	assert_eq(jing_sha_ci, 0, "体型 2.5 还没到击败线（>2）")
	var sheng_qian_yao_ju := jing_sha._yao_ji_ju_li()  # 体型 2.5 时的判定区：升级后要比它大
	jing_sha.zou_boos_sheng_ji(60.0)  # 两个 30 秒档：每档 +2 级 → +4，2.5 → 6.5
	assert_eq(_xiang_deng(jing_sha.tixing, 6.5), 1, "首领每 30 秒升 2 级（60 秒共 +4：2.5 → 6.5）")
	assert_eq(1 if jing_sha._yao_ji_ju_li() > sheng_qian_yao_ju else 0, 1,
			"升级后咬击判定区跟着变大（每 30 秒那一档）")
	jing_sha.shou_dao_yao_ji(4.6, yu)  # 6.5 → 1.9
	assert_eq(1 if jing_sha.si_le else 0, 1, "咬到体型 ≤2：首领被击败")
	assert_eq(jing_sha_ci, 1, "首领败退应广播 bei_ji_bai 一次")
	await get_tree().process_frame

	# ---- 用例 6o：反应时间表（偷袭身体要懵一会儿；正面咬嘴立刻反应）----
	var chi_yu: YuNpc = load("res://scenes/YuNpc.tscn").instantiate()
	chi_yu.yu_zhong = load("res://data/yuzhong/hong_yu.tres")  # 红鱼：反应 0.5 秒
	chi_yu.position = Vector2(700, 700)
	chi_yu.ai_kai_qi = true
	add_child(chi_yu)
	assert_eq(1 if chi_yu.get_node("BossPengZhuangQu").monitoring else 0, 0,
			"普通鱼不开推挤层：BossPengZhuangQu 只属于首领")
	assert_eq(_xiang_deng(chi_yu.fan_ying_shi_jian, 0.5), 1, "反应时间从鱼种表读：红鱼 0.5 秒")
	chi_yu.shou_dao_yao_ji(0.1, yu, "shen")
	assert_eq(1 if chi_yu._chou_hen == null else 0, 1, "偷袭身体：反应时间内先不记仇")
	chi_yu._zou_fan_ying(0.4)
	assert_eq(1 if chi_yu._chou_hen == null else 0, 1, "0.4 秒还没反应过来（红鱼要 0.5 秒）")
	chi_yu._zou_fan_ying(0.2)
	assert_eq(1 if chi_yu._chou_hen == yu else 0, 1, "反应时间到：记仇（随后按体型决定逃/反击）")
	assert_eq(1 if chi_yu._tao_pao_ji_shi > 0.0 else 0, 1, "咬它的玩家比它大：反应过来后逃跑 2 秒")
	# 正面咬嘴：当面咬，不吃反应时间
	chi_yu._chou_hen = null
	chi_yu._fan_ying_ji_shi = 0.0
	chi_yu._tao_pao_ji_shi = 0.0
	chi_yu.shou_dao_yao_ji(0.1, yu, "zui")
	assert_eq(1 if chi_yu._chou_hen == yu else 0, 1, "正面咬嘴：立即记仇（没有偷袭窗口）")
	chi_yu.queue_free()
	await get_tree().process_frame

	# ---- 用例 6p：玩家主动——放电麻痹（半径 90，一次满条 → 失控 2 秒）----
	for n in get_tree().get_nodes_in_group("yu_npc"):
		n.queue_free()
	await get_tree().process_frame
	await get_tree().physics_frame
	ZhangBen.chong_zhi()
	_she_deng_ji(5)
	ZhangBen.dang_qian_ti_xing = 5.0
	yu.scale = yu._ti_xing_vector()
	yu.position = Vector2(400, 400)
	yu.fang_xiang = Vector2.ZERO
	yu.wudi = true  # 只测技能：不让周围靶鱼的接触伤插进来
	yu.zi_dong_yao_ji = false
	yu.set_process(false)  # 手动调技能方法：避免自动 _process 抢跑冷却/位移
	yu._qu_xiao_shi_fang()
	yu.zhu_dong_leng_que.clear()
	yu.zui_qu.monitoring = false  # 关嘴圈监测：80px 靶鱼恰在嘴圈边缘，物理时序一晃就被误吞（本用例只放电不吃鱼）
	var jin_dian: YuNpc = _zao_yu(1)
	jin_dian.position = yu.position + Vector2(80, 0)  # 在放电半径 90 内，但别贴进嘴圈（玩家一张嘴就吞了）
	jin_dian.sudu = 0.0  # 钉死靶鱼：系统忙时 physics 帧的 delta 会变大，AI 巡游两帧就可能漂出 90 半径
	var yuan_dian: YuNpc = _zao_yu(2)
	yuan_dian.position = yu.position + Vector2(500, 0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var fang_dian: NengLi = _zhuang_bei(&"fang_dian_ma_bi")
	assert_eq(1 if fang_dian != null else 0, 1, "放电能力资源应可加载")
	assert_eq(1 if ZhangBen.zhao_zhu_dong(&"fang_dian_ma_bi") == fang_dian else 0, 1,
			"放电装入主动组")
	assert_eq(1 if yu.shi_fang_zhu_dong(fang_dian) else 0, 1, "放电释放成功")
	# 技能替身虚影（缺口 20）：放出来才浮现，来源鱼贴图对得上，且纯表现不建判定
	var xu_ying := yu.get_parent().get_node_or_null("XuYing") as Node2D
	assert_eq(1 if xu_ying != null else 0, 1, "主动技释放：身后浮现替身虚影")
	var xu_ying_tu := xu_ying.get_node_or_null("Ying") as Sprite2D if xu_ying != null else null
	var dian_yao_zhong: YuZhong = load("res://data/yuzhong/lv_yu.tres")
	assert_eq(1 if xu_ying_tu != null and xu_ying_tu.texture == dian_yao_zhong.tie_tu else 0, 1,
			"放电麻痹的虚影 = 来源鱼电鳗的贴图")
	assert_eq(1 if xu_ying != null and xu_ying.get_child_count() == 1
			and xu_ying.get_node("Ying").get_child_count() == 0 else 0, 1,
			"虚影纯表现：只有一个贴图子节点，没有碰撞/判定")
	var xuan_wo_z: NengLi = load("res://data/nengli/xuan_wo.tres")
	assert_eq(1 if yu._xu_ying_tie_tu(xuan_wo_z) != null else 0, 1,
			"通用池主动没有来源鱼：虚影回退玩家形态贴图（每个主动都有演出）")
	assert_eq(1 if jin_dian.zai_kong_zhi() else 0, 1, "半径 90 内的鱼：电麻条满 → 失控")
	assert_eq(_xiang_deng(jin_dian._yun_xuan_ji_shi, 2.0), 1, "放电一次控制 2 秒")
	assert_eq(1 if yuan_dian.zai_kong_zhi() else 0, 0, "半径 90 外的鱼不受影响")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"fang_dian_ma_bi"), 6.0), 1, "放电冷却 6 秒")
	assert_eq(1 if yu.shi_fang_zhu_dong(fang_dian) else 0, 0, "冷却中再按无效")
	yu._geng_xin_zhu_dong(6.1)
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"fang_dian_ma_bi"), 0.0), 1, "冷却走完归 0")
	jin_dian.queue_free()
	yuan_dian.queue_free()
	yu.zui_qu.monitoring = true  # 还原：后面的用例可能还要测吞吃
	await get_tree().process_frame

	# ---- 用例 6q：毒棘护体（被动叠层：45 + 15×层；咬/撞两条入口都反毒）----
	for n in get_tree().get_nodes_in_group("yu_npc"):
		n.queue_free()
	await get_tree().process_frame
	ZhangBen.chong_zhi()
	_she_deng_ji(5)
	ZhangBen.dang_qian_ti_xing = 5.0
	yu.scale = yu._ti_xing_vector()
	yu.wudi = false
	yu.set_process(false)
	yu._qu_xiao_shi_fang()
	var du_ji: NengLi = _zhuang_bei(&"du_ji_hu_ti")
	assert_eq(1 if du_ji != null else 0, 1, "毒棘能力资源应可加载")
	var yao_zhe: YuNpc = _zao_yu(1)
	yao_zhe.position = yu.position + Vector2(120, 0)
	await get_tree().physics_frame
	var xue_qian := ZhangBen.dang_qian_ti_xing
	yu.shou_dao_yao_ji(0.2, yao_zhe, "shen")
	assert_eq(_xiang_deng(yao_zhe.du_yun, 45.0), 1, "毒棘 1 层：咬玩家的人 +45 毒晕")
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, xue_qian - 0.2), 1, "毒棘不替玩家挡伤害")
	_zhuang_bei(&"du_ji_hu_ti")
	yao_zhe.du_yun = 0.0
	yu.wudi = false
	yu.shou_dao_yao_ji(0.2, yao_zhe, "shen")
	assert_eq(_xiang_deng(yao_zhe.du_yun, 60.0), 1, "毒棘 2 层：45+15=60")
	# NPC 真实咬人入口 _yao 必须传来源，否则毒棘不生效
	yao_zhe.du_yun = 0.0
	yao_zhe._yao_ji_leng_que = 0.0
	yu.wudi = false
	ZhangBen.dang_qian_ti_xing = 5.0
	yao_zhe._yao(yu)
	assert_eq(_xiang_deng(yao_zhe.du_yun, 60.0), 1, "NPC 咬人走 _yao：毒棘反毒照样生效")
	# 接触伤害入口：大鱼撞上来也反毒
	yao_zhe.du_yun = 0.0
	yao_zhe.tixing = 10.0
	yao_zhe._ying_she_ti_xing()
	yu.wudi = false
	ZhangBen.dang_qian_ti_xing = 5.0
	yu._on_shang_qu_entered(yao_zhe.get_node("PandingQu"))
	assert_eq(_xiang_deng(yao_zhe.du_yun, 60.0), 1, "大鱼撞玩家：接触伤害也触发毒棘")
	yao_zhe.queue_free()
	await get_tree().process_frame

	# ---- 用例 6r：极速突进（0.8 秒 ×2，冷却 8 秒）----
	ZhangBen.chong_zhi()
	_she_deng_ji(5)
	ZhangBen.dang_qian_ti_xing = 5.0
	yu.scale = yu._ti_xing_vector()
	yu.position = Vector2(400, 400)
	yu.fang_xiang = Vector2.RIGHT
	yu.set_process(false)
	yu._qu_xiao_shi_fang()
	yu.zhu_dong_leng_que.clear()
	var ji_su: NengLi = _zhuang_bei(&"ji_su_tu_jin")
	assert_eq(1 if ji_su != null else 0, 1, "极速能力资源应可加载")
	assert_eq(1 if yu.shi_fang_zhu_dong(ji_su) else 0, 1, "极速释放成功")
	assert_eq(_xiang_deng(yu._su_du_bei_lv, 2.0), 1, "极速速度倍率 ×2")
	assert_eq(_xiang_deng(yu._su_du_sheng_yu, 0.8), 1, "极速持续 0.8 秒")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"ji_su_tu_jin"), 8.0), 1, "极速冷却 8 秒")
	assert_eq(1 if yu.shi_fang_zhu_dong(ji_su) else 0, 0, "施放中再按无效")
	yu._geng_xin_zhu_dong(0.81)
	assert_eq(_xiang_deng(yu._su_du_bei_lv, 1.0), 1, "极速到期恢复 1.0×")
	yu.fang_xiang = Vector2.ZERO

	# ---- 用例 6s：蛮力冲撞（0.45 秒 ×2.2 速，伤害 ×2，每目标一次，不整吞）----
	ZhangBen.chong_zhi()
	_she_deng_ji(5)
	ZhangBen.dang_qian_ti_xing = 5.0
	yu.scale = yu._ti_xing_vector()
	yu.position = Vector2(400, 400)
	yu.fang_xiang = Vector2.RIGHT
	yu.set_process(false)
	yu._qu_xiao_shi_fang()
	yu.zhu_dong_leng_que.clear()
	var chong: NengLi = _zhuang_bei(&"man_li_chong_zhuang")
	assert_eq(1 if chong != null else 0, 1, "冲撞能力资源应可加载")
	var chong_yu: YuNpc = _zao_yu(6)
	chong_yu.position = yu.position + Vector2(120, 0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(1 if yu.shi_fang_zhu_dong(chong) else 0, 1, "冲撞释放成功")
	assert_eq(_xiang_deng(yu._chong_zhuang_sheng_yu, 0.45), 1, "冲撞持续 0.45 秒")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"man_li_chong_zhuang"), 9.0), 1, "冲撞冷却 9 秒")
	var chong_shang_hai := ZhanDou.yao_ji_shang_hai(5.0, yu.zui_ba) * 2.0
	var ti_qian := chong_yu.tixing
	yu._chong_zhuang(0.1)  # 先位移
	await get_tree().physics_frame  # 物理帧刷新重叠列表（Area2D 不会在同一帧内跟着瞬移）
	yu._chong_zhuang(0.001)  # 再扫一次：这一下才结算
	assert_eq(_xiang_deng(chong_yu.tixing, ti_qian - chong_shang_hai), 1, "冲撞伤害 ×2（6.0 → 4.4）")
	assert_eq(1 if is_instance_valid(chong_yu) else 0, 1, "冲撞不整吞：鱼还在")
	var ti_hou := chong_yu.tixing
	await get_tree().physics_frame
	yu._chong_zhuang(0.001)
	assert_eq(_xiang_deng(chong_yu.tixing, ti_hou), 1, "同一目标冲撞只结算一次")
	chong_yu.position = yu.position
	yu._on_zui_qu_entered(null)
	assert_eq(1 if is_instance_valid(chong_yu) else 0, 1, "冲撞期间嘴圈吞被屏蔽")
	yu._geng_xin_zhu_dong(0.5)
	assert_eq(_xiang_deng(yu._chong_zhuang_sheng_yu, 0.0), 1, "冲撞到期结束")
	chong_yu.queue_free()
	await get_tree().process_frame

	# ---- 用例 6t：潜伏突袭（2 秒隐身 + 下一口 ×2；索敌跳过 / 咬中与受伤破隐）----
	ZhangBen.chong_zhi()
	_she_deng_ji(5)
	ZhangBen.dang_qian_ti_xing = 5.0
	yu.scale = yu._ti_xing_vector()
	yu.position = Vector2(400, 400)
	yu.fang_xiang = Vector2.ZERO
	yu.wudi = false
	yu.set_process(false)
	yu._qu_xiao_shi_fang()
	yu.zhu_dong_leng_que.clear()
	var qian_fu: NengLi = _zhuang_bei(&"qian_fu_tu_xi")
	assert_eq(1 if qian_fu != null else 0, 1, "潜伏能力资源应可加载")
	var kan_yu: YuNpc = _zao_yu(2)
	kan_yu.position = yu.position + Vector2(100, 0)
	kan_yu.ai_kai_qi = true
	kan_yu.set_process(false)
	await get_tree().physics_frame
	assert_eq(1 if yu.shi_fang_zhu_dong(qian_fu) else 0, 1, "潜伏释放成功")
	assert_eq(1 if yu.yin_shen else 0, 1, "潜伏中：隐身")
	assert_eq(_xiang_deng(yu._yin_shen_sheng_yu, 2.0), 1, "潜伏 2 秒")
	assert_eq(1 if yu._qian_fu_zhun_bei else 0, 1, "下一口 ×2 已就绪")
	assert_eq(_xiang_deng(yu.get_node("AnimatedSprite2D").modulate.a, 0.45), 1, "潜伏半透明")
	kan_yu._mu_biao = null
	kan_yu._si_kao()
	assert_eq(1 if kan_yu._mu_biao == null else 0, 1, "普通鱼看不见潜伏的玩家")
	kan_yu._mu_biao = yu
	kan_yu._xing_dong(0.016)
	assert_eq(1 if kan_yu._mu_biao == null else 0, 1, "已在追的鱼也会放弃潜伏目标")
	# 下一口 ×2
	var yao_wu: YuNpc = _zao_yu(5)
	yao_wu.position = yu.position + Vector2(70, 0)
	await get_tree().physics_frame
	var yao_wu_xue := yao_wu.tixing
	yu._yao_ji_leng_que = 0.0
	yu._chang_shi_yao_ji()
	assert_eq(_xiang_deng(yao_wu.tixing, yao_wu_xue - ZhanDou.yao_ji_shang_hai(5.0, 1.0) * 2.0), 1,
			"潜伏下一口伤害 ×2")
	assert_eq(1 if not yu.yin_shen else 0, 1, "咬中破隐")
	assert_eq(1 if not yu._qian_fu_zhun_bei else 0, 1, "×2 用掉后清零")
	# 到期破隐
	yu.zhu_dong_leng_que.clear()
	yu._qu_xiao_shi_fang()
	assert_eq(1 if yu.shi_fang_zhu_dong(qian_fu) else 0, 1, "冷却清零后再潜伏")
	yu._geng_xin_zhu_dong(2.1)
	assert_eq(1 if not yu.yin_shen else 0, 1, "2 秒到期自动破隐")
	# 受击破隐
	yu.zhu_dong_leng_que.clear()
	yu.shi_fang_zhu_dong(qian_fu)
	yu.wudi = false
	ZhangBen.dang_qian_ti_xing = 5.0
	yu.shou_dao_yao_ji(0.1, kan_yu, "shen")
	assert_eq(1 if not yu.yin_shen else 0, 1, "受伤破隐")
	kan_yu.queue_free()
	yao_wu.queue_free()
	await get_tree().process_frame

	# ---- 用例 6t2：多主动共存（独立冷却 / 释放互斥跨能力 / 防重复入槽）----
	ZhangBen.chong_zhi()
	_she_deng_ji(5)
	ZhangBen.dang_qian_ti_xing = 5.0
	yu.scale = yu._ti_xing_vector()
	yu.position = Vector2(400, 400)
	yu.fang_xiang = Vector2.ZERO
	yu.wudi = true
	yu.zi_dong_yao_ji = false
	yu.set_process(false)
	yu._qu_xiao_shi_fang()
	yu.zhu_dong_leng_que.clear()
	var duo_dian: NengLi = _zhuang_bei(&"fang_dian_ma_bi")
	var duo_su: NengLi = _zhuang_bei(&"ji_su_tu_jin")
	assert_eq(ZhangBen.zhu_dong_zu.size(), 2, "连装两个主动：共存于主动组（唯一槽已退役）")
	assert_eq(1 if yu.shi_fang_zhu_dong(duo_su) else 0, 1, "释放极速成功")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"ji_su_tu_jin"), 8.0), 1, "极速冷却 8 秒")
	assert_eq(1 if yu.shi_fang_zhu_dong(duo_dian) else 0, 0, "极速施放中按放电无效（释放互斥跨能力）")
	yu._geng_xin_zhu_dong(0.81)  # 极速持续 0.8 秒走完
	assert_eq(1 if yu.shi_fang_zhu_dong(duo_dian) else 0, 1, "极速结束后放电可释放")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"fang_dian_ma_bi"), 6.0), 1, "放电冷却 6 秒（独立计时，未被极速占用）")
	yu._geng_xin_zhu_dong(6.1)
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"fang_dian_ma_bi"), 0.0), 1, "放电冷却归 0")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"ji_su_tu_jin"), 8.0 - 0.81 - 6.1), 1,
			"极速仍剩约 1.1 秒（各主动独立倒数，互不干扰）")
	assert_eq(1 if yu.shi_fang_zhu_dong(duo_su) else 0, 0, "极速冷却未到按不动")
	assert_eq(1 if yu.shi_fang_zhu_dong(duo_dian) else 0, 1, "放电就绪按得动（各自门禁）")
	ZhangBen.xuan_neng_li(duo_su)  # 直调装备入口：重复装同 id 主动
	assert_eq(ZhangBen.zhu_dong_zu.size(), 2, "重复装备同 id 主动：槽数不涨（满档幂等）")
	await get_tree().process_frame

	# ---- 用例 6t3：通用能力池六主动（效果生效 + 升档门控；插课：策划案 8.2）----
	for n in get_tree().get_nodes_in_group("yu_npc"):
		n.queue_free()
	await get_tree().process_frame
	ZhangBen.chong_zhi()
	_she_deng_ji(5)
	ZhangBen.dang_qian_ti_xing = 5.0
	yu.scale = yu._ti_xing_vector()
	yu.position = Vector2(400, 400)
	yu.fang_xiang = Vector2.ZERO
	yu.wudi = true
	yu.zi_dong_yao_ji = false
	yu.set_process(false)
	yu._qu_xiao_shi_fang()
	yu.zhu_dong_leng_que.clear()
	# 鱼雷冲刺：与冲撞同构（复用 _shi_fang_chong_zhuang，数值各看各的表）
	var yu_lei: NengLi = _zhuang_bei(&"yu_lei_chong_ci")
	assert_eq(1 if yu.shi_fang_zhu_dong(yu_lei) else 0, 1, "鱼雷冲刺释放成功")
	assert_eq(_xiang_deng(yu._chong_zhuang_sheng_yu, 0.35), 1, "鱼雷冲刺持续 0.35 秒")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"yu_lei_chong_ci"), 7.0), 1, "鱼雷冲刺 1 档冷却 7 秒")
	ZhangBen.xuan_neng_li(yu_lei)  # 再选一次 = 升 2 档
	assert_eq(ZhangBen.dang_qian_zhu_dong_dang(&"yu_lei_chong_ci"), 2, "鱼雷冲刺已升到 2 档")
	yu.zhu_dong_leng_que.clear()
	yu._qu_xiao_shi_fang()
	assert_eq(1 if yu.shi_fang_zhu_dong(yu_lei) else 0, 1, "升档后可再次释放")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"yu_lei_chong_ci"), 4.9), 1, "鱼雷冲刺 2 档冷却降到 4.9（升档门控）")
	# 长矛穿刺：与冲撞同构（复用 _shi_fang_chong_zhuang，数值各看各的表）
	var chuan_ci: NengLi = _zhuang_bei(&"chang_mao_chuan_ci")
	yu.zhu_dong_leng_que.clear()
	yu._qu_xiao_shi_fang()
	assert_eq(1 if yu.shi_fang_zhu_dong(chuan_ci) else 0, 1, "长矛穿刺释放成功")
	assert_eq(_xiang_deng(yu._chong_zhuang_sheng_yu, 0.5), 1, "长矛穿刺持续 0.5 秒")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"chang_mao_chuan_ci"), 8.0), 1, "长矛穿刺冷却 8 秒")
	# 剑鱼 NPC：玩家进入 320 像素冲刺半径就直接启动穿刺（与冲撞共用直线分支）
	var jian_zhong: YuZhong = load("res://data/yuzhong/jian_yu.tres")
	var jian_npc := _zao_yu(7, jian_zhong)
	jian_npc.ai_kai_qi = true
	jian_npc.position = Vector2(600, 400)  # 玩家在 (400,400)：距离 200 < ban_jing 320
	jian_npc._mu_biao = yu
	assert_eq(1 if jian_npc._chang_shi_neng_li() else 0, 1, "剑鱼进入穿刺距离应启动直线冲刺")
	assert_eq(1 if jian_npc._chong_zhuang_sheng_yu > 0.0 else 0, 1, "穿刺复用冲撞的剩余时间通道")
	jian_npc.queue_free()
	await get_tree().process_frame
	# 弱点洞察：锁定视野内体型最大的鱼，只对它加伤并亮出等级
	var ruo_dian: NengLi = _zhuang_bei(&"ruo_dian_dong_cha")
	yu.zhu_dong_leng_que.clear()
	yu._qu_xiao_shi_fang()
	var xiao_yu := _zao_yu(2)
	xiao_yu.position = Vector2(440, 400)  # 距玩家 40
	var da_yu := _zao_yu(6)
	da_yu.position = Vector2(480, 400)  # 距玩家 80：比小鱼大，应被优先锁定
	# 直接调用配小半径夹具：只锁这两条，不受场上其它测试鱼干扰
	var ce_ding := NengLi.new()
	ce_ding.bian_hao = &"ruo_dian_dong_cha"
	ce_ding.lei_xing = NengLi.LeiXing.ZHU_DONG
	ce_ding.leng_que = 15.0
	ce_ding.chi_xu = 5.0
	ce_ding.ban_jing = 120.0
	ce_ding.shu_zhi = 1.5
	ce_ding.zui_da_dang = 3
	assert_eq(1 if yu._shi_fang_ruo_dian(ce_ding, 1) else 0, 1, "弱点洞察锁定成功")
	assert_eq(1 if yu._ruo_dian_mu_biao == da_yu else 0, 1, "锁定范围内体型最大的鱼")
	assert_eq(_xiang_deng(yu._ruo_dian_sheng_yu, 5.0), 1, "弱点洞察持续 5 秒")
	assert_eq(1 if da_yu._deng_ji_biao != null and da_yu._deng_ji_biao.visible else 0, 1, "目标头顶亮出等级数字")
	assert_eq_ming(da_yu._deng_ji_biao.text, "Lv.6", "等级数字与目标体型一致")
	assert_eq(_xiang_deng(yu._ruo_dian_bei(da_yu), 1.5), 1, "对锁定目标伤害 ×1.5")
	assert_eq(_xiang_deng(yu._ruo_dian_bei(xiao_yu), 1.0), 1, "对非锁定目标不加伤")
	# 走真实释放入口：冷却与持续按数据表结算
	yu._ruo_dian_sheng_yu = 0.0
	yu._ruo_dian_mu_biao = null
	yu.zhu_dong_leng_que.clear()
	assert_eq(1 if yu.shi_fang_zhu_dong(ruo_dian) else 0, 1, "弱点洞察经技能入口释放成功")
	assert_eq(_xiang_deng(yu._ruo_dian_sheng_yu, 5.0), 1, "1 档持续 5 秒")
	assert_eq(_xiang_deng(yu.leng_que_sheng(&"ruo_dian_dong_cha"), 15.0), 1, "1 档冷却 15 秒")
	assert_eq(1 if yu._ruo_dian_mu_biao != null else 0, 1, "锁定仍在有效期内")
	# 大眼金枪鱼 NPC：看到目标就洞察（不改变移动），咬玩家时加伤
	var zong_zhong: YuZhong = load("res://data/yuzhong/zong_yu.tres")
	var zong_npc := _zao_yu(5, zong_zhong)
	zong_npc.position = Vector2(500, 400)  # 距玩家 100 < 640
	zong_npc._mu_biao = yu
	assert_eq(1 if zong_npc._chang_shi_neng_li() else 0, 0, "洞察不改变移动：起手返回 false 继续追击")
	assert_eq(1 if zong_npc._ruo_dian_sheng_yu > 0.0 else 0, 1, "金枪鱼洞察进入持续期")
	assert_eq(_xiang_deng(zong_npc._ruo_dian_bei_lv, 1.5), 1, "NPC 洞察加伤 ×1.5")
	# 伤害落地：同一口，洞察期间咬得更痛
	ZhangBen.hui_ti_xing(99.0)  # 补满血：前面用例把玩家咬得差不多了
	yu.wudi = false
	yu._ni_liu_sheng_yu = 0.0
	zong_npc._yao_ji_leng_que = 0.0
	var ruo_xue_you := ZhangBen.dang_qian_ti_xing
	zong_npc._yao(yu)
	var ruo_sun_you := ruo_xue_you - ZhangBen.dang_qian_ti_xing
	zong_npc._ruo_dian_sheng_yu = 0.0
	zong_npc._ruo_dian_bei_lv = 1.0
	yu.wudi = false
	zong_npc._yao_ji_leng_que = 0.0
	ruo_xue_you = ZhangBen.dang_qian_ti_xing
	zong_npc._yao(yu)
	var ruo_sun_wu := ruo_xue_you - ZhangBen.dang_qian_ti_xing
	assert_eq(1 if ruo_sun_you > ruo_sun_wu else 0, 1, "洞察期间咬玩家更痛（加伤真的落到咬击结算）")
	zong_npc.queue_free()
	xiao_yu.queue_free()
	da_yu.queue_free()
	await get_tree().process_frame
	# 逆流闪避：短无敌窗，档 2 加长；窗内咬击直接挡下
	var ni_liu: NengLi = _zhuang_bei(&"ni_liu_shan_bi")
	yu.zhu_dong_leng_que.clear()
	yu._qu_xiao_shi_fang()
	assert_eq(1 if yu.shi_fang_zhu_dong(ni_liu) else 0, 1, "逆流闪避释放成功")
	assert_eq(_xiang_deng(yu._ni_liu_sheng_yu, 0.5), 1, "逆流 1 档无敌窗 0.5 秒")
	yu.wudi = false
	var ni_xue := ZhangBen.dang_qian_ti_xing
	yu.shou_dao_yao_ji(0.2, null, "shen")
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, ni_xue), 1, "逆流无敌窗内咬击直接挡下（wudi 关着也挡）")
	ZhangBen.xuan_neng_li(ni_liu)
	yu.zhu_dong_leng_que.clear()
	yu._qu_xiao_shi_fang()
	assert_eq(1 if yu.shi_fang_zhu_dong(ni_liu) else 0, 1, "逆流 2 档再释放")
	assert_eq(_xiang_deng(yu._ni_liu_sheng_yu, 1.0), 1, "逆流 2 档无敌窗加长到 1 秒（档位门控）")
	# 漩涡：持续吸卷，档 2 半径 180 → 270
	var xuan_wo: NengLi = _zhuang_bei(&"xuan_wo")
	yu.zhu_dong_leng_que.clear()
	yu._qu_xiao_shi_fang()
	assert_eq(1 if yu.shi_fang_zhu_dong(xuan_wo) else 0, 1, "漩涡释放成功")
	assert_eq(_xiang_deng(yu._xuan_wo_sheng_yu, 1.5), 1, "漩涡持续 1.5 秒")
	assert_eq(_xiang_deng(yu._xuan_wo_ban_jing, 180.0), 1, "漩涡 1 档半径 180")
	ZhangBen.xuan_neng_li(xuan_wo)
	yu.zhu_dong_leng_que.clear()
	yu._qu_xiao_shi_fang()
	assert_eq(1 if yu.shi_fang_zhu_dong(xuan_wo) else 0, 1, "漩涡 2 档再释放")
	assert_eq(_xiang_deng(yu._xuan_wo_ban_jing, 270.0), 1, "漩涡 2 档半径扩到 270（档位门控）")
	# 淤泥弹：朝前方丢一团雾（YuNiWu 入 "yu_ni_wu" 组，雾里 NPC 感知打折）
	var yu_ni: NengLi = _zhuang_bei(&"yu_ni_dan")
	var wu_qian := get_tree().get_nodes_in_group("yu_ni_wu").size()
	yu.zhu_dong_leng_que.clear()
	yu._qu_xiao_shi_fang()
	assert_eq(1 if yu.shi_fang_zhu_dong(yu_ni) else 0, 1, "淤泥弹释放成功")
	await get_tree().process_frame
	assert_eq(get_tree().get_nodes_in_group("yu_ni_wu").size() - wu_qian, 1, "淤泥弹应生成一团淤泥雾")
	var wu_tuan: YuNiWu = get_tree().get_nodes_in_group("yu_ni_wu")[wu_qian]
	assert_eq(_xiang_deng(wu_tuan.gan_zhi_xi_shu, 0.25), 1, "雾内感知系数 0.25（读能力表）")
	for w in get_tree().get_nodes_in_group("yu_ni_wu"):
		w.queue_free()  # 清场：雾团 3 秒自散，测试里手动收（资源卫生）
	await get_tree().process_frame
	# 狂暴撕咬：窗口期咬伤倍率
	var kuang_bao: NengLi = _zhuang_bei(&"kuang_bao_si_yao")
	yu.zhu_dong_leng_que.clear()
	yu._qu_xiao_shi_fang()
	assert_eq(1 if yu.shi_fang_zhu_dong(kuang_bao) else 0, 1, "狂暴撕咬释放成功")
	assert_eq(_xiang_deng(yu._kuang_bao_sheng_yu, 4.0), 1, "狂暴 1 档窗口 4 秒")
	assert_eq(_xiang_deng(yu._kuang_bao_bei_lv, 2.0), 1, "狂暴窗口内咬伤 ×2")
	# 声呐脉冲：半径内 NPC 泛黄高亮；档 3 起定身 1 秒
	var sheng_na: NengLi = _zhuang_bei(&"sheng_na_mai_chong")
	var na_yu: YuNpc = _zao_yu(1)
	na_yu.position = yu.position + Vector2(200, 0)
	await get_tree().physics_frame
	yu.zhu_dong_leng_que.clear()
	yu._qu_xiao_shi_fang()
	assert_eq(1 if yu.shi_fang_zhu_dong(sheng_na) else 0, 1, "声呐脉冲释放成功")
	assert_eq(1 if na_yu._gao_liang_sheng_yu > 0.0 else 0, 1, "声呐半径内的鱼泛黄高亮")
	assert_eq(1 if na_yu._fan_ying_ji_shi > 0.0 else 0, 0, "声呐 1 档不定身")
	ZhangBen.xuan_neng_li(sheng_na)
	ZhangBen.xuan_neng_li(sheng_na)  # 升到 3 档
	yu.zhu_dong_leng_que.clear()
	yu._qu_xiao_shi_fang()
	assert_eq(1 if yu.shi_fang_zhu_dong(sheng_na) else 0, 1, "声呐 3 档再释放")
	assert_eq(1 if na_yu._fan_ying_ji_shi >= 1.0 else 0, 1, "声呐 3 档定身 1 秒（复用 NPC 反应延迟通道）")
	na_yu.queue_free()
	await get_tree().process_frame

	# ---- 用例 6t4：通用能力池十四被动（咬击联动 / 受击折减 / 进食与感知改写）----
	for n in get_tree().get_nodes_in_group("yu_npc"):
		n.queue_free()
	await get_tree().process_frame
	ZhangBen.chong_zhi()
	_she_deng_ji(5)
	ZhangBen.dang_qian_ti_xing = 5.0
	yu.scale = yu._ti_xing_vector()
	yu.position = Vector2(400, 400)
	yu.fang_xiang = Vector2.ZERO
	yu.wudi = true
	yu.zi_dong_yao_ji = false
	yu.set_process(false)
	yu._qu_xiao_shi_fang()
	yu._xiao_hua.clear()
	yu.xiao_hua_jin_du = 0.0
	# 撕裂齿 1 层：咬击联动掉 2 块肉（int(round(2.0))；伤害本体走咬击，不掉额外血）
	_zhuang_bei(&"si_lie_chi")
	var si_yu: YuNpc = _zao_yu(6)
	si_yu.position = Vector2(400, 650)
	await get_tree().physics_frame
	var rou_qian2 := get_tree().get_nodes_in_group("rou_kuai").size()
	yu._yao_ji_lian_dong(si_yu, 0.8)  # 直调联动：不依赖物理重叠，咬击伤害入口另算
	await get_tree().process_frame
	assert_eq(get_tree().get_nodes_in_group("rou_kuai").size() - rou_qian2, 2, "撕裂齿 1 层：咬一口掉 2 块肉")
	assert_eq(_xiang_deng(si_yu.tixing, 6.0), 1, "咬击联动只掉肉：血量走咬击本体（这里没扣）")
	# 毒腺：咬击附加毒晕；满层覆写 45（不是 20+5×2=30）
	_zhuang_bei(&"du_xian")
	si_yu.du_yun = 0.0
	yu._yao_ji_lian_dong(si_yu, 0.8)
	assert_eq(_xiang_deng(si_yu.du_yun, 20.0), 1, "毒腺 1 层：咬中附加 20 毒晕")
	ZhangBen.xuan_neng_li(ZhangBen.zhao_bei_dong(&"du_xian"))
	ZhangBen.xuan_neng_li(ZhangBen.zhao_bei_dong(&"du_xian"))  # 叠满 3 层
	si_yu.du_yun = 0.0
	yu._yao_ji_lian_dong(si_yu, 0.8)
	assert_eq(_xiang_deng(si_yu.du_yun, 45.0), 1, "毒腺满层质变：附加直接 45（dang_biao 覆写）")
	si_yu.queue_free()
	for r in get_tree().get_nodes_in_group("rou_kuai"):
		r.queue_free()
	await get_tree().process_frame
	# 暴食连锁：吞鱼后的下一口 ×2（窗口 3 秒；档 3 加长到 5 秒，由账本 dang_zhi 供给）
	_zhuang_bei(&"bao_shi_lian_suo")
	yu._bao_shi_chu_fa()
	assert_eq(_xiang_deng(yu._bao_shi_sheng_yu, 3.0), 1, "暴食连锁：窗口 3 秒（吞鱼触发，测试直调入口）")
	assert_eq(_xiang_deng(yu._bao_shi_bei_lv, 2.0), 1, "暴食窗口内下一口 ×2")
	# 电感受器：NPC 锁定玩家的瞬间，玩家头顶冒 "!" 预警
	_zhuang_bei(&"dian_gan_shou_qi")
	var dian_yu: YuNpc = _zao_yu(2)
	dian_yu.position = yu.position + Vector2(150, 0)
	dian_yu.gan_zhi = 300.0  # 裸鱼默认感知不定：测试里拉大，确保 150px 在感知内
	await get_tree().physics_frame
	dian_yu.ai_kai_qi = true
	dian_yu._si_kao()
	assert_eq(1 if dian_yu._mu_biao == yu else 0, 1, "电感受器前置：NPC 锁定玩家")
	assert_eq(1 if yu._yu_jing_biao != null and yu._yu_jing_biao.visible else 0, 1, "被锁定的瞬间：玩家头顶冒 \"!\" 预警")
	dian_yu.queue_free()
	await get_tree().process_frame
	# 猎手直觉：周期扫描（基准 260 ×(1+层数)）圈内的鱼泛黄
	_zhuang_bei(&"lie_shou_zhi_jue")
	var lie_yu: YuNpc = _zao_yu(1)
	lie_yu.position = yu.position + Vector2(200, 0)
	await get_tree().physics_frame
	yu._lie_shou_sao_miao(0.5)  # 直调扫描：跳过 0.5 秒节拍
	assert_eq(1 if lie_yu._gao_liang_sheng_yu > 0.0 else 0, 1, "猎手直觉：扫描圈内的鱼被高亮")
	lie_yu.queue_free()
	await get_tree().process_frame
	# 肾上腺：残血条件加速（体型 ≤ 上限 30% 时 +30%）
	_zhuang_bei(&"shen_shang_xian")
	assert_eq(_xiang_deng(yu._shen_shang_xian_jia_su(), 0.0), 1, "满血时肾上腺不加速")
	ZhangBen.dang_qian_ti_xing = 1.0  # 上限 6.0 的一成七：已进残血线
	assert_eq(_xiang_deng(yu._shen_shang_xian_jia_su(), 0.3), 1, "残血（≤30% 上限）：加速 +30%")
	ZhangBen.dang_qian_ti_xing = 5.0
	# 读数断言（行为侧：贪食/饥饿耐受改账本曲线在账本测试；尾鳍/大胃王在速度层与消化槽生效）
	_zhuang_bei(&"da_wei_wang")
	_zhuang_bei(&"ling_min_wei_qi")
	_zhuang_bei(&"yin_ni_qi_xi")
	assert_eq(_xiang_deng(ZhangBen.bei_dong_zhi(&"da_wei_wang"), 0.15), 1, "大胃王 1 层：消化时长 ÷1.15 的读数就位")
	assert_eq(_xiang_deng(ZhangBen.bei_dong_zhi(&"ling_min_wei_qi"), 0.15), 1, "灵敏尾鳍 1 层：转向/追速 +15%")
	ZhangBen.xuan_neng_li(ZhangBen.zhao_bei_dong(&"ling_min_wei_qi"))
	ZhangBen.xuan_neng_li(ZhangBen.zhao_bei_dong(&"ling_min_wei_qi"))
	assert_eq(_xiang_deng(ZhangBen.bei_dong_fu_jia(&"ling_min_wei_qi", &"zhui_jia"), 0.1), 1, "灵敏尾鳍满层附加：追速再 +10%")
	assert_eq(_xiang_deng(ZhangBen.wan_jia_yin_bi_xi_shu(), 0.9), 1, "隐匿气息 1 层：玩家可见度 ×0.9")
	# 食腐者 1 层：吃肉经验 ×1.5（1 → round(1.5) = 2）
	ZhangBen.jing_yan = 0
	_zhuang_bei(&"shi_fu_zhe")
	yu.diao_rou(1)
	await get_tree().process_frame
	var fu_rou: RouKuai = get_tree().get_nodes_in_group("rou_kuai")[0]
	fu_rou.ke_chi = true
	fu_rou.global_position = yu.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	yu._chi_rou()  # 玩家 _process 已停（set_process(false)）：手动跑一次进食扫描（重叠列表已刷新）
	await get_tree().process_frame
	assert_eq(ZhangBen.jing_yan, 2, "食腐者 1 层：吃 1 经验的肉得 round(1×1.5)=2")
	# 软鳞（满层覆写 36%）+ 硬鳞反击（被咬反伤 20%）：受击链一次过
	var ruan_lin: NengLi = _zhuang_bei(&"ruan_lin")
	ZhangBen.xuan_neng_li(ruan_lin)
	ZhangBen.xuan_neng_li(ruan_lin)  # 叠满 3 层 → dang_biao 覆写 36
	_zhuang_bei(&"ying_lin_fan_ji")
	var ying_yu: YuNpc = _zao_yu(1)
	ying_yu.position = Vector2(400, 650)
	await get_tree().physics_frame
	var ying_xue := ying_yu.tixing
	yu.wudi = false
	var lin_qian := ZhangBen.dang_qian_ti_xing
	yu.shou_dao_yao_ji(0.2, ying_yu, "shen")
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, lin_qian - 0.2 * (1.0 - 36.0 / 100.0)), 1, "软鳞满层：受伤 ×0.64")
	assert_eq(_xiang_deng(ying_yu.tixing, ying_xue - 0.2 * 0.2), 1, "硬鳞反击：被咬反伤 20%")
	ying_yu.queue_free()
	for r in get_tree().get_nodes_in_group("rou_kuai"):
		r.queue_free()
	await get_tree().process_frame

	# ---- 用例 6t5：新增八能力——4 主动 + 4 被动（策划案 v0.9，2026-11-03）----
	for n in get_tree().get_nodes_in_group("yu_npc"):
		n.queue_free()
	for r in get_tree().get_nodes_in_group("rou_kuai"):
		r.queue_free()
	await get_tree().process_frame
	ZhangBen.chong_zhi()
	_she_deng_ji(5)
	ZhangBen.dang_qian_ti_xing = 5.0
	yu.scale = yu._ti_xing_vector()
	yu.position = Vector2(400, 400)
	yu.dang_qian_jiao = 0.0
	yu.fang_xiang = Vector2.ZERO
	yu.wudi = true
	yu.zi_dong_yao_ji = false
	yu.set_process(false)
	yu._qu_xiao_shi_fang()
	yu._bao_shi_sheng_yu = 0.0  # 上一用例的暴食窗口没走表（玩家 process 已停）：这里手动清
	yu._bao_shi_bei_lv = 1.0
	yu.zhu_dong_leng_que.clear()
	# 硬壳护体：2 秒减伤 60%，咬壳的鱼被撞退 130 像素
	var ying_ke: NengLi = _zhuang_bei(&"ying_ke_hu_ti")
	assert_eq(1 if yu.shi_fang_zhu_dong(ying_ke) else 0, 1, "硬壳护体释放成功")
	assert_eq(_xiang_deng(yu._ying_ke_sheng_yu, 2.0), 1, "硬壳护体 1 档持续 2 秒")
	assert_eq(_xiang_deng(yu._ying_ke_jian_shang, 0.6), 1, "硬壳护体 1 档减伤 60%")
	var ke_yu: YuNpc = _zao_yu(6)
	await get_tree().physics_frame
	yu.wudi = false
	var ke_xue := ZhangBen.dang_qian_ti_xing
	var ke_wei := ke_yu.position
	yu.shou_dao_yao_ji(0.2, ke_yu)
	assert_eq(_xiang_deng(ke_xue - ZhangBen.dang_qian_ti_xing, 0.08), 1, "硬壳护体：0.2 伤害只吃 0.08")
	assert_eq(_xiang_deng(ke_yu.position.distance_to(ke_wei), 130.0), 1, "咬硬壳的鱼被撞退 130 像素")
	ke_yu.queue_free()
	await get_tree().process_frame
	# 电脉冲：清自己的电麻条，半径内 NPC +50；满档电晕的鱼掉一块肉
	yu._qu_xiao_shi_fang()
	yu.zhu_dong_leng_que.clear()
	var dian_mai: NengLi = _zhuang_bei(&"dian_mai_chong")
	ZhangBen.dian_ma = 70.0
	var dian_yu1: YuNpc = _zao_yu(2)
	dian_yu1.position = Vector2(450, 400)
	dian_yu1.dian_ma = 10.0
	var dian_yu2: YuNpc = _zao_yu(2)
	dian_yu2.position = Vector2(500, 400)
	dian_yu2.dian_ma = 80.0
	assert_eq(1 if yu.shi_fang_zhu_dong(dian_mai) else 0, 1, "电脉冲释放成功")
	assert_eq(_xiang_deng(ZhangBen.dian_ma, 0.0), 1, "电脉冲先清空自己的电麻条")
	assert_eq(_xiang_deng(dian_yu1.dian_ma, 60.0), 1, "半径内 NPC 电麻条 +50（10 → 60）")
	assert_eq(1 if dian_yu2.zai_kong_zhi() else 0, 1, "电麻条被推满的 NPC 当场失控")
	dian_yu1.queue_free()
	dian_yu2.queue_free()
	await get_tree().process_frame
	ZhangBen.xuan_neng_li(dian_mai)  # 升 2 档：半径 330
	yu.zhu_dong_leng_que.clear()
	var yuan_yu: YuNpc = _zao_yu(2)
	yuan_yu.position = Vector2(700, 400)  # 距玩家 300：1 档 220 够不着，2 档 330 够得着
	yuan_yu.dian_ma = 0.0
	assert_eq(1 if yu.shi_fang_zhu_dong(dian_mai) else 0, 1, "电脉冲 2 档再释放")
	assert_eq(_xiang_deng(yuan_yu.dian_ma, 50.0), 1, "电脉冲 2 档半径 330：300 像素外的鱼也吃电")
	yuan_yu.queue_free()
	await get_tree().process_frame
	ZhangBen.xuan_neng_li(dian_mai)  # 升 3 档：电晕的鱼掉肉
	yu.zhu_dong_leng_que.clear()
	var dian_dao: YuNpc = _zao_yu(2)
	dian_dao.position = Vector2(500, 400)
	dian_dao.dian_ma = 80.0
	var rou_qian_dian := get_tree().get_nodes_in_group("rou_kuai").size()
	assert_eq(1 if yu.shi_fang_zhu_dong(dian_mai) else 0, 1, "电脉冲 3 档释放成功")
	await get_tree().process_frame
	assert_eq(1 if dian_dao.zai_kong_zhi() else 0, 1, "电脉冲 3 档同样能把鱼电晕")
	assert_eq(get_tree().get_nodes_in_group("rou_kuai").size() - rou_qian_dian, 1, "电脉冲 3 档：被电晕的鱼掉 1 块肉")
	dian_dao.queue_free()
	for r in get_tree().get_nodes_in_group("rou_kuai"):
		r.queue_free()
	await get_tree().process_frame
	# 诱饵气泡：吐出一颗漂泡，NPC 优先去咬；满档咬破炸晕咬它的鱼
	yu._qu_xiao_shi_fang()
	yu.zhu_dong_leng_que.clear()
	var you_er: NengLi = _zhuang_bei(&"you_er_qi_pao")
	var pao_qian := get_tree().get_nodes_in_group("you_er_qi_pao").size()
	assert_eq(1 if yu.shi_fang_zhu_dong(you_er) else 0, 1, "诱饵气泡释放成功")
	await get_tree().process_frame
	assert_eq(get_tree().get_nodes_in_group("you_er_qi_pao").size() - pao_qian, 1, "应生成 1 颗诱饵气泡")
	var qi_pao: YouErQiPao = get_tree().get_nodes_in_group("you_er_qi_pao")[pao_qian]
	assert_eq(_xiang_deng(qi_pao.chi_xu, 3.0), 1, "气泡 1 档存在 3 秒")
	assert_eq(_xiang_deng(qi_pao.ban_jing, 360.0), 1, "气泡吸引半径 360")
	assert_eq(1 if qi_pao.zha_yun else 0, 0, "气泡 1 档咬破不炸晕")
	assert_eq(_xiang_deng(qi_pao.position.x, yu.position.x + 110.0), 1, "气泡吐在朝向前方 110 像素")
	var mi_yu: YuNpc = _zao_yu(2)
	mi_yu.position = qi_pao.position + Vector2(200, 0)
	mi_yu.gong_ji_yu_wang = false  # 连不主动攻击的路人鱼也会被诱饵骗走
	mi_yu._si_kao()
	assert_eq(1 if mi_yu._mu_biao == qi_pao else 0, 1, "NPC 优先把诱饵气泡当目标")
	ZhangBen.xuan_neng_li(you_er)
	ZhangBen.xuan_neng_li(you_er)  # 升 3 档：咬破炸晕
	for q in get_tree().get_nodes_in_group("you_er_qi_pao"):
		q.queue_free()
	await get_tree().process_frame
	yu.zhu_dong_leng_que.clear()
	assert_eq(1 if yu.shi_fang_zhu_dong(you_er) else 0, 1, "诱饵气泡 3 档再释放")
	await get_tree().process_frame
	var qi_pao3: YouErQiPao = get_tree().get_nodes_in_group("you_er_qi_pao")[0]
	assert_eq(1 if qi_pao3.zha_yun else 0, 1, "气泡 3 档咬破会炸晕")
	var zha_yu: YuNpc = _zao_yu(2)
	zha_yu.position = qi_pao3.position + Vector2(40, 0)
	qi_pao3.bei_yao(zha_yu)
	assert_eq(1 if zha_yu.zai_kong_zhi() else 0, 1, "气泡 3 档被咬破：咬它的鱼当场毒晕/失控")
	zha_yu.queue_free()
	mi_yu.queue_free()
	await get_tree().process_frame
	# 血腥狂热：4 秒内进食回体型 +100%；满档咬伤 +25%
	yu._qu_xiao_shi_fang()
	yu.zhu_dong_leng_que.clear()
	var xue_xing: NengLi = _zhuang_bei(&"xue_xing_kuang_re")
	assert_eq(1 if yu.shi_fang_zhu_dong(xue_xing) else 0, 1, "血腥狂热释放成功")
	assert_eq(_xiang_deng(yu._xue_xing_sheng_yu, 4.0), 1, "血腥狂热 1 档持续 4 秒")
	assert_eq(_xiang_deng(yu._xue_xing_hui_bei, 1.0), 1, "血腥狂热：进食回体型 +100%")
	assert_eq(_xiang_deng(yu._xue_xing_hui(1.5), 3.0), 1, "进食回体型加成：1.5 → 3.0")
	ZhangBen.dang_qian_ti_xing = 2.0
	var xue_chi_yu: YuNpc = _zao_yu(1)
	yu._chi_diao(xue_chi_yu)
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 2.0 + (1.0 / 1.5) * 1.2 * 2.0), 1, "狂热期间吃 1 体型鱼：回 1.6（平时 0.8，含吃鱼 +20%）")
	ZhangBen.xuan_neng_li(xue_xing)
	ZhangBen.xuan_neng_li(xue_xing)  # 升 3 档：咬伤 +25%
	yu._qu_xiao_shi_fang()
	yu.zhu_dong_leng_que.clear()
	assert_eq(1 if yu.shi_fang_zhu_dong(xue_xing) else 0, 1, "血腥狂热 3 档再释放")
	assert_eq(_xiang_deng(yu._xue_xing_yao_shang, 0.25), 1, "血腥狂热 3 档：窗口内咬伤 +25%")
	ZhangBen.dang_qian_ti_xing = 5.0
	var xue_yao_yu: YuNpc = _zao_yu(6)
	xue_yao_yu.position = yu.position + Vector2(20, 0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	yu._yao_ji_leng_que = 0.0
	yu._chang_shi_yao_ji()
	assert_eq(_xiang_deng(xue_yao_yu.tixing, 5.0), 1, "狂热咬伤：基础 0.8 ×1.25 = 1.0（6 → 5）")
	xue_yao_yu.queue_free()
	await get_tree().process_frame

	# ---- 用例 6t6：新增四被动（背刺 / 绝境 / 锈鳞 / 腐肉诱饵）----
	for n in get_tree().get_nodes_in_group("yu_npc"):
		n.queue_free()
	for r in get_tree().get_nodes_in_group("rou_kuai"):
		r.queue_free()
	await get_tree().process_frame
	ZhangBen.chong_zhi()
	_she_deng_ji(5)
	ZhangBen.dang_qian_ti_xing = 5.0
	yu.scale = yu._ti_xing_vector()
	yu.position = Vector2(400, 400)
	yu.fang_xiang = Vector2.ZERO
	yu.wudi = true
	yu.zi_dong_yao_ji = false
	yu.set_process(false)
	yu._qu_xiao_shi_fang()
	yu._bao_shi_sheng_yu = 0.0
	yu._bao_shi_bei_lv = 1.0
	# 背刺直觉：目标背对我才 +30%
	_zhuang_bei(&"bei_ci_zhi_jue")
	var bei_yu: YuNpc = _zao_yu(3)
	bei_yu.position = Vector2(500, 400)
	var bei_tie := bei_yu.get_node("AnimatedSprite2D") as AnimatedSprite2D
	bei_tie.flip_h = false  # 朝右：玩家在它左边 = 背后
	assert_eq(_xiang_deng(yu._bei_ci_bei(bei_yu), 1.3), 1, "背刺直觉 1 层：从背后咬 ×1.3")
	bei_tie.flip_h = true  # 朝左：玩家在它正前方
	assert_eq(_xiang_deng(yu._bei_ci_bei(bei_yu), 1.0), 1, "正面咬不加背刺伤害")
	bei_yu.queue_free()
	await get_tree().process_frame
	# 绝境反咬：目标越大加成越高，2 倍体型吃满
	var jue_jing: NengLi = _zhuang_bei(&"jue_jing_fan_yao")
	var xiao_ju: YuNpc = _zao_yu(3)
	assert_eq(_xiang_deng(yu._jue_jing_bei(xiao_ju), 1.0), 1, "目标比我小：绝境反咬不触发")
	var da_ju: YuNpc = _zao_yu(6)
	assert_eq(_xiang_deng(yu._jue_jing_bei(da_ju), 1.08), 1, "目标 1.2 倍体型：1 档 +40% 按比例给 +8%")
	xiao_ju.queue_free()
	da_ju.queue_free()
	await get_tree().process_frame
	ZhangBen.xuan_neng_li(jue_jing)
	ZhangBen.xuan_neng_li(jue_jing)  # 升 3 档：上限 +60%
	var ju_da: YuNpc = _zao_yu(10)
	assert_eq(_xiang_deng(yu._jue_jing_bei(ju_da), 1.6), 1, "目标 2 倍体型：满档 +60% 全吃")
	ju_da.queue_free()
	await get_tree().process_frame
	# 锈鳞：被咬时攻击者叠 25 电麻
	_zhuang_bei(&"xiu_lin")
	var xiu_yu: YuNpc = _zao_yu(3)
	xiu_yu.position = Vector2(450, 450)
	xiu_yu.dian_ma = 0.0
	xiu_yu._yun_xuan_ji_shi = 0.0
	yu.wudi = false
	yu.shou_dao_yao_ji(0.2, xiu_yu)
	assert_eq(_xiang_deng(xiu_yu.dian_ma, 25.0), 1, "锈鳞 1 层：咬我的鱼 +25 电麻")
	xiu_yu.queue_free()
	await get_tree().process_frame
	# 腐肉诱饵：咬中的鱼掉 1 块发光肉，肉自己吸引 NPC 来吃
	_zhuang_bei(&"fu_rou_you_er")
	var fu_yu: YuNpc = _zao_yu(6)
	fu_yu.position = Vector2(600, 600)
	var rou_qian_fu := get_tree().get_nodes_in_group("rou_kuai").size()
	yu._yao_ji_lian_dong(fu_yu, 0.8)
	assert_eq(get_tree().get_nodes_in_group("rou_kuai").size() - rou_qian_fu, 1, "腐肉诱饵：咬一口掉 1 块发光肉")
	var you_rou: RouKuai = get_tree().get_nodes_in_group("rou_kuai")[rou_qian_fu]
	assert_eq(_xiang_deng(you_rou.fu_rou_you_er_sheng_yu, 2.0), 1, "腐肉诱饵 1 层：发光 2 秒")
	assert_eq(_xiang_deng(you_rou.xi_yin_ban_jing, 320.0), 1, "腐肉诱饵吸引半径 320")
	await get_tree().process_frame
	var chou_yu: YuNpc = _zao_yu(2)
	chou_yu.position = you_rou.position + Vector2(200, 0)
	chou_yu.gong_ji_yu_wang = false
	chou_yu._si_kao()
	assert_eq(1 if chou_yu._mu_biao == you_rou else 0, 1, "附近的鱼被发光肉吸过去")
	you_rou.ke_chi = true
	var rou_jing := you_rou.jing_yan
	chou_yu.position = you_rou.position
	var chou_jing_qian := chou_yu.jing_yan_nei
	chou_yu._mu_biao = you_rou
	chou_yu._xing_dong(0.016)
	assert_eq(chou_yu.jing_yan_nei - chou_jing_qian, rou_jing, "NPC 吃掉发光肉：涨隐藏经验")
	await get_tree().process_frame
	assert_eq(1 if not is_instance_valid(you_rou) else 0, 1, "发光肉被吃掉后释放")
	chou_yu.queue_free()
	fu_yu.queue_free()
	await get_tree().process_frame

	# ---- 用例 6u：NPC 能力——旗鱼突进 / 金枪鱼洞察 / 巨口鱼潜伏 / 首领看不见潜伏 ----
	for n in get_tree().get_nodes_in_group("yu_npc"):
		n.queue_free()
	await get_tree().process_frame
	ZhangBen.chong_zhi()
	_she_deng_ji(5)
	ZhangBen.dang_qian_ti_xing = 5.0
	yu.scale = yu._ti_xing_vector()
	yu.position = Vector2(400, 400)
	yu.fang_xiang = Vector2.ZERO
	yu.wudi = false
	yu.set_process(false)
	yu._qu_xiao_shi_fang()
	# 旗鱼：200 像素（感知内、咬击外）→ 启动 0.8 秒 2 倍速突进
	var qi_yu: YuNpc = _zao_yu(3, load("res://data/yuzhong/qi_yu.tres"))
	qi_yu.position = yu.position + Vector2(200, 0)
	qi_yu.sudu = 300.0
	qi_yu.set_process(false)
	qi_yu._mu_biao = yu
	await get_tree().physics_frame
	assert_eq(1 if qi_yu._chang_shi_neng_li() else 0, 1, "旗鱼在突进半径内会启动突进")
	assert_eq(_xiang_deng(qi_yu._tu_jin_sheng_yu, 0.8), 1, "旗鱼突进持续 0.8 秒")
	assert_eq(_xiang_deng(qi_yu._neng_li_leng_que, 6.0), 1, "旗鱼突进冷却 6 秒")
	var qi_qian := qi_yu.position.x
	qi_yu._tu_jin(0.1)
	assert_eq(1 if qi_yu.position.x < qi_qian else 0, 1, "旗鱼朝玩家方向突进")
	qi_yu.queue_free()
	await get_tree().process_frame
	# 大眼金枪鱼：150 像素 → 洞察起手（不位移），持续期内咬玩家 ×1.5
	ZhangBen.dang_qian_ti_xing = 5.0
	yu.wudi = false
	var zong_yu: YuNpc = _zao_yu(3, load("res://data/yuzhong/zong_yu.tres"))
	zong_yu.position = yu.position + Vector2(150, 0)
	zong_yu.sudu = 300.0
	zong_yu.set_process(false)
	zong_yu._mu_biao = yu
	await get_tree().physics_frame
	assert_eq(1 if zong_yu._chang_shi_neng_li() else 0, 0, "金枪鱼洞察不启动冲撞（继续正常追击）")
	assert_eq(_xiang_deng(zong_yu._chong_zhuang_sheng_yu, 0.0), 1, "金枪鱼不再走冲撞通道")
	assert_eq(_xiang_deng(zong_yu._ruo_dian_sheng_yu, 5.0), 1, "金枪鱼洞察持续 5 秒")
	assert_eq(_xiang_deng(zong_yu._neng_li_leng_que, 12.0), 1, "金枪鱼洞察冷却 12 秒")
	zong_yu._yao_ji_leng_que = 0.0
	var zong_xue_qian := ZhangBen.dang_qian_ti_xing
	zong_yu._yao(yu)
	assert_eq(_xiang_deng(zong_xue_qian - ZhangBen.dang_qian_ti_xing, 0.75), 1, "洞察期间 3 级鱼咬 5.0 → 4.25（0.5 ×1.5）")
	zong_yu.queue_free()
	await get_tree().process_frame
	# 巨口鱼：200 像素 → 隐身 2 秒，下一口 ×2
	ZhangBen.dang_qian_ti_xing = 5.0
	yu.wudi = false
	var ju_kou: YuNpc = _zao_yu(3, load("res://data/yuzhong/ju_kou_yu.tres"))
	ju_kou.position = yu.position + Vector2(200, 0)
	ju_kou.sudu = 0.0
	ju_kou.set_process(false)
	ju_kou._mu_biao = yu
	await get_tree().physics_frame
	assert_eq(1 if ju_kou._chang_shi_neng_li() else 0, 0, "巨口鱼潜伏不打断本帧追击")
	assert_eq(_xiang_deng(ju_kou._yin_shen_sheng_yu, 2.0), 1, "巨口鱼潜伏 2 秒")
	assert_eq(1 if ju_kou._qian_fu_zhun_bei else 0, 1, "巨口鱼下一口 ×2 就绪")
	assert_eq(_xiang_deng(ju_kou._neng_li_leng_que, 8.0), 1, "巨口鱼潜伏冷却 8 秒")
	ju_kou._yao_ji_leng_que = 0.0
	ju_kou._yao(yu)
	var ju_shang_hai := ZhanDou.yao_ji_shang_hai(3.0, ju_kou.zui_ba) * 2.0
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, 5.0 - ju_shang_hai), 1,
			"巨口鱼潜伏下一口 ×2：5.0 → %.2f" % (5.0 - ju_shang_hai))
	assert_eq(1 if not ju_kou._qian_fu_zhun_bei else 0, 1, "巨口鱼咬后破隐")
	ju_kou.queue_free()
	await get_tree().process_frame
	# 首领：玩家潜伏时放弃追击
	var boos: YuNpc = _zao_yu(10, load("res://data/yuzhong/fen_yu.tres"))
	boos.position = yu.position + Vector2(150, 0)
	boos.set_process(false)
	boos._boos_zhu_ji_ji_shi = 5.0
	yu.yin_shen = true
	boos._boos_xing_dong(0.1)
	assert_eq(_xiang_deng(boos._boos_zhu_ji_ji_shi, 0.0), 1, "首领也看不见潜伏玩家：放弃追击")
	yu.yin_shen = false
	boos.queue_free()
	await get_tree().process_frame
	# 回归：死亡切场景时旧 YuNpc 可能离树后还被 _process 一帧，不得读视口
	var li_shu: YuNpc = load("res://scenes/YuNpc.tscn").instantiate()
	assert_eq(1 if not li_shu.is_inside_tree() else 0, 1, "回归夹具：YuNpc 未进树")
	li_shu._process(0.016)  # 修复前这里会报 get_viewport_rect / get_camera_2d
	assert_eq(1 if li_shu._shi_jiao_fan_wei() == Rect2() else 0, 1,
			"离树后 _shi_jiao_fan_wei 返回空范围，不读视口")
	li_shu.free()

	# ---- 用例 6v：形态外观/数值应用（直接调 Yu.ying_yong_xing_tai）----
	var qi_yu_xt: XingTai = load("res://data/xingtai/qi_yu.tres")
	var deng_xt: XingTai = load("res://data/xingtai/ye_deng_long_yu.tres")
	var dian_xt: XingTai = load("res://data/xingtai/lv_yu.tres")
	assert_eq(1 if qi_yu_xt != null and deng_xt != null and dian_xt != null else 0, 1,
			"形态资源应能加载（集成用例前置）")
	yu.ying_yong_xing_tai(qi_yu_xt)
	assert_eq(_xiang_deng(yu.yidong_sudu, 360.0), 1, "旗鱼速度 360")
	assert_eq(_xiang_deng(yu.zui_ba, 0.85), 1, "旗鱼嘴巴 0.85")
	assert_eq(_xiang_deng(yu.zhuanxiang_ji_su, 7.5), 1, "旗鱼转向 7.5")
	assert_eq(1 if yu.get_node("AnimatedSprite2D").sprite_frames == qi_yu_xt.dong_hua else 0, 1,
			"旗鱼应换成 4 帧形态动画")
	assert_eq(yu.get_node("AnimatedSprite2D").sprite_frames.get_frame_count(&"you"), 4,
			"旗鱼形态动画应是 4 帧")
	assert_eq(1 if yu.get_node("AnimatedSprite2D").animation == &"you" else 0, 1,
			"形态动画名必须是 you")
	yu.ying_yong_xing_tai(deng_xt)  # 还原灯笼鱼，后续死亡用例沿用
	assert_eq(_xiang_deng(yu.yidong_sudu, 300.0), 1, "还原灯笼鱼速度 300")

	# ---- 用例 6w：第二个 Yu 在 _ready 自动应用当前形态（电鳗）----
	ZhangBen.chong_zhi()
	assert_eq(1 if ZhangBen.kai_ju_xing_tai(dian_xt) else 0, 1, "装配电鳗形态")
	var yu2: Yu = load("res://scenes/Yu.tscn").instantiate()
	yu2.position = Vector2(600, 600)
	yu2.zi_dong_yao_ji = false
	add_child(yu2)
	await get_tree().physics_frame
	assert_eq(ZhangBen.deng_ji, 1, "电鳗开局 Lv.1")
	assert_eq(_xiang_deng(yu2.yidong_sudu, 260.0), 1, "第二个 Yu 自动读电鳗速度 260")
	assert_eq(_xiang_deng(yu2.zui_ba, 1.0), 1, "第二个 Yu 自动读电鳗嘴巴 1.0")
	assert_eq(_xiang_deng(yu2.zhuanxiang_ji_su, 6.0), 1, "第二个 Yu 自动读电鳗转向 6.0")
	assert_eq(1 if yu2.get_node("AnimatedSprite2D").sprite_frames == dian_xt.dong_hua else 0, 1,
			"第二个 Yu 自动换电鳗 4 帧动画")
	assert_eq(yu2.get_node("AnimatedSprite2D").sprite_frames.get_frame_count(&"you"), 4,
			"电鳗形态动画应是 4 帧")
	assert_eq(_xiang_deng(yu2.scale.x, ZhangBen.ti_xing_dao_chi_du(2.0)), 1,
			"电鳗 Lv.1 开局缩放按体型 2.0 计算")
	yu2.queue_free()
	await get_tree().process_frame
	ZhangBen.chong_zhi()

	# ---- 用例 6x：形态选择页（12 形态：玩家 + 10 NPC 鱼 + 首领鲸鲨）----
	var ce_lu_jing := "user://ce_panding_jie_suo_%d.json" % OS.get_process_id()
	var ce_zhong_tu := "user://ce_panding_zhongtu_%d.json" % OS.get_process_id()
	var ce_she_zhi := "user://ce_panding_shezhi_%d.json" % OS.get_process_id()
	if FileAccess.file_exists(ce_lu_jing):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ce_lu_jing))
	if FileAccess.file_exists(ce_she_zhi):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ce_she_zhi))
	CunDang.lu_jing = ce_lu_jing
	CunDang.zhong_tu_lu_jing = ce_zhong_tu  # 中途档同样隔离：6y 的胜负回调不许删真实存档
	CunDang.she_zhi_lu_jing = ce_she_zhi  # 设置文件隔离：断言读写不许碰玩家真实设置
	CunDang.tiao_shi_qing_chu_jin_du()  # 建一份 0 胜临时存档
	var xuan: CanvasLayer = load("res://scenes/XingTaiXuanZe.tscn").instantiate()
	add_child(xuan)
	await get_tree().process_frame
	var ka_zu: GridContainer = xuan.get_node("KaPianZu/WangGe")
	assert_eq(ka_zu.get_child_count(), 12, "选择页 12 张卡：玩家 + 10 NPC 鱼 + 鲸鲨")
	assert_eq(_shu_suo_ka(ka_zu), 0, "0 胜全开：12 个形态都可选")
	assert_eq_ming(xuan.get_node("FuBiaoTi").text, "已胜利 0 次 · 解锁 12/12", "0 胜副标题")
	CunDang.sheng_li_ci_shu = 2  # 直接模拟两胜（解锁推导只读这个计数）
	xuan._shua_xin()
	assert_eq(ka_zu.get_child_count(), 12, "2 胜仍是 12 张卡")
	assert_eq(_shu_suo_ka(ka_zu), 0, "2 胜：全部形态仍解锁")
	assert_eq_ming(xuan.get_node("FuBiaoTi").text, "已胜利 2 次 · 解锁 12/12", "2 胜副标题")
	xuan.queue_free()
	await get_tree().process_frame

	# ---- 用例 6y：胜利信号 → 局外记档；形态全部预解锁，胜利不再解锁新形态 ----
	CunDang.tiao_shi_qing_chu_jin_du()  # 清回 0 胜
	ZhangBen.chong_zhi()
	ZhangBen.ding_jie_suan(ZhangBen.JieJu.SHENG_LI)  # 场景无 Main：只发信号，不切场景
	assert_eq(CunDang.sheng_li_ci_shu, 1, "胜利信号让 CunDang 立即记 1 胜")
	assert_eq(1 if CunDang.shi_fou_jie_suo(&"ao_tu_wo_niu_yu") else 0, 1, "主角始终解锁")
	assert_eq(1 if FileAccess.file_exists(ce_lu_jing) else 0, 1, "胜利瞬间写入临时存档")
	var jie_suan: CanvasLayer = load("res://scenes/JieSuan.tscn").instantiate()
	add_child(jie_suan)
	await get_tree().process_frame
	assert_eq(1 if jie_suan.has_node("HuanXingTai") else 0, 1, "结算页有换形态按钮")
	assert_eq(1 if jie_suan.has_node("JieSuoTiShi") else 0, 1, "结算页有解锁提示")
	assert_eq(1 if jie_suan.get_node("JieSuoTiShi").visible else 0, 0,
			"全部形态 0 胜解锁：胜利后不显示新解锁提示")
	assert_eq(CunDang.shang_ci_xin_jie_suo.size(), 0, "胜利后解锁提示队列为空")
	jie_suan.queue_free()
	await get_tree().process_frame
	# 死亡/失败不显示残留提示：手动塞一条，_ready 应无条件消费并隐藏
	CunDang.shang_ci_xin_jie_suo.append(dian_xt)
	ZhangBen.jie_ju = ZhangBen.JieJu.SI_WANG
	var jie_suan2: CanvasLayer = load("res://scenes/JieSuan.tscn").instantiate()
	add_child(jie_suan2)
	await get_tree().process_frame
	assert_eq(1 if jie_suan2.get_node("JieSuoTiShi").visible else 0, 0, "死亡页不显示解锁提示")
	assert_eq(CunDang.shang_ci_xin_jie_suo.size(), 0, "死亡页也消费掉残留提示")
	jie_suan2.queue_free()
	await get_tree().process_frame
	ZhangBen.chong_zhi()
	# 测试存档与真实存档隔离：恢复默认路径并删临时文件
	CunDang.lu_jing = "user://shenhaishiji_jin_du.json"
	CunDang.zai_ru()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ce_lu_jing))
	await get_tree().process_frame

	# ---- 用例 6y2：按鱼种进化——选剑鱼后只出剑鱼分支，跨鱼种分支被拒 ----
	ZhangBen.chong_zhi()
	var jian_xt: XingTai = load("res://data/xingtai/jian_yu.tres")
	assert_eq(1 if ZhangBen.kai_ju_xing_tai(jian_xt) else 0, 1, "前置：剑鱼开局装配成功")
	assert_eq(ZhangBen.deng_ji, 1, "剑鱼开局统一 Lv.1")
	assert_eq_ming(String(ZhangBen.dang_qian_yu_zhong()), "jian_yu", "当前鱼种是剑鱼")
	var jian_fen_zhi := JinHuaKu.wan_jia_fen_zhi(ZhangBen.dang_qian_yu_zhong())
	assert_eq(jian_fen_zhi.size(), 3, "剑鱼有且只有 3 条进化分支")
	for fz in jian_fen_zhi:
		assert_eq_ming(String(fz.ji_yu_bian_hao), "jian_yu", "剑鱼候选分支全部属于剑鱼组")
	ZhangBen.deng_ji = 6  # 直接抬到门槛：弹窗 _ready 会补开
	var jian_chuang: CanvasLayer = load("res://scenes/JinHuaDanChuang.tscn").instantiate()
	add_child(jian_chuang)
	await get_tree().process_frame
	assert_eq(1 if jian_chuang.visible else 0, 1, "剑鱼 Lv.6 弹出进化三选一")
	assert_eq(jian_chuang.dang_qian_san_zhang.size(), 3, "剑鱼弹窗展示 3 条剑鱼分支")
	var wo_niu_fen_zhi := JinHuaKu.wan_jia_fen_zhi(&"ao_tu_wo_niu_yu")
	assert_eq(1 if ZhangBen.jin_hua_wei(wo_niu_fen_zhi[0]) else 0, 0,
			"剑鱼选蜗牛鱼分支被拒（跨鱼种）")
	assert_eq(1 if ZhangBen.dang_qian_jin_hua == null else 0, 1, "跨鱼种失败：不记进化形态")
	assert_eq(1 if ZhangBen.ke_yi_jin_hua() else 0, 1, "跨鱼种失败：本局资格仍在")
	var ben_jin_jian := yu.get_node("AnimatedSprite2D") as AnimatedSprite2D
	jian_chuang._on_fen_zhi_dian(0)
	assert_eq_ming(String(ZhangBen.dang_qian_jin_hua.bian_hao), String(jian_fen_zhi[0].bian_hao),
			"剑鱼选定自己的第一条分支")
	assert_eq(1 if ben_jin_jian.sprite_frames == jian_fen_zhi[0].dong_hua else 0, 1,
			"剑鱼进化后播剑鱼分支的 6 帧动画")
	assert_eq(ben_jin_jian.sprite_frames.get_frame_count(&"you"), 6, "剑鱼进化动画 6 帧")
	ZhangBen.jie_shu_jin_hua_yan_chu()  # 不真等 1.7 秒演出
	jian_chuang.queue_free()
	await get_tree().process_frame
	ZhangBen.chong_zhi()

	# ---- 用例 6z：主界面 + 中途存档显隐 + 设置面板暂停/恢复 ----
	# 主界面是新启动场景（main_scene 配置断言在 ce_shu_ju）；这里测行为：
	# 继续游戏按钮显隐 = 是否存在中途存档（生命周期规则④）
	CunDang.qing_chu_zhong_tu()  # 从"无档"状态开始
	var zhu_jie: CanvasLayer = load("res://scenes/ZhuJieMian.tscn").instantiate()
	add_child(zhu_jie)
	await get_tree().process_frame
	assert_eq_ming(zhu_jie.get_node("BiaoTi").text, "大鱼吃小鱼", "主界面标题")
	assert_eq_ming(zhu_jie.get_node("BanBen").text, "v0.3-原型", "主界面版本号")
	assert_eq(1 if zhu_jie.get_node("AnNiuZu/KaiShi") is Button else 0, 1, "主界面有开始游戏按钮")
	assert_eq(1 if zhu_jie.get_node("AnNiuZu/TuiChu") is Button else 0, 1, "主界面有退出游戏按钮")
	assert_eq(1 if not zhu_jie.get_node("AnNiuZu/JiXu").visible else 0, 1, "无中途存档：继续游戏应隐藏")
	# 主界面设置面板（游戏外）：音量+摇杆侧边，不含暂停（与游戏内 SheZhi 分工）
	assert_eq(1 if zhu_jie.has_node("ZhuSheZhiMianBan/SheZhiMianBan/MianBanLie/YinXiaoLie/YinXiaoHua") else 0, 1,
			"主界面设置面板有音效音量滑条")
	assert_eq(1 if zhu_jie.has_node("ZhuSheZhiMianBan/SheZhiMianBan/MianBanLie/BgmLie/BgmHua") else 0, 1,
			"主界面设置面板有音乐音量滑条")
	assert_eq(1 if zhu_jie.has_node("ZhuSheZhiMianBan/SheZhiMianBan/MianBanLie/YaoGanAnNiu") else 0, 1,
			"主界面设置面板有摇杆侧边按钮")
	assert_eq(1 if zhu_jie.has_node("ZhuSheZhiMianBan/SheZhiMianBan/MianBanLie/GuanBi") else 0, 1,
			"主界面设置面板有关闭按钮")
	zhu_jie._on_she_zhi_pressed()
	assert_eq(1 if zhu_jie.get_node("ZhuSheZhiMianBan/SheZhiMianBan").visible else 0, 1,
			"主界面点设置后面板应可见")
	assert_eq(1 if not shu.paused else 0, 1, "主界面打开设置不应暂停（没有一局在跑）")
	zhu_jie.get_node("ZhuSheZhiMianBan")._on_guan_bi()
	assert_eq(1 if not zhu_jie.get_node("ZhuSheZhiMianBan/SheZhiMianBan").visible else 0, 1,
			"关闭应收起主界面设置面板")
	zhu_jie.queue_free()
	await get_tree().process_frame
	# 摆一局"打了一半"的状态 → 写中途档 → 主界面"继续游戏"应现身
	ZhangBen.chong_zhi()
	assert_eq(1 if ZhangBen.kai_ju_xing_tai(dian_xt) else 0, 1, "前置：装配电鳗形态")
	ZhangBen.jia_jing_yan(5)
	ZhangBen.ju_nei_shi_jian = 66.0
	assert_eq(1 if CunDang.xie_zhong_tu() else 0, 1, "运行时写档：默认查 /root/ZhangBen")
	var zhu_jie2: CanvasLayer = load("res://scenes/ZhuJieMian.tscn").instantiate()
	add_child(zhu_jie2)
	await get_tree().process_frame
	assert_eq(1 if zhu_jie2.get_node("AnNiuZu/JiXu").visible else 0, 1, "有中途存档：继续游戏应显示")
	zhu_jie2.queue_free()
	await get_tree().process_frame
	CunDang.qing_chu_zhong_tu()
	ZhangBen.chong_zhi()
	# 游戏内设置面板：Main 结构骨架（不入树：instantiate 后查节点，查完立即 free）
	var mo_ni: Node2D = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	assert_eq(1 if mo_ni.has_node("SheZhi/SheZhiAnNiu") else 0, 1, "Main 有右上角设置按钮")
	assert_eq(1 if mo_ni.has_node("SheZhi/SheZhiMianBan/MianBanLie/ZanTing") else 0, 1,
			"设置面板有暂停按钮")
	assert_eq(1 if mo_ni.has_node("SheZhi/SheZhiMianBan/MianBanLie/JiXu") else 0, 1,
			"设置面板有继续按钮")
	assert_eq(1 if mo_ni.has_node("SheZhi/SheZhiMianBan/MianBanLie/FanHui") else 0, 1,
			"设置面板有返回主界面并保存按钮")
	assert_eq(1 if mo_ni.get_node("SheZhi").process_mode == Node.PROCESS_MODE_ALWAYS else 0, 1,
			"设置面板根应是 Always（暂停中可点，与三选一弹窗同一套）")
	mo_ni.free()
	# 暂停/恢复切换：入树面板实例直接走按钮回调（paused 是真树状态）
	var mian_ban: CanvasLayer = load("res://scenes/SheZhi.tscn").instantiate()
	add_child(mian_ban)
	await get_tree().process_frame
	assert_eq(1 if not shu.paused else 0, 1, "前置：暂停测试从非暂停开始")
	mian_ban._on_she_zhi_an_niu()
	assert_eq(1 if shu.paused else 0, 1, "打开设置面板应暂停全场（打开即暂停）")
	assert_eq(1 if mian_ban.get_node("SheZhiMianBan").visible else 0, 1, "打开后面板应可见")
	# 「角色」能力一览：入口按钮插在设置菜单里，点开是全屏滚动面板
	var jiao_se_an_niu: Button = mian_ban.get_node_or_null("SheZhiMianBan/MianBanLie/JiaoSe")
	assert_eq(1 if jiao_se_an_niu != null else 0, 1, "设置菜单应有「角色」入口")
	if jiao_se_an_niu != null:
		assert_eq_ming(jiao_se_an_niu.text, "角色", "入口按钮文字")
		assert_eq(1 if jiao_se_an_niu.get_index() < mian_ban.get_node("SheZhiMianBan/MianBanLie/FanHui").get_index() else 0,
				1, "「角色」应排在「返回主界面」之前")
	mian_ban._on_jiao_se_an_niu()
	assert_eq(1 if mian_ban.get_node("JiaoSeFuCeng").visible else 0, 1, "点「角色」应打开能力一览")
	assert_eq(1 if mian_ban.has_node("JiaoSeFuCeng/JiaoSeMianBan/WaiLie/GunDong/NeiLie") else 0, 1,
			"能力页应有可滚动内容列（竖屏/横屏都能看全）")
	assert_eq(1 if mian_ban.get_node("JiaoSeFuCeng/JiaoSeMianBan/WaiLie/BiaoTiLie/BiaoTi").text == "当前角色" else 0,
			1, "能力页标题为「当前角色」")
	assert_eq(1 if mian_ban.get_node("JiaoSeFuCeng/JiaoSeMianBan/WaiLie/GunDong/NeiLie").get_child_count() > 0 else 0,
			1, "能力页打开后必须有内容（能力卡或空状态提示）")
	mian_ban._on_jiao_se_guan_bi()
	assert_eq(1 if mian_ban.get_node("JiaoSeFuCeng").visible else 0, 0, "关闭能力页只收这一层")
	assert_eq(1 if shu.paused else 0, 1, "关闭能力页不解除暂停（设置面板仍在）")
	mian_ban._on_zan_ting_an_niu()
	assert_eq(1 if shu.paused else 0, 1, "暂停按钮保持暂停（幂等）")
	mian_ban._on_ji_xu_an_niu()
	assert_eq(1 if not shu.paused else 0, 1, "继续应解除暂停")
	assert_eq(1 if not mian_ban.get_node("SheZhiMianBan").visible else 0, 1, "继续应收起面板")
	mian_ban.queue_free()
	await get_tree().process_frame
	# ---- 游玩设置：读写、坏档回退、音量应用、摇杆侧边（独立文件，与局内存档互不干扰）----
	CunDang.yin_xiao_yin_liang = 0.7
	CunDang.bgm_yin_liang = 0.4
	CunDang.yao_gan_ce = "you"
	assert_eq(1 if CunDang.xie_she_zhi() else 0, 1, "写设置应成功")
	assert_eq(1 if FileAccess.file_exists(ce_she_zhi) else 0, 1, "设置应落在临时路径")
	CunDang.yin_xiao_yin_liang = 1.0  # 弄脏缓存：读档必须覆盖回来
	CunDang.bgm_yin_liang = 1.0
	CunDang.yao_gan_ce = "zuo"
	CunDang.zai_ru_she_zhi()
	assert_eq(_xiang_deng(CunDang.yin_xiao_yin_liang, 0.7), 1, "读设置应恢复音效音量 0.7")
	assert_eq(_xiang_deng(CunDang.bgm_yin_liang, 0.4), 1, "读设置应恢复音乐音量 0.4")
	assert_eq_ming(CunDang.yao_gan_ce, "you", "读设置应恢复摇杆右下")
	var huai_she_zhi := FileAccess.open(ce_she_zhi, FileAccess.WRITE)
	huai_she_zhi.store_string("{\"ban_ben\": 999}")  # 版本不认 → 整体回退默认
	huai_she_zhi.close()
	CunDang.zai_ru_she_zhi()
	assert_eq(_xiang_deng(CunDang.yin_xiao_yin_liang, 1.0), 1, "设置版本不认：音量回默认 1.0")
	assert_eq_ming(CunDang.yao_gan_ce, "zuo", "设置版本不认：摇杆回默认左下")
	# YinXiang 音量属性：线性 0~1，0 = -80dB 全静音；BGM 在 -10dB 基础值上叠加
	YinXiang.yin_xiao_yin_liang = 0.0
	assert_eq(_xiang_deng(YinXiang._chi[0].volume_db, -80.0), 1, "音效 0% → 播放器 -80dB 静音")
	YinXiang.yin_xiao_yin_liang = 1.0
	assert_eq(_xiang_deng(YinXiang._chi[0].volume_db, 0.0), 1, "音效 100% → 播放器 0dB")
	YinXiang.bgm_yin_liang = 0.0
	assert_eq(_xiang_deng(YinXiang._bgm.volume_db, -90.0), 1, "音乐 0% → -10dB 基础上再 -80dB")
	YinXiang.bgm_yin_liang = 1.0
	assert_eq(_xiang_deng(YinXiang._bgm.volume_db, -10.0), 1, "音乐 100% → 恢复 -10dB 基础值")
	# 摇杆侧边：设置 you → 入树实例的中心应在右半屏（纯逻辑在 ce_yao_gan，这里测设置接线）
	CunDang.yao_gan_ce = "you"
	var ce_yg: YaoGan = load("res://scenes/YaoGan.tscn").instantiate()
	add_child(ce_yg)
	assert_eq(1 if ce_yg.zhong_xin.x > 640.0 else 0, 1, "右手模式：摇杆中心应在右半屏")
	ce_yg.queue_free()
	await get_tree().process_frame
	CunDang.yao_gan_ce = "zuo"  # 恢复默认，别污染后续用例
	# 设置临时路径也恢复默认
	CunDang.she_zhi_lu_jing = "user://shenhaishiji_shezhi.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ce_she_zhi))
	# 中途档临时路径也恢复默认：后续死亡用例触发胜负回调时删的是真实路径（不存在则幂等空删）
	CunDang.zhong_tu_lu_jing = "user://shenhaishiji_zhongtu.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ce_zhong_tu))  # 临时中途档收尾

	# ---- 用例 6za：NPC 隐藏经验条（v0.4：吃东西涨经验、升级=体型+1、受伤不倒扣）----
	ZhangBen.jing_yan = 0  # 从零记：断言 NPC 的成长不污染玩家账本
	for r in get_tree().get_nodes_in_group("rou_kuai"):
		r.queue_free()  # 清残留鱼肉：前面用例掉的肉漂进靶鱼吃肉区会多记经验（偶发红）
	await get_tree().process_frame
	var lan_yu_zhong: YuZhong = load("res://data/yuzhong/lan_yu.tres")  # Lv.1 / 分值 1
	var jing_yu_a: YuNpc = _zao_yu(2, lan_yu_zhong)  # 隐藏等级从鱼种 1 起跳；体型覆盖 2
	yu.position = Vector2(400, 400)  # 镜头锚点拉回固定处：靶鱼放玩家旁，躲开出屏回收
	jing_yu_a.position = Vector2(560, 400)  # 玩家旁 160px：屏内且互不干扰
	assert_eq(jing_yu_a.deng_ji_nei, 1, "隐藏等级初始 = 鱼种等级（蓝鱼 Lv.1）")
	jing_yu_a.jia_jing_yan_nei(3)  # 未到阈值（Lv.1 需 10×1.2=12）
	assert_eq(jing_yu_a.jing_yan_nei, 3, "吃 3 点经验：隐藏经验条记 3")
	assert_eq(_xiang_deng(jing_yu_a.tixing, 2.0), 1, "未到阈值不升级：体型不动")
	jing_yu_a.jia_jing_yan_nei(9)  # 3+9=12 恰达阈值
	assert_eq(jing_yu_a.deng_ji_nei, 2, "经验满阈值：隐藏等级 +1")
	assert_eq(_xiang_deng(jing_yu_a.tixing, 3.0), 1, "升级 = 体型 +1（视觉变大，单值模型拍板）")
	assert_eq(jing_yu_a.jing_yan_nei, 0, "升级扣掉已用阈值：经验清零")
	var qian_deng := jing_yu_a.deng_ji_nei
	jing_yu_a.jia_jing_yan_nei(200)  # 大数连升：while 循环一口吞一群的镜像
	var sheng_le := jing_yu_a.deng_ji_nei - qian_deng
	assert_eq(1 if sheng_le >= 5 else 0, 1, "一次 200 经验应连升多级（200/15~30 均值 ≥5）")
	assert_eq(_xiang_deng(jing_yu_a.tixing, 3.0 + float(sheng_le)), 1, "连升 N 级 = 体型 +N")
	jing_yu_a.shou_dao_yao_ji(0.5, null, "shen")  # 受伤掉体型
	assert_eq(_xiang_deng(jing_yu_a.tixing, 3.0 + float(sheng_le) - 0.5), 1, "被咬掉 0.5 体型")
	assert_eq(jing_yu_a.deng_ji_nei, qian_deng + sheng_le, "受伤不倒扣隐藏等级（成长永不回退）")
	assert_eq(1 if jing_yu_a.jing_yan_nei >= 0 else 0, 1, "受伤也不清经验进度")
	# NPC 吃鱼肉块涨经验：经验取 KeChiWu.jing_yan（与玩家同字段）
	var rou_qian_nei := jing_yu_a.jing_yan_nei
	var rou_b: RouKuai = load("res://scenes/RouKuai.tscn").instantiate()
	rou_b.ke_chi = true  # 跳过 0.4 秒保护期
	rou_b.position = jing_yu_a.position
	add_child(rou_b)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(jing_yu_a.jing_yan_nei - rou_qian_nei, 1, "NPC 吃一块鱼肉应 +1 隐藏经验（吃白吃时代结束）")
	assert_eq(ZhangBen.jing_yan, 0, "NPC 成长全走自己的账：玩家经验纹丝不动")
	jing_yu_a.queue_free()
	for r in get_tree().get_nodes_in_group("rou_kuai"):
		r.queue_free()  # 清场
	await get_tree().process_frame

	# ---- 用例 6zb：鲸鲨同食（v0.4：巨口吞入不分玩家与 NPC，吃 NPC 涨隐藏经验）----
	for n in get_tree().get_nodes_in_group("yu_npc"):
		n.queue_free()  # 清场：只留本用例的鱼
	await get_tree().process_frame
	var tong_shi: YuNpc = load("res://scenes/YuNpc.tscn").instantiate()
	tong_shi.yu_zhong = load("res://data/yuzhong/fen_yu.tres")  # 鲸鲨：Lv.10、shi_boss
	tong_shi.ai_kai_qi = false  # 手动调吞食方法：不让自动 AI 干扰
	yu.position = Vector2(400, 400)  # 把镜头拽过来：鲸鲨和小鱼都留在屏内，躲开出屏回收
	tong_shi.position = Vector2(700, 400)
	add_child(tong_shi)
	var xiao_1: YuNpc = _zao_yu(1, lan_yu_zhong)   # 分值 1
	var xiao_2: YuNpc = _zao_yu(2, load("res://data/yuzhong/hong_yu.tres"))  # 分值 1
	xiao_1.position = tong_shi.position + Vector2(60, 0)   # 嘴边：吞食距离 = 35+140+14×体型
	xiao_2.position = tong_shi.position + Vector2(0, 80)
	await get_tree().process_frame
	tong_shi._tun_shen_bian_yu(0.31)  # 越过 0.3 秒节流：立即扫一圈
	assert_eq(1 if xiao_1.si_le else 0, 1, "鲸鲨身边的小鱼 1 应被吞（同食）")
	assert_eq(1 if xiao_2.si_le else 0, 1, "鲸鲨身边的小鱼 2 应被吞（同食）")
	assert_eq(tong_shi.jing_yan_nei, 2, "吞 2 条分值 1 的小鱼：隐藏经验 +2（真·吃全场吃肥）")
	# 吞不动的大鱼：体型门槛不过（10 < 10×1.1），交给推挤层
	var da_yu_c: YuNpc = _zao_yu(10, load("res://data/yuzhong/zong_yu.tres"))
	da_yu_c.position = tong_shi.position + Vector2(60, 0)
	tong_shi._tun_shen_bian_yu(0.31)
	assert_eq(1 if not da_yu_c.si_le else 0, 1, "吞不动的大鱼（体型≥自己÷1.1）不被整吞")
	# 玩家豁免：玩家不在 yu_npc 组——同食永不误吞玩家（对玩家保持纯咬击）
	yu.position = tong_shi.position + Vector2(40, 0)
	yu.wudi = true  # 哨兵：万一被吞/被咬也不影响后续用例
	tong_shi._tun_shen_bian_yu(0.31)
	assert_eq(1 if is_instance_valid(yu) else 0, 1, "玩家站在鲸鲨嘴边也不被同食吞掉（对玩家保持纯咬击）")
	tong_shi.queue_free()
	da_yu_c.queue_free()
	await get_tree().process_frame

	# ---- 用例 6y：进化体系——Lv.6 弹 3 选 1、全数值 ×1.5、每局一次 ----
	# 进化完成会点亮图鉴并写永久档：这里重新临时化路径（6x 段末尾已恢复默认），
	# 否则测试会把玩家真实存档里的「已点亮形态」写脏
	var ce_jh_lu := "user://ce_panding_jinhua_%d.json" % OS.get_process_id()
	if FileAccess.file_exists(ce_jh_lu):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ce_jh_lu))
	CunDang.lu_jing = ce_jh_lu
	CunDang.zai_ru()
	# 玩家专属：账本默认形态是凹凸蜗牛鱼，进化分支 3 条全部可选
	ZhangBen.chong_zhi()
	ZhangBen.deng_ji = 5  # 差一级到门槛
	ZhangBen.dang_qian_ti_xing = ZhangBen.ti_xing_shang_xian()
	yu.yidong_sudu = 300.0  # 前面用例可能改过：先把基础值摆正，倍率断言才有意义
	yu.zui_ba = 1.0
	yu.zhuanxiang_ji_su = 7.0
	# 已有能力保留（v0.18）：进化前先装 1 主动 + 1 被动，进化后必须原样还在
	ZhangBen.xuan_neng_li(load("res://data/nengli/fang_dian_ma_bi.tres"))
	ZhangBen.xuan_neng_li(load("res://data/nengli/ruan_lin.tres"))
	var jin_hua_chuang: CanvasLayer = load("res://scenes/JinHuaDanChuang.tscn").instantiate()
	add_child(jin_hua_chuang)
	await get_tree().process_frame
	assert_eq(1 if jin_hua_chuang.visible else 0, 0, "进化弹窗平时藏着")
	assert_eq(1 if ZhangBen.jin_hua_dan_chuang_zai_chang else 0, 1, "进化弹窗在场会在账本登记")
	assert_eq(1 if ZhangBen.ke_yi_jin_hua() else 0, 0, "Lv.5 还不能进化")
	# 升到 Lv.6：账本发 sheng_ji，进化弹窗接管
	ZhangBen.jia_jing_yan(ZhangBen.dangqian_yuzhi())
	assert_eq(ZhangBen.deng_ji, 6, "前置：应升到 Lv.6")
	assert_eq(1 if ZhangBen.ke_yi_jin_hua() else 0, 1, "Lv.6 获得进化资格")
	assert_eq(1 if jin_hua_chuang.visible else 0, 1, "Lv.6 弹出进化三选一")
	assert_eq(1 if get_tree().paused else 0, 1, "进化选择期间全场暂停")
	assert_eq(jin_hua_chuang.dang_qian_san_zhang.size(), 3, "进化弹窗恰好 3 张分支卡")
	assert_eq_ming(String(jin_hua_chuang.dang_qian_san_zhang[0].ming_zi), "太岁肉灵芝兽", "卡 1 = 东方神话分支")
	assert_eq_ming(String(jin_hua_chuang.dang_qian_san_zhang[2].ming_zi), "超压凝胶炮", "卡 3 = 能力异化分支")
	var shang_xian_qian := ZhangBen.ti_xing_shang_xian()
	jin_hua_chuang._on_fen_zhi_dian(0)  # 选东方分支
	assert_eq(1 if get_tree().paused else 0, 0, "选定分支立即解冻")
	assert_eq(1 if jin_hua_chuang.visible else 0, 0, "选定分支后弹窗收起")
	assert_eq_ming(String(ZhangBen.dang_qian_jin_hua.bian_hao), "tai_sui_rou_ling_zhi_shou",
			"账本记录选中的进化形态")
	assert_eq(_xiang_deng(yu.yidong_sudu, 450.0), 1, "进化：移动速度 ×1.5（300 → 450）")
	assert_eq(_xiang_deng(yu.zui_ba, 1.5), 1, "进化：嘴巴系数 ×1.5")
	assert_eq(_xiang_deng(yu.zhuanxiang_ji_su, 10.5), 1, "进化：转向速率 ×1.5")
	assert_eq(_xiang_deng(ZhangBen.ti_xing_shang_xian(), shang_xian_qian * 1.5), 1,
			"进化：体型（血量）上限 ×1.5")
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, ZhangBen.ti_xing_shang_xian()), 1,
			"进化后体型回满：变强不是残血续命")
	var ben_jin := yu.get_node("AnimatedSprite2D") as AnimatedSprite2D
	assert_eq(1 if ben_jin.sprite_frames == ZhangBen.dang_qian_jin_hua.dong_hua else 0, 1,
			"进化后换用进化形态的 6 帧游动动画")
	assert_eq(ben_jin.sprite_frames.get_frame_count(&"you"), 6,
			"进化形态动画恰好 6 帧（不再是单帧兜底）")
	assert_eq(_xiang_deng(ben_jin.sprite_frames.get_animation_speed(&"you"), 10.0), 1,
			"进化形态动画速度 10 fps")
	assert_eq(1 if ben_jin.sprite_frames.get_frame_texture(&"you", 0)
			!= ZhangBen.dang_qian_jin_hua.tie_tu else 0, 1,
			"进化后首帧取自 6 帧图集，不再是静态贴图")
	assert_eq(1 if ZhangBen.ke_yi_jin_hua() else 0, 0, "每局一次：进化后不再有资格")
	# 已有能力保留：专属主动/被动是“追加”，绝不顶替旧技能（v0.18 8.6）
	assert_eq(1 if ZhangBen.zhuang_lei(&"fang_dian_ma_bi") else 0, 1,
			"进化后原有主动仍在（独立键，不顶替）")
	assert_eq(ZhangBen.dang_qian_bei_dong_ceng(&"ruan_lin"), 1, "进化后原有被动层数不变")
	# 进化演出：1.7 秒免伤，任何扣血通道都挡下
	assert_eq(1 if ZhangBen.jin_hua_yan_chu_zhong else 0, 1, "选定分支后进入进化演出")
	assert_eq(1 if yu.wudi else 0, 1, "演出期间玩家无敌")
	var xue_jin_qian := ZhangBen.dang_qian_ti_xing
	ZhangBen.shou_shang(0.5)
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, xue_jin_qian), 1, "演出期间直接扣血被挡下")
	yu.shou_dao_yao_ji(0.5)
	assert_eq(_xiang_deng(ZhangBen.dang_qian_ti_xing, xue_jin_qian), 1, "演出期间咬击被玩家无敌挡下")
	# 图鉴永久点亮：进化完成即写档（CunDang 听 jin_hua_wan_cheng）
	assert_eq(1 if CunDang.shi_fou_dian_liang(&"tai_sui_rou_ling_zhi_shou") else 0, 1,
			"进化完成：图鉴永久点亮该分支")
	assert_eq(1 if FileAccess.file_exists(ce_jh_lu) else 0, 1, "点亮立即写入临时存档")
	var deng_ji_liu := ZhangBen.deng_ji
	ZhangBen.jia_jing_yan(ZhangBen.dangqian_yuzhi())
	assert_eq(ZhangBen.deng_ji, deng_ji_liu + 1, "前置：再升一级")
	assert_eq(1 if jin_hua_chuang.visible else 0, 0, "每局一次：Lv.7 不再弹进化")
	# 复位 + 继续游戏恢复：只恢复倍率，不重复发能力
	ZhangBen.chong_zhi()
	assert_eq(1 if ZhangBen.dang_qian_jin_hua == null else 0, 1, "重开复位：进化形态清空")
	assert_eq(_xiang_deng(ZhangBen.ti_xing_shang_xian(), 1.0), 1, "重开复位：体型上限回 Lv.0 的 1.0")
	assert_eq(1 if ZhangBen.zai_ru_jin_hua(&"chao_ya_ning_jiao_pao") else 0, 1,
			"继续游戏可按 id 恢复进化形态")
	assert_eq(_xiang_deng(ZhangBen.jin_hua_ti_xing_bei, 1.5), 1, "恢复进化后倍率仍是 1.5")
	assert_eq(1 if not ZhangBen.zai_ru_jin_hua(&"bu_cun_zai") else 0, 1, "未知进化 id 恢复失败但不崩")
	jin_hua_chuang.queue_free()
	await get_tree().process_frame

	# ---- 用例 6z：6 级先进化、选完再弹升级三选一（欠下的能力选择不丢）----
	ZhangBen.chong_zhi()
	ZhangBen.deng_ji = 5
	ZhangBen.dang_qian_ti_xing = ZhangBen.ti_xing_shang_xian()
	yu.yidong_sudu = 300.0
	var jin_chuang: CanvasLayer = load("res://scenes/JinHuaDanChuang.tscn").instantiate()
	add_child(jin_chuang)
	var neng_chuang: CanvasLayer = load("res://scenes/NengLiDanChuang.tscn").instantiate()
	add_child(neng_chuang)
	await get_tree().process_frame
	ZhangBen.jia_jing_yan(ZhangBen.dangqian_yuzhi())  # 升到 6 级：两个弹窗同时听到
	assert_eq(1 if jin_chuang.visible else 0, 1, "6 级：进化先弹")
	assert_eq(1 if neng_chuang.visible else 0, 0, "6 级：升级三选一先让位排队")
	assert_eq(neng_chuang._dai_chu_ci_shu, 1, "6 级欠下的一轮能力选择记在排队数里")
	jin_chuang._on_fen_zhi_dian(0)
	assert_eq(1 if jin_chuang.visible else 0, 0, "进化选完：进化弹窗收起")
	# v0.18：演出中升级三选一先欠着，1.7 秒演出结束才补弹（别让暂停盖住演出）
	assert_eq(1 if ZhangBen.jin_hua_yan_chu_zhong else 0, 1, "进化选完：进入演出")
	assert_eq(1 if neng_chuang.visible else 0, 0, "演出中：升级三选一不抢镜")
	assert_eq(neng_chuang._dai_chu_ci_shu, 1, "演出中：欠账仍记在排队数里")
	ZhangBen.jie_shu_jin_hua_yan_chu()
	assert_eq(1 if neng_chuang.visible else 0, 1, "演出结束：升级三选一接着弹（欠账不丢）")
	assert_eq(1 if get_tree().paused else 0, 1, "能力选择期间仍暂停")
	var yi_xuan_qian := ZhangBen.yi_xuan_neng_li.size()
	neng_chuang._on_neng_li_dian(0)
	assert_eq(1 if neng_chuang.visible else 0, 0, "能力选完：升级三选一收起")
	assert_eq(1 if get_tree().paused else 0, 0, "能力选完：全场解冻")
	assert_eq(ZhangBen.yi_xuan_neng_li.size(), yi_xuan_qian + 1, "欠下的那一轮能力确实进账")
	jin_chuang.queue_free()
	neng_chuang.queue_free()
	await get_tree().process_frame
	ZhangBen.chong_zhi()

	# ---- 用例 6z2：稍后再选——升级三选一不再让位、HUD 读数、点提示重开（策划案 v0.18 8.6）----
	ZhangBen.chong_zhi()
	ZhangBen.deng_ji = 5
	ZhangBen.dang_qian_ti_xing = ZhangBen.ti_xing_shang_xian()
	var jin_zan: CanvasLayer = load("res://scenes/JinHuaDanChuang.tscn").instantiate()
	add_child(jin_zan)
	var neng_zan: CanvasLayer = load("res://scenes/NengLiDanChuang.tscn").instantiate()
	add_child(neng_zan)
	await get_tree().process_frame
	ZhangBen.jia_jing_yan(ZhangBen.dangqian_yuzhi())  # 升 6：进化先弹
	assert_eq(1 if jin_zan.visible else 0, 1, "前置：Lv.6 进化弹窗已开")
	assert_eq(neng_zan._dai_chu_ci_shu, 1, "前置：升级三选一欠一轮")
	jin_zan._on_shao_hou()  # 稍后再选
	assert_eq(1 if jin_zan.visible else 0, 0, "稍后再选：进化弹窗收起")
	assert_eq(1 if ZhangBen.jin_hua_zan_huan else 0, 1, "稍后再选：账本记下暂缓")
	assert_eq(1 if ZhangBen.jin_hua_dai_xuan() else 0, 1, "HUD 读数：有进化待选择")
	assert_eq(1 if neng_zan.visible else 0, 1, "稍后再选：升级三选一立刻补弹（不再让位）")
	assert_eq(1 if get_tree().paused else 0, 1, "升级三选一接管暂停（不是卡在进化窗）")
	assert_eq(neng_zan._dai_chu_ci_shu, 0, "补弹即还账：排队数清零")
	neng_zan._on_neng_li_dian(0)
	assert_eq(1 if get_tree().paused else 0, 0, "能力选完解冻")
	jin_zan.zai_kai()  # 点 HUD 提示回来
	assert_eq(1 if jin_zan.visible else 0, 1, "点提示可重新打开进化三选一")
	assert_eq(1 if ZhangBen.jin_hua_zan_huan else 0, 0, "重开即取消暂缓（脉动提示随之隐藏）")
	jin_zan._on_shao_hou()  # 再暂缓一次：可反复暂缓，不卡死
	assert_eq(1 if ZhangBen.jin_hua_zan_huan else 0, 1, "可反复暂缓")
	jin_zan.zai_kai()
	var yan_chu: CanvasLayer = load("res://scenes/JinHuaYanChu.tscn").instantiate()
	add_child(yan_chu)
	await get_tree().process_frame
	jin_zan._on_fen_zhi_dian(0)
	assert_eq(1 if ZhangBen.jin_hua_zan_huan else 0, 0, "选定分支后暂缓状态清掉")
	assert_eq(1 if ZhangBen.jin_hua_yan_chu_zhong else 0, 1, "选定分支后进入演出")
	assert_eq(1 if yan_chu.get_node("FenZhiGuang").modulate.a > 0.0 else 0, 1,
			"进化演出：全屏分支光已亮起")
	assert_eq_ming(String(yan_chu.get_node("MingZi").text), "进化 · 太岁肉灵芝兽",
			"进化演出：浮现形态名")
	assert_eq(1 if neng_zan.visible else 0, 0, "演出中升级三选一不抢镜")
	ZhangBen.jie_shu_jin_hua_yan_chu()
	assert_eq(1 if neng_zan.visible else 0, 0, "演出结束：没有欠账就不补弹")
	yan_chu.queue_free()
	jin_zan.queue_free()
	neng_zan.queue_free()
	await get_tree().process_frame
	ZhangBen.chong_zhi()
	# 恢复真实存档路径并删掉临时档（进化点亮测试不许留下正式存档）
	CunDang.lu_jing = "user://shenhaishiji_jin_du.json"
	CunDang.zai_ru()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ce_jh_lu))
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
	# 停声再退出：退出时的资源检查比场景树析构早，quit 那一刻仍在播的流
	# 会被记成 "resources still in use"（ERROR 级）→ pao_pi 打红门禁；
	# 被 stop() 掐断的流也要再等墙钟时间引擎才释放引用（帧计数不保险）。
	# 难点：死亡切场景后 JieSuan._ready 还会播结算音，负载高时它哪帧开播
	# 完全不定——不能按固定帧数掐，只能轮询等它开播再掐。
	# 不能 await process_frame：死亡用例已切场景，本节点帧末被 free，
	# 协程不再恢复 → 收尾全丢。改用 process_frame 信号 + 纯闭包链：
	# 闭包不挂本节点，切场景拆不掉（lambda 是值捕获，自引用要过数组拿）
	shu.paused = false  # 死亡路径若带着暂停切场景：帧信号照发，闭包链不被卡住
	YinXiang.ting_bgm()
	YinXiang.quan_ting()
	var shi_bai_shu := failed
	var deng_yin: Array[bool] = [true]  # true = 还在等 JieSuan 的结算音开播
	var zhen: Array[int] = [0]
	var lian: Array = []
	var zou_zhen := func() -> void:
		if deng_yin[0]:
			zhen[0] += 1
			if not YinXiang.ren_he_zai_xiang() and zhen[0] < 120:
				shu.process_frame.connect(lian[0], CONNECT_ONE_SHOT)
				return  # 结算音还没开播：继续等（120 帧兜底，防结算页不播音）
			# 结算音开播（或等满 120 帧）→ 掐掉，转入墙钟释放等待
			YinXiang.ting_bgm()
			YinXiang.quan_ting()
			deng_yin[0] = false
			lian.clear()  # 断开闭包↔数组的引用环：环留着会把脚本资源挂到退出，报 still in use
			# 掐断的流要墙钟时间才被音频线程释放引用——headless 帧间隔可能不足 1 毫秒，
			# 数帧不保险（机器快时 4 帧只有几毫秒，曾整批报 resources still in use）；
			# SceneTreeTimer 不挂节点、切场景拆不掉，与闭包链同一套哲学，墙钟走满再退出
			var jie_guo_shu := shi_bai_shu
			shu.create_timer(0.3).timeout.connect(
					func() -> void: shu.quit(1 if jie_guo_shu > 0 else 0), CONNECT_ONE_SHOT)
			return
	lian.append(zou_zhen)
	shu.process_frame.connect(zou_zhen, CONNECT_ONE_SHOT)


func _she_deng_ji(deng_ji: int) -> void:
	# 测试专用：直接设等级并回满血（正式代码走 jia_jing_yan，不许绕后门）
	ZhangBen.deng_ji = deng_ji
	ZhangBen.dang_qian_ti_xing = ZhangBen.ti_xing_shang_xian()


func zhang_ben_tixing(yu: Yu) -> float:
	# 玩家的体型 getter 直接读账本：这里包一层，断言失败时能看清读的是谁
	return yu.tixing


func _zao_yu(tixing_zhi: int, zhong: YuZhong = null) -> YuNpc:
	# 造一条测试鱼：先定住再进树；add_child 当场跑 _ready（体型=鱼种等级），
	# 之后写 tixing 即覆盖——判定读的是这个值，物理侦测要等下一帧才发生，来得及
	# zhong：可选鱼种（消化/毒/电用例要真实分值/能力；不传就是“裸鱼”，只认体型）
	var npc: YuNpc = load("res://scenes/YuNpc.tscn").instantiate()
	npc.sudu = 0.0  # 测试鱼定住不游走（先于 add_child 设——_ready 不重置 sudu）
	npc.ai_kai_qi = false  # 关状态机：旧用例要的是“站着不动的靶鱼”，不是会追人的 AI
	npc.yu_zhong = zhong  # 必须在 add_child 前注入：_ready 要读鱼种表
	npc.position = Vector2(400, 650)  # 屏内但离玩家远：三圈全都够不着
	add_child(npc)
	npc.tixing = tixing_zhi  # 覆盖 _ready 的鱼种等级——测试体型可控
	npc._ying_she_ti_xing()  # 体型改了，视觉/判定圈也要同步（生产里由咬击入口负责）
	return npc


func _zhuang_bei(bian_hao: StringName) -> NengLi:
	# 测试专用装配：按 id 从 data/nengli 载入并走账本真实入口（会广播给玩家清状态）
	var neng: NengLi = load("res://data/nengli/" + String(bian_hao) + ".tres")
	ZhangBen.xuan_neng_li(neng)
	return neng


func _shu_suo_ka(ka_zu: Container) -> int:
	# 数锁定卡：每张卡里名为 AnNiu 的按钮 disabled = 锁
	var shu := 0
	for ka in ka_zu.get_children():
		var an := ka.find_child("AnNiu", true, false) as Button
		if an != null and an.disabled:
			shu += 1
	return shu


func _shu_ji_bai() -> void:
	# bei_ji_bai 接收器：只数次数
	ji_bai_ci += 1


func _shu_jing_sha_bai() -> void:
	# 鲸鲨 bei_ji_bai 接收器：只数次数
	jing_sha_ci += 1


func _xiang_deng(shu: float, qi_wang: float) -> int:
	# 浮点断言适配器：账本血量是 float，断言助手只认 int——相等给 1，否则 0
	return 1 if is_equal_approx(shu, qi_wang) else 0


func _jin_si(shu: float, qi_wang: float) -> int:
	# 概率断言的宽松适配器：0.7×0.8 这种连乘必有浮点尾差，容差 0.001
	return 1 if absf(shu - qi_wang) < 0.001 else 0


func _biao_he(biao: PackedFloat32Array) -> float:
	# 概率表求和：验证「各等级概率加起来正好是 1」
	var he := 0.0
	for p in biao:
		he += p
	return he


func _biao_qi_wang(biao: PackedFloat32Array) -> float:
	# 概率表的期望值：Σ(等级 × 概率) = 这一分钟平均会刷出几级鱼
	var he := 0.0
	for d in range(biao.size()):
		he += float(d) * biao[d]
	return he


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
