extends RefCounted
class_name TeXiaoKu
# pixelfx v2 特效运行时（TASK-031）：语义反馈 / 状态光环 / 界面特效 / 技能段播放
# 口径（用户硬要求）：技能特效屏幕尺寸跟体型走——
#   范围型宽 = 判定直径（ji_neng_ban_jing × 2），贴身/命中宽 = 鱼实际体长 × 系数，
#   全屏技固定为视口尺寸。节点缩放 = 目标像素宽 ÷ 该图集“不透明内容并集宽”。
# 资源缺失 / 主开关关闭 → 返回 null，调用方保留旧 TeXiao 回退，不阻塞战斗。
# 动画名统一 bao；所有 v2 节点进组 xiang_su_te_xiao（测试基线）与 te_xiao_v2（排查）。

const SHI_YONG_V2 := true  # 总开关：false = 全部回退旧 4 帧 / 待用像素版（不删代码）
const ZU_V2 := &"te_xiao_v2"
# 跟随特效脚本：bo_ming 传 {"gen_sui": 节点} 时挂上，特效每帧贴着该节点走（罩身光环/目标标记）
const GEN_SUI_JIAO_BEN := preload("res://scripts/te_xiao_gen_sui.gd")

# 通用战斗反馈：声音语义 → {key=v2 资源键, kuan=尺码口径: shi_zhe 施放者体长 / mu_biao 目标体长 / gu_ding 固定像素, bei=系数, y=?}
const FAN_KUI := {
	&"ming_zhong": {"key": &"fb_ming_zhong", "kuan": "shi_zhe", "bei": 0.75},
	&"zhi_ming": {"key": &"fb_zhi_ming", "kuan": "shi_zhe", "bei": 0.75},
	&"zhi_ming_shu": {"key": &"fb_zhi_ming_shu", "kuan": "mu_biao", "bei": 0.85, "y": -0.55},
	&"shou_ji": {"key": &"fb_shou_ji", "kuan": "mu_biao", "bei": 0.8},
	&"bao_lie": {"key": &"fb_bao_lie", "kuan": "shi_zhe", "bei": 0.8},
	&"fan_shang": {"key": &"fb_fan_shang", "kuan": "shi_zhe", "bei": 0.85},
	&"fan_shang_fen": {"key": &"fb_fan_shang_fen", "kuan": "shi_zhe", "bei": 0.85},
	&"tun_shui": {"key": &"fb_tun_shui", "kuan": "mu_biao", "bei": 0.8},
	&"tun_yan": {"key": &"fb_tun_yan", "kuan": "mu_biao", "bei": 0.6},
	&"bei_yao_si": {"key": &"fb_bei_yao_si", "kuan": "mu_biao", "bei": 0.8},
	&"si_wang": {"key": &"fb_si_wang", "kuan": "shi_zhe", "bei": 1.0},
	&"sheng_ji": {"key": &"fb_sheng_ji", "kuan": "shi_zhe", "bei": 1.2},
	&"xiao_hua": {"key": &"fb_xiao_hua", "kuan": "shi_zhe", "bei": 0.65},
	&"chi_rou": {"key": &"fb_chi_rou", "kuan": "gu_ding", "bei": 52.0},
	&"lian_suo": {"key": &"fb_lian_suo", "kuan": "shi_zhe", "bei": 0.85},
	&"bian_jie": {"key": &"fb_bian_jie", "kuan": "gu_ding", "bei": 90.0},
	&"jin_hua": {"key": &"sys_jin_hua", "kuan": "shi_zhe", "bei": 0.9},
	&"xuan_jiao": {"key": &"sys_xuan_jiao", "kuan": "shi_zhe", "bei": 1.1},
	&"shi_rou": {"key": &"sys_shi_rou", "kuan": "shi_zhe", "bei": 0.55},
}

