extends SceneTree
# 局外存档测试（TASK-018）：默认值 / 胜利解锁 / 选择 / 读写档 / 损坏回退 / 调试
# 不上树裸实例：_init 只装形态表，_ready 才读正式存档并连 ZhangBen 信号
# 全程用临时存档路径，结束时删除；测试不得碰玩家的正式存档

const CUN_DANG_SCRIPT := preload("res://scripts/cun_dang.gd")

var passed := 0
var failed := 0
var lu_jing := ""


func _initialize() -> void:
	lu_jing = "user://ce_jie_suo_%d_%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	_shan_chu()
	var cd = CUN_DANG_SCRIPT.new()
	cd.lu_jing = lu_jing
	cd.zai_ru()

	# ---- 用例 1：没存档时的默认值 ----
	assert_eq(cd.sheng_li_ci_shu, 0, "默认胜场 0")
	assert_string(String(cd.dang_qian_bian_hao), "deng_long_yu", "默认形态灯笼鱼")
	assert_eq(cd.suo_you_xing_tai().size(), 3, "形态表共 3 个")
	assert_eq(cd.ke_xuan_xing_tai().size(), 1, "0 胜只解锁 1 个")
	assert_bool(cd.shi_fou_jie_suo(&"deng_long_yu"), true, "灯笼鱼默认解锁")
	assert_bool(cd.shi_fou_jie_suo(&"dian_yao"), false, "0 胜电鳐未解锁")
	assert_bool(cd.shi_fou_jie_suo(&"qi_yu"), false, "0 胜旗鱼未解锁")
	assert_bool(cd.shi_fou_jie_suo(&"bu_cun_zai"), false, "未知 id 视为未解锁")
	assert_string(String(cd.dang_qian_xing_tai().bian_hao), "deng_long_yu", "当前形态回默认")
	assert_bool(FileAccess.file_exists(lu_jing), false, "读档不得创建存档文件")

	# ---- 用例 2：首胜解锁电鳐并立即写档 ----
	var xin: Array[XingTai] = cd.ji_lu_sheng_li()
	assert_eq(xin.size(), 1, "首胜只解锁 1 个")
	assert_string(String(xin[0].bian_hao), "dian_yao", "首胜解锁电鳐")
	assert_eq(cd.sheng_li_ci_shu, 1, "首胜后累计 1")
	assert_bool(cd.shi_fou_jie_suo(&"dian_yao"), true, "1 胜电鳐已解锁")
	assert_bool(cd.shi_fou_jie_suo(&"qi_yu"), false, "1 胜旗鱼仍未解锁")
	assert_eq(cd.ke_xuan_xing_tai().size(), 2, "1 胜可选出 2 个")
	assert_bool(FileAccess.file_exists(lu_jing), true, "胜利瞬间写档")
	assert_eq(cd.shang_ci_xin_jie_suo.size(), 1, "解锁提示已入队")
	var ti: Array[XingTai] = cd.qu_xin_jie_suo()
	assert_eq(ti.size(), 1, "第一次消费拿到 1 个提示")
	assert_string(String(ti[0].bian_hao), "dian_yao", "提示内容为电鳐")
	assert_eq(cd.qu_xin_jie_suo().size(), 0, "提示只消费一次")

	# ---- 用例 3：第二胜解锁旗鱼，第三胜不再解锁 ----
	xin = cd.ji_lu_sheng_li()
	assert_eq(xin.size(), 1, "第二胜解锁 1 个")
	assert_string(String(xin[0].bian_hao), "qi_yu", "第二胜解锁旗鱼")
	assert_eq(cd.sheng_li_ci_shu, 2, "第二胜后累计 2")
	assert_eq(cd.ke_xuan_xing_tai().size(), 3, "2 胜全解锁")
	xin = cd.ji_lu_sheng_li()
	assert_eq(xin.size(), 0, "第三胜不再解锁新形态")
	assert_eq(cd.sheng_li_ci_shu, 3, "第三胜后累计 3")

	# ---- 用例 4：选择与重读 ----
	assert_bool(cd.xuan_ze(&"qi_yu"), true, "旗鱼已解锁可选")
	assert_string(String(cd.dang_qian_bian_hao), "qi_yu", "选择后当前形态为旗鱼")
	assert_bool(cd.xuan_ze(&"bu_cun_zai"), false, "未知 id 不可选")
	var cd2 = CUN_DANG_SCRIPT.new()
	cd2.lu_jing = lu_jing
	cd2.zai_ru()
	assert_eq(cd2.sheng_li_ci_shu, 3, "重读胜场保持 3")
	assert_string(String(cd2.dang_qian_bian_hao), "qi_yu", "重读当前形态保持旗鱼")
	cd2.free()

	# ---- 用例 5：调试解锁全部 / 清空进度 ----
	cd.tiao_shi_jie_suo_quan_bu()
	assert_eq(cd.sheng_li_ci_shu, 2, "调试解锁拉到最高阈值 2")
	assert_eq(cd.ke_xuan_xing_tai().size(), 3, "调试解锁后全可选")
	var cd3 = CUN_DANG_SCRIPT.new()
	cd3.lu_jing = lu_jing
	cd3.zai_ru()
	assert_eq(cd3.sheng_li_ci_shu, 2, "调试解锁已落盘")
	cd3.free()
	cd.tiao_shi_qing_chu_jin_du()
	assert_eq(cd.sheng_li_ci_shu, 0, "调试清空后胜场 0")
	assert_string(String(cd.dang_qian_bian_hao), "deng_long_yu", "调试清空后回灯笼鱼")
	assert_bool(cd.xuan_ze(&"dian_yao"), false, "0 胜不能选电鳐")
	assert_eq(cd.qu_xin_jie_suo().size(), 0, "调试清空清掉提示")

	# ---- 用例 6：坏存档只回退、不覆盖 ----
	_xie_wen("not json at all")
	var yuan := _du_wen()
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 0, "坏 JSON 回退 0 胜")
	assert_string(String(cd.dang_qian_bian_hao), "deng_long_yu", "坏 JSON 回退默认形态")
	assert_string(_du_wen(), yuan, "坏 JSON 加载后不得覆盖原文件")

	_xie_wen("[1, 2, 3]")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 0, "JSON 非字典回退 0 胜")

	_xie_wen("{\"ban_ben\": 99, \"sheng_li_ci_shu\": 2, \"dang_qian_xing_tai\": \"qi_yu\"}")
	yuan = _du_wen()
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 0, "版本不符整体回退 0 胜")
	assert_string(String(cd.dang_qian_bian_hao), "deng_long_yu", "版本不符回退默认形态")
	assert_string(_du_wen(), yuan, "版本不符不得覆盖原文件")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": -5, \"dang_qian_xing_tai\": \"deng_long_yu\"}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 0, "负胜场夹到 0")
	assert_string(String(cd.dang_qian_bian_hao), "deng_long_yu", "负胜场时默认形态保留")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 2, \"dang_qian_xing_tai\": \"bu_cun_zai\"}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 2, "未知形态 id 时保留胜场")
	assert_string(String(cd.dang_qian_bian_hao), "deng_long_yu", "未知形态 id 回退默认")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 0, \"dang_qian_xing_tai\": \"dian_yao\"}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 0, "未解锁形态记录不影响胜场")
	assert_string(String(cd.dang_qian_bian_hao), "deng_long_yu", "未解锁形态不可作为当前形态")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 1.0, \"dang_qian_xing_tai\": \"deng_long_yu\"}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 1, "JSON 浮点胜场按整数读取")
	assert_bool(cd.shi_fou_jie_suo(&"dian_yao"), true, "浮点胜场也参与解锁")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": \"2\", \"dang_qian_xing_tai\": \"deng_long_yu\"}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 0, "字符串胜场视为非法回退 0")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 2, \"dang_qian_xing_tai\": 5}")
	cd.zai_ru()
	assert_eq(cd.sheng_li_ci_shu, 2, "非字符串当前形态保留胜场")
	assert_string(String(cd.dang_qian_bian_hao), "deng_long_yu", "非字符串当前形态回默认")

	_xie_wen("{\"ban_ben\": 1, \"sheng_li_ci_shu\": 2, \"dang_qian_xing_tai\": \"qi_yu\"}")
	cd.zai_ru()
	assert_string(String(cd.dang_qian_bian_hao), "qi_yu", "合法存档正常恢复旗鱼")

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
