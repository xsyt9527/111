extends Node2D
class_name YuQun
# 鱼群生成器：持续刷新（不是每波来一批），刷新出来的鱼随局内时间越来越大（策划案 8.4 / 8.5）
# 开局：小孩鱼（1 级）为主，偶尔 2 级；每过 20 秒刷新档位 +1（原为每分钟：用户反馈升级太慢），
# 同时「最低等级鱼」占比逐档下降，且最低等级本身也逐档抬高（1→2→3→4 封顶，小鱼彻底退场）

const YU_NPC_CHANGJING := preload("res://scenes/YuNpc.tscn")  # NPC 鱼蓝图
const SHU_ZHI := preload("res://scripts/shu_zhi.gd")  # A 核心数值表
const SHUA_XIN_JI_CHU := 2  # 第 0 档能刷到 2 级
const SHUA_XIN_FENG_DING := 10  # 体型上限封顶 10 级（与鱼种表最高级一致）
const SHUA_XIN_ZUI_DI_FENG_DING := 4  # 最低刷新等级封顶 4 级：后期 1~3 级彻底退场（2026-11-02 拍板）
const SHUA_XIN_MEI_DANG_SHI_JIAN := 20.0  # 每 20 秒刷新分布上一档（原 60 秒：升级太慢）
const ZUI_XIAO_JIAN_GE := 0.6  # 两条鱼之间的最短刷新间隔（秒）
const ZUI_DA_JIAN_GE := 1.8  # 最长刷新间隔（秒）
const LU_REN_JIAN_SHUAI := 0.8  # 每过一档，最低等级鱼占比 ×0.8
const LU_REN_ZUI_DI := 0.2  # 最低等级鱼占比下限：局末再凶，垫底档也得留口饭吃
const DA_YU_QUAN_ZHONG_ZHI_SHU := 2.0  # 非小孩鱼的权重 =（体型 / 当前上限）^2
const HUAN_FANG_HUAN_YING_XIAO_YU := 10  # 换房欢迎小鱼目标数量：淡入后立刻有食物/生态
const HUAN_FANG_AN_QUAN_JIAN_JU := 240.0  # 欢迎小鱼与玩家的最小距离：保证不贴脸
const HUAN_FANG_NEI_BIAN_JU := 40.0  # 欢迎小鱼落点距房间四边的最小边距
const HUAN_FANG_WAI_BIAN_JU := 60.0  # 安全入口 y 距房间上下边的最小边距
const HUAN_FANG_PAI_DUI_RONG_YU := 5  # 补屏去重余量：鱼数已接近上限就不再叠加
const HUI_SHOU_YU_LIANG_YU := 8.0  # 生成点距 NPC 回收线留下的安全余量（像素）
const HUAN_FANG_PIAN_YI: Array[Vector2] = [
	Vector2(-70.0, -50.0),
	Vector2(70.0, -50.0),
	Vector2(-70.0, 50.0),
	Vector2(70.0, 50.0),
]  # 欢迎小鱼在安全落点周围的 4 个确定性散开偏移（≤90px，按序号循环）

@export var zuida_shuliang := 35   # 同屏 NPC 鱼数量上限（v0.4 上调 20→35：密度与吞食机会↑；性能靠 0.3 秒思考节流扛）
@export var yu_zhong_zu: Array[YuZhong]  # 鱼种注册表：检查器拖入 .tres——加新鱼不改代码
@export var lu_ren_zhan_bi := 0.7  # 第 0 档的最低等级鱼（此时即 1 级小孩鱼）占比

var _dang := 0  # 已过档数：由账本局内时钟 ÷ 20 秒换算（纯函数只认这个数）
var shua_xin_ting_zhi := false  # 决战期停刷开关：机器船降临后置 true，只停新增/补鱼，不清存量 NPC（2026-11-02 拍板）
var ya_li_xiu_zheng := 0  # E 隐藏压力修正（-2~+2）：Main 开战前从存档写回；负值=对玩家更宽松
var _da_yu_ji_shi := 0.0  # A11 大体型专刷计时器
var _hu_chi_ji_shi := 0.0  # A14 NPC 互吃判定的全局节拍
var fang_jian_qu := Rect2(0.0, 0.0, 4128.0, 2304.0)  # 当前房间矩形：默认整图，Main 会收窄

