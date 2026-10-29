extends Node
# 游戏账本（Autoload 全局单例）：经验、等级、当前体型的唯一所有者
# 先于一切场景就绪、切场景不销毁；任意脚本直接按名访问 ZhangBen
# 等级 = 体型上限（成长轴）；当前体型 = 血量（受伤扣、吃东西回），两者不是一回事

signal jing_yan_bian_hua(jing_yan: int, yuzhi: int)  # 经验变动：UI 刷新进度条
signal sheng_ji(xin_deng_ji: int)                    # 升级：玩家长大、弹窗弹卡
signal ti_xing_bian_hua(dang_qian: float, shang_xian: float)  # 当前体型（血量）变了：缩/胀、刷 UI
signal si_wang                                       # 当前体型（血量）归零：进结算
signal ka_yi_xuan(ka: QiangHuaKa)                    # 选卡完成：第 7 课强化系统连接生效

const KAI_JU_DENG_JI := 0    # 开局等级：从最底层的小鱼开始，先吃海草珊瑚再吃鱼
const TI_XING_XI_SHU := 0.32  # 体型→像素缩放系数（贴图基准高 100px，1 点体型≈32px）
const TI_XING_QU_XIAN := 0.7  # 体型→像素的曲线指数：等级无上限，线性增长会在高等级把鱼撑爆
const JI_CHU_TI_XING := 1.0   # Lv.0 的基础体型（血量）：没有它 0 级就没法玩了
const MEI_CI_SHANG_HAI := 1.0 # 每次受伤扣 1 点体型单位（= 1 级的分量）
const JI_E_SHANG_XIAN := 100.0   # 饥饿条上限：一条 100 点的条
const JI_E_XIA_JIANG_LV := 2.5  # 饥饿每秒下降：约 40 秒见底，逼玩家持续觅食
const JI_E_E_SI_KOU_XUE := 0.1  # 饥饿归零后每秒扣多少当前体型：Lv.0 约 10 秒死
var sheng_ji_biao := preload("res://data/shengji/sheng_ji_biao.tres")  # 升级曲线参数（改表零代码调曲线）

var jing_yan := 0  # 当前经验（本级的，升级时扣掉已用部分）
var deng_ji := KAI_JU_DENG_JI  # 当前等级 = 体型上限
var dang_qian_ti_xing := JI_CHU_TI_XING  # 当前体型 = 血量（0~上限，受伤扣，吃东西回）
var yi_xuan_ka: Array[QiangHuaKa] = []  # 本局已选强化卡（效果第 7 课生效）
var jing_yan_jia_cheng := 1.0  # 经验加成倍率（睿智卡生效；bei_chi 记账时乘算）
var ji_e := JI_E_SHANG_XIAN  # 当前饥饿：0~100，随时间下降，吃东西回
var sheng_cun_zhong := true  # 局内活着才掉饥饿：死亡后停止，重开复位
var _e_si_lei_ji := 0.0  # 饥饿归零后的计时器：攒满 1 秒扣一次体型


func _ready() -> void:
	# 账本挂 Autoload：升级三选一暂停时，饥饿也必须停——否则选卡期间玩家会被饿死
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _process(delta: float) -> void:
	# Autoload 自己走时钟：每帧只做“饥饿下降”这一件事，伤害仍统一走 shou_shang
	xia_jiang_ji_e(delta)


func ti_xing_shang_xian() -> float:
	# 体型上限：Lv.0 给 1 点基础体型，之后每级 +1（Lv.8 → 9 点）
	return float(deng_ji) + JI_CHU_TI_XING


func ti_xing_dao_chi_du(ti_xing_zhi: float) -> float:
	# 体型→像素的唯一换算入口：玩家与 NPC 共用，保证「看起来谁大」与判定一致
	# 指数 0.7 < 1：每升一级的视觉增量递减；Lv.0 仍约 32px，Lv.8 约 149px（线性会是 288px）
	return TI_XING_XI_SHU * pow(maxf(ti_xing_zhi, 0.0), TI_XING_QU_XIAN)


func she_jing_yan_jia_cheng(bei: float) -> void:
	# 睿智卡唯一入口：倍率的唯一所有者仍是账本（玩家不私自存倍率）
	jing_yan_jia_cheng = bei


