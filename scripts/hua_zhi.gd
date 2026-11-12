extends Node
# 画风切换管理器（Autoload HuaZhi）：像素风 / 经典2D 两套贴图热切换
# 原理：assets/sucai_classic/ 与 assets/sucai/ 同名同尺寸一一对应（419 张 png）；
# 游戏代码永远只引用 res://assets/sucai/ 路径。切换画风分三步：
# 1) 把目标风格的纹理加载进来，用 take_over_path 顶到 sucai 路径的缓存位上——
#    此后所有 load("res://assets/sucai/xxx.png") 都拿到目标风格（ResourceLoader 缓存层替换）；
# 2) 已加载的资源（动画 .tres 里的 AtlasTexture/SpriteFrames、场景树节点的纹理属性）逐一重新指向；
# 3) 视口纹理过滤切换：像素风 Nearest 保颗粒，经典2D Linear 平滑。
# 惯例：按路径找 CunDang（编译期零依赖，--script 测试不注册 Autoload 也能跑）

const XIANG_SU_GEN := "res://assets/sucai/"
const JING_DIAN_GEN := "res://assets/sucai_classic/"
const _ZUI_SHEN := 8  # 引用递归深度上限：visited 去重之外再加一道保险

var feng_ge := "xiang_su"  # 当前画风："xiang_su"（默认）/ "jing_dian"
var _qing_dan := PackedStringArray()  # sucai 下全部 png 的相对路径（两套目录同构）
var _ying_she := {}  # 本次切换的"旧纹理实例 id → 新纹理实例"映射：take_over_path 会清掉旧实例的
                     # resource_path，已加载引用（如 NengLi.tu_biao）只能靠实例映射找回新纹理


func _ready() -> void:
	_sao_qing_dan()
	# PC 版默认经典原版画风（2026-11-06 拍板：像素化只保留在手机版）：
	# 每次启动都回到原版，存档画风在 PC 上不生效；切换按钮保留、本次会话内仍可玩
	if OS.has_feature("pc"):
		_ying_yong("jing_dian")
		return
	# 启动即应用存档画风：Autoload 先于主场景 ready，先换缓存再加载场景，开局零闪烁零混合
	var cd := get_node_or_null("/root/CunDang")
	if cd != null and String(cd.get("hua_zhi_feng_ge")) == "jing_dian":
		_ying_yong("jing_dian")


func qie_huan() -> String:
	# 切换画风并落盘，返回切换后的画风（"xiang_su" / "jing_dian"）
	var xin := "jing_dian" if feng_ge == "xiang_su" else "xiang_su"
	_ying_yong(xin)
	var cd := get_node_or_null("/root/CunDang")
	if cd != null:
		cd.set("hua_zhi_feng_ge", xin)
		cd.call("xie_she_zhi")
	return xin


