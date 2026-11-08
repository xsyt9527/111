extends Node
# 局外存档：累计胜利次数 → 推导形态解锁；当前选择的形态；游玩设置（音量/摇杆侧边）
# 与 ZhangBen 分工：ZhangBen 管"这一局"，CunDang 管"跨局、跨启动"
# 存档用 JSON（损坏只回退默认，不向 Output 打 ERROR，不覆盖原文件）

const BAN_BEN := 1  # 存档格式版本；不兼容时整体回退默认
const JIE_JU_WEI_DING := 0  # 与 ZhangBen.JieJu.WEI_DING 对齐；--script 模式不加载 Autoload，不能直接写全局名
const JIE_JU_SHENG_LI := 1  # 与 ZhangBen.JieJu.SHENG_LI 对齐；--script 模式不加载 Autoload，不能直接写全局名
const MO_REN_LU_JING := "user://shenhaishiji_jin_du.json"
const ZHONG_TU_BAN_BEN := 1  # 中途存档格式版本；不兼容时整体作废（当没有存档处理）
const MO_REN_BIAN_HAO := &"ao_tu_wo_niu_yu"
const CHENG_JIU_MEI_CI := 10  # 每次通关（胜利）获得的成就值
const YONG_JIU_ZHU_DONG_DAI_JIA := 30  # 永久解锁一个主动技能的成就值价格
const YONG_JIU_BEI_DONG_DAI_JIA := 20  # 永久解锁一个被动技能的成就值价格
# 显式注册表：导出后 .tres 会变成 .remap/.res，运行时 DirAccess 列目录不可靠
# 试玩版全开：凹凸蜗牛鱼 + 10 种 NPC 鱼 + 鲸鲨首领（暗影剑鱼沿用剑鱼进化树）
# 旧的 deng_long_yu/dian_yao 两份形态文件保留作历史数据，不再进入注册表
const XING_TAI_ZU := [
	preload("res://data/xingtai/ao_tu_wo_niu_yu.tres"),
	preload("res://data/xingtai/lan_yu.tres"),
	preload("res://data/xingtai/hong_yu.tres"),
	preload("res://data/xingtai/cheng_yu.tres"),
	preload("res://data/xingtai/lv_yu.tres"),
	preload("res://data/xingtai/ju_kou_yu.tres"),
	preload("res://data/xingtai/zong_yu.tres"),
	preload("res://data/xingtai/qi_yu.tres"),
	preload("res://data/xingtai/jian_yu.tres"),
	preload("res://data/xingtai/ye_deng_long_yu.tres"),
	preload("res://data/xingtai/an_ying_jian_yu.tres"),
	preload("res://data/xingtai/fen_yu.tres"),
]

var lu_jing := MO_REN_LU_JING  # 测试可换临时路径；正式运行用默认路径
var zhong_tu_lu_jing := "user://shenhaishiji_zhongtu.json"  # 中途存档路径（测试可换临时路径）
var she_zhi_lu_jing := "user://shenhaishiji_shezhi.json"  # 游玩设置路径（测试可换临时路径）
var yin_xiao_yin_liang := 1.0  # 音效音量 0.0~1.0（线性）；主界面设置面板滑条直改
var bgm_yin_liang := 1.0       # BGM 音量 0.0~1.0（线性）
var yao_gan_ce := "zuo"        # 摇杆在屏幕哪一侧："zuo"=左下（默认）/ "you"=右下；技能按钮跟着换边
var hua_zhi_feng_ge := "xiang_su"  # 画风："xiang_su"=像素（默认）/ "jing_dian"=经典2D；主界面设置切换
var sheng_li_ci_shu := 0  # 累计胜利次数（解锁唯一依据）
var cheng_jiu_zhi := 0  # 成就值：通关后获得，花在永久开局技能上
var yong_jiu_neng_li: Array[StringName] = []  # 已永久解锁的开局技能 id
var yi_dian_liang_jin_hua: Array[StringName] = []  # 图鉴已永久点亮的进化形态 id（策划案 v0.18 8.6）
var dang_qian_bian_hao: StringName = MO_REN_BIAN_HAO  # 已选择的形态 id
var shang_ci_xin_jie_suo: Array[XingTai] = []  # 本次胜利新解锁的形态（瞬时，不存档）

var _xing_tai_zu: Array[XingTai] = []  # 按解锁阈值升序排好的形态表


func _init() -> void:
	# 裸实例（--script 测试）不经过 _ready，也要能先用形态表
	jia_zai_xing_tai()


