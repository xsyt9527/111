extends Node2D
# 主场景协调者：读摇杆方向，交给玩家鱼（输入层与运动层分离）
# 同时负责 3×3 大地图：相机跟随玩家，按玩家位置显示当前区域名

const DI_TU_MEI_GE := Vector2(1376.0, 768.0)  # 3×3 拼图单格尺寸（源图原生 1376×768）
const SHI_JIAO_MEI_JI := 0.10  # 每升 1 级，可见范围 +10%
const SHI_JIAO_FENG_DING := 2.0  # 可见范围最多拉到 2 倍
const SHI_JIAO_FENG_DING_JI := 10  # Lv.10 封顶：等级无上限，镜头必须有上限，否则地图会缩成一点
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
@onready var yao_gan: YaoGan = $UI/YaoGan  # 虚拟摇杆（只给方向，不给速度）
@onready var ti_xing_label: Label = $TiXingUI/TiXingLabel  # 体型数字（替代退役的血条）
@onready var ji_e_label: Label = $JiEUI/JiELabel  # 饥饿数字：低于 20 变红示警
@onready var ji_e_tiao: ProgressBar = $JiEUI/JiETiao  # 饥饿条
@onready var camera: Camera2D = $Camera2D  # 3×3 大地图相机：跟着玩家走，边界夹在地图内
@onready var di_tu_ming: Label = $DiTuUI/DiTuMing  # 当前区域名（右上角）


func _ready() -> void:
	# 相机先对准玩家再开平滑，避免开局从 (0,0) 滑过来
	camera.global_position = yu.global_position
	camera.reset_smoothing()
	di_tu_ming.text = qu_yu_ming(yu.global_position)


func _process(_delta: float) -> void:
	# 每帧只转发方向：转多快、游多快由鱼按体型自己算，Main 不掺和运动细节
	yu.fang_xiang = _du_qu_fang_xiang()
	# 等级由经验条的 DengJiLabel 显示；这里只报当前体型（血量）/上限，受伤回血一眼可见
	ti_xing_label.text = "体型 %.1f/%.1f" % [ZhangBen.dang_qian_ti_xing, ZhangBen.ti_xing_shang_xian()]
	# 饥饿：账本每帧扣，这里只读不写；低于 20 变红，提醒“该找东西吃了”
	ji_e_tiao.value = ZhangBen.ji_e
	ji_e_label.text = "饥饿 %d/%d" % [int(ZhangBen.ji_e), int(ZhangBen.JI_E_SHANG_XIAN)]
	ji_e_label.modulate = Color(1.0, 0.45, 0.45) if ZhangBen.ji_e < 20.0 else Color.WHITE
	# 相机跟随玩家；Camera2D 的 limit 会把它夹在地图边界内
	camera.global_position = yu.global_position
	# 镜头拉远：等级越高看得越远（范围 ×(1+0.1×等级)，Lv.10 封顶 2.0×）
	# Camera2D.zoom 是放大倍数，>1 看得更少；范围 ×N 等价于 zoom ÷N
	camera.zoom = Vector2.ONE / _shi_jiao_bei()
	# 区域名：玩家跨过 1376/768 的格子边界才换字
	var ming := qu_yu_ming(yu.global_position)
	if di_tu_ming.text != ming:
		di_tu_ming.text = ming


func _du_qu_fang_xiang() -> Vector2:
	# 调试用键盘：仅 debug 构建生效，方便桌面测试；导出后的正式版仍只认摇杆
	if OS.is_debug_build():
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
