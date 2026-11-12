extends RefCounted
# 灯笼鱼（ye_deng_long_yu）专属技模块——3 分支 ×（1 主动 + 1 被动）
# 契约见 docs/专属技模块_开发契约.md
# 三条分支：幽冥引路灯（鬼火引路/幽冥体）、星落游魂（星辰隐形/星座余晖）、
# 爆裂磷光兽（磷光爆闪/爆裂体质）。数值全部从 NengLi 读，模块只管行为与状态。

const ZHU_DONG_IDS: Array[StringName] = [&"gui_huo_yin_lu", &"xing_chen_yin_xing", &"lin_guang_bao_shan"]
const BEI_DONG_IDS: Array[StringName] = [&"you_ming_ti", &"xing_zuo_yu_hui", &"bao_lie_ti_zhi"]

const TE_XIAO := preload("res://scripts/te_xiao.gd")
const DIAN_TE_XIAO: SpriteFrames = preload("res://data/donghua/dian_texiao_4zhen.tres")

# 每玩家状态：全部走 yu 的 meta，不给 Yu 加成员变量
const META_GUI_HUO := &"zs_gui_huo_yin_lu_huo"  # {huo: Node2D, mu: Node2D}
const META_YIN_SHEN := &"zs_xing_chen_yin_xing"  # {sheng_yu: float, shou_ci: bool}
const META_LIN_GUANG := &"zs_lin_guang_bao_shan"  # {qian_yao: float, fan_zhi_mang: float}

const GUI_HUO_ZHEN_MING := "YeDengGuiHuo"  # 鬼火节点名：自测按名查找
const QIAN_YAO_SHI_CHANG := 0.5  # 行为常量：磷光爆闪前摇（前摇期间玩家仍可行动）
const FAN_ZHI_MANG_YAO_SHANG_BEI := 0.75  # 反致盲期间咬伤倍率：看不见弱点 = ×0.75
const GUI_HUO_CHU_SHI_BIAN := 0.55  # 鬼火视觉大小（像素倍数，行为常量）
const GUI_HUO_ZI_HUI_JIE_DIAN := "ZiHui"  # 鬼火自毁计时器名


static func guan_zhu_dong(bian_hao: StringName) -> bool:
	return ZHU_DONG_IDS.has(bian_hao)


static func zhu_dong_ids() -> Array[StringName]:
	return ZHU_DONG_IDS


static func bei_dong_ids() -> Array[StringName]:
	return BEI_DONG_IDS


static func shi_fang(yu, neng: NengLi, dang: int) -> bool:
	# 主动释放：返回 true 才扣冷却/播音效；false = 空放（条件不足）
	if yu == null or neng == null:
		return false
	match neng.bian_hao:
		&"gui_huo_yin_lu":
			return _shi_fang_gui_huo(yu, neng, dang)
		&"xing_chen_yin_xing":
			return _shi_fang_xing_chen(yu, neng, dang)
		&"lin_guang_bao_shan":
			return _shi_fang_lin_guang(yu, neng, dang)
	return false


static func geng_xin(yu, neng: NengLi, delta: float) -> void:
	# 每帧：只对已装备技能调用（框架已过滤）；持续效果、召唤物、节拍都写这里
	if yu == null or neng == null:
		return
	match neng.bian_hao:
		&"gui_huo_yin_lu":
			_geng_gui_huo(yu, neng, delta)
		&"xing_chen_yin_xing":
			_geng_xing_chen(yu, neng, delta)
		&"lin_guang_bao_shan":
			_geng_lin_guang(yu, neng, delta)
		_:
			pass  # 三个被动没有每帧效果：xing_zuo 的 1s 由隐身结束/破隐瞬间给


static func shi_jian(yu, neng: NengLi, jian: StringName, shu_ju: Dictionary) -> bool:
	# 事件钩子：返回 true = 事件被吃掉（主流程立刻 return）
	if yu == null or neng == null:
		return false
	match neng.bian_hao:
		&"xing_chen_yin_xing":
			return _shi_jian_xing_chen(yu, neng, jian, shu_ju)
		&"xing_zuo_yu_hui":
			return _shi_jian_xing_zuo(yu, neng, jian, shu_ju)
		&"bao_lie_ti_zhi":
			return _shi_jian_bao_lie(yu, neng, jian, shu_ju)
	return false


