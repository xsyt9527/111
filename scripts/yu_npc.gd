extends Node2D
class_name YuNpc
# NPC 鱼：鱼种数据驱动；有感知→评分→行动的状态机（策划案 8.5、8.6.3）
# 优先级：复仇目标 > 感知范围内最大的小鱼 > 玩家；打不过就逃

@export var bianju := 80.0  # 屏幕外多远才算离开（像素）
const HONG_GUANG_FANG_DA := 1.5  # 红光层比本体大 50%：露在贴图外的部分才是那圈“红光”
const SI_KAO_JIAN_GE := 0.3  # 思考间隔（秒）：不每帧扫全场的性能闸
const YAO_JI_LENG_QUE := 0.5  # 咬击冷却（秒，策划案 8.6.3）
const TAO_PAO_SHI_CHANG := 2.0  # 受击逃跑持续（秒）
const ZUI_XIAO_TI_XING := 0.5  # 被咬到的最小体型：不会被咬成负数
const ZHUI_GAN_JIA_SU := 1.15  # 追击/逃跑步频略快于巡游
const CHI_YU_BEI_LV := 1.1  # 整吞门槛（与玩家 Yu.TUN_CHI_BEI_LV 同值）
const BU_RE_DA_BEI_LV := 2.0  # NPC 不惹大太多：同类比它大 2 倍以上就不去复仇（鱼群磨不死鲸鲨）
const DIAN_JI_JIAN_GE := 1.5  # 电鳗放电间隔（秒）
const DIAN_JI_BAN_JING := 90.0  # 电鳗放电半径（世界像素）：身边的鱼和玩家一起被电
const SHOU_HUI_YU_LIANG := 240.0  # 游出镜头多远才回收：留出“刚出生在一屏外排队进场”的纵深
const BOOS_SHENG_JI_JIAN_GE := 30.0  # 首领每 30 秒长一次（想改成长节奏改这里）
const BOOS_MEI_CI_JIA_DENG_JI := 2.0  # ★首领每次加多少等级（体型 +N）：想改成长速度就改这一行
const BOOS_ZHUI_JI_SHI_CHANG := 8.0  # 首领看见玩家后追多久（秒）
const BOOS_ZHUI_JI_LENG_QUE := 5.0  # 追完歇多久才能再次上头（秒）：给玩家脱战窗口
const BOOS_ZHUI_JI_SU_DU := 170.0  # 首领追击速度（像素/秒）：巡逻仍用鱼种表 sudu
const BOOS_TING_LIU_SHI_CHANG := 2.0  # 到巡逻点后停留几秒
const BOOS_DAO_DIAN_BAN_JING := 80.0  # 离巡逻点多近算“到点”
const FAN_MIAN_SI_QU := 20.0  # 翻面死区（像素）：横向差小于它就不转头，防止正上方追人时疯狂摆头
const BOOS_TUI_SU_DU := 140.0  # 首领推开 NPC 的速度（像素/秒）：重叠时把小鱼顶开，不让它们卡进鲸鲨身体
const BOOS_YAO_JI_JI_CHU := 55.0  # 首领咬击判定的基础半径：与玩家 YaoQu 同值，乘体型→像素曲线用
const TE_XIAO := preload("res://scripts/te_xiao.gd")  # 放电/中毒的一次性特效生成器
const ROU_KUAI_CHANGJING := preload("res://scenes/RouKuai.tscn")  # 鱼肉块蓝图：撕裂齿咬掉肉用
const MEI_KUAI_ROU_TI_XING := 0.5  # 每块鱼肉默认携带的体型量（撕裂齿不传量时的兜底）
const TUN_SHI_JIAN_GE := 0.3  # 首领吞食检查间隔（秒）：与思考间隔同量级，不逐帧扫组
const SHENG_JI_BIAO := preload("res://data/shengji/sheng_ji_biao.tres")  # 升级曲线参数：与玩家同表，改表两边同步

enum ZhuangTai { YOU_DANG, ZHUI_ZHU, TAO_PAO }  # 巡游 / 追击 / 逃跑

signal bei_ji_bai  # 首领被咬到残血：Main 据此触发「提前开战」奖励（普通鱼永不发）

var yu_zhong: YuZhong  # 鱼种数据（生成器在 add_child 前注入；_ready 里读它）
var _neng_li: NengLi = null  # 鱼种能力（只读引用）：电鳗放电/蓑鲉反毒都从这里查数值
var tixing := 1.0  # 体型=当前血量：被咬会变小，被吃归零
var deng_ji_nei := 1  # 隐藏等级（经验曲线索引，只涨不降）：被咬掉 tixing 不倒扣经验进度
var jing_yan_nei := 0  # 隐藏经验条：玩家看不见；吃东西涨，涨满升级=体型 +1（v0.4 生态三件套）
var sudu := 100.0  # 游速（像素/秒），由生成器写入
var fangxiang := -1.0  # 1 向右，-1 向左，由生成器写入
var bei_xi: Yu = null  # 吸附目标（玩家 ChiQu 打的标记）：非空 = 被吸中，朝它游
var ai_kai_qi := true  # 状态机总闸：测试夹具关掉它，鱼就只直线巡游
var gan_zhi := 260.0  # 感知半径（像素），数据表可调
var fan_ying_shi_jian := 0.8  # 反应时间（秒）：被偷袭身体后要懵多久才转头（鱼种表 fan_ying_shi_jian）
var gong_ji_yu_wang := true  # 攻击欲望：路人鱼 false，只在被咬时逃跑
var zui_ba := 1.0  # 嘴巴系数（鱼种表 zui_ba）：咬击伤害的倍率，决定“咬小大鱼”的快慢
var zhuang_tai := ZhuangTai.YOU_DANG  # 当前状态（调试/测试可读）
var si_le := false  # 已被吃掉（queue_free 前先立旗）：防止同一帧被重复咬/重复吞
var dian_ma := 0.0  # 电麻条（0~100）：被电鳗电到会涨，满了失控
var du_yun := 0.0   # 毒晕条（0~100）：被蓑鲉毒到会涨，满了失控
var shi_boss := false  # 首领：不参与普通鱼群刷新；不逃跑，被咬到残血才算击败（TASK-017）
var xun_luo_dian: Array[Vector2] = []  # 首领巡逻点（世界坐标）：Main 注入 4 个，循环游荡