func _ying_yong(xin: String) -> void:
	feng_ge = xin
	var mu_biao_gen := JING_DIAN_GEN if xin == "jing_dian" else XIANG_SU_GEN
	_ying_she.clear()
	for rel in _qing_dan:
		var lu_jing := XIANG_SU_GEN + rel  # 游戏内统一从这个路径取图
		# 先记下缓存里现在的实例（被各处引用的旧纹理），再换缓存
		var jiu := ResourceLoader.load(lu_jing, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
		# 新素材可能暂时只有一套（如 2026-11-10 新增的专属主动图标）：目标画风缺图就保留原图继续，
		# 不能直接 load——缺文件会打 ERROR，八步门禁见到 ERROR 一律判红
		var mu_biao_lu := mu_biao_gen + rel
		if not ResourceLoader.exists(mu_biao_lu):
			continue
		var t := ResourceLoader.load(mu_biao_lu, "Texture2D", ResourceLoader.CACHE_MODE_REPLACE)
		if t == null:
			continue
		if t.resource_path != lu_jing:
			t.take_over_path(lu_jing)  # 顶掉缓存位：之后 load(lu_jing) 返回目标风格
		if jiu != null and jiu != t:
			_ying_she[jiu.get_instance_id()] = t
	_xiu_fu_su_cai_yin_yong()
	# 纹理过滤跟画风走：这是 project.godot 里 default_texture_filter 的运行时等价物
	var lv_jing: int = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR if xin == "jing_dian" \
			else Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	get_tree().root.canvas_item_default_texture_filter = lv_jing


func _sao_qing_dan() -> void:
	_qing_dan.clear()
	_sao_mu_lu(XIANG_SU_GEN, "")


func _sao_mu_lu(gen: String, qian_zhui: String) -> void:
	var dir := DirAccess.open(gen)
	if dir == null:
		return
	dir.list_dir_begin()
	var ming := dir.get_next()
	while ming != "":
		if ming != "." and ming != "..":
			if dir.current_is_dir():
				_sao_mu_lu(gen + ming + "/", qian_zhui + ming + "/")
			elif ming.ends_with(".png"):
				_jia_ru(qian_zhui + ming)
			elif ming.ends_with(".png.import"):
				# 导出 PCK 里没有 png 源文件，只有 .png.import 重映射元数据：还原成 png 路径
				_jia_ru(qian_zhui + ming.trim_suffix(".import"))
		ming = dir.get_next()
	dir.list_dir_end()


func _jia_ru(lu: String) -> void:
	# 去重：编辑器里同目录会同时列出 .png 和 .png.import，归一后只留一份
	if not _qing_dan.has(lu):
		_qing_dan.append(lu)


func _xiu_fu_su_cai_yin_yong() -> void:
	# 缓存换完，修复所有已存在的引用：data/ 下的资源 + 场景树现存的节点
	var yi_fang := {}
	for gen in ["res://data/", "res://scenes/"]:
		var wen_jian := PackedStringArray()
		_ji_wen_jian(gen, wen_jian)
		for lu in wen_jian:
			var zi_yuan := ResourceLoader.load(lu, "", ResourceLoader.CACHE_MODE_REUSE)
			if zi_yuan != null:
				_xiu_fu_dui_xiang(zi_yuan, yi_fang, 0)
	_xiu_fu_dui_xiang(get_tree().root, yi_fang, 0)


func _ji_wen_jian(gen: String, jie_guo: PackedStringArray) -> void:
	var dir := DirAccess.open(gen)
	if dir == null:
		return
	dir.list_dir_begin()
	var ming := dir.get_next()
	while ming != "":
		if ming != "." and ming != "..":
			if dir.current_is_dir():
				_ji_wen_jian(gen + ming + "/", jie_guo)
			elif ming.ends_with(".tres") or ming.ends_with(".tscn"):
				jie_guo.append(gen + ming)
		ming = dir.get_next()
	dir.list_dir_end()


func _xiu_fu_dui_xiang(dui_xiang: Object, yi_fang: Dictionary, shen_du: int) -> void:
	# 通用引用修复：走属性表找 Texture2D/AtlasTexture/SpriteFrames，逐个重新指向目标风格
	if dui_xiang == null or shen_du > _ZUI_SHEN:
		return
	var id := dui_xiang.get_instance_id()
	if yi_fang.has(id):
		return
	yi_fang[id] = true
	if dui_xiang is SpriteFrames:
		_xiu_fu_dong_hua_zhen(dui_xiang)  # 帧表内部不暴露为属性，走专用 API
	elif dui_xiang is AtlasTexture:
		var su_cai: Texture2D = dui_xiang.atlas
		if su_cai != null:
			var xin_a := _huan_tie(su_cai)
			if xin_a != null:
				dui_xiang.atlas = xin_a
	else:
		for shu_xing in dui_xiang.get_property_list():
			var zhi: Variant = dui_xiang.get(shu_xing.name)
			if zhi is Texture2D:
				var xin_t := _huan_tie(zhi)
				if xin_t != null:
					dui_xiang.set(shu_xing.name, xin_t)
			elif zhi is AtlasTexture:
				_xiu_fu_dui_xiang(zhi, yi_fang, shen_du + 1)
			elif zhi is SpriteFrames:
				_xiu_fu_dong_hua_zhen(zhi)
			elif zhi is Resource:
				_xiu_fu_dui_xiang(zhi, yi_fang, shen_du + 1)
	if dui_xiang is Node:
		for hai_zi in dui_xiang.get_children():
			_xiu_fu_dui_xiang(hai_zi, yi_fang, shen_du + 1)


func _xiu_fu_dong_hua_zhen(zhen: SpriteFrames) -> void:
	for dong_hua in zhen.get_animation_names():
		for i in zhen.get_frame_count(dong_hua):
			var t := zhen.get_frame_texture(dong_hua, i)
			if t is AtlasTexture:
				var xin_a := _huan_tie(t.atlas)
				if xin_a != null:
					t.atlas = xin_a
			elif t != null:
				var xin_t := _huan_tie(t)
				if xin_t != null:
					zhen.set_frame(dong_hua, i, xin_t)


func _huan_tie(t: Texture2D) -> Texture2D:
	# 先查实例映射（take_over_path 清了旧实例的路径标记，路径查不到它们），再按路径兜底
	if t == null:
		return null
	if _ying_she.has(t.get_instance_id()):
		return _ying_she[t.get_instance_id()]
	var lu := t.resource_path
	if lu == "" or not lu.begins_with(XIANG_SU_GEN):
		return null
	var xin := ResourceLoader.load(lu, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
	if xin == null or xin == t:
		return null
	return xin