static func wen(yu, neng: NengLi, jian: StringName, shu_ju: Dictionary) -> float:
	# 数值查询：返回倍率；没装备时框架直接不调用，默认 1.0
	if yu == null or neng == null:
		return 1.0
	match neng.bian_hao:
		&"xing_chen_yin_xing":
			return _wen_xing_chen(yu, neng, jian, shu_ju)
		&"you_ming_ti":
			return _wen_you_ming(yu, neng, jian, shu_ju)
		&"lin_guang_bao_shan":
			return _wen_lin_guang(yu, neng, jian, shu_ju)
	return 1.0


# ---- 通用小工具 ----

static func _zhi(neng: NengLi, jian: StringName, dang: int) -> float:
	# 统一从能力表读值：专属技单档，dang_zhi 没写档位表就回退基础字段
	return neng.dang_zhi(jian, dang)


static func _zui_jin_npc(yu) -> Node2D:
	# 最近的活 NPC：跳过 si_le / 无效实例；首领也是 NPC（命中后由 jia_zhuang_tai 自己免疫）
	if yu == null or not is_instance_valid(yu) or not yu.is_inside_tree():
		return null
	var zui_jin: Node2D = null
	var zui_jin_ju := INF
	for node in yu.get_tree().get_nodes_in_group(&"yu_npc"):
		var npc := node as YuNpc
		if npc == null or not is_instance_valid(npc) or npc.si_le:
			continue
		var ju: float = yu.global_position.distance_squared_to(npc.global_position)
		if ju < zui_jin_ju:
			zui_jin_ju = ju
			zui_jin = npc
	return zui_jin


# ---- 鬼火引路（幽冥引路灯·主动）----

static func _shi_fang_gui_huo(yu, neng: NengLi, dang: int) -> bool:
	# 空放：场上没有可飞向的活鱼 → false（不扣冷却）
	var mu := _zui_jin_npc(yu)
	if mu == null:
		return false
	var huo := _zao_gui_huo(yu, neng, dang)
	if huo == null:
		return false
	yu.set_meta(META_GUI_HUO, {"huo": huo, "mu": mu})
	return true


static func _zao_gui_huo(yu, neng: NengLi, dang: int) -> Node2D:
	# 鬼火视觉：挂场景层，不继承玩家体型缩放；Timer 自毁保证卸下技能也不会留孤儿节点
	var gen: Node = yu.get_parent()
	if gen == null or not is_instance_valid(gen) or not gen.is_inside_tree():
		return null
	var huo := Sprite2D.new()
	huo.name = GUI_HUO_ZHEN_MING
	huo.texture = DIAN_TE_XIAO.get_frame_texture(&"bao", 0)
	huo.scale = Vector2.ONE * GUI_HUO_CHU_SHI_BIAN
	huo.modulate = Color(0.55, 1.0, 0.82, 1.0)
	huo.z_index = 5
	var cai := CanvasItemMaterial.new()
	cai.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD  # 发光叠色，深海里不会出现黑方块
	huo.material = cai
	gen.add_child(huo)
	huo.global_position = yu.global_position
	var timer := Timer.new()
	timer.name = GUI_HUO_ZI_HUI_JIE_DIAN
	timer.wait_time = maxf(0.01, _zhi(neng, &"fu_shu_zhi", dang))
	timer.one_shot = true
	timer.timeout.connect(huo.queue_free)
	huo.add_child(timer)
	timer.start()
	return huo