var _hong_guang: AnimatedSprite2D  # 红光层：玩家吃得下我时亮，提示“这个是猎物”
var _wan_jia: Yu = null  # 玩家（靠 player 组找）：没有玩家（测试场景）就不亮
var _guang_shi_jian := 0.0  # 红光呼吸相位（秒）
var _si_kao_ji_shi := 0.0  # 距离下次思考的累计时间
var _yao_ji_leng_que := 0.0  # 咬击冷却剩余
var _tao_pao_ji_shi := 0.0  # 逃跑剩余时间
var _tao_pao_lai_yuan = null  # 逃跑时背离的那个家伙
var _mu_biao = null  # 当前目标（YuNpc 或 Yu）
var _chou_hen = null  # 仇人：谁咬过我（复仇优先）
var _fan_ying_ji_shi := 0.0  # 反应延迟剩余（秒）：>0 时不记仇、不转头
var _dai_chou_hen = null  # 反应延迟结束后才记账的偷袭者
var _yan_se_tween: Tween
var _yun_xuan_ji_shi := 0.0  # 失控剩余时间（秒）：>0 时不动、不咬、不吃
var _kong_zhi_shi_jian := 0.0  # 失控累计时间（驱动抽搐表现）
var _dian_ji_ji_shi := 0.0  # 电鳗放电倒计时
var _neng_li_leng_que := 0.0  # 能力冷却（旗鱼突进/金枪鱼洞察/巨口鱼潜伏共用）
var _ruo_dian_sheng_yu := 0.0  # 弱点洞察剩余（秒）：NPC 金枪鱼咬玩家时加伤
var _ruo_dian_bei_lv := 1.0  # 弱点洞察加伤倍率（起手时按能力表读）
var _deng_ji_sheng_yu := 0.0  # 等级数字标记剩余（秒）：玩家看穿这条鱼
var _deng_ji_biao: Label = null  # 等级数字标记（懒创建：被锁定时才 new）
var _tu_jin_sheng_yu := 0.0  # 旗鱼突进剩余（秒）
var _tu_jin_fang := Vector2.ZERO  # 突进锁定方向
var _chong_zhuang_sheng_yu := 0.0  # 冲撞剩余（秒）：剑鱼穿刺/通用蛮力冲撞共用
var _chong_zhuang_fang := Vector2.ZERO  # 冲撞锁定方向
var _chong_zhuang_ming_zhong := {}  # 冲撞去重：instance_id -> true
var _yin_shen_sheng_yu := 0.0  # 巨口鱼潜伏剩余（秒）
var _qian_fu_zhun_bei := false  # 潜伏下一口 ×2 已就绪
var _boos_sheng_ji_ji_shi := 0.0  # 首领升级计时（秒）
var _boos_zhu_ji_ji_shi := 0.0  # 首领追击剩余时间（秒）
var _boos_leng_que_ji_shi := 0.0  # 首领追击冷却（秒）
var _xun_luo_suo_yin := 0  # 当前巡逻目标下标
var _xun_luo_ting_liu := 0.0  # 在巡逻点停留剩余（秒）
var _gao_liang_sheng_yu := 0.0  # 声呐/猎手直觉高亮剩余（秒）：泛黄显示，纯表现
var _tun_shi_ji_shi := 0.0  # 首领吞食检查节流计时（秒）
var _gong_ci := 0  # 咬击动画代次：连咬时旧协程回来不把新动画切掉
var _zai_gong_ji := false  # 咬击动画播放中：红光让位，避免两层帧错位

@onready var rou_qu: Area2D = $RouQu  # 鱼肉区：NPC 也能吃鱼肉（策划案 8.1「任何鱼可进食」）


func _ready() -> void:
	# 体型直接取鱼种等级：同种鱼不再随机大小，玩家一眼能判断吃不吃得下
	tixing = float(yu_zhong.dengji) if yu_zhong != null else 1.0
	deng_ji_nei = yu_zhong.dengji if yu_zhong != null else 1  # 隐藏等级从鱼种等级起跳
	if yu_zhong != null:
		gan_zhi = yu_zhong.gan_zhi
		fan_ying_shi_jian = yu_zhong.fan_ying_shi_jian
		gong_ji_yu_wang = yu_zhong.gong_ji_yu_wang
		zui_ba = yu_zhong.zui_ba
		shi_boss = yu_zhong.shi_boss
		_neng_li = yu_zhong.neng_li
	scale = Vector2.ONE * ZhangBen.ti_xing_dao_chi_du(tixing)  # 与玩家共用同一条体型→像素曲线
	var ti: AnimatedSprite2D = $AnimatedSprite2D
	if yu_zhong != null and yu_zhong.dong_hua != null:
		ti.sprite_frames = yu_zhong.dong_hua  # 4 帧游动动画：鱼种定什么就长什么样
	elif yu_zhong != null and yu_zhong.tie_tu != null:
		ti.sprite_frames = _dan_zhen_dong_hua(yu_zhong.tie_tu)  # 兜底：只有静态图的老数据也能显示
	if ti.sprite_frames != null and ti.sprite_frames.has_animation(&"you"):
		ti.play(&"you")  # 裸鱼（测试夹具没注入鱼种）没有帧资源：不播，避免 "you" 不存在报错
	ti.flip_h = fangxiang < 0.0  # 贴图默认朝右，向左游时翻转
	_geng_xin_bu_wei()  # 部位点跟着朝向翻：嘴永远在脸那一侧
	_hong_guang = $HongGuang
	_hong_guang.sprite_frames = ti.sprite_frames  # 与本体同一套帧：不另做美术资源
	if _hong_guang.sprite_frames != null and _hong_guang.sprite_frames.has_animation(&"you"):
		_hong_guang.play(&"you")
	_hong_guang.scale = Vector2.ONE * HONG_GUANG_FANG_DA
	$BossPengZhuangQu.monitoring = shi_boss  # 推挤层只开在首领身上：普通鱼不用每帧扫身边
	var cai: CanvasItemMaterial = CanvasItemMaterial.new()
	cai.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD  # 叠加发光：比半透明盖一层更像“光”
	_hong_guang.material = cai
	_hong_guang.visible = false
	add_to_group("yu_npc")  # 同类互相索敌、互相吃：状态机靠这个组扫附近
	# 电鳗错峰放电：一群鱼不会同一帧全开火；间隔读能力表（npc_jian_ge），改表零代码
	if _neng_li != null and _neng_li.bian_hao == &"fang_dian_ma_bi":
		_dian_ji_ji_shi = randf_range(0.0, _neng_li.npc_jian_ge if _neng_li.npc_jian_ge > 0.0 else DIAN_JI_JIAN_GE)


func _dan_zhen_dong_hua(tie: Texture2D) -> SpriteFrames:
	# 兜底：把一张静态图包成单帧 SpriteFrames，保证 AnimatedSprite2D 一定有 "you" 可播
	var kuang := SpriteFrames.new()
	kuang.add_animation(&"you")
	kuang.set_animation_speed(&"you", 1.0)
	kuang.set_animation_loop(&"you", true)
	kuang.add_frame(&"you", tie)
	return kuang


func _process(delta: float) -> void:
	if not is_inside_tree():
		return  # 场景切换时旧场景节点可能还会被 processing 一帧：不在树里不读视口
	_yao_ji_leng_que = maxf(0.0, _yao_ji_leng_que - delta)
	_zou_kong_zhi(delta)  # 控制条消退 / 失控倒数
	_geng_xin_neng_li(delta)  # 能力冷却/突进/冲撞/潜伏倒数
	if shi_boss:
		zou_boos_sheng_ji(delta)  # 首领随时间成长：就算被电麻/毒晕也照长
	else:
		_zou_fan_ying(delta)  # 普通鱼：反应延迟读秒（时间到了才记仇/逃跑）
	if zai_kong_zhi():
		_kong_zhi_zhong(delta)
		_geng_xin_bu_wei()
		_geng_xin_hong_guang(delta)  # 失控时照样亮红光：玩家可以放心去吃
		return
	$AnimatedSprite2D.modulate = Color.WHITE  # 失控结束：恢复本色
	if _yin_shen_sheng_yu > 0.0:
		$AnimatedSprite2D.modulate.a = 0.45  # 巨口鱼潜伏：半透明
	if _gao_liang_sheng_yu > 0.0:
		$AnimatedSprite2D.modulate = Color(1.0, 0.92, 0.45)  # 声呐/猎手直觉标记：泛黄一瞬
	$AnimatedSprite2D.rotation = 0.0
	_fang_dian(delta)  # 电鳗：醒着才放电（被动能力）
	if bei_xi != null:
		# 被吸中：朝玩家游（吸力略快于自身游速）；路自己走（设计决策 1A：NPC 自决）
		var cha_xi: Vector2 = bei_xi.global_position - position
		position = position.move_toward(bei_xi.global_position, sudu * 1.2 * delta)
		_chao_xiang(cha_xi)
	elif not ai_kai_qi:
		_you_dang(delta)  # 测试/演示用：关 AI 就是一条直线巡游的鱼
	elif shi_boss:
		_boos_xing_dong(delta)  # 首领：平时 4 处巡逻，看见玩家追 8 秒
	elif _tu_jin_sheng_yu > 0.0:
		_tu_jin(delta)  # 旗鱼突进：直线冲刺，够近就咬
	elif _chong_zhuang_sheng_yu > 0.0:
		_chong_zhuang_npc(delta)  # 直线冲撞（剑鱼穿刺/蛮力冲撞共用）：每目标一次伤害
	else:
		_si_kao_ji_shi += delta
		if _si_kao_ji_shi >= SI_KAO_JIAN_GE:
			_si_kao_ji_shi = 0.0
			_si_kao()  # 想：选目标
		_xing_dong(delta)  # 动：追、咬、吞、逃
	_geng_xin_bu_wei()  # 朝向可能变了：把嘴/致命点挪到脸侧（咬击取点要用）
	if shi_boss:
		_tui_kai_zhou_wei(delta)  # 首领推挤：把挡路的 NPC 顶开（BossPengZhuangQu）
	# 以相机可视矩形为边界：相机走到哪，鱼群就在哪一屏生成/回收
	# 首领例外：它要满地图巡逻，不能被“出屏回收”删掉
	var fan_wei := _shi_jiao_fan_wei()
	if not shi_boss and (position.x < fan_wei.position.x - SHOU_HUI_YU_LIANG or position.x > fan_wei.end.x + SHOU_HUI_YU_LIANG):
		queue_free()  # 游出当前镜头：释放节点，避免越积越多
	_chi_rou()
	_geng_xin_hong_guang(delta)