@onready var dingshi: Timer = $Dingshi  # 定时器子节点（one_shot：每刷一条重新排程）


func _ready() -> void:
	dingshi.timeout.connect(_on_dingshi_timeout)
	_chong_tian_yu_qun.call_deferred()  # 开局先铺满一屏（不然前几秒全场空空）
	_kai_xia_yi_lun()


func _process(delta: float) -> void:
	# 只负责读档位：刷新分布随档位变化，节奏本身是持续的
	# 用账本时钟而不是自己累计：暂停、重开、终局都跟账本一致
	_dang = int(ZhangBen.ju_nei_shi_jian / SHUA_XIN_MEI_DANG_SHI_JIAN)
	# 停刷后连加压计时也清零：决战期不再加鱼（A11/A14 都属于「刷新期系统」）
	if shua_xin_ting_zhi:
		_da_yu_ji_shi = 0.0
		_hu_chi_ji_shi = 0.0
		return
	_geng_xin_da_yu(delta)  # A11 双重加压：第 4 分钟起单独刷大体型
	_geng_xin_hu_chi(delta)  # A14：每 20 秒一次全局 NPC 互吃判定


func _geng_xin_da_yu(delta: float) -> void:
	# A11：第 4 分钟起按线性收紧的间隔补一条大体型；船降临前一直生效
	if ZhangBen.ju_nei_shi_jian < da_yu_qi_dian():
		return
	_da_yu_ji_shi += delta
	var jian_ge := da_yu_jian_ge()
	var bao_xian := 0
	while _da_yu_ji_shi >= jian_ge and bao_xian < 8:
		_da_yu_ji_shi -= jian_ge
		_shengcheng_da_yu()
		bao_xian += 1
		if jian_ge <= 0.0:
			_da_yu_ji_shi = 0.0
			break


func da_yu_qi_dian() -> float:
	# 双重加压起点：E 正修正每档提前 30 秒（+1 → 210 秒，+2 → 180 秒）；
	# 负修正每档推迟 30 秒（-1 → 270 秒起，-2 → 300 秒起）
	return maxf(60.0, SHU_ZHI.DA_YU_JIA_YA_QI_DIAN - 30.0 * float(ya_li_xiu_zheng))


func da_yu_jian_ge() -> float:
	# A11 纯函数：25 秒线性收紧到 15 秒（到第 10 分钟）；
	# E 修正按档收紧/放宽 10%（+2 → ×0.8，-2 → ×1.2）
	var qi := da_yu_qi_dian()
	var zhong := SHU_ZHI.DA_YU_JIAN_GE_ZHONG_DIAN
	var bi := 0.0
	if zhong > qi:
		bi = clampf((ZhangBen.ju_nei_shi_jian - qi) / (zhong - qi), 0.0, 1.0)
	var jian_ge := lerpf(SHU_ZHI.DA_YU_JIAN_GE_QI_SHI, SHU_ZHI.DA_YU_JIAN_GE_MO, bi)
	return jian_ge * clampf(1.0 - 0.1 * float(ya_li_xiu_zheng), 0.8, 1.2)


func _geng_xin_hu_chi(delta: float) -> void:
	# A14：固定 20 秒节拍，和刷新档位脱钩（世界不围玩家转的支柱）
	_hu_chi_ji_shi += delta
	var bao_xian := 0
	while _hu_chi_ji_shi >= SHU_ZHI.NPC_HU_CHI_JIAN_GE and bao_xian < 4:
		_hu_chi_ji_shi -= SHU_ZHI.NPC_HU_CHI_JIAN_GE
		_hu_chi_ju_ding()
		bao_xian += 1


