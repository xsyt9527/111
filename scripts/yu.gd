extends Node2D
class_name Yu
# 玩家鱼：移动规则 + 大吃小判定都在这里

@export var yidong_sudu := 300.0  # 移动速度，像素/秒
@export var zui_ba := 1.0  # 嘴巴系数：玩家的咬击伤害倍率（后续能力卡可以强化它）

const TUN_CHI_BEI_LV := 1.1  # 吞噬门槛：体型 ≥ 对方 ×1.1 才能整吞
const YAO_JI_LENG_QUE := 0.5  # 自动咬击冷却（秒，策划案 8.6.3）
const DI_TU_DA_XIAO := Vector2(4128, 2304)  # 3×3 拼图世界尺寸（3 × 1376, 3 × 768）
const ROU_KUAI_CHANGJING := preload("res://scenes/RouKuai.tscn")  # 鱼肉块蓝图
const DIAO_ROU_SHU := 2  # 受伤一次掉 2 块（伤害量的临时映射，TASK-012 调参）
const MEI_KUAI_ROU_TI_XING := 0.5  # 每块鱼肉默认携带的体型量（直接调 diao_rou 时的兜底）
const XIAO_HUA_SHI_CHANG := 3.0  # 消化一口要 3 秒：吞下去不等于拿到手（策划案 8.4 消化槽）
const TE_XIAO := preload("res://scripts/te_xiao.gd")  # 放电/中毒的一次性特效生成器

var fang_xiang := Vector2.ZERO  # 摇杆方向（单位向量），由 Main 每帧写入；零向量 = 松手
var dang_qian_jiao := 0.0  # 当前朝向角（弧度）：点可以瞬间改，朝向只能一点点拧
var dang_qian_su_du := 0.0  # 当前实际速度（像素/秒）：松手后平滑减到 0

@export var zhuanxiang_ji_su := 7.0  # 转向基准速率（弧度/秒）；实际速率 = 基准 ÷ √体型
@export var jia_su_du := 900.0  # 速度趋近目标值的加速度（像素/秒²）

var tixing: float:
	get:
		return ZhangBen.dang_qian_ti_xing  # 体型=当前血量：账本是唯一所有者，玩家不另存一份
var wudi := false  # 受伤后的短暂无敌标记
var bai_shi_jian := 0.0  # 摆尾相位时钟：游动时累积，驱动 sin 摆动
var zi_dong_yao_ji := true  # 自动咬击总闸：测试夹具关掉它，避免咬死布置好的靶鱼
var _yao_ji_leng_que := 0.0  # 咬击冷却剩余（秒）
var _xiao_hua: Array = []  # 消化队列：[{fen: 经验, sheng_yu: 剩余秒数, neng: 能力}]，先进先出
var xiao_hua_jin_du := 0.0  # 当前第一口的消化进度 0~1（HUD 只读）
var zhu_dong_leng_que := {}  # 主动冷却表：bian_hao(StringName) -> 剩余秒；各主动独立计时
var yin_shen := false  # 潜伏中：NPC 索敌跳过玩家（只影响感知，不影响判定）
var _su_du_bei_lv := 1.0  # 极速倍率：1.0 = 正常，2.0 = 双倍
var _su_du_sheng_yu := 0.0  # 极速剩余（秒）
var _chong_zhuang_sheng_yu := 0.0  # 冲撞剩余（秒）：>0 时走直线冲撞分支
var _chong_zhuang_fang := Vector2.ZERO  # 冲撞锁定方向（施放瞬间定死）
var _chong_zhuang_ming_zhong := {}  # 冲撞去重：instance_id -> true（每目标只结算一次）
var _chong_zhuang_su_du := 2.2  # 冲撞冲刺速度倍率（施放时从能力表读）
var _chong_zhuang_shang_hai := 2.0  # 冲撞伤害倍率（施放时从能力表读）
var _yin_shen_sheng_yu := 0.0  # 潜伏剩余（秒）
var _qian_fu_zhun_bei := false  # 潜伏下一口 ×2 已就绪
var _dian_ma_biao_xian := 0.0  # 放电闪蓝剩余（秒）：只做表现，不参与判定
var _ni_liu_sheng_yu := 0.0  # 逆流闪避剩余（秒）：>0 时无敌（shou_dao_yao_ji 直接挡下）
var _xuan_wo_sheng_yu := 0.0  # 漩涡剩余（秒）：吸卷周围 NPC
var _xuan_wo_ban_jing := 0.0  # 漩涡半径（施放时按当前档读表定死）
var _xuan_wo_la_li := 1.0  # 漩涡吸力（每拍 10 像素 × 吸力）
var _xuan_wo_ji_shi := 0.0  # 漩涡吸卷节拍（每 0.1 秒拉一把）
var _kuang_bao_sheng_yu := 0.0  # 狂暴撕咬剩余（秒）
var _kuang_bao_bei_lv := 1.0  # 狂暴咬伤倍率（施放时从能力表读）
var _bao_shi_sheng_yu := 0.0  # 暴食连锁窗口剩余（秒）：吞鱼后的下一口加成
var _bao_shi_bei_lv := 1.0  # 暴食咬伤倍率
var _lie_shou_ji_shi := 0.0  # 猎手直觉扫描节拍（每 0.5 秒扫一圈）
var _yu_jing_sheng_yu := 0.0  # 电感受器预警剩余（秒）：头顶"!"
var _yu_jing_biao: Label = null  # 预警标记（懒创建：第一次预警才 new，死后随节点释放）

@onready var zui_qu: Area2D = $ZuiQu  # 嘴圈（吃）：够大才吞——收益的唯一入口
@onready var yao_qu: Area2D = $YaoQu  # 咬击区（咬）：够 0.6 倍就能咬，把大鱼咬小再吞
@onready var shang_qu: Area2D = $ShangQu  # 伤区（伤）：对方 ≥ 我 ×1.1 才掉体型——代价的唯一入口
@onready var chi_qu: Area2D = $ChiQu  # 吸附区（磁吸）：只打标记，判定不归它管——分行为须分 Area2D
@onready var rou_qu: Area2D = $RouQu  # 鱼肉区（吃鱼肉）：只认 layer 4 的鱼肉块
@onready var wudi_dingshi: Timer = $WudiDingshi  # 无敌计时器


