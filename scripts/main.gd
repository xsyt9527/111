extends Node2D
# 主场景协调者：读摇杆方向，交给玩家鱼（输入层与运动层分离）
# 同时负责 3×3 大地图：相机跟随玩家，按玩家位置显示当前区域名

const DI_TU_MEI_GE := Vector2(1376.0, 768.0)  # 3×3 拼图单格尺寸（源图原生 1376×768）
const DI_TU_CHI_CUN := Vector2(4128.0, 2304.0)  # 整图尺寸：只用于全图相机，不重切美术
const FANG_JIAN_JIN_BIAO_LIU := 6.0  # 换房后夹到新房内 6px：避免站在边界反复触发
const FANG_JIAN_HUAN_CHU_SHI_JIAN := 0.12  # 单程淡入/淡出时长：黑场总计约 0.24 秒
const HUAN_FANG_WU_DI_SHI_JIAN := 0.9  # 换房入场免伤时长：淡入 0.12 秒内也不可被咬
const REN_LEI_QUAN_TU_OFFSET := Vector2(0.0, -260.0)  # 人类战相机上移：机器船在玩家上方 600px
const REN_LEI_QUAN_TU_ZOOM := 0.85  # 人类战取景放宽：能看到船与预警圈
const QUAN_TU_LIMIT := Rect2(Vector2.ZERO, DI_TU_CHI_CUN)  # 人类战/九图演出的全图 limit
const SHI_JIAO_MEI_JI := 0.0  # TASK-019：固定探索镜头 1.0 倍，体型增长不再被镜头拉远抵消
const SHI_JIAO_FENG_DING := 2.0  # 可见范围最多拉到 2 倍（保留旧上限语义；当前系数为 0 时恒 1.0）
const SHI_JIAO_FENG_DING_JI := 10  # Lv.10 封顶：等级无上限，镜头必须有上限，否则地图会缩成一点
const JI_QI_CHUAN_CHANGJING := preload("res://scenes/JiQiChuan.tscn")  # 人类战 Boss 蓝图
const DI_TU_PIN_JIE_YAN_CHU := preload("res://scripts/di_tu_pin_jie_yan_chu.gd")  # 人类战九图拼合演出（1A+2A）
const HUD_CENG_MING := [
	"JingYanTiao", "TiXingUI", "JiEUI", "XiaoHuaUI", "KongZhiUI",
	"ShiJianUI", "BossUI", "XiaoXiUI", "UI", "NengLiUI", "XiaoDiTuUI",
]  # 演出期间要藏的 HUD 层：名字固定，漏一个就会在超级视角里露出读数
const SHU_ZHI := preload("res://scripts/shu_zhi.gd")  # A 核心数值表
const SHOU_JU_JIAO_BEN := preload("res://scripts/shou_ju_jiao_ben.gd")  # C 首局 10 分钟节奏脚本
const YU_NPC_CHANGJING := preload("res://scenes/YuNpc.tscn")  # 鱼骨架：首领也用同一套
const FEN_YU := preload("res://data/yuzhong/fen_yu.tres")  # 鲸鲨鱼种（shi_boss = true）
const BOOS_CHU_SHENG_DIAN := Vector2(3440.0, 1920.0)  # 东南 · 远古祭坛地宫中心
const BOOS_XUN_LUO_DIAN := [
	Vector2(3000.0, 1750.0),  # 东南房间 8 内：左上
	Vector2(3850.0, 1750.0),  # 右上
	Vector2(3850.0, 2100.0),  # 右下
	Vector2(3000.0, 2100.0),  # 左下
]  # 首领只在东南祭坛房间内巡逻，不再跨九格
const BOOS_TI_SHI_SHI_JIAN := 360.0  # 第 6 分钟起提示巨影位置：给玩家留 2 分钟去挑战（首领四处游荡，位置现查）
const DI_TU_MING := [
	"西北 · 沉船锚链悬崖",
	"中北 · 微光珊瑚悬崖",
	"东北 · 浮空遗迹钟楼",
	"西侧 · 古沉船荧光溶洞",
	"正中 · 核心海山交汇大殿",
	"东侧 · 远古遗迹荧光森林",
	"西南 · 沉船宝库深渊",
	"中南 · 幽光晶洞深谷",
	"东南 · 远古祭坛地宫",
]  # 行优先：左上→中上→右上→左中→正中→右中→左下→中下→右下