# 状态槽名 → 头顶光环资源（六色互斥：石化灰白/魅惑粉/电麻电黄/毒晕绿/恐惧黑紫/疯狂洋红）
const ZHUANG_TAI_KU := {
	&"shi_hua": &"zt_shi_hua",
	&"feng_kuang": &"zt_feng_kuang",
	&"kong_ju": &"zt_kong_ju",
	&"mei_huo": &"zt_mei_huo",
	&"dian_ma": &"zt_dian_ma",
	&"du_yun": &"zt_du_yun",
}

# 全屏 / 界面特效：key → {key=资源键, kuan=视口倍率 或 kuan_px=固定像素, wei_y=纵向位置 0~1}
const JIE_MIAN_KU := {
	&"san_xuan": {"key": &"fb_san_xuan", "kuan": 1.2},
	&"jing_sha": {"key": &"fb_jing_sha", "kuan": 1.25},
	&"zhuan_chang": {"key": &"sys_zhuan_chang", "kuan": 1.25},
	&"cheng_jiu": {"key": &"sys_cheng_jiu", "kuan": 0.55, "wei_y": 0.22},
	&"xuan_jiao": {"key": &"sys_xuan_jiao", "kuan_px": 420.0, "wei_y": 0.5},
	&"lian_suo": {"key": &"fb_lian_suo", "kuan_px": 300.0, "wei_y": 0.28},
	&"bian_jie": {"key": &"fb_bian_jie", "kuan_px": 90.0},
	&"xue_tiao": {"key": &"sys_xue_tiao", "kuan_px": 90.0},
}

# 主动技 id → v2 资源键（NengLiKu.ZHU_DONG 42 条全覆盖；注册表测试锁死，漏接即门禁红）
const JI_NENG_KU := {
	# 通用池 12
	&"chang_mao_chuan_ci": &"jn_chang_mao",
	&"fang_dian_ma_bi": &"jn_fang_dian",
	&"ji_su_tu_jin": &"jn_ji_su",
	&"kuang_bao_si_yao": &"jn_kuang_bao",
	&"ni_liu_shan_bi": &"jn_ni_liu",
	&"qian_fu_tu_xi": &"jn_qian_fu",
	&"ruo_dian_dong_cha": &"jn_ruo_dian",
	&"xuan_wo": &"jn_xuan_wo",
	&"xue_xing_kuang_re": &"jn_xue_xing",
	&"ying_ke_hu_ti": &"jn_ying_ke",
	&"you_er_qi_pao": &"jn_you_er",
	&"yu_lei_chong_ci": &"jn_yu_lei",
	# 进化专属 30（H10 跳过，不在 NengLiKu 中）
	&"tai_sui_ge_rou": &"tai_sui_poof",
	&"qiang_suan_pen_tu": &"qiang_suan",
	&"chao_ya_shui_dao": &"chao_ya",
	&"lei_bao_zhao_huan": &"lei_bao_yun",
	&"jiu_tou_dian_wang": &"jiu_tou",
	&"ci_chang_hu_bi": &"ci_chang",
	&"huan_feng": &"huan_feng",
	&"you_ling_qi_she": &"you_ling",
	&"po_kong_fu_chong": &"po_kong",
	&"luo_xuan_zuan_tu": &"luo_xuan",
	&"ju_du_tu_ci": &"ju_du",
	&"kong_jian_lie_feng": &"kong_jian",
	&"kong_que_huan_ying": &"kong_que",
	&"shi_hua_zhi_tong": &"shi_hua_tong",
	&"ji_guan_fan_jia": &"ji_guan",
	&"liu_xing_yue": &"liu_xing",
	&"shen_ju_chong_feng": &"shen_ju",
	&"qian_yan_qi_she": &"qian_yan",
	&"gui_huo_yin_lu": &"gui_huo",
	&"xing_chen_yin_xing": &"xing_chen",
	&"lin_guang_bao_shan": &"lin_guang",
	&"kun_tun_tian_di": &"kun_tun",
	&"shen_yuan_xuan_wo": &"shen_yuan",
	&"tun_xing": &"tun_xing",
	&"tao_tie_ju_tun": &"tao_tie",
	&"lie_kou_xian_jing": &"lie_kou",
	&"she_hun": &"she_hun",
	&"ying_ju_cheng_long": &"ying_ju",
	&"zu_zhou_bao_zi": &"zu_zhou",
	&"deng_li_zi_qi_she": &"deng_li_zi",
}