func shua_xin_shang_xian(dang: int) -> int:
	# 刷新体型上限 = 基础 2 + 档数，封顶 10（策划案 8.4）
	# 纯函数：不读时间、不碰节点，测试可喂任意档数
	return mini(SHUA_XIN_JI_CHU + maxi(dang, 0), SHUA_XIN_FENG_DING)


func shua_xin_zui_di(dang: int) -> int:
	# 刷新最小体型（最低等级）：每过 20 秒抬 1 级，封顶 4 级
	# 2026-11-02 拍板：小鱼渐渐不再出现，与「上限抬高」形成双重压迫
	return mini(1 + maxi(dang, 0), SHUA_XIN_ZUI_DI_FENG_DING)


func lu_ren_bi_li(dang: int) -> float:
	# 最低等级鱼占比：0.7 → 0.56 → 0.45 … 每档 ×0.8，掉到 0.2 就不再降
	return maxf(LU_REN_ZUI_DI, lu_ren_zhan_bi * pow(LU_REN_JIAN_SHUAI, float(maxi(dang, 0))))


func ti_xing_quan_zhong(deng_ji: int, shang_xian: int) -> float:
	# 非小孩鱼的权重：体型越大权重越高（平方）；上限每档涨 1，分母随之变大 → 分布整体右移
	# 用「占上限的比例」而不是绝对等级，鲸鲨 10 级在哪个档都是最稀少的那一档
	return pow(float(maxi(deng_ji, 1)) / float(maxi(shang_xian, 1)), DA_YU_QUAN_ZHONG_ZHI_SHU)


func deng_ji_gai_lv(dang: int) -> PackedFloat32Array:
	# 纯函数：某一档刷出各体型等级的概率表（下标 = 等级，0 位不用，总和 = 1）
	# 两条分支：最低等级按时间衰减占比；更高等级按权重分配
	# 2026-11-02：最低等级随档抬高（shua_xin_zui_di），低于下限的等级概率直接为 0
	var shang_xian := shua_xin_shang_xian(dang)
	var zui_di := shua_xin_zui_di(dang)
	var biao: PackedFloat32Array = []
	biao.resize(SHUA_XIN_FENG_DING + 1)  # 下标 0~10：等级 10 也要放得下
	var di_ji_bi := lu_ren_bi_li(dang)
	biao[zui_di] = di_ji_bi
	var zong := 0.0
	for d in range(zui_di + 1, shang_xian + 1):
		zong += ti_xing_quan_zhong(d, shang_xian)
	if zong <= 0.0:
		biao[zui_di] = 1.0  # 只剩最低一级可刷：全场都是这一级
		return biao
	for d in range(zui_di + 1, shang_xian + 1):
		biao[d] = (1.0 - di_ji_bi) * ti_xing_quan_zhong(d, shang_xian) / zong
	return biao


func ting_zhi_shua_xin() -> void:
	# 决战期停刷：只停后续刷新与补鱼；已经在场的鱼保持原样，继续游、继续被吃
	# 幂等：重复调用不会重置任何东西，也不会清空现有 NPC
	shua_xin_ting_zhi = true
	if is_instance_valid(dingshi):
		dingshi.stop()


func qie_huan_fang_jian(qu: Rect2) -> void:
	# 换房：更新房间、清掉旧房普通鱼、重置计时；Boss 不是 YuQun 子节点，不受影响
	fang_jian_qu = qu
	for zi in get_children():
		if zi is YuNpc and not zi.shi_boss:
			remove_child(zi)  # 先摘树：queue_free 本帧仍算在 get_children 里，先摘才能让补屏看到空房
			zi.queue_free()
	_da_yu_ji_shi = 0.0
	_hu_chi_ji_shi = 0.0
	if shua_xin_ting_zhi:
		return
	var wan_jia_wei := _zhao_wan_jia_wei()  # 换房前先记玩家位置：安全入口与欢迎小鱼都按它算
	_chong_tian_an_quan.call_deferred(wan_jia_wei)
	_kai_xia_yi_lun()  # Timer.start 会重排当前等待，不会叠出第二个刷新循环


