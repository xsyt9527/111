extends Control
class_name XiaoDiTu
# 上帝视角（永久被动）：整张九宫格海图缩略 + 实时标记
# 只读组（player / yu_npc / zhi_wu）与 Main 的公开变量，不复制、不写任何 gameplay 状态。
# 每帧只 queue_redraw；约 65 个标记点，开销可忽略。

const DI_TU_WEN_LI: Texture2D = preload("res://assets/sucai/shenhai_beijing/beijing_3x3.webp")
const SHI_JIE_CHI_CUN := Vector2(4128.0, 2304.0)  # 世界总尺寸（3×3 拼图原始像素）
const DI_TU_QU := Rect2(0.0, 20.0, 240.0, 134.0)  # 地图矩形：标题下方 20，高 134
const GE_SHU := 3                                 # 九宫格每边房间数
const MO_REN_FANG_JIAN := 4                       # 读不到 Main 时默认开局正中

# 面板与标记配色（rgba）
const YAN_SE_DI := Color(0.02, 0.05, 0.09, 0.62)          # 半透明深色面板底
const YAN_SE_BIAN := Color(0.42, 0.72, 0.92, 0.42)        # 面板细边框
const YAN_SE_WANG_GE := Color(1.0, 1.0, 1.0, 0.18)        # 3×3 网格线
const YAN_SE_DANG_QIAN := Color(0.60, 1.0, 1.0, 0.96)     # 当前房间亮青边框
const YAN_SE_ZHI_WU := Color(0.35, 1.0, 0.42, 0.95)       # 植物绿点
const YAN_SE_NPC := Color(1.0, 0.30, 0.28, 0.96)          # NPC 鱼红点
const YAN_SE_WAN_JIA := Color(0.22, 0.62, 1.0, 1.0)       # 玩家蓝点
const YAN_SE_HEI_DIAN := Color(0.03, 0.03, 0.05, 1.0)     # 首领/机械船黑点
const YAN_SE_BAI_BIAN := Color(1.0, 1.0, 1.0, 0.96)       # 黑点白色描边


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP  # 纯展示但不穿透：吃掉点击，别让地图区域误触左下摇杆
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()  # 实时标记：每帧重绘；点数少，CPU/GPU 开销都可忽略


func _draw() -> void:
	var zhu_jie_mian := _qu_zhu_jie_mian()
	# 1) 半透明深色面板底（标题/图例区域也在其中）
	draw_rect(Rect2(Vector2.ZERO, size), YAN_SE_DI)
	# 2) 整张 4128×2304 海图缩放到 240×134：不贴九张、不复制美术
	draw_texture_rect(DI_TU_WEN_LI, DI_TU_QU, false)
	# 3) 3×3 房间网格线
	_hu_wang_ge()
	# 4) 当前房间亮青边框
	_hu_dang_qian_fang_jian(zhu_jie_mian)
	# 5) 状态标记：植物 → NPC → 首领/机械船 → 玩家（小点先画，大点后盖）
	_hu_zhi_wu()
	_hu_npc()
	_hu_shou_ling_he_chuan(zhu_jie_mian)
	_hu_wan_jia()
	# 6) 面板细边框最后画：压在地图边缘上，保证四边都看得见
	draw_rect(Rect2(Vector2.ZERO, size), YAN_SE_BIAN, false, 1.0)


func _qu_zhu_jie_mian() -> Node:
	# 层级：XiaoDiTu(Control) → XiaoDiTuUI(CanvasLayer) → Main(Node2D)
	var fu_qin := get_parent()
	if fu_qin == null:
		return null
	return fu_qin.get_parent()


func _hu_wang_ge() -> void:
	for i in range(1, GE_SHU):
		var bi := float(i) / float(GE_SHU)
		# 竖线
		var x := DI_TU_QU.position.x + DI_TU_QU.size.x * bi
		draw_line(Vector2(x, DI_TU_QU.position.y), Vector2(x, DI_TU_QU.end.y), YAN_SE_WANG_GE, 1.0)
		# 横线
		var y := DI_TU_QU.position.y + DI_TU_QU.size.y * bi
		draw_line(Vector2(DI_TU_QU.position.x, y), Vector2(DI_TU_QU.end.x, y), YAN_SE_WANG_GE, 1.0)


func _hu_dang_qian_fang_jian(zhu_jie_mian: Node) -> void:
	var fang_jian := _qu_dang_qian_fang_jian(zhu_jie_mian)
	var hang := int(float(fang_jian) / float(GE_SHU))  # 行优先：0..2
	var lie := fang_jian % GE_SHU                        # 列优先：0..2
	var kuai := Vector2(
		DI_TU_QU.size.x / float(GE_SHU),
		DI_TU_QU.size.y / float(GE_SHU))
	var mian := Rect2(
		DI_TU_QU.position + Vector2(lie * kuai.x, hang * kuai.y),
		kuai)
	draw_rect(mian, YAN_SE_DANG_QIAN, false, 1.5)