func _ready() -> void:
	zai_ru()
	zai_ru_she_zhi()
	var zhang_ben := get_node_or_null("/root/ZhangBen")
	if zhang_ben != null and not zhang_ben.ju_jie_shu.is_connected(_on_ju_jie_shu):
		zhang_ben.ju_jie_shu.connect(_on_ju_jie_shu)
	# 进化完成 → 图鉴永久点亮：局内只生效一次，但图鉴记录跨局、跨启动
	if zhang_ben != null and not zhang_ben.jin_hua_wan_cheng.is_connected(_on_jin_hua_wan_cheng):
		zhang_ben.jin_hua_wan_cheng.connect(_on_jin_hua_wan_cheng)


func jia_zai_xing_tai() -> void:
	# 装载显式注册表；先按 pai_xu（玩家 0、NPC 按生态层级、首领最后），
	# 同序号再按解锁阈值与 id（选择页/解锁顺序稳定）
	_xing_tai_zu.assign(XING_TAI_ZU)
	_xing_tai_zu.sort_custom(func(a: XingTai, b: XingTai) -> bool:
		if a.pai_xu != b.pai_xu:
			return a.pai_xu < b.pai_xu
		if a.jie_suo_sheng_li_ci_shu != b.jie_suo_sheng_li_ci_shu:
			return a.jie_suo_sheng_li_ci_shu < b.jie_suo_sheng_li_ci_shu
		return String(a.bian_hao) < String(b.bian_hao)
	)


func zai_ru() -> void:
	# 读档：任何失败都只回退默认值，绝不写文件（避免把玩家存档改坏）
	sheng_li_ci_shu = 0
	cheng_jiu_zhi = 0
	yong_jiu_neng_li.clear()
	dang_qian_bian_hao = MO_REN_BIAN_HAO
	shang_ci_xin_jie_suo.clear()
	yi_dian_liang_jin_hua.clear()
	if not FileAccess.file_exists(lu_jing):
		return
	var wen_jian := FileAccess.open(lu_jing, FileAccess.READ)
	if wen_jian == null:
		return
	var wen := wen_jian.get_as_text()
	wen_jian.close()
	# 用 JSON 实例的 parse：JSON.parse_string 解析失败会向 Output 打 ERROR，
	# 而门禁对 ERROR 零容忍；parse 只返回错误码，可静默回退
	var json := JSON.new()
	if json.parse(wen) != OK:
		return
	var shu_ju = json.data
	if not (shu_ju is Dictionary):
		return
	var ban_ben = shu_ju.get("ban_ben")
	if not _shi_shu_zi(ban_ben) or int(ban_ben) != BAN_BEN:
		return
	var ci_shu = shu_ju.get("sheng_li_ci_shu", 0)
	if _shi_shu_zi(ci_shu):
		sheng_li_ci_shu = maxi(0, int(ci_shu))
	# 成就字段缺省视为 0/空：旧存档原样可读，不因版本升级被作废
	var cheng_jiu = shu_ju.get("cheng_jiu_zhi", 0)
	if _shi_shu_zi(cheng_jiu):
		cheng_jiu_zhi = maxi(0, int(cheng_jiu))
	var yong_jiu = shu_ju.get("yong_jiu_neng_li", [])
	if yong_jiu is Array:
		for id_wen in yong_jiu:
			if not (id_wen is String):
				continue
			var id := StringName(id_wen)
			var yj_neng := NengLiKu.zhao(id)
			# 进化专属技不进成就账本：旧档里即使有，也按“未解锁”丢弃（v0.21 独占规则）
			if yj_neng != null and not yj_neng.shi_zhuan_shu() and not yong_jiu_neng_li.has(id):
				yong_jiu_neng_li.append(id)
	# 进化图鉴点亮：放在“当前形态校验”之前读——后面未知 id 会提前 return，别把点亮一起丢掉
	# 旧档没有这个键 = 一个都没点亮；只认注册表里真实存在的 id（手改坏档不污染图鉴）
	var dian_liang = shu_ju.get("yi_dian_liang_jin_hua", [])
	if dian_liang is Array:
		for id_wen in dian_liang:
			if not (id_wen is String):
				continue
			var jh_id := StringName(id_wen)
			if JinHuaKu.zhao(jh_id) != null and not yi_dian_liang_jin_hua.has(jh_id):
				yi_dian_liang_jin_hua.append(jh_id)
	var bian_hao = shu_ju.get("dang_qian_xing_tai", "")
	if not (bian_hao is String):
		return
	var xt := _zhao_xing_tai(StringName(bian_hao))
	if xt == null:
		return  # 未知 id：保留胜场，当前形态回默认
	if sheng_li_ci_shu < xt.jie_suo_sheng_li_ci_shu:
		return  # 已选形态尚未解锁：保留胜场，当前形态回默认
	dang_qian_bian_hao = xt.bian_hao