@onready var yu: Yu = $Yu  # 玩家鱼实例
@onready var yu_qun: YuQun = $YuQun  # 鱼群生成器：决战期由 Main 通知停刷（只停新增，不清存量）
@onready var yao_gan: YaoGan = $UI/YaoGan  # 虚拟摇杆（只给方向，不给速度）
@onready var ti_xing_label: Label = $TiXingUI/TiXingLabel  # 体型数字（替代退役的血条）
@onready var ji_e_label: Label = $JiEUI/JiELabel  # 饥饿数字：低于 20 变红示警
@onready var ji_e_tiao: ProgressBar = $JiEUI/JiETiao  # 饥饿条
@onready var xiao_hua_label: Label = $XiaoHuaUI/XiaoHuaLabel  # 消化槽读数
@onready var xiao_hua_tiao: ProgressBar = $XiaoHuaUI/XiaoHuaTiao  # 消化槽进度条
@onready var kong_zhi_label: Label = $KongZhiUI/KongZhiLabel  # 电麻/毒晕读数（失控时变红）
@onready var dian_ma_tiao: ProgressBar = $KongZhiUI/DianMaTiao  # 电麻条
@onready var du_yun_tiao: ProgressBar = $KongZhiUI/DuYunTiao  # 毒晕条
@onready var camera: Camera2D = $Camera2D  # 3×3 大地图相机：跟着玩家走，边界夹在地图内
@onready var shi_jian_label: Label = $ShiJianUI/ShiJianLabel  # 局内倒计时（经验条下方）
@onready var boss_label: Label = $BossUI/BossLabel  # Boss 名称（人类战才显示）
@onready var boss_tiao: ProgressBar = $BossUI/BossTiao  # Boss 血条
@onready var xiao_xi_label: Label = $XiaoXiUI/XiaoXiLabel  # 大事件横幅（降临/体型不足）
var ji_qi_chuan: JiQiChuan = null  # 人类战机器船：生成后 Main 持有，胜利判定与血条都读它
var _jing_sha: YuNpc = null  # 祭坛首领（鲸鲨）：8 分钟内打到残血 → 机器船提前降临
var _yi_ti_shi_boos := false  # 第 6 分钟的巨影位置提示只弹一次
var yan_chu_zhong := false  # 九图拼合演出期间：锁输入 + 不吃不发招 + 暂不接管相机
var tou_ding_xue_tiao: Node2D = null  # 玩家头顶体型血条（演出时一起藏）
var dang_qian_fang_jian := 4  # 当前房间：0..8，行优先；开局正中
var _qie_huan_zhong := false  # 换房过渡中：锁移动，禁止再次触发
var _zhe_hei: ColorRect = null  # 全屏黑幕：运行时建在独立 CanvasLayer，不改 Main.tscn 层级