func _ready() -> void:
	# 形态必须在体型缩放之前应用：先改速度/嘴巴/转向与贴图，再按新等级算 scale
	var xing_tai := ZhangBen.dang_qian_xing_tai
	if xing_tai != null:
		ying_yong_xing_tai(xing_tai)
	dang_qian_jiao = 0.0  # 开局朝右（贴图默认方向）
	scale = _ti_xing_vector()  # 开局体型=开局血量：场景里的 scale 只是编辑器占位
	add_to_group("player")  # NPC 靠这个组找到玩家，判断自己是不是“红光可吃”
	$AnimatedSprite2D.play("you")  # 播 4 帧游动动画（场景里 autoplay 也开了，这里显式写清意图）
	zui_qu.area_entered.connect(_on_zui_qu_entered)
	shang_qu.area_entered.connect(_on_shang_qu_entered)
	chi_qu.area_entered.connect(_on_chi_qu_entered)
	chi_qu.area_exited.connect(_on_chi_qu_exited)
	wudi_dingshi.timeout.connect(_jiechu_wudi)
	# 只连 ti_xing_bian_hua：升级回满、受伤扣血、吃东西回血都会广播它——
	# 一个信号管全部“显示体型变了”，避免和 sheng_ji 两条 tween 抢同一个 scale
	ZhangBen.ti_xing_bian_hua.connect(_on_ti_xing_bian_hua)
	ZhangBen.si_wang.connect(_si_wang)  # 体型（血量）归零：切结算


func ying_yong_xing_tai(xing_tai: XingTai) -> void:
	# 应用形态数值与外观：速度/嘴巴/转向 + SpriteFrames
	# 根 scale 仍由体型决定（碰撞圈一起缩放），这里不碰 scale，也不用 modulate
	if xing_tai == null:
		return
	yidong_sudu = maxf(1.0, xing_tai.yi_dong_su_du)
	zui_ba = maxf(0.01, xing_tai.zui_ba)
	zhuanxiang_ji_su = maxf(0.1, xing_tai.zhuan_xiang_ji_su)
	if xing_tai.dong_hua != null:
		$AnimatedSprite2D.sprite_frames = xing_tai.dong_hua
		$AnimatedSprite2D.play("you")
	$AnimatedSprite2D.flip_h = false
	$AnimatedSprite2D.rotation = 0.0


func _ti_xing_vector() -> Vector2:
	# 体型→缩放向量：走账本的统一换算入口，玩家与 NPC 共用同一条曲线
	return Vector2.ONE * ZhangBen.ti_xing_dao_chi_du(tixing)


func _process(delta: float) -> void:
	_yao_ji_leng_que = maxf(0.0, _yao_ji_leng_que - delta)
	_zou_xiao_hua(delta)  # 消化槽照走：失控时肚子里的东西也在消化
	_geng_xin_zhu_dong(delta)  # 主动冷却/持续效果：失控也倒数，但失控会打断施放
	# 控制条满（电麻/毒晕）：任人宰割——不能游、不能咬、不能吃，只能挨打
	if ZhangBen.zai_kong_zhi():
		_qu_xiao_shi_fang()  # 失控打断极速/冲撞/隐身：醒来重新按键
		_kong_zhi_zhong(delta)
		return
	$AnimatedSprite2D.modulate = Color.WHITE  # 失控结束：恢复本色
	if _dian_ma_biao_xian > 0.0:
		$AnimatedSprite2D.modulate = Color(0.55, 0.85, 1.0)  # 放电闪蓝
	elif yin_shen:
		$AnimatedSprite2D.modulate.a = 0.45  # 潜伏半透明
	if _chong_zhuang_sheng_yu > 0.0:
		_chong_zhuang(delta)  # 冲撞分支：直线冲、撞一次结算一次，跳过嘴圈吞/自动咬
		return
	# 速度层：有方向就加速到 yidong_sudu（极速时 ×倍率），松手就平滑减到 0
	# 肾上腺（条件加速）与灵敏尾鳍满层追击在这里并进目标速度，走同一条 move_toward
	var mu_biao_su_du := yidong_sudu * _su_du_bei_lv if fang_xiang != Vector2.ZERO else 0.0
	mu_biao_su_du *= 1.0 + _shen_shang_xian_jia_su() \
			+ ZhangBen.bei_dong_fu_jia(&"ling_min_wei_qi", &"zhui_jia")
	dang_qian_su_du = move_toward(dang_qian_su_du, mu_biao_su_du, jia_su_du * delta)

	# 转向层：有输入才拧朝向；大鱼（tixing 大）拧得慢，小鱼灵活
	if fang_xiang != Vector2.ZERO:
		dang_qian_jiao = _zhuan_xiang(dang_qian_jiao, fang_xiang.angle(), delta)

	# 位移层：永远沿着"当前朝向"游，而不是直接朝摇杆方向瞬移
	if dang_qian_su_du > 0.1:
		position += Vector2.RIGHT.rotated(dang_qian_jiao) * dang_qian_su_du * delta
		_xian_zhi_zai_di_tu_nei()

	# 鱼头朝向当前朝向（贴图默认朝右，朝左时水平翻转）
	# 死区：纯上/下时 cos≈0，浮点符号会把鱼头甩向左边；|cos|<0.15 时保持上一帧朝向
	var heng_xiang := cos(dang_qian_jiao)
	if absf(heng_xiang) > 0.15:
		$AnimatedSprite2D.flip_h = heng_xiang < 0.0
	# 摆尾：sin 周期驱动，速度越快摆得越起劲；摆幅与体型反比（大鱼稳重）
	bai_shi_jian += delta
	var bai_fu := 0.12 / maxf(float(tixing), 0.2) * clampf(dang_qian_su_du / maxf(yidong_sudu, 1.0), 0.0, 1.0)
	$AnimatedSprite2D.rotation = sin(bai_shi_jian * 10.0) * bai_fu
	_chi_zui_bian()  # 每帧扫嘴圈：被咬小的鱼即使没出过嘴圈，也要能补吞
	if zi_dong_yao_ji and _yao_ji_leng_que <= 0.0 and _chong_zhuang_sheng_yu <= 0.0:
		_chang_shi_yao_ji()  # 咬击区里有咬得动的鱼：自动咬（0.5 秒一口）
	_chi_rou()  # 每帧查鱼肉区：鱼肉过保护期后即使原地重叠也能被吃（area_entered 不会再发一次）


func _kong_zhi_zhong(delta: float) -> void:
	# 失控表现：停住 + 发蓝 + 小幅抽搐（玩家一眼知道“现在动不了”）
	dang_qian_su_du = 0.0
	bai_shi_jian += delta
	$AnimatedSprite2D.modulate = Color(0.65, 0.8, 1.0)
	$AnimatedSprite2D.rotation = sin(bai_shi_jian * 30.0) * 0.05


