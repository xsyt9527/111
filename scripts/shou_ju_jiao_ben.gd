extends Node
# C 首局 10 分钟节奏脚本（2026-11-08 交接文档）
# 只在第一局生效：存档 0 胜 + 首局脚本未执行过。教学事件全部用预排布 NPC，
# 不改 YuQun 的刷怪系统；脚本自己只负责「到点生成一条被标记的鱼/弹一句字幕」。
# 时间轴：0:00 正常小鱼 → 首次升级高亮 → 1:00 追不上人的中型鱼 → 2:00 刚好可吞的同级鱼
# → 3:00 远处黑影 → 4:00 水域收缩字幕 → 5:30 咬尾巴三口的大鱼 → 8:00 机械船警报
# → 8:30 入场（本局人类战整体推迟 30 秒）。

const YU_NPC_CHANGJING := preload("res://scenes/YuNpc.tscn")
const SHU_ZHI := preload("res://scripts/shu_zhi.gd")
const ZHONG_XIAO := preload("res://data/yuzhong/lan_yu.tres")  # 钻光鱼：小型路人
const ZHONG_YU := preload("res://data/yuzhong/hong_yu.tres")  # 铜眼鱼：中型追猎
const DA_YU := preload("res://data/yuzhong/zong_yu.tres")  # 大眼金枪鱼：黑影/尾巴大鱼

var zhu_chang: Node = null  # Main：生成 NPC、弹字幕都走它
var yu: Yu = null  # 玩家：所有教学鱼围绕玩家当前位置预排布
var _yi_dan := {}  # 事件 key → 已执行（一次性）
var _deng_dai_liang := false  # 首次升级后等技能按钮出现再高亮
var _liang_guo := false
var _wu_shi_zhi_xing := false  # 事件全部按本局时钟推进；结算后自动停


func kai_shi(zhu: Node) -> void:
	zhu_chang = zhu
	yu = zhu.get_node_or_null("Yu") as Yu
	if yu == null:
		return
	ZhangBen.sheng_ji.connect(_on_sheng_ji)


func _process(_delta: float) -> void:
	if zhu_chang == null or not is_instance_valid(zhu_chang) or yu == null:
		return
	var t := ZhangBen.ju_nei_shi_jian
	# 首次升级 → 高亮新技能按钮 2 秒（按钮由 NengLiUI 动态生成，等它出现）
	if _deng_dai_liang and not _liang_guo:
		var ui := zhu_chang.get_node_or_null("NengLiUI")
		if ui != null and ui.get("_an_niu_zu") != null and (ui.get("_an_niu_zu") as Array).size() > 0:
			ui.call("shan_liang_di_yi_ge", 2.0)
			_deng_dai_liang = false
			_liang_guo = true
	if _dao(t, 60.0, "zhui"):
		_biao_ji_yi_zhi_xing()
		_sheng_jiao_xue(ZHONG_YU, yu.tixing * 1.05, 140.0, Vector2(-620, 80), false)
		_xian_shi("小心：一条中型鱼盯上你了——游起来，它追不上你")
	if _dao(t, 120.0, "ke_tun"):
		_sheng_jiao_xue(ZHONG_XIAO, yu.tixing / SHU_ZHI.TUN_CHI_BEI_LV, 90.0, Vector2(560, -60), true)
		_xian_shi("这条鱼刚好比你小 1.1 倍——撞上去，整口吞下")
	if _dao(t, 180.0, "hei_ying"):
		_sheng_jiao_xue(DA_YU, yu.tixing * 2.5, 60.0, Vector2(-760, -160), true)
		_xian_shi("阴影里有更大的东西游过……它没看见你")
	if _dao(t, 240.0, "shou_suo"):
		_xian_shi("水域正在收缩")
	if _dao(t, 330.0, "wei_ba"):
		_sheng_jiao_xue(DA_YU, yu.tixing * 1.2, 110.0, Vector2(-420, 60), true)
		_xian_shi("大鱼的尾巴露出来了——咬它三口，体型掉下来就能吞")
	if _dao(t, 480.0, "jing_bao"):
		YinXiang.fang(&"jing_bao")
		_xian_shi("低频警报：机械船正在接近")


func _on_sheng_ji(_xin_deng_ji: int) -> void:
	# 第一次升级：记下「等按钮出现再高亮」，不是所有形态开局都带主动技
	if not _liang_guo and not _deng_dai_liang:
		_deng_dai_liang = true


func _dao(shi_jian: float, shi_jian_dian: float, key: String) -> bool:
	# 一次性时间点判定：本局时钟过了阈值且从未触发 → 触发并记账
	if shi_jian < shi_jian_dian or _yi_dan.has(key):
		return false
	_yi_dan[key] = true
	return true


func _sheng_jiao_xue(zhong: YuZhong, ti_xing: float, su_du: float,
		pian_yi: Vector2, wu_shi: bool) -> YuNpc:
	# 预排布一条教学 NPC：位置按玩家当前位置偏移；体型/速度/AI 在本条上覆写
	var xin_yu: YuNpc = YU_NPC_CHANGJING.instantiate()
	xin_yu.yu_zhong = zhong
	xin_yu.position = yu.global_position + pian_yi
	xin_yu.fangxiang = 1.0 if pian_yi.x > 0.0 else -1.0
	zhu_chang.add_child(xin_yu)  # 先入树：_ready 会用鱼种默认值初始化
	# _ready 之后覆写：体型是局部变量，不会自动跟着 gan_zhi 变化，必须一起改
	xin_yu.tixing = maxf(0.5, ti_xing)
	xin_yu.tixing_chu_shi = xin_yu.tixing
	xin_yu.sudu = su_du
	xin_yu.gan_zhi = xin_yu.tixing * SHU_ZHI.NPC_GAN_ZHI_MEI_TI
	xin_yu.jiao_xue_wu_shi = wu_shi
	if wu_shi:
		xin_yu.gong_ji_yu_wang = false  # 教学猎物不反击
	return xin_yu


func _biao_ji_yi_zhi_xing() -> void:
	# 第一局脚本跑过就不再重跑（跨启动失效）；同局人类战按 C 表 8:30 入场
	if not _wu_shi_zhi_xing:
		_wu_shi_zhi_xing = true
		CunDang.biao_ji_shou_ju_jiao_ben()
		ZhangBen.ren_lei_yan_chi = 30.0


func _xian_shi(wen: String) -> void:
	# 字幕走 Main 的大事件横幅：不新做 UI，和机器船预告共用一条
	if zhu_chang != null and is_instance_valid(zhu_chang):
		zhu_chang.call("_xian_shi_xiao_xi", wen)
