extends Node
# 游戏账本（Autoload 全局单例）：经验、等级、当前体型的唯一所有者
# 先于一切场景就绪、切场景不销毁；任意脚本直接按名访问 ZhangBen
# 等级 = 体型上限（成长轴）；当前体型 = 血量（受伤扣、吃东西回），两者不是一回事

signal jing_yan_bian_hua(jing_yan: int, yuzhi: int)  # 经验变动：UI 刷新进度条
signal sheng_ji(xin_deng_ji: int)                    # 升级：玩家长大、弹窗弹卡
signal ti_xing_bian_hua(dang_qian: float, shang_xian: float)  # 当前体型（血量）变了：缩/胀、刷 UI
signal si_wang                                       # 当前体型（血量）归零：进结算
signal neng_li_zhuang_bei(neng_li: NengLi, ceng: int)  # 能力装备/叠层：玩家与技能按钮刷新
signal jie_duan_gai_bian(xin_jie_duan: int)          # 阶段变了：Main 据此生成机器船、刷 HUD
signal ju_jie_shu(jie_guo: int)                      # 一局结束（胜/负）：Main 延时切结算页
signal jin_hua_wan_cheng(jin_hua: JinHua)            # 进化完成：玩家鱼换外观/调数值、升级三选一接着弹
signal jin_hua_zan_huan_wan                           # 玩家点了「稍后再选」：升级三选一立刻补弹当级欠账
signal jin_hua_yan_chu_jie_shu(jin_hua: JinHua)       # 进化演出结束：升级三选一这时才补弹

# 终局时间轴（策划案第九章）：一局 10 分钟，第 8 分钟人类机器船降临，8~10 分钟人类战
const JU_SHI_CHANG := 600.0          # 一局总时长（秒）
const REN_LEI_ZHAN_QI_DIAN := 480.0  # 机器船降临时刻（第 8 分钟）
const TIQIAN_DENG_JI := 5            # 提前开战门槛：8 分钟内体型达标并击败鲸鲨 → 船提前来
const BOOS_BAI_TI_XING := 2.0        # 鲸鲨被咬到体型 ≤2 即判定击败（它不吃致命区，只看血量）

enum JieDuan { ZHENG_CHANG, REN_LEI_ZHAN, JIE_SHU }  # 阶段：正常生态 / 人类战 / 已结束
enum JieJu { WEI_DING, SHENG_LI, SHI_BAI, SI_WANG }  # 结局：未定 / 胜利 / 超时失败 / 死亡

var ju_nei_shi_jian := 0.0  # 局内时钟（秒）：只统计活着且未结算的时间
var ren_lei_yan_chi := 0.0  # C 首局节奏脚本：人类战整体推迟（秒）；0 = 标准 8:00 降临
var jie_duan := JieDuan.ZHENG_CHANG  # 当前阶段
var jie_ju := JieJu.WEI_DING          # 本局结局：只写一次，结算页读它选文案

const KAI_JU_DENG_JI := 0    # 开局等级：从最底层的小鱼开始，先吃海草珊瑚再吃鱼
const MO_REN_XING_TAI := preload("res://data/xingtai/ao_tu_wo_niu_yu.tres")  # 默认主角形态：直接启动 Main 也认它
const SHU_ZHI := preload("res://scripts/shu_zhi.gd")  # A 核心数值表（2026-11-08）：可调参数集中管理
const TI_XING_XI_SHU := 0.32  # 体型→像素缩放系数（贴图基准高 100px，1 点体型≈32px）
const TI_XING_QU_XIAN := 0.7  # 体型→像素的曲线指数：等级无上限，线性增长会在高等级把鱼撑爆
const JI_CHU_TI_XING := 1.0   # Lv.0 的基础体型（血量）：没有它 0 级就没法玩了
const MEI_CI_SHANG_HAI := 1.0 # 每次受伤扣 1 点体型单位（= 1 级的分量）
const JI_E_SHANG_XIAN := SHU_ZHI.JI_E_SHANG_XIAN  # A5：饥饿条上限 100
const JI_E_XIA_JIANG_LV := SHU_ZHI.JI_E_XIA_JIANG_MEI_MIAO  # A5：每秒 -0.6（旧 5.0 已废弃）
const JI_E_E_SI_KOU_XUE := 0.1  # 旧字段保留（A6 改为按自身体型百分比扣，见 xia_jiang_ji_e）
const HUI_TI_CHU_SHU := 1.5  # 体型恢复除数：吃进肚子的体型 ÷1.5 才是回血（策划案 8.6.2）
const KONG_ZHI_SHANG_XIAN := 100.0  # 电麻条/毒晕条上限：任一条满 → 失控（策划案 8.6.3）
const KONG_ZHI_XIA_JIANG := 20.0    # 控制条每秒自然消退：离开危险源约 5 秒清空
const YUN_XUAN_SHI_CHANG := 2.0     # 条满后的失控时长（秒）：任人宰割
const JIN_HUA_DENG_JI := 6          # 进化等级门槛：Lv.6 起可进化（策划案 8.6 拍板）
const JIN_HUA_SHU_ZHI_BEI := 1.5    # 进化基础倍率：所有数值 ×1.5（策划案 8.6 拍板）
var sheng_ji_biao := preload("res://data/shengji/sheng_ji_biao.tres")  # 升级曲线参数（改表零代码调曲线）