# 机械船四招 → v2 资源键（船不是 NengLi，单独一组给覆盖测试）
const CHUAN_KU: Array[StringName] = [&"chuan_zha_dan", &"chuan_chuan_mao", &"chuan_tan_zhao", &"chuan_yu_cha"]


static func ji_neng_key(bian_hao: StringName) -> StringName:
	# 技能 id → 特效键；未登记返回空名（调用方可回退旧特效）
	return JI_NENG_KU.get(bian_hao, &"")


static func zi_yuan(key: StringName) -> Dictionary:
	# v2 资源表查条目（表由烘焙脚本生成）
	var biao = TeXiaoKuZiYuan.ZI_YUAN
	return biao.get(String(key), {})


static func you(key: StringName) -> bool:
	# 是否有可用资源（测试 / 调用方判回退）
	var zi := zi_yuan(key)
	if zi.is_empty() or not SHI_YONG_V2:
		return false
	return not XiangSuTeXiao.qu_lu(String(zi["lu"])).is_empty()


static func ti_kuan(node: Node, mo_ren := 100.0) -> float:
	# 鱼的实际体长（世界像素）：玩家 yu.gd / NPC yu_npc.gd 都有 ti_chang()
	if node != null and is_instance_valid(node) and node.has_method(&"ti_chang"):
		return maxf(float(node.call(&"ti_chang")), 1.0)
	return mo_ren


static func ti_gao(node: Node, mo_ren := 80.0) -> float:
	if node != null and is_instance_valid(node) and node.has_method(&"ti_gao"):
		return maxf(float(node.call(&"ti_gao")), 1.0)
	return mo_ren


static func ban_jing_kuan(node: Node, neng, dang: int, xi_shu := 2.0) -> float:
	# 范围型目标像素宽：直接借 yu.gd 的判定半径唯一入口（身位/固定像素/体长下限都已算好）
	# 否则特效和判定圈差 34%（100 vs 152 基准），验收 ±10% 过不了
	if node == null or not is_instance_valid(node) or not node.has_method(&"ji_neng_ban_jing"):
		return 100.0
	return maxf(float(node.call(&"ji_neng_ban_jing", neng, dang)) * xi_shu, 1.0)


static func bo_ming(key: StringName, gen: Node, wei: Vector2, kuan_px: float,
		can_shu: Dictionary = {}) -> AnimatedSprite2D:
	# 世界坐标播一套 v2 特效：kuan_px = 屏幕目标宽（像素），按可见内容宽换算节点缩放
	if not SHI_YONG_V2:
		return null
	if gen == null or not is_instance_valid(gen) or not gen.is_inside_tree():
		return null
	var zi := zi_yuan(key)
	if zi.is_empty():
		return null
	var jie := XiangSuTeXiao.qu_lu(String(zi["lu"]))
	if jie.is_empty():
		return null
	var fan := bool(can_shu.get("fan", false))
	var fx := _jian_chi(jie, fan)
	var bi := maxf(kuan_px, 1.0) / XiangSuTeXiao.ke_jian_kuan(jie)
	fx.scale = Vector2.ONE * bi * float(can_shu.get("bei", 1.0))
	if can_shu.has("tint"):
		fx.modulate = can_shu["tint"]
	fx.set_meta(&"texiao_key", key)
	gen.add_child(fx)
	fx.global_position = wei
	var gen_sui: Node2D = can_shu.get("gen_sui")
	if gen_sui != null and is_instance_valid(gen_sui):
		# 跟随：挂 TeXiaoGenSui，每帧贴到目标当前位置 + 生成时偏移
		fx.set_script(GEN_SUI_JIAO_BEN)
		fx.set(&"mu_biao", gen_sui)
		fx.set(&"pian_yi", wei - gen_sui.global_position)
	_bu_chong(fx, jie, can_shu)
	return fx


