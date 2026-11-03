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
# 显式注册表：导出后 .tres 会变成 .remap/.res，运行时 DirAccess 列目录不可靠
# 当前唯一主角是凹凸蜗牛鱼；灯笼鱼/电鳐/旗鱼的 .tres 仍保留，但只作为 NPC 鱼种数据，
# 不再进入形态注册表（选择页因此只生成蜗牛鱼一张卡）。以后加主角向这里追加即可。
const XING_TAI_ZU := [
	preload("res://data/xingtai/ao_tu_wo_niu_yu.tres"),
]

var lu_jing := MO_REN_LU_JING  # 测试可换临时路径；正式运行用默认路径
var zhong_tu_lu_jing := "user://shenhaishiji_zhongtu.json"  # 中途存档路径（测试可换临时路径）
var she_zhi_lu_jing := "user://shenhaishiji_shezhi.json"  # 游玩设置路径（测试可换临时路径）
var yin_xiao_yin_liang := 1.0  # 音效音量 0.0~1.0（线性）；主界面设置面板滑条直改
var bgm_yin_liang := 1.0       # BGM 音量 0.0~1.0（线性）
var yao_gan_ce := "zuo"        # 摇杆在屏幕哪一侧："zuo"=左下（默认）/ "you"=右下；技能按钮跟着换边
var sheng_li_ci_shu := 0  # 累计胜利次数（解锁唯一依据）
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


func jia_zai_xing_tai() -> void:
	# 装载显式注册表；阈值升序，同阈值按 id 排序（选择页/解锁顺序稳定）
	_xing_tai_zu.assign(XING_TAI_ZU)
	_xing_tai_zu.sort_custom(func(a: XingTai, b: XingTai) -> bool:
		if a.jie_suo_sheng_li_ci_shu != b.jie_suo_sheng_li_ci_shu:
			return a.jie_suo_sheng_li_ci_shu < b.jie_suo_sheng_li_ci_shu
		return String(a.bian_hao) < String(b.bian_hao)
	)


func zai_ru() -> void:
	# 读档：任何失败都只回退默认值，绝不写文件（避免把玩家存档改坏）
	sheng_li_ci_shu = 0
	dang_qian_bian_hao = MO_REN_BIAN_HAO
	shang_ci_xin_jie_suo.clear()
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
	wen_jian.store_string(JSON.stringify({
		"ban_ben": BAN_BEN,
		"sheng_li_ci_shu": sheng_li_ci_shu,
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
	}))
	wen_jian.close()
	return true


func an_bian_hao_zhao_xing_tai(bian_hao: StringName) -> XingTai:
	# 按 id 查形态资源：主界面"继续游戏"重建账本形态引用用（查不到返回 null，由调用方回退）
	return _zhao_xing_tai(bian_hao)


func ji_lu_sheng_li() -> Array[XingTai]:
	# 胜利瞬间调用：胜场 +1，返回跨过阈值的新解锁形态，并立即写档
	var jiu_ci_shu := sheng_li_ci_shu
	sheng_li_ci_shu += 1
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
	# 仅编辑器调试按钮：进度归零、当前形态回默认
	sheng_li_ci_shu = 0
	dang_qian_bian_hao = MO_REN_BIAN_HAO
	shang_ci_xin_jie_suo.clear()
	bao_cun()


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