func _si_kao() -> void:
	# 选目标：先看逃不逃，再按“复仇 > 最大的小鱼 > 玩家”挑猎物（策划案 8.5）
	# 反应延迟里：保持原目标/原路线——被偷袭的鱼还没意识到是谁咬的，不能立刻转头
	if _fan_ying_ji_shi > 0.0:
		return
	if _tao_pao_ji_shi > 0.0:
		_mu_biao = null
		zhuang_tai = ZhuangTai.TAO_PAO
		return
	# 诱饵优先于一切常规目标：气泡是主动技吐出来的“假猎物”，腐肉是咬出来的发光肉
	# 放在 gong_ji_yu_wang 之前：连不主动攻击的路人鱼也会被诱饵骗走
	var qi := _zhao_you_er_qi_pao()
	if qi != null:
		_mu_biao = qi
		zhuang_tai = ZhuangTai.ZHUI_ZHU
		return
	var fu_rou := _zhao_fu_rou_you_er()
	if fu_rou != null:
		_mu_biao = fu_rou
		zhuang_tai = ZhuangTai.ZHUI_ZHU
		return
	if not gong_ji_yu_wang:
		_mu_biao = null
		zhuang_tai = ZhuangTai.YOU_DANG
		return
	# ① 复仇：咬过我的家伙，只要还在感知的 1.5 倍范围内就去找它
	# 同类例外：不惹体型超过自己 2 倍的（小鱼围攻也啃不动鲸鲨）；玩家不设限——玩家可随意咬大鱼
	# 感知半径走 dang_qian_gan_zhi()：被淤泥雾罩住时复仇圈一起缩水
	if is_instance_valid(_chou_hen) \
			and not (_chou_hen is Yu and _chou_hen.yin_shen) \
			and (_chou_hen is Yu or float(_chou_hen.tixing) <= tixing * BU_RE_DA_BEI_LV) \
			and global_position.distance_to(_chou_hen.global_position) <= dang_qian_gan_zhi() * 1.5:
		_mu_biao = _chou_hen
		zhuang_tai = ZhuangTai.ZHUI_ZHU
		return
	# ② 感知范围内比自己小的鱼里，体型最大的那条（吃最划算的）
	var zui_da = null
	var zui_da_ti := -1.0
	for yu in _zhou_wei_yu():
		if yu.tixing >= tixing:
			continue
		if global_position.distance_to(yu.global_position) > dang_qian_gan_zhi():
			continue
		if yu.tixing > zui_da_ti:
			zui_da_ti = yu.tixing
			zui_da = yu
	if zui_da != null:
		_mu_biao = zui_da
		zhuang_tai = ZhuangTai.ZHUI_ZHU
		return
	# ③ 玩家：没有体型门槛——小鱼也敢咬大玩家（小挑战）；追不追得到是另一回事
	# 潜伏中的玩家看不见：不索敌（只影响感知，不影响玩家主动咬它）
	# 看玩家用 _wan_jia_gan_zhi()：淤泥隐匿（档3）与隐匿气息被动都在这里打折
	# 电感受器：一锁定玩家就通知一声——装了被动的玩家头顶亮"!"
	var wan := _zhao_wan_jia()
	if is_instance_valid(wan) and not wan.yin_shen and global_position.distance_to(wan.global_position) <= _wan_jia_gan_zhi():
		_mu_biao = wan
		zhuang_tai = ZhuangTai.ZHUI_ZHU
		wan.shi_fang_yu_jing()
		return
	_mu_biao = null
	zhuang_tai = ZhuangTai.YOU_DANG


func _xing_dong(delta: float) -> void:
	if _tao_pao_ji_shi > 0.0:
		_tao_pao_ji_shi = maxf(0.0, _tao_pao_ji_shi - delta)
		_tao_pao(delta)
		return
	# 潜伏中的玩家追丢了：放弃目标，回到巡游（破隐后会重新索敌）
	if is_instance_valid(_mu_biao) and _mu_biao is Yu and _mu_biao.yin_shen:
		_mu_biao = null
	if not is_instance_valid(_mu_biao):
		_you_dang(delta)
		return
	# 诱饵气泡：游到嘴边就咬破；被咬破由气泡自己播特效（满档会炸晕咬它的鱼）
	if _mu_biao is YouErQiPao:
		var qi := _mu_biao as YouErQiPao
		var cha_qi: Vector2 = qi.global_position - global_position
		if cha_qi.length() <= _yao_ji_ju_li():
			qi.bei_yao(self)
			_mu_biao = null
			zhuang_tai = ZhuangTai.YOU_DANG
			return
		_xiang(cha_qi.normalized(), delta)
		return
	# 腐肉诱饵：游到发光的肉旁边直接吃掉，涨隐藏经验（和路过吃同一套账）
	if _mu_biao is RouKuai:
		var rou := _mu_biao as RouKuai
		var cha_rou: Vector2 = rou.global_position - global_position
		if cha_rou.length() <= _yao_ji_ju_li() and rou.ke_chi:
			jia_jing_yan_nei(rou.jing_yan)
			rou.bei_chi()
			_mu_biao = null
			zhuang_tai = ZhuangTai.YOU_DANG
			return
		_xiang(cha_rou.normalized(), delta)
		return
	if _chang_shi_neng_li():
		return  # 旗鱼突进 / 剑鱼穿刺：本帧启动位移，交给专用分支
	var cha: Vector2 = _mu_biao.global_position - global_position
	var ju_li := cha.length()
	# 玩家永远不整吞：玩家是体验核心，只吃咬击的消耗（策划案 8.6.3）
	if _mu_biao is Yu:
		if ju_li <= _yao_ji_ju_li():
			_yao(_mu_biao)
		_xiang(cha.normalized(), delta)
		return
	# 够大又够近：整吞
	if ju_li <= _chi_yu_ju_li(_mu_biao) and tixing >= float(_mu_biao.tixing) * CHI_YU_BEI_LV:
		_tun_diao(_mu_biao)
		return
	# 到了咬击距离：先咬一口（没有资格门槛），再继续靠近
	if ju_li <= _yao_ji_ju_li():
		_yao(_mu_biao)
	_xiang(cha.normalized(), delta)