func _zhao_wan_jia_wei() -> Vector2:
	# 玩家当前位置：换房补屏的安全距离都以它为基准；取不到就用房间中心兜底
	if is_inside_tree():
		var wan := get_tree().get_first_node_in_group("player") as Node2D
		if wan != null:
			return wan.global_position
	return fang_jian_qu.get_center()


func _wan_jia_ti_xing() -> float:
	# 玩家当前体型：欢迎小鱼与安全入口都按它判断“能不能一口吞”
	if is_inside_tree():
		var wan := get_tree().get_first_node_in_group("player")
		if wan != null:
			var ti = wan.get("tixing")  # 鸭子类型：测试夹具没有 tixing 时回退账本等级
			if ti != null:
				return float(ti)
	return maxf(1.0, float(ZhangBen.deng_ji + 1))


func ru_chang_xiao_yu_deng_ji(wan_jia_ti: float, zui_da := 3) -> int:
	# 换房欢迎小鱼等级：玩家可整吞（tixing >= 对方 × 1.1）且不超过 zui_da
	# 开局体型 1 时无鱼可吞，保底 1 级小鱼（至少不是贴脸大鱼）
	return clampi(int(floor(wan_jia_ti / 1.1)), 1, zui_da)


func an_quan_fang_nei_dian(qu: Rect2, wan_jia_wei: Vector2) -> Vector2:
	# 房内四个象限中心里离玩家最远的一个：欢迎小鱼落点，保证不贴脸
	# 1376×768 房间下，即使玩家在正中，最近象限中心也在约 394px 外
	var si_ge: Array[Vector2] = [
		Vector2(qu.position.x + qu.size.x * 0.25, qu.position.y + qu.size.y * 0.25),  # 左上
		Vector2(qu.position.x + qu.size.x * 0.75, qu.position.y + qu.size.y * 0.25),  # 右上
		Vector2(qu.position.x + qu.size.x * 0.25, qu.position.y + qu.size.y * 0.75),  # 左下
		Vector2(qu.position.x + qu.size.x * 0.75, qu.position.y + qu.size.y * 0.75),  # 右下
	]
	for i in si_ge.size():
		# 再夹进 40px 边距：任意房间尺寸下都保证落点在房内
		var dian := si_ge[i]
		dian.x = clampf(dian.x, qu.position.x + HUAN_FANG_NEI_BIAN_JU, qu.end.x - HUAN_FANG_NEI_BIAN_JU)
		dian.y = clampf(dian.y, qu.position.y + HUAN_FANG_NEI_BIAN_JU, qu.end.y - HUAN_FANG_NEI_BIAN_JU)
		si_ge[i] = dian
	var zui_yuan := si_ge[0]
	var zui_da := -1.0
	for dian in si_ge:
		var ju := dian.distance_squared_to(wan_jia_wei)
		if ju > zui_da:
			zui_da = ju
			zui_yuan = dian
	return zui_yuan


func an_quan_chu_kou(qu: Rect2, wan_jia_wei: Vector2, bianju: float = 80.0) -> Vector2:
	# 常规鱼安全入口：从玩家所在半场的对侧房间边缘外进入
	# 返回点 x 必在房外；y 取玩家 y 下方 180px，再夹到房内 60px 边距
	var zhong := qu.get_center()
	var y := clampf(wan_jia_wei.y + 180.0, qu.position.y + HUAN_FANG_WAI_BIAN_JU,
			qu.end.y - HUAN_FANG_WAI_BIAN_JU)
	if wan_jia_wei.x <= zhong.x:
		# 玩家在左半场（含正中）：从右边缘外进，水平距离 ≥ 半房宽 + bianju
		return Vector2(qu.end.x + bianju, y)
	# 玩家在右半场：从左边缘外进
	return Vector2(qu.position.x - bianju, y)