func bao_cun() -> bool:
	# 写档：失败只警告不抛错（不能因为存档目录异常卡住开局）
	var wen_jian := FileAccess.open(lu_jing, FileAccess.WRITE)
	if wen_jian == null:
		push_warning("CunDang 无法写入存档: " + lu_jing)
		return false
	var yong_jiu_wen := []
	for id in yong_jiu_neng_li:
		yong_jiu_wen.append(String(id))
	var jin_hua_wen := []
	for id in yi_dian_liang_jin_hua:
		jin_hua_wen.append(String(id))
	wen_jian.store_string(JSON.stringify({
		"ban_ben": BAN_BEN,
		"sheng_li_ci_shu": sheng_li_ci_shu,
		"cheng_jiu_zhi": cheng_jiu_zhi,
		"yong_jiu_neng_li": yong_jiu_wen,
		"yi_dian_liang_jin_hua": jin_hua_wen,
		"dang_qian_xing_tai": String(dang_qian_bian_hao),
	}))
	wen_jian.close()
	return true


func you_zhong_tu() -> bool:
	# 是否存在中途存档：主界面"继续游戏"按钮的显隐唯一依据（生命周期规则④）
	return FileAccess.file_exists(zhong_tu_lu_jing)


func qing_chu_zhong_tu() -> void:
	# 清除中途存档：开始新局（规则②）/ 一局打完胜胜负负（规则①）时调用
	# 文件不存在就安静返回：清档是幂等操作，调用方不用先问有没有
	if FileAccess.file_exists(zhong_tu_lu_jing):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(zhong_tu_lu_jing))


func xie_zhong_tu(zhang_ben: Node = null) -> bool:
	# 中途存档写入（规则③"返回主界面并保存"）：从账本采集可序列化状态写 JSON
	# 只存可序列化字段（形态/等级/经验/主动档位/被动层数/饥饿/局内时间/食谱）；
	# 鱼位置、NPC 状态不存——继续游戏后场景重新生成，属原型级行为
	# 参数默认 null：正式运行运行时查 /root/ZhangBen（--script 测试传独立实例注入）
	var zb: Node = zhang_ben
	if zb == null:
		zb = get_node_or_null("/root/ZhangBen")
	if zb == null:
		return false
	# 只在"活着且未结算"的局面可存：结局已定的中途档毫无意义（回来直接进结算）
	if int(zb.get("jie_ju")) != JIE_JU_WEI_DING or not bool(zb.get("sheng_cun_zhong")):
		return false
	var xing_tai: XingTai = zb.get("dang_qian_xing_tai")
	if xing_tai == null:
		return false  # 没装配形态的局面不可存：继续游戏无法重建外观与数值
	var zhu_dong_id: Array = []
	for neng in zb.get("zhu_dong_zu"):
		zhu_dong_id.append(String(neng.bian_hao))
	var yi_xuan_id: Array = []
	for neng in zb.get("yi_xuan_neng_li"):
		yi_xuan_id.append(String(neng.bian_hao))
	var dang_biao: Dictionary = zb.get("zhu_dong_dang")
	var dang_cun := {}
	for jian in dang_biao:
		dang_cun[String(jian)] = int(dang_biao[jian])
	var ceng_biao: Dictionary = zb.get("bei_dong_ceng")
	var ceng_cun := {}
	for jian in ceng_biao:
		ceng_cun[String(jian)] = int(ceng_biao[jian])
	var shi_pu: Dictionary = zb.get("chi_yu_ji_lu")
	var shi_pu_cun := {}
	for jian in shi_pu:
		shi_pu_cun[String(jian)] = int(shi_pu[jian])
	var wen_jian := FileAccess.open(zhong_tu_lu_jing, FileAccess.WRITE)
	if wen_jian == null:
		push_warning("CunDang 无法写入中途存档: " + zhong_tu_lu_jing)
		return false
	wen_jian.store_string(JSON.stringify({
		"ban_ben": ZHONG_TU_BAN_BEN,
		"xing_tai": String(xing_tai.bian_hao),
		"deng_ji": int(zb.get("deng_ji")),
		"jing_yan": int(zb.get("jing_yan")),
		"dang_qian_ti_xing": float(zb.get("dang_qian_ti_xing")),
		"ji_e": float(zb.get("ji_e")),
		"ju_nei_shi_jian": float(zb.get("ju_nei_shi_jian")),
		# 进化形态：没进化存空串；旧档没有这个键时按未进化读（zai_ru_zhong_tu 静默跳过）
		"jin_hua": String(zb.get("dang_qian_jin_hua").bian_hao) if zb.get("dang_qian_jin_hua") != null else "",
		"zhu_dong": zhu_dong_id,
		"zhu_dong_dang": dang_cun,
		"bei_dong_ceng": ceng_cun,
		"yi_xuan": yi_xuan_id,
		"chi_yu_ji_lu": shi_pu_cun,
	}))
	wen_jian.close()
	return true


