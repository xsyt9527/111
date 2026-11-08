extends Node
# 音效管理器（Autoload YinXiang）：所有声音的统一入口
# 设计：fang() 内部是播放器池（同帧多处触发不打架）；BGM 单独一个常驻播放器，
# 场景切换不断曲；升级音在这里监听账本信号——表现层不写进账本
# 素材全部是程序合成 WAV（免版税·自制，见 docs/美术资源首装记录/引擎词总表）

const YIN_XIAO_BIAO: Dictionary = {
	&"chi": preload("res://assets/yinxiao/chi.wav"),            # 吞鱼 / 吃鱼肉 / 吃植物
	&"yao": preload("res://assets/yinxiao/yao.wav"),            # 咬击命中
	&"shou_shang": preload("res://assets/yinxiao/shou_shang.wav"),  # 玩家受伤
	&"sheng_ji": preload("res://assets/yinxiao/sheng_ji.wav"),  # 升级琶音
	&"shi_kong": preload("res://assets/yinxiao/shi_kong.wav"),  # 电麻/毒晕失控
	&"tan_chuang": preload("res://assets/yinxiao/tan_chuang.wav"),  # 升级三选一弹出
	&"fang_neng_li": preload("res://assets/yinxiao/fang_neng_li.wav"),  # 主动能力释放
	&"sheng_li": preload("res://assets/yinxiao/sheng_li.wav"),  # 胜利结算
	&"shi_bai": preload("res://assets/yinxiao/shi_bai.wav"),    # 失败结算
	&"si_wang": preload("res://assets/yinxiao/si_wang.wav"),    # 死亡结算
	&"an_niu": preload("res://assets/yinxiao/an_niu.wav"),      # 按钮点击
}
const BGM_SHEN_HAI := preload("res://assets/yinxiao/bgm_shen_hai.wav")  # 深海摇篮：主界面/选角/结算/默认氛围
const BGM_QU_MU: Dictionary = {
	&"shen_hai": BGM_SHEN_HAI,
	&"tan_suo": preload("res://assets/yinxiao/bgm_tan_suo.wav"),    # 深海探索：局内成长
	&"jue_zhan": preload("res://assets/yinxiao/bgm_jue_zhan.wav"),  # 钢铁围猎：机器船决战
}

const CHI_RONG_LIANG := 6        # 播放器池大小：同屏咬声+吃声+受伤声并发够用
const BGM_YIN_LIANG_DB := -10.0  # BGM 比音效低一截：氛围垫底，不抢反馈

var _chi: Array[AudioStreamPlayer] = []  # 播放器池
var _bgm: AudioStreamPlayer
var _dang_qian_qu: StringName = &"shen_hai"  # 当前曲目：同曲重复调用不重头

# 音量（0~1 线性，主界面设置面板滑条直改）：setter 同步所有播放器，拖动即听即得
var yin_xiao_yin_liang := 1.0: set = _she_yin_xiao_yin_liang
var bgm_yin_liang := 1.0: set = _she_bgm_yin_liang


func _ready() -> void:
	for i in CHI_RONG_LIANG:
		var bo: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(bo)
		_chi.append(bo)
	_bgm = AudioStreamPlayer.new()
	_bgm.stream = BGM_SHEN_HAI
	_bgm.volume_db = BGM_YIN_LIANG_DB
	add_child(_bgm)
	# 三首 BGM 都是自己用 LMMS 做的无缝循环：运行时打上循环标记（WAV 导入参数不生效，
	# 实测 4.7 导入器会忽略 edit/loop_mode，所以这里直接改 AudioStreamWAV）。
	# 循环端点 = 整首长度；AudioStreamPlayer 播到末尾自动回到开头，没有 finished 空档。
	for qu in BGM_QU_MU:
		_kai_xun_huan(BGM_QU_MU[qu])
	# 兜底：万一某个流没打上循环（例如将来换成 ogg），播完手动续，
	# 选择页/主场景/结算页同一首不断曲
	_bgm.finished.connect(func() -> void: _bgm.play())
	# 启动时应用玩家设置：CunDang 在本 Autoload 之前 ready（project.godot 顺序），缓存字段已就绪
	# 按路径找：--script 模式不注册 Autoload，编译期引用会让那些测试全红（ce_panding 老规矩）
	var cd := get_node_or_null("/root/CunDang")
	if cd != null:
		yin_xiao_yin_liang = cd.get("yin_xiao_yin_liang")
		bgm_yin_liang = cd.get("bgm_yin_liang")
	# 升级音由这里监听账本：触发方（加经验的地方）不用关心声音
	# 不能写 ZhangBen.xxx：--script 纯逻辑测试不注册 Autoload，编译期引用会让那些测试全红
	# （ce_panding 注释里的老规矩）；运行时按路径找，编译期零依赖
	var zb := get_node_or_null("/root/ZhangBen")
	if zb != null:
		zb.sheng_ji.connect(_on_sheng_ji)


