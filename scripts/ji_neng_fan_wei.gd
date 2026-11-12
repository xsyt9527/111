extends Node2D
# 主动技能「长按看范围」指示层：由 neng_li_ui.gd 懒创建，挂在世界层（玩家父节点下）
# 三类技能与画法：
#   范围型：以玩家为圆心的淡红圆，半径 = 技能当前档的 ban_jing（世界像素）
#   突进型：玩家朝向前方的淡红扇形 + 箭头，长度 = ban_jing（没有就用 320），张角约 35°
#   自身型：玩家周围的小淡红圆，半径 = ban_jing（没有就用 70）
# 颜色：填充 Color(1, 0.3, 0.3, 0.32)，描边同色 alpha 0.8
# 层级：z_index = 4，挂世界层；半透明不遮鱼，且所有 CanvasLayer UI 都在它上面
# 暂停：节点设为 Always 是为了在暂停瞬间自己藏起来（NengLiUI 是 Pausable，暂停后不再跑）

enum FanWeiLeiXing { FAN_WEI, TU_JIN, ZI_SHEN }

# 范围型：圆心在玩家、按半径画整圆
const FAN_WEI_BIAO := [
	&"fang_dian_ma_bi",
	&"xuan_wo",
	&"sheng_na_mai_chong",
	&"yu_ni_dan",
	&"ruo_dian_dong_cha",
	&"dian_mai_chong",
	&"you_er_qi_pao",
]
# 突进型：朝向前方的扇形 + 箭头
const TU_JIN_BIAO := [
	&"yu_lei_chong_ci",
	&"chang_mao_chuan_ci",
	&"man_li_chong_zhuang",
	&"ji_su_tu_jin",
]
# 自身增益型：玩家身边的小圆
const ZI_SHEN_BIAO := [
	&"kuang_bao_si_yao",
	&"ni_liu_shan_bi",
	&"qian_fu_tu_xi",
	&"ying_ke_hu_ti",
	&"xue_xing_kuang_re",
]

const TIAN_CHONG_SE := Color(1.0, 0.3, 0.3, 0.32)  # 填充：淡红半透明
const MIAO_BIAN_SE := Color(1.0, 0.3, 0.3, 0.8)   # 描边：同色更高不透明度

const MO_REN_FAN_WEI := 120.0  # 范围型 ban_jing 为 0 时的兜底半径
const MO_REN_TU_JIN := 320.0   # 突进型 ban_jing 为 0 时的兜底长度
const MO_REN_ZI_SHEN := 70.0   # 自身型 ban_jing 为 0 时的兜底半径
const TU_JIN_JIAO_DU := 35.0   # 突进扇形总张角（度）
const YUAN_HU_DIAN_SHU := 96   # 整圆描边段数：半径 640 也不出棱角
const SHAN_XING_DIAN_SHU := 28 # 扇形弧线分段数

var _neng: NengLi = null           # 当前显示范围对应技能（空 = 无）
var _lei_xing := FanWeiLeiXing.FAN_WEI  # 当前画法
var _ban_jing := 0.0               # 当前半径/长度（世界像素）
var _fang_xiang := Vector2.RIGHT   # 突进型朝向（单位向量）


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # 暂停时也要醒来把指示藏掉
	z_index = 4  # 鱼群/玩家上方，CanvasLayer UI 下方
	visible = false


func _process(_delta: float) -> void:
	# 暂停、弹窗、切场景时绝不留在画面上；继续游戏由 NengLiUI 重新长按触发
	if not visible:
		return
	if get_tree().paused:
		yin_cang()


func xian_shi(neng: NengLi, zhong_xin: Vector2, fang_xiang: Vector2, wan_jia: Yu = null) -> void:
	# 显示某个主动技能的作用范围：圆心=玩家当前位置，朝向=玩家当前朝向
	# TASK-019：优先用玩家实例的 ji_neng_ban_jing，保证「显示圈」与「实际命中半径」同一入口
	if neng == null:
		yin_cang()
		return
	_neng = neng
	_lei_xing = _pan_lei_xing(neng.bian_hao)
	_ban_jing = _qu_ban_jing(neng, wan_jia)
	if fang_xiang.length_squared() > 0.0001:
		_fang_xiang = fang_xiang.normalized()
	else:
		_fang_xiang = Vector2.RIGHT
	global_position = zhong_xin
	visible = true
	queue_redraw()


func yin_cang() -> void:
	# 松手/暂停/释放技能时立即收起；重复调用无副作用
	if not visible and _neng == null:
		return
	visible = false
	_neng = null
	queue_redraw()