func _ready() -> void:
	# 相机先对准玩家再开平滑，避免开局从 (0,0) 滑过来
	camera.global_position = yu.global_position
	camera.reset_smoothing()
	camera.zoom = Vector2.ONE / _shi_jiao_bei()  # 首帧就按开局等级取景，避免 Lv.1 电鳗镜头跳变
	dian_ma_tiao.modulate = Color(1.0, 0.85, 0.35)  # 电麻条：黄（只染色，不改主题）
	du_yun_tiao.modulate = Color(0.55, 1.0, 0.45)   # 毒晕条：绿
	_shua_tiao_yang_se(boss_tiao, Color(0.92, 0.22, 0.22))  # Boss（机器船）血条：红
	_shua_tiao_yang_se(ji_e_tiao, Color(0.95, 0.82, 0.25))  # 饥饿条：黄
	_gua_tou_ding_xue_tiao()  # 玩家头顶体型血条（红，跟随体型掉血）
	# 终局时间轴：阶段切换由账本广播，Main 只负责“演出”（生成船、横幅、切结算页）
	ZhangBen.jie_duan_gai_bian.connect(_on_jie_duan_gai_bian)
	ZhangBen.ju_jie_shu.connect(_on_ju_jie_shu)
	YinXiang.bo_bgm(&"tan_suo")  # 局内探索曲：从选择页的深海摇篮切过来
	# E2：把跨局隐藏压力修正交给鱼群（只影响刷怪节奏/数量，不碰玩家数值与能力池）
	yu_qun.ya_li_xiu_zheng = CunDang.ya_li_xiu_zheng
	# C：首局教学时间轴（只第一局；后续局不挂脚本，零额外开销）
	if CunDang.shi_fou_shou_ju():
		var jiao_ben := SHOU_JU_JIAO_BEN.new()
		jiao_ben.name = "ShouJuJiaoBen"
		add_child(jiao_ben)
		jiao_ben.kai_shi(self)
	_sheng_cheng_jing_sha()
	# TASK-020：首帧前把当前房间、相机 limit、黑幕和鱼群都收窄到开局房间（正中 4）
	dang_qian_fang_jian = qu_yu_pian(yu.global_position)
	_suo_fang_jian(dang_qian_fang_jian)
	camera.global_position = yu.global_position
	camera.reset_smoothing()
	_chuang_jian_hei_mu()
	yu_qun.qie_huan_fang_jian(fang_jian_qu(dang_qian_fang_jian))


func _shua_tiao_yang_se(tiao: ProgressBar, tian_se: Color) -> void:
	# 进度条配色：深色圆角底槽 + 指定填充色（运行时覆写默认主题，不进场景文件）
	var di := StyleBoxFlat.new()
	di.bg_color = Color(0.1, 0.13, 0.18, 0.9)
	di.set_corner_radius_all(4)
	var tian := StyleBoxFlat.new()
	tian.bg_color = tian_se
	tian.set_corner_radius_all(4)
	tiao.add_theme_stylebox_override("background", di)
	tiao.add_theme_stylebox_override("fill", tian)


func _gua_tou_ding_xue_tiao() -> void:
	# 玩家头顶体型血条：top_level 脱离鱼的体型缩放，屏幕恒定大小；随体型（血量）掉红条
	var tiao = Node2D.new()
	tiao.set_script(load("res://scripts/tou_ding_xue_tiao.gd"))
	tiao.mu_biao = yu
	tiao.top_level = true
	tiao.z_index = 100
	add_child(tiao)
	tou_ding_xue_tiao = tiao