func _chang_shi_neng_li() -> bool:
	# 普通鱼能力起手：旗鱼突进/剑鱼穿刺返回 true（本帧不再走常规移动）
	# 金枪鱼洞察返回 false：只挂加伤，移动仍走常规追击
	# 巨口鱼潜伏返回 false：隐身之后继续正常追击，下一口才爆发
	if _neng_li == null or _neng_li_leng_que > 0.0:
		return false
	if not is_instance_valid(_mu_biao):
		return false
	var ju := global_position.distance_to(_mu_biao.global_position)
	match _neng_li.bian_hao:
		&"ji_su_tu_jin":
			if ju > _yao_ji_ju_li() and ju <= _neng_li.ban_jing:
				_qi_dong_tu_jin()
				return true
		&"man_li_chong_zhuang":
			if ju <= _neng_li.ban_jing:
				_qi_dong_chong_zhuang()
				return true
		&"chang_mao_chuan_ci":
			if ju <= _neng_li.ban_jing:
				_qi_dong_chong_zhuang()  # 剑鱼穿刺与蛮力冲撞同构：直线冲 + 路径穿透；数值各看各的表
				return true
		&"qian_fu_tu_xi":
			if ju > _yao_ji_ju_li() and ju <= dang_qian_gan_zhi() and _yin_shen_sheng_yu <= 0.0:
				_qi_dong_yin_shen_npc()
		&"ruo_dian_dong_cha":
			# 弱点洞察：看见目标就锁定，接下来几秒咬它更痛；不改变移动，继续正常追击
			if ju <= _neng_li.ban_jing and _ruo_dian_sheng_yu <= 0.0:
				_ruo_dian_sheng_yu = maxf(0.01, _neng_li.chi_xu)
				_ruo_dian_bei_lv = maxf(1.0, _neng_li.npc_zhi())
				_neng_li_leng_que = _neng_li.npc_jian_ge if _neng_li.npc_jian_ge > 0.0 else 12.0
	return false


func _qi_dong_tu_jin() -> void:
	# 旗鱼突进：锁定目标方向，0.8 秒内以 2 倍速冲过去；冷却读能力表
	_neng_li_leng_que = _neng_li.npc_jian_ge if _neng_li.npc_jian_ge > 0.0 else 6.0
	_tu_jin_sheng_yu = maxf(0.01, _neng_li.chi_xu)
	_tu_jin_fang = (_mu_biao.global_position - global_position).normalized()
	if _tu_jin_fang == Vector2.ZERO:
		_tu_jin_fang = Vector2.RIGHT.rotated(rotation)
	_chao_xiang(_tu_jin_fang * 100.0)


func _tu_jin(delta: float) -> void:
	# 突进分支：直线位移，够近就咬（伤害仍走 _yao 的常规公式）
	if is_instance_valid(_mu_biao) and _mu_biao is Yu and _mu_biao.yin_shen:
		_tu_jin_sheng_yu = 0.0  # 目标潜伏：突进落空，回巡逻
		_mu_biao = null
		return
	position += _tu_jin_fang * sudu * maxf(1.0, _neng_li.shu_zhi) * delta
	_chao_xiang(_tu_jin_fang * 100.0)
	if is_instance_valid(_mu_biao) \
			and global_position.distance_to(_mu_biao.global_position) <= _yao_ji_ju_li():
		_yao(_mu_biao)


func _qi_dong_chong_zhuang() -> void:
	# 蛮力冲撞 / 剑鱼穿刺：锁定方向，以 fu_shu_zhi 倍速直线冲；每目标只结算一次，不整吞
	_neng_li_leng_que = _neng_li.npc_jian_ge if _neng_li.npc_jian_ge > 0.0 else 7.0
	_chong_zhuang_sheng_yu = maxf(0.01, _neng_li.chi_xu)
	_chong_zhuang_fang = (_mu_biao.global_position - global_position).normalized()
	if _chong_zhuang_fang == Vector2.ZERO:
		_chong_zhuang_fang = Vector2.RIGHT.rotated(rotation)
	_chong_zhuang_ming_zhong.clear()
	_chao_xiang(_chong_zhuang_fang * 100.0)


func _chong_zhuang_npc(delta: float) -> void:
	# 冲撞分支：直线位移 + 距离命中；伤害 ×shu_zhi，调同一套 shou_dao_yao_ji
	if is_instance_valid(_mu_biao) and _mu_biao is Yu and _mu_biao.yin_shen:
		_chong_zhuang_sheng_yu = 0.0  # 目标潜伏：冲撞落空
		_mu_biao = null
		return
	position += _chong_zhuang_fang * sudu * maxf(1.0, _neng_li.fu_shu_zhi) * delta
	_chao_xiang(_chong_zhuang_fang * 100.0)
	var shang_hai := ZhanDou.yao_ji_shang_hai(tixing, zui_ba) * _neng_li.shu_zhi
	var mu_biao_men: Array = _zhou_wei_yu()
	var wan := _zhao_wan_jia()
	if is_instance_valid(wan) and not wan.yin_shen:
		mu_biao_men.append(wan)
	for mu in mu_biao_men:
		if mu == null or not is_instance_valid(mu) or mu.get("si_le") == true:
			continue
		if global_position.distance_to(mu.global_position) > _yao_ji_ju_li():
			continue
		var jian: int = mu.get_instance_id()
		if _chong_zhuang_ming_zhong.has(jian):
			continue
		_chong_zhuang_ming_zhong[jian] = true
		mu.call("shou_dao_yao_ji", shang_hai, self, "shen")


func _qi_dong_yin_shen_npc() -> void:
	# 巨口鱼潜伏：隐身 2 秒 + 下一口 ×2；冷却读表（8 秒）
	_neng_li_leng_que = _neng_li.npc_jian_ge if _neng_li.npc_jian_ge > 0.0 else 8.0
	_yin_shen_sheng_yu = maxf(0.01, _neng_li.chi_xu)
	_qian_fu_zhun_bei = true
	$AnimatedSprite2D.modulate.a = 0.45


func _jie_chu_yin_shen_npc() -> void:
	# NPC 破隐：咬中/受击/失控/到期都走这里
	if _yin_shen_sheng_yu <= 0.0 and not _qian_fu_zhun_bei:
		return
	_yin_shen_sheng_yu = 0.0
	_qian_fu_zhun_bei = false
	$AnimatedSprite2D.modulate.a = 1.0


func _geng_xin_neng_li(delta: float) -> void:
	# 能力时钟：冷却与三种持续效果一起倒数
	_neng_li_leng_que = maxf(0.0, _neng_li_leng_que - delta)
	_gao_liang_sheng_yu = maxf(0.0, _gao_liang_sheng_yu - delta)  # 声呐/猎手直觉标记到点熄灭
	if _tu_jin_sheng_yu > 0.0:
		_tu_jin_sheng_yu = maxf(0.0, _tu_jin_sheng_yu - delta)
	if _chong_zhuang_sheng_yu > 0.0:
		_chong_zhuang_sheng_yu = maxf(0.0, _chong_zhuang_sheng_yu - delta)
		if _chong_zhuang_sheng_yu <= 0.0:
			_chong_zhuang_ming_zhong.clear()
	if _yin_shen_sheng_yu > 0.0:
		_yin_shen_sheng_yu = maxf(0.0, _yin_shen_sheng_yu - delta)
		if _yin_shen_sheng_yu <= 0.0:
			_jie_chu_yin_shen_npc()
	if _ruo_dian_sheng_yu > 0.0:
		_ruo_dian_sheng_yu = maxf(0.0, _ruo_dian_sheng_yu - delta)
		if _ruo_dian_sheng_yu <= 0.0:
			_ruo_dian_bei_lv = 1.0
	if _deng_ji_sheng_yu > 0.0:
		# 玩家看穿的等级数字：到期关掉；期间每帧刷新——目标被咬小后数字跟着变
		_deng_ji_sheng_yu = maxf(0.0, _deng_ji_sheng_yu - delta)
		if _deng_ji_biao != null and _deng_ji_biao.visible:
			_deng_ji_biao.text = "Lv.%d" % int(tixing)
		if _deng_ji_sheng_yu <= 0.0 and _deng_ji_biao != null:
			_deng_ji_biao.visible = false


