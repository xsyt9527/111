extends Node2D
class_name YuQun
# 鱼群生成器：持续刷新（不是每波来一批），刷新出来的鱼随局内时间越来越大（策划案 8.4 / 8.5）
# 开局：小孩鱼（1 级）为主，偶尔 2 级；每过 20 秒刷新档位 +1（原为每分钟：用户反馈升级太慢），
# 同时「最低等级鱼」占比逐档下降，且最低等级本身也逐档抬高（1→2→3→4 封顶，小鱼彻底退场）

const YU_NPC_CHANGJING := preload("res://scenes/YuNpc.tscn")  # NPC 鱼蓝图
const SHU_ZHI := preload("res://scripts/shu_zhi.gd")  # A 核心数值表
const SHENG_JI_BIAO := preload("res://data/shengji/sheng_ji_biao.tres")  # 隐藏成长升级曲线：与 YuNpc 同表
const SHUA_XIN_JI_CHU := 2  # 第 0 档能刷到 2 级
const SHUA_XIN_FENG_DING := 10  # 体型上限封顶 10 级（与鱼种表最高级一致）
const SHUA_XIN_ZUI_DI_FENG_DING := 4  # 最低刷新等级封顶 4 级：后期 1~3 级彻底退场（2026-11-02 拍板）
const SHUA_XIN_MEI_DANG_SHI_JIAN := 20.0  # 每 20 秒刷新分布上一档（原 60 秒：升级太慢）
const ZUI_XIAO_JIAN_GE := 0.6  # 两条鱼之间的最短刷新间隔（秒）
const ZUI_DA_JIAN_GE := 1.8  # 最长刷新间隔（秒）
const LU_REN_JIAN_SHUAI := 0.8  # 每过一档，最低等级鱼占比 ×0.8
const LU_REN_ZUI_DI := 0.2  # 最低等级鱼占比下限：局末再凶，垫底档也得留口饭吃
const DA_YU_QUAN_ZHONG_ZHI_SHU := 2.0  # 非小孩鱼的权重 =（体型 / 当前上限）^2
const FANG_JIAN_CHI_CUN := Vector2(1376.0, 768.0)  # 九宫格单格尺寸：记录坐标按它换算房号
const JIU_FANG_SHU := 9  # 3×3 房间总数
const FANG_JIAN_NEI_BIAN_JU := 40.0  # 记录初始落点与加载落点距房间四边的最小边距
const FANG_JIAN_WAI_BIAN_JU := 60.0  # 当前房实体允许越出房边的缓冲带（也用作出生带宽度）
const JIA_ZAI_AN_QUAN_JIAN_JU := 240.0  # 加载时与玩家的最小距离：避免换房贴脸
const XU_NI_YOU_DONG_JIAN_GE := 0.25  # 未加载房虚拟游动推进节拍（秒）
const DANG_WEI_TAO_TAI_BI_LI := 0.2  # 每档淘汰未加载房最小约 20%
const WEI_JIA_ZAI_BAO_DI_BI_LI := 0.6  # 未加载房数量保底 = 上限×0.6（最低 8）

@export var zuida_shuliang := 35   # 同屏 NPC 鱼数量上限（v0.4 上调 20→35：密度与吞食机会↑；性能靠 0.3 秒思考节流扛）
@export var yu_zhong_zu: Array[YuZhong]  # 鱼种注册表：检查器拖入 .tres——加新鱼不改代码
@export var lu_ren_zhan_bi := 0.7  # 第 0 档的最低等级鱼（此时即 1 级小孩鱼）占比

