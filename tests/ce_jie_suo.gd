extends SceneTree
# 局外存档测试（TASK-018；2026-11-02 主角化改造）
# 默认值 / 胜利不误解锁 / 选择 / 读写档 / 损坏回退 / 调试
# 当前唯一主角是凹凸蜗牛鱼：0 胜即解锁、形态表只有 1 个；旧三形态已退为 NPC 数据。
# 不上树裸实例：_init 只装形态表，_ready 才读正式存档并连 ZhangBen 信号
# 全程用临时存档路径，结束时删除；测试不得碰玩家的正式存档

const CUN_DANG_SCRIPT := preload("res://scripts/cun_dang.gd")
const ZHU_JUE := "ao_tu_wo_niu_yu"

var passed := 0
var failed := 0
var lu_jing := ""


func _initialize() -> void:
	lu_jing = "user://ce_jie_suo_%d_%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	_shan_chu()
	var cd = CUN_DANG_SCRIPT.new()
	cd.lu_jing = lu_jing
	cd.zai_ru()

	# ---- 用例 1：没存档时的默认值（唯一主角开局可用）----
	assert_eq(cd.sheng_li_ci_shu, 0, "默认胜场 0")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "默认形态是凹凸蜗牛鱼")
	assert_eq(cd.suo_you_xing_tai().size(), 1, "形态表只剩 1 个主角")
	assert_eq(cd.ke_xuan_xing_tai().size(), 1, "0 胜也解锁唯一主角")
	assert_bool(cd.shi_fou_jie_suo(&"ao_tu_wo_niu_yu"), true, "蜗牛鱼默认解锁")
	assert_bool(cd.shi_fou_jie_suo(&"deng_long_yu"), false, "旧形态灯笼鱼不再是玩家选项")
	assert_bool(cd.shi_fou_jie_suo(&"dian_yao"), false, "旧形态电鳐不再是玩家选项")
	assert_bool(cd.shi_fou_jie_suo(&"qi_yu"), false, "旧形态旗鱼不再是玩家选项")
	assert_bool(cd.shi_fou_jie_suo(&"bu_cun_zai"), false, "未知 id 视为未解锁")
	assert_string(String(cd.dang_qian_xing_tai().bian_hao), ZHU_JUE, "当前形态回默认")
	assert_bool(FileAccess.file_exists(lu_jing), false, "读档不得创建存档文件")

	# ---- 用例 2：胜利只累计胜场，不再有“第 N 胜解锁新形态” ----
	var xin: Array[XingTai] = cd.ji_lu_sheng_li()
	assert_eq(xin.size(), 0, "首胜不解锁新形态（唯一主角早已可用）")
	assert_eq(cd.sheng_li_ci_shu, 1, "首胜后累计 1")
	assert_eq(cd.ke_xuan_xing_tai().size(), 1, "1 胜时可选形态仍 1 个")
	assert_bool(FileAccess.file_exists(lu_jing), true, "胜利瞬间写档")
	assert_eq(cd.shang_ci_xin_jie_suo.size(), 0, "没有新解锁提示入队")
	assert_eq(cd.qu_xin_jie_suo().size(), 0, "提示队列为空")

	# ---- 用例 3：继续胜利仍不解锁；旧形态不因胜场回到注册表 ----
	xin = cd.ji_lu_sheng_li()
	assert_eq(xin.size(), 0, "第二胜不解锁")
	assert_eq(cd.sheng_li_ci_shu, 2, "第二胜后累计 2")
	assert_bool(cd.shi_fou_jie_suo(&"qi_yu"), false, "2 胜也不会解锁旧旗鱼形态")
	xin = cd.ji_lu_sheng_li()
	assert_eq(xin.size(), 0, "第三胜不解锁")
	assert_eq(cd.sheng_li_ci_shu, 3, "第三胜后累计 3")

	# ---- 用例 4：选择与重读 ----
	assert_bool(cd.xuan_ze(&"ao_tu_wo_niu_yu"), true, "唯一主角可选")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "选择后当前形态为蜗牛鱼")
	assert_bool(cd.xuan_ze(&"qi_yu"), false, "旧形态不可选")
	assert_bool(cd.xuan_ze(&"bu_cun_zai"), false, "未知 id 不可选")
	var cd2 = CUN_DANG_SCRIPT.new()
	cd2.lu_jing = lu_jing
	cd2.zai_ru()
	assert_eq(cd2.sheng_li_ci_shu, 3, "重读胜场保持 3")
	assert_string(String(cd2.dang_qian_bian_hao), ZHU_JUE, "重读当前形态保持蜗牛鱼")
	cd2.free()

	# ---- 用例 5：调试解锁全部 / 清空进度 ----
	# 唯一形态 0 胜解锁：调试解锁只抬高胜场，不降——已累计 3 胜就保持 3，主角仍可选
	cd.tiao_shi_jie_suo_quan_bu()
	assert_eq(cd.sheng_li_ci_shu, 3, "调试解锁不降已有胜场（最高阈值 0，保持 3）")
	assert_eq(cd.ke_xuan_xing_tai().size(), 1, "调试解锁后主角仍可选")
	var cd3 = CUN_DANG_SCRIPT.new()
	cd3.lu_jing = lu_jing
	cd3.zai_ru()
	assert_eq(cd3.sheng_li_ci_shu, 3, "调试解锁已落盘")
	cd3.free()
	cd.tiao_shi_qing_chu_jin_du()
	assert_eq(cd.sheng_li_ci_shu, 0, "调试清空后胜场 0")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "调试清空后仍是蜗牛鱼")
	assert_bool(cd.xuan_ze(&"dian_yao"), false, "0 胜不能选旧电鳐形态")
	assert_eq(cd.qu_xin_jie_suo().size(), 0, "调试清空清掉提示")

	# ---- 用例 6：坏存档只回退、不覆盖 ----
	_xie_wen("not json at all")
	var yuan := _du_wen()
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 0, "坏 JSON 回退 0 胜")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "坏 JSON 回退默认主角")
	assert_string(_du_wen(), yuan, "坏 JSON 加载后不得覆盖原文件")

	_xie_wen("[1, 2, 3]")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 0, "JSON 非字典回退 0 胜")

	_xie_wen("{\"ban_ben\": 99, \"sheng_li_ci_shu\": 2, \"dang_qian_xing_tai\": \"ao_tu_wo_niu_yu\"}")
	yuan = _du_wen()
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 0, "版本不符整体回退 0 胜")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "版本不符回退默认主角")
	assert_string(_du_wen(), yuan, "版本不符不得覆盖原文件")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": -5, \"dang_qian_xing_tai\": \"ao_tu_wo_niu_yu\"}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 0, "负胜场夹到 0")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "负胜场时默认形态保留")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 2, \"dang_qian_xing_tai\": \"bu_cun_zai\"}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 2, "未知形态 id 时保留胜场")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "未知形态 id 回退默认")

	# 旧版本存档里可能还记着灯笼鱼/电鳐/旗鱼：胜场保留，形态回默认主角
	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 2, \"dang_qian_xing_tai\": \"qi_yu\"}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 2, "旧形态 id 不影响胜场")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "旧形态 id 不再恢复，回退蜗牛鱼")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 0, \"dang_qian_xing_tai\": \"dian_yao\"}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 0, "旧形态记录不影响胜场")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "旧形态不可作为当前形态")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 1.0, \"dang_qian_xing_tai\": \"ao_tu_wo_niu_yu\"}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 1, "JSON 浮点胜场按整数读取")
	assert_bool(cd.shi_fou_jie_suo(&"ao_tu_wo_niu_yu"), true, "浮点胜场也认主角")
	assert_bool(cd.shi_fou_jie_suo(&"dian_yao"), false, "浮点胜场不会复活旧形态")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": \"2\", \"dang_qian_xing_tai\": \"ao_tu_wo_niu_yu\"}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 0, "字符串胜场视为非法回退 0")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 2, \"dang_qian_xing_tai\": 5}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 2, "非字符串当前形态保留胜场")
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "非字符串当前形态回默认")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 2, \"dang_qian_xing_tai\": \"ao_tu_wo_niu_yu\"}")
	cd.zai_ru()
	assert_string(String(cd.dang_qian_bian_hao), ZHU_JUE, "合法存档正常恢复蜗牛鱼")

	# ---- 收卷 ----
	cd.free()
	_shan_chu()
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _xie_wen(wen: String) -> void:
	var wen_jian := FileAccess.open(lu_jing, FileAccess.WRITE)
	if wen_jian == null:
		failed += 1
		print("FAIL: 无法写入临时存档 " + lu_jing)
		return
	wen_jian.store_string(wen)
	wen_jian.close()


func _du_wen() -> String:
	var wen_jian := FileAccess.open(lu_jing, FileAccess.READ)
	if wen_jian == null:
		return ""
	var wen := wen_jian.get_as_text()
	wen_jian.close()
	return wen


func _shan_chu() -> void:
	if FileAccess.file_exists(lu_jing):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(lu_jing))


func assert_eq(shi_ji, qi_wang: int, biao_qian: String) -> void:
	# 严格比较：类型也必须一致，防 bool == 1 之类的假绿
	if shi_ji == qi_wang and typeof(shi_ji) == typeof(qi_wang):
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %s，实际 %s）" % [biao_qian, str(qi_wang), str(shi_ji)])


func assert_bool(shi_ji: bool, qi_wang: bool, biao_qian: String) -> void:
	if typeof(shi_ji) == TYPE_BOOL and shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %s，实际 %s）" % [biao_qian, str(qi_wang), str(shi_ji)])


func assert_string(shi_ji: String, qi_wang: String, biao_qian: String) -> void:
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %s，实际 %s）" % [biao_qian, qi_wang, shi_ji])