var jing_yan := 0  # 当前经验（本级的，升级时扣掉已用部分）
var deng_ji := KAI_JU_DENG_JI  # 当前等级 = 体型上限
var dang_qian_ti_xing := JI_CHU_TI_XING  # 当前体型 = 血量（0~上限，受伤扣，吃东西回）
var zhu_dong_zu: Array[NengLi] = []  # 已装备主动组（多槽共存）：可升档，满档后候选池排除它
var zhu_dong_dang: Dictionary = {}  # 主动档位：bian_hao(StringName) -> int（装备=1，上限 neng.zui_da_dang）
var bei_dong_ceng: Dictionary = {}  # 被动能力层数：bian_hao(StringName) -> int（上限 neng.zui_da_dang）
var yi_xuan_neng_li: Array[NengLi] = []  # 本局获得历史：结算页查名字
var dang_qian_xing_tai: XingTai = null  # 本局形态引用；只在开局装配时写入
var xing_tai_yi_ying_yong := false  # 幂等保护：同一局不重复装初始能力/改等级
var chi_yu_ji_lu: Dictionary = {}  # 本局食谱：bian_hao(StringName) -> 吃掉并消化的条数
var zui_duo_bian_hao: StringName = &""  # 本局吃得最多的能力 id（没吃过带能力的鱼 = 空）
var _zui_duo_ci_shu := 0  # 最常吃的条数：平局保留先到者（只有严格大于才换人）
var ji_e := JI_E_SHANG_XIAN  # 当前饥饿：0~100，随时间下降，吃东西回
var sheng_cun_zhong := true  # 局内活着才掉饥饿：死亡后停止，重开复位
var _e_si_lei_ji := 0.0  # 饥饿归零后的计时器：攒满 1 秒扣一次体型
var dian_ma := 0.0  # 电麻条（0~100）：被电鳗放电/电麻猎物叠满 → 失控
var du_yun := 0.0   # 毒晕条（0~100）：被蓑鲉咬/吞蓑鲉叠满 → 失控
var yun_xuan_ji_shi := 0.0  # 失控剩余时间（秒）：>0 时玩家不能游、不能咬、不能吃
var dang_qian_jin_hua: JinHua = null  # 本局已选进化形态；null = 还没进化（每局一次）
var jin_hua_ti_xing_bei := 1.0        # 进化倍率：体型上限也跟着 ×1.5，未进化时恒为 1.0
var jin_hua_dan_chuang_zai_chang := false  # 进化弹窗在 _ready/_exit_tree 登记：没有弹窗的场景（测试）不拖住升级三选一
var jin_hua_zan_huan := false  # 进化「稍后再选」：暂缓期间升级三选一不再让位（策划案 v0.18 8.6）
var jin_hua_yan_chu_zhong := false  # 进化演出中：玩家免伤，升级三选一等演出结束再弹
var jin_hua_yan_chu_shi_chang := 1.7  # 进化演出时长（秒）：策划案 1.5~2 秒，实机可调
# ---- 本局战绩（B2 死亡/胜利结算：战斗账本直接读，chong_zhi 必须同步复位）----
var ben_ju_tun_chi_shu := 0  # 吞噬数：吞掉的 NPC 鱼条数
var ben_ju_ji_sha_shu := 0  # 击杀数：吞鱼 + 打沉机器船（结算公式按击杀计分）
var ben_ju_diao_rou_liang := 0.0  # 造成的掉肉总量：玩家对敌人累计造成的咬击伤害
var ben_ju_tun_chi_yu_zhong: Array[StringName] = []  # 本局吞过的鱼种 id（去重）
var ben_ju_tun_chi_yu_zhong_ming: Array[String] = []  # 与上一行一一对应的显示名（B2 首次吞噬提示用）
var ben_ju_sha_shou_ming := ""  # 死亡瞬间的击杀者显示名（B2「差一点」）
var ben_ju_sha_shou_ti_xing := 0.0  # 击杀者当前体型
var ben_ju_sha_shou_chu_shi := 0.0  # 击杀者初始体型（算「它还剩 X%」）
var ben_ju_fan_sha_kou := 0  # 再咬几口就能反杀（按 3%/口 逐口推演）
var ben_ju_qiang_du := 0  # E1 当局强度评分（结算时算一次）


func _ready() -> void:
	# 账本挂 Autoload：升级三选一暂停时，饥饿也必须停——否则选卡期间玩家会被饿死
	process_mode = Node.PROCESS_MODE_PAUSABLE
	# 默认形态：直接启动 Main（测试/调试路径）不经过选择页，账本要自带主角。
	# 选择页与继续游戏都会先 chong_zhi() 再按存档重装，不会被这里的默认值覆盖。
	if dang_qian_xing_tai == null:
		kai_ju_xing_tai(MO_REN_XING_TAI)


func _process(delta: float) -> void:
	# Autoload 自己走时钟：局内时间 + 饥饿下降 + 控制条消退，伤害仍统一走 shou_shang
	zou_ju_shi_jian(delta)
	xia_jiang_ji_e(delta)
	geng_xin_kong_zhi(delta)


func ti_xing_shang_xian() -> float:
	# 体型上限：Lv.0 给 1 点基础体型，之后每级 +1（Lv.8 → 9 点）
	# 进化后整体 ×1.5（策划案 8.6「所有数值 ×1.5」）：未进化时倍率恒为 1.0，旧规则原样
	return (float(deng_ji) + JI_CHU_TI_XING) * jin_hua_ti_xing_bei


func ti_xing_dao_chi_du(ti_xing_zhi: float) -> float:
	# 体型→像素的唯一换算入口：玩家与 NPC 共用，保证「看起来谁大」与判定一致
	# 指数 0.7 < 1：每升一级的视觉增量递减；Lv.0 仍约 32px，Lv.8 约 149px（线性会是 288px）
	# TASK-019：每满 5 点体型额外 ×1.06（Lv.5/Lv.10/Lv.15 有可见跳变）；Lv.1 仍恰好 0.32
	var li_cheng_bei := pow(1.06, floor(maxf(ti_xing_zhi, 0.0) / 5.0))
	return TI_XING_XI_SHU * pow(maxf(ti_xing_zhi, 0.0), TI_XING_QU_XIAN) * li_cheng_bei


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