func _process(_delta: float) -> void:
	# 每帧只转发方向：转多快、游多快由鱼按体型自己算，Main 不掺和运动细节
	# 九图演出期间强制零输入：玩家鱼自己也会在 _process 里提前返回
	yu.fang_xiang = Vector2.ZERO if (yan_chu_zhong or _qie_huan_zhong) else _du_qu_fang_xiang()
	# 等级由经验条的 DengJiLabel 显示；这里只报当前体型（血量）/上限，受伤回血一眼可见
	ti_xing_label.text = "体型 %.1f/%.1f" % [ZhangBen.dang_qian_ti_xing, ZhangBen.ti_xing_shang_xian()]
	# 饥饿：账本每帧扣，这里只读不写；低于 20 变红，提醒“该找东西吃了”
	ji_e_tiao.value = ZhangBen.ji_e
	ji_e_label.text = "饥饿 %d/%d" % [int(ZhangBen.ji_e), int(ZhangBen.JI_E_SHANG_XIAN)]
	ji_e_label.modulate = Color(1.0, 0.45, 0.45) if ZhangBen.ji_e < 20.0 else Color.WHITE
	# 消化槽：第一口的进度；肚子里没东西就不显示百分比
	if yu.xiao_hua_jin_du > 0.0:
		xiao_hua_tiao.value = yu.xiao_hua_jin_du * 100.0
		xiao_hua_label.text = "消化 %d%%" % int(yu.xiao_hua_jin_du * 100.0)
	else:
		xiao_hua_tiao.value = 0.0
		xiao_hua_label.text = "消化 —"
	# 控制条：电麻/毒晕读数；失控时整行变红 + 倒计时（此刻不能游、不能咬）
	dian_ma_tiao.value = ZhangBen.dian_ma
	du_yun_tiao.value = ZhangBen.du_yun
	if ZhangBen.zai_kong_zhi():
		kong_zhi_label.text = "失控！%.1f 秒" % ZhangBen.yun_xuan_ji_shi
		kong_zhi_label.modulate = Color(1.0, 0.45, 0.45)
	else:
		kong_zhi_label.text = "电麻 %d  毒晕 %d" % [int(ZhangBen.dian_ma), int(ZhangBen.du_yun)]
		kong_zhi_label.modulate = Color.WHITE
	# 相机跟随玩家；普通探索时 limit 锁当前房间，人类战临时切全图取景
	# 演出期间相机由 DiTuPinJieYanChu 接管，这里不要再每帧抢回来
	if not yan_chu_zhong:
		camera.global_position = yu.global_position
		if _zai_ren_lei_zhan():
			camera.offset = REN_LEI_QUAN_TU_OFFSET
			camera.zoom = Vector2.ONE * REN_LEI_QUAN_TU_ZOOM
		else:
			camera.offset = Vector2.ZERO
			# 普通探索（含船沉后的收尾）恢复当前房间 limit：把人类战借用的全图取景归还
			_suo_fang_jian(dang_qian_fang_jian)
			# 镜头拉远：等级越高看得越远（范围 ×(1+0.1×等级)，Lv.10 封顶 2.0×）
			# Camera2D.zoom 是放大倍数，>1 看得更少；范围 ×N 等价于 zoom ÷N
			camera.zoom = Vector2.ONE / _shi_jiao_bei()
		# 普通探索才查越界；换房过渡中或船战期间不重复触发
		if not _qie_huan_zhong and not _zai_ren_lei_zhan():
			var pian := qu_yu_pian(yu.global_position)
			if pian != dang_qian_fang_jian:
				_qie_huan_fang_jian(pian)
	_geng_xin_zhong_ju_hud()


func _geng_xin_zhong_ju_hud() -> void:
	# 终局 HUD：倒计时 + Boss 血条——只读账本与船节点，不反写状态
	var sheng_yu := ZhangBen.sheng_yu_shi_jian()
	var qian_zhui := "人类战 " if ZhangBen.jie_duan == ZhangBen.JieDuan.REN_LEI_ZHAN else "剩余 "
	shi_jian_label.text = qian_zhui + ZhangBen.ge_shi_shi_jian(sheng_yu)
	# 最后 60 秒变红：不用看数字也知道要收尾了
	shi_jian_label.modulate = Color(1.0, 0.45, 0.45) if sheng_yu <= 60.0 else Color.WHITE
	var you_chuan := is_instance_valid(ji_qi_chuan) and not ji_qi_chuan.si_le
	boss_label.visible = you_chuan
	boss_tiao.visible = you_chuan
	if you_chuan:
		boss_tiao.max_value = ji_qi_chuan.zui_da_xue
		boss_tiao.value = ji_qi_chuan.xue
		boss_label.text = "机器船 %d/%d" % [int(ji_qi_chuan.xue), int(ji_qi_chuan.zui_da_xue)]
	# 第 6 分钟给一次指引：鲸鲨还活着就告诉玩家东南有“提前开战”的机会
	if not _yi_ti_shi_boos and is_instance_valid(_jing_sha) and not _jing_sha.si_le \
			and ZhangBen.ju_nei_shi_jian >= BOOS_TI_SHI_SHI_JIAN:
		_yi_ti_shi_boos = true
		# 首领已固定盘踞东南房间：提示用“盘踞”，不再说它到处游荡
		_xian_shi_xiao_xi("巨影盘踞在 %s" % qu_yu_ming(_jing_sha.global_position))