func du_zhong_tu() -> Dictionary:
	# 读中途存档：任何失败都返回空字典（调用方据此当"没有存档"处理）
	# JSON 实例的 parse 静默回退：JSON.parse_string 失败会向 Output 打 ERROR，门禁零容忍
	if not FileAccess.file_exists(zhong_tu_lu_jing):
		return {}
	var wen_jian := FileAccess.open(zhong_tu_lu_jing, FileAccess.READ)
	if wen_jian == null:
		return {}
	var wen := wen_jian.get_as_text()
	wen_jian.close()
	var json := JSON.new()
	if json.parse(wen) != OK:
		return {}
	var shu_ju = json.data
	if not (shu_ju is Dictionary):
		return {}
	if int(shu_ju.get("ban_ben", -1)) != ZHONG_TU_BAN_BEN:
		return {}
	if not (shu_ju.get("xing_tai") is String) or String(shu_ju.get("xing_tai")) == "":
		return {}
	return shu_ju


# —— 游玩设置（音量 / 摇杆侧边）：独立文件，与局内存档互不干扰，清档不影响设置 ——

const SHE_ZHI_BAN_BEN := 1  # 设置格式版本；不兼容时整体回退默认


func zai_ru_she_zhi() -> void:
	# 读设置：任何失败都保持默认值，绝不写文件（与 zai_ru 同一套静默回退）
	yin_xiao_yin_liang = 1.0
	bgm_yin_liang = 1.0
	yao_gan_ce = "zuo"
	hua_zhi_feng_ge = "xiang_su"
	if not FileAccess.file_exists(she_zhi_lu_jing):
		return
	var wen_jian := FileAccess.open(she_zhi_lu_jing, FileAccess.READ)
	if wen_jian == null:
		return
	var wen := wen_jian.get_as_text()
	wen_jian.close()
	var json := JSON.new()
	if json.parse(wen) != OK:
		return
	var shu_ju = json.data
	if not (shu_ju is Dictionary):
		return
	if int(shu_ju.get("ban_ben", -1)) != SHE_ZHI_BAN_BEN:
		return
	var yin_xiao = shu_ju.get("yin_xiao", 1.0)
	if _shi_shu_zi(yin_xiao):
		yin_xiao_yin_liang = clampf(float(yin_xiao), 0.0, 1.0)
	var bgm = shu_ju.get("bgm", 1.0)
	if _shi_shu_zi(bgm):
		bgm_yin_liang = clampf(float(bgm), 0.0, 1.0)
	if String(shu_ju.get("yao_gan_ce", "zuo")) == "you":
		yao_gan_ce = "you"
	if String(shu_ju.get("hua_zhi", "xiang_su")) == "jing_dian":
		hua_zhi_feng_ge = "jing_dian"


func xie_she_zhi() -> bool:
	# 写设置：失败只警告（音量存不下来不致命，不该卡住任何流程）
	var wen_jian := FileAccess.open(she_zhi_lu_jing, FileAccess.WRITE)
	if wen_jian == null:
		push_warning("CunDang 无法写入设置: " + she_zhi_lu_jing)
		return false
	wen_jian.store_string(JSON.stringify({
		"ban_ben": SHE_ZHI_BAN_BEN,
		"yin_xiao": yin_xiao_yin_liang,
		"bgm": bgm_yin_liang,
		"yao_gan_ce": yao_gan_ce,
		"hua_zhi": hua_zhi_feng_ge,
	}))
	wen_jian.close()
	return true


func an_bian_hao_zhao_xing_tai(bian_hao: StringName) -> XingTai:
	# 按 id 查形态资源：主界面"继续游戏"重建账本形态引用用（查不到返回 null，由调用方回退）
	return _zhao_xing_tai(bian_hao)