var _dang := 0  # 已过档数：由账本局内时钟 ÷ 20 秒换算（纯函数只认这个数）
var shua_xin_ting_zhi := false  # 决战期停刷开关：机器船降临后置 true，只停新增/补鱼，不清存量 NPC（2026-11-02 拍板）
var ya_li_xiu_zheng := 0  # E 隐藏压力修正（-2~+2）：Main 开战前从存档写回；负值=对玩家更宽松
var _da_yu_ji_shi := 0.0  # A11 大体型专刷计时器
var _hu_chi_ji_shi := 0.0  # A14 NPC 互吃判定的全局节拍
var fang_jian_qu := Rect2(0.0, 0.0, 4128.0, 2304.0)  # 当前房间矩形：默认整图，Main 会收窄
var _fang_jian_yu_qun: Array = []  # 九房鱼群记录：每房一个 Dictionary 数组；未加载房只有记录、不建节点
var _dang_qian_fang_jian := -1  # 当前房号 0..8；-1 表示还没接管过任何房间
var _xu_ni_you_dong_ji_shi := 0.0  # 未加载房虚拟游动累计（每 0.25 秒推进一拍）

@onready var dingshi: Timer = $Dingshi  # 定时器子节点（one_shot：每刷一条重新排程）


func _ready() -> void:
	dingshi.timeout.connect(_on_dingshi_timeout)
	# 九房记录要等 Main 注入压力修正后，由首次 qie_huan_fang_jian 惰性初始化；
	# 这里只排第一轮补鱼，不再 deferred 铺屏（开局与换房共用同一套记录加载）
	_kai_xia_yi_lun()


func _process(delta: float) -> void:
	# 只负责读档位：刷新分布随档位变化，节奏本身是持续的
	# 用账本时钟而不是自己累计：暂停、重开、终局都跟账本一致
	var shang_yi_dang := _dang
	_dang = int(ZhangBen.ju_nei_shi_jian / SHUA_XIN_MEI_DANG_SHI_JIAN)
	# 九房尚未初始化（裸 YuQun 测试夹具）：只更新档位，保持旧的纯函数行为
	if _fang_jian_yu_qun.is_empty():
		if shua_xin_ting_zhi:
			_da_yu_ji_shi = 0.0
			_hu_chi_ji_shi = 0.0
			return
		_geng_xin_da_yu(delta)
		_geng_xin_hu_chi(delta)
		return
	# 记录是唯一权威：先把当前房实体状态回写，再处理其它房；停刷也要先同步再冻结
	_jia_zhu_dang_qian_fang_jian()
	_tong_bu_dang_qian_fang_jian()
	# 停刷后连加压计时也清零：决战期不再加鱼（A11/A14 都属于「刷新期系统」）
	if shua_xin_ting_zhi:
		_da_yu_ji_shi = 0.0
		_hu_chi_ji_shi = 0.0
		return
	# 档位提升：未加载房淘汰最小的约 20%，并从房边补同数量当前档新鱼
	if _dang > shang_yi_dang:
		_dang_ti_tao_tai_he_bu_di()
	_xu_ni_you_dong(delta)  # 未加载房后台虚拟游动（0.25 秒一拍）
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
		_xu_ni_hu_chi(SHU_ZHI.NPC_HU_CHI_GAI_LV)  # 同一拍处理 8 个未加载房
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


func qie_huan_fang_jian(qu: Rect2, pian: int = -1) -> void:
	# 换房：保存并释放旧房实体 → 更新房间 → 按目标房记录加载；不再清场后整批补满
	var mu_biao := pian if pian >= 0 else qu_pian(qu)
	mu_biao = clampi(mu_biao, 0, JIU_FANG_SHU - 1)
	if _fang_jian_yu_qun.is_empty():
		_chu_shi_hua_jiu_fang()
	_bao_cun_dang_qian_fang_jian()
	fang_jian_qu = fang_jian_qu_an(mu_biao)
	_dang_qian_fang_jian = mu_biao
	_da_yu_ji_shi = 0.0
	# 全局 20 秒互吃节拍跨房连续：这里不重置 _hu_chi_ji_shi
	if shua_xin_ting_zhi:
		return
	var wan_jia_wei := _zhao_wan_jia_wei()
	_jia_zai_fang_jian(mu_biao, wan_jia_wei)
	_kai_xia_yi_lun()  # Timer.start 会重排当前等待，不会叠出第二个刷新循环