func _chong_tian_an_quan(wan_jia_wei: Vector2) -> void:
	# 换房黑场补屏：先放离玩家远的可吃小鱼，再从安全入口补常规鱼
	if shua_xin_ting_zhi:
		return
	var shang_xian := dang_qian_shang_xian()
	# 防重复：开局 YuQun._ready 已排了 _chong_tian_yu_qun，两个 deferred 不能叠加超上限
	if _dangqian_yu_shu() >= maxi(1, shang_xian - HUAN_FANG_PAI_DUI_RONG_YU):
		return
	var qu := fang_jian_qu
	var wan_jia_ti := _wan_jia_ti_xing()
	var xiao_yu_deng_ji := ru_chang_xiao_yu_deng_ji(wan_jia_ti)
	var luo_dian := an_quan_fang_nei_dian(qu, wan_jia_wei)
	var huan_ying_shu := mini(HUAN_FANG_HUAN_YING_XIAO_YU, shang_xian - _dangqian_yu_shu())
	for i in huan_ying_shu:
		var zhong: YuZhong = _chou_xiao_yu_zhong(xiao_yu_deng_ji)
		if zhong == null:
			break
		var dian := luo_dian + HUAN_FANG_PIAN_YI[i % HUAN_FANG_PIAN_YI.size()]
		if dian.distance_to(wan_jia_wei) < HUAN_FANG_AN_QUAN_JIAN_JU:
			# 离玩家太近：沿远离玩家的方向推回安全距离，再夹回房内 40px 边距
			var tui := dian - wan_jia_wei
			if tui.length_squared() < 0.001:
				tui = Vector2.RIGHT
			dian = wan_jia_wei + tui.normalized() * HUAN_FANG_AN_QUAN_JIAN_JU
		dian.x = clampf(dian.x, qu.position.x + HUAN_FANG_NEI_BIAN_JU, qu.end.x - HUAN_FANG_NEI_BIAN_JU)
		dian.y = clampf(dian.y, qu.position.y + HUAN_FANG_NEI_BIAN_JU, qu.end.y - HUAN_FANG_NEI_BIAN_JU)
		_fang_huan_ying_xiao_yu(zhong, dian, qu.get_center())
	var bao_xian := 0
	while _dangqian_yu_shu() < dang_qian_shang_xian() and bao_xian < 35:
		if not _shengcheng_yi_tiao(true):
			break
		bao_xian += 1


func _fang_huan_ying_xiao_yu(zhong: YuZhong, dian: Vector2, zhong_xin: Vector2) -> void:
	# 欢迎小鱼直接落在房内安全点：不进房外排队，淡入后立刻有食物/生态
	var xin_yu: YuNpc = YU_NPC_CHANGJING.instantiate()
	xin_yu.yu_zhong = zhong
	xin_yu.sudu = randf_range(zhong.sudu_fanwei.x, zhong.sudu_fanwei.y)
	xin_yu.position = dian
	xin_yu.fangxiang = 1.0 if dian.x <= zhong_xin.x else -1.0  # 朝房间中心游
	add_child(xin_yu)


func _on_dingshi_timeout() -> void:
	# 停刷后不再补鱼，也不重新排程：让定时器彻底安静下来
	if shua_xin_ting_zhi:
		return
	# 持续补充：没到上限就再刷一条；满了也照常等下一轮（鱼被吃掉后马上会有新的补进来）
	if _dangqian_yu_shu() < dang_qian_shang_xian():
		_shengcheng_yi_tiao()
	_kai_xia_yi_lun()


func _kai_xia_yi_lun() -> void:
	# 随机间隔：不给玩家“整点来一波”的机械感
	# E3：压力正修正把间隔收紧（+2 → ×0.8），负修正放宽（-2 → ×1.2）
	dingshi.start(randf_range(ZUI_XIAO_JIAN_GE, ZUI_DA_JIAN_GE) * shua_xin_jian_ge_bei())


