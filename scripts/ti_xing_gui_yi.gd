extends RefCounted
class_name TiXingGuiYi
# 体型归一化：让「鱼身可见内容宽」= 体型等级，而不是画布宽
# 背景：同一个体型的鱼，美术画布留白不同（有的鱼只占画布 60%），
# 只按画布宽乘曲线会让小鱼看起来比实际等级还小，玩家容易误判吃不吃得下。
# 口径：视觉内容宽 = JI_ZHUN_KUAN × ZhangBen.ti_xing_dao_chi_du(tixing)
# 默认玩家形态 ao_tu_wo_niu_yu 的 you 帧不透明内容宽实测 152 → 它的归一化因子正好 1，
# 所有形态都以它为基准：偏小的放大、偏大的收一点，同一体型所有鱼等宽。
# 不改数值账本：体型/等级、吞噬门槛、咬伤公式全部照旧，只统一「看起来多大」。

const JI_ZHUN_KUAN := 152.0  # 基准内容宽（像素 @ scale 1.0）：默认玩家形态实测值
const HUI_TUI_KUAN_GAO := Vector2(152.0, 101.0)  # 读不到贴图时的兜底内容尺寸（默认玩家量级）

# 缓存：贴图/图集区域不透明内容尺寸 + 动画归一化因子，避免每条鱼出生都重扫图片
static var _nei_rong_huan_cun := {}
static var _yin_zi_huan_cun := {}


static func nei_rong_kuan_gao(tu: Texture2D) -> Vector2:
	# 量一张贴图的“可见内容”宽高：透明留白不算，只取不透明像素包围盒
	# AtlasTexture（4 帧图集切片）要先按 region 裁出子图，否则会量成整张图集
	if tu == null:
		return HUI_TUI_KUAN_GAO
	var jian := _kuan_gao_jian(tu)
	if _nei_rong_huan_cun.has(jian):
		return _nei_rong_huan_cun[jian]
	var yuan := tu
	var qu := Rect2(Vector2.ZERO, Vector2(tu.get_width(), tu.get_height()))
	if tu is AtlasTexture:
		var a := tu as AtlasTexture
		yuan = a.atlas
		qu = a.region
	var jie := _liang_tu(yuan, qu)
	_nei_rong_huan_cun[jian] = jie
	return jie


static func _kuan_gao_jian(tu: Texture2D) -> String:
	# 缓存键：图集贴图按「图集 id + region」区分，普通贴图只用实例 id
	if tu is AtlasTexture:
		var a := tu as AtlasTexture
		var yuan := a.atlas
		var id := yuan.get_instance_id() if yuan != null else 0
		return "%d|%d,%d,%d,%d" % [id, a.region.position.x, a.region.position.y,
				a.region.size.x, a.region.size.y]
	return str(tu.get_instance_id())


static func _liang_tu(yuan: Texture2D, qu: Rect2) -> Vector2:
	# 真正量图：读像素 → 裁 region → 不透明包围盒；任何一步失败都退回画布宽高
	if yuan == null:
		return HUI_TUI_KUAN_GAO
	var xiang := yuan.get_image()
	if xiang == null or xiang.is_empty():
		return HUI_TUI_KUAN_GAO
	if xiang.is_compressed():
		var jie := xiang.duplicate()
		jie.decompress()  # VRAM 压缩纹理先解压；解不开就退回画布尺寸，不阻塞游戏
		if jie.is_compressed() or jie.is_empty():
			return Vector2(yuan.get_width(), yuan.get_height())
		xiang = jie
	var zheng := Rect2i(Vector2i(qu.position), Vector2i(qu.size))
	zheng = zheng.intersection(Rect2i(Vector2i.ZERO, xiang.get_size()))
	if zheng.size.x <= 0 or zheng.size.y <= 0:
		return Vector2(maxf(qu.size.x, 1.0), maxf(qu.size.y, 1.0))
	xiang = xiang.get_region(zheng)
	var yong := xiang.get_used_rect()
	if yong.size.x <= 0 or yong.size.y <= 0:
		return Vector2(maxf(qu.size.x, 1.0), maxf(qu.size.y, 1.0))
	return Vector2(float(yong.size.x), float(yong.size.y))


static func xing_xiang_bi(biao: SpriteFrames, dong := &"you", ji_zhun := JI_ZHUN_KUAN) -> float:
	# 形态归一化因子：框架帧 0（站姿）的内容宽对齐基准宽
	# 无动画 / 无帧 / 量不出内容：返回 1.0（老资源照旧按画布缩放，不会原地爆炸）
	if biao == null or not biao.has_animation(dong):
		return 1.0
	if biao.get_frame_count(dong) <= 0:
		return 1.0
	var jian := "%d|%s|%.1f" % [biao.get_instance_id(), String(dong), ji_zhun]
	if _yin_zi_huan_cun.has(jian):
		return _yin_zi_huan_cun[jian]
	var kuan := nei_rong_kuan_gao(biao.get_frame_texture(dong, 0)).x
	var bi := 1.0 if kuan <= 0.0 else ji_zhun / kuan
	_yin_zi_huan_cun[jian] = bi
	return bi


static func zui_da_nei_rong(biao: SpriteFrames, dong := &"you") -> Vector2:
	# 一个动画所有帧里最大的内容宽/高：给体长 / 体高（碰撞、边界、技能下限）用
	# 取最大而不是帧 0：摆尾 / 张嘴帧可能更宽，判定圈按整段动画的最大轮廓算才不会露馅
	if biao == null or not biao.has_animation(dong):
		return HUI_TUI_KUAN_GAO
	var zui := Vector2.ZERO
	for i in biao.get_frame_count(dong):
		var kuan_gao := nei_rong_kuan_gao(biao.get_frame_texture(dong, i))
		zui.x = maxf(zui.x, kuan_gao.x)
		zui.y = maxf(zui.y, kuan_gao.y)
	if zui.x <= 0.0 or zui.y <= 0.0:
		return HUI_TUI_KUAN_GAO
	return zui


static func qing_huan_cun() -> void:
	# 测试用：换美术 / 重导入后让缓存重新量（正式流程不需要调用）
	_nei_rong_huan_cun.clear()
	_yin_zi_huan_cun.clear()