func _qu_dang_qian_fang_jian(zhu_jie_mian: Node) -> int:
	if zhu_jie_mian == null:
		return MO_REN_FANG_JIAN
	var zhi = zhu_jie_mian.get("dang_qian_fang_jian")  # 只读 Main 的公开变量
	if zhi == null:
		return MO_REN_FANG_JIAN
	return clampi(int(zhi), 0, GE_SHU * GE_SHU - 1)


func _dao_di_tu(shijie: Vector2) -> Vector2:
	# 世界坐标 → 地图坐标：整图等比映射（4128×2304 → 240×134）
	return DI_TU_QU.position + Vector2(
		shijie.x / SHI_JIE_CHI_CUN.x * DI_TU_QU.size.x,
		shijie.y / SHI_JIE_CHI_CUN.y * DI_TU_QU.size.y)


func _zai_shi_jie_nei(shijie: Vector2) -> bool:
	# 世界外（例如船刚生成在玩家上方 600px、可能越过地图上缘）不画，避免点跑到标题/图例上
	return (shijie.x >= 0.0 and shijie.y >= 0.0
		and shijie.x <= SHI_JIE_CHI_CUN.x and shijie.y <= SHI_JIE_CHI_CUN.y)


func _hua_dian(shijie: Vector2, yan_se: Color, ban_jing: float) -> void:
	if not _zai_shi_jie_nei(shijie):
		return
	draw_circle(_dao_di_tu(shijie), ban_jing, yan_se)


func _hua_shou_ling(shijie: Vector2) -> void:
	if not _zai_shi_jie_nei(shijie):
		return
	var dian := _dao_di_tu(shijie)
	draw_circle(dian, 5.8, YAN_SE_BAI_BIAN)  # 白色描边：海图偏暗也看得见
	draw_circle(dian, 4.5, YAN_SE_HEI_DIAN)


func _hu_zhi_wu() -> void:
	for zhu in get_tree().get_nodes_in_group("zhi_wu"):
		var jie_dian := zhu as Node2D
		if jie_dian == null:
			continue
		if zhu.get("ke_chi") != true:
			continue
		var dong_hua := zhu.get("dong_hua") as AnimatedSprite2D
		if dong_hua == null or not dong_hua.visible:
			continue  # 被吃掉后只隐藏动画、节点还在：不可吃就不画
		_hua_dian(jie_dian.global_position, YAN_SE_ZHI_WU, 1.6)


func _hu_npc() -> void:
	# 第一遍：普通 NPC 红点（首领跳过，留到第二遍压在上层）
	for npc in get_tree().get_nodes_in_group("yu_npc"):
		var jie_dian := npc as Node2D
		if jie_dian == null:
			continue
		if npc.get("si_le") == true:
			continue  # 已死（queue_free 前先立旗）：不画残留点
		if npc.get("shi_boss") == true:
			continue
		_hua_dian(jie_dian.global_position, YAN_SE_NPC, 2.0)
	# 第二遍：首领黑点；鲸鲨也在 yu_npc 组里，这里自然识别
	for npc in get_tree().get_nodes_in_group("yu_npc"):
		var jie_dian := npc as Node2D
		if jie_dian == null:
			continue
		if npc.get("si_le") == true:
			continue
		if npc.get("shi_boss") == true:
			_hua_shou_ling(jie_dian.global_position)


func _hu_shou_ling_he_chuan(zhu_jie_mian: Node) -> void:
	if zhu_jie_mian == null:
		return
	var chuan = zhu_jie_mian.get("ji_qi_chuan")  # Main 持有的机器船引用（可能为 null）
	if not is_instance_valid(chuan):
		return  # 未生成或已释放：只读检查，不缓存副本
	var jie_dian := chuan as Node2D
	if jie_dian == null:
		return
	if chuan.get("si_le") == true:
		return  # 已沉没：与 Main 的存活判定一致，不画残留点
	_hua_shou_ling(jie_dian.global_position)


func _hu_wan_jia() -> void:
	for wan_jia in get_tree().get_nodes_in_group("player"):
		var jie_dian := wan_jia as Node2D
		if jie_dian == null:
			continue
		if not _zai_shi_jie_nei(jie_dian.global_position):
			continue
		var dian := _dao_di_tu(jie_dian.global_position)
		draw_circle(dian, 4.8, YAN_SE_BAI_BIAN)  # 白色描边：深色海图上更醒目
		draw_circle(dian, 3.2, YAN_SE_WAN_JIA)