func _exit_tree() -> void:
	# 离树即停声（场景树析构时每个节点都会收到；--script 测试不进树走不到这里，
	# 那条路径的停声收尾在 ce_panding 收卷处自己做）。
	# 已知限制：headless --quit-after 强杀时退出流程没有帧可走，在播的 BGM 仍会报
	# 1 行 resources still in use（AudioStreamPlayback 引用由音频线程异步释放）——
	# 引擎级行为，与游戏逻辑无关，真机运行不受影响
	ting_bgm()
	quan_ting()


func fang(bian_hao: StringName, yin_liang_db := 0.0) -> void:
	# 播一条音效：名字查表；池里有空闲就用，全忙就顶掉最早的那个
	var liu: AudioStream = YIN_XIAO_BIAO.get(bian_hao)
	if liu == null:
		push_warning("YinXiang: 未知音效名 " + String(bian_hao))
		return
	for bo in _chi:
		if not bo.playing:
			_bo_fang(bo, liu, yin_liang_db)
			return
	_bo_fang(_chi[0], liu, yin_liang_db)  # 全忙：新声音优先（连吃一串鱼时后一口要响）


func bo_bgm(qu: StringName = &"shen_hai") -> void:
	# BGM 常驻播：同一首已在播就不重头（选择页 → Main → 结算页无缝续）；
	# 换曲（局内探索 → 机器船决战）才切流并从头播
	var liu: AudioStream = BGM_QU_MU.get(qu, BGM_SHEN_HAI)
	if _dang_qian_qu == qu and _bgm.playing:
		return
	_dang_qian_qu = qu
	if _bgm.stream != liu:
		_bgm.stream = liu
	_bgm.play()


func _kai_xun_huan(liu: AudioStream) -> void:
	# 给 WAV 打开前向循环：loop_end 用帧数（不是秒）
	var w := liu as AudioStreamWAV
	if w == null:
		return
	w.loop_begin = 0
	w.loop_end = int(round(w.get_length() * w.mix_rate))
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD


func ting_bgm() -> void:
	_bgm.stop()


func quan_ting() -> void:
	# 全部静音：池里所有正在响的音效立刻停（暂停菜单/测试收卷共用）
	for bo in _chi:
		bo.stop()


func ren_he_zai_xiang() -> bool:
	# 有没有任何声音正在响（测试收卷轮询用：等结算音开播再掐，掐早了盖不住它）
	for bo in _chi:
		if bo.playing:
			return true
	return _bgm != null and _bgm.playing


func _bo_fang(bo: AudioStreamPlayer, liu: AudioStream, yin_liang_db: float) -> void:
	bo.stream = liu
	bo.volume_db = _xian_xing_zhuan_db(yin_xiao_yin_liang) + yin_liang_db  # 玩家音量打底，调用方参数做相对微调
	bo.play()


func _she_yin_xiao_yin_liang(zhi: float) -> void:
	yin_xiao_yin_liang = clampf(zhi, 0.0, 1.0)
	var db := _xian_xing_zhuan_db(yin_xiao_yin_liang)
	for bo in _chi:
		bo.volume_db = db


func _she_bgm_yin_liang(zhi: float) -> void:
	bgm_yin_liang = clampf(zhi, 0.0, 1.0)
	if _bgm != null:
		_bgm.volume_db = BGM_YIN_LIANG_DB + _xian_xing_zhuan_db(bgm_yin_liang)


func _xian_xing_zhuan_db(xian_xing: float) -> float:
	# 线性 0~1 → 分贝；0 = 全静音用 -80dB（linear_to_db(0) 是负无穷，播放器不认）
	return -80.0 if xian_xing <= 0.0 else linear_to_db(xian_xing)


func _on_sheng_ji(_xin_deng_ji: int) -> void:
	# 升级音由这里监听账本广播：触发方（加经验的地方）不用关心声音
	fang(&"sheng_ji")