func qu_pian(qu: Rect2) -> int:
	# 房间矩形 → 房号 0..8：与 Main 的行优先规则一致，越界夹到边缘格
	var ge_x := clampi(int(floor(qu.position.x / FANG_JIAN_CHI_CUN.x)), 0, 2)
	var ge_y := clampi(int(floor(qu.position.y / FANG_JIAN_CHI_CUN.y)), 0, 2)
	return ge_y * 3 + ge_x


func fang_jian_qu_an(pian: int) -> Rect2:
	# 第 pian 格的房间矩形：不依赖 Main，测试与后台模拟可直接用
	var p := clampi(pian, 0, JIU_FANG_SHU - 1)
	var ge_x := p % 3
	var ge_y := int(floor(float(p) / 3.0))
	return Rect2(Vector2(ge_x * FANG_JIAN_CHI_CUN.x, ge_y * FANG_JIAN_CHI_CUN.y), FANG_JIAN_CHI_CUN)


func fang_jian_ji_lu(pian: int) -> Array:
	# 雷达只读接口：直接返回该房内部记录数组（调用方约定不修改、不保存引用）
	var p := clampi(pian, 0, JIU_FANG_SHU - 1)
	if _fang_jian_yu_qun.is_empty():
		return []
	return _fang_jian_yu_qun[p]


func _chu_shi_hua_jiu_fang() -> void:
	# 首次惰性初始化：9 个房间各预置固定数量记录；只有记录，不建节点
	# 此时 Main 已写入 ya_li_xiu_zheng，dang_qian_shang_xian() 是最终数量
	if not _fang_jian_yu_qun.is_empty():
		return
	var shang_xian := dang_qian_shang_xian()
	_fang_jian_yu_qun.clear()
	for pian in range(JIU_FANG_SHU):
		var ji_lu: Array = []
		var qu := fang_jian_qu_an(pian)
		for i in range(shang_xian):
			var zhong: YuZhong = _chou_yu_zhong()
			if zhong == null:
				break
			var wei := _sui_ji_fang_nei_dian(qu)
			var fang := 1.0 if randf() < 0.5 else -1.0
			var su := randf_range(zhong.sudu_fanwei.x, zhong.sudu_fanwei.y)
			ji_lu.append(_xin_ji_lu(zhong, wei, fang, su))
		_fang_jian_yu_qun.append(ji_lu)


func _xin_ji_lu(zhong: YuZhong, wei: Vector2, fang: float, su: float) -> Dictionary:
	# 一条鱼记录：未加载房只有这份数据；加载成实体后 node 指回实例
	return {
		"zhong": zhong,
		"wei": wei,
		"fang": fang,
		"su": su,
		"ti": float(zhong.dengji),
		"nei_deng": zhong.dengji,
		"nei_jing_yan": 0,
		"node": null,
	}


func _sui_ji_fang_nei_dian(qu: Rect2) -> Vector2:
	# 房内随机落点：四边各留 40px，避免记录一出生就贴在边界上
	return Vector2(
		randf_range(qu.position.x + FANG_JIAN_NEI_BIAN_JU, qu.end.x - FANG_JIAN_NEI_BIAN_JU),
		randf_range(qu.position.y + FANG_JIAN_NEI_BIAN_JU, qu.end.y - FANG_JIAN_NEI_BIAN_JU))


func _jia_dao_fang_nei(wei: Vector2, pian: int) -> Vector2:
	# 把坐标夹回指定房间的 40px 边距内：记录与加载落点共用
	var qu := fang_jian_qu_an(pian)
	return Vector2(
		clampf(wei.x, qu.position.x + FANG_JIAN_NEI_BIAN_JU, qu.end.x - FANG_JIAN_NEI_BIAN_JU),
		clampf(wei.y, qu.position.y + FANG_JIAN_NEI_BIAN_JU, qu.end.y - FANG_JIAN_NEI_BIAN_JU))