static func _geng_gui_huo(yu, neng: NengLi, delta: float) -> void:
	# 每帧把鬼火朝目标推进；到达后上魅惑，落点=鬼火当前位置（NPC 反向追随该点）
	if not yu.has_meta(META_GUI_HUO):
		return
	var zhuang = yu.get_meta(META_GUI_HUO)
	if not (zhuang is Dictionary):
		return
	var huo = zhuang.get("huo", null) as Node2D
	var mu = zhuang.get("mu", null) as Node2D
	if huo == null or not is_instance_valid(huo):
		yu.remove_meta(META_GUI_HUO)
		return
	if mu == null or not is_instance_valid(mu) or (mu is YuNpc and (mu as YuNpc).si_le):
		huo.queue_free()  # 目标先死：鬼火散掉，不飞向尸体
		yu.remove_meta(META_GUI_HUO)
		return
	var bu: float = maxf(0.0, _zhi(neng, &"shu_zhi", 1)) * yu._shen_wei() * maxf(0.0, delta)
	if bu <= 0.0:
		return
	if huo.global_position.distance_to(mu.global_position) <= bu + 8.0:
		huo.global_position = mu.global_position
		if mu.has_method("jia_zhuang_tai"):
			mu.call("jia_zhuang_tai", &"mei_huo", maxf(0.0, _zhi(neng, &"chi_xu", 1)), huo.global_position)
		if yu.get_parent() != null:
			TE_XIAO.bo(yu.get_parent(), DIAN_TE_XIAO, huo.global_position, 0.9)
		huo.queue_free()
		yu.remove_meta(META_GUI_HUO)
		return
	huo.global_position = huo.global_position.move_toward(mu.global_position, bu)


# ---- 星辰隐形（星落游魂·主动）----

static func _shi_fang_xing_chen(yu, neng: NengLi, dang: int) -> bool:
	# 4s 完全隐身：wudi + _ni_liu_sheng_yu 双重覆盖；感知倍率在 wen 里给 0
	var chi_xu := maxf(0.01, _zhi(neng, &"chi_xu", dang))
	yu.set_meta(META_YIN_SHEN, {"sheng_yu": chi_xu, "shou_ci": true})
	yu.jin_ru_wudi(chi_xu)
	yu._ni_liu_sheng_yu = maxf(yu._ni_liu_sheng_yu, chi_xu)
	_she_yin_shen_tou_ming(yu, true)
	return true


static func _geng_xing_chen(yu, _neng: NengLi, delta: float) -> void:
	# 到期结束：清 meta、恢复透明度；若装了星座余晖，给 1s 无敌（“隐身结束”触发）
	if not yu.has_meta(META_YIN_SHEN):
		return
	var zhuang = yu.get_meta(META_YIN_SHEN)
	if not (zhuang is Dictionary):
		return
	var sheng_yu := float(zhuang.get("sheng_yu", 0.0)) - maxf(0.0, delta)
	if sheng_yu > 0.0:
		zhuang["sheng_yu"] = sheng_yu
		yu.set_meta(META_YIN_SHEN, zhuang)
		yu._ni_liu_sheng_yu = maxf(yu._ni_liu_sheng_yu, sheng_yu)  # 连续覆盖
		_she_yin_shen_tou_ming(yu, true)
		return
	_jie_shu_yin_shen(yu)
	_gei_xing_zuo_yu_hui(yu)


static func _jie_shu_yin_shen(yu) -> void:
	# 结束/破隐的唯一收口：清状态 + 恢复半透明；不主动改 wudi/_ni_liu（让它们按自身计时走完）
	if yu == null or not is_instance_valid(yu):
		return
	if yu.has_meta(META_YIN_SHEN):
		yu.remove_meta(META_YIN_SHEN)
	_she_yin_shen_tou_ming(yu, false)


static func _she_yin_shen_tou_ming(yu, kai: bool) -> void:
	# 玩家本体半透明反馈；破隐恢复时若通用潜伏还在，就不抢它的 0.45
	if yu == null or not is_instance_valid(yu) or not yu.is_inside_tree():
		return
	var ben := yu.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if ben == null:
		return
	if kai:
		ben.modulate.a = 0.45
	elif not yu.yin_shen and float(yu._yin_shen_sheng_yu) <= 0.0:
		ben.modulate.a = 1.0


static func _yin_shen_zhong(yu) -> bool:
	return yu != null and is_instance_valid(yu) and yu.has_meta(META_YIN_SHEN)


static func _gei_xing_zuo_yu_hui(yu) -> void:
	# 星座余晖：只在装了被动时给，秒数从被动表读（默认 1.0）
	if yu == null or not is_instance_valid(yu):
		return
	if ZhangBen.dang_qian_bei_dong_ceng(&"xing_zuo_yu_hui") <= 0:
		return
	var bei := ZhangBen.zhao_bei_dong(&"xing_zuo_yu_hui")
	if bei == null:
		return
	var miao := maxf(0.0, bei.dang_zhi(&"shu_zhi", 1))
	if miao <= 0.0:
		return
	yu._ni_liu_sheng_yu = maxf(yu._ni_liu_sheng_yu, miao)
	if yu.get_parent() != null:
		TE_XIAO.bo(yu.get_parent(), DIAN_TE_XIAO, yu.global_position, 0.8)