func dang_qian_shang_xian() -> int:
	# E3：同屏数量也随压力微调（每档 ±5 条，保底 8 条）；0 压力时仍是 35
	return maxi(8, zuida_shuliang + 5 * ya_li_xiu_zheng)


func shua_xin_jian_ge_bei() -> float:
	# E3：普通刷新节奏倍率，0 压力恒为 1.0
	return clampf(1.0 - 0.1 * float(ya_li_xiu_zheng), 0.8, 1.2)


func _chong_tian_yu_qun() -> void:
	# 开局铺满一屏；中途不再整批补，改为定时器一条一条补
	# 停刷后连铺屏也跳过（正常流程不会走到，防御调用顺序异常）
	if shua_xin_ting_zhi:
		return
	var bao_xian := 0  # 防死循环：没有可刷鱼种时 _shengcheng_yi_tiao 返回 false 会 break
	while _dangqian_yu_shu() < zuida_shuliang and bao_xian < zuida_shuliang:
		if not _shengcheng_yi_tiao():
			break
		bao_xian += 1


func _dangqian_yu_shu() -> int:
	# 只数 YuNpc 子节点（Dingshi 也是子节点，不能直接用 get_child_count）
	var shu := 0
	for zi in get_children():
		if zi is YuNpc:
			shu += 1
	return shu


func _shengcheng_yi_tiao(an_quan := false) -> bool:
	# 生成一条鱼；没有符合当前刷新上限的鱼种时返回 false（调用方据此收手）
	# an_quan=true：换房补屏，不能整吞的鱼改走对侧安全入口
	# 停刷后这里是最后一道闸：任何调用路径都不会再新增鱼
	if shua_xin_ting_zhi:
		return false
	var zhong: YuZhong = _chou_yu_zhong()
	if zhong == null:
		return false
	_sheng_yu(zhong, an_quan)
	return true


func _shengcheng_da_yu() -> bool:
	# A11 专用路径：无视当前档位概率，直接抽一条「玩家等级 +2 以上」的大体型
	if shua_xin_ting_zhi or _dangqian_yu_shu() >= dang_qian_shang_xian():
		return false
	var zhong: YuZhong = _chou_da_yu_zhong()
	if zhong == null:
		return false
	_sheng_yu(zhong)
	return true


func huan_chong_hui_shou_xian(qu: Rect2) -> Vector2:
	# 普通补鱼可安全停留的 x 范围：NPC 在相机视野边 ±240px 外回收，这里内收 8px 留余量。
	# 相机被房间 limit 夹住后，视野边相对房边会内缩 0~96px；必须用真实视野而不是房边，
	# 否则从房外排队进场的鱼会一出生就落在回收线外、下一帧被删。
	# 无相机（测试/异常路径）按房边兜底，返回的仍是“房外 232px”的保守范围。
	if is_inside_tree():
		var jiao := get_viewport().get_camera_2d()
		if jiao != null:
			var ban := get_viewport_rect().size.x * 0.5
			var zhong := jiao.get_screen_center_position().x
			return Vector2(zhong - ban - YuNpc.SHOU_HUI_YU_LIANG + HUI_SHOU_YU_LIANG_YU,
					zhong + ban + YuNpc.SHOU_HUI_YU_LIANG - HUI_SHOU_YU_LIANG_YU)
	return Vector2(qu.position.x - YuNpc.SHOU_HUI_YU_LIANG + HUI_SHOU_YU_LIANG_YU,
			qu.end.x + YuNpc.SHOU_HUI_YU_LIANG - HUI_SHOU_YU_LIANG_YU)