func _zhao_wan_jia_wei() -> Vector2:
	# 玩家当前位置：加载时按它做贴脸保护；取不到返回 INF 哨兵，加载时跳过贴脸推挤
	# （不用房间中心兜底：测试夹具在树外调用时不该被“假玩家”推得满屋跑）
	if is_inside_tree():
		var wan := get_tree().get_first_node_in_group("player") as Node2D
		if wan != null:
			return wan.global_position
	return Vector2(INF, INF)


func _bao_cun_dang_qian_fang_jian() -> void:
	# 换房保存：实体状态回写记录 → 释放实体；记录保留，下次进房按它恢复
	if _dang_qian_fang_jian < 0 or _fang_jian_yu_qun.is_empty():
		return
	var ji_lu: Array = _fang_jian_yu_qun[_dang_qian_fang_jian]
	# 1) 回写；死鱼/失效节点直接从记录删除
	for i in range(ji_lu.size() - 1, -1, -1):
		var rec: Dictionary = ji_lu[i]
		var yu = rec.get("node")
		if yu == null:
			continue  # 未加载记录（例如停刷期换房）：原样保留，不能当死鱼删掉
		if not is_instance_valid(yu) or yu.si_le:
			ji_lu.remove_at(i)
			continue
		rec["wei"] = _jia_dao_fang_nei(yu.position, _dang_qian_fang_jian)
		rec["ti"] = yu.tixing
		rec["nei_deng"] = yu.deng_ji_nei
		rec["nei_jing_yan"] = yu.jing_yan_nei
		rec["su"] = yu.sudu
		rec["fang"] = yu.fangxiang
	# 2) 释放本条房的实体，记录里的引用清空
	for rec in ji_lu:
		var yu = rec.get("node")
		if yu != null and is_instance_valid(yu):
			if yu.get_parent() == self:
				remove_child(yu)
			yu.queue_free()
		rec["node"] = null
	# 3) 对账清理：只遍历 YuQun 直接子节点，绝不按 yu_npc 组全表清理
	#    Main 下的鲸鲨 Boss 与教学脚本预排布鱼不是 YuQun 子节点，不能被换房误杀
	for zi in get_children():
		if zi is YuNpc and not zi.shi_boss:
			remove_child(zi)
			zi.queue_free()


func _jia_zai_fang_jian(pian: int, wan_jia_wei: Vector2) -> void:
	# 按记录加载目标房：恢复鱼种/速度/朝向/体型/隐藏成长；离玩家 <240px 的沿远离方向推开
	var ji_lu: Array = _fang_jian_yu_qun[pian]
	for rec in ji_lu:
		var zhong = rec.get("zhong")
		if zhong == null:
			continue
		var xin_yu: YuNpc = YU_NPC_CHANGJING.instantiate()
		xin_yu.yu_zhong = zhong
		xin_yu.sudu = float(rec.get("su", 100.0))
		xin_yu.fangxiang = float(rec.get("fang", -1.0))
		var luo_dian: Vector2 = _jia_dao_fang_nei(rec.get("wei", fang_jian_qu.get_center()), pian)
		luo_dian = _an_quan_jia_zai_dian(pian, luo_dian, wan_jia_wei)
		xin_yu.position = luo_dian
		# 恢复载荷必须在 add_child 前写入：_ready 末尾会覆盖默认的体型/隐藏成长
		xin_yu.zai_ru_ti_xing(float(rec.get("ti", 1.0)),
				int(rec.get("nei_deng", 1)), int(rec.get("nei_jing_yan", 0)))
		xin_yu.you_yu_qun_guan_li = true
		add_child(xin_yu)
		rec["node"] = xin_yu
		rec["wei"] = luo_dian