func tiao_shi_sheng_yi_ji() -> void:
	# 仅调试构建的局内「测试升级」：清掉本级余量，正好补满一级。
	# 先清余量是为了“点一次 = 升一级”，不会因为已有经验一次连升几级；
	# 仍然走 jia_jing_yan 唯一入口，升级信号/回血/进化弹窗等后续逻辑全部照常触发。
	jing_yan = 0
	jia_jing_yan(dangqian_yuzhi())


func shou_shang(liang: float = MEI_CI_SHANG_HAI) -> void:
	# 受伤唯一入口：扣当前体型（血量），不碰等级上限
	# 体型越大血越厚——同样扣 1 点，Lv.0 一次见底，Lv.8 能扛九次
	if dang_qian_ti_xing <= 0.0:
		return  # 已死亡：不再重复扣、不重复播死亡
	if jin_hua_yan_chu_zhong:
		return  # 进化演出无敌：连饿死等绕过玩家 wudi 的直接扣血也挡住（策划案 v0.18）
	dang_qian_ti_xing = maxf(0.0, dang_qian_ti_xing - liang)
	ti_xing_bian_hua.emit(dang_qian_ti_xing, ti_xing_shang_xian())
	if dang_qian_ti_xing <= 0.0:
		sheng_cun_zhong = false  # 先停饥饿时钟，再广播：si_wang 的接收者会切场景
		var gang_si := jie_ju == JieJu.WEI_DING
		if gang_si:
			jie_ju = JieJu.SI_WANG  # 死亡也是一种结局；已经结算过就不再改写
			jie_duan = JieDuan.JIE_SHU
		si_wang.emit()
		# B2 死亡钩子（2026-11-08）：死亡也要走结算广播——CunDang 据此入账成就值、
		# JieSuan 页据此展示「本局战绩/差一点/进度钩」。只在本函数把结局写成 SI_WANG 时发一次。
		if gang_si:
			ju_jie_shu.emit(jie_ju)


func hui_ti_xing(liang: float) -> void:
	# 回血唯一入口：吃东西回体型，最多回到当前等级的上限
	var shang := ti_xing_shang_xian()
	if dang_qian_ti_xing >= shang:
		return  # 满血不再广播，避免白刷 UI
	dang_qian_ti_xing = minf(shang, dang_qian_ti_xing + liang)
	ti_xing_bian_hua.emit(dang_qian_ti_xing, shang)


func xia_jiang_ji_e(delta: float) -> void:
	# 饥饿唯一时钟：活着才走；A5 每秒 -0.6；归零后 A6 每秒掉「自身体型 0.5%」
	# 拆成公开函数是为了可测：_process 只是调用者，测试可喂确定的 delta
	if not sheng_cun_zhong:
		return
	if ji_e > 0.0:
		# 饥饿耐受：每层 -10% 下降速率（数值从能力表读，满层 30%）
		var xia_jiang := JI_E_XIA_JIANG_LV * (1.0 - clampf(bei_dong_zhi(&"ji_e_nai_shou"), 0.0, 0.9))
		ji_e = maxf(0.0, ji_e - xia_jiang * delta)
		return
	_e_si_lei_ji += delta
	while _e_si_lei_ji >= 1.0:
		_e_si_lei_ji -= 1.0
		# A6：按当前体型百分比扣，并加绝对底值——纯百分比是指数衰减，永远到不了 0
		var kou := maxf(dang_qian_ti_xing * SHU_ZHI.E_SI_TI_XING_BI, SHU_ZHI.E_SI_ZUI_DI_MEI_MIAO)
		shou_shang(kou)  # 饿死走的仍是受伤通道：归零时账本广播 si_wang + ju_jie_shu


func hui_ji_e(liang: float) -> void:
	# 吃东西回饥饿：封顶 100；死亡后不再回（已经进结算了）
	# 饥饿耐受满层附加：吃食回饥饿 ×1.2（dang_biao.hui_de_bei，没满层不加成）
	if not sheng_cun_zhong:
		return
	if ji_e >= JI_E_SHANG_XIAN:
		return
	var bei := bei_dong_fu_jia(&"ji_e_nai_shou", &"hui_de_bei")
	if bei > 1.0:
		liang *= bei
	ji_e = minf(JI_E_SHANG_XIAN, ji_e + liang)
	_e_si_lei_ji = 0.0  # 吃了东西就脱离饥饿：饿死计时重新从 0 攒，不留残数提前扣血


func chi_yu_hui_ji_e(_dui_fang_ti_xing: float) -> float:
	# A7：吞一条鱼固定回 25 点饥饿（2026-11-08 拍板，不再按鱼体型分 10/8/30）
	# 参数保留：调用方仍按「被吃鱼的体型」传，方便后续按体型分档回填
	return SHU_ZHI.TUN_YU_HUI_JI_E


func chi_wu_hui_ti_xing(wu_ti_xing: float) -> float:
	# A7：鱼肉块回复 = 自身体型上限 ×1.5%（植物没有体型值 → 只给经验/饥饿）
	# 保留 ÷1.5 恢复系数（贪食满层改为 ÷1.3）；参数只用于判断是不是「肉」
	if wu_ti_xing <= 0.0:
		return 0.0
	return _hui_ti_xi_shu(ti_xing_shang_xian() * SHU_ZHI.ROU_HUI_TI_XING_BI)


func chi_yu_hui_ti_xing(_dui_fang_ti_xing: float) -> float:
	# A7：吞一条鱼回复 = 自身体型上限 ×4%，再走 ÷1.5 恢复系数（贪食满层 ÷1.3）
	# 旧实现按「被吃鱼的体型 ÷1.5」算，与 A7 的 +4% 口径不同，2026-11-08 起切换
	return _hui_ti_xi_shu(ti_xing_shang_xian() * SHU_ZHI.TUN_YU_HUI_TI_XING_BI)