func _sheng_yu(zhong: YuZhong, an_quan := false) -> void:
	# 生成一条指定鱼种的 NPC：普通刷新与大体型专刷共用
	var xin_yu: YuNpc = YU_NPC_CHANGJING.instantiate()
	xin_yu.yu_zhong = zhong  # 数据注入必须在 add_child 前：_ready 要读它
	xin_yu.sudu = randf_range(zhong.sudu_fanwei.x, zhong.sudu_fanwei.y)

	var qu := fang_jian_qu
	if an_quan and zhong.dengji >= int(floor(_wan_jia_ti_xing())):
		# 换房安全入口：不能整吞/同级或更大的鱼，从玩家所在半场的对侧房间边缘外进
		# 水平距离 ≥ 半房宽（1376 房间约 688px），玩家贴边时更大：不给大鱼贴脸机会
		var wan_jia_wei := _zhao_wan_jia_wei()
		xin_yu.position = an_quan_chu_kou(qu, wan_jia_wei, xin_yu.bianju)
		xin_yu.fangxiang = 1.0 if xin_yu.position.x <= qu.get_center().x else -1.0  # 左入口→1，右入口→-1
		add_child(xin_yu)  # 进树：触发 NPC 的 _ready
		return
	# 从当前房间左右两侧外进入：相机 limit 会裁掉房外部分，画面上仍是“从屏幕边游入”
	var gao := randf_range(qu.position.y + 60.0, qu.end.y - 60.0)  # 上下留 60 像素边距
	# 房外再退 0~160 像素增加纵深：一次补一屏鱼时不会全叠在同一条竖线上。
	# 纵深上限取“出生点到 NPC 回收线”的余量：相机靠房间一侧时视野内缩 96px，
	# 仍退满 160px 会让约六成新鱼在下一帧被 _process 回收；这里动态压上限并夹取。
	var hui_shou := huan_chong_hui_shou_xian(qu)
	var tui_shang := minf(160.0, maxf(0.0, minf(
			qu.position.x - xin_yu.bianju - hui_shou.x,
			hui_shou.y - qu.end.x - xin_yu.bianju)))
	var tui := randf_range(0.0, tui_shang)
	if randf() < 0.5:
		xin_yu.fangxiang = 1.0  # 从左边进，向右游
		xin_yu.position = Vector2(clampf(qu.position.x - xin_yu.bianju - tui, hui_shou.x, hui_shou.y), gao)
	else:
		xin_yu.fangxiang = -1.0  # 从右边进，向左游
		xin_yu.position = Vector2(clampf(qu.end.x + xin_yu.bianju + tui, hui_shou.x, hui_shou.y), gao)

	add_child(xin_yu)  # 进树：触发 NPC 的 _ready


func _chou_da_yu_zhong() -> YuZhong:
	# A11：从「≥ 玩家 +2 级」里按等级加权抽（越大越可能），体型不够时返回 null
	# A12 保护期同样约束大体型专刷：前 120 秒不刷 ≥ 玩家 +3 的大鱼（= 只能刷 +2）
	var zui_di := ZhangBen.deng_ji + SHU_ZHI.DA_YU_CHA_JI
	var zui_gao := SHUA_XIN_FENG_DING
	if ZhangBen.ju_nei_shi_jian < SHU_ZHI.BAO_HU_SHI_JIAN:
		zui_gao = ZhangBen.deng_ji + SHU_ZHI.BAO_HU_CHA_JI - 1
	var ke_xuan: Array[YuZhong] = []
	var zong := 0.0
	for z in yu_zhong_zu:
		if z == null or z.dengji < zui_di or z.dengji > zui_gao:
			continue
		ke_xuan.append(z)
		zong += float(z.dengji)
	if ke_xuan.is_empty() or zong <= 0.0:
		return null
	var dian := randf() * zong
	for z in ke_xuan:
		dian -= float(z.dengji)
		if dian <= 0.0:
			return z
	return ke_xuan.back()


