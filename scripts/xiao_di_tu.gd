extends Control
class_name XiaoDiTu
# 上帝视角（永久被动）：整张九宫格海图缩略 + 实时标记（雷达风）。
# 只读组（player / yu_npc / zhi_wu）与 Main 的公开变量，不复制、不写任何 gameplay 状态。
# 每帧只 queue_redraw；约 65 个标记点，开销可忽略。

const SHI_JIE_CHI_CUN := Vector2(4128.0, 2304.0)  # 世界总尺寸（3×3 拼图原始像素）
const DI_TU_QU := Rect2(0.0, 0.0, 240.0, 134.0)  # 地图矩形：标题删除后从面板顶部开始，高 134
const GE_SHU := 3                                 # 九宫格每边房间数
const MO_REN_FANG_JIAN := 4                       # 读不到 Main 时默认开局正中

# 面板与标记配色（rgba）。面板元素的 alpha 在绘制时按 tou_ming_du 缩放；标记另有 0.55 保底。
const YAN_SE_DI := Color(0.0, 0.0, 0.0, 0.82)              # 半透明深色面板底（不是纯黑不透明）
const YAN_SE_BIAN := Color(0.42, 0.72, 0.92, 0.24)        # 面板细边框（保留但调淡）
const YAN_SE_WANG_GE := Color(0.42, 0.72, 0.92, 0.10)     # 3×3 网格线：青色低 alpha
const YAN_SE_LEI_DA := Color(0.42, 0.72, 0.92, 0.11)      # 雷达同心椭圆环 + 中心小十字
const YAN_SE_DANG_QIAN := Color(0.60, 1.0, 1.0, 0.96)     # 当前房间亮青边框
const YAN_SE_ZHI_WU := Color(0.35, 1.0, 0.42, 0.95)       # 植物绿点
const YAN_SE_NPC := Color(1.0, 0.30, 0.28, 0.96)          # NPC 鱼红点
const YAN_SE_WAN_JIA := Color(0.22, 0.62, 1.0, 1.0)       # 玩家蓝点
const YAN_SE_SHOU_LING := Color(1.0, 0.78, 0.16, 1.0)     # 首领/机械船金色点
const YAN_SE_BAI_BIAN := Color(1.0, 1.0, 1.0, 0.96)       # 首领/玩家白描边

var tou_ming_du: float = 0.85  # 面板整体透明度（设置面板可调，范围 0.3–1.0）
var _tu_li: CanvasItem = null  # 底部图例 Label；透明度随面板同步


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP  # 纯展示但不穿透：吃掉点击，别让地图区域误触左下摇杆
	_tu_li = get_node_or_null("TuLi") as CanvasItem
	_tong_bu_tu_li()
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()  # 实时标记：每帧重绘；点数少，CPU/GPU 开销都可忽略


func she_tou_ming_du(zhi: float) -> void:
	# 供设置面板调用：写入合法范围并重绘；子节点图例同步变淡/变亮
	tou_ming_du = clampf(zhi, 0.3, 1.0)
	_tong_bu_tu_li()
	queue_redraw()


func _tong_bu_tu_li() -> void:
	if _tu_li == null:
		return  # 场景里没有图例节点也不报错
	_tu_li.modulate.a = tou_ming_du


func _yan_se_an(yan_se: Color, xi_shu: float) -> Color:
	# 面板元素：色相不变，alpha 按系数缩放（随 tou_ming_du 整体变淡）
	return Color(yan_se.r, yan_se.g, yan_se.b, yan_se.a * xi_shu)


func _yan_se_biao_ji(yan_se: Color) -> Color:
	# 标记：alpha 统一取 maxf(0.55, tou_ming_du)，保证调低透明度后首领/玩家/鱼/植物仍看得见
	return Color(yan_se.r, yan_se.g, yan_se.b, maxf(0.55, tou_ming_du))


func _draw() -> void:
	var zhu_jie_mian := _qu_zhu_jie_mian()
	# 1) 半透明深色面板底（地图 + 下方图例区域都盖住）
	draw_rect(Rect2(Vector2.ZERO, size), _yan_se_an(YAN_SE_DI, tou_ming_du))
	# 2) 雷达感：两圈静态椭圆环 + 中心小十字；不旋转、不逐帧动画，避免更花
	_hu_lei_da()
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
	draw_rect(Rect2(Vector2.ZERO, size), _yan_se_an(YAN_SE_BIAN, tou_ming_du), false, 1.0)


func _hu_lei_da() -> void:
	# 以地图矩形中心为雷达中心；两圈很淡的椭圆环（横向略宽，贴合 240×134 地图）
	var zhong_xin := DI_TU_QU.position + DI_TU_QU.size * 0.5
	var yan_se := _yan_se_an(YAN_SE_LEI_DA, tou_ming_du)
	_hua_tuo_yuan_huan(zhong_xin, DI_TU_QU.size * Vector2(0.36, 0.40), yan_se, 56, 1.0)
	_hua_tuo_yuan_huan(zhong_xin, DI_TU_QU.size * Vector2(0.19, 0.22), yan_se, 40, 1.0)
	# 中心小十字（±5px）：加强“雷达中心”的读数，仍用同一低 alpha
	var shi_zi := 5.0
	draw_line(zhong_xin - Vector2(shi_zi, 0.0), zhong_xin + Vector2(shi_zi, 0.0), yan_se, 1.0)
	draw_line(zhong_xin - Vector2(0.0, shi_zi), zhong_xin + Vector2(0.0, shi_zi), yan_se, 1.0)