func ji_lu_sheng_li() -> Array[XingTai]:
	# 胜利瞬间调用：胜场 +1、成就值入账，返回跨过阈值的新解锁形态，并立即写档
	var jiu_ci_shu := sheng_li_ci_shu
	sheng_li_ci_shu += 1
	cheng_jiu_zhi += CHENG_JIU_MEI_CI
	var xin_jie_suo: Array[XingTai] = []
	for xt in _xing_tai_zu:
		if xt.jie_suo_sheng_li_ci_shu > jiu_ci_shu and xt.jie_suo_sheng_li_ci_shu <= sheng_li_ci_shu:
			xin_jie_suo.append(xt)
	shang_ci_xin_jie_suo.assign(xin_jie_suo)
	bao_cun()
	return xin_jie_suo


func qu_xin_jie_suo() -> Array[XingTai]:
	# 结算页消费一次解锁提示；消费后清空，死亡/失败不会显示上一局残留
	var jie_guo: Array[XingTai] = []
	jie_guo.assign(shang_ci_xin_jie_suo)
	shang_ci_xin_jie_suo.clear()
	return jie_guo


func shi_fou_jie_suo(bian_hao: StringName) -> bool:
	var xt := _zhao_xing_tai(bian_hao)
	if xt == null:
		return false
	return sheng_li_ci_shu >= xt.jie_suo_sheng_li_ci_shu


func ke_xuan_xing_tai() -> Array[XingTai]:
	var jie_guo: Array[XingTai] = []
	for xt in _xing_tai_zu:
		if sheng_li_ci_shu >= xt.jie_suo_sheng_li_ci_shu:
			jie_guo.append(xt)
	return jie_guo


func suo_you_xing_tai() -> Array[XingTai]:
	var jie_guo: Array[XingTai] = []
	jie_guo.assign(_xing_tai_zu)
	return jie_guo


func dang_qian_xing_tai() -> XingTai:
	var xt := _zhao_xing_tai(dang_qian_bian_hao)
	if xt == null or sheng_li_ci_shu < xt.jie_suo_sheng_li_ci_shu:
		return _zhao_xing_tai(MO_REN_BIAN_HAO)
	return xt


func xuan_ze(bian_hao: StringName) -> bool:
	# 选择形态：未知或未解锁一律拒绝；成功才写档
	if not shi_fou_jie_suo(bian_hao):
		return false
	dang_qian_bian_hao = bian_hao
	bao_cun()
	return true


func tiao_shi_jie_suo_quan_bu() -> void:
	# 仅编辑器调试按钮：胜场拉到最高阈值，解锁全部形态
	# 唯一形态的解锁阈值是 0：用 maxi 保留玩家已有胜场，别让“解锁全部”反而把进度清零
	var zui_gao := 0
	for xt in _xing_tai_zu:
		zui_gao = maxi(zui_gao, xt.jie_suo_sheng_li_ci_shu)
	sheng_li_ci_shu = maxi(sheng_li_ci_shu, zui_gao)
	bao_cun()


func tiao_shi_qing_chu_jin_du() -> void:
	# 仅编辑器调试按钮：进度归零、当前形态回默认、成就一并清空（调试口径一致）
	sheng_li_ci_shu = 0
	cheng_jiu_zhi = 0
	yong_jiu_neng_li.clear()
	dang_qian_bian_hao = MO_REN_BIAN_HAO
	shang_ci_xin_jie_suo.clear()
	yi_dian_liang_jin_hua.clear()  # 图鉴点亮也算进度：清进度一并清掉
	bao_cun()


# —— 成就：通关得成就值，花成就值永久解锁开局技能 ——

func cheng_jiu_dai_jia(neng: NengLi) -> int:
	# 价格只分主动/被动两档：主动贵在立刻改变开局手感，被动便宜在只加一层
	if neng == null:
		return 0
	return YONG_JIU_ZHU_DONG_DAI_JIA if neng.shi_zhu_dong() else YONG_JIU_BEI_DONG_DAI_JIA


func you_yong_jiu(bian_hao: StringName) -> bool:
	return yong_jiu_neng_li.has(bian_hao)


func ke_yong_jiu_dui_huan(neng: NengLi) -> bool:
	# 成就页可兑换判据（策划案 v0.21）：专属技只随进化形态装配，永不进成就商店
	return neng != null and not neng.shi_zhuan_shu()