func _tun_diao(mu) -> void:
	# 吃 NPC 记隐藏经验（先记账再吞：经验取被吞方的鱼种分值）
	if mu is YuNpc and mu.yu_zhong != null:
		jia_jing_yan_nei(int(mu.yu_zhong.fenzhi))
	mu.bei_chi(false, self)  # NPC 吃 NPC：不给玩家记经验（玩家没参与）；毒鱼照样毒到吃它的鱼
	_mu_biao = null
	zhuang_tai = ZhuangTai.YOU_DANG


func dang_qian_gan_zhi() -> float:
	# 有效感知半径：本体感知 × 淤泥雾系数（站在雾里就瞎）——索敌/起手/复仇圈都读这一处
	var xi_shu := 1.0
	for wu in get_tree().get_nodes_in_group("yu_ni_wu"):
		var yu_ni_wu := wu as YuNiWu
		if yu_ni_wu != null \
				and global_position.distance_to(yu_ni_wu.global_position) <= yu_ni_wu.ban_jing:
			xi_shu *= yu_ni_wu.gan_zhi_xi_shu
	return gan_zhi * xi_shu


func _wan_jia_gan_zhi() -> float:
	# 专门用来看玩家的感知半径：有效感知 × 雾中玩家隐匿（淤泥档3）× 隐匿气息被动
	var gan := dang_qian_gan_zhi()
	for wu in get_tree().get_nodes_in_group("yu_ni_wu"):
		var yu_ni_wu := wu as YuNiWu
		if yu_ni_wu != null and yu_ni_wu.wan_jia_yin_bi > 0.0 \
				and global_position.distance_to(yu_ni_wu.global_position) <= yu_ni_wu.ban_jing:
			gan *= yu_ni_wu.wan_jia_yin_bi
	return gan * ZhangBen.wan_jia_yin_bi_xi_shu()


func ding_zhu(shi_chang: float) -> void:
	# 被定身（声呐档3 / 被漩涡卷住）：拉长反应延迟——延迟里不索敌、不记仇、按原路线游
	# 复用 _fan_ying_ji_shi 通道：不新增状态，计时走完自然恢复（首领不读它，定不住是预期）
	if si_le or not is_inside_tree():
		return
	_fan_ying_ji_shi = maxf(_fan_ying_ji_shi, shi_chang)


func shi_fang_gao_liang(shi_chang: float) -> void:
	# 被声呐/猎手直觉标记：本体泛黄一小会儿（纯表现：告诉玩家“这条鱼在感知里”）
	if si_le:
		return
	_gao_liang_sheng_yu = maxf(_gao_liang_sheng_yu, shi_chang)


func diao_rou(shu: int, mei_kuai_ti_xing := MEI_KUAI_ROU_TI_XING,
		fu_rou_sheng_yu := 0.0, xi_yin_ban_jing := 0.0) -> void:
	# 被玩家的撕裂齿咬掉肉：往四周随机方向弹出去（镜像玩家版 diao_rou；NPC 互咬不掉肉）
	# fu_rou_sheng_yu/xi_yin_ban_jing 只给「腐肉诱饵」用：>0 时这块肉会发光并吸引附近的鱼
	if si_le:
		return
	for i in range(shu):
		var rou: RouKuai = ROU_KUAI_CHANGJING.instantiate()
		rou.ti_xing_liang = mei_kuai_ti_xing  # 每块肉携带的体型量：玩家吃回来时 ÷1.5
		rou.fu_rou_you_er_sheng_yu = fu_rou_sheng_yu
		rou.xi_yin_ban_jing = xi_yin_ban_jing
		var jiao := randf_range(0.0, TAU)
		rou.position = position + Vector2(cos(jiao), sin(jiao)) * randf_range(46.0, 58.0)
		rou.position.x = clampf(rou.position.x, 40.0, Yu.DI_TU_DA_XIAO.x - 40.0)
		rou.position.y = clampf(rou.position.y, 40.0, Yu.DI_TU_DA_XIAO.y - 40.0)
		# 咬击信号可能来自物理帧：直接 add_child(Area2D) 会报状态错误，必须推迟到空闲帧
		if Engine.is_in_physics_frame():
			get_parent().add_child.call_deferred(rou)
		else:
			get_parent().add_child(rou)


func _yao(mu) -> void:
	if _yao_ji_leng_que > 0.0:
		return
	_yao_ji_leng_que = YAO_JI_LENG_QUE
	_bo_gong_ji()  # 咬中同帧播 4 帧咬击动画：有素材的鱼种才播，没有就沿用游动帧
	var shang_hai := ZhanDou.yao_ji_shang_hai(tixing, zui_ba)
	if _qian_fu_zhun_bei:
		shang_hai *= _neng_li.shu_zhi  # 巨口鱼潜伏：下一口 ×2
		_jie_chu_yin_shen_npc()
	if _ruo_dian_sheng_yu > 0.0:
		shang_hai *= _ruo_dian_bei_lv  # 弱点洞察：锁定期间咬得更痛
	# 传来源：玩家毒棘护体 / NPC 蓑鲉反毒都靠它判断“谁咬了我”
	if mu is Yu:
		YinXiang.fang(&"yao", -4.0)  # 咬到玩家才出声：NPC 互咬一屏会太吵
	mu.shou_dao_yao_ji(shang_hai, self)


func _bo_gong_ji() -> void:
	# 咬击动画：临时把本体 SpriteFrames 换成 gong 四帧，播完切回 you
	# 攻击帧只有 0.4 秒（4 帧 @10fps）；用代次 _gong_ci 防止连咬时旧计时器把新动画打断
	if yu_zhong == null or yu_zhong.gong_ji_dong_hua == null:
		return
	var ti: AnimatedSprite2D = $AnimatedSprite2D
	_gong_ci += 1
	var ci := _gong_ci
	_zai_gong_ji = true
	ti.sprite_frames = yu_zhong.gong_ji_dong_hua
	ti.play(&"gong")
	if _hong_guang != null:
		_hong_guang.visible = false
	await get_tree().create_timer(0.4).timeout
	if not is_instance_valid(self) or ci != _gong_ci:
		return
	_zai_gong_ji = false
	if yu_zhong != null and yu_zhong.dong_hua != null:
		ti.sprite_frames = yu_zhong.dong_hua
		ti.play(&"you")


func xian_shi_deng_ji(shi_chang: float) -> void:
	# 弱点洞察：头顶亮出等级数字（纯表现，不参与判定）
	_deng_ji_sheng_yu = maxf(_deng_ji_sheng_yu, shi_chang)
	if _deng_ji_biao == null:
		_deng_ji_biao = Label.new()
		_deng_ji_biao.position = Vector2(-26.0, -124.0)
		_deng_ji_biao.add_theme_font_size_override("font_size", 24)
		_deng_ji_biao.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		add_child(_deng_ji_biao)
	_deng_ji_biao.text = "Lv.%d" % int(tixing)
	_deng_ji_biao.visible = true


func _xiang(fang: Vector2, delta: float) -> void:
	# 朝目标直线游；带 0.05 死区，纯上下追时不会反复转头
	if fang == Vector2.ZERO:
		return
	position += fang * sudu * ZHUI_GAN_JIA_SU * delta
	if absf(fang.x) > 0.05:
		$AnimatedSprite2D.flip_h = fang.x < 0.0


func _you_dang(delta: float) -> void:
	position.x += fangxiang * sudu * delta
	$AnimatedSprite2D.flip_h = fangxiang < 0.0  # 贴图默认朝右，向左游时翻转