static func _wen_xing_chen(yu, neng: NengLi, jian: StringName, shu_ju: Dictionary) -> float:
	if jian == &"gan_zhi_bei":
		# 完全隐身：NPC 看玩家的感知半径归零（不是 -25%，是彻底失去目标）
		return 0.0 if _yin_shen_zhong(yu) else 1.0
	if jian == &"yao_shang_bei":
		if not _yin_shen_zhong(yu):
			return 1.0
		var bu := StringName(str(shu_ju.get("bu", "")))
		if bu != &"zhi_ming":
			return 1.0  # 只对致命区；普通咬击不消耗首次加成
		var zhuang = yu.get_meta(META_YIN_SHEN, null)
		if zhuang == null or not (zhuang is Dictionary):
			return 1.0
		if not bool(zhuang.get("shou_ci", false)):
			return 1.0
		zhuang["shou_ci"] = false
		yu.set_meta(META_YIN_SHEN, zhuang)
		return maxf(0.0, _zhi(neng, &"shu_zhi", 1))
	return 1.0


static func _shi_jian_xing_chen(yu, _neng: NengLi, jian: StringName, _shu_ju: Dictionary) -> bool:
	# 攻击/受击破隐：只清 meta 与视觉；返回 false，不吞掉命中/伤害事件
	if jian != &"yao_zhong" and jian != &"bei_yao":
		return false
	if not _yin_shen_zhong(yu):
		return false
	_jie_shu_yin_shen(yu)
	_gei_xing_zuo_yu_hui(yu)
	return false


# ---- 星座余晖（星落游魂·被动）----

static func _shi_jian_xing_zuo(yu, neng: NengLi, jian: StringName, _shu_ju: Dictionary) -> bool:
	# 受击破隐的兜底：若主动钩子没先清（理论上同形态并存时会先清），这里也补 1s。
	# 返回 false——星座余晖只给无敌，不整口免伤。
	if jian != &"bei_yao":
		return false
	if not _yin_shen_zhong(yu):
		return false
	_jie_shu_yin_shen(yu)
	var miao := maxf(0.0, _zhi(neng, &"shu_zhi", 1))
	if miao > 0.0:
		yu._ni_liu_sheng_yu = maxf(yu._ni_liu_sheng_yu, miao)
	return false


# ---- 磷光爆闪（爆裂磷光兽·主动）----

static func _shi_fang_lin_guang(yu, _neng: NengLi, _dang: int) -> bool:
	# 只写前摇状态：玩家仍可移动/转向/咬击，不锁动作
	if yu == null or not is_instance_valid(yu):
		return false
	yu.set_meta(META_LIN_GUANG, {"qian_yao": QIAN_YAO_SHI_CHANG, "fan_zhi_mang": 0.0})
	return true