static func bo_fan_kui(ming: StringName, gen: Node, wei: Vector2, mu: Node = null,
		bei := 1.0, can_shu: Dictionary = {}) -> AnimatedSprite2D:
	# 通用战斗反馈：按语义查表，尺寸随施放者/目标体长
	var pei: Dictionary = FAN_KUI.get(ming, {})
	if pei.is_empty():
		return null
	var kuan := 0.0
	match String(pei.get("kuan", "shi_zhe")):
		"mu_biao":
			var can_kao := mu if mu != null else gen
			kuan = ti_kuan(can_kao) * float(pei.get("bei", 1.0)) * bei
		"gu_ding":
			kuan = float(pei.get("bei", 100.0)) * bei
		_:
			# shi_zhe：优先用调用方显式传的施放者（gen 往往只是世界容器，量不到体长）
			var can_kao: Node = can_shu.get("shi_zhe")
			if can_kao == null or not is_instance_valid(can_kao):
				can_kao = mu if mu != null else gen
			kuan = ti_kuan(can_kao) * float(pei.get("bei", 1.0)) * bei
	var can_kao2 := mu if mu != null else gen
	var dian := wei + Vector2(0.0, float(pei.get("y", 0.0)) * ti_gao(can_kao2))
	return bo_ming(pei["key"], gen, dian, kuan, can_shu)


static func bo_jie_mian(ming: StringName, can_shu: Dictionary = {}) -> AnimatedSprite2D:
	# 屏幕坐标播界面/全屏特效：懒建 TeXiaoUI（CanvasLayer layer 50，低于弹窗 100）
	# 不挂相机：换场景跟着 current_scene 走；全屏技宽度固定为视口尺寸，不随体型
	if not SHI_YONG_V2:
		return null
	var pei: Dictionary = JIE_MIAN_KU.get(ming, {})
	if pei.is_empty():
		return null
	var zi := zi_yuan(pei["key"])
	if zi.is_empty():
		return null
	var jie := XiangSuTeXiao.qu_lu(String(zi["lu"]))
	if jie.is_empty():
		return null
	var chang_jing := _chang_jing(bool(can_shu.get("chang_zhu", false)))
	if chang_jing == null:
		return null
	var ceng := _jie_mian_ceng(chang_jing)
	if ceng == null:
		return null
	var shi_kou := chang_jing.get_viewport().get_visible_rect().size
	var mo_ren_kuan := float(pei.get("kuan_px", maxf(shi_kou.x, shi_kou.y) * float(pei.get("kuan", 1.0))))
	var kuan := float(can_shu.get("kuan", mo_ren_kuan))
	var wei := Vector2(shi_kou.x * 0.5, shi_kou.y * float(pei.get("wei_y", 0.5)))
	if can_shu.has("wei"):
		wei = can_shu["wei"]
	var fx := _jian_chi(jie, false)
	fx.scale = Vector2.ONE * (maxf(kuan, 1.0) / XiangSuTeXiao.ke_jian_kuan(jie))
	if can_shu.has("tint"):
		fx.modulate = can_shu["tint"]
	fx.set_meta(&"texiao_key", pei["key"])
	ceng.add_child(fx)
	fx.position = wei
	_bu_chong(fx, jie, can_shu)
	return fx


static func san_xuan() -> void:
	# 三选一登场：三根光柱按卡片位置立在屏幕 1/4、2/4、3/4 处；红/蓝/绿靠 modulate 上色（底图是中性白）
	var shi_kou := shi_kou_chi_cun()
	var yan := [Color(1.0, 0.42, 0.36), Color(0.42, 0.68, 1.0), Color(0.45, 1.0, 0.55)]
	for i in 3:
		bo_jie_mian(&"san_xuan", {
			"wei": Vector2(shi_kou.x * (0.25 + 0.25 * float(i)), shi_kou.y * 0.45),
			"kuan": 230.0,
			"tint": yan[i],
		})