func _hui_ti_xi_shu(ji_chu: float) -> float:
	# 进食回体型统一折算：÷1.5；贪食按层数加量，满层附加把恢复系数 1.5 → 1.3
	var hui := maxf(0.0, ji_chu) / HUI_TI_CHU_SHU
	var jia := bei_dong_zhi(&"tan_shi_hui_fu")
	if jia > 0.0:
		hui *= 1.0 + jia
		var xi_shu := bei_dong_fu_jia(&"tan_shi_hui_fu", &"xi_shu")
		if xi_shu > 1.0:
			hui *= HUI_TI_CHU_SHU / xi_shu
	return hui


# ---- 本局战绩记账（B1/B2 结算用：只增不减，chong_zhi 复位）----

func ji_tun_chi(yu_zhong_bian_hao: StringName = &"", yu_zhong_ming := "") -> void:
	# 吞掉一条 NPC：吞噬数 +1、击杀数 +1、记录鱼种/显示名（B1「首次吞噬新鱼种」按鱼种去重）
	ben_ju_tun_chi_shu += 1
	ben_ju_ji_sha_shu += 1
	if yu_zhong_bian_hao != &"" and not ben_ju_tun_chi_yu_zhong.has(yu_zhong_bian_hao):
		ben_ju_tun_chi_yu_zhong.append(yu_zhong_bian_hao)
		ben_ju_tun_chi_yu_zhong_ming.append(yu_zhong_ming if yu_zhong_ming != "" else String(yu_zhong_bian_hao))


func ji_ji_sha() -> void:
	# 非吞噬类击杀（机器船沉没）：只加击杀数
	ben_ju_ji_sha_shu += 1


func ji_zao_cheng_diao_rou(liang: float) -> void:
	# 玩家对敌人造成的掉肉总量（B2 战绩②）：所有咬击/冲撞/直伤入口都调这里
	if liang > 0.0:
		ben_ju_diao_rou_liang += liang


func ji_lu_sha_shou(sha_shou, wan_jia_ti_xing: float) -> void:
	# 死亡瞬间记录击杀者（B2「差一点」）：只记第一次，避免连击重复覆盖
	if ben_ju_sha_shou_ming != "" or sha_shou == null or not is_instance_valid(sha_shou):
		return
	var ming := "未知鱼种"
	var yu_zhong = sha_shou.get("yu_zhong")
	if yu_zhong != null:
		ming = str(yu_zhong.ming_zi)
	ben_ju_sha_shou_ming = ming
	ben_ju_sha_shou_ti_xing = float(sha_shou.get("tixing"))
	var chu_shi = sha_shou.get("tixing_chu_shi")
	if chu_shi != null and float(chu_shi) > 0.0:
		ben_ju_sha_shou_chu_shi = float(chu_shi)
	else:
		ben_ju_sha_shou_chu_shi = ben_ju_sha_shou_ti_xing
	ben_ju_fan_sha_kou = ji_suan_fan_sha_kou(wan_jia_ti_xing, ben_ju_sha_shou_ti_xing)


func ji_suan_fan_sha_kou(wan_jia_ti_xing: float, sha_shou_ti_xing: float) -> int:
	# 再咬几口就能反杀：按 A2 的 3%/口 逐口推演（NPC 最小体型夹到 0.5）
	# 反杀口径 = 把它咬到「我 ×1.1 门槛」以下，下一口就能整吞
	var yao_dao := wan_jia_ti_xing / SHU_ZHI.TUN_CHI_BEI_LV
	var ti_xing := sha_shou_ti_xing
	var kou := 0
	while ti_xing > yao_dao and kou < 200:
		ti_xing = maxf(0.5, ti_xing - maxf(SHU_ZHI.YAO_JI_ZUI_DI_SHANG_HAI,
				ti_xing * SHU_ZHI.YAO_JI_SHANG_HAI_BI))
		kou += 1
	return kou


func ben_ju_sha_shou_sheng_yu_bi() -> float:
	# 击杀者「还剩多少体型」的百分比（相对它出场时的体型）：B2 文案 X%
	if ben_ju_sha_shou_chu_shi <= 0.0:
		return 0.0
	return clampf(ben_ju_sha_shou_ti_xing / ben_ju_sha_shou_chu_shi, 0.0, 1.0)


func jia_dian_ma(liang: float) -> void:
	# 电麻条唯一入口：叠满 → 失控 2 秒（条清零，避免醒来立刻又被同一下触发）
	if not sheng_cun_zhong or yun_xuan_ji_shi > 0.0:
		return  # 死了 / 已经失控：不再叠条
	dian_ma = minf(KONG_ZHI_SHANG_XIAN, dian_ma + liang)
	if dian_ma >= KONG_ZHI_SHANG_XIAN:
		_chu_fa_yun_xuan(&"dian_xi")  # F7 电麻失控：电击颗粒音


func qing_dian_ma() -> void:
	# 电脉冲主动：清空自己的电麻条，但不解除已经触发的失控
	dian_ma = 0.0


func jia_du_yun(liang: float) -> void:
	# 毒晕条唯一入口：与电麻共用同一套“满 → 失控”规则
	if not sheng_cun_zhong or yun_xuan_ji_shi > 0.0:
		return
	du_yun = minf(KONG_ZHI_SHANG_XIAN, du_yun + liang)
	if du_yun >= KONG_ZHI_SHANG_XIAN:
		_chu_fa_yun_xuan(&"du_xi")  # F8 毒晕失控：气泡破裂音


func zai_kong_zhi() -> bool:
	# 玩家此刻是否失控：玩家鱼与 HUD 都读这一个判断，不各存一份状态
	return yun_xuan_ji_shi > 0.0


func geng_xin_kong_zhi(delta: float) -> void:
	# 控制条时钟：失控期间只倒数失控时间；正常时两条一起自然消退
	# 拆成公开函数是为了可测：_process 只是调用者
	if not sheng_cun_zhong:
		return
	if yun_xuan_ji_shi > 0.0:
		yun_xuan_ji_shi = maxf(0.0, yun_xuan_ji_shi - delta)
		return
	dian_ma = maxf(0.0, dian_ma - KONG_ZHI_XIA_JIANG * delta)
	du_yun = maxf(0.0, du_yun - KONG_ZHI_XIA_JIANG * delta)


