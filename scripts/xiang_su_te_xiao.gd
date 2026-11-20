extends RefCounted
class_name XiangSuTeXiao
# 像素特效素材加载器：pixelfx 导出的图集 PNG + Aseprite JSON → SpriteFrames
# 目录约定：
#   正式（选项 1）：res://assets/texiao_pixel/<名>/<名>.png 与 .json
#   待用（选项 2）：res://assets/待用/<名>.png 与 .json
#   v2（TASK-031）：res://assets/texiao_pixel/v2/<键>/texiao_<键>.json（按精确路径走 qu_lu）
# 读不到资源就返回空字典，调用方回退旧特效，绝不阻塞战斗
# 缓存按 JSON 路径：v1 按名字解析到路径后与 qu_lu 共用同一份缓存
# LRU 上限 24 套：单档高清每套约 0.8MB，长会话换场景不无限涨显存

const ZHENG_SHI_MU_LU := "res://assets/texiao_pixel/%s/%s.json"  # 正式目录模板
const DAI_YONG_MU_LU := "res://assets/待用/%s.json"  # 待用目录模板
const DONG := &"bao"  # 统一动画名：与旧特效一致
const JIU_ZHEN_KUAN := 274.0  # 旧特效帧宽（像素）：v1 像素版按这个屏幕足迹对齐
const HUI_TUI_YUAN_DIAN := Vector2.ZERO
const HUI_TUI_CHI_CUN := Vector2(136.0, 80.0)
const ZUI_DA_ZHU_SHU := 24  # 缓存上限：超出后释放最久未用的一套

static var _huan_cun := {}  # 缓存键（JSON 路径）→ 解析结果字典
static var _yong_ci := []  # LRU 顺序：末尾 = 最近使用


static func qu(ming: StringName) -> Dictionary:
	# v1 按名字取：{kuang, yuan_dian, chi_cun, xun_huan, fps, ...}
	# 无资源 / 解析失败 → 空字典（调用方走旧 4 帧）
	var json_lu := _zhao_json(String(ming))
	if json_lu.is_empty():
		return {}
	return qu_lu(json_lu)


static func qu_lu(json_lu: String) -> Dictionary:
	# v2 按精确 JSON 路径取（不扫目录）：返回字段多出
	# ke_jian_x/ke_jian_gao=不透明内容并集宽高；fit=对齐口径；blend/z_index/lifetime/anchor_mode
	if json_lu.is_empty() or not FileAccess.file_exists(json_lu):
		return {}
	if _huan_cun.has(json_lu):
		_ji_lu_yong(json_lu)
		return _huan_cun[json_lu]
	var jie := _du_lu(json_lu)
	if jie.is_empty():
		return {}
	_huan_cun[json_lu] = jie
	_ji_lu_yong(json_lu)
	_tao_tai_jiu()
	return jie


static func kuang(ming: StringName) -> SpriteFrames:
	# 只要 SpriteFrames：没有就返回 null
	return qu(ming).get("kuang") as SpriteFrames


static func kuang_lu(json_lu: String) -> SpriteFrames:
	# v2 路径版：只要 SpriteFrames
	return qu_lu(json_lu).get("kuang") as SpriteFrames


static func yuan_dian_pian_yi(ming: StringName) -> Vector2:
	# v1 的 AnimatedSprite2D offset：把 JSON pivot（特效原点）对准节点世界坐标
	# Godot 默认把帧中心放在节点位置，所以偏移 = 帧中心 - pivot
	return pian_yi(qu(ming))


static func pian_yi(jie: Dictionary, fan := false) -> Vector2:
	# 通用 offset：pivot 显式（v2 fit=native）直接算；v1 pivot=(0,0) 视为“左上哨兵”→按帧中心放
	# fan=true（水平翻转）时把 offset.x 取反，让锚点仍在原世界位置（直线技朝左时不会甩出去）
	if jie.is_empty():
		return HUI_TUI_YUAN_DIAN
	var chi: Vector2 = jie.get("chi_cun", HUI_TUI_CHI_CUN)
	var yuan: Vector2 = jie.get("yuan_dian", Vector2.ZERO)
	var pian := Vector2.ZERO
	if String(jie.get("fit", "")) == "native":
		pian = Vector2(chi.x * 0.5 - yuan.x, chi.y * 0.5 - yuan.y)
	elif yuan != Vector2.ZERO:
		pian = Vector2(chi.x * 0.5 - yuan.x, chi.y * 0.5 - yuan.y)
	if fan:
		pian.x = -pian.x
	return pian


static func guan_mo_bi(ming: StringName) -> float:
	# v1 像素 sheet 帧宽通常比旧 274 帧小：乘这个倍率让屏幕足迹接近旧版
	var jie := qu(ming)
	if jie.is_empty():
		return 1.0
	var chi: Vector2 = jie["chi_cun"]
	if chi.x <= 0.0:
		return 1.0
	return JIU_ZHEN_KUAN / chi.x