static func lian_suo() -> void:
	# 暴食连锁：UI 层金数字（资源烘成 x2 COMBO，正好对应窗口期 ×2 咬伤），不随体型缩放
	bo_jie_mian(&"lian_suo")


static func xuan_jiao() -> void:
	# 选角达成：屏幕中央开箱金光；挂根节点（chang_zhu）——切到 Main 后仍能走完 1.6 秒
	bo_jie_mian(&"xuan_jiao", {"chang_zhu": true})


static func zhuan_chang() -> void:
	# 章节 / 死亡转场：全屏像素溶解；挂根节点，切场景时不被一起拆掉
	bo_jie_mian(&"zhuan_chang", {"chang_zhu": true})


static func bian_jie(chao: Vector2) -> void:
	# 边界收缩警告：贴屏幕对应边缘的小标记，固定尺寸（不随体型、不随相机）
	if chao.length_squared() < 0.0001:
		return
	var shi_kou := shi_kou_chi_cun()
	var bian := 52.0
	var wei := shi_kou * 0.5
	if absf(chao.x) >= absf(chao.y):
		wei.x = bian if chao.x < 0.0 else shi_kou.x - bian
	else:
		wei.y = bian if chao.y < 0.0 else shi_kou.y - bian
	bo_jie_mian(&"bian_jie", {"wei": wei})


static func shi_kou_chi_cun() -> Vector2:
	# 当前视口尺寸：UI 定位 / 全屏技换算用
	var chang_jing := _chang_jing()
	if chang_jing == null:
		return Vector2(1280.0, 720.0)
	return chang_jing.get_viewport().get_visible_rect().size


static func gua_zhuang_tai(ming: StringName, mu: Node, bei := 1.2,
		can_shu: Dictionary = {}) -> AnimatedSprite2D:
	# 状态光环：挂目标头顶（局部坐标，跟鱼走），宽度随目标体长；同名先清旧的
	if not SHI_YONG_V2 or mu == null or not is_instance_valid(mu) or not mu.is_inside_tree():
		return null
	var key: StringName = ZHUANG_TAI_KU.get(ming, &"")
	if String(key) == "":
		return null
	xia_zhuang_tai(ming, mu)
	var zi := zi_yuan(key)
	if zi.is_empty():
		return null
	var jie := XiangSuTeXiao.qu_lu(String(zi["lu"]))
	if jie.is_empty():
		return null
	var fx := _jian_chi(jie, false)
	# 光环盖在鱼头上方：不挡身体；z 提到 6（状态要一眼可见）
	fx.z_index = int(can_shu.get("z", 6))
	var kuan := ti_kuan(mu) * maxf(bei, 0.1)
	fx.scale = Vector2.ONE * (kuan / XiangSuTeXiao.ke_jian_kuan(jie))
	fx.set_meta(&"texiao_key", key)
	fx.set_meta(&"texiao_zt", ming)
	mu.add_child(fx)
	fx.position = Vector2(0.0, -ti_gao(mu) * 0.75)
	_bu_chong(fx, jie, can_shu)
	return fx


static func xia_zhuang_tai(ming: StringName, mu: Node) -> void:
	# 状态结束：把同名光环淡出释放（状态系统在计时结束时调）
	if mu == null or not is_instance_valid(mu):
		return
	for zi in mu.get_children():
		if zi is AnimatedSprite2D and zi.has_meta(&"texiao_zt") \
				and String(zi.get_meta(&"texiao_zt")) == String(ming):
			shan_chu(zi)


static func qing_zhuang_tai(mu: Node) -> void:
	# 死亡 / 复活：清空全部状态光环
	if mu == null or not is_instance_valid(mu):
		return
	for zi in mu.get_children():
		if zi is AnimatedSprite2D and zi.has_meta(&"texiao_zt"):
			shan_chu(zi)