func _chu_fa_yun_xuan(yuan: StringName = &"shi_kong") -> void:
	# 任一条满：两条一起清零并进入失控——只罚一次，不做“电麻条一直满着反复晕”
	# F7/F8：按来源播电击/毒音；来源不明（外部强制）仍用旧的失控音兜底
	yun_xuan_ji_shi = YUN_XUAN_SHI_CHANG
	dian_ma = 0.0
	du_yun = 0.0
	YinXiang.fang(yuan)


func qiang_zhi_kong_zhi(shi_chang: float) -> void:
	# 外部强制失控（机器船渔网）：不走控制条，直接进入失控 N 秒
	# 与条满的失控共用同一个计时器 yun_xuan_ji_shi——玩家侧只认 zai_kong_zhi()
	if not sheng_cun_zhong:
		return
	yun_xuan_ji_shi = maxf(yun_xuan_ji_shi, shi_chang)


func zou_ju_shi_jian(delta: float) -> void:
	# 局内时钟唯一入口：活着且未结算才走表
	# 先记时间再判阶段：跨过 480 秒立刻开人类战，到 600 秒自动判负
	if not sheng_cun_zhong or jie_ju != JieJu.WEI_DING:
		return
	ju_nei_shi_jian += delta
	if jie_duan == JieDuan.ZHENG_CHANG and ju_nei_shi_jian >= REN_LEI_ZHAN_QI_DIAN + ren_lei_yan_chi:
		kai_shi_ren_lei_zhan()
	if ju_nei_shi_jian >= JU_SHI_CHANG:
		ding_jie_suan(JieJu.SHI_BAI)


func kai_shi_ren_lei_zhan() -> void:
	# 进入人类战：重复调用只生效一次（时间到 + 鲸鲨提前开战 两条路共用）
	if jie_duan != JieDuan.ZHENG_CHANG or jie_ju != JieJu.WEI_DING:
		return
	jie_duan = JieDuan.REN_LEI_ZHAN
	jie_duan_gai_bian.emit(jie_duan)


func ti_qian_kai_zhan() -> bool:
	# 提前开战奖励：8 分钟前击败鲸鲨且体型达标 → 机器船当场降临
	# 返回 false 的三种原因由调用方（Main）给提示，账本不改阶段
	if jie_duan != JieDuan.ZHENG_CHANG or jie_ju != JieJu.WEI_DING:
		return false
	if ju_nei_shi_jian >= REN_LEI_ZHAN_QI_DIAN:
		return false
	if deng_ji < TIQIAN_DENG_JI:
		return false
	kai_shi_ren_lei_zhan()
	return true


func ding_jie_suan(jie_guo: int) -> void:
	# 一局结束唯一入口：结局只写一次，之后时钟/饥饿全部停表
	if jie_ju != JieJu.WEI_DING:
		return
	jie_ju = jie_guo
	jie_duan = JieDuan.JIE_SHU
	sheng_cun_zhong = false
	ju_jie_shu.emit(jie_ju)


func sheng_yu_shi_jian() -> float:
	# 剩余时间（秒）：HUD 与测试都读它，负数夹到 0
	return maxf(0.0, JU_SHI_CHANG - ju_nei_shi_jian)


static func ge_shi_shi_jian(miao: float) -> String:
	# 秒 → “mm:ss”：HUD 与结算页共用一份格式化，避免两处各写一遍
	var zong := int(maxf(0.0, miao))
	return "%02d:%02d" % [int(zong / 60.0), zong % 60]


func chong_zhi() -> void:
	# 局内状态归零唯一入口（重开时用）：账本是 Autoload 常驻——谁常驻谁负责自己的复位
	jing_yan = 0
	deng_ji = KAI_JU_DENG_JI
	dang_qian_ti_xing = JI_CHU_TI_XING
	zhu_dong_zu.clear()  # 能力装备清空（形态初始能力经 kai_ju_xing_tai 重新入组的路径不变）
	zhu_dong_dang.clear()  # 档位表跟着清：重开一局所有主动都回到 0 档
	bei_dong_ceng.clear()
	yi_xuan_neng_li.clear()
	chi_yu_ji_lu.clear()
	zui_duo_bian_hao = &""
	_zui_duo_ci_shu = 0
	ji_e = JI_E_SHANG_XIAN  # 饥饿回满
	_e_si_lei_ji = 0.0
	dian_ma = 0.0  # 控制条回零
	du_yun = 0.0
	yun_xuan_ji_shi = 0.0
	sheng_cun_zhong = true  # 重开复活：饥饿时钟重新走
	ju_nei_shi_jian = 0.0  # 局内时钟归零
	ren_lei_yan_chi = 0.0  # C 首局脚本的推迟不跨局
	jie_duan = JieDuan.ZHENG_CHANG  # 阶段回到正常生态
	jie_ju = JieJu.WEI_DING  # 结局清空：上一局的胜负不能带进新局
	dang_qian_xing_tai = null  # 形态属于“上一局开局”，纯复位必须清掉
	xing_tai_yi_ying_yong = false
	dang_qian_jin_hua = null  # 进化是每局一次：重开回到基础形态
	jin_hua_ti_xing_bei = 1.0
	jin_hua_zan_huan = false  # 暂缓状态不跨局
	jin_hua_yan_chu_zhong = false  # 演出标志不跨局（防止免伤残留）
	# 本局战绩：重开一局从零开始（B1 结算公式读这些字段）
	ben_ju_tun_chi_shu = 0
	ben_ju_ji_sha_shu = 0
	ben_ju_diao_rou_liang = 0.0
	ben_ju_tun_chi_yu_zhong.clear()
	ben_ju_tun_chi_yu_zhong_ming.clear()
	ben_ju_sha_shou_ming = ""
	ben_ju_sha_shou_ti_xing = 0.0
	ben_ju_sha_shou_chu_shi = 0.0
	ben_ju_fan_sha_kou = 0
	ben_ju_qiang_du = 0