func _zou_xiao_hua(delta: float) -> void:
	# 消化槽：先进先出，一口 3 秒；消化完才把经验记进账本
	# 消化中死亡 → 队列跟着玩家节点消失，经验白吞（策划案 8.4：死亡损失消化中的猎物）
	# 大胃王：每层 +15% 消化速度 → 有效时长 ÷(1+加成)，其余规则原样
	if _xiao_hua.is_empty():
		xiao_hua_jin_du = 0.0
		return
	var shi_chang := XIAO_HUA_SHI_CHANG / (1.0 + ZhangBen.bei_dong_zhi(&"da_wei_wang"))
	var dang_qian: Dictionary = _xiao_hua[0]
	dang_qian["sheng_yu"] = float(dang_qian["sheng_yu"]) - delta
	if float(dang_qian["sheng_yu"]) <= 0.0:
		_xiao_hua.pop_front()
		# 先记食谱再发经验：本次消化触发的升级弹窗已经能看到最新“最常吃”
		var neng = dang_qian.get("neng")
		if neng is NengLi:
			ZhangBen.ji_chi_yu(neng)
		if int(dang_qian["fen"]) > 0:
			ZhangBen.jia_jing_yan(int(dang_qian["fen"]))
		xiao_hua_jin_du = 0.0
		if not _xiao_hua.is_empty():
			_xiao_hua[0]["sheng_yu"] = shi_chang  # 下一口从满时长开始，不吃上一口的余数
		return
	xiao_hua_jin_du = clampf(1.0 - float(dang_qian["sheng_yu"]) / shi_chang, 0.0, 1.0)


func _geng_xin_zhu_dong(delta: float) -> void:
	# 主动能力时钟：冷却、极速、冲撞、潜伏都在这里倒数
	# 失控时也照样倒数（控 2 秒不该白赚 2 秒冷却），但失控会调 _qu_xiao_shi_fang 打断效果
	# 冷却表逐条倒数（归零保留条目不 erase：容量最多 4 项，len_que_sheng 缺项按 0 算不受影响）
	for bian_hao in zhu_dong_leng_que:
		zhu_dong_leng_que[bian_hao] = maxf(0.0, float(zhu_dong_leng_que[bian_hao]) - delta)
	_dian_ma_biao_xian = maxf(0.0, _dian_ma_biao_xian - delta)
	if _su_du_sheng_yu > 0.0:
		_su_du_sheng_yu = maxf(0.0, _su_du_sheng_yu - delta)
		if _su_du_sheng_yu <= 0.0:
			_su_du_bei_lv = 1.0
	if _chong_zhuang_sheng_yu > 0.0:
		_chong_zhuang_sheng_yu = maxf(0.0, _chong_zhuang_sheng_yu - delta)
		if _chong_zhuang_sheng_yu <= 0.0:
			$AnimatedSprite2D.rotation = 0.0
	if _yin_shen_sheng_yu > 0.0:
		_yin_shen_sheng_yu = maxf(0.0, _yin_shen_sheng_yu - delta)
		if _yin_shen_sheng_yu <= 0.0:
			_jie_chu_yin_shen()
	_zeng_yi_shi_chang(delta)  # 通用能力池：逆流/漩涡/狂暴/暴食/预警的倒计时与漩涡吸卷
	_lie_shou_sao_miao(delta)  # 猎手直觉：节拍扫描高亮（失控也照扫，纯表现不参与判定）


func _zeng_yi_shi_chang(delta: float) -> void:
	# 通用能力池的持续状态时钟：逆流无敌 / 漩涡吸卷 / 狂暴窗口 / 暴食窗口 / 电感受器预警
	if _ni_liu_sheng_yu > 0.0:
		_ni_liu_sheng_yu = maxf(0.0, _ni_liu_sheng_yu - delta)
	if _xuan_wo_sheng_yu > 0.0:
		_xuan_wo_sheng_yu = maxf(0.0, _xuan_wo_sheng_yu - delta)
		_xuan_wo_ji_shi -= delta
		if _xuan_wo_ji_shi <= 0.0:
			_xuan_wo_ji_shi = 0.1  # 每 0.1 秒拉一把：10 像素/拍 ≈ 100 像素/秒的向心流速
			for node in get_tree().get_nodes_in_group("yu_npc"):
				var yu_npc := node as YuNpc
				if yu_npc == null or yu_npc.si_le:
					continue
				var cha := global_position - yu_npc.global_position
				if cha.length() <= _xuan_wo_ban_jing:
					yu_npc.tui_kai(cha.normalized(), 10.0 * _xuan_wo_la_li)
					yu_npc.ding_zhu(0.4)  # 被卷住：反应延迟拉满，不索敌、不转头
	if _kuang_bao_sheng_yu > 0.0:
		_kuang_bao_sheng_yu = maxf(0.0, _kuang_bao_sheng_yu - delta)
		if _kuang_bao_sheng_yu <= 0.0:
			_kuang_bao_bei_lv = 1.0
	if _bao_shi_sheng_yu > 0.0:
		_bao_shi_sheng_yu = maxf(0.0, _bao_shi_sheng_yu - delta)
		if _bao_shi_sheng_yu <= 0.0:
			_bao_shi_bei_lv = 1.0
	if _yu_jing_sheng_yu > 0.0:
		_yu_jing_sheng_yu = maxf(0.0, _yu_jing_sheng_yu - delta)
		if _yu_jing_sheng_yu <= 0.0 and _yu_jing_biao != null:
			_yu_jing_biao.visible = false


func _lie_shou_sao_miao(delta: float) -> void:
	# 猎手直觉：每 0.5 秒扫一圈，范围（260 像素 ×(1+层数加成)）内的 NPC 泛黄高亮
	# 玩家侧没有"感知半径"属性，策划案接线约定以 260 为基准（与路人鱼 gan_zhi 同值）
	_lie_shou_ji_shi -= delta
	if _lie_shou_ji_shi > 0.0:
		return
	_lie_shou_ji_shi = 0.5
	var jia := ZhangBen.bei_dong_zhi(&"lie_shou_zhi_jue")
	if jia <= 0.0:
		return
	var ju := 260.0 * (1.0 + jia)
	for node in get_tree().get_nodes_in_group("yu_npc"):
		var yu_npc := node as YuNpc
		if yu_npc != null and not yu_npc.si_le \
				and global_position.distance_to(yu_npc.global_position) <= ju:
			yu_npc.shi_fang_gao_liang(0.6)


func _qu_xiao_shi_fang() -> void:
	# 取消当前施放（切换主动 / 失控）：只清效果，不动冷却
	# 不碰 _dian_ma_biao_xian：那只是闪蓝表现，清不清都不影响判定
	_su_du_bei_lv = 1.0
	_su_du_sheng_yu = 0.0
	_chong_zhuang_sheng_yu = 0.0
	_chong_zhuang_ming_zhong.clear()
	_ni_liu_sheng_yu = 0.0  # 逆流无敌窗一并掐掉：失控里白嫖无敌太脏
	_xuan_wo_sheng_yu = 0.0
	_kuang_bao_sheng_yu = 0.0
	_kuang_bao_bei_lv = 1.0
	$AnimatedSprite2D.rotation = 0.0
	_jie_chu_yin_shen()