func jie_suo_yong_jiu(bian_hao: StringName) -> bool:
	# 永久解锁唯一入口：校验 id/归属/重复/余额后扣分写档；失败不改任何状态
	var neng := NengLiKu.zhao(bian_hao)
	if not ke_yong_jiu_dui_huan(neng) or you_yong_jiu(bian_hao):
		return false
	var dai_jia := cheng_jiu_dai_jia(neng)
	if cheng_jiu_zhi < dai_jia:
		return false
	cheng_jiu_zhi -= dai_jia
	yong_jiu_neng_li.append(bian_hao)
	bao_cun()
	return true


func ying_yong_yong_jiu(zhang_ben: Node) -> void:
	# 开局装配：形态自带的能力不重复加（主动不叠档、被动不加层），其余各装一次
	if zhang_ben == null:
		return
	for id in yong_jiu_neng_li:
		var neng := NengLiKu.zhao(id)
		if not ke_yong_jiu_dui_huan(neng):
			continue
		if neng.shi_zhu_dong():
			if bool(zhang_ben.call("zhuang_lei", id)):
				continue
		elif int(zhang_ben.call("dang_qian_bei_dong_ceng", id)) > 0:
			continue
		zhang_ben.call("xuan_neng_li", neng)


func tiao_shi_jia_cheng_jiu(shu_liang: int) -> void:
	# 仅编辑器调试按钮：给成就值试玩成就页（导出包不出现）
	cheng_jiu_zhi = maxi(0, cheng_jiu_zhi + shu_liang)
	bao_cun()


func chong_zhi_cheng_jiu() -> void:
	# 成就页「重置成就」：清空已兑换技能，并把花掉的成就值按原价退回。
	# 结算口径 = 已用掉的 + 还没用的：重置只清技能，不动玩家的成就值总额。
	# 先遍历技能算返还、再清列表——顺序反了就只能退回 0。
	# 胜场、当前形态、图鉴点亮、中途存档都不动——那些属于“进度/选角”，不是成就账本。
	var tui_hui := 0
	for id in yong_jiu_neng_li:
		var neng := NengLiKu.zhao(id)
		if neng != null:
			tui_hui += cheng_jiu_dai_jia(neng)
	cheng_jiu_zhi += tui_hui
	yong_jiu_neng_li.clear()
	bao_cun()


func _on_jin_hua_wan_cheng(jin_hua: JinHua) -> void:
	# 局内进化完成：图鉴永久点亮并立刻写档（玩家直接关游戏也不丢记录）
	if jin_hua != null:
		dian_liang_jin_hua(jin_hua.bian_hao)


# —— 图鉴点亮：进化过一次即永久解锁图鉴卡（局内仍是每局一次） ——

func dian_liang_jin_hua(bian_hao: StringName) -> bool:
	# 点亮唯一入口：未知 id 拒绝、重复调用幂等（返回 false = 本来就没亮/不是合法形态）
	if JinHuaKu.zhao(bian_hao) == null or yi_dian_liang_jin_hua.has(bian_hao):
		return false
	yi_dian_liang_jin_hua.append(bian_hao)
	bao_cun()
	return true


func shi_fou_dian_liang(bian_hao: StringName) -> bool:
	return yi_dian_liang_jin_hua.has(bian_hao)


func yi_dian_liang_ming_dan() -> Array[StringName]:
	# 只读副本：图鉴按它决定灰显，外部别直接改内部数组
	var jie_guo: Array[StringName] = []
	jie_guo.assign(yi_dian_liang_jin_hua)
	return jie_guo


func _on_ju_jie_shu(jie_guo: int) -> void:
	# 胜利立刻记档（玩家直接关游戏也不丢解锁）；失败/死亡清掉瞬时提示
	# 一局打完（胜/负/死）中途存档即作废：这一局已经走到了终点，没得"继续"了（生命周期规则①）
	qing_chu_zhong_tu()
	if jie_guo == JIE_JU_SHENG_LI:
		ji_lu_sheng_li()
	else:
		shang_ci_xin_jie_suo.clear()


func _zhao_xing_tai(bian_hao: StringName) -> XingTai:
	for xt in _xing_tai_zu:
		if xt.bian_hao == bian_hao:
			return xt
	return null


func _shi_shu_zi(zhi) -> bool:
	# JSON 的数字统一是 float，不能只认 TYPE_INT
	var lei_xing := typeof(zhi)
	return lei_xing == TYPE_INT or lei_xing == TYPE_FLOAT