func jia_jing_yan_nei(fen: int) -> void:
	# NPC 隐藏经验条（v0.4）：吃东西涨经验，涨满升级 = 体型 +1（视觉变大，顺带回 1 点血——
	# 单值模型下「变大」与「不回血」不可兼得，拍板取变大：大鱼变强即压迫感）
	# deng_ji_nei 只涨不降：被咬掉 tixing 不倒扣经验进度（隐藏成长永不回退）
	if fen <= 0:
		return
	jing_yan_nei += fen
	while jing_yan_nei >= _sheng_ji_yu_zhi():  # while：鲸鲨一口吞一群可能连升
		jing_yan_nei -= _sheng_ji_yu_zhi()
		deng_ji_nei += 1
		tixing += 1.0
		_ying_she_ti_xing()


func _sheng_ji_yu_zhi() -> int:
	# 升级阈值：读与玩家同一张 sheng_ji_biao.tres（10 × 1.2^等级），按自己的隐藏等级算。
	# 不调 ZhangBen.dangqian_yuzhi()——账本曲线读玩家的 deng_ji 且有状态，NPC 借它会污染玩家账本
	return ceili(SHENG_JI_BIAO.ji_chu * pow(SHENG_JI_BIAO.zeng_zhang, maxi(deng_ji_nei, 0)))


func zou_boos_sheng_ji(delta: float) -> void:
	# 首领随时间升级：每 BOOS_SHENG_JI_JIAN_GE 秒，体型 +BOOS_MEI_CI_JIA_DENG_JI
	# 体型=血量：升级同时回血——越拖越硬，逼玩家早点去祭坛挑战（用户可调上面两个常量）
	if not shi_boss:
		return
	_boos_sheng_ji_ji_shi += delta
	while _boos_sheng_ji_ji_shi >= BOOS_SHENG_JI_JIAN_GE:
		_boos_sheng_ji_ji_shi -= BOOS_SHENG_JI_JIAN_GE
		tixing += BOOS_MEI_CI_JIA_DENG_JI
		_ying_she_ti_xing()


func _tui_kai_zhou_wei(delta: float) -> void:
	# 首领推挤层：BossPengZhuangQu 只开在首领身上，把重叠的 NPC 沿远离方向挤出去
	# NPC 是纯 Node2D、没有物理刚体——这里直接改对方位置，效果等价于“被大鲸鲨顶开”
	for qu in $BossPengZhuangQu.get_overlapping_areas():
		var yu := qu.get_parent() as YuNpc
		if yu == null or yu == self or yu.si_le:
			continue
		var cha := yu.global_position - global_position
		if cha.length_squared() < 0.001:
			cha = Vector2.RIGHT.rotated(randf() * TAU)  # 完全重叠：随机方向挤开，避免除零
		yu.tui_kai(cha.normalized(), BOOS_TUI_SU_DU * delta)


func tui_kai(fang: Vector2, ju_li: float) -> void:
	# 被首领顶开：位移一小段；不打断 AI，鱼会继续按自己的目标游
	if si_le or not is_inside_tree():
		return
	position += fang * ju_li


func _tun_shen_bian_yu(delta: float) -> void:
	# 首领同食（v0.4）：巨口吞入不分玩家与 NPC——巡游/追击路上碰到吃得下的小鱼照吞。
	# 节流 0.3 秒查一次（组扫描 O(n)，不逐帧扫）；吞不掉的交给推挤层顶开，两不误。
	# 失控中不吞（电麻/毒晕的鲸鲨嘴张不开）：_process 的失控分支提前 return，走不到这里
	_tun_shi_ji_shi += delta
	if _tun_shi_ji_shi < TUN_SHI_JIAN_GE:
		return
	_tun_shi_ji_shi = 0.0
	for mu in _zhou_wei_yu():
		if mu.si_le:
			continue
		if global_position.distance_to(mu.global_position) > _chi_yu_ju_li(mu):
			continue
		if tixing < float(mu.tixing) * CHI_YU_BEI_LV:
			continue  # 吞不动的大鱼：留给推挤层顶开
		_tun_diao(mu)  # 吃 NPC 管道现成：隐藏经验自动挂上


func _boos_xing_dong(delta: float) -> void:
	# 首领两态：看见玩家 → 优先追 8 秒；平时在 4 个巡逻点之间游荡
	# 同食两态都吃（策划案：巡游路上碰到的小鱼照吞不误）
	_tun_shen_bian_yu(delta)
	var wan := _zhao_wan_jia()
	if is_instance_valid(wan) and wan.yin_shen:
		# 潜伏中的玩家：首领也看不见——立刻放弃追击回巡逻（潜伏是首领战的脱战手段）
		_boos_zhu_ji_ji_shi = 0.0
		wan = null
	if _boos_zhu_ji_ji_shi <= 0.0 and _boos_leng_que_ji_shi <= 0.0 and wan != null \
			and global_position.distance_to(wan.global_position) <= _wan_jia_gan_zhi():
		_boos_zhu_ji_ji_shi = BOOS_ZHUI_JI_SHI_CHANG  # 看见玩家：开始 8 秒追击
		zhuang_tai = ZhuangTai.ZHUI_ZHU
	if _boos_zhu_ji_ji_shi > 0.0:
		_boos_zhu_ji_ji_shi = maxf(0.0, _boos_zhu_ji_ji_shi - delta)
		_boos_zhui_ji(wan, delta)
		if _boos_zhu_ji_ji_shi <= 0.0:
			_boos_leng_que_ji_shi = BOOS_ZHUI_JI_LENG_QUE  # 追累了：歇一会，给玩家脱战窗口
			zhuang_tai = ZhuangTai.YOU_DANG
		return
	_boos_leng_que_ji_shi = maxf(0.0, _boos_leng_que_ji_shi - delta)
	_boos_xun_luo(delta)


func _boos_zhui_ji(wan, delta: float) -> void:
	# 追玩家：直线压过去，够得着就咬（复用普通鱼的咬击入口，伤害按首领体型算）
	if wan == null or not is_instance_valid(wan):
		return
	var cha: Vector2 = wan.global_position - global_position
	if cha.length() > 1.0:
		position += cha.normalized() * BOOS_ZHUI_JI_SU_DU * delta
		_chao_xiang(cha)
	if global_position.distance_to(wan.global_position) <= _yao_ji_ju_li():
		_yao(wan)


func _boos_xun_luo(delta: float) -> void:
	# 巡逻：朝当前点游，到了停几秒，再换下一个点（循环）
	if xun_luo_dian.is_empty():
		_you_dang(delta)  # 没设巡逻点：退回普通直线巡游（测试/兜底）
		return
	if _xun_luo_ting_liu > 0.0:
		_xun_luo_ting_liu = maxf(0.0, _xun_luo_ting_liu - delta)
		return
	var mu_biao_dian: Vector2 = xun_luo_dian[_xun_luo_suo_yin]
	var cha := mu_biao_dian - global_position
	if cha.length() <= BOOS_DAO_DIAN_BAN_JING:
		_xun_luo_ting_liu = BOOS_TING_LIU_SHI_CHANG  # 到点：歇几秒再走
		_xun_luo_suo_yin = (_xun_luo_suo_yin + 1) % xun_luo_dian.size()
		return
	position += cha.normalized() * sudu * delta
	_chao_xiang(cha)


func _chao_xiang(cha: Vector2) -> void:
	# 翻面：横向差要够大才转头。目标在正上/正下方时保持原朝向——
	# 否则玩家站在头顶，x 的浮点抖动会每帧翻一次，看起来像“疯狂摆头”
	if absf(cha.x) > FAN_MIAN_SI_QU:
		$AnimatedSprite2D.flip_h = cha.x < 0.0


func _tao_pao(delta: float) -> void:
	if is_instance_valid(_tao_pao_lai_yuan):
		var fang: Vector2 = global_position - _tao_pao_lai_yuan.global_position
		if fang.length_squared() > 0.001:
			fang = fang.normalized()
			position += fang * sudu * 1.3 * delta
			if absf(fang.x) > 0.05:
				$AnimatedSprite2D.flip_h = fang.x < 0.0
	if _tao_pao_ji_shi <= 0.0:
		_tao_pao_lai_yuan = null
		zhuang_tai = ZhuangTai.YOU_DANG