func _jie_chu_yin_shen() -> void:
	# 破隐：被咬 / 咬中 / 到期 / 切换主动都走这里；本就没潜伏时什么也不做
	if not yin_shen and _yin_shen_sheng_yu <= 0.0 and not _qian_fu_zhun_bei:
		return
	yin_shen = false
	_yin_shen_sheng_yu = 0.0
	_qian_fu_zhun_bei = false
	$AnimatedSprite2D.modulate.a = 1.0


func _zheng_zai_shi_fang() -> bool:
	# 施放中：技能按钮据此变灰；冲撞期间还要屏蔽嘴圈吞/自动咬
	# 通用能力池的持续型主动（逆流/漩涡/狂暴）与极速/冲撞/潜伏同规则互斥
	return _su_du_sheng_yu > 0.0 or _chong_zhuang_sheng_yu > 0.0 or _yin_shen_sheng_yu > 0.0 \
			or _ni_liu_sheng_yu > 0.0 or _xuan_wo_sheng_yu > 0.0 or _kuang_bao_sheng_yu > 0.0


func leng_que_sheng(bian_hao: StringName) -> float:
	# 冷却剩余读数：缺项按 0（就绪）算——没释放过的能力天生就绪；技能按钮和测试统一走它
	return float(zhu_dong_leng_que.get(bian_hao, 0.0))


func shi_fang_zhu_dong(neng: NengLi) -> bool:
	# 主动能力唯一释放入口：按传入能力分派（按钮 bind 序号回查、测试直传）；成功才进它自己的冷却
	# 不做无参版本：无参就得定义「默认释放谁」——那是新的隐性状态，宁可让调用方显式传
	if neng == null or not neng.shi_zhu_dong():
		return false
	if ZhangBen.zai_kong_zhi() or _zheng_zai_shi_fang():
		return false  # 失控 / 正在施放：任何主动都按不动（极速/冲撞同时开会互相干扰速度）
	if leng_que_sheng(neng.bian_hao) > 0.0:
		return false  # 该能力自己的冷却：各主动独立计时
	var dang := maxi(ZhangBen.dang_qian_zhu_dong_dang(neng.bian_hao), 1)  # 当前档位：升档改数值与冷却
	match neng.bian_hao:
		&"fang_dian_ma_bi":
			_shi_fang_fang_dian(neng)
		&"ji_su_tu_jin":
			_shi_fang_ji_su(neng)
		&"man_li_chong_zhuang":
			_shi_fang_chong_zhuang(neng)
		&"qian_fu_tu_xi":
			_shi_fang_qian_fu(neng)
		&"yu_lei_chong_ci":
			_shi_fang_chong_zhuang(neng)  # 鱼雷冲刺与蛮力冲撞同构：走同一分支，数值各看各的表
		&"ni_liu_shan_bi":
			_shi_fang_ni_liu(neng, dang)
		&"xuan_wo":
			_shi_fang_xuan_wo(neng, dang)
		&"yu_ni_dan":
			_shi_fang_yu_ni(neng, dang)
		&"kuang_bao_si_yao":
			_shi_fang_kuang_bao(neng, dang)
		&"sheng_na_mai_chong":
			_shi_fang_sheng_na(neng, dang)
		_:
			return false
	YinXiang.fang(&"fang_neng_li")  # 能力起手音：按钮按下去立刻有反馈
	zhu_dong_leng_que[neng.bian_hao] = neng.dang_zhi(&"leng_que", dang)  # 冷却也按当前档读表
	return true


func _shi_fang_fang_dian(neng: NengLi) -> void:
	# 放电麻痹：以玩家为圆心，半径内所有 NPC 叠电麻条；主值 100 = 一次满条 → 失控 2 秒
	# 只打别人，不电自己——玩家的电鳐能力是猎人技能
	for node in get_tree().get_nodes_in_group("yu_npc"):
		var yu_npc := node as YuNpc
		if yu_npc == null or yu_npc.si_le:
			continue
		if global_position.distance_to(yu_npc.global_position) <= neng.ban_jing:
			yu_npc.jia_dian_ma(neng.shu_zhi)
	_dian_ma_biao_xian = 0.15  # 闪蓝 0.15 秒（表现层，_process 里读）
	TE_XIAO.fang_dian(get_parent(), global_position)


func _shi_fang_ji_su(neng: NengLi) -> void:
	# 极速突进：0.8 秒内目标速度 ×2；转向仍按体型，不锁方向
	_su_du_bei_lv = maxf(1.0, neng.shu_zhi)
	_su_du_sheng_yu = maxf(0.01, neng.chi_xu)
	if fang_xiang != Vector2.ZERO:
		dang_qian_su_du = maxf(dang_qian_su_du, yidong_sudu * _su_du_bei_lv)


func _shi_fang_chong_zhuang(neng: NengLi) -> void:
	# 蛮力冲撞：锁死施放瞬间的方向，0.45 秒直线冲刺；每目标只撞一次，不整吞
	var fang := fang_xiang
	if fang == Vector2.ZERO:
		fang = Vector2.RIGHT.rotated(dang_qian_jiao)  # 没按摇杆：沿当前朝向冲
	_chong_zhuang_fang = fang.normalized()
	_chong_zhuang_su_du = maxf(1.0, neng.fu_shu_zhi)
	_chong_zhuang_shang_hai = maxf(0.0, neng.shu_zhi)
	_chong_zhuang_sheng_yu = maxf(0.01, neng.chi_xu)
	_chong_zhuang_ming_zhong.clear()
	dang_qian_jiao = _chong_zhuang_fang.angle()
	if absf(_chong_zhuang_fang.x) > 0.05:
		$AnimatedSprite2D.flip_h = _chong_zhuang_fang.x < 0.0


func _shi_fang_qian_fu(neng: NengLi) -> void:
	# 潜伏突袭：2 秒隐身 + 下一口 ×2；破隐时机 = 咬中 / 受伤 / 到期
	yin_shen = true
	_yin_shen_sheng_yu = maxf(0.01, neng.chi_xu)
	_qian_fu_zhun_bei = true
	$AnimatedSprite2D.modulate.a = 0.45


func _shi_fang_ni_liu(neng: NengLi, dang: int) -> void:
	# 逆流闪避：短无敌窗（档 2 起加长）；档 3（shu_zhi 覆写 ≥ 1）把身边的鱼推开一段
	_ni_liu_sheng_yu = maxf(0.01, neng.dang_zhi(&"chi_xu", dang))
	if neng.dang_zhi(&"shu_zhi", dang) >= 1.0:
		for node in get_tree().get_nodes_in_group("yu_npc"):
			var yu_npc := node as YuNpc
			if yu_npc == null or yu_npc.si_le:
				continue
			var cha := yu_npc.global_position - global_position
			if cha.length() > neng.ban_jing:
				continue
			if cha.length_squared() < 0.001:
				cha = Vector2.RIGHT.rotated(randf() * TAU)  # 完全重叠：随机方向弹开
			yu_npc.tui_kai(cha.normalized(), 130.0)


