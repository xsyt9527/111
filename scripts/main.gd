extends Node2D
# 主场景协调者：读摇杆方向，交给玩家鱼（输入层与运动层分离）
# 同时负责 3×3 大地图：相机跟随玩家，按玩家位置显示当前区域名

const DI_TU_MEI_GE := Vector2(1376.0, 768.0)  # 3×3 拼图单格尺寸（源图原生 1376×768）
const SHI_JIAO_MEI_JI := 0.10  # 每升 1 级，可见范围 +10%
const SHI_JIAO_FENG_DING := 2.0  # 可见范围最多拉到 2 倍
const SHI_JIAO_FENG_DING_JI := 10  # Lv.10 封顶：等级无上限，镜头必须有上限，否则地图会缩成一点
const JI_QI_CHUAN_CHANGJING := preload("res://scenes/JiQiChuan.tscn")  # 人类战 Boss 蓝图
const SHU_ZHI := preload("res://scripts/shu_zhi.gd")  # A 核心数值表
const SHOU_JU_JIAO_BEN := preload("res://scripts/shou_ju_jiao_ben.gd")  # C 首局 10 分钟节奏脚本
const YU_NPC_CHANGJING := preload("res://scenes/YuNpc.tscn")  # 鱼骨架：首领也用同一套
const FEN_YU := preload("res://data/yuzhong/fen_yu.tres")  # 鲸鲨鱼种（shi_boss = true）
const BOOS_CHU_SHENG_DIAN := Vector2(3440.0, 1920.0)  # 东南 · 远古祭坛地宫中心
const BOOS_XUN_LUO_DIAN := [
	Vector2(3440.0, 1920.0),  # 东南 · 远古祭坛地宫（出生点）
	Vector2(688.0, 1920.0),   # 西南 · 沉船宝库深渊
	Vector2(688.0, 384.0),    # 西北 · 沉船锚链悬崖
	Vector2(3440.0, 384.0),   # 东北 · 浮空遗迹钟楼
]  # 首领四处游荡：出生点 → 西南 → 西北 → 东北 → 回东南，循环
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


func _process(_delta: float) -> void:
	# 每帧只转发方向：转多快、游多快由鱼按体型自己算，Main 不掺和运动细节
	yu.fang_xiang = _du_qu_fang_xiang()
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
	# 相机跟随玩家；Camera2D 的 limit 会把它夹在地图边界内
	camera.global_position = yu.global_position
	# 镜头拉远：等级越高看得越远（范围 ×(1+0.1×等级)，Lv.10 封顶 2.0×）
	# Camera2D.zoom 是放大倍数，>1 看得更少；范围 ×N 等价于 zoom ÷N
	camera.zoom = Vector2.ONE / _shi_jiao_bei()
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
		# 首领已四处游荡：按它“此刻”所在的九宫格报位置，别再说死东南祭坛
		_xian_shi_xiao_xi("巨影游荡至 %s" % qu_yu_ming(_jing_sha.global_position))


func _sheng_cheng_jing_sha() -> void:
	# 祭坛首领：和普通鱼共用 YuNpc 场景，靠鱼种表的 shi_boss 标记身份
	# 四处巡逻、不随鱼群刷新、不被出屏回收——玩家得在地图上找它（或等它巡过来）
	_jing_sha = YU_NPC_CHANGJING.instantiate()
	_jing_sha.yu_zhong = FEN_YU
	_jing_sha.position = BOOS_CHU_SHENG_DIAN
	_jing_sha.xun_luo_dian.assign(BOOS_XUN_LUO_DIAN)  # 四个巡逻点：注入给首领 AI
	_jing_sha.sudu = 60.0  # 巡逻游得慢：玩家能绕到它侧面；追击速度另算（YuNpc 常量）
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
	# 账本宣布进入人类战：Main 负责生成机器船 + 打横幅
	if xin_jie_duan == ZhangBen.JieDuan.REN_LEI_ZHAN:
		_sheng_cheng_ji_qi_chuan()
		YinXiang.fang(&"jing_bao")  # F11 机械船入场警报：与横幅同一拍
		_xian_shi_xiao_xi("人类机器船降临！")


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
	# 可见范围倍率：每级 +10%，Lv.10 到达 2.0× 后不再增长（等级无上限，镜头必须有顶）
	return minf(1.0 + SHI_JIAO_MEI_JI * mini(ZhangBen.deng_ji, SHI_JIAO_FENG_DING_JI), SHI_JIAO_FENG_DING)


func qu_yu_ming(weizhi: Vector2) -> String:
	# 世界坐标落在九宫格哪一格：行优先，越界夹到边缘格（相机 limit 保证不会真的越界）
	var ge_x := clampi(int(floor(weizhi.x / DI_TU_MEI_GE.x)), 0, 2)
	var ge_y := clampi(int(floor(weizhi.y / DI_TU_MEI_GE.y)), 0, 2)
	return DI_TU_MING[ge_y * 3 + ge_x]
