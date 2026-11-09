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
var sheng_li_ci_shu := 0  # 累计胜利次数（通关次数；D 通关解锁用）
var cheng_jiu_zhi := 0  # 成就值余额（可花在永久开局技能上）
var lei_ji_cheng_jiu_zhi := 0  # B1/D：历史累计获得的成就值（只增不减；成就解锁只看它）
var yong_jiu_neng_li: Array[StringName] = []  # 已永久解锁的开局技能 id
var yi_dian_liang_jin_hua: Array[StringName] = []  # 图鉴已永久点亮的进化形态 id（策划案 v0.18 8.6）
var yi_chi_yu_zhong: Array[StringName] = []  # B1：跨局已吞噬过的鱼种 id（首次吞噬多给 5 成就值）
var yi_kan_guang_gao: Array[StringName] = []  # D：已看广告解锁的广告位形态 id（SDK 未接入时不会写入）
var dang_qian_bian_hao: StringName = MO_REN_BIAN_HAO  # 已选择的形态 id
var shang_ci_xin_jie_suo: Array[XingTai] = []  # 本次结算新解锁的形态（瞬时，不存档）
var shang_ci_jie_suan: Dictionary = {}  # B2：本局结算明细（瞬时，结算页消费；不存档）
var ya_li_xiu_zheng := 0  # E2：隐藏压力修正 -2~+2（跨局持久；负=对玩家更宽松）
var you_dai_zhu_dong_bao_di := false  # E2：下局首次三选一必含 1 个进攻主动（结算时写，消耗后清）
var shou_ju_jiao_ben_yi_zhi_xing := false  # C：首局 10 分钟节奏脚本只跑一次（存档持久）

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
	lei_ji_cheng_jiu_zhi = 0
	ya_li_xiu_zheng = 0
	you_dai_zhu_dong_bao_di = false
	shou_ju_jiao_ben_yi_zhi_xing = false
	yong_jiu_neng_li.clear()
	dang_qian_bian_hao = MO_REN_BIAN_HAO
	shang_ci_xin_jie_suo.clear()
	shang_ci_jie_suan.clear()
	yi_dian_liang_jin_hua.clear()
	yi_chi_yu_zhong.clear()
	yi_kan_guang_gao.clear()
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
	# B1/D/E 新字段：缺省时按旧档迁移（累计成就 = 当前余额 + 已花掉的技能原价）
	var lei_ji = shu_ju.get("lei_ji_cheng_jiu_zhi", null)
	if _shi_shu_zi(lei_ji):
		lei_ji_cheng_jiu_zhi = maxi(0, int(lei_ji))
	else:
		var hua_fei := 0
		for id in yong_jiu_neng_li:
			var yj := NengLiKu.zhao(id)
			if yj != null:
				hua_fei += cheng_jiu_dai_jia(yj)
		lei_ji_cheng_jiu_zhi = cheng_jiu_zhi + hua_fei
	var xiu_zheng = shu_ju.get("ya_li_xiu_zheng", 0)
	if _shi_shu_zi(xiu_zheng):
		ya_li_xiu_zheng = clampi(int(xiu_zheng), -2, 2)
	you_dai_zhu_dong_bao_di = bool(shu_ju.get("you_dai_zhu_dong_bao_di", false))
	shou_ju_jiao_ben_yi_zhi_xing = bool(shu_ju.get("shou_ju_jiao_ben_yi_zhi_xing", false))
	var chi_guo = shu_ju.get("yi_chi_yu_zhong", [])
	if chi_guo is Array:
		for id_wen in chi_guo:
			if id_wen is String:
				var yz_id := StringName(id_wen)
				if not yi_chi_yu_zhong.has(yz_id):
					yi_chi_yu_zhong.append(yz_id)
	var kan_guo = shu_ju.get("yi_kan_guang_gao", [])
	if kan_guo is Array:
		for id_wen in kan_guo:
			if id_wen is String:
				var gg_id := StringName(id_wen)
				if _zhao_xing_tai(gg_id) != null and not yi_kan_guang_gao.has(gg_id):
					yi_kan_guang_gao.append(gg_id)
	var bian_hao = shu_ju.get("dang_qian_xing_tai", "")
	if not (bian_hao is String):
		return
	var xt := _zhao_xing_tai(StringName(bian_hao))
	if xt == null:
		return  # 未知 id：保留胜场，当前形态回默认
	if not _pan_duan_jie_suo(xt, sheng_li_ci_shu, lei_ji_cheng_jiu_zhi):
		return  # 已选形态尚未解锁（广告/成就/通关任一来源）：保留胜场，当前形态回默认
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
	var chi_yu_wen := []
	for id in yi_chi_yu_zhong:
		chi_yu_wen.append(String(id))
	var guang_gao_wen := []
	for id in yi_kan_guang_gao:
		guang_gao_wen.append(String(id))
	wen_jian.store_string(JSON.stringify({
		"ban_ben": BAN_BEN,
		"sheng_li_ci_shu": sheng_li_ci_shu,
		"cheng_jiu_zhi": cheng_jiu_zhi,
		"lei_ji_cheng_jiu_zhi": lei_ji_cheng_jiu_zhi,
		"ya_li_xiu_zheng": ya_li_xiu_zheng,
		"you_dai_zhu_dong_bao_di": you_dai_zhu_dong_bao_di,
		"shou_ju_jiao_ben_yi_zhi_xing": shou_ju_jiao_ben_yi_zhi_xing,
		"yong_jiu_neng_li": yong_jiu_wen,
		"yi_dian_liang_jin_hua": jin_hua_wen,
		"yi_chi_yu_zhong": chi_yu_wen,
		"yi_kan_guang_gao": guang_gao_wen,
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


func _id_shu_zu(shu_zu) -> Array:
	# StringName 数组 → JSON 可存的 String 数组（中途存档共用）
	var jie_guo: Array = []
	if shu_zu is Array:
		for id in shu_zu:
			jie_guo.append(String(id))
	return jie_guo


func _ming_shu_zu(shu_zu) -> Array:
	# 显示名数组 → JSON 可存数组（保持与 id 数组一一对应）
	var jie_guo: Array = []
	if shu_zu is Array:
		for ming in shu_zu:
			jie_guo.append(String(ming))
	return jie_guo


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
		# B1 局内战绩：继续游戏后结算公式仍按本局真实数据算（旧档缺这些键时按 0 读）
		"ben_ju_tun_chi_shu": int(zb.get("ben_ju_tun_chi_shu")),
		"ben_ju_ji_sha_shu": int(zb.get("ben_ju_ji_sha_shu")),
		"ben_ju_diao_rou_liang": float(zb.get("ben_ju_diao_rou_liang")),
		"ben_ju_tun_chi_yu_zhong": _id_shu_zu(zb.get("ben_ju_tun_chi_yu_zhong")),
		"ben_ju_tun_chi_yu_zhong_ming": _ming_shu_zu(zb.get("ben_ju_tun_chi_yu_zhong_ming")),
		"ben_ju_sha_shou_ming": String(zb.get("ben_ju_sha_shou_ming")),
		"ben_ju_sha_shou_ti_xing": float(zb.get("ben_ju_sha_shou_ti_xing")),
		"ben_ju_sha_shou_chu_shi": float(zb.get("ben_ju_sha_shou_chu_shi")),
		"ben_ju_fan_sha_kou": int(zb.get("ben_ju_fan_sha_kou")),
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


func shi_fou_shou_ju() -> bool:
	# C：只在「0 胜 + 首局脚本没跑过」时启动教学时间轴；通关后不再触发
	return sheng_li_ci_shu == 0 and not shou_ju_jiao_ben_yi_zhi_xing


func biao_ji_shou_ju_jiao_ben() -> void:
	# C：首局脚本跑过就打标记写档；重复调用幂等
	if shou_ju_jiao_ben_yi_zhi_xing:
		return
	shou_ju_jiao_ben_yi_zhi_xing = true
	bao_cun()


func qu_zhu_dong_bao_di() -> bool:
	# E2：消费「下局首次三选一必含进攻主动」欠账；消费后立刻写档，跨启动也只生效一次
	var you := you_dai_zhu_dong_bao_di
	if you:
		you_dai_zhu_dong_bao_di = false
		bao_cun()
	return you


func jie_suan_ben_ju(jie_guo: int, zhang_ben = null) -> Dictionary:
	# B1/B2/B3：每局结束都入账——死亡/失败也拿保底（不再只有胜利才有成就值）
	# zhang_ben 可传账本节点或字典（--script 测试用字典喂数据）；默认查 /root/ZhangBen
	var zb = zhang_ben
	if zb == null:
		zb = get_node_or_null("/root/ZhangBen")
	if zb == null:
		return {}
	var dang_ji := int(_qu(zb, "deng_ji", 0))
	var ji_sha := int(_qu(zb, "ben_ju_ji_sha_shu", 0))
	var tun_chi := int(_qu(zb, "ben_ju_tun_chi_shu", 0))
	var diao_rou := float(_qu(zb, "ben_ju_diao_rou_liang", 0.0))
	var miao := maxf(0.0, float(_qu(zb, "ju_nei_shi_jian", 0.0)))
	var fen := int(floor(miao / 60.0))
	var tong_guan := 50 if jie_guo == JIE_JU_SHENG_LI else 0
	var qiang_du := _ji_suan_qiang_du(zb)
	# 首次吞噬新鱼种：跨局集合求差，每局限计 5 个（之后仍记入图鉴/持久集合，只是不再计费）
	var xin_id: Array[StringName] = []
	var xin_ming: Array[String] = []
	var tun_ids = _qu(zb, "ben_ju_tun_chi_yu_zhong", [])
	var tun_ming = _qu(zb, "ben_ju_tun_chi_yu_zhong_ming", [])
	if tun_ids is Array:
		for i in tun_ids.size():
			var yz_id := StringName(str(tun_ids[i]))
			if yz_id == &"" or yi_chi_yu_zhong.has(yz_id):
				continue
			xin_id.append(yz_id)
			var ming := String(yz_id)
			if tun_ming is Array and i < tun_ming.size():
				ming = str(tun_ming[i])
			xin_ming.append(ming)
	var ji_fei := mini(xin_id.size(), 5)
	var cheng_jiu := 10 + dang_ji * 2 + ji_sha + fen * 2 + tong_guan + ji_fei * 5
	# 明细（结算页 B2③ 逐条展示）
	var ming_xi: Array[String] = []
	ming_xi.append("参战保底 +10")
	ming_xi.append("体型 Lv.%d +%d" % [dang_ji, dang_ji * 2])
	ming_xi.append("击杀 %d +%d" % [ji_sha, ji_sha])
	ming_xi.append("存活 %d 分钟 +%d" % [fen, fen * 2])
	if tong_guan > 0:
		ming_xi.append("击沉机器船 +50")
	if ji_fei > 0:
		ming_xi.append("首次吞噬新鱼种 %d ×5 +%d" % [ji_fei, ji_fei * 5])
	# 入账：余额与累计同时加；持久集合记录本局所有新鱼种（计费只取前 5）
	cheng_jiu_zhi += cheng_jiu
	lei_ji_cheng_jiu_zhi += cheng_jiu
	for yz_id in xin_id:
		if not yi_chi_yu_zhong.has(yz_id):
			yi_chi_yu_zhong.append(yz_id)
	var jiu_sheng := sheng_li_ci_shu
	var jiu_lei := lei_ji_cheng_jiu_zhi - cheng_jiu
	var jie_suo_qian := {}
	for xt in _xing_tai_zu:
		jie_suo_qian[xt.bian_hao] = _pan_duan_jie_suo(xt, jiu_sheng, jiu_lei)
	if jie_guo == JIE_JU_SHENG_LI:
		sheng_li_ci_shu += 1
		ya_li_xiu_zheng = mini(2, ya_li_xiu_zheng + 1)  # E2：通关者下局压力 +
	elif qiang_du >= 10:
		ya_li_xiu_zheng = maxi(-2, ya_li_xiu_zheng - 1)  # E2：构筑成形仍死亡 → 下局宽松
	else:
		you_dai_zhu_dong_bao_di = true  # E2：构筑没成形 → 下局首次三选一保底进攻主动
	# D：扫一遍新跨过门槛的形态（成就/通关两种来源；广告位只认已看广告集合）
	var xin_jie_suo: Array[XingTai] = []
	for xt in _xing_tai_zu:
		if not bool(jie_suo_qian.get(xt.bian_hao, false)) and shi_fou_jie_suo(xt.bian_hao):
			xin_jie_suo.append(xt)
	shang_ci_xin_jie_suo.assign(xin_jie_suo)
	# B2③：最近未购能力差额（余额+本局之后看）
	var dui_huan := _zui_jin_dui_huan()
	var jie_suan := {
		"jie_guo": jie_guo,
		"deng_ji": dang_ji,
		"ji_sha": ji_sha,
		"tun_chi": tun_chi,
		"diao_rou": diao_rou,
		"sheng_cun": miao,
		"sheng_cun_min": fen,
		"qiang_du": qiang_du,
		"cheng_jiu": cheng_jiu,
		"ming_xi": ming_xi,
		"lei_ji": lei_ji_cheng_jiu_zhi,
		"yu_e": cheng_jiu_zhi,
		"xin_yu_zhong": xin_ming,
		"xin_jie_suo": xin_jie_suo,
		"sha_shou_ming": str(_qu(zb, "ben_ju_sha_shou_ming", "")),
		"sha_shou_sheng_yu": int(round(float(_qu(zb, "ben_ju_sha_shou_chu_shi", 0.0)) / maxf(float(_qu(zb, "ben_ju_sha_shou_ti_xing", 0.0)), 0.001) * 100.0)) if float(_qu(zb, "ben_ju_sha_shou_chu_shi", 0.0)) > 0.0 else 0,
		"fan_sha_kou": int(_qu(zb, "ben_ju_fan_sha_kou", 0)),
		"dui_huan_ming": str(dui_huan.get("ming", "")),
		"dui_huan_cha": int(dui_huan.get("cha", 0)),
		"tong_guan_ci_shu": sheng_li_ci_shu,
	}
	# 击杀者剩余比例按「当前体型 / 初始体型」算：上面直接按账本函数口径重算，避免 UI 再推
	jie_suan["sha_shou_sheng_yu"] = _sha_shou_sheng_yu_bi(zb)
	shang_ci_jie_suan = jie_suan
	bao_cun()
	return jie_suan


func _sha_shou_sheng_yu_bi(zb) -> int:
	# B2 文案 X%：击杀者当前体型 / 出场体型（无记录时 0）
	var chu := float(_qu(zb, "ben_ju_sha_shou_chu_shi", 0.0))
	var dang := float(_qu(zb, "ben_ju_sha_shou_ti_xing", 0.0))
	if chu <= 0.0:
		return 0
	return int(round(clampf(dang / chu, 0.0, 1.0) * 100.0))


func _ji_suan_qiang_du(zb) -> int:
	# E1：强度 = 主动技数 ×3 + 被动总档位 ×2 + 专属技持有 ×4 + 最终体型等级
	var zhu_dong = _qu(zb, "zhu_dong_zu", [])
	var zhu_dong_shu: int = zhu_dong.size() if zhu_dong is Array else 0
	var bei_dong_dang := 0
	var ceng = _qu(zb, "bei_dong_ceng", {})
	if ceng is Dictionary:
		for jian in ceng:
			bei_dong_dang += int(ceng[jian])
	var zhuan_shu := 0
	var yi_jing := {}
	var yi_xuan = _qu(zb, "yi_xuan_neng_li", [])
	if yi_xuan is Array:
		for neng in yi_xuan:
			if neng != null and neng.shi_zhuan_shu() and not yi_jing.has(neng.bian_hao):
				yi_jing[neng.bian_hao] = true
				zhuan_shu += 1
	return zhu_dong_shu * 3 + bei_dong_dang * 2 + zhuan_shu * 4 + int(_qu(zb, "deng_ji", 0))


func _zui_jin_dui_huan() -> Dictionary:
	# B2③：在所有未购、可兑换的通用能力里，找差额绝对值最小的一项
	var ming := ""
	var cha := 0
	var zui_cha := 1 << 30
	for neng in NengLiKu.quan_bu():
		if not ke_yong_jiu_dui_huan(neng) or you_yong_jiu(neng.bian_hao):
			continue
		var dai := cheng_jiu_dai_jia(neng)
		var cha_zhi := dai - cheng_jiu_zhi
		if absi(cha_zhi) < zui_cha:
			zui_cha = absi(cha_zhi)
			ming = neng.ming_zi
			cha = cha_zhi
	return {"ming": ming, "cha": cha}


func _qu(zb, jian: String, mo_ren = null):
	# 统一取值：账本节点 / 测试字典都能读；Node.get 读不到时给默认值
	if zb is Dictionary:
		return zb.get(jian, mo_ren)
	if zb is Object:
		var zhi = zb.get(jian)
		return mo_ren if zhi == null else zhi
	return mo_ren


func ji_lu_sheng_li() -> Array[XingTai]:
	# 兼容旧调用：按当前账本状态记一次胜利（B1 公式在 jie_suan_ben_ju；无账本时给保底 10）
	var jie_guo := {}
	# 裸实例（--script 测试）不在场景树里：绝对路径 get_node 会报 ERROR，
	# 直接走无账本保底分支，别让门禁被 ERROR 污染
	if is_inside_tree():
		jie_guo = jie_suan_ben_ju(JIE_JU_SHENG_LI)
	if jie_guo.is_empty():
		_ji_sheng_bao_di()
	return shang_ci_xin_jie_suo


func _ji_sheng_bao_di() -> void:
	# 无账本保底：胜场 +1，余额与累计成就各 +10（不叠加 B1 胜利的击沉机器船 +50）
	# 解锁差集按 D 的四类来源重算，让 --script 旧测试也能看到真实的新解锁提示
	var jiu_sheng := sheng_li_ci_shu
	var jiu_lei := lei_ji_cheng_jiu_zhi
	sheng_li_ci_shu += 1
	cheng_jiu_zhi += CHENG_JIU_MEI_CI
	lei_ji_cheng_jiu_zhi += CHENG_JIU_MEI_CI
	var xin_jie_suo: Array[XingTai] = []
	for xt in _xing_tai_zu:
		if not _pan_duan_jie_suo(xt, jiu_sheng, jiu_lei) and _pan_duan_jie_suo(xt, sheng_li_ci_shu, lei_ji_cheng_jiu_zhi):
			xin_jie_suo.append(xt)
	shang_ci_xin_jie_suo.assign(xin_jie_suo)
	bao_cun()


func get_xin_jie_suo() -> Array[XingTai]:
	var jie_guo: Array[XingTai] = []
	jie_guo.assign(shang_ci_xin_jie_suo)
	return jie_guo


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
	return _pan_duan_jie_suo(xt, sheng_li_ci_shu, lei_ji_cheng_jiu_zhi)


func _pan_duan_jie_suo(xt: XingTai, sheng: int, lei_ji: int) -> bool:
	# D 解锁分派：默认免费 / 广告 / 累计成就值 / 累计通关
	match xt.jie_suo_fang_shi:
		"mian":
			return true
		"guang_gao":
			return yi_kan_guang_gao.has(xt.bian_hao)
		"cheng_jiu":
			return lei_ji >= xt.jie_suo_can_shu
		"tong_guan":
			return sheng >= xt.jie_suo_can_shu
	# 旧数据/未知方式：退回旧字段的胜场阈值（保证旧 .tres 行为不变）
	return sheng >= xt.jie_suo_sheng_li_ci_shu


func jie_suo_ti_shi(xt: XingTai) -> String:
	# 选择页锁定卡文案：按 D 的解锁来源给一句人话
	if xt == null:
		return ""
	match xt.jie_suo_fang_shi:
		"guang_gao":
			return "看广告解锁（敬请期待）"
		"cheng_jiu":
			return "累计成就值 %d 解锁（当前 %d）" % [xt.jie_suo_can_shu, lei_ji_cheng_jiu_zhi]
		"tong_guan":
			return "累计通关 %d 次解锁（当前 %d）" % [xt.jie_suo_can_shu, sheng_li_ci_shu]
	return "胜利 %d 次解锁（当前 %d 次）" % [xt.jie_suo_sheng_li_ci_shu, sheng_li_ci_shu]


func shi_fou_guang_gao_jie_suo(bian_hao: StringName) -> bool:
	# 广告位判定：D 规定 TapTap SDK 未接入前置灰；这里只提供数据钩子
	return yi_kan_guang_gao.has(bian_hao)


func ke_xuan_xing_tai() -> Array[XingTai]:
	var jie_guo: Array[XingTai] = []
	for xt in _xing_tai_zu:
		if shi_fou_jie_suo(xt.bian_hao):
			jie_guo.append(xt)
	return jie_guo


func suo_you_xing_tai() -> Array[XingTai]:
	var jie_guo: Array[XingTai] = []
	jie_guo.assign(_xing_tai_zu)
	return jie_guo


func dang_qian_xing_tai() -> XingTai:
	var xt := _zhao_xing_tai(dang_qian_bian_hao)
	if xt == null or not shi_fou_jie_suo(dang_qian_bian_hao):
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
	# 仅编辑器调试按钮：按 D 的三种来源全部满足，解锁全部形态
	# 成就来源抬高「累计成就」而不是余额：不会凭空多出可消费的成就值
	var zui_gao_sheng := 0
	var zui_gao_lei := 0
	for xt in _xing_tai_zu:
		zui_gao_sheng = maxi(zui_gao_sheng, xt.jie_suo_sheng_li_ci_shu)
		if xt.jie_suo_fang_shi == "tong_guan":
			zui_gao_sheng = maxi(zui_gao_sheng, xt.jie_suo_can_shu)
		elif xt.jie_suo_fang_shi == "cheng_jiu":
			zui_gao_lei = maxi(zui_gao_lei, xt.jie_suo_can_shu)
		elif xt.jie_suo_fang_shi == "guang_gao" and not yi_kan_guang_gao.has(xt.bian_hao):
			yi_kan_guang_gao.append(xt.bian_hao)
	sheng_li_ci_shu = maxi(sheng_li_ci_shu, zui_gao_sheng)
	lei_ji_cheng_jiu_zhi = maxi(lei_ji_cheng_jiu_zhi, zui_gao_lei)
	bao_cun()


func tiao_shi_qing_chu_jin_du() -> void:
	# 仅编辑器调试按钮：进度归零、当前形态回默认、成就一并清空（调试口径一致）
	sheng_li_ci_shu = 0
	cheng_jiu_zhi = 0
	lei_ji_cheng_jiu_zhi = 0
	ya_li_xiu_zheng = 0
	you_dai_zhu_dong_bao_di = false
	shou_ju_jiao_ben_yi_zhi_xing = false
	yong_jiu_neng_li.clear()
	dang_qian_bian_hao = MO_REN_BIAN_HAO
	shang_ci_xin_jie_suo.clear()
	shang_ci_jie_suan.clear()
	yi_dian_liang_jin_hua.clear()  # 图鉴点亮也算进度：清进度一并清掉
	yi_chi_yu_zhong.clear()
	yi_kan_guang_gao.clear()
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
	# 一局打完（胜/负/死）都走 B1 结算入账；中途存档随即作废
	# 成就/解锁/压力修正都在 jie_suan_ben_ju 里一次写完并落盘
	qing_chu_zhong_tu()
	jie_suan_ben_ju(jie_guo)


func _zhao_xing_tai(bian_hao: StringName) -> XingTai:
	for xt in _xing_tai_zu:
		if xt.bian_hao == bian_hao:
			return xt
	return null


func _shi_shu_zi(zhi) -> bool:
	# JSON 的数字统一是 float，不能只认 TYPE_INT
	var lei_xing := typeof(zhi)
	return lei_xing == TYPE_INT or lei_xing == TYPE_FLOAT