func _sheng_cheng_jing_sha() -> void:
	# 祭坛首领：和普通鱼共用 YuNpc 场景，靠鱼种表的 shi_boss 标记身份
	# 四处巡逻、不随鱼群刷新、不被出屏回收——玩家得在地图上找它（或等它巡过来）
	_jing_sha = YU_NPC_CHANGJING.instantiate()
	_jing_sha.yu_zhong = FEN_YU
	_jing_sha.position = BOOS_CHU_SHENG_DIAN
	_jing_sha.xun_luo_dian.assign(BOOS_XUN_LUO_DIAN)  # 四个巡逻点：注入给首领 AI
	_jing_sha.sudu = 60.0  # 巡逻游得慢：玩家能绕到它侧面；追击速度另算（YuNpc 常量）
	# TASK-021：首领只在自己房间索敌/追击，禁止跨房贴脸
	_jing_sha.xian_ding_qu = fang_jian_qu(8)
	add_child(_jing_sha)
	_jing_sha.bei_ji_bai.connect(_on_jing_sha_bei_ji_bai)


func _on_jing_sha_bei_ji_bai() -> void:
	# 8 分钟内打残鲸鲨 = 提前开战奖励；体型不够就只给提示，船照常第 8 分钟来
	_jing_sha = null
	if ZhangBen.ti_qian_kai_zhan():
		_xian_shi_xiao_xi("鲸鲨败退！机器船提前降临！")
	elif ZhangBen.jie_duan == ZhangBen.JieDuan.ZHENG_CHANG:
		_xian_shi_xiao_xi("鲸鲨败退，但体型不足 Lv.%d——机器船仍会准时到来" % ZhangBen.TIQIAN_DENG_JI)


func _on_jie_duan_gai_bian(xin_jie_duan: int) -> void:
	# 账本宣布进入人类战：先放九图拼合演出（1A+2A），演完再生成真正的机器船
	if xin_jie_duan == ZhangBen.JieDuan.REN_LEI_ZHAN:
		_bo_fang_ren_lei_yan_chu()


func _bo_fang_ren_lei_yan_chu() -> void:
	# 演出入口：锁玩家、藏 HUD、藏整张背景，交给 DiTuPinJieYanChu 自己跑时间轴
	if yan_chu_zhong or is_instance_valid(ji_qi_chuan):
		return
	yan_chu_zhong = true
	_suo_quan_tu()  # 九图演出要 zoom 到全图：先解除房间 limit，避免相机被裁在当前房
	# 先取消正在放的主动技，再锁移动/吞噬/自动咬；10 秒无敌覆盖演出 + 落地后的缓冲
	yu.she_yan_chu_kong_zhi(true)
	yu.jin_ru_wudi(10.0)
	# 整张背景与世界里的活物一起收：九块图飞入时，鱼群/植物/鲸鲨不能浮在空底色上
	$Haodi.visible = false
	$YuQun.visible = false
	$ZhiWuQun.visible = false
	if is_instance_valid(_jing_sha):
		_jing_sha.visible = false
	_qie_huan_hud(false)
	var yan_chu: DiTuPinJieYanChu = DI_TU_PIN_JIE_YAN_CHU.new()
	yan_chu.name = "DiTuPinJieYanChu"
	yan_chu.jie_shu.connect(_on_ren_lei_yan_chu_jie_shu)
	add_child(yan_chu)
	yan_chu.bo_fang(yu, camera, qu_yu_ming(yu.global_position),
			Vector2.ONE / _shi_jiao_bei())