func _shi_fang_xuan_wo(neng: NengLi, dang: int) -> void:
	# 漩涡：以自身为涡心，持续把半径内的 NPC 往里卷（吸卷节奏见 _zeng_yi_shi_chang）
	_xuan_wo_ban_jing = neng.dang_zhi(&"ban_jing", dang)
	_xuan_wo_la_li = maxf(0.1, neng.shu_zhi)
	_xuan_wo_ji_shi = 0.0  # 第一拍立刻拉
	_xuan_wo_sheng_yu = maxf(0.01, neng.chi_xu)
	TE_XIAO.fang_dian(get_parent(), global_position, 1.6)  # 大号电圈当涡纹：复用现有特效


func _shi_fang_yu_ni(neng: NengLi, dang: int) -> void:
	# 淤泥弹：朝朝向前方丢一团淤泥雾——雾里 NPC 感知打折（YuNiWu 自带寿命，到点自散）
	var fang := fang_xiang
	if fang == Vector2.ZERO:
		fang = Vector2.RIGHT.rotated(dang_qian_jiao)
	var wu := YuNiWu.new()
	wu.ban_jing = neng.ban_jing
	wu.gan_zhi_xi_shu = neng.shu_zhi
	wu.shi_chang = neng.dang_zhi(&"chi_xu", dang)
	wu.wan_jia_yin_bi = neng.dang_zhi(&"yin_bi", dang)  # 档 3 才有：雾里玩家可见度再打折
	wu.position = global_position + fang.normalized() * 150.0
	TE_XIAO.zhong_du(get_parent(), wu.position, 1.5)  # 落点一团墨绿：告诉玩家雾在哪
	if Engine.is_in_physics_frame():
		get_parent().add_child.call_deferred(wu)  # 物理帧里加节点要推迟（同掉肉的处理）
	else:
		get_parent().add_child(wu)


func _shi_fang_kuang_bao(neng: NengLi, dang: int) -> void:
	# 狂暴撕咬：窗口期内自动咬击全部按倍率结算（档 2 起窗口加长）
	_kuang_bao_bei_lv = maxf(1.0, neng.shu_zhi)
	_kuang_bao_sheng_yu = maxf(0.01, neng.dang_zhi(&"chi_xu", dang))


func _shi_fang_sheng_na(neng: NengLi, dang: int) -> void:
	# 声呐脉冲：半径内 NPC 全部泛黄高亮（简化版：不做致命区单独描边）；
	# 档 3 起附赠定身 1 秒（复用 NPC 反应延迟通道——定身里不索敌、不转头）
	for node in get_tree().get_nodes_in_group("yu_npc"):
		var yu_npc := node as YuNpc
		if yu_npc == null or yu_npc.si_le:
			continue
		if global_position.distance_to(yu_npc.global_position) > neng.ban_jing:
			continue
		yu_npc.shi_fang_gao_liang(neng.dang_zhi(&"chi_xu", dang))
		if dang >= 3:
			yu_npc.ding_zhu(neng.dang_zhi(&"shu_zhi", dang))
	TE_XIAO.fang_dian(get_parent(), global_position, 2.0)  # 最大号电圈当声呐波纹


func _chong_zhuang(delta: float) -> void:
	# 冲撞分支：直接位移（不经过转向层），撞到谁就算一次伤害
	position += _chong_zhuang_fang * yidong_sudu * _chong_zhuang_su_du * delta
	_xian_zhi_zai_di_tu_nei()
	if absf(_chong_zhuang_fang.x) > 0.05:
		$AnimatedSprite2D.flip_h = _chong_zhuang_fang.x < 0.0
	bai_shi_jian += delta
	$AnimatedSprite2D.rotation = sin(bai_shi_jian * 20.0) * 0.04
	var shang_hai := ZhanDou.yao_ji_shang_hai(tixing, zui_ba) * _chong_zhuang_shang_hai
	for qu in yao_qu.get_overlapping_areas():
		var mu := qu.get_parent() as Node2D
		if mu == null or not is_instance_valid(mu):
			continue
		if not mu.has_method("shou_dao_yao_ji") or mu.get("si_le") == true:
			continue
		var jian := mu.get_instance_id()
		if _chong_zhuang_ming_zhong.has(jian):
			continue  # 同一目标冲撞期间只结算一次
		_chong_zhuang_ming_zhong[jian] = true
		mu.call("shou_dao_yao_ji", shang_hai, self, "shen")


func _zhao_bei_dong(bian_hao: StringName) -> NengLi:
	# 从本局获得历史里反查被动 Resource（层数账本只存 id，数值仍由 Resource 提供）
	for neng in ZhangBen.yi_xuan_neng_li:
		if neng != null and neng.bian_hao == bian_hao:
			return neng
	return null


func _chi_rou() -> void:
	# 吃可食物：鱼肉与海草/珊瑚同一入口（策划案 8.1「任何鱼可进食」+ 第十章可食用植物）
	for qu in rou_qu.get_overlapping_areas():
		var wu := qu as KeChiWu
		if wu != null and wu.ke_chi:
			# 食腐者：吃鱼肉块经验加成 50/100/150%；先记账再退场：bei_chi 之后节点可能已释放
			ZhangBen.jia_jing_yan(int(round(float(wu.jing_yan) * (1.0 + ZhangBen.bei_dong_zhi(&"shi_fu_zhe")))))
			# 体型恢复只认“肉”：鱼肉按自身携带的体型 ÷1.5 回血；植物 ti_xing_liang=0，只给经验/饥饿
			if wu.ti_xing_liang > 0.0:
				ZhangBen.hui_ti_xing(ZhangBen.chi_wu_hui_ti_xing(wu.ti_xing_liang))
			ZhangBen.hui_ji_e(wu.ji_e)  # 回饥饿：植物/鱼肉都是「双给」的一部分
			var fu_jia := ZhangBen.bei_dong_fu_jia(&"shi_fu_zhe", &"ji_e")
			if fu_jia > 0.0:
				ZhangBen.hui_ji_e(fu_jia)  # 食腐者满层附加：腐肉额外垫 3 点饥饿
			YinXiang.fang(&"chi")  # 吃植物/鱼肉也走吞吃音：同一个动作同一种反馈
			wu.bei_chi()