func _an_quan_jia_zai_dian(pian: int, luo_dian: Vector2, wan_jia_wei: Vector2) -> Vector2:
	# 贴脸保护：先沿远离玩家方向推到 240px；被房边夹回来后仍不够远，就退到最远象限中心
	if not (is_finite(wan_jia_wei.x) and is_finite(wan_jia_wei.y)):
		return luo_dian  # 取不到玩家（树外夹具）：不做推挤
	if luo_dian.distance_to(wan_jia_wei) >= JIA_ZAI_AN_QUAN_JIAN_JU:
		return luo_dian
	var tui := luo_dian - wan_jia_wei
	if tui.length_squared() < 0.001:
		tui = Vector2.RIGHT
	var dian := _jia_dao_fang_nei(wan_jia_wei + tui.normalized() * JIA_ZAI_AN_QUAN_JIAN_JU, pian)
	if dian.distance_to(wan_jia_wei) >= JIA_ZAI_AN_QUAN_JIAN_JU:
		return dian
	# 房角兜底：1376×768 下任意玩家位置到最远象限中心都 ≥240px
	var qu := fang_jian_qu_an(pian)
	var si_ge: Array[Vector2] = [
		Vector2(qu.position.x + qu.size.x * 0.25, qu.position.y + qu.size.y * 0.25),
		Vector2(qu.position.x + qu.size.x * 0.75, qu.position.y + qu.size.y * 0.25),
		Vector2(qu.position.x + qu.size.x * 0.25, qu.position.y + qu.size.y * 0.75),
		Vector2(qu.position.x + qu.size.x * 0.75, qu.position.y + qu.size.y * 0.75),
	]
	var zui_yuan := si_ge[0]
	var zui_da := -1.0
	for ge in si_ge:
		var dian_ge := _jia_dao_fang_nei(ge, pian)
		var ju := dian_ge.distance_squared_to(wan_jia_wei)
		if ju > zui_da:
			zui_da = ju
			zui_yuan = dian_ge
	return zui_yuan


func _jia_zhu_dang_qian_fang_jian() -> void:
	# 托管鱼不再被相机出屏回收；改为夹在房间外扩 60px 的缓冲带内，越界当帧夹回并翻转
	if _dang_qian_fang_jian < 0 or _fang_jian_yu_qun.is_empty():
		return
	var bian := fang_jian_qu.grow(FANG_JIAN_WAI_BIAN_JU)
	for rec in _fang_jian_yu_qun[_dang_qian_fang_jian]:
		var yu = rec.get("node")
		if yu == null or not is_instance_valid(yu) or yu.si_le:
			continue
		var wei: Vector2 = yu.position
		if wei.x < bian.position.x:
			wei.x = bian.position.x
			yu.fangxiang = 1.0
		elif wei.x > bian.end.x:
			wei.x = bian.end.x
			yu.fangxiang = -1.0
		if wei.y < bian.position.y:
			wei.y = bian.position.y
		elif wei.y > bian.end.y:
			wei.y = bian.end.y
		if wei != yu.position:
			yu.position = wei