static func _geng_lin_guang(yu, neng: NengLi, delta: float) -> void:
	if not yu.has_meta(META_LIN_GUANG):
		return
	var zhuang = yu.get_meta(META_LIN_GUANG)
	if not (zhuang is Dictionary):
		return
	# 反致盲窗口：先倒数，归零清 meta
	var fan := float(zhuang.get("fan_zhi_mang", 0.0))
	if fan > 0.0:
		fan -= maxf(0.0, delta)
		if fan <= 0.0:
			yu.remove_meta(META_LIN_GUANG)
			return
		zhuang["fan_zhi_mang"] = fan
		yu.set_meta(META_LIN_GUANG, zhuang)
		return
	var qian := float(zhuang.get("qian_yao", 0.0)) - maxf(0.0, delta)
	if qian > 0.0:
		zhuang["qian_yao"] = qian
		yu.set_meta(META_LIN_GUANG, zhuang)
		return
	# 前摇结束：以玩家为圆心结算一次
	var ban_jing := maxf(0.0, _zhi(neng, &"ban_jing", 1))
	if neng.ban_jing_shen_wei:
		ban_jing *= yu._shen_wei()
	ban_jing = float(yu.fan_wei_xiu_zheng(ban_jing, 0.5))
	var chi_xu := maxf(0.0, _zhi(neng, &"chi_xu", 1))
	var dian_ma := maxf(0.0, _zhi(neng, &"shu_zhi", 1))
	var zhi_shang := maxf(0.0, _zhi(neng, &"fu_shu_zhi", 1))
	var yuan: Vector2 = yu.global_position
	for node in yu.get_tree().get_nodes_in_group(&"yu_npc"):
		var npc := node as YuNpc
		if npc == null or not is_instance_valid(npc) or npc.si_le:
			continue
		if yuan.distance_to(npc.global_position) > ban_jing:
			continue
		npc.jia_zhuang_tai(&"zhi_mang", chi_xu)
		npc.jia_dian_ma(dian_ma)
		# 无视防御直伤对首领减半（契约 §2 规则），普通鱼按能力表原值
		npc.shou_zhi_jie_shang(zhi_shang * (0.5 if npc.shi_boss else 1.0))
		if yu.get_parent() != null:
			TE_XIAO.bo(yu.get_parent(), DIAN_TE_XIAO, npc.global_position, 1.0)
	var fan_zhi := maxf(0.0, _zhi(neng, &"npc_shu_zhi", 1))
	if fan_zhi <= 0.0:
		yu.remove_meta(META_LIN_GUANG)
	else:
		zhuang["qian_yao"] = 0.0
		zhuang["fan_zhi_mang"] = fan_zhi
		yu.set_meta(META_LIN_GUANG, zhuang)
	if yu.get_parent() != null:
		TE_XIAO.bo(yu.get_parent(), DIAN_TE_XIAO, yuan, 1.5)


static func _wen_lin_guang(yu, _neng: NengLi, jian: StringName, _shu_ju: Dictionary) -> float:
	# 玩家侧没有状态层：反致盲用 meta 计时，期间咬伤 ×0.75（“看不见弱点”的等价取舍）
	if jian != &"yao_shang_bei" or not yu.has_meta(META_LIN_GUANG):
		return 1.0
	var zhuang = yu.get_meta(META_LIN_GUANG)
	if zhuang is Dictionary and float(zhuang.get("fan_zhi_mang", 0.0)) > 0.0:
		return FAN_ZHI_MANG_YAO_SHANG_BEI
	return 1.0


# ---- 幽冥体（幽冥引路灯·被动）----

static func _wen_you_ming(_yu, neng: NengLi, jian: StringName, _shu_ju: Dictionary) -> float:
	# 原案“暗区再 -15%”在当前工程没有暗区判定；这里只实装基础 -25%，报告写明取舍
	if jian == &"gan_zhi_bei":
		return maxf(0.0, _zhi(neng, &"shu_zhi", 1))
	return 1.0


# ---- 爆裂体质（爆裂磷光兽·被动）----

static func _shi_jian_bao_lie(yu, neng: NengLi, jian: StringName, shu_ju: Dictionary) -> bool:
	# 被咬：30% 概率反致盲 1s + 电麻 20；内部 CD 3s。返回 false——不整口免伤。
	if jian != &"bei_yao":
		return false
	if yu.nei_bu_leng_que_sheng(&"bao_lie_ti_zhi") > 0.0:
		return false
	var lai = shu_ju.get("lai_yuan", null)
	if lai == null or not is_instance_valid(lai) or not (lai is YuNpc):
		return false
	var npc := lai as YuNpc
	if npc.si_le:
		return false
	var gai := clampf(_zhi(neng, &"shu_zhi", 1), 0.0, 1.0)
	if randf() >= gai:
		return false
	var chi_xu := maxf(0.0, _zhi(neng, &"chi_xu", 1))
	var dian_ma := maxf(0.0, _zhi(neng, &"fu_shu_zhi", 1))
	npc.jia_zhuang_tai(&"zhi_mang", chi_xu)
	npc.jia_dian_ma(dian_ma)
	yu._dong_nei_bu_leng_que(&"bao_lie_ti_zhi", maxf(0.0, neng.nei_bu_leng_que))
	if yu.get_parent() != null:
		TE_XIAO.bo(yu.get_parent(), DIAN_TE_XIAO, npc.global_position, 0.8)
	return false
