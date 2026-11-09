extends CanvasLayer
# 结算页：读账本展示本局结局、等级、存活时长与能力 build（主动 + 被动层数）
# 账本是 Autoload 常驻——玩家死了场景销毁，数据还活着，这里见天日（第 6 课预埋数据首次展示）
# 三种结局：击败机器船（胜利）/ 拖满 10 分钟（失败）/ 被吃或饿死（死亡）

func _ready() -> void:
	get_tree().paused = false  # 保险：结算页绝不能停在一半的暂停里
	$ChongKai.pressed.connect(_on_chong_kai_pressed)  # 先接线：空能力分支带 return，放后面会被跳过
	$HuanXingTai.pressed.connect(_on_huan_xing_tai_pressed)
	$DengJi.text = "Lv." + str(ZhangBen.deng_ji)
	# 存活时长：死亡也算本局用时，账本时钟只在活着时走，正好是“活了多久”
	$ShengCun.text = "存活 " + ZhangBen.ge_shi_shi_jian(ZhangBen.ju_nei_shi_jian)
	_xie_jie_ju()
	_xie_ben_ju_zhan_ji()
	_xie_cheng_jiu()
	_xie_neng_li()
	_xie_jie_suo()


func _jie_suan_shu_ju() -> Dictionary:
	# B2：优先用结算瞬间 CunDang 记下的明细；没有（直接开场景/旧流程）时退回账本现算
	if not CunDang.shang_ci_jie_suan.is_empty():
		return CunDang.shang_ci_jie_suan
	return {
		"deng_ji": ZhangBen.deng_ji,
		"ji_sha": ZhangBen.ben_ju_ji_sha_shu,
		"tun_chi": ZhangBen.ben_ju_tun_chi_shu,
		"diao_rou": ZhangBen.ben_ju_diao_rou_liang,
		"sheng_cun": ZhangBen.ju_nei_shi_jian,
		"cheng_jiu": 0,
		"ming_xi": [],
		"sha_shou_ming": ZhangBen.ben_ju_sha_shou_ming,
		"sha_shou_sheng_yu": 0,
		"fan_sha_kou": ZhangBen.ben_ju_fan_sha_kou,
		"xin_yu_zhong": [],
		"dui_huan_ming": "",
		"dui_huan_cha": 0,
	}


func _xie_ben_ju_zhan_ji() -> void:
	# B2 区块①：本局战绩（存活/最终体型/吞噬数/造成掉肉总量）
	var js := _jie_suan_shu_ju()
	var miao := float(js.get("sheng_cun", 0.0))
	$ZhanJi.text = "① 本局战绩\n存活 %s ｜ 最终体型 Lv.%d\n吞噬 %d 条 ｜ 击杀 %d\n对敌造成掉肉总量 %.1f" % [
		ZhangBen.ge_shi_shi_jian(miao), int(js.get("deng_ji", 0)),
		int(js.get("tun_chi", 0)), int(js.get("ji_sha", 0)),
		float(js.get("diao_rou", 0.0)),
	]
	# B2 区块②：差一点——死亡才有意义；胜利时给一句收束
	if ZhangBen.jie_ju == ZhangBen.JieJu.SI_WANG and str(js.get("sha_shou_ming", "")) != "":
		$ChaYiDian.text = "② 差一点\n被【%s】击杀，它剩 %d%% 体型——再咬 %d 口就能反杀" % [
			str(js.get("sha_shou_ming", "")),
			int(js.get("sha_shou_sheng_yu", 0)),
			int(js.get("fan_sha_kou", 0)),
		]
	elif ZhangBen.jie_ju == ZhangBen.JieJu.SI_WANG:
		$ChaYiDian.text = "② 差一点\n没记录到击杀者——下一局再咬回来"
	else:
		$ChaYiDian.text = "② 差一点\n你活到了最后，没有差一点"


func _xie_cheng_jiu() -> void:
	# B2 区块③ + B1：成就值明细不再只在胜利显示（死亡局也入账）
	var js := _jie_suan_shu_ju()
	var ming_xi = js.get("ming_xi", [])
	var xiang := ""
	if ming_xi is Array and not ming_xi.is_empty():
		xiang = "\n明细：" + _lian_jie(ming_xi, "；")
	var xin_yu = js.get("xin_yu_zhong", [])
	var xin_wen := ""
	if xin_yu is Array and not xin_yu.is_empty():
		xin_wen = "\n图鉴新点亮鱼种：" + _lian_jie(xin_yu, "、")
	var dui_huan := ""
	var dm := str(js.get("dui_huan_ming", ""))
	if dm != "":
		var cha := int(js.get("dui_huan_cha", 0))
		if cha > 0:
			dui_huan = "\n成就值可兑换【%s】还差 %d" % [dm, cha]
		else:
			dui_huan = "\n成就值已可兑换【%s】" % dm
	$ChengJiuZhi.text = "成就值 +%d ｜ 累计 %d ｜ 余额 %d" % [
		int(js.get("cheng_jiu", 0)), int(js.get("lei_ji", CunDang.lei_ji_cheng_jiu_zhi)),
		int(js.get("yu_e", CunDang.cheng_jiu_zhi)),
	]
	$JinDuGou.text = "③ 进度钩" + xiang + xin_wen + dui_huan