func _tong_bu_dang_qian_fang_jian() -> void:
	# 记录唯一权威：当前房实体每帧回写记录；被吃/失效实体直接删除记录
	if _dang_qian_fang_jian < 0 or _fang_jian_yu_qun.is_empty():
		return
	var ji_lu: Array = _fang_jian_yu_qun[_dang_qian_fang_jian]
	for i in range(ji_lu.size() - 1, -1, -1):
		var rec: Dictionary = ji_lu[i]
		var yu = rec.get("node")
		if yu == null:
			continue  # 停刷期换房只换房号不加载：记录保留，等下次加载
		if not is_instance_valid(yu) or yu.si_le:
			ji_lu.remove_at(i)
			continue
		rec["wei"] = yu.position
		rec["ti"] = yu.tixing
		rec["nei_deng"] = yu.deng_ji_nei
		rec["nei_jing_yan"] = yu.jing_yan_nei
		rec["su"] = yu.sudu
		rec["fang"] = yu.fangxiang


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
	# 生成一条指定鱼种的 NPC：普通刷新与大体型专刷共用；生成后统一登记到当前房记录
	var xin_yu: YuNpc = YU_NPC_CHANGJING.instantiate()
	xin_yu.yu_zhong = zhong  # 数据注入必须在 add_child 前：_ready 要读它
	xin_yu.sudu = randf_range(zhong.sudu_fanwei.x, zhong.sudu_fanwei.y)
	var qu := fang_jian_qu
	# 出生带：房间左右边缘外 0~60px；相机 limit 裁掉房外部分，画面上仍是“从屏幕边游入”
	var gao := randf_range(qu.position.y + FANG_JIAN_WAI_BIAN_JU, qu.end.y - FANG_JIAN_WAI_BIAN_JU)
	var tui := randf_range(0.0, FANG_JIAN_WAI_BIAN_JU)
	if randf() < 0.5:
		xin_yu.fangxiang = 1.0  # 从左边进，向右游
		xin_yu.position = Vector2(qu.position.x - tui, gao)
	else:
		xin_yu.fangxiang = -1.0  # 从右边进，向左游
		xin_yu.position = Vector2(qu.end.x + tui, gao)
	xin_yu.you_yu_qun_guan_li = true  # 由鱼群按房间边界管理，关闭相机出屏回收
	add_child(xin_yu)  # 进树：触发 NPC 的 _ready
	# 统一登记记录：Dingshi 补鱼、A11 专刷都必须走这里，禁止绕过
	if _fang_jian_yu_qun.is_empty() or _dang_qian_fang_jian < 0:
		return
	var rec := _xin_ji_lu(zhong, xin_yu.position, xin_yu.fangxiang, xin_yu.sudu)
	rec["node"] = xin_yu
	_fang_jian_yu_qun[_dang_qian_fang_jian].append(rec)


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
		var zui_xiao: YuNpc = null
		var zui_ti := INF
		var zui_ju := INF
		for j in yu_men.size():
			if i == j:
				continue
			var mu := yu_men[j]
			if mu.si_le:
				continue
			if chi_zhe.tixing < mu.tixing * SHU_ZHI.TUN_CHI_BEI_LV:
				continue
			var ju := chi_zhe.global_position.distance_to(mu.global_position)
			if ju > SHU_ZHI.NPC_HU_CHI_BAN_JING:
				continue
			# 体型最小优先、距离次之：留下来的小鱼先被吃掉，不占场景（与未加载房同口径）
			if mu.tixing < zui_ti - 0.0001:
				zui_ti = mu.tixing
				zui_ju = ju
				zui_xiao = mu
			elif absf(mu.tixing - zui_ti) <= 0.0001 and ju < zui_ju:
				zui_ju = ju
				zui_xiao = mu
		if zui_xiao == null:
			continue
		if randf() >= SHU_ZHI.NPC_HU_CHI_GAI_LV:
			continue
		chi_zhe._tun_diao(zui_xiao)


func _xu_ni_you_dong(delta: float) -> void:
	# 未加载房轻量模拟：0.25 秒推进一拍；只改记录字典，不实例化任何节点
	_xu_ni_you_dong_ji_shi += delta
	var bao_xian := 0
	while _xu_ni_you_dong_ji_shi >= XU_NI_YOU_DONG_JIAN_GE and bao_xian < 8:
		_xu_ni_you_dong_ji_shi -= XU_NI_YOU_DONG_JIAN_GE
		_xu_ni_you_dong_yi_pai(XU_NI_YOU_DONG_JIAN_GE)
		bao_xian += 1


