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
	_xie_neng_li()
	_xie_jie_suo()


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
	var xin := CunDang.qu_xin_jie_suo()
	if ZhangBen.jie_ju != ZhangBen.JieJu.SHENG_LI or xin.is_empty():
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