static func ke_jian_kuan(jie: Dictionary) -> float:
	# 可见内容宽：v2 烘焙时量的所有帧 alpha 并集；v1 回退整帧宽
	if jie.is_empty():
		return 1.0
	return maxf(float(jie.get("ke_jian_x", jie.get("chi_cun", HUI_TUI_CHI_CUN).x)), 1.0)


static func ke_jian_gao(jie: Dictionary) -> float:
	if jie.is_empty():
		return 1.0
	return maxf(float(jie.get("ke_jian_gao", jie.get("chi_cun", HUI_TUI_CHI_CUN).y)), 1.0)


static func qing_huan_cun() -> void:
	# 测试用：换图 / 重导入后让缓存重新解析（正式流程不需要调用）
	_huan_cun.clear()
	_yong_ci.clear()


static func zhu_shu() -> int:
	# 测试用：当前缓存套数（LRU 上限断言）
	return _huan_cun.size()


static func _ji_lu_yong(json_lu: String) -> void:
	var wei := _yong_ci.find(json_lu)
	if wei >= 0:
		_yong_ci.remove_at(wei)
	_yong_ci.append(json_lu)


static func _tao_tai_jiu() -> void:
	# 缓存超上限就丢最久未用的一套：只删字典引用，正在播的节点自己握着 SpriteFrames，不会被吃掉
	while _yong_ci.size() > ZUI_DA_ZHU_SHU:
		var zui_jiu: String = _yong_ci.pop_front()
		_huan_cun.erase(zui_jiu)


static func _zhao_json(ming: String) -> String:
	# 先找正式目录，再找待用目录
	for lu in [ZHENG_SHI_MU_LU % [ming, ming], DAI_YONG_MU_LU % ming]:
		if FileAccess.file_exists(lu):
			return lu
	return ""


static func _du_zi_liao(ming: String) -> Dictionary:
	# 兼容旧入口：按名字找到路径再解析
	var json_lu := _zhao_json(ming)
	if json_lu.is_empty():
		return {}
	return _du_lu(json_lu)


static func _du_lu(json_lu: String) -> Dictionary:
	# 读 JSON → 建 SpriteFrames；任何一步失败都返回 {}
	var wen := FileAccess.open(json_lu, FileAccess.READ)
	if wen == null:
		return {}
	var jie = JSON.parse_string(wen.get_as_text())
	wen.close()
	if not (jie is Dictionary):
		return {}
	var png_lu := json_lu.get_basename() + ".png"
	var tu := load(png_lu)
	if tu == null or not (tu is Texture2D):
		return {}
	var zhen_lie: Array = jie.get("frames", [])
	if zhen_lie.is_empty():
		return {}
	var pf: Dictionary = jie.get("meta", {}).get("pixelfx", {})
	var biao := SpriteFrames.new()
	biao.add_animation(DONG)
	biao.set_animation_speed(DONG, float(pf.get("fps", 12.0)))
	biao.set_animation_loop(DONG, bool(pf.get("loop", false)))
	for z in zhen_lie:
		var r: Dictionary = z.get("frame", {})
		if r.is_empty():
			continue
		var at := AtlasTexture.new()
		at.atlas = tu
		at.region = Rect2(float(r.get("x", 0)), float(r.get("y", 0)),
				float(r.get("w", 1)), float(r.get("h", 1)))
		biao.add_frame(DONG, at)
	var chi_lie: Array = pf.get("frameSize", [float(tu.get_width()), 101.0])
	var chi := Vector2(float(chi_lie[0]), float(chi_lie[1]))
	var yuan_lie: Array = pf.get("pivot", [chi.x * 0.5, chi.y * 0.5])
	var yuan := Vector2(float(yuan_lie[0]), float(yuan_lie[1]))
	var ke_lie: Array = pf.get("visible", [chi.x, chi.y])
	var ke := Vector2(float(ke_lie[0]), float(ke_lie[1]))
	var chi_xu := 0.0
	if bool(pf.get("loop", false)):
		chi_xu = float(pf.get("lifetime", 0.0))
	return {
		"lu": json_lu,
		"kuang": biao,
		"yuan_dian": yuan,
		"chi_cun": chi,
		"xun_huan": bool(pf.get("loop", false)),
		"fps": float(pf.get("fps", 12.0)),
		"ke_jian_x": ke.x,
		"ke_jian_gao": ke.y,
		"fit": String(pf.get("fit", "")),
		"blend": String(pf.get("blend", "normal")),
		"z_index": int(pf.get("zIndex", 5)),
		"lifetime": chi_xu,
		"anchor_mode": String(pf.get("anchorMode", "center")),
	}