func _hua_tuo_yuan_huan(zhong_xin: Vector2, ban_jing: Vector2, yan_se: Color, dian_shu: int, xian_kuan: float) -> void:
	# draw_arc 只画正圆；这里按椭圆参数生成折线，首尾闭合
	var dian := PackedVector2Array()
	for i in range(dian_shu + 1):
		var jiao := TAU * float(i) / float(dian_shu)
		dian.append(zhong_xin + Vector2(cos(jiao) * ban_jing.x, sin(jiao) * ban_jing.y))
	draw_polyline(dian, yan_se, xian_kuan, true)


func _qu_zhu_jie_mian() -> Node:
	# 层级：XiaoDiTu(Control) → XiaoDiTuUI(CanvasLayer) → Main(Node2D)
	var fu_qin := get_parent()
	if fu_qin == null:
		return null
	return fu_qin.get_parent()


func _hu_wang_ge() -> void:
	var yan_se := _yan_se_an(YAN_SE_WANG_GE, tou_ming_du)
	for i in range(1, GE_SHU):
		var bi := float(i) / float(GE_SHU)
		# 竖线
		var x := DI_TU_QU.position.x + DI_TU_QU.size.x * bi
		draw_line(Vector2(x, DI_TU_QU.position.y), Vector2(x, DI_TU_QU.end.y), yan_se, 1.0)
		# 横线
		var y := DI_TU_QU.position.y + DI_TU_QU.size.y * bi
		draw_line(Vector2(DI_TU_QU.position.x, y), Vector2(DI_TU_QU.end.x, y), yan_se, 1.0)


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
	draw_rect(mian, _yan_se_an(YAN_SE_DANG_QIAN, tou_ming_du), false, 1.5)


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
	# 世界外（例如船刚生成在玩家上方 600px、可能越过地图上缘）不画，避免点越出地图矩形
	return (shijie.x >= 0.0 and shijie.y >= 0.0
		and shijie.x <= SHI_JIE_CHI_CUN.x and shijie.y <= SHI_JIE_CHI_CUN.y)


func _hua_dian(shijie: Vector2, yan_se: Color, ban_jing: float, tou_ming_xi_shu := 1.0) -> void:
	if not _zai_shi_jie_nei(shijie):
		return
	var se := _yan_se_biao_ji(yan_se)
	se.a *= tou_ming_xi_shu  # 其他房间的 NPC 点额外压暗：当前房更醒目
	draw_circle(_dao_di_tu(shijie), ban_jing, se)


func _hua_shou_ling(shijie: Vector2) -> void:
	if not _zai_shi_jie_nei(shijie):
		return
	var dian := _dao_di_tu(shijie)
	draw_circle(dian, 5.8, _yan_se_biao_ji(YAN_SE_BAI_BIAN))  # 白色描边：深色底上也看得见
	draw_circle(dian, 4.5, _yan_se_biao_ji(YAN_SE_SHOU_LING))  # 金色圆点标明首领/机械船


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
	# 优先读 YuQun 的九房记录：未加载房也有点，当前房稍大稍亮、其他房略小略暗
	var zhu_jie_mian := _qu_zhu_jie_mian()
	var qun = null
	if zhu_jie_mian != null:
		qun = zhu_jie_mian.get("yu_qun")  # 只读 Main 的公开引用
	var you_ji_lu := false
	if qun != null and qun.has_method("fang_jian_ji_lu"):
		var dang_qian := _qu_dang_qian_fang_jian(zhu_jie_mian)
		for pian in range(GE_SHU * GE_SHU):
			var ji_lu: Array = qun.fang_jian_ji_lu(pian)  # 直接返回内部数组：不复制、不新建
			var shi_dang_qian := pian == dang_qian
			for rec in ji_lu:
				var wei: Vector2 = rec.get("wei", Vector2.ZERO)
				var ti := float(rec.get("ti", 1.0))
				var ban_jing := 2.0
				var an := 1.0
				if shi_dang_qian:
					ban_jing = clampf(1.8 + 0.15 * ti, 1.8, 2.6)
				else:
					ban_jing = clampf(1.3 + 0.1 * ti, 1.3, 1.9)
					an = 0.72
				_hua_dian(wei, YAN_SE_NPC, ban_jing, an)
				you_ji_lu = true
	var yu_men := get_tree().get_nodes_in_group("yu_npc")
	# 记录画完补扫：只画未托管鱼（教学鱼/临时鱼），避免它们不进记录而在雷达上消失
	for npc in yu_men:
		var jie_dian := npc as Node2D
		if jie_dian == null:
			continue
		if npc.get("si_le") == true:
			continue  # 已死（queue_free 前先立旗）：不画残留点
		if npc.get("shi_boss") == true:
			continue
		if you_ji_lu and npc.get("you_yu_qun_guan_li") == true:
			continue  # 九房记录已经画过
		_hua_dian(jie_dian.global_position, YAN_SE_NPC, 2.0)
	# 首领金点；鲸鲨也在 yu_npc 组里，这里自然识别
	for npc in yu_men:
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
		draw_circle(dian, 4.8, _yan_se_biao_ji(YAN_SE_BAI_BIAN))  # 白色描边：深色底上更醒目
		draw_circle(dian, 3.2, _yan_se_biao_ji(YAN_SE_WAN_JIA))