func _zhuan_xiang(dang_qian: float, mu_biao: float, delta: float) -> float:
	# 朝目标角一点点拧过去：差角取最短方向（避免绕远路），每帧步长 = 转向速率 × delta
	# 除的是 √体型而不是体型：线性太惩罚——Lv.8 会慢到转不动；开根号让小鱼跟手、大鱼仍显笨重
	# 灵敏尾鳍：每层 +15% 转向速率（大鱼也能灵活一点）
	var cha := wrapf(mu_biao - dang_qian, -PI, PI)
	var wei_qi := 1.0 + ZhangBen.bei_dong_zhi(&"ling_min_wei_qi")
	var bu_chang := (zhuanxiang_ji_su * wei_qi / sqrt(maxf(float(tixing), 1.0))) * delta
	return dang_qian + clampf(cha, -bu_chang, bu_chang)


func _xian_zhi_zai_di_tu_nei() -> void:
	# 别游出九宫格大地图：留 30 像素边距（约半个鱼身），相机 limit 会跟着夹住视野
	var bian_ju := 30.0
	position.x = clampf(position.x, bian_ju, DI_TU_DA_XIAO.x - bian_ju)
	position.y = clampf(position.y, bian_ju, DI_TU_DA_XIAO.y - bian_ju)


func _on_zui_qu_entered(_qu: Area2D) -> void:
	# 闯进嘴圈：只管吃（收益的唯一入口）。比我大的进嘴圈直接无视——掉血归伤区管
	if _chong_zhuang_sheng_yu > 0.0:
		return  # 冲撞期间不整吞：撞击伤害由 _chong_zhuang 单独结算
	_chi_zui_bian()  # 立刻扫一遍；每帧的兜底扫描见 _process


func _chi_zui_bian() -> void:
	# 嘴圈里够大的鱼就吞：每帧扫一次，不只是 area_entered——
	# “把大鱼咬小再吃掉”时鱼一直在嘴圈里，不会再发第二次 area_entered
	if _chong_zhuang_sheng_yu > 0.0:
		return
	for qu in zui_qu.get_overlapping_areas():
		var yu_npc := qu.get_parent() as YuNpc
		if yu_npc == null or not is_instance_valid(yu_npc) or yu_npc.si_le:
			continue
		if yu_npc.get("shi_boss") == true:
			continue  # 首领只能咬死，不能整吞（鲸鲨要打到残血才算击败）
		# 吞噬门槛：我要比它大 10% 才吞得下；同体型/略大略小都吞不动（咬击带，TASK-012 兑现）
		if tixing >= yu_npc.tixing * TUN_CHI_BEI_LV:
			_chi_diao(yu_npc)
			_tun_chi_maichong()  # 吞吃反馈：玩家轻弹一下


func _chi_diao(yu_npc: YuNpc) -> void:
	# 吃掉一条鱼：回体型/回饥饿立即生效；经验先进消化槽，3 秒后才入账（策划案 8.4）
	# 吞下去 ≠ 拿到手——消化中死亡，这一口就白吞了
	# 能力也走同一条消化槽：消化完成才记进“本局食谱”，冲撞/放电击杀不算
	var dui_fang_ti_xing := yu_npc.tixing
	var fen := 0
	var neng: NengLi = null
	if yu_npc.yu_zhong != null:
		fen = int(yu_npc.yu_zhong.fenzhi)
		neng = yu_npc.yu_zhong.neng_li
	yu_npc.bei_chi(false, self)  # 经验由消化槽结算；毒鱼会把毒传给吞它的人
	_bao_shi_chu_fa()  # 暴食连锁：吞下鱼就刷新加成窗口（经验走消化槽，加成先到手）
	ZhangBen.hui_ti_xing(ZhangBen.chi_wu_hui_ti_xing(dui_fang_ti_xing))  # 吃进多大的鱼就 ÷1.5 回血
	ZhangBen.hui_ji_e(ZhangBen.chi_yu_hui_ji_e(dui_fang_ti_xing))  # 回饥饿：路人鱼最顶饱
	if fen > 0 or neng != null:
		_xiao_hua.append({"fen": fen, "sheng_yu": XIAO_HUA_SHI_CHANG, "neng": neng})
	YinXiang.fang(&"chi")  # 吞吃音：反馈要跟嘴合上，等消化到账再响就晚了


func _chang_shi_yao_ji() -> void:
	# 自动咬击：咬击区里挑最近的、咬得动的目标；咬头且体型够大 → 直接带走
	var mu_biao := _yao_ji_mu_biao()
	if mu_biao == null:
		return
	_yao_ji_leng_que = YAO_JI_LENG_QUE  # 有目标才进冷却：空挥不计时
	YinXiang.fang(&"yao")  # 咬击音跟冷却同一时机：有声的一口才算真咬
	var bu := _zui_jin_bu_wei(mu_biao)
	var mu_ti_xing := float(mu_biao.get("tixing"))
	if bu == "zhi_ming" and ZhanDou.zhi_ming_ke_sha(tixing, mu_ti_xing):
		var yu_mu := mu_biao as YuNpc
		# 首领不可整吞（鲸鲨要咬到残血、机器船要打沉），只有普通鱼才走吞食分支
		if yu_mu != null and yu_mu.get("shi_boss") != true:
			_jie_chu_yin_shen()  # 整吞也算“咬中”：潜伏状态消耗掉，不把 ×2 留到下一次
			_chi_diao(yu_mu)
			_tun_chi_maichong()
			return
	# 鸭子类型：鱼和机器船都接这一口；部位参数给分部位伤害用（船：玻璃舱 ×3）
	var shang_hai := ZhanDou.yao_ji_shang_hai(tixing, zui_ba)
	if _qian_fu_zhun_bei and ZhangBen.zhuang_lei(&"qian_fu_tu_xi"):
		# 潜伏下一口 ×2：双保险——_qian_fu_zhun_bei 管时机，账本管「确实还装备着它」
		shang_hai *= ZhangBen.zhao_zhu_dong(&"qian_fu_tu_xi").shu_zhi
		_jie_chu_yin_shen()
	if _kuang_bao_sheng_yu > 0.0:
		shang_hai *= _kuang_bao_bei_lv  # 狂暴撕咬：窗口内每一口都按倍率结算
	if _bao_shi_sheng_yu > 0.0:
		shang_hai *= _bao_shi_bei_lv  # 暴食连锁：刚吞完鱼的下一口加倍
	mu_biao.call("shou_dao_yao_ji", shang_hai, self, bu)
	_yao_ji_lian_dong(mu_biao, shang_hai)  # 咬击落定后的被动联动：毒腺上毒 / 撕裂齿掉肉