func kai_ju_xing_tai(xing_tai: XingTai) -> bool:
	# 开局装配形态：只设初始等级/体型/初始能力
	# 不走 jia_jing_yan：直接赋值等级，避免开局弹三选一
	# 调用前应先 chong_zhi()；同一局重复调用返回 false（防初始能力重复叠层）
	if xing_tai == null or xing_tai_yi_ying_yong:
		return false
	dang_qian_xing_tai = xing_tai
	xing_tai_yi_ying_yong = true
	deng_ji = maxi(0, xing_tai.kai_ju_deng_ji)
	jing_yan = 0
	dang_qian_ti_xing = ti_xing_shang_xian()  # 新上限直接填满
	if xing_tai.kai_ju_neng_li != null:
		xuan_neng_li(xing_tai.kai_ju_neng_li)
	# 成就永久解锁：形态自带的那一个不重复加，其余每样装一份（主动 1 档 / 被动 1 层）
	# 纯逻辑测试用 --script 跑，账本还没进场景树：此时不碰 /root，避免 get_node 报错
	if is_inside_tree():
		var cun_dang := get_node_or_null("/root/CunDang")
		if cun_dang != null:
			cun_dang.ying_yong_yong_jiu(self)
	return true


func chong_zhi_bao_liu_xing_tai() -> void:
	# 结算“再来一次”：先存引用再复位，避免 chong_zhi 清空后读到 null
	var xing_tai := dang_qian_xing_tai
	chong_zhi()
	if xing_tai != null:
		kai_ju_xing_tai(xing_tai)


func ke_yi_jin_hua() -> bool:
	# 进化资格：活到 Lv.6、还没进化、本局未结束——三个条件缺一不可（每局一次）
	# 弹窗与测试都读这一处，不各写一份判断
	return dang_qian_jin_hua == null and deng_ji >= JIN_HUA_DENG_JI \
			and sheng_cun_zhong and jie_ju == JieJu.WEI_DING


func dang_qian_yu_zhong() -> StringName:
	# 当前鱼种 id：选 NPC 鱼开局后，Lv.6 只能选该鱼种自己的三分支
	# 没装形态（纯逻辑测试/极端读档失败）时按默认主角处理，绝不返回空串
	if dang_qian_xing_tai != null:
		return dang_qian_xing_tai.yu_zhong_bian_hao()
	return MO_REN_XING_TAI.yu_zhong_bian_hao()


func jin_hua_dai_xuan() -> bool:
	# 「进化待选择」读数：已暂缓、且仍然有资格——HUD 脉动提示与测试都读这一处
	return jin_hua_zan_huan and ke_yi_jin_hua()


func zan_huan_jin_hua() -> bool:
	# 「稍后再选」：只置暂缓标志，不改 ke_yi_jin_hua（之后仍能回来选）
	# 发信号让升级三选一立刻补弹 6 级欠下的那一轮，别等下一次升级
	if not ke_yi_jin_hua():
		return false
	jin_hua_zan_huan = true
	jin_hua_zan_huan_wan.emit()
	return true


func kai_shi_jin_hua_yan_chu() -> void:
	# 进化演出开始：玩家免伤，升级三选一先欠账不出（演出结束由弹窗发结束信号）
	jin_hua_yan_chu_zhong = true


func jie_shu_jin_hua_yan_chu(jin_hua: JinHua = null) -> void:
	# 进化演出结束：清免伤标志并广播，升级三选一这时才补弹
	if not jin_hua_yan_chu_zhong:
		return
	jin_hua_yan_chu_zhong = false
	jin_hua_yan_chu_jie_shu.emit(jin_hua if jin_hua != null else dang_qian_jin_hua)


func jin_hua_wei(xuan_ze: JinHua) -> bool:
	# 进化唯一入口：玩家在 3 选 1 里选定分支 → 记形态、乘倍率、装配专属能力、广播
	# 倍率分工：体型上限在这里乘（账本自己管），速度/嘴巴/转向由玩家鱼听信号后乘——
	# 账本不持有玩家的移动参数，谁拥有谁改
	if xuan_ze == null or not xuan_ze.wan_jia_ke_yong or not ke_yi_jin_hua():
		return false
	# 分支必须属于当前鱼种：防旧测试/旧存档把别的鱼种分支装进来
	if xuan_ze.ji_yu_bian_hao != dang_qian_yu_zhong():
		return false
	dang_qian_jin_hua = xuan_ze
	jin_hua_zan_huan = false  # 选定即完成：暂缓状态清掉，HUD 提示随之消失
	jin_hua_ti_xing_bei = maxf(1.0, xuan_ze.shu_zhi_bei)
	dang_qian_ti_xing = ti_xing_shang_xian()  # 新上限直接填满：进化是变强，不是残血续命
	ti_xing_bian_hua.emit(dang_qian_ti_xing, ti_xing_shang_xian())
	# 专属主动/专属被动：走现有装备入口（主动占槽、被动叠层）；内容待填时为空，这里不动作
	if xuan_ze.zhuan_shu_zhu_dong != null:
		xuan_neng_li(xuan_ze.zhuan_shu_zhu_dong)
	if xuan_ze.zhuan_shu_bei_dong != null:
		xuan_neng_li(xuan_ze.zhuan_shu_bei_dong)
	jin_hua_wan_cheng.emit(xuan_ze)
	return true


func zai_ru_jin_hua(bian_hao: StringName) -> bool:
	# 继续游戏：按存档 id 恢复进化形态（只恢复倍率与外观引用，不重复发专属能力——
	# 专属能力已经躺在存档的主动/被动列表里，再装一次会白升一档）
	var jin_hua := JinHuaKu.zhao(bian_hao)
	if jin_hua == null or not jin_hua.wan_jia_ke_yong:
		return false
	# 存档里的分支必须属于当前鱼种：旧档/手改档跨鱼种分支一律忽略（回退基础形态）
	if jin_hua.ji_yu_bian_hao != dang_qian_yu_zhong():
		return false
	dang_qian_jin_hua = jin_hua
	jin_hua_ti_xing_bei = maxf(1.0, jin_hua.shu_zhi_bei)
	return true