func jia_jing_yan(fen: int) -> void:
	# 唯一记账入口：吃鱼/肉/植物的经验都从这进账
	# 等级无上限：经验够了就升，不再有封顶分支
	jing_yan += fen
	var yuzhi := dangqian_yuzhi()
	if jing_yan >= yuzhi:
		jing_yan -= yuzhi
		deng_ji += 1
		dang_qian_ti_xing = ti_xing_shang_xian()  # 升级回满血：新上限直接填满
		sheng_ji.emit(deng_ji)
		ti_xing_bian_hua.emit(dang_qian_ti_xing, ti_xing_shang_xian())
	jing_yan_bian_hua.emit(jing_yan, dangqian_yuzhi())


func dangqian_yuzhi() -> int:
	# 阈值 = 基础 × 增长率^等级（10 × 1.2^N），向上取整——曲线代替固定表，等级再高都算得出
	# 取整口径按策划案 8.6.1：ceil，避免阈值 0 时白送一级
	# 负等级只在测试里出现：按 Lv.0 算，避免 pow 出小数
	return ceili(sheng_ji_biao.ji_chu * pow(sheng_ji_biao.zeng_zhang, maxi(deng_ji, 0)))


func shou_shang(liang: float = MEI_CI_SHANG_HAI) -> void:
	# 受伤唯一入口：扣当前体型（血量），不碰等级上限
	# 体型越大血越厚——同样扣 1 点，Lv.0 一次见底，Lv.8 能扛九次
	if dang_qian_ti_xing <= 0.0:
		return  # 已死亡：不再重复扣、不重复播死亡
	dang_qian_ti_xing = maxf(0.0, dang_qian_ti_xing - liang)
	ti_xing_bian_hua.emit(dang_qian_ti_xing, ti_xing_shang_xian())
	if dang_qian_ti_xing <= 0.0:
		sheng_cun_zhong = false  # 先停饥饿时钟，再广播：si_wang 的接收者会切场景
		si_wang.emit()


func hui_ti_xing(liang: float) -> void:
	# 回血唯一入口：吃东西回体型，最多回到当前等级的上限
	var shang := ti_xing_shang_xian()
	if dang_qian_ti_xing >= shang:
		return  # 满血不再广播，避免白刷 UI
	dang_qian_ti_xing = minf(shang, dang_qian_ti_xing + liang)
	ti_xing_bian_hua.emit(dang_qian_ti_xing, shang)


func xia_jiang_ji_e(delta: float) -> void:
	# 饥饿唯一时钟：活着才走；有饥饿就扣饥饿，归零后每秒扣 0.1 当前体型
	# 拆成公开函数是为了可测：_process 只是调用者，测试可喂确定的 delta
	if not sheng_cun_zhong:
		return
	if ji_e > 0.0:
		ji_e = maxf(0.0, ji_e - JI_E_XIA_JIANG_LV * delta)
		return
	_e_si_lei_ji += delta
	while _e_si_lei_ji >= 1.0:
		_e_si_lei_ji -= 1.0
		shou_shang(JI_E_E_SI_KOU_XUE)  # 饿死走的仍是受伤通道：归零时账本广播 si_wang


func hui_ji_e(liang: float) -> void:
	# 吃东西回饥饿：封顶 100；死亡后不再回（已经进结算了）
	if not sheng_cun_zhong:
		return
	if ji_e >= JI_E_SHANG_XIAN:
		return
	ji_e = minf(JI_E_SHANG_XIAN, ji_e + liang)
	_e_si_lei_ji = 0.0  # 吃了东西就脱离饥饿：饿死计时重新从 0 攒，不留残数提前扣血


func chi_yu_hui_ji_e(dui_fang_ti_xing: int) -> float:
	# 吃鱼回多少饥饿：路人鱼（1 级）最顶饱，普通鱼 8，鲸鲨 30
	# 与 8.6.2 食物收益表一一对应；改数值只改这里
	if dui_fang_ti_xing >= 10:
		return 30.0
	if dui_fang_ti_xing <= 1:
		return 10.0
	return 8.0


func chong_zhi() -> void:
	# 局内状态归零唯一入口（重开时用）：账本是 Autoload 常驻——谁常驻谁负责自己的复位
	jing_yan = 0
	deng_ji = KAI_JU_DENG_JI
	dang_qian_ti_xing = JI_CHU_TI_XING
	yi_xuan_ka.clear()
	jing_yan_jia_cheng = 1.0
	ji_e = JI_E_SHANG_XIAN  # 饥饿回满
	_e_si_lei_ji = 0.0
	sheng_cun_zhong = true  # 重开复活：饥饿时钟重新走


func xuan_ka(ka: QiangHuaKa) -> void:
	# 选卡唯一入口：入账 + 广播（效果第 7 课在 ka_yi_xuan 回调里生效）
	yi_xuan_ka.append(ka)
	ka_yi_xuan.emit(ka)