func _on_ren_lei_yan_chu_jie_shu() -> void:
	# 演出结束（自然或跳过）：交还相机/输入/HUD，显示整图背景，再让船真正落到玩家头顶
	yan_chu_zhong = false
	yu.she_yan_chu_kong_zhi(false)
	yu.fang_xiang = Vector2.ZERO
	$Haodi.visible = true
	$YuQun.visible = true
	$ZhiWuQun.visible = true
	if is_instance_valid(_jing_sha):
		_jing_sha.visible = true
	_qie_huan_hud(true)
	# 船在玩家上方 600px：保持全图 limit，交给 _process 的船战取景（offset/zoom）
	_suo_quan_tu()
	camera.offset = REN_LEI_QUAN_TU_OFFSET
	camera.position_smoothing_enabled = true
	camera.zoom = Vector2.ONE * REN_LEI_QUAN_TU_ZOOM
	camera.global_position = yu.global_position
	camera.reset_smoothing()
	_sheng_cheng_ji_qi_chuan()
	_xian_shi_xiao_xi("人类机器船降临！")


func _qie_huan_hud(ke_jian: bool) -> void:
	# 演出期间藏所有读数与摇杆；头顶血条是 top_level 节点，单独藏
	for ming in HUD_CENG_MING:
		var ceng := get_node_or_null(ming) as CanvasLayer
		if ceng != null:
			ceng.visible = ke_jian
	if is_instance_valid(tou_ding_xue_tiao):
		tou_ding_xue_tiao.visible = ke_jian


func _sheng_cheng_ji_qi_chuan() -> void:
	# 只在玩家上方生成一次；重复调用（时间到 + 提前开战）不会叠出两条船
	if is_instance_valid(ji_qi_chuan):
		return
	# 机器船降临 = 决战期开始：通知鱼群停刷，存量 NPC 保持原样（2026-11-02 拍板）
	yu_qun.ting_zhi_shua_xin()
	ji_qi_chuan = JI_QI_CHUAN_CHANGJING.instantiate()
	ji_qi_chuan.wan_jia = yu  # 注入玩家：船不靠组名找人，测试也好塞假玩家
	# A13：船血量 = 玩家当前体型 ×40（生成时定格；鲸鲨战/提前开战都不另外加成）
	var chuan_xue := maxf(1.0, ZhangBen.dang_qian_ti_xing * SHU_ZHI.CHUAN_XUE_MEI_TI)
	ji_qi_chuan.zui_da_xue = chuan_xue
	ji_qi_chuan.xue = chuan_xue
	# 鲸鲨还活着：船降临后先打它 8~10 秒（玩家咬船会立刻转仇）
	ji_qi_chuan.jing_sha = _jing_sha if is_instance_valid(_jing_sha) and not _jing_sha.si_le else null
	ji_qi_chuan.position = yu.global_position + Vector2(0, -600)
	add_child(ji_qi_chuan)
	ji_qi_chuan.bei_ji_bai.connect(_on_ji_qi_chuan_bei_ji_bai)
	YinXiang.bo_bgm(&"jue_zhan")  # 决战曲：船降临即换，胜利/失败进结算页再切回深海摇篮


func _on_ji_qi_chuan_bei_ji_bai() -> void:
	# 船沉了 = 本局胜利；结局写进账本，由 _on_ju_jie_shu 统一收尾
	ZhangBen.ding_jie_suan(ZhangBen.JieJu.SHENG_LI)