func zai_ru_zhong_tu(shu_ju: Dictionary, xing_tai: XingTai) -> bool:
	# 继续游戏唯一入口：跳过“新局复位”，把中途存档字段直接写回账本
	# 与 kai_ju_xing_tai 的区别：不重置等级/经验/能力，而是按存档数值恢复
	# 简化（原型级）：鱼位置、NPC、机器船不恢复——继续游戏 = 用存档数值重开一个场景；
	# 阶段不存：若存档时钟已过 480 秒，回来后下一帧 zou_ju_shi_jian 会自动重新进入
	# 人类战（机器船重新降临）；鲸鲨也由 Main._ready 无条件重生——都是原型级取舍
	if shu_ju.is_empty() or xing_tai == null:
		return false
	chong_zhi()  # 先归零再覆写：没存的瞬时字段（控制条/失控/饿死计时）一律回到开局值
	dang_qian_xing_tai = xing_tai
	xing_tai_yi_ying_yong = true  # 幂等保护照常生效：这一局不许再走 kai_ju_xing_tai
	deng_ji = maxi(0, int(shu_ju.get("deng_ji", KAI_JU_DENG_JI)))
	jing_yan = maxi(0, int(shu_ju.get("jing_yan", 0)))
	# 进化恢复：先恢复倍率再算上限——否则读回的血量上限会比进化前少 1/3
	var jin_hua_id = shu_ju.get("jin_hua", "")
	if jin_hua_id is String and String(jin_hua_id) != "":
		if zai_ru_jin_hua(StringName(jin_hua_id)) and is_inside_tree():
			# 继续游戏也算“进化过”：图鉴永久点亮（已亮则 dian_liang_jin_hua 幂等返回 false）
			var cun_dang := get_node_or_null("/root/CunDang")
			if cun_dang != null:
				cun_dang.dian_liang_jin_hua(StringName(jin_hua_id))
	var shang_xian := ti_xing_shang_xian()
	dang_qian_ti_xing = clampf(float(shu_ju.get("dang_qian_ti_xing", shang_xian)), 0.0, shang_xian)
	ji_e = clampf(float(shu_ju.get("ji_e", JI_E_SHANG_XIAN)), 0.0, JI_E_SHANG_XIAN)
	ju_nei_shi_jian = maxf(0.0, float(shu_ju.get("ju_nei_shi_jian", 0.0)))
	# B1 局内战绩恢复：继续游戏后结算仍按本局真实吞噬/击杀/掉肉/首杀信息算（旧档缺键按 0）
	ben_ju_tun_chi_shu = maxi(0, int(shu_ju.get("ben_ju_tun_chi_shu", 0)))
	ben_ju_ji_sha_shu = maxi(0, int(shu_ju.get("ben_ju_ji_sha_shu", 0)))
	ben_ju_diao_rou_liang = maxf(0.0, float(shu_ju.get("ben_ju_diao_rou_liang", 0.0)))
	for id_wen in shu_ju.get("ben_ju_tun_chi_yu_zhong", []):
		if id_wen is String:
			var yz_id := StringName(id_wen)
			if yz_id != &"" and not ben_ju_tun_chi_yu_zhong.has(yz_id):
				ben_ju_tun_chi_yu_zhong.append(yz_id)
	for ming_wen in shu_ju.get("ben_ju_tun_chi_yu_zhong_ming", []):
		ben_ju_tun_chi_yu_zhong_ming.append(String(ming_wen))
	ben_ju_sha_shou_ming = String(shu_ju.get("ben_ju_sha_shou_ming", ""))
	ben_ju_sha_shou_ti_xing = maxf(0.0, float(shu_ju.get("ben_ju_sha_shou_ti_xing", 0.0)))
	ben_ju_sha_shou_chu_shi = maxf(0.0, float(shu_ju.get("ben_ju_sha_shou_chu_shi", 0.0)))
	ben_ju_fan_sha_kou = maxi(0, int(shu_ju.get("ben_ju_fan_sha_kou", 0)))
	# 能力恢复：按 id 从能力池载入资源（load 有缓存：同 id 同实例，装备组与历史天然同源）
	for id_wen in shu_ju.get("yi_xuan", []):
		var li_shi_neng: NengLi = load("res://data/nengli/%s.tres" % String(id_wen))
		if li_shi_neng != null:
			yi_xuan_neng_li.append(li_shi_neng)
	for id_wen in shu_ju.get("zhu_dong", []):
		var zhu_dong_neng: NengLi = load("res://data/nengli/%s.tres" % String(id_wen))
		if zhu_dong_neng != null and neng_li_ke_yong(zhu_dong_neng):
			zhu_dong_zu.append(zhu_dong_neng)
	var cun_dang_biao: Dictionary = shu_ju.get("zhu_dong_dang", {})
	for jian in cun_dang_biao:
		zhu_dong_dang[StringName(jian)] = maxi(1, int(cun_dang_biao[jian]))
	var ceng_cun: Dictionary = shu_ju.get("bei_dong_ceng", {})
	for jian in ceng_cun:
		# 专属被动：旧档/手改档若带着不属于当前形态的归属，整条丢弃（不生效）
		var bei_dong_neng := NengLiKu.zhao(StringName(jian))
		if bei_dong_neng != null and not neng_li_ke_yong(bei_dong_neng):
			continue
		bei_dong_ceng[StringName(jian)] = maxi(1, int(ceng_cun[jian]))
	# 食谱恢复：最常吃（id + 次数）从计数表重新推导，不单独存——推导比存两份更不会不一致
	var shi_pu_cun: Dictionary = shu_ju.get("chi_yu_ji_lu", {})
	var zui_duo_ci := 0
	for jian in shi_pu_cun:
		var ci := maxi(0, int(shi_pu_cun[jian]))
		chi_yu_ji_lu[StringName(jian)] = ci
		if ci > zui_duo_ci:
			zui_duo_ci = ci
			zui_duo_bian_hao = StringName(jian)
	_zui_duo_ci_shu = zui_duo_ci
	return true


