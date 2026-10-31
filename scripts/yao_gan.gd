extends Control
class_name YaoGan
# 虚拟摇杆（TASK-011 step-01）：只出口径方向，不管速度——输入层与运动层分离

const BAN_JING := 120.0  # 底板半径（像素）
const TOU_BAN_JING := 50.0  # 摇杆头半径
const SI_QU := 15.0  # 死区：偏移小于它算没推（防止手指微抖当作输入）
const AN_XIA_FAN_WEI := 1.6  # 按下判定范围 = 底板半径 × 此倍数（手指粗，容错放大）

var fang_xiang := Vector2.ZERO  # 归一化方向；零向量 = 松手
var zhong_xin := Vector2.ZERO  # 底板中心（屏幕坐标）
var _pian_yi := Vector2.ZERO  # 摇杆头当前偏移（只用于绘制）
var _an_xia := false  # 是否正在操作
var _shou_zhi := -1  # 正在操作的手指编号（多点触控时不串手）


func _ready() -> void:
	var ping_mu := get_viewport_rect().size
	# 摇杆侧边可在主界面设置里切换（左手/右手习惯）；按路径找 CunDang：
	# --script 模式不注册 Autoload，编译期零依赖（ce_panding 老规矩）
	var cd := get_node_or_null("/root/CunDang")
	if cd != null and String(cd.get("yao_gan_ce")) == "you":
		zhong_xin = Vector2(ping_mu.x - 180.0, ping_mu.y - 180.0)  # 右下角
	else:
		zhong_xin = Vector2(180.0, ping_mu.y - 180.0)  # 左下角（默认）
	queue_redraw()


func _draw() -> void:
	# 底板：半透明大圆 + 描边（颜色全用白色透明度，不依赖主题）
	draw_circle(zhong_xin, BAN_JING, Color(1.0, 1.0, 1.0, 0.12))
	draw_arc(zhong_xin, BAN_JING, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.35), 3.0, true)
	# 摇杆头：跟着偏移走
	draw_circle(zhong_xin + _pian_yi, TOU_BAN_JING, Color(1.0, 1.0, 1.0, 0.35))
	draw_arc(zhong_xin + _pian_yi, TOU_BAN_JING, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.6), 3.0, true)


func _unhandled_input(event: InputEvent) -> void:
	# 鼠标模拟触摸已在 project.godot 开启：鼠标拖动同样产生 ScreenTouch / ScreenDrag
	if event is InputEventScreenTouch:
		if event.pressed and not _an_xia and event.position.distance_to(zhong_xin) <= BAN_JING * AN_XIA_FAN_WEI:
			_an_xia = true
			_shou_zhi = event.index
			_geng_xin_pian_yi(event.position)
		elif not event.pressed and _an_xia and event.index == _shou_zhi:
			_song_shou()
	elif event is InputEventScreenDrag and _an_xia and event.index == _shou_zhi:
		_geng_xin_pian_yi(event.position)


func _geng_xin_pian_yi(shou_zhi_wei_zhi: Vector2) -> void:
	# 偏移先限幅在半径内，再归一化成方向——摇杆只回答"往哪个方向"，不回答"多快"
	_pian_yi = shou_zhi_wei_zhi - zhong_xin
	if _pian_yi.length() > BAN_JING:
		_pian_yi = _pian_yi.normalized() * BAN_JING
	fang_xiang = _pian_yi.normalized() if _pian_yi.length() >= SI_QU else Vector2.ZERO
	queue_redraw()


func _song_shou() -> void:
	_an_xia = false
	_shou_zhi = -1
	_pian_yi = Vector2.ZERO
	fang_xiang = Vector2.ZERO  # 松手：方向归零，鱼自己减速停下
	queue_redraw()