func _xu_ni_you_dong_yi_pai(bu_chang: float) -> void:
	if _fang_jian_yu_qun.is_empty():
		return
	for pian in range(JIU_FANG_SHU):
		if pian == _dang_qian_fang_jian:
			continue  # 当前房由实体 AI 自己游
		var ji_lu: Array = _fang_jian_yu_qun[pian]
		var qu := fang_jian_qu_an(pian)
		var nei := qu.grow(-FANG_JIAN_NEI_BIAN_JU)
		for i in range(ji_lu.size()):
			var rec: Dictionary = ji_lu[i]
			var wei: Vector2 = rec.get("wei", qu.get_center())
			var fang: float = float(rec.get("fang", -1.0))
			var su: float = float(rec.get("su", 100.0))
			var mu_biao = _xu_ni_zhao_xiao_yu(ji_lu, i)
			if mu_biao != null:
				# 感知范围内有更小的鱼：朝它靠近（保持“大鱼吃小鱼”的生态感）
				var cha: Vector2 = mu_biao.get("wei", wei) - wei
				if cha.length_squared() > 0.001:
					wei += cha.normalized() * su * bu_chang
					fang = 1.0 if cha.x >= 0.0 else -1.0
			else:
				wei.x += fang * su * bu_chang
			# 碰房边反弹：记录始终留在房内 40px 边距
			if wei.x < nei.position.x:
				wei.x = nei.position.x
				fang = 1.0
			elif wei.x > nei.end.x:
				wei.x = nei.end.x
				fang = -1.0
			wei.y = clampf(wei.y, nei.position.y, nei.end.y)
			rec["wei"] = wei
			rec["fang"] = fang


func _xu_ni_zhao_xiao_yu(ji_lu: Array, zi_index: int):
	# 在感知半径内找“最近的更小鱼”；没找到返回 null
	var rec: Dictionary = ji_lu[zi_index]
	var zi_ti := float(rec.get("ti", 1.0))
	var gan := maxf(80.0, zi_ti * SHU_ZHI.NPC_GAN_ZHI_MEI_TI)
	var zui_jin: Dictionary = {}
	var zui_ju := gan
	for j in range(ji_lu.size()):
		if j == zi_index:
			continue
		var mu: Dictionary = ji_lu[j]
		if float(mu.get("ti", 1.0)) >= zi_ti:
			continue  # 只追更小的
		var ju: float = (mu.get("wei", Vector2.ZERO) as Vector2).distance_to(rec.get("wei", Vector2.ZERO))
		if ju <= zui_ju:
			zui_ju = ju
			zui_jin = mu
	return zui_jin if not zui_jin.is_empty() else null


func _xu_ni_hu_chi(gai_lv := -1.0) -> void:
	# 未加载房虚拟互吃：同房 140px、体型 ≥ 对方 ×1.1、35% 概率；优先吃最小的
	if _fang_jian_yu_qun.is_empty():
		return
	if gai_lv < 0.0:
		gai_lv = SHU_ZHI.NPC_HU_CHI_GAI_LV
	for pian in range(JIU_FANG_SHU):
		if pian == _dang_qian_fang_jian:
			continue
		var ji_lu: Array = _fang_jian_yu_qun[pian]
		var i := 0
		while i < ji_lu.size():
			var chi: Dictionary = ji_lu[i]
			var zui_xiao_idx := -1
			var zui_ti := INF
			var zui_ju := INF
			for j in range(ji_lu.size()):
				if j == i:
					continue
				var mu: Dictionary = ji_lu[j]
				if float(chi.get("ti", 1.0)) < float(mu.get("ti", 1.0)) * SHU_ZHI.TUN_CHI_BEI_LV:
					continue
				var ju: float = (mu.get("wei", Vector2.ZERO) as Vector2).distance_to(
						chi.get("wei", Vector2.ZERO))
				if ju > SHU_ZHI.NPC_HU_CHI_BAN_JING:
					continue
				# 体型最小优先、距离次之：小鱼先被吃掉，不占场景
				if float(mu.get("ti", 1.0)) < zui_ti - 0.0001:
					zui_ti = float(mu.get("ti", 1.0))
					zui_ju = ju
					zui_xiao_idx = j
				elif absf(float(mu.get("ti", 1.0)) - zui_ti) <= 0.0001 and ju < zui_ju:
					zui_ju = ju
					zui_xiao_idx = j
			if zui_xiao_idx >= 0 and randf() < gai_lv:
				_xu_ni_chi_diao(chi, ji_lu[zui_xiao_idx])
				ji_lu.remove_at(zui_xiao_idx)
				if zui_xiao_idx < i:
					i -= 1  # 被吃的是前面的记录：游标回退一格
			i += 1