func _pan_lei_xing(bian_hao: StringName) -> FanWeiLeiXing:
	# 技能 id → 三类画法；未知主动按自身型小圆兜底，至少给玩家一个范围反馈
	if bian_hao in FAN_WEI_BIAO:
		return FanWeiLeiXing.FAN_WEI
	if bian_hao in TU_JIN_BIAO:
		return FanWeiLeiXing.TU_JIN
	if bian_hao in ZI_SHEN_BIAO:
		return FanWeiLeiXing.ZI_SHEN
	return FanWeiLeiXing.ZI_SHEN


func _qu_ban_jing(neng: NengLi, wan_jia: Yu = null) -> float:
	# 取当前档位的实际半径；TASK-019 起优先走玩家唯一入口（身位/固定像素/体长下限全在里面）
	# 兜底：本节点由 neng_li_ui 懒创建并挂在玩家父节点（Main）下，父节点里有兄弟节点 "Yu"。
	# 这样旧调用不传 wan_jia 也能取到玩家；纯逻辑测试没有玩家时仍退回旧 ban_jing 口径。
	var dang := maxi(ZhangBen.dang_qian_zhu_dong_dang(neng.bian_hao), 1)
	var zui_xiao_bei := 1.5 if _lei_xing == FanWeiLeiXing.TU_JIN else 0.5
	var wan := wan_jia
	if wan == null:
		var fu := get_parent()
		if fu != null:
			wan = fu.get_node_or_null("Yu") as Yu
	if wan != null:
		return wan.ji_neng_ban_jing(neng, dang, zui_xiao_bei)
	var ban := neng.dang_zhi(&"ban_jing", dang)
	if ban <= 0.0:
		ban = neng.ban_jing
	if ban > 0.0:
		return ban
	match _lei_xing:
		FanWeiLeiXing.TU_JIN:
			return MO_REN_TU_JIN
		FanWeiLeiXing.ZI_SHEN:
			return MO_REN_ZI_SHEN
		_:
			return MO_REN_FAN_WEI


func _draw() -> void:
	if _neng == null:
		return
	match _lei_xing:
		FanWeiLeiXing.FAN_WEI:
			_hua_yuan(_ban_jing)
		FanWeiLeiXing.TU_JIN:
			_hua_shan_xing()
		FanWeiLeiXing.ZI_SHEN:
			_hua_yuan(_ban_jing)


func _hua_yuan(ban_jing: float) -> void:
	# 范围型/自身型：淡红实心圆 + 同色描边
	draw_circle(Vector2.ZERO, ban_jing, TIAN_CHONG_SE)
	draw_arc(Vector2.ZERO, ban_jing, 0.0, TAU, YUAN_HU_DIAN_SHU, MIAO_BIAN_SE, 2.0, true)


func _hua_shan_xing() -> void:
	# 突进型：以朝向为中线的扇形，圆心出发的箭头指出冲刺正方向
	var ban_jiao := deg_to_rad(TU_JIN_JIAO_DU) * 0.5
	var d := _fang_xiang.normalized()

	# 扇形填充（含圆心，形成实心扇面）
	var mian := PackedVector2Array([Vector2.ZERO])
	for k in SHAN_XING_DIAN_SHU + 1:
		var jiao := -ban_jiao + (2.0 * ban_jiao) * float(k) / float(SHAN_XING_DIAN_SHU)
		mian.append(d.rotated(jiao) * _ban_jing)
	draw_colored_polygon(mian, TIAN_CHONG_SE)

	# 两侧直边 + 外弧描边
	draw_line(Vector2.ZERO, d.rotated(-ban_jiao) * _ban_jing, MIAO_BIAN_SE, 2.0, true)
	draw_line(Vector2.ZERO, d.rotated(ban_jiao) * _ban_jing, MIAO_BIAN_SE, 2.0, true)
	var hu := PackedVector2Array()
	for k in SHAN_XING_DIAN_SHU + 1:
		var jiao := -ban_jiao + (2.0 * ban_jiao) * float(k) / float(SHAN_XING_DIAN_SHU)
		hu.append(d.rotated(jiao) * _ban_jing)
	draw_polyline(hu, MIAO_BIAN_SE, 2.0, true)

	# 中线箭头：杆 + 两片箭头翼，长度跟随 ban_jing（短距离也不会翻出扇面）
	var jian_tou := d * _ban_jing
	var gan_chang := minf(36.0, _ban_jing * 0.25)
	var wei := d * maxf(0.0, _ban_jing - 46.0)
	var ce := d.orthogonal() * 18.0
	draw_line(d * gan_chang, jian_tou, MIAO_BIAN_SE, 3.0, true)
	draw_line(jian_tou, wei + ce, MIAO_BIAN_SE, 3.0, true)
	draw_line(jian_tou, wei - ce, MIAO_BIAN_SE, 3.0, true)