func _hu_chi_ju_ding() -> void:
	# A14：全局扫一遍，每条鱼找「半径 140px 内、体型 ≥ 自己 1.1 倍」的最近目标，
	# 35% 概率直接吞掉（走 YuNpc._tun_diao：吃方拿隐藏经验，被吃方正常死亡/放毒）
	var yu_men: Array[YuNpc] = []
	for zi in get_children():
		if zi is YuNpc and not zi.si_le:
			yu_men.append(zi)
	for i in yu_men.size():
		var chi_zhe := yu_men[i]
		if chi_zhe.si_le:
			continue
		var zui_jin: YuNpc = null
		var zui_ju := SHU_ZHI.NPC_HU_CHI_BAN_JING
		for j in yu_men.size():
			if i == j:
				continue
			var mu := yu_men[j]
			if mu.si_le:
				continue
			if chi_zhe.tixing < mu.tixing * SHU_ZHI.TUN_CHI_BEI_LV:
				continue
			var ju := chi_zhe.global_position.distance_to(mu.global_position)
			if ju <= zui_ju:
				zui_ju = ju
				zui_jin = mu
		if zui_jin == null:
			continue
		if randf() >= SHU_ZHI.NPC_HU_CHI_GAI_LV:
			continue
		chi_zhe._tun_diao(zui_jin)


func _chou_xiao_yu_zhong(zui_gao_deng_ji: int) -> YuZhong:
	# 换房欢迎小鱼专用：只从 1..最高可吃等级里挑，优先最高级（同等级多条随机）
	var ke_xuan: Array[YuZhong] = []
	var zui_gao := 0
	for z in yu_zhong_zu:
		if z == null or z.dengji < 1 or z.dengji > zui_gao_deng_ji:
			continue
		if z.dengji > zui_gao:
			zui_gao = z.dengji
			ke_xuan.clear()
		if z.dengji == zui_gao:
			ke_xuan.append(z)
	if ke_xuan.is_empty():
		return null
	return ke_xuan[randi() % ke_xuan.size()]


func _chou_yu_zhong() -> YuZhong:
	# 按当前档位的概率表抽一条：同等级的鱼等分该等级的概率
	# 某等级暂时没有鱼种（比如 Lv.8/9 还没做）时，那份概率自动摊给其它等级，不会崩、不会刷空
	var shang_xian := shua_xin_shang_xian(_dang)
	var zui_di := shua_xin_zui_di(_dang)
	# A12 前 2 分钟保护：不刷 ≥ 玩家 +3 级的大体型（上限压到玩家 +2）
	if ZhangBen.ju_nei_shi_jian < SHU_ZHI.BAO_HU_SHI_JIAN:
		shang_xian = mini(shang_xian, ZhangBen.deng_ji + SHU_ZHI.BAO_HU_CHA_JI - 1)
	var biao := deng_ji_gai_lv(_dang)
	var mei_ji_shu := {}  # 等级 → 该等级有几条鱼
	for z in yu_zhong_zu:
		if z == null or z.dengji < zui_di or z.dengji > shang_xian:
			continue
		mei_ji_shu[z.dengji] = mei_ji_shu.get(z.dengji, 0) + 1
	if mei_ji_shu.is_empty():
		return null  # 数据表里没有够小的鱼：这一轮刷不出来
	var zong := 0.0
	for z in yu_zhong_zu:
		if z == null or z.dengji < zui_di or z.dengji > shang_xian:
			continue
		zong += biao[z.dengji] / float(mei_ji_shu[z.dengji])
	if zong <= 0.0:
		return null
	var dian := randf() * zong
	for z in yu_zhong_zu:
		if z == null or z.dengji < zui_di or z.dengji > shang_xian:
			continue
		dian -= biao[z.dengji] / float(mei_ji_shu[z.dengji])
		if dian <= 0.0:
			return z
	return null


func _shi_jiao_fan_wei() -> Rect2:
	# 相机在世界里的可视矩形；用 get_screen_center_position() 才能算上 limit 与平滑
	var pingmu := get_viewport_rect().size
	var shi_jiao := get_viewport().get_camera_2d()
	if shi_jiao != null:
		return Rect2(shi_jiao.get_screen_center_position() - pingmu * 0.5, pingmu)
	return Rect2(Vector2.ZERO, pingmu)