func _on_ju_jie_shu(jie_guo: int) -> void:
	# 胜负已定：留 1.2 秒给横幅/沉没动画，再进结算页
	# 死亡不走这里：Yu._si_wang 已立即切结算页，这里再切会二次加载场景
	if jie_guo == ZhangBen.JieJu.SI_WANG:
		return
	if jie_guo == ZhangBen.JieJu.SHI_BAI:
		_xian_shi_xiao_xi("时间耗尽——机器船仍在头顶")
	elif jie_guo == ZhangBen.JieJu.SHENG_LI:
		_xian_shi_xiao_xi("机器船沉没！")
	await get_tree().create_timer(1.2).timeout
	get_tree().change_scene_to_file("res://scenes/JieSuan.tscn")


func _xian_shi_xiao_xi(wen_ben: String) -> void:
	# 横幅：亮 2 秒 + 0.8 秒淡出；连续触发时后一条直接覆盖前一条的补间
	xiao_xi_label.text = wen_ben
	xiao_xi_label.visible = true
	xiao_xi_label.modulate.a = 1.0
	var bu_jian := create_tween()
	bu_jian.tween_interval(2.0)
	bu_jian.tween_property(xiao_xi_label, "modulate:a", 0.0, 0.8)
	bu_jian.tween_callback(func() -> void: xiao_xi_label.visible = false)


func _du_qu_fang_xiang() -> Vector2:
	# PC 键盘控制：WASD/方向键全构建生效（键盘优先覆盖摇杆，松开回落摇杆）；手机版无键盘不受影响
	var jian_pan := Vector2(
		(1.0 if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) else 0.0)
		- (1.0 if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) else 0.0),
		(1.0 if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) else 0.0)
		- (1.0 if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) else 0.0)
	)
	if jian_pan.length() > 0.0:
		return jian_pan.normalized()  # 键盘优先：按下时覆盖摇杆，松开回到摇杆
	return yao_gan.fang_xiang


func _shi_jiao_bei() -> float:
	# 可见范围倍率：TASK-019 起 SHI_JIAO_MEI_JI=0，结果恒 1.0（固定探索镜头）
	# 公式保留：未来若恢复逐级拉远，只改系数即可；camera.zoom = 1.0 / _shi_jiao_bei()
	return minf(1.0 + SHI_JIAO_MEI_JI * mini(ZhangBen.deng_ji, SHI_JIAO_FENG_DING_JI), SHI_JIAO_FENG_DING)


func qu_yu_ming(weizhi: Vector2) -> String:
	# 世界坐标落在九宫格哪一格：行优先，越界夹到边缘格（相机 limit 保证不会真的越界）
	var ge_x := clampi(int(floor(weizhi.x / DI_TU_MEI_GE.x)), 0, 2)
	var ge_y := clampi(int(floor(weizhi.y / DI_TU_MEI_GE.y)), 0, 2)
	return DI_TU_MING[ge_y * 3 + ge_x]


func fang_jian_qu(pian: int) -> Rect2:
	# 九宫格第 pian 格的矩形：行优先，越界夹到 0..8
	var p := clampi(pian, 0, 8)
	var ge_x := p % 3
	var ge_y := int(floor(float(p) / 3.0))
	return Rect2(Vector2(ge_x * DI_TU_MEI_GE.x, ge_y * DI_TU_MEI_GE.y), DI_TU_MEI_GE)


func qu_yu_pian(shijie_wei: Vector2) -> int:
	# 世界坐标落在哪一格：与 DiTuPinJieYanChu.wan_jia_pian 同规则（格边界归右下格）
	var ge_x := clampi(int(floor(shijie_wei.x / DI_TU_MEI_GE.x)), 0, 2)
	var ge_y := clampi(int(floor(shijie_wei.y / DI_TU_MEI_GE.y)), 0, 2)
	return ge_y * 3 + ge_x


func _suo_fang_jian(pian: int) -> void:
	# 只锁 limit，不改 zoom：TASK-019 已把探索 zoom 固定 1.0
	var qu := fang_jian_qu(pian)
	camera.limit_left = int(qu.position.x)
	camera.limit_top = int(qu.position.y)
	camera.limit_right = int(qu.end.x)
	camera.limit_bottom = int(qu.end.y)