func _yao_ji_lian_dong(mu_biao: Node2D, shang_hai: float) -> void:
	# 咬击结算后的被动联动：只对 NPC 生效（咬机器船不掉肉、不上毒）
	var yu_npc := mu_biao as YuNpc
	if yu_npc == null or yu_npc.si_le:
		return
	# 毒腺：咬中带毒，目标叠毒晕条（20/25/45——满层质变写档位表覆写）
	var du_ceng := ZhangBen.dang_qian_bei_dong_ceng(&"du_xian")
	if du_ceng > 0:
		var du_neng := ZhangBen.zhao_bei_dong(&"du_xian")
		if du_neng != null:
			yu_npc.jia_du_yun(ZhangBen.bei_dong_zhi(&"du_xian"))
			TE_XIAO.zhong_du(get_parent(), yu_npc.global_position, 0.4)
	# 撕裂齿：咬中撕下肉块（块数 = 主值四舍五入：2/3/3——每块肉带 咬伤÷块数 的体型）
	var lie_ceng := ZhangBen.dang_qian_bei_dong_ceng(&"si_lie_chi")
	if lie_ceng > 0:
		var lie_neng := ZhangBen.zhao_bei_dong(&"si_lie_chi")
		if lie_neng != null:
			var kuai := int(round(lie_neng.ceng_shu_zhi(lie_ceng)))
			yu_npc.diao_rou(kuai, shang_hai / maxf(float(kuai), 1.0))


func _shen_shang_xian_jia_su() -> float:
	# 肾上腺：当前体型 ≤ 上限 30% 时，每层 +30% 速度（0.3/0.6/0.9）
	# 满层附加：饥饿 ≤ 30（dang_biao.ji_e_yu）也触发——绝境里多一条活路
	var jia := ZhangBen.bei_dong_zhi(&"shen_shang_xian")
	if jia <= 0.0:
		return 0.0
	var chu_fa := tixing <= ZhangBen.ti_xing_shang_xian() * 0.3
	if not chu_fa:
		var yu := ZhangBen.bei_dong_fu_jia(&"shen_shang_xian", &"ji_e_yu")
		chu_fa = yu > 0.0 and ZhangBen.ji_e <= yu
	return jia if chu_fa else 0.0


func shi_fang_yu_jing() -> void:
	# 电感受器（被动）：NPC 把玩家锁定为目标时被叫到——头顶"!"预警（时长 0.5/0.75/1.0 秒）
	# 简化版：不做反应延迟减免，只给"背后有鱼盯上我"的信息
	var shi_chang := ZhangBen.bei_dong_zhi(&"dian_gan_shou_qi")
	if shi_chang <= 0.0:
		return
	_yu_jing_sheng_yu = maxf(_yu_jing_sheng_yu, shi_chang)
	if _yu_jing_biao == null:
		_yu_jing_biao = Label.new()
		_yu_jing_biao.text = "!"
		_yu_jing_biao.position = Vector2(-8.0, -92.0)
		_yu_jing_biao.add_theme_font_size_override("font_size", 30)
		_yu_jing_biao.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		add_child(_yu_jing_biao)
	_yu_jing_biao.visible = true


func _bao_shi_chu_fa() -> void:
	# 暴食连锁：吞下整鱼 → 窗口期内下一口咬伤 ×2（档 3 窗口 5 秒，重复吞刷新时长）
	var ceng := ZhangBen.dang_qian_bei_dong_ceng(&"bao_shi_lian_suo")
	if ceng <= 0:
		return
	var neng := ZhangBen.zhao_bei_dong(&"bao_shi_lian_suo")
	if neng == null:
		return
	_bao_shi_bei_lv = maxf(1.0, neng.shu_zhi)
	_bao_shi_sheng_yu = maxf(_bao_shi_sheng_yu, neng.dang_zhi(&"chi_xu", ceng))


func _yao_ji_mu_biao() -> Node2D:
	# 咬击区里最近的可咬目标：鱼、鲸鲨、机器船——只要会 shou_dao_yao_ji / qu_dian
	# 不写死 as YuNpc：机器船不继承鱼，但玩家该能用同一套咬击打它（鸭子类型）
	var zui_jin: Node2D = null
	var zui_jin_ju := INF
	for qu in yao_qu.get_overlapping_areas():
		var mu := qu.get_parent() as Node2D
		if mu == null or not is_instance_valid(mu):
			continue
		if not mu.has_method("shou_dao_yao_ji") or not mu.has_method("qu_dian"):
			continue  # 将来的水雷、道具不一定是可咬目标：只认契约，不认类型
		if mu.get("si_le") == true:
			continue
		var ju := global_position.distance_squared_to(mu.global_position)
		if ju < zui_jin_ju:
			zui_jin_ju = ju
			zui_jin = mu
	return zui_jin


func _zui_jin_bu_wei(mu_biao: Node2D) -> String:
	# 锁最近的部位：鱼嘴 / 头部致命区 / 身体中心（船：玻璃舱 / 船体）
	var zui_jin := "shen"
	var zui_jin_ju := INF
	for bu in ["zui", "zhi_ming", "shen"]:
		var dian: Vector2 = mu_biao.call("qu_dian", bu)
		var ju := global_position.distance_squared_to(dian)
		if ju < zui_jin_ju:
			zui_jin_ju = ju
			zui_jin = bu
	return zui_jin


func _on_shang_qu_entered(qu: Area2D) -> void:
	# 闯进伤区：只管掉体型（代价的唯一入口）。吃逻辑已移嘴圈；无敌期内跳过，不重复伤
	var yu_npc := qu.get_parent() as YuNpc
	if yu_npc == null:
		return  # 不是鱼群（将来可能有别的区域闯进来），直接忽略
	# 对方要大到能吞我（它 ≥ 我 ×1.1）才伤得到；中间带同样无事发生
	if yu_npc.tixing >= tixing * TUN_CHI_BEI_LV and not wudi:
		# 接触伤害按攻击者体型算：(0.15×它的体型+0.05)×它的嘴巴系数——撞大鱼比撞小鱼疼
		# 传来源：毒棘护体要反毒给撞上来的鱼（和咬击走同一条入口）
		shou_dao_yao_ji(ZhanDou.yao_ji_shang_hai(yu_npc.tixing, yu_npc.zui_ba), yu_npc, "shen")


func _on_chi_qu_entered(qu: Area2D) -> void:
	# 小鱼游进吸附大圈：只给它打标记，路让它自己走（设计决策 1A：NPC 自决）
	var yu_npc := qu.get_parent() as YuNpc
	if yu_npc != null and tixing > yu_npc.tixing:
		yu_npc.bei_xi = self  # 打得过的小鱼才吸；大鱼不吸


func _on_chi_qu_exited(qu: Area2D) -> void:
	# 游出吸附圈：放手（不吸一辈子）
	var yu_npc := qu.get_parent() as YuNpc
	if yu_npc != null:
		yu_npc.bei_xi = null