func neng_li_ke_yong(neng: NengLi) -> bool:
	# 进化专属技的运行时归属校验（策划案 v0.21）：只有当前进化形态恰好是它绑定的形态才生效。
	# 通用/鱼种能力（suoshu_xing_tai 为空）不受影响；这条同时挡住读档、未来商店/掉落等旁路。
	if neng == null:
		return false
	if not neng.shi_zhuan_shu():
		return true
	return dang_qian_jin_hua != null and dang_qian_jin_hua.bian_hao == neng.suoshu_xing_tai


func xuan_neng_li(neng: NengLi) -> void:
	# 能力装备唯一入口：主动入组/升档（满档静默）；被动叠层（满层静默）；生效的选择进历史
	# neng_li_zhuang_bei 的 ceng 参数双义：主动=当前档位，被动=当前层数（UI 统一显示 ×N）
	if neng == null or not neng_li_ke_yong(neng):
		return
	if neng.shi_zhu_dong():
		if zhuang_lei(neng.bian_hao):
			var dang := dang_qian_zhu_dong_dang(neng.bian_hao)
			if dang >= neng.zui_da_dang:
				return  # 满档：再选一次按无操作处理（不广播、不进历史）
			zhu_dong_dang[neng.bian_hao] = dang + 1
			neng_li_zhuang_bei.emit(neng, dang + 1)
		else:
			zhu_dong_zu.append(neng)
			zhu_dong_dang[neng.bian_hao] = 1
			neng_li_zhuang_bei.emit(neng, 1)
	else:
		var ceng := dang_qian_bei_dong_ceng(neng.bian_hao)
		if ceng >= neng.zui_da_dang:
			return  # 满层：再选一次按无操作处理（不广播、不进历史）
		bei_dong_ceng[neng.bian_hao] = ceng + 1
		neng_li_zhuang_bei.emit(neng, ceng + 1)
	yi_xuan_neng_li.append(neng)


func zhuang_lei(bian_hao: StringName) -> bool:
	# 是否已装备该主动：候选排除、潜伏判定、测试断言共用的唯一读数
	for neng in zhu_dong_zu:
		if neng != null and neng.bian_hao == bian_hao:
			return true
	return false


func zhao_zhu_dong(bian_hao: StringName) -> NengLi:
	# 按 id 反查已装备主动（潜伏翻倍要读 shu_zhi）；没装备返回 null
	for neng in zhu_dong_zu:
		if neng != null and neng.bian_hao == bian_hao:
			return neng
	return null


func dang_qian_bei_dong_ceng(bian_hao: StringName) -> int:
	# 被动层数读数：玩家效果与技能按钮都读这一处，不各存一份
	return int(bei_dong_ceng.get(bian_hao, 0))


func dang_qian_zhu_dong_dang(bian_hao: StringName) -> int:
	# 主动档位读数：未装备 = 0，装备后从 1 起；效果结算与技能按钮都读这一处
	return int(zhu_dong_dang.get(bian_hao, 0))


func zhao_bei_dong(bian_hao: StringName) -> NengLi:
	# 按 id 反查已装备被动 Resource（读 zui_da_dang/dang_biao 用）；没装备返回 null
	for neng in yi_xuan_neng_li:
		if neng != null and neng.bian_hao == bian_hao:
			return neng
	return null


func bei_dong_zhi(bian_hao: StringName) -> float:
	# 被动当前层数的主数值：基础走 ceng_shu_zhi（主值 + 每层增量）；
	# 档位表覆写了 shu_zhi 的档（满层质变）直接取覆写值——两种曲线都从这一处读
	var ceng := dang_qian_bei_dong_ceng(bian_hao)
	if ceng <= 0:
		return 0.0
	var neng := zhao_bei_dong(bian_hao)
	if neng == null:
		return 0.0
	if neng.dang_biao.has(ceng):
		var biao: Dictionary = neng.dang_biao[ceng]
		if biao.has(&"shu_zhi"):
			return float(biao[&"shu_zhi"])
	return neng.ceng_shu_zhi(ceng)


func bei_dong_fu_jia(bian_hao: StringName, jian: StringName) -> float:
	# 被动满层附加（质变项）：只在满层时从档位表读，没满层/没写 = 0——效果侧判 > 0 启用
	var ceng := dang_qian_bei_dong_ceng(bian_hao)
	if ceng <= 0:
		return 0.0
	var neng := zhao_bei_dong(bian_hao)
	if neng == null or ceng < neng.zui_da_dang:
		return 0.0
	return neng.dang_zhi(jian, ceng)


func wan_jia_yin_bi_xi_shu() -> float:
	# NPC 看玩家时的感知折算系数：隐匿气息每层 -10% 可见度（0.9/0.8/0.7）
	return 1.0 - clampf(bei_dong_zhi(&"yin_ni_qi_xi"), 0.0, 0.9)


func ji_chi_yu(neng: NengLi) -> void:
	# 食谱记账：只在消化完成时调用（吞下去不等于吃到手）
	# 平局保留先到者：只有严格大于才换人，避免“并列时每次吃都改答案”
	if neng == null:
		return
	var ci := int(chi_yu_ji_lu.get(neng.bian_hao, 0)) + 1
	chi_yu_ji_lu[neng.bian_hao] = ci
	if ci > _zui_duo_ci_shu:
		_zui_duo_ci_shu = ci
		zui_duo_bian_hao = neng.bian_hao