static func shan_chu(fx: Node) -> void:
	# 立刻释放（不淡出）：给状态清除 / 场景收尾用
	if fx != null and is_instance_valid(fx):
		fx.queue_free()


static func _jian_chi(jie: Dictionary, fan: bool) -> AnimatedSprite2D:
	# 建节点：最近邻、按 pivot 摆原点、叠加混合、分组
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = jie["kuang"]
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx.z_index = int(jie.get("z_index", 5))
	if String(jie.get("blend", "normal")) == "add":
		var cai := CanvasItemMaterial.new()
		cai.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		fx.material = cai
	fx.offset = XiangSuTeXiao.pian_yi(jie, fan)
	fx.flip_h = fan
	fx.add_to_group(&"xiang_su_te_xiao")
	fx.add_to_group(ZU_V2)
	return fx


static func _bu_chong(fx: AnimatedSprite2D, jie: Dictionary, can_shu: Dictionary) -> void:
	# 播放与寿命：一次性播完自毁；循环/长特效按 chi_xu 秒淡出（0 且循环 = 调用方负责释放，如状态光环）
	fx.play(&"bao")
	if not bool(jie.get("xun_huan", false)):
		fx.animation_finished.connect(func() -> void:
			if is_instance_valid(fx):
				fx.queue_free())
	var chi = can_shu.get("chi_xu", jie.get("lifetime", 0.0))
	var shi_chang := float(chi) if chi != null else 0.0
	if shi_chang > 0.0:
		_ding_shi_xiao_hui(fx, shi_chang)


static func _ding_shi_xiao_hui(fx: AnimatedSprite2D, shi_chang: float) -> void:
	# 定时淡出：循环特效没有 animation_finished，按时间收；最后 0.15 秒渐隐
	# WeakRef 拿节点，避免特效先自毁时 lambda 抓已释放对象报 capture freed
	var shu := fx.get_tree()
	if shu == null:
		return
	var ruan: WeakRef = weakref(fx)
	var ding := shu.create_timer(shi_chang)
	ding.timeout.connect(func() -> void:
		var zhu = ruan.get_ref()
		if zhu == null or not is_instance_valid(zhu) or zhu.is_queued_for_deletion():
			return
		var tui: Tween = zhu.create_tween()
		tui.tween_property(zhu, "modulate:a", 0.0, 0.15)
		var ruan_tui: WeakRef = weakref(zhu)
		tui.finished.connect(func() -> void:
			var zui = ruan_tui.get_ref()
			if zui != null and is_instance_valid(zui):
				zui.queue_free()))


static func _chang_jing(chang_zhu := false) -> Node:
	# 当前场景根：界面特效挂它下面，换场景自动清掉
	# chang_zhu=true → 挂 SceneTree.root：死亡/转场时切场景后特效还能走完
	var shu := Engine.get_main_loop() as SceneTree
	if shu == null:
		return null
	if chang_zhu:
		if shu.root != null and shu.root.is_inside_tree():
			return shu.root
		return null
	var chang_jing: Node = shu.current_scene
	if chang_jing != null and chang_jing.is_inside_tree():
		return chang_jing
	if shu.root != null and shu.root.is_inside_tree():
		return shu.root
	return null


static func _jie_mian_ceng(chang_jing: Node) -> CanvasLayer:
	# 懒建 TeXiaoUI：屏幕坐标层，放在弹窗（100）之下，游戏世界之上
	# process_mode=Always：三选一弹窗会暂停树，光柱/开箱这些界面特效仍要能播完
	var ceng := chang_jing.get_node_or_null(^"TeXiaoUI") as CanvasLayer
	if ceng == null:
		ceng = CanvasLayer.new()
		ceng.name = "TeXiaoUI"
		ceng.layer = 50
		ceng.process_mode = Node.PROCESS_MODE_ALWAYS
		chang_jing.add_child(ceng)
	return ceng