func jia_dian_ma(liang: float) -> void:
	# 被电到：叠电麻条，满 → 失控（策划案 8.6.3）；失控中不再叠，免得无限晕
	if si_le or not is_inside_tree() or _yun_xuan_ji_shi > 0.0:
		return
	dian_ma = minf(ZhangBen.KONG_ZHI_SHANG_XIAN, dian_ma + liang)
	if dian_ma >= ZhangBen.KONG_ZHI_SHANG_XIAN:
		_chu_fa_yun_xuan()


func jia_du_yun(liang: float) -> void:
	# 被毒到：叠毒晕条，规则与电麻完全一致
	if si_le or not is_inside_tree() or _yun_xuan_ji_shi > 0.0:
		return
	du_yun = minf(ZhangBen.KONG_ZHI_SHANG_XIAN, du_yun + liang)
	if du_yun >= ZhangBen.KONG_ZHI_SHANG_XIAN:
		_chu_fa_yun_xuan()


func zai_kong_zhi() -> bool:
	# 失控判定：只认这一个状态，AI 与表现都读它
	return _yun_xuan_ji_shi > 0.0


func _chu_fa_yun_xuan() -> void:
	# 任一条满：两条一起清零 + 失控 2 秒；顺手放弃当前目标（醒来自会重新思考）
	_yun_xuan_ji_shi = ZhangBen.YUN_XUAN_SHI_CHANG
	dian_ma = 0.0
	du_yun = 0.0
	_kong_zhi_shi_jian = 0.0
	_mu_biao = null
	_tao_pao_lai_yuan = null
	_tao_pao_ji_shi = 0.0
	_tu_jin_sheng_yu = 0.0  # 失控打断突进/冲撞/潜伏
	_chong_zhuang_sheng_yu = 0.0
	_chong_zhuang_ming_zhong.clear()
	_jie_chu_yin_shen_npc()
	zhuang_tai = ZhuangTai.YOU_DANG


func _zou_kong_zhi(delta: float) -> void:
	if _yun_xuan_ji_shi > 0.0:
		_yun_xuan_ji_shi = maxf(0.0, _yun_xuan_ji_shi - delta)
		return
	dian_ma = maxf(0.0, dian_ma - ZhangBen.KONG_ZHI_XIA_JIANG * delta)
	du_yun = maxf(0.0, du_yun - ZhangBen.KONG_ZHI_XIA_JIANG * delta)


func _kong_zhi_zhong(delta: float) -> void:
	# 失控表现：停住 + 发蓝 + 抽搐；不游、不咬、不吃——任人宰割
	_kong_zhi_shi_jian += delta
	$AnimatedSprite2D.modulate = Color(0.65, 0.8, 1.0)
	$AnimatedSprite2D.rotation = sin(_kong_zhi_shi_jian * 30.0) * 0.06


func _fang_dian(delta: float) -> void:
	# 电鳗：能力表 bian_hao = fang_dian_ma_bi 的鱼，每 npc_jian_ge 秒电一次身边的鱼与玩家
	# 数值走 npc_zhi()：玩家拿 100（一次满条），NPC 用 55（保留原来的两下节奏）
	if _neng_li == null or _neng_li.bian_hao != &"fang_dian_ma_bi":
		return
	_dian_ji_ji_shi -= delta
	if _dian_ji_ji_shi > 0.0:
		return
	_dian_ji_ji_shi = _neng_li.npc_jian_ge if _neng_li.npc_jian_ge > 0.0 else DIAN_JI_JIAN_GE
	var ban_jing := _neng_li.ban_jing if _neng_li.ban_jing > 0.0 else DIAN_JI_BAN_JING
	TE_XIAO.fang_dian(get_parent(), global_position)  # 先亮电圈：玩家能看到“这一下从哪来”
	for yu in _zhou_wei_yu():
		if global_position.distance_to(yu.global_position) <= ban_jing:
			yu.jia_dian_ma(_neng_li.npc_zhi())
	var wan := _zhao_wan_jia()
	if wan != null and global_position.distance_to(wan.global_position) <= ban_jing:
		wan.jia_dian_ma(_neng_li.npc_zhi())


func shou_dao_yao_ji(shang_hai: float, lai_yuan = null, bu := "shen") -> void:
	# 被咬：掉体型、闪红、记仇；咬我的是同级或更大的 → 逃 2 秒（策划案 8.6.3 受击反应）
	# 不按“是不是玩家”区别对待：玩家体型不够大时，大鱼也不该怕他——才能站着被咬小
	# bu 是部位：普通鱼全身一个价；但「正面咬嘴」与「偷袭身体」的反应速度不同（见下方反应时间）
	if si_le or not is_inside_tree():
		return
	_jie_chu_yin_shen_npc()  # 受击破隐：潜伏的 ×2 不留给下一次
	tixing = maxf(ZUI_XIAO_TI_XING, tixing - shang_hai)
	_ying_she_ti_xing()
	_shan_hong()
	# 蓑鲉反毒：谁咬我，谁就叠毒晕条（被咬也中毒，逼玩家换目标或速战速决）
	# 能力表 bian_hao = du_ji_hu_ti；NPC 用 npc_zhi()（没覆写就是 45）
	if _neng_li != null and _neng_li.bian_hao == &"du_ji_hu_ti" and _neng_li.npc_zhi() > 0.0 \
			and lai_yuan != null and is_instance_valid(lai_yuan) and lai_yuan.has_method("jia_du_yun"):
		lai_yuan.jia_du_yun(_neng_li.npc_zhi())
		TE_XIAO.zhong_du(get_parent(), global_position)  # 毒雾喷在蓑鲉身上：咬人者中毒的反馈
	# 首领被咬到残血 = 击败：不是被吞，而是“打服了”——发信号给 Main 触发提前开战
	if shi_boss and tixing <= ZhangBen.BOOS_BAI_TI_XING:
		_bei_ji_bai()
		return
	if shi_boss:
		return  # 首领不逃跑：站着挨咬才打得动
	# 反应时间：偷袭身体/头 → 先懵一会儿；正面咬嘴（zui）算当面咬，立刻反应
	# 延迟中再挨咬不刷新计时——否则玩家连咬就能把鱼永远定住
	if lai_yuan != null and is_instance_valid(lai_yuan):
		if bu == "zui" or lai_yuan == _mu_biao:
			_ji_zhang_chou_hen(lai_yuan)
		elif _fan_ying_ji_shi > 0.0:
			pass  # 还在懵：保持原来的反应节奏
		elif fan_ying_shi_jian > 0.0:
			_dai_chou_hen = lai_yuan
			_fan_ying_ji_shi = fan_ying_shi_jian
		else:
			_ji_zhang_chou_hen(lai_yuan)


func _ji_zhang_chou_hen(lai_yuan) -> void:
	# 记仇：咬我的是同级或更大的 → 逃 2 秒（策划案 8.6.3 受击反应）
	if lai_yuan == null or not is_instance_valid(lai_yuan):
		return
	_chou_hen = lai_yuan
	if float(lai_yuan.tixing) >= tixing:
		_tao_pao_lai_yuan = lai_yuan
		_tao_pao_ji_shi = TAO_PAO_SHI_CHANG
		_mu_biao = null
		zhuang_tai = ZhuangTai.TAO_PAO


func _zou_fan_ying(delta: float) -> void:
	# 反应延迟：被偷袭后先按原路线游；计时结束才“反应过来”记仇/逃跑/反击
	if _fan_ying_ji_shi <= 0.0:
		return
	_fan_ying_ji_shi = maxf(0.0, _fan_ying_ji_shi - delta)
	if _fan_ying_ji_shi > 0.0:
		return
	var chou = _dai_chou_hen
	_dai_chou_hen = null
	_ji_zhang_chou_hen(chou)


