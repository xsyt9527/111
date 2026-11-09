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

@export var zuida_shuliang := 35   # 同屏 NPC 鱼数量上限（v0.4 上调 20→35：密度与吞食机会↑；性能靠 0.3 秒思考节流扛）
@export var yu_zhong_zu: Array[YuZhong]  # 鱼种注册表：检查器拖入 .tres——加新鱼不改代码
@export var lu_ren_zhan_bi := 0.7  # 第 0 档的最低等级鱼（此时即 1 级小孩鱼）占比

var _dang := 0  # 已过档数：由账本局内时钟 ÷ 20 秒换算（纯函数只认这个数）
var shua_xin_ting_zhi := false  # 决战期停刷开关：机器船降临后置 true，只停新增/补鱼，不清存量 NPC（2026-11-02 拍板）
var ya_li_xiu_zheng := 0  # E 隐藏压力修正（-2~+2）：Main 开战前从存档写回；负值=对玩家更宽松
var _da_yu_ji_shi := 0.0  # A11 大体型专刷计时器
var _hu_chi_ji_shi := 0.0  # A14 NPC 互吃判定的全局节拍

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


func _shengcheng_yi_tiao() -> bool:
	# 生成一条鱼；没有符合当前刷新上限的鱼种时返回 false（调用方据此收手）
	# 停刷后这里是最后一道闸：任何调用路径都不会再新增鱼
	if shua_xin_ting_zhi:
		return false
	var zhong: YuZhong = _chou_yu_zhong()
	if zhong == null:
		return false
	_sheng_yu(zhong)
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


func _sheng_yu(zhong: YuZhong) -> void:
	# 生成一条指定鱼种的 NPC：普通刷新与大体型专刷共用
	var xin_yu: YuNpc = YU_NPC_CHANGJING.instantiate()
	xin_yu.yu_zhong = zhong  # 数据注入必须在 add_child 前：_ready 要读它
	xin_yu.sudu = randf_range(zhong.sudu_fanwei.x, zhong.sudu_fanwei.y)

	# 从当前镜头左右两侧外进入；有相机时按相机视野算，没有相机时退回视口
	var fan_wei := _shi_jiao_fan_wei()
	var gao := randf_range(fan_wei.position.y + 60.0, fan_wei.end.y - 60.0)  # 上下留 60 像素边距
	# 屏外再退 0~160 像素增加纵深：一次补一屏鱼时不会全叠在同一条竖线上
	# （NPC 的回收阈值是 bianju + SHOU_HUI_YU_LIANG，正好容得下这段排队距离）
	var tui := randf_range(0.0, 160.0)
	if randf() < 0.5:
		xin_yu.fangxiang = 1.0  # 从左边进，向右游
		xin_yu.position = Vector2(fan_wei.position.x - xin_yu.bianju - tui, gao)
	else:
		xin_yu.fangxiang = -1.0  # 从右边进，向左游
		xin_yu.position = Vector2(fan_wei.end.x + xin_yu.bianju + tui, gao)

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