func _xie_neng_li() -> void:
	# 当前 build：全部已装备主动 + 被动叠层（多槽共存后没有“被替换”概念，只看最终成型）
	if ZhangBen.zhu_dong_zu.is_empty() and ZhangBen.bei_dong_ceng.is_empty():
		var kong := Label.new()
		kong.text = "（一个能力都没获得）"
		$NengLiLieBiao.add_child(kong)
		return
	for neng in ZhangBen.zhu_dong_zu:
		var zhu := Label.new()
		zhu.text = "主动：" + neng.ming_zi
		$NengLiLieBiao.add_child(zhu)
	for bian_hao in ZhangBen.bei_dong_ceng:
		var ceng := int(ZhangBen.bei_dong_ceng[bian_hao])
		if ceng <= 0:
			continue
		var ming := _zhao_ming(bian_hao)
		if ming == "":
			continue
		var bei := Label.new()
		bei.text = "被动：%s ×%d" % [ming, ceng]
		$NengLiLieBiao.add_child(bei)


func _lian_jie(shu_zu: Array, fen: String) -> String:
	# 把任意 Array 拼成 "a；b；c"（String.join 只吃 PackedStringArray，这里手动拼更稳）
	var wen := ""
	for i in shu_zu.size():
		if i > 0:
			wen += fen
		wen += str(shu_zu[i])
	return wen


func _zhao_ming(bian_hao: StringName) -> String:
	# 能力 id → 显示名：从本局获得历史反查（账本只存 id 与层数）
	for neng in ZhangBen.yi_xuan_neng_li:
		if neng != null and neng.bian_hao == bian_hao:
			return neng.ming_zi
	return ""


func _xie_jie_ju() -> void:
	# 标题/副标题/颜色都按账本结局选：结算页不自己判断生死，只翻译账本
	match ZhangBen.jie_ju:
		ZhangBen.JieJu.SHENG_LI:
			$BiaoTi.text = "打破圈养"
			$BiaoTi.modulate = Color(1.0, 0.86, 0.35)
			$JieGuo.text = "机器船沉入深海，你逃出了鱼缸"
			YinXiang.fang(&"sheng_li")
		ZhangBen.JieJu.SHI_BAI:
			$BiaoTi.text = "被收走"
			$BiaoTi.modulate = Color(0.78, 0.84, 0.95)
			$JieGuo.text = "时间耗尽，机器船仍在头顶"
			YinXiang.fang(&"shi_bai")
		ZhangBen.JieJu.SI_WANG:
			$BiaoTi.text = "本局终了"
			$BiaoTi.modulate = Color(1.0, 0.45, 0.45)
			$JieGuo.text = "你成了别人的食物"
			YinXiang.fang(&"si_wang")
		_:
			$BiaoTi.text = "本局终了"
			$JieGuo.text = "（没有记录到结局）"


func _xie_jie_suo() -> void:
	# 无条件消费本次解锁提示：死亡/失败也清掉，避免显示上一局残留
	# D 的成就值解锁可能在死亡局跨过门槛，所以不再限定胜利才显示
	var xin := CunDang.qu_xin_jie_suo()
	if xin.is_empty():
		$JieSuoTiShi.visible = false
		return
	var wen := "解锁新形态："
	for i in xin.size():
		if i > 0:
			wen += "、"
		wen += xin[i].ming_zi
	$JieSuoTiShi.text = wen
	$JieSuoTiShi.visible = true


func _on_chong_kai_pressed() -> void:
	# 再来一次：保留当前形态，只复位局内账本
	YinXiang.fang(&"an_niu")
	ZhangBen.chong_zhi_bao_liu_xing_tai()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_huan_xing_tai_pressed() -> void:
	# 换形态：回选择页，形态由玩家重新选
	YinXiang.fang(&"an_niu")
	ZhangBen.chong_zhi()
	get_tree().change_scene_to_file("res://scenes/XingTaiXuanZe.tscn")