func _bei_ji_bai() -> void:
	# 首领败退：立死旗、停 AI、淡出并释放；广播放在最前面，Main 立刻能收到
	si_le = true
	set_process(false)
	bei_ji_bai.emit()
	var bu_jian := create_tween()
	bu_jian.set_parallel(true)
	bu_jian.tween_property(self, "modulate:a", 0.0, 0.6)
	bu_jian.tween_property(self, "scale", scale * 0.6, 0.6)
	bu_jian.chain().tween_callback(queue_free)


func _ying_she_ti_xing() -> void:
	# 体型变了，贴图大小跟着变：玩家能一眼看出“这条鱼被我咬小了”
	scale = Vector2.ONE * ZhangBen.ti_xing_dao_chi_du(tixing)


func _shan_hong() -> void:
	if _yan_se_tween != null and _yan_se_tween.is_valid():
		_yan_se_tween.kill()
	modulate = Color(1.0, 0.35, 0.35)
	_yan_se_tween = create_tween()
	_yan_se_tween.tween_property(self, "modulate", Color.WHITE, 0.18)


func _geng_xin_bu_wei() -> void:
	# 部位点（本地坐标）随贴图翻转：否则鱼朝左时“嘴”还留在右边，锁点会锁错
	var chao := -1.0 if $AnimatedSprite2D.flip_h else 1.0
	$ZuiDian.position = Vector2(62.0 * chao, 0.0)
	$ZhiMingDian.position = Vector2(35.0 * chao, -34.0)


func qu_dian(bu: String) -> Vector2:
	# 取世界坐标的部位点：zui=鱼嘴，zhi_ming=头部致命区，其余=身体中心
	match bu:
		"zui":
			return $ZuiDian.global_position
		"zhi_ming":
			return $ZhiMingDian.global_position
		_:
			return global_position


func _zhou_wei_yu() -> Array:
	var jie_guo := []
	for n in get_tree().get_nodes_in_group("yu_npc"):
		if n != self and is_instance_valid(n):
			jie_guo.append(n)
	return jie_guo


func _zhao_you_er_qi_pao() -> YouErQiPao:
	# 找感知内最近的诱饵气泡：气泡自带吸引半径，只有圈里的鱼才被骗
	var zui_jin: YouErQiPao = null
	var zui_jin_ju := INF
	for node in get_tree().get_nodes_in_group("you_er_qi_pao"):
		var qi := node as YouErQiPao
		if qi == null or not is_instance_valid(qi):
			continue
		var ju := global_position.distance_to(qi.global_position)
		if ju <= qi.ban_jing and ju < zui_jin_ju:
			zui_jin_ju = ju
			zui_jin = qi
	return zui_jin


func _zhao_fu_rou_you_er() -> RouKuai:
	# 找腐肉诱饵：只认被玩家咬出来的“发光肉”，普通鱼肉不吸鱼
	var zui_jin: RouKuai = null
	var zui_jin_ju := INF
	for node in get_tree().get_nodes_in_group("rou_kuai"):
		var rou := node as RouKuai
		if rou == null or not is_instance_valid(rou) or rou.fu_rou_you_er_sheng_yu <= 0.0:
			continue
		var ju := global_position.distance_to(rou.global_position)
		if ju <= rou.xi_yin_ban_jing and ju < zui_jin_ju:
			zui_jin_ju = ju
			zui_jin = rou
	return zui_jin


func _zhao_wan_jia() -> Yu:
	if _wan_jia == null or not is_instance_valid(_wan_jia):
		_wan_jia = get_tree().get_first_node_in_group("player") as Yu
	return _wan_jia


func _yao_ji_ju_li() -> float:
	# 能咬到多远的鱼：体型越大嘴越远
	# 首领例外：走玩家同款「基础半径 × 体型→像素」曲线——开局与视觉等大，
	# 随每 30 秒的成长（zou_boos_sheng_ji）逐渐变大；不再一出场就是超视觉的大判定圈，
	# 玩家从鲸鲨旁边路过不会被隔空咬死（试玩反馈 2026-10-30）
	if shi_boss:
		return BOOS_YAO_JI_JI_CHU * ZhangBen.ti_xing_dao_chi_du(tixing)
	return 55.0 + 14.0 * tixing


func _chi_yu_ju_li(mu) -> float:
	# 整吞距离：比咬击更近，得“贴脸”
	return 35.0 + 14.0 * tixing + 14.0 * float(mu.tixing)


func _geng_xin_hong_guang(delta: float) -> void:
	# “玩家能不能吃我”与 yu.gd 嘴圈的判定共用同一常数 Yu.TUN_CHI_BEI_LV——两边永不分叉
	if _wan_jia == null:
		_wan_jia = get_tree().get_first_node_in_group("player") as Yu
	if _zai_gong_ji:
		_hong_guang.visible = false  # 咬击帧和游动帧不是同一套图：红光层先让位
		return
	if _wan_jia == null or _wan_jia.tixing < tixing * Yu.TUN_CHI_BEI_LV:
		_hong_guang.visible = false  # 吃不下 / 没有玩家：关灯，少画一层
		return
	_guang_shi_jian += delta
	_hong_guang.visible = true
	_hong_guang.flip_h = $AnimatedSprite2D.flip_h  # 跟着本体翻转，红光不会偏到一侧
	_hong_guang.frame = $AnimatedSprite2D.frame  # 帧也对齐：红光轮廓始终贴着本体当前姿态
	# 红通道给到 3.2（Color 分量可以 >1）：贴图多半偏暗，只乘 1 倍的红光根本看不清
	_hong_guang.modulate = Color(3.2, 0.1, 0.1, 0.5 + 0.18 * sin(_guang_shi_jian * 5.0))


func _chi_rou() -> void:
	# NPC 吃可食物：涨隐藏经验（v0.4 吃白吃时代结束）；路过就吃，不主动追
	for qu in rou_qu.get_overlapping_areas():
		var wu := qu as KeChiWu
		if wu != null and wu.ke_chi:
			jia_jing_yan_nei(wu.jing_yan)
			wu.bei_chi()


func bei_chi(ji_yu_jiang_li := true, chi_zhe = null) -> void:
	# 被吃掉的统一入口：先记账再释放（第 3 课挖好的挂钩点在此兑现）
	# ji_yu_jiang_li=false：被别的 NPC 吃掉 / 玩家走消化槽时调用——这里不记玩家经验
	# chi_zhe：吞它的那张嘴。蓑鲉有毒 → 吞下去的人叠毒晕条（策划案 8.6.3）
	if si_le or shi_boss:
		return  # 首领不可整吞：只能一口口咬到残血（TASK-017）
	si_le = true
	if _neng_li != null and _neng_li.bian_hao == &"du_ji_hu_ti" and _neng_li.npc_zhi() > 0.0 \
			and chi_zhe != null and is_instance_valid(chi_zhe) and chi_zhe.has_method("jia_du_yun"):
		chi_zhe.jia_du_yun(_neng_li.npc_zhi())
	if ji_yu_jiang_li and yu_zhong != null:
		ZhangBen.jia_jing_yan(int(yu_zhong.fenzhi))  # 吃兜底鱼不给经验
	queue_free()


func _shi_jiao_fan_wei() -> Rect2:
	# 相机在世界里的可视矩形；没有相机（测试场景）时退回视口，保持旧行为
	if not is_inside_tree():
		return Rect2()  # 已离开树：没有视口，交给上层按“空范围”处理
	var pingmu := get_viewport_rect().size
	var shi_jiao := get_viewport().get_camera_2d()
	if shi_jiao != null:
		return Rect2(shi_jiao.get_screen_center_position() - pingmu * 0.5, pingmu)
	return Rect2(Vector2.ZERO, pingmu)