func _suo_quan_tu() -> void:
	# 人类战/九图演出专用：恢复整图 limit；不要在这里改 zoom/offset
	camera.limit_left = int(QUAN_TU_LIMIT.position.x)
	camera.limit_top = int(QUAN_TU_LIMIT.position.y)
	camera.limit_right = int(QUAN_TU_LIMIT.end.x)
	camera.limit_bottom = int(QUAN_TU_LIMIT.end.y)


func _chuang_jian_hei_mu() -> void:
	# 黑幕放独立 CanvasLayer（layer=100）：盖住 HUD 与所有 CanvasLayer
	var ceng := CanvasLayer.new()
	ceng.name = "FangJianHeiMu"
	ceng.layer = 100
	add_child(ceng)
	_zhe_hei = ColorRect.new()
	_zhe_hei.color = Color(0.0, 0.0, 0.0, 0.0)
	_zhe_hei.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ceng.add_child(_zhe_hei)
	_zhe_hei.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _zai_ren_lei_zhan() -> bool:
	# 船已生成且未沉：人类战相机特例；结算前 1.2 秒船已沉，会回到普通取景
	return is_instance_valid(ji_qi_chuan) and not ji_qi_chuan.si_le


func xu_yao_huan_fang_wu_di(dang_qian_wu_di: bool, sheng_yu: float) -> bool:
	# 换房免伤不截短更长保护：无敌剩余 ≥0.9 秒就原样保留，否则（含无无敌）重开 0.9 秒
	return not dang_qian_wu_di or sheng_yu < HUAN_FANG_WU_DI_SHI_JIAN


func _qie_huan_fang_jian(pian: int) -> void:
	# 0.12 秒淡出 → 黑场中换房 → 0.12 秒淡入；过渡只锁移动，不取消技能
	if _qie_huan_zhong or yan_chu_zhong or _zai_ren_lei_zhan():
		return
	if pian == dang_qian_fang_jian:
		return
	_qie_huan_zhong = true
	yu.fang_xiang = Vector2.ZERO
	if _zhe_hei != null:
		var an := create_tween()
		an.tween_property(_zhe_hei, "color:a", 1.0, FANG_JIAN_HUAN_CHU_SHI_JIAN)
		await an.finished
	if not is_inside_tree():
		return
	dang_qian_fang_jian = clampi(pian, 0, 8)
	_suo_fang_jian(dang_qian_fang_jian)
	var qu := fang_jian_qu(dang_qian_fang_jian)
	yu.global_position = Vector2(
		clampf(yu.global_position.x, qu.position.x + FANG_JIAN_JIN_BIAO_LIU, qu.end.x - FANG_JIAN_JIN_BIAO_LIU),
		clampf(yu.global_position.y, qu.position.y + FANG_JIAN_JIN_BIAO_LIU, qu.end.y - FANG_JIAN_JIN_BIAO_LIU))
	camera.global_position = yu.global_position
	camera.reset_smoothing()
	# 入场免伤：淡入瞬间不让大鱼一口贴脸咬死。
	# 只在“当前没有无敌”或“剩余无敌不足 0.9 秒”时开启；否则保留更长的无敌（进化 1.7s、冲刺 2s 等），
	# 避免换房把玩家已有的保护截短。
	if xu_yao_huan_fang_wu_di(yu.wudi, yu.wudi_dingshi.time_left):
		yu.jin_ru_wudi(HUAN_FANG_WU_DI_SHI_JIAN)
	yu_qun.qie_huan_fang_jian(qu)
	_xian_shi_xiao_xi("进入 " + DI_TU_MING[dang_qian_fang_jian])
	if _zhe_hei != null:
		var chu := create_tween()
		chu.tween_property(_zhe_hei, "color:a", 0.0, FANG_JIAN_HUAN_CHU_SHI_JIAN)
		await chu.finished
	_qie_huan_zhong = false