func _xu_ni_chi_diao(chi: Dictionary, mu: Dictionary) -> void:
	# 虚拟吃：吃方按被吃方鱼种分值加隐藏经验，按同一张升级表可能连升体型
	var zhong = mu.get("zhong")
	if zhong != null:
		chi["nei_jing_yan"] = int(chi.get("nei_jing_yan", 0)) + int(zhong.fenzhi)
	while int(chi.get("nei_jing_yan", 0)) >= _sheng_ji_yu_zhi_nei(int(chi.get("nei_deng", 1))):
		var yu_zhi := _sheng_ji_yu_zhi_nei(int(chi.get("nei_deng", 1)))
		chi["nei_jing_yan"] = int(chi.get("nei_jing_yan", 0)) - yu_zhi
		chi["nei_deng"] = int(chi.get("nei_deng", 1)) + 1
		chi["ti"] = float(chi.get("ti", 1.0)) + 1.0


func _sheng_ji_yu_zhi_nei(nei_deng: int) -> int:
	# 与 YuNpc._sheng_ji_yu_zhi 同表同公式：虚拟成长与实体成长不出现两套曲线
	return ceili(SHENG_JI_BIAO.ji_chu * pow(SHENG_JI_BIAO.zeng_zhang, maxi(nei_deng, 0)))


func _dang_ti_tao_tai_he_bu_di() -> void:
	# 每档：未加载房淘汰最小的约 20%，补同数量当前档新鱼；再按 60% 保底补齐，防止灭绝
	if _fang_jian_yu_qun.is_empty():
		return
	var bao_di := maxi(8, int(float(dang_qian_shang_xian()) * WEI_JIA_ZAI_BAO_DI_BI_LI))
	for pian in range(JIU_FANG_SHU):
		if pian == _dang_qian_fang_jian:
			continue  # 当前房走 Dingshi 节奏，不在这里整批换
		var ji_lu: Array = _fang_jian_yu_qun[pian]
		var tao := 0
		if not ji_lu.is_empty():
			tao = maxi(1, int(floor(float(ji_lu.size()) * DANG_WEI_TAO_TAI_BI_LI)))
			var pai: Array[int] = []
			for idx in range(ji_lu.size()):
				pai.append(idx)
			pai.sort_custom(func(a, b): return float(ji_lu[a]["ti"]) < float(ji_lu[b]["ti"]))
			var shan := {}
			for k in range(tao):
				shan[pai[k]] = true
			var xin: Array = []
			for idx in range(ji_lu.size()):
				if not shan.has(idx):
					xin.append(ji_lu[idx])
			_fang_jian_yu_qun[pian] = xin
			ji_lu = xin
		for k in range(tao):
			_tian_ji_lu_dang_qian(pian)
		while ji_lu.size() < bao_di:
			if not _tian_ji_lu_dang_qian(pian):
				break  # 没有可刷鱼种：停止补齐，等下个档位再试


func _tian_ji_lu_dang_qian(pian: int) -> bool:
	# 从房边补一条当前档新记录：左/右边缘内 40px，朝向房内
	var zhong: YuZhong = _chou_yu_zhong()
	if zhong == null:
		return false
	var qu := fang_jian_qu_an(pian)
	var x := qu.position.x + FANG_JIAN_NEI_BIAN_JU
	if randf() < 0.5:
		x = qu.end.x - FANG_JIAN_NEI_BIAN_JU
	var y := randf_range(qu.position.y + FANG_JIAN_NEI_BIAN_JU, qu.end.y - FANG_JIAN_NEI_BIAN_JU)
	var fang := 1.0 if x <= qu.get_center().x else -1.0
	var su := randf_range(zhong.sudu_fanwei.x, zhong.sudu_fanwei.y)
	_fang_jian_yu_qun[pian].append(_xin_ji_lu(zhong, Vector2(x, y), fang, su))
	return true


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