func _shoushang(shang_hai: float = 1.0) -> void:
	# 受伤统一入口：闪红 + 无敌 + 扣当前体型（血量）；默认 1.0 是接触伤害（策划案 8.6.3）
	# 等级（体型上限）不动——被打只觉得鱼变小了，不会掉级、更不会因为掉级丢进度
	# 软鳞：减伤 8/16/36%（满层质变写档位表覆写）——先减再扣，掉肉也按实扣的量折算
	var lin := ZhangBen.bei_dong_zhi(&"ruan_lin")
	if lin > 0.0:
		shang_hai *= 1.0 - clampf(lin / 100.0, 0.0, 0.9)
	wudi = true
	modulate = Color(1.0, 0.4, 0.4)  # 闪红示警
	wudi_dingshi.start()
	YinXiang.fang(&"shou_shang")  # 受伤音：闪红和声音同一帧，反馈才对得上
	ZhangBen.shou_shang(shang_hai)  # 账本扣血 → ti_xing_bian_hua → 平滑缩小；归零时账本广播 si_wang
	if ZhangBen.dang_qian_ti_xing > 0.0:
		# 掉肉按伤害折算：1 点伤害 = 2 块（策划案 8.6.3）；轻咬不掉，免得满地是肉
		var rou_shu := int(round(shang_hai * float(DIAO_ROU_SHU)))
		if rou_shu > 0:
			# 每块肉带 伤害÷块数 的体型：捡回来也要 ÷1.5 折算，不能靠掉肉回满
			diao_rou(rou_shu, shang_hai / float(rou_shu))


func shou_dao_yao_ji(shang_hai: float, lai_yuan = null, _bu := "shen") -> void:
	# 被咬一口 / 被大鱼撞到：先反毒（毒棘护体），再走同一条受伤流程
	# lai_yuan/_bu 有默认值：机器船等旧调用方仍可单参调用；_bu 预留给分部位反应
	if wudi or _ni_liu_sheng_yu > 0.0:
		return  # 无敌：受伤后的短暂无敌 / 逆流闪避窗口都从这里挡下
	# 毒棘护体：被动层数从账本读，数值从能力表读；咬我的人叠毒晕条
	# 反毒放在扣血之前：即使这一口把我咬死，对方也得中毒（高风险食物的定位）
	var ceng := ZhangBen.dang_qian_bei_dong_ceng(&"du_ji_hu_ti")
	if ceng > 0 and lai_yuan != null and is_instance_valid(lai_yuan) \
			and lai_yuan.has_method("jia_du_yun"):
		var neng := _zhao_bei_dong(&"du_ji_hu_ti")
		if neng != null:
			lai_yuan.jia_du_yun(neng.ceng_shu_zhi(ceng))
			TE_XIAO.zhong_du(get_parent(), global_position)  # 毒棘反弹：让玩家看到“这一口带毒”
	# 硬鳞反击：这一口的部分伤害弹回攻击者（20/25/30%）
	# 反伤也走 shou_dao_yao_ji：NPC 那边会闪红记仇——“打了反而更凶”是设计的一部分
	var fan := ZhangBen.bei_dong_zhi(&"ying_lin_fan_ji")
	if fan > 0.0 and lai_yuan != null and is_instance_valid(lai_yuan) \
			and lai_yuan != self and lai_yuan.has_method("shou_dao_yao_ji"):
		lai_yuan.shou_dao_yao_ji(shang_hai * fan, self)
	_jie_chu_yin_shen()  # 受伤破隐：潜伏的 ×2 不留给下一次
	_shoushang(shang_hai)


func jia_dian_ma(liang: float) -> void:
	# 被电鳐电到：只记进账本（玩家不自己存控制条，HUD 与失控判定都读账本）
	ZhangBen.jia_dian_ma(liang)
	TE_XIAO.fang_dian(get_parent(), global_position, 0.5)  # 小号电圈：告诉玩家“你被电了”


func jia_du_yun(liang: float) -> void:
	# 被蓑鲉毒到（被它咬 / 吞了它）：同样记进账本
	ZhangBen.jia_du_yun(liang)
	TE_XIAO.zhong_du(get_parent(), global_position, 0.4)  # 小号毒雾：中毒反馈


func diao_rou(shu: int, mei_kuai_ti_xing := MEI_KUAI_ROU_TI_XING) -> void:
	# 掉鱼肉：往四周随机方向弹出去，避免和受伤者叠在一起被秒吃
	for i in range(shu):
		var rou: RouKuai = ROU_KUAI_CHANGJING.instantiate()
		rou.ti_xing_liang = mei_kuai_ti_xing  # 每块肉携带的体型量：吃回来时 ÷1.5
		var jiao := randf_range(0.0, TAU)
		rou.position = position + Vector2(cos(jiao), sin(jiao)) * randf_range(46.0, 58.0)
		rou.position.x = clampf(rou.position.x, 40.0, DI_TU_DA_XIAO.x - 40.0)
		rou.position.y = clampf(rou.position.y, 40.0, DI_TU_DA_XIAO.y - 40.0)
		# 受伤信号来自物理查询刷新期间，此时直接 add_child(Area2D) 会报
		# "Can't change this state while flushing queries"——物理帧里必须延迟到空闲帧
		if Engine.is_in_physics_frame():
			get_parent().add_child.call_deferred(rou)
		else:
			get_parent().add_child(rou)  # 挂到场景层，不跟玩家一起移动/缩放


func _si_wang() -> void:
	# 体型跌破死亡线：切结算页。change_scene_to_file 整场景销毁重建——
	# Main 全树（玩家 buff/bei_xi 标记/鱼群/弹窗）就地释放，账本（Autoload）常驻带走数据
	get_tree().change_scene_to_file("res://scenes/JieSuan.tscn")


func _jiechu_wudi() -> void:
	wudi = false
	modulate = Color.WHITE  # 恢复原色


func _on_ti_xing_bian_hua(_dang_qian: float, _shang_xian: float) -> void:
	# 显示体型变了（升级回满 / 受伤变小 / 吃东西回血）：账本已是新值，显示层 Tween 追过去
	# 0.25 秒——受伤要立刻看得见“我变小了”，回血也别慢吞吞
	var tween := create_tween()
	tween.tween_property(self, "scale", _ti_xing_vector(), 0.25).set_ease(Tween.EASE_OUT)


func _tun_chi_maichong() -> void:
	# 吞吃瞬间脉冲：链式两段——先快速弹大 8%，再回弹到真实体型（每次都以 tixing 收尾，不漂移）
	var tween := create_tween()
	tween.tween_property(self, "scale", _ti_xing_vector() * 1.08, 0.08)
	tween.tween_property(self, "scale", _ti_xing_vector(), 0.12)
