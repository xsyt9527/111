extends Node2D
class_name YuQun
# 鱼群生成器：持续刷新（不是每波来一批），刷新出来的鱼随局内时间越来越大（策划案 8.4 / 8.5）
# 开局：小孩鱼（1 级）为主，偶尔 2 级；每过 20 秒刷新档位 +1（原为每分钟：用户反馈升级太慢），
# 同时「小孩鱼」占比逐档下降——小鱼照样刷，只是越来越少，青少年 / 大鱼越来越多

const YU_NPC_CHANGJING := preload("res://scenes/YuNpc.tscn")  # NPC 鱼蓝图
const SHUA_XIN_JI_CHU := 2  # 第 0 档能刷到 2 级
const SHUA_XIN_FENG_DING := 10  # 体型上限封顶 10 级（与鱼种表最高级一致）
const SHUA_XIN_MEI_DANG_SHI_JIAN := 20.0  # 每 20 秒刷新分布上一档（原 60 秒：升级太慢）
const ZUI_XIAO_JIAN_GE := 0.6  # 两条鱼之间的最短刷新间隔（秒）
const ZUI_DA_JIAN_GE := 1.8  # 最长刷新间隔（秒）
const LU_REN_JIAN_SHUAI := 0.8  # 每过一档，小孩鱼占比 ×0.8
const LU_REN_ZUI_DI := 0.2  # 小孩鱼占比下限：局末再凶，也得留口饭吃
const DA_YU_QUAN_ZHONG_ZHI_SHU := 2.0  # 非小孩鱼的权重 =（体型 / 当前上限）^2

@export var zuida_shuliang := 20   # 同屏 NPC 鱼数量上限（策划案 8.6.4：同屏 20 条）
@export var yu_zhong_zu: Array[YuZhong]  # 鱼种注册表：检查器拖入 .tres——加新鱼不改代码
@export var lu_ren_zhan_bi := 0.7  # 第 0 档的小孩鱼（1 级）占比

var _dang := 0  # 已过档数：由账本局内时钟 ÷ 20 秒换算（纯函数只认这个数）

@onready var dingshi: Timer = $Dingshi  # 定时器子节点（one_shot：每刷一条重新排程）


func _ready() -> void:
	dingshi.timeout.connect(_on_dingshi_timeout)
	_chong_tian_yu_qun.call_deferred()  # 开局先铺满一屏（不然前几秒全场空空）
	_kai_xia_yi_lun()


func _process(_delta: float) -> void:
	# 只负责读档位：刷新分布随档位变化，节奏本身是持续的
	# 用账本时钟而不是自己累计：暂停、重开、终局都跟账本一致
	_dang = int(ZhangBen.ju_nei_shi_jian / SHUA_XIN_MEI_DANG_SHI_JIAN)


func shua_xin_shang_xian(dang: int) -> int:
	# 刷新体型上限 = 基础 2 + 档数，封顶 10（策划案 8.4）
	# 纯函数：不读时间、不碰节点，测试可喂任意档数
	return mini(SHUA_XIN_JI_CHU + maxi(dang, 0), SHUA_XIN_FENG_DING)


func lu_ren_bi_li(dang: int) -> float:
	# 小孩鱼占比：0.7 → 0.56 → 0.45 … 每档 ×0.8，掉到 0.2 就不再降
	return maxf(LU_REN_ZUI_DI, lu_ren_zhan_bi * pow(LU_REN_JIAN_SHUAI, float(maxi(dang, 0))))


func ti_xing_quan_zhong(deng_ji: int, shang_xian: int) -> float:
	# 非小孩鱼的权重：体型越大权重越高（平方）；上限每档涨 1，分母随之变大 → 分布整体右移
	# 用「占上限的比例」而不是绝对等级，鲸鲨 10 级在哪个档都是最稀少的那一档
	return pow(float(maxi(deng_ji, 1)) / float(maxi(shang_xian, 1)), DA_YU_QUAN_ZHONG_ZHI_SHU)


func deng_ji_gai_lv(dang: int) -> PackedFloat32Array:
	# 纯函数：某一档刷出各体型等级的概率表（下标 = 等级，0 位不用，总和 = 1）
	# 两条分支：小孩鱼（1 级）按时间衰减；其余等级按权重分配
	var shang_xian := shua_xin_shang_xian(dang)
	var biao: PackedFloat32Array = []
	biao.resize(SHUA_XIN_FENG_DING + 1)  # 下标 0~10：等级 10 也要放得下
	var xiao_hai := lu_ren_bi_li(dang)
	biao[1] = xiao_hai
	var zong := 0.0
	for d in range(2, shang_xian + 1):
		zong += ti_xing_quan_zhong(d, shang_xian)
	if zong <= 0.0:
		biao[1] = 1.0  # 上限只有 1 级：全场都是小孩鱼
		return biao
	for d in range(2, shang_xian + 1):
		biao[d] = (1.0 - xiao_hai) * ti_xing_quan_zhong(d, shang_xian) / zong
	return biao


func _on_dingshi_timeout() -> void:
	# 持续补充：没到上限就再刷一条；满了也照常等下一轮（鱼被吃掉后马上会有新的补进来）
	if _dangqian_yu_shu() < zuida_shuliang:
		_shengcheng_yi_tiao()
	_kai_xia_yi_lun()


func _kai_xia_yi_lun() -> void:
	# 随机间隔：不给玩家“整点来一波”的机械感
	dingshi.start(randf_range(ZUI_XIAO_JIAN_GE, ZUI_DA_JIAN_GE))


func _chong_tian_yu_qun() -> void:
	# 开局铺满一屏；中途不再整批补，改为定时器一条一条补
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
	var zhong: YuZhong = _chou_yu_zhong()
	if zhong == null:
		return false
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
	return true


func _chou_yu_zhong() -> YuZhong:
	# 按当前档位的概率表抽一条：同等级的鱼等分该等级的概率
	# 某等级暂时没有鱼种（比如 Lv.8/9 还没做）时，那份概率自动摊给其它等级，不会崩、不会刷空
	var shang_xian := shua_xin_shang_xian(_dang)
	var biao := deng_ji_gai_lv(_dang)
	var mei_ji_shu := {}  # 等级 → 该等级有几条鱼
	for z in yu_zhong_zu:
		if z == null or z.dengji < 1 or z.dengji > shang_xian:
			continue
		mei_ji_shu[z.dengji] = mei_ji_shu.get(z.dengji, 0) + 1
	if mei_ji_shu.is_empty():
		return null  # 数据表里没有够小的鱼：这一轮刷不出来
	var zong := 0.0
	for z in yu_zhong_zu:
		if z == null or z.dengji < 1 or z.dengji > shang_xian:
			continue
		zong += biao[z.dengji] / float(mei_ji_shu[z.dengji])
	if zong <= 0.0:
		return null
	var dian := randf() * zong
	for z in yu_zhong_zu:
		if z == null or z.dengji < 1 or z.dengji > shang_xian:
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
