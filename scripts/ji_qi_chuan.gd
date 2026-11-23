extends Node2D
class_name JiQiChuan
# 人类机器船（TASK-017 终局）：8 分钟（或鲸鲨提前开战）后降临，玩家咬弱点把它打沉
# 它和鱼群不是一家：不继承 YuNpc，只实现玩家咬击要用的最小契约
# （tixing / si_le / qu_dian / shou_dao_yao_ji），让 Yu 的自动咬击原样锁定它
#
# 2026-11-03 扩展：整船视觉/判定 ×3，攻击范围 ×2。
# 2026-11-12 TASK-022：整船视觉/受击判定在 ×3 基础上再 ×0.8（倍率 3.0→2.4），攻击范围保持不变。
# 2026-11-05 改版：只保留素材包里的四招（探照灯扫描/船锚横扫/深水炸弹/鱼叉齐射），
# 取消血量/时间阶段解锁——开局即四招轮换，出招规则见 _ke_xuan_zhao() 的硬约束。

signal bei_ji_bai  # 船被打沉：Main 据此判胜

# 初始血量唯一入口（11-23 A13）：固定 400，与玩家体型彻底脱钩。
# 玩家对船的伤害仍随体型增长（另一半激励），两者互不干扰。
static func chu_shi_xue() -> float:
	return SHU_ZHI.CHUAN_XUE_GU_DING

const SHU_ZHI := preload("res://scripts/shu_zhi.gd")  # A 核心数值表
const ZUI_DA_XUE := SHU_ZHI.CHUAN_XUE_GU_DING  # 固定 400（11-23 A13 拍板）：编辑器/测试兜底，Main 也读同一个入口
const RUO_DIAN_BEI_LV := 3.0      # 弱点（玻璃舱）伤害倍率
const GEN_SUI_SU_DU := 110.0      # 横向跟随玩家的速度（px/秒）：慢到玩家能绕到侧面
const XUAN_FU_GAO_DU := 480.0     # 悬停在玩家上方多高（TASK-022 船体 ×0.8 后由 600 同步降到 480）
const GONG_JI_JIAN_GE := 1.0      # 两次攻击的间隔（秒）：高频压迫，靠规则限制连段
const CHUAN_TI_BEI_LV := 2.4      # 整船视觉倍率（TASK-022 用户反馈船太大：3.0 ×0.8 = 2.4）
const ZHAO_TI_BEI_LV := 3.04      # 整船招式动画倍率：让动画里的船体约等于普通船贴图 ×2.4（3.8 ×0.8）
const GONG_JI_FAN_WEI_BEI_LV := 2.0  # 所有攻击范围倍率（用户 2026-11-03：范围 ×2）

# —— 技能/被动兼容（2026-11-13 玩家反馈：主动技能与被动必须能作用于机械船）——
const JI_NENG_MEI_JI_HP := 8.0  # 鱼技能「掉 1 级体型」换算成船体 HP 的比例（约 8 HP/级，可调）
const KONG_ZHI_DAN_CI_SHANG_XIAN := 1.2  # 单次硬控最长秒数（用户要求 0.6~1.5 秒）
const KONG_ZHI_KANG_XING_SHI_CHANG := 3.0  # 吃到一次硬控后的内部抗性窗口（秒）
const KONG_ZHI_KANG_XING_XI_SHU := 0.35  # 抗性窗口内后续硬控时长折扣：防无限锁
const YUN_XUAN_SHI_CHANG := 1.2  # 电麻/毒晕满条后的失控时长（秒）
const ZHUANG_TAI_MING: Array[StringName] = [&"shi_hua", &"feng_kuang", &"kong_ju", \
		&"mei_huo", &"zhi_mang", &"shu_fu"]  # 与 YuNpc 同名的六状态白名单

# —— 深水炸弹 ——
const ZHA_DAN_BAN_JING := 240.0   # 120 × 2
const ZHA_DAN_YU_JING := 0.5      # 预警 0.5 秒
const ZHA_DAN_SHANG_HAI := 1.0
const ZHA_DAN_JING_SHA_BEI_LV := 0.8  # 对鲸鲨伤害 ×0.8
const ZHA_DAN_LENG_QUE := 5.0
# —— 船锚横扫 ——
const MAO_NEI_BAN_JING := 100.0   # 内径 50 × 2：贴脸反而打不到，留出反打位
const MAO_WAI_BAN_JING := 480.0   # 外径 240 × 2
const MAO_JIAO_DU := 150.0        # 扇形总角度（度）
const MAO_SHANG_HAI := 0.7
const MAO_SAO_SHI_CHANG := 0.35   # 伤害结算时刻 = 开始扫的时间
const MAO_TUI_KAI := 440.0        # 击退距离：220 × 2
const MAO_TUI_KAI_SHI_CHANG := 0.25
const MAO_LENG_QUE := 6.0
# —— 探照灯扫描（控制/减速，无伤害） ——
const TAN_ZHAO_CHANG := 1120.0    # 560 × 2
const TAN_ZHAO_BAN_JIAO := 18.0   # 半角 18°
const TAN_ZHAO_JIAN_SU_BEI := 0.55
const TAN_ZHAO_CAN_LIU := 0.4     # 离开光束后减速残留
const TAN_ZHAO_SHI_CHANG := 0.6   # 有效照射时长
const TAN_ZHAO_LENG_QUE := 5.0
# —— 鱼叉齐射 ——
const YU_CHA_SHU := 3
const YU_CHA_JIAN_GE := 0.1
const YU_CHA_SU_DU := 1000.0
const YU_CHA_SHE_CHENG := 1300.0  # 650 × 2
const YU_CHA_BAN_JING := 28.0     # 14 × 2
const YU_CHA_SHANG_HAI := 0.6
const YU_CHA_ZHUAN_BEI := 0.15    # 预判玩家 0.15 秒后的位置
const YU_CHA_PIAN_JIAO := 10.0    # 三发 ±10°
const YU_CHA_LENG_QUE := 4.0
const WAN_JIA_TI_XING_SHANG_HAI_BI := 0.04  # TASK-019 船招伤害附加：玩家当前体型 ×4%/招
# —— 开局先打鲸鲨 ——
const XIAN_DA_JING_SHA_SHI_CHANG := 9.0  # 降临后 8~10 秒内优先攻击鲸鲨

const ZHAO_ZHA_DAN := &"zha_dan"
const ZHAO_CHUAN_MAO := &"chuan_mao"
const ZHAO_TAN_ZHAO := &"tan_zhao"
const ZHAO_YU_CHA := &"yu_cha"
const ZHAO_QUAN_BU: Array[StringName] = [
	ZHAO_TAN_ZHAO, ZHAO_CHUAN_MAO, ZHAO_ZHA_DAN, ZHAO_YU_CHA,
]
const SHANG_HAI_ZHAO: Array[StringName] = [
	ZHAO_ZHA_DAN, ZHAO_CHUAN_MAO, ZHAO_YU_CHA,
]
const KONG_ZHI_ZHAO: Array[StringName] = [ZHAO_TAN_ZHAO]
const ZHAO_LENG_QUE := {
	ZHAO_ZHA_DAN: ZHA_DAN_LENG_QUE,
	ZHAO_CHUAN_MAO: MAO_LENG_QUE,
	ZHAO_TAN_ZHAO: TAN_ZHAO_LENG_QUE,
	ZHAO_YU_CHA: YU_CHA_LENG_QUE,
}

var zui_da_xue := ZUI_DA_XUE  # 上限也做成变量：Main 的血条直接读，不必知道常量
var xue := ZUI_DA_XUE
var tixing := 99.0  # 鸭子类型契约：体型 99 → 玩家永远吞不掉，只能一口口咬
var si_le := false  # 鸭子类型契约：死亡后玩家不再锁定
var wan_jia: Yu = null  # 玩家引用：由 Main 生成时注入（不靠组名，测试也好塞假人）
var jing_sha: YuNpc = null  # 鲸鲨引用：开局 8~10 秒优先打它；Main 注入

var _chuan_ti: AnimatedSprite2D
var _zhao_ti: AnimatedSprite2D
var _shan_guang_tween: Tween  # 受击闪白补间：连续受击先杀旧的，避免多个 Tween 同时抢根节点 modulate
var _gong_ji_dingshi: Timer
var _gong_ji_lun := 0  # 攻击轮次：只用于测试与日志，出招由权重选择
var _zheng_zai_chu_zhao := false  # 防重叠：上一招还在前摇/结算时，本轮定时器直接跳过

var _leng_que: Dictionary = {}  # 招式冷却：StringName -> 剩余秒
var _zui_jin: Array[StringName] = []  # 最近 4 拍出的招：硬规则用
var _mao_ming_zhong := false  # 船锚命中：下一拍炸弹权重 0
var _cha_ming_zhong := false  # 鱼叉命中：下一拍船锚权重 0
var _gang_shou_ji := false  # 连续受击：下一拍强制控制招
var _shou_ji_ji_shi := 0.0  # 受击连击窗口剩余
var _shou_ji_lian_xu := 0  # 窗口内受击次数
var _xian_da_jing_sha := 0.0  # 开局优先鲸鲨剩余秒：玩家咬船立即清零

# —— 技能/被动兼容状态（2026-11-13）——
# 船可以吃控/状态，但用独立时钟与抗性，绝不照搬 YuNpc 的无限锁语义
var shi_boss := true  # 终局首领：模块据此对百分比/直伤减半；船体仍不可被整吞
var shi_hua_shou_shang_bei := 1.0  # 石化期间受击倍率：_fang_shi_hua 成功后由玩家技能覆写
var dian_ma := 0.0  # 电麻条 0~100：满条触发短失控
var du_yun := 0.0  # 毒晕条 0~100：满条触发短失控
var _yun_xuan_sheng_yu := 0.0  # 电麻/毒晕失控剩余秒
var _ding_zhu_sheng_yu := 0.0  # 定身剩余秒（只拉长反应，不追命）
var _kong_zhi_kang_xing_sheng_yu := 0.0  # 内部抗性剩余秒：窗口内后续硬控按折扣缩时
var _zhuang_tai_sheng_yu: Dictionary = {}  # 六状态：StringName -> 剩余秒
var _mei_huo_dian := Vector2.ZERO  # 魅惑记录点（与 YuNpc 同名，模块可能读取）
var _qiang_suan_sheng_yu := 0.0  # 酸蚀总剩余秒（只对船体掉少量 HP）
var _qiang_suan_mei_miao := 0.0  # 酸蚀每秒掉几级体型
var _qiang_suan_ji_shi := 0.0  # 酸蚀结算累计秒
var _qiang_suan_bei_yao := false  # 酸蚀期间被咬是否 ×2（与 YuNpc 语义一致）
var _gao_liang_sheng_yu := 0.0  # 被声呐/共生海葵等标记的剩余秒
var _deng_ji_sheng_yu := 0.0  # 头顶等级牌剩余秒
var _deng_ji_biao: Label = null  # 头顶等级牌（弱点洞察/声呐选最大体型时给玩家反馈）

# 深水炸弹
var _zha_dan_dian := Vector2.ZERO
var _zha_dan_jin_xing := false
var _zha_dan_sheng_yu := 0.0
var _zha_dan_bao_sheng_yu := 0.0  # 爆炸余辉绘制时间
# 船锚
var _mao_fang := Vector2.DOWN
var _mao_jin_xing := false
var _mao_sheng_yu := 0.0
# 探照灯
var _tan_zhao_fang := Vector2.DOWN
var _tan_zhao_jin_xing := false
var _tan_zhao_sheng_yu := 0.0
# 鱼叉
var _yu_chas: Array[Dictionary] = []
var _zhao_ci := 0  # 整船动画代次：旧协程回来不覆盖新招式


func _ready() -> void:
	_chuan_ti = $ChuanTi
	_zhao_ti = $ZhaoTi
	_chuan_ti.play(&"dong")  # 4 帧潜艇推进动画（场景 autoplay 也开了，这里显式写清意图）
	_zhao_ti.scale = Vector2.ONE * ZHAO_TI_BEI_LV
	_zhao_ti.visible = false
	_gong_ji_dingshi = $GongJiDingshi
	_gong_ji_dingshi.timeout.connect(_on_gong_ji_timeout)
	_gong_ji_dingshi.start(GONG_JI_JIAN_GE)  # 降临后 1 秒首次出招
	_ying_yong_fang_da()
	_xian_da_jing_sha = XIAN_DA_JING_SHA_SHI_CHANG if _jing_sha_huo() else 0.0
	# 技能/被动兼容：单独成组，绝不加入 "yu_npc"（避免 NPC 吞噬/刷怪/同类逻辑把船当鱼）
	add_to_group(&"ji_qi_chuan")


func _ying_yong_fang_da() -> void:
	# 船体贴图 + 两个受击圆统一按 CHUAN_TI_BEI_LV 缩放（TASK-022 为 ×2.4，视觉与判定一致）；
	# 攻击范围常量不在这里改（GONG_JI_FAN_WEI_BEI_LV 等保持原值）。
	_chuan_ti.scale = Vector2.ONE * CHUAN_TI_BEI_LV
	var ruo_dian: CollisionShape2D = $SheDingQu/CollisionShape2D
	var chuan_ti_qu: CollisionShape2D = $ChuanTiQu/CollisionShape2D
	ruo_dian.position = Vector2(0, -20.0 * CHUAN_TI_BEI_LV)
	chuan_ti_qu.position = Vector2(0, 60.0 * CHUAN_TI_BEI_LV)
	if ruo_dian.shape is CircleShape2D:
		ruo_dian.shape.radius = 60.0 * CHUAN_TI_BEI_LV  # 弱点玻璃舱：基准 60 × 整船倍率
	if chuan_ti_qu.shape is CircleShape2D:
		chuan_ti_qu.shape.radius = 150.0 * CHUAN_TI_BEI_LV  # 船体：基准 150 × 整船倍率


func chuan_ti_ban_jing() -> float:
	# 船体碰撞圆半径（世界像素）：基准 150 × 整船视觉倍率；决战相机用它按船体大小取景
	return 150.0 * CHUAN_TI_BEI_LV


func _process(delta: float) -> void:
	# 先走所有时钟：即使玩家暂时无效，冷却/爆炸/弹道也该收尾
	_geng_xin_leng_que(delta)
	_geng_xin_zha_dan(delta)
	_geng_xin_chuan_mao(delta)
	_geng_xin_tan_zhao(delta)
	_geng_xin_yu_chas(delta)
	_geng_xin_zhuang_tai(delta)  # 技能状态/酸蚀 DoT：死亡后也收尾，但不重复扣血
	if si_le or wan_jia == null or not is_instance_valid(wan_jia):
		return
	if _xian_da_jing_sha > 0.0:
		_xian_da_jing_sha = maxf(0.0, _xian_da_jing_sha - delta)
	if _shou_ji_ji_shi > 0.0:
		_shou_ji_ji_shi = maxf(0.0, _shou_ji_ji_shi - delta)
		if _shou_ji_ji_shi <= 0.0:
			_shou_ji_lian_xu = 0
	# 硬控期间不跟随：玩家能靠定身/失控拉开距离；减速（探照灯）仍由玩家侧处理
	if zai_kong_zhi():
		return
	# 慢速跟随：横向追玩家、纵向吊在玩家上方——玩家往上顶才能咬到玻璃舱
	position.x = move_toward(position.x, wan_jia.position.x, GEN_SUI_SU_DU * delta)
	position.y = clampf(wan_jia.position.y - XUAN_FU_GAO_DU, 90.0, 2150.0)


func _geng_xin_leng_que(delta: float) -> void:
	for id in _leng_que.keys():
		_leng_que[id] = maxf(0.0, float(_leng_que[id]) - delta)


func qu_dian(bu: String) -> Vector2:
	# 鸭子类型契约：部位坐标——玻璃舱在上方（弱点），船体在下方（普通伤害）
	match bu:
		"zhi_ming":
			return global_position + Vector2(0, -20.0 * CHUAN_TI_BEI_LV)
		_:
			return global_position + Vector2(0, 70.0 * CHUAN_TI_BEI_LV)


# —— 技能/被动兼容 API（2026-11-13）——
# 设计口径：
# 1) 鱼技能的「掉几级体型」不能直接当船 HP：统一走 shou_dao_ji_neng，按 JI_NENG_MEI_JI_HP 换算。
# 2) 百分比直伤（水刀/裂缝等）走 shou_dao_ji_neng_bai_fen，按 max(xue) 计算并保留首领减半。
# 3) 技能对船只走普通船体伤害：不叠玻璃舱 ×3，也不重复套护甲（护甲留在玩家主动咬击通道）。
# 4) 控制类方法都做单次上限 + 内部抗性，避免多个技能把船无限锁死。

func mian_chao_fang() -> float:
	# 鸭子契约：水平朝向（贴图默认朝右，-1=朝左）；背刺直觉按它判背后
	var mu := _mu_biao()
	if mu != null and is_instance_valid(mu) and mu.global_position.x < global_position.x:
		return -1.0
	return 1.0


func ji_neng_dui_bi_ti_xing() -> float:
	# 鸭子契约：需要「对方体型」的鱼技能公式（剧毒突刺/冲撞）以玩家体型为参照。
	# 船真实 tixing=99 只用于「吞不下」，不能拿来算 3% 咬伤，否则单次伤害会爆表。
	if wan_jia != null and is_instance_valid(wan_jia):
		return maxf(1.0, wan_jia.tixing)
	return 9.0


func shou_dao_ji_neng(liang: float, lai_yuan = null) -> void:
	# 主动/被动技能的统一等级伤害入口：liang=「掉几级体型」，1 级 ≈ JI_NENG_MEI_JI_HP HP
	if si_le or liang <= 0.0:
		return
	_kou_xue_ji_neng(liang * JI_NENG_MEI_JI_HP, lai_yuan)


func shou_dao_ji_neng_bai_fen(bai_fen: float, lai_yuan = null) -> void:
	# 百分比直伤入口：按当前最大血量换算；船是首领，固定减半，绝不使用 tixing*百分比
	if si_le or bai_fen <= 0.0:
		return
	_kou_xue_ji_neng(maxf(zui_da_xue, 1.0) * bai_fen / 100.0 * 0.5, lai_yuan)


func shou_dao_ji_neng_hp(shang_hai: float, lai_yuan = null) -> void:
	# 已换算成船体 HP 的入口：咬击联动（撕裂齿/腐肉诱饵）按实际 HP 再折算少量伤害
	if si_le or shang_hai <= 0.0:
		return
	_kou_xue_ji_neng(shang_hai, lai_yuan)


func _kou_xue_ji_neng(shang_hai: float, _lai_yuan) -> void:
	# 技能伤害不触发「1.5 秒 3 次」连击保护：否则多个 DoT 会逼船一直出控制招
	if si_le or shang_hai <= 0.0:
		return
	xue = maxf(0.0, xue - shang_hai)
	_shan_guang()
	_xian_da_jing_sha = 0.0  # 被技能打也算转仇
	if xue <= 0.0:
		_chen_mo()


func shou_zhi_jie_shang(liang: float, lai_yuan = null) -> void:
	# 兼容 YuNpc 的「无视防御直伤」：调用方给的是「级」，这里换 HP；不经过护甲/反甲/记仇
	if si_le or liang <= 0.0:
		return
	_kou_xue_ji_neng(liang * JI_NENG_MEI_JI_HP, lai_yuan)


func jia_dian_ma(liang: float) -> void:
	# 兼容 YuNpc：电麻条 0~100；满条进入短失控（不是永久麻痹）
	if si_le or not is_inside_tree() or liang <= 0.0 or _yun_xuan_sheng_yu > 0.0:
		return
	dian_ma = minf(100.0, dian_ma + liang)
	if dian_ma >= 100.0:
		# v2 电麻光环：满条瞬间头顶一电黄爆闪，和 YuNpc 同款；不显形也不影响判定
		TeXiaoKu.gua_zhuang_tai(&"dian_ma", self, 1.2, {"chi_xu": YUN_XUAN_SHI_CHANG})
		_chu_fa_yun_xuan()


func jia_du_yun(liang: float) -> void:
	# 兼容 YuNpc：毒晕条 0~100；满条进入短失控
	if si_le or not is_inside_tree() or liang <= 0.0 or _yun_xuan_sheng_yu > 0.0:
		return
	du_yun = minf(100.0, du_yun + liang)
	if du_yun >= 100.0:
		# v2 毒晕光环：满条瞬间头顶一绿毒爆闪，和 YuNpc 同款
		TeXiaoKu.gua_zhuang_tai(&"du_yun", self, 1.2, {"chi_xu": YUN_XUAN_SHI_CHANG})
		_chu_fa_yun_xuan()


func _chu_fa_yun_xuan() -> void:
	# 电麻/毒晕统一失控：清零两条、单次限时、并写入内部抗性
	var shi := _suan_kong_zhi_shi_chang(YUN_XUAN_SHI_CHANG)
	_yun_xuan_sheng_yu = maxf(_yun_xuan_sheng_yu, shi)
	dian_ma = 0.0
	du_yun = 0.0
	_kong_zhi_kang_xing_sheng_yu = KONG_ZHI_KANG_XING_SHI_CHANG


func _suan_kong_zhi_shi_chang(shi_chang: float) -> float:
	# 硬控单次上限 + 抗性窗口折扣：防止电麻流/定身流无限锁船
	var shi := minf(shi_chang, KONG_ZHI_DAN_CI_SHANG_XIAN)
	if _kong_zhi_kang_xing_sheng_yu > 0.0:
		shi *= KONG_ZHI_KANG_XING_XI_SHU
	return maxf(0.0, shi)


func ding_zhu(shi_chang: float) -> void:
	# 兼容 YuNpc 的定身：只拉长出招反应，不阻止玩家拉开距离；同样受单次上限/抗性约束
	if si_le or not is_inside_tree() or shi_chang <= 0.0:
		return
	var shi := _suan_kong_zhi_shi_chang(shi_chang)
	if shi <= 0.0:
		return
	_ding_zhu_sheng_yu = maxf(_ding_zhu_sheng_yu, shi)
	_kong_zhi_kang_xing_sheng_yu = KONG_ZHI_KANG_XING_SHI_CHANG


func jia_zhuang_tai(ming: StringName, shi_chang: float, mu_dian := Vector2.ZERO) -> bool:
	# 兼容 YuNpc 的六状态白名单；船不免疫状态，但每个状态都限时，并共享硬控抗性
	if si_le or not is_inside_tree() or shi_chang <= 0.0 or not ZHUANG_TAI_MING.has(ming):
		return false
	var shi := _suan_kong_zhi_shi_chang(shi_chang)
	if shi <= 0.0:
		return false
	_zhuang_tai_sheng_yu[ming] = maxf(float(_zhuang_tai_sheng_yu.get(ming, 0.0)), shi)
	# v2 状态光环：和 YuNpc 同一套六色头顶标记（石化/魅惑/恐惧/疯狂等）；船无 ti_chang 按默认尺度
	TeXiaoKu.gua_zhuang_tai(ming, self, 1.2, {"chi_xu": shi})
	if ming == &"mei_huo":
		_mei_huo_dian = mu_dian  # 鬼火引路要记录魅惑点（与 YuNpc 契约一致）
	_kong_zhi_kang_xing_sheng_yu = KONG_ZHI_KANG_XING_SHI_CHANG
	return true


func you_zhuang_tai(ming: StringName) -> bool:
	return float(_zhuang_tai_sheng_yu.get(ming, 0.0)) > 0.0


func zhuang_tai_sheng_yu(ming: StringName) -> float:
	if ming == &"ding_zhu":
		return _ding_zhu_sheng_yu
	return float(_zhuang_tai_sheng_yu.get(ming, 0.0))


func zai_kong_zhi() -> bool:
	# 硬控口径：失控/定身/石化/疯狂/恐惧/麻痹视觉；魅惑/致盲只停攻击，不拦跟随
	return _yun_xuan_sheng_yu > 0.0 or _ding_zhu_sheng_yu > 0.0 \
		or you_zhuang_tai(&"shi_hua") or you_zhuang_tai(&"feng_kuang") \
		or you_zhuang_tai(&"kong_ju") or you_zhuang_tai(&"shu_fu")


func jia_qiang_suan(shi_chang: float, mei_miao: float, bei_yao := true) -> bool:
	# 兼容 YuNpc：酸蚀不掉「级」，按每秒折算船体 HP；总时长仍受调用方控制
	if si_le or not is_inside_tree() or shi_chang <= 0.0 or mei_miao <= 0.0:
		return false
	_qiang_suan_sheng_yu = maxf(_qiang_suan_sheng_yu, shi_chang)
	_qiang_suan_mei_miao = maxf(_qiang_suan_mei_miao, mei_miao)
	_qiang_suan_bei_yao = bool(_qiang_suan_bei_yao) or bei_yao
	return true


func diao_rou(shu: int, mei_kuai_ti_xing := 0.3, _fu_rou_sheng_yu := 0.0, _xi_yin_ban_jing := 0.0) -> void:
	# 兼容 YuNpc 掉肉：船不掉肉块，把「块数 × 每块等级」折算成少量 HP，保证被动有实际输出
	if si_le or shu <= 0 or mei_kuai_ti_xing <= 0.0:
		return
	shou_dao_ji_neng(float(shu) * mei_kuai_ti_xing, null)


func tui_kai(fang: Vector2, ju_li: float) -> void:
	# 兼容 YuNpc 击退：机械船太大，只吃「极轻位移」（每次最多 3px，约等于漩涡 10px/秒），
	# 不会被单次技能推飞/推出战场；方向由调用方给，零向量忽略。
	if si_le or ju_li <= 0.0 or fang.length_squared() < 0.0001:
		return
	position += fang.normalized() * minf(ju_li * 0.1, 3.0)


func bei_chi(_ji_yu_jiang_li := true, _chi_zhe = null) -> void:
	# 兼容 YuNpc 吞噬：船体不可整吞；留空实现让模块鸭子调用不报错
	pass


func shi_fang_gao_liang(shi_chang: float) -> void:
	# 兼容 YuNpc 标记：本体画一圈黄环，告诉玩家技能已选中船
	if si_le or shi_chang <= 0.0:
		return
	_gao_liang_sheng_yu = maxf(_gao_liang_sheng_yu, shi_chang)
	queue_redraw()


func xian_shi_deng_ji(shi_chang: float) -> void:
	# 兼容 YuNpc：头顶显示 Lv.99，配合弱点洞察/声呐的「选最大体型」反馈
	if si_le or shi_chang <= 0.0:
		return
	_deng_ji_sheng_yu = maxf(_deng_ji_sheng_yu, shi_chang)
	if _deng_ji_biao == null or not is_instance_valid(_deng_ji_biao):
		_deng_ji_biao = Label.new()
		_deng_ji_biao.position = Vector2(-26.0, -180.0)
		_deng_ji_biao.z_index = 5
		add_child(_deng_ji_biao)
	_deng_ji_biao.text = "Lv.%d" % int(round(tixing))
	_deng_ji_biao.visible = true


func _geng_xin_zhuang_tai(delta: float) -> void:
	# 所有技能状态与 DoT 的独立时钟：抗性先减，再减各控制/标记
	_kong_zhi_kang_xing_sheng_yu = maxf(0.0, _kong_zhi_kang_xing_sheng_yu - delta)
	_yun_xuan_sheng_yu = maxf(0.0, _yun_xuan_sheng_yu - delta)
	_ding_zhu_sheng_yu = maxf(0.0, _ding_zhu_sheng_yu - delta)
	var guo_qi: Array = []
	for ming in _zhuang_tai_sheng_yu.keys():
		var sheng := float(_zhuang_tai_sheng_yu[ming]) - delta
		if sheng <= 0.0:
			guo_qi.append(ming)
		else:
			_zhuang_tai_sheng_yu[ming] = sheng
	for ming in guo_qi:
		_zhuang_tai_sheng_yu.erase(ming)
		TeXiaoKu.xia_zhuang_tai(ming, self)  # 状态到期：同名光环同步释放
	# 电麻/毒晕条缓慢回落：不让一次没打满的积累永久挂账
	if _yun_xuan_sheng_yu <= 0.0:
		dian_ma = maxf(0.0, dian_ma - 15.0 * delta)
		du_yun = maxf(0.0, du_yun - 15.0 * delta)
	if _qiang_suan_sheng_yu > 0.0 and not si_le:
		_qiang_suan_sheng_yu = maxf(0.0, _qiang_suan_sheng_yu - delta)
		_qiang_suan_ji_shi += delta
		while _qiang_suan_ji_shi >= 1.0 and not si_le:
			_qiang_suan_ji_shi -= 1.0
			_kou_xue_ji_neng(_qiang_suan_mei_miao * JI_NENG_MEI_JI_HP, null)
		if _qiang_suan_sheng_yu <= 0.0:
			_qiang_suan_mei_miao = 0.0
			_qiang_suan_ji_shi = 0.0
			_qiang_suan_bei_yao = false
	if _gao_liang_sheng_yu > 0.0:
		_gao_liang_sheng_yu = maxf(0.0, _gao_liang_sheng_yu - delta)
		queue_redraw()
	if _deng_ji_sheng_yu > 0.0:
		_deng_ji_sheng_yu = maxf(0.0, _deng_ji_sheng_yu - delta)
		if _deng_ji_sheng_yu <= 0.0 and _deng_ji_biao != null and is_instance_valid(_deng_ji_biao):
			_deng_ji_biao.visible = false


func shou_dao_yao_ji(shang_hai: float, _lai_yuan = null, bu := "shen") -> void:
	# 鸭子类型契约：玩家咬一口。咬玻璃舱 ×3，咬船体 ×1
	if si_le:
		return
	var xi_shu := RUO_DIAN_BEI_LV if bu == "zhi_ming" else 1.0
	# A13：非致命区（船体）护甲减伤 30%；玻璃舱是弱点，不吃护甲
	if bu != "zhi_ming":
		shang_hai *= 1.0 - SHU_ZHI.CHUAN_HU_JIA_JIAN_SHANG
	# 技能/被动兼容：石化期间只对玩家来源加伤；酸蚀期间被咬 ×2（与 YuNpc 语义一致）
	if you_zhuang_tai(&"shi_hua") and _lai_yuan is Node and (_lai_yuan as Node).is_in_group(&"player"):
		shang_hai *= shi_hua_shou_shang_bei
	if _qiang_suan_sheng_yu > 0.0 and _qiang_suan_bei_yao:
		shang_hai *= 2.0
	xue = maxf(0.0, xue - shang_hai * xi_shu)
	_shan_guang()
	# 玩家咬船 = 立刻转仇：开局先打鲸鲨的窗口作废，后续招式回到玩家身上
	_xian_da_jing_sha = 0.0
	# 连续受击保护：1.5 秒内被打 3 次 → 下一拍出控制招（探照灯）
	if _shou_ji_ji_shi <= 0.0:
		_shou_ji_lian_xu = 0
	_shou_ji_lian_xu += 1
	_shou_ji_ji_shi = 1.5
	if _shou_ji_lian_xu >= 3:
		_gang_shou_ji = true
		_shou_ji_lian_xu = 0
	if xue <= 0.0:
		_chen_mo()


func _shan_guang() -> void:
	# 受击反馈：过曝白闪光——modulate 分量 >1，彩色贴图被乘法推向白色，玩家能确认“咬中了”
	# 染根节点而不是 _chuan_ti：出招动画期间 _chuan_ti 被隐藏、_zhao_ti 可见，
	# 只染船体会让 0.7~1.0 秒的出招期完全看不到受击白闪；根节点两层贴图一起闪。
	# 死亡淡出仍写 _chuan_ti.modulate:a，与根节点的白闪互不抢属性。
	if _shan_guang_tween != null and _shan_guang_tween.is_valid():
		_shan_guang_tween.kill()
	modulate = Color(2.8, 2.8, 2.8, 1.0)  # 过曝白起手：2.8 倍亮度
	_shan_guang_tween = create_tween()
	_shan_guang_tween.tween_property(self, "modulate", Color.WHITE, 0.13)  # 0.13 秒回到本色


func _chen_mo() -> void:
	# 打沉：关碰撞、停攻击、广播胜利，再沉下去淡出
	si_le = true
	_gong_ji_dingshi.stop()
	# v2 沉没：淡蓝魂焰从船体升起（固定尺寸，船体本身很大；不随玩家体型）
	TeXiaoKu.bo_ming(&"fb_si_wang", get_parent(), global_position, 220.0)
	$SheDingQu.collision_layer = 0
	$ChuanTiQu.collision_layer = 0
	_zhao_ti.visible = false
	_chuan_ti.visible = true  # 死在整船动画中：把普通船体放回来，沉没动画才看得见
	_zhao_ci += 1  # 让未完成的整船动画协程失效
	_zha_dan_jin_xing = false
	_mao_jin_xing = false
	_tan_zhao_jin_xing = false
	_yu_chas.clear()
	_zheng_zai_chu_zhao = false
	# 技能兼容状态收尾：死亡后不再吃控/DoT，等级牌也隐藏
	_zhuang_tai_sheng_yu.clear()
	TeXiaoKu.qing_zhuang_tai(self)  # 沉没：所有头顶状态光环一起收掉
	_yun_xuan_sheng_yu = 0.0
	_ding_zhu_sheng_yu = 0.0
	_qiang_suan_sheng_yu = 0.0
	_gao_liang_sheng_yu = 0.0
	_deng_ji_sheng_yu = 0.0
	if _deng_ji_biao != null and is_instance_valid(_deng_ji_biao):
		_deng_ji_biao.visible = false
	queue_redraw()
	bei_ji_bai.emit()
	var bu_jian := create_tween()
	bu_jian.set_parallel(true)
	bu_jian.tween_property(self, "rotation", 0.35, 2.0)
	bu_jian.tween_property(self, "position:y", position.y + 260.0, 2.0)
	bu_jian.tween_property(_chuan_ti, "modulate:a", 0.0, 2.0)
	bu_jian.chain().tween_callback(queue_free)


# —— 出招调度 ——

func _on_gong_ji_timeout() -> void:
	if si_le:
		return
	if _zheng_zai_chu_zhao:
		_gong_ji_dingshi.start(GONG_JI_JIAN_GE)
		return
	# 失控保护：整拍跳过，等玩家能动了再出招（设计允许“跳过”）
	if ZhangBen.zai_kong_zhi():
		_gong_ji_dingshi.start(GONG_JI_JIAN_GE)
		return
	# 技能控制/致盲/魅惑：本拍不出招；状态都由限时/抗性收尾，不会无限锁
	if zai_kong_zhi() or you_zhuang_tai(&"zhi_mang") or you_zhuang_tai(&"mei_huo"):
		_gong_ji_dingshi.start(GONG_JI_JIAN_GE)
		return
	var zhao := _ke_xuan_zhao()
	if zhao == &"":
		_gong_ji_dingshi.start(GONG_JI_JIAN_GE)
		return
	_ji_lu_chu_zhao(zhao)
	match zhao:
		ZHAO_ZHA_DAN:
			_kai_shi_shen_zha_dan()
		ZHAO_CHUAN_MAO:
			_kai_shi_chuan_mao()
		ZHAO_TAN_ZHAO:
			_kai_shi_tan_zhao()
		ZHAO_YU_CHA:
			_kai_shi_yu_cha()
	_gong_ji_lun += 1
	_gong_ji_dingshi.start(GONG_JI_JIAN_GE)


func _ji_lu_chu_zhao(zhao: StringName) -> void:
	# 记录 + 清一次性标记：标记只影响紧接的下一拍
	_zui_jin.append(zhao)
	while _zui_jin.size() > 4:
		_zui_jin.pop_front()
	_leng_que[zhao] = float(ZHAO_LENG_QUE.get(zhao, 0.0))
	_mao_ming_zhong = false
	_cha_ming_zhong = false
	_gang_shou_ji = false


func _ke_xuan_zhao() -> StringName:
	# 硬规则（策划案实装）：
	# 1) 冷却中的不出；2) 不连续同招；3) 最近 4 拍同招最多 2 次；
	# 4) 不连续 3 拍伤害招；5) 连续受击 → 下一拍只出控制招（探照灯）；
	# 6) 船锚命中后下一拍不出炸弹；鱼叉命中后下一拍不出船锚。
	# 2026-11-05：取消阶段解锁，开局四招全部可选。
	#
	# 硬规则之间会互相锁死：例如「受击保护只许探照灯」撞上「探照灯刚出过」，
	# 或者鲸鲨窗口只剩两招伤害、又被「不连续 3 拍伤害」卡住。一旦没有任何候选，
	# 标记就永远清不掉（_gang_shou_ji 只在真出招时清），船会彻底停手。
	# 所以下面逐级放宽，只在原规则会空转时才发生；正常情况仍走第一档。
	var biao := _hou_xuan()
	if biao.is_empty() and _xian_da_jing_sha > 0.0 and _jing_sha_huo():
		# 鲸鲨窗口两招都在冷却/被连伤规则卡住 → 提前收工回玩家，别干站满 9 秒
		_xian_da_jing_sha = 0.0
		biao = _hou_xuan()
	if biao.is_empty() and _gang_shou_ji:
		# 受击保护只许控制招：探照灯若被“连发/次数”卡住，先只给探照灯放开这两条
		biao = _hou_xuan(false, true, true)
	if biao.is_empty():
		biao = _hou_xuan(true, false, false)  # 一次性标记（受击/命中后续）让位
	if biao.is_empty():
		biao = _hou_xuan(true, true, false)  # 次数限制也让位
	if biao.is_empty():
		return &""
	var zong := 0.0
	for id in biao:
		zong += _quan_zhong(id, xue / maxf(zui_da_xue, 1.0))
	var gun := randf() * zong
	for id in biao:
		gun -= _quan_zhong(id, xue / maxf(zui_da_xue, 1.0))
		if gun <= 0.0:
			return id
	return biao[-1]


func _hou_xuan(fang_yi_ci := false, fang_ci_shu := false, zhi_kong_zhi := false) -> Array[StringName]:
	# 按硬规则挑候选。三个开关只给「锁死时放宽」用，正常调用一律 false：
	#   fang_yi_ci  = 一次性标记（受击保护/命中后续）让位
	#   fang_ci_shu = 放宽“不连续同招 + 最近 4 拍最多 2 次”
	#   zhi_kong_zhi = 只收控制招（受击保护放宽时的专用路径）
	var biao: Array[StringName] = []
	var mu := _mu_biao()
	var da_jing_sha := mu != null and mu == jing_sha
	for id in ZHAO_QUAN_BU:
		if zhi_kong_zhi and not KONG_ZHI_ZHAO.has(id):
			continue
		if float(_leng_que.get(id, 0.0)) > 0.0:
			continue
		if da_jing_sha and id != ZHAO_ZHA_DAN and id != ZHAO_YU_CHA:
			continue
		if not fang_yi_ci:
			if _gang_shou_ji and not KONG_ZHI_ZHAO.has(id):
				continue
			if _mao_ming_zhong and id == ZHAO_ZHA_DAN:
				continue
			if _cha_ming_zhong and id == ZHAO_CHUAN_MAO:
				continue
		if not fang_ci_shu:
			if _zui_jin.size() > 0 and _zui_jin[-1] == id:
				continue
			var ci := 0
			for guo_qu in _zui_jin:
				if guo_qu == id:
					ci += 1
			if ci >= 2:
				continue
		if _lian_xu_shang_hai(id):
			continue
		biao.append(id)
	return biao


func _lian_xu_shang_hai(id: StringName) -> bool:
	# 不连续 3 拍伤害招：最近两拍都是伤害 → 这一拍不许再伤害
	if not SHANG_HAI_ZHAO.has(id):
		return false
	var shang_hai_ci := 0
	var kan := mini(2, _zui_jin.size())
	for i in range(kan):
		if SHANG_HAI_ZHAO.has(_zui_jin[_zui_jin.size() - 1 - i]):
			shang_hai_ci += 1
	return shang_hai_ci >= 2


func _quan_zhong(id: StringName, bi_lv: float) -> float:
	# 阶段权重：血越少伤害招越重；对鲸鲨则炸弹/鱼叉优先
	if _mu_biao() == jing_sha:
		return 3.0 if (id == ZHAO_ZHA_DAN or id == ZHAO_YU_CHA) else 1.0
	if bi_lv <= 0.15:
		return 2.5 if SHANG_HAI_ZHAO.has(id) else 1.0
	return 1.0


func _mu_biao() -> Node2D:
	# 开局窗口内优先鲸鲨；鲸鲨死了/玩家咬了船 → 回到玩家
	if _xian_da_jing_sha > 0.0 and _jing_sha_huo():
		return jing_sha
	return wan_jia


func _jing_sha_huo() -> bool:
	return jing_sha != null and is_instance_valid(jing_sha) and not jing_sha.si_le


# —— 整船动画 ——

func _bo_zhao(ming: StringName, shi_chang: float) -> void:
	# 播整船招式动画：隐藏普通船体贴图，播完切回；代次防旧协程覆盖
	_zhao_ci += 1
	var ci := _zhao_ci
	_zhao_ti.visible = true
	_zhao_ti.flip_h = _mu_biao() != null and _mu_biao().global_position.x < global_position.x
	_chuan_ti.visible = false
	_zhao_ti.play(ming)
	await get_tree().create_timer(shi_chang).timeout
	if not is_instance_valid(self) or ci != _zhao_ci:
		return
	_zhao_ti.visible = false
	_chuan_ti.visible = true
	_zheng_zai_chu_zhao = false


# —— 深水炸弹 ——

func _kai_shi_shen_zha_dan() -> void:
	var mu := _mu_biao()
	if mu == null:
		return
	_zheng_zai_chu_zhao = true
	_zha_dan_dian = mu.global_position
	_zha_dan_jin_xing = true
	_zha_dan_sheng_yu = ZHA_DAN_YU_JING
	_zha_dan_bao_sheng_yu = 0.0
	_bo_zhao(&"shen_zha_dan", 1.0)
	queue_redraw()


func _geng_xin_zha_dan(delta: float) -> void:
	if _zha_dan_bao_sheng_yu > 0.0:
		_zha_dan_bao_sheng_yu = maxf(0.0, _zha_dan_bao_sheng_yu - delta)
		queue_redraw()
	if not _zha_dan_jin_xing:
		return
	_zha_dan_sheng_yu -= delta
	queue_redraw()
	if _zha_dan_sheng_yu <= 0.0:
		_jie_suan_zha_dan()


func _jie_suan_zha_dan() -> void:
	# 爆炸：对范围内玩家与 NPC 结算；鲸鲨吃 0.8 倍，其余 1.0
	_zha_dan_jin_xing = false
	_zha_dan_bao_sheng_yu = 0.35
	queue_redraw()
	# v2 深水炸弹爆炸：直径 = 爆炸判定圈（240×2），位置锁落点、不随玩家体型
	TeXiaoKu.bo_ming(&"chuan_zha_dan", get_parent(), _zha_dan_dian, ZHA_DAN_BAN_JING * 2.0)
	if wan_jia != null and wan_jia.global_position.distance_to(_zha_dan_dian) <= ZHA_DAN_BAN_JING:
		# G 玩家侧：磁场护壁 → 深水炸弹偏转失效；金属斥力 → 船伤 -30%
		if not wan_jia.zhuan_shu_pi_bi_dan_dao(_zha_dan_dian):
			# 磁场只罩半径内：炸弹落点在圈外照样炸（不再全屏免弹道）
			var shang := (ZHA_DAN_SHANG_HAI \
					+ wan_jia.tixing * WAN_JIA_TI_XING_SHANG_HAI_BI) \
					* wan_jia.zhuan_shu_chuan_shang_hai_bei()
			wan_jia.shou_dao_yao_ji(shang, self)
	for npc in get_tree().get_nodes_in_group("yu_npc"):
		if npc == self or not is_instance_valid(npc) or bool(npc.get("si_le")):
			continue
		if npc.global_position.distance_to(_zha_dan_dian) > ZHA_DAN_BAN_JING:
			continue
		var bei := ZHA_DAN_JING_SHA_BEI_LV if bool(npc.get("shi_boss")) else 1.0
		npc.shou_dao_yao_ji(ZHA_DAN_SHANG_HAI * bei, self)


# —— 船锚横扫 ——

func _kai_shi_chuan_mao() -> void:
	var mu := _mu_biao()
	if mu == null:
		return
	_zheng_zai_chu_zhao = true
	var cha: Vector2 = mu.global_position - global_position
	_mao_fang = cha.normalized() if cha.length_squared() > 0.001 else Vector2.DOWN
	_mao_jin_xing = true
	_mao_sheng_yu = MAO_SAO_SHI_CHANG
	_bo_zhao(&"chuan_mao", 0.9)
	queue_redraw()


func _geng_xin_chuan_mao(delta: float) -> void:
	if not _mao_jin_xing:
		return
	_mao_sheng_yu -= delta
	if _mao_sheng_yu <= 0.0:
		_jie_suan_chuan_mao()


func _jie_suan_chuan_mao() -> void:
	# 扇形判定：内径内/外径外都不吃；命中后击退，并给下一拍炸弹上规则
	_mao_jin_xing = false
	queue_redraw()
	# v2 船锚横扫：铁灰锚影落在扇形中段，宽度按外径（判定最远处）；朝向随挥扫方向
	var mao_wei := global_position + _mao_fang * (MAO_NEI_BAN_JING + MAO_WAI_BAN_JING) * 0.5
	var mao_fx := TeXiaoKu.bo_ming(&"chuan_chuan_mao", get_parent(), mao_wei, MAO_WAI_BAN_JING * 2.0)
	if mao_fx != null:
		mao_fx.rotation = _mao_fang.angle()
	if wan_jia == null or si_le:
		return
	var cha: Vector2 = wan_jia.global_position - global_position
	var ju_li := cha.length()
	if ju_li < MAO_NEI_BAN_JING or ju_li > MAO_WAI_BAN_JING:
		return
	if absf(rad_to_deg(wrapf(cha.angle() - _mao_fang.angle(), -PI, PI))) > MAO_JIAO_DU * 0.5:
		return
	var shang := (MAO_SHANG_HAI + wan_jia.tixing * WAN_JIA_TI_XING_SHANG_HAI_BI) \
			* wan_jia.zhuan_shu_chuan_shang_hai_bei()
	wan_jia.shou_dao_yao_ji(shang, self)
	wan_jia.tui_kai(cha, MAO_TUI_KAI, MAO_TUI_KAI_SHI_CHANG)
	_mao_ming_zhong = true


# —— 探照灯扫描 ——

func _kai_shi_tan_zhao() -> void:
	# 无伤害，只减速：指向玩家此刻的位置，扫 0.6 秒 + 0.4 秒残留
	var mu := _mu_biao()
	if mu == null:
		return
	_zheng_zai_chu_zhao = true
	var cha: Vector2 = mu.global_position - global_position
	_tan_zhao_fang = cha.normalized() if cha.length_squared() > 0.001 else Vector2.DOWN
	_tan_zhao_jin_xing = true
	_tan_zhao_sheng_yu = TAN_ZHAO_SHI_CHANG
	_bo_zhao(&"tan_zhao", 0.9)
	queue_redraw()
	# v2 探照灯：纯白光锥从船体压向玩家方向；god-rays 的 pivot 在底部，故旋转 +90° 对齐扫描角
	# 光锥本身是循环贴图，按扫描时长（含残留）定时淡出
	var tan_fx := TeXiaoKu.bo_ming(&"chuan_tan_zhao", get_parent(), global_position,
			TAN_ZHAO_CHANG * 0.8, {"chi_xu": TAN_ZHAO_SHI_CHANG + TAN_ZHAO_CAN_LIU})
	if tan_fx != null:
		tan_fx.rotation = _tan_zhao_fang.angle() + PI * 0.5


func _geng_xin_tan_zhao(delta: float) -> void:
	if not _tan_zhao_jin_xing:
		return
	_tan_zhao_sheng_yu = maxf(0.0, _tan_zhao_sheng_yu - delta)
	if wan_jia != null and _zai_tan_zhao_nei(wan_jia.global_position):
		wan_jia.jia_wai_bu_jian_su(TAN_ZHAO_JIAN_SU_BEI, TAN_ZHAO_CAN_LIU)
	queue_redraw()
	if _tan_zhao_sheng_yu <= 0.0:
		_tan_zhao_jin_xing = false
		queue_redraw()


func _zai_tan_zhao_nei(dian: Vector2) -> bool:
	var cha := dian - global_position
	if cha.length() > TAN_ZHAO_CHANG:
		return false
	return absf(rad_to_deg(wrapf(cha.angle() - _tan_zhao_fang.angle(), -PI, PI))) <= TAN_ZHAO_BAN_JIAO


# —— 鱼叉齐射 ——

func _kai_shi_yu_cha() -> void:
	var mu := _mu_biao()
	if mu == null:
		return
	_zheng_zai_chu_zhao = true
	_bo_zhao(&"yu_cha", 0.7)
	for i in range(YU_CHA_SHU):
		if si_le:
			return
		if i > 0:
			await get_tree().create_timer(YU_CHA_JIAN_GE).timeout
			if si_le:
				return
		_fa_yi_fa(mu)


func _fa_yi_fa(mu: Node2D) -> void:
	# 预判：朝目标当前位置 + 0.15 秒速度；三发按 -10°/0°/+10° 散开
	var mu_dian := mu.global_position
	if mu is Yu:
		var you: Yu = mu
		mu_dian += Vector2.RIGHT.rotated(you.dang_qian_jiao) * you.dang_qian_su_du * YU_CHA_ZHUAN_BEI
	var ji_xian := (mu_dian - global_position).angle()
	# v2 鱼叉齐射：每轮一支钢灰箭影从船体射出，朝向预判角；尺寸固定（弹道本体）
	var cha_fx := TeXiaoKu.bo_ming(&"chuan_yu_cha", get_parent(),
			global_position + Vector2.RIGHT.rotated(ji_xian) * 120.0, 220.0)
	if cha_fx != null:
		cha_fx.rotation = ji_xian
	for pian in [-YU_CHA_PIAN_JIAO, 0.0, YU_CHA_PIAN_JIAO]:
		_yu_chas.append({
			"pos": global_position,
			"fang": Vector2.RIGHT.rotated(ji_xian + deg_to_rad(pian)),
			"fei": 0.0,
		})
	queue_redraw()


func _geng_xin_yu_chas(delta: float) -> void:
	if _yu_chas.is_empty():
		return
	# G：磁场护壁期间，落进磁场圈的鱼叉偏转失效（逐发判位置：圈外照飞，不是全局清空）
	var huo_zhe: Array[Dictionary] = []
	for cha in _yu_chas:
		var pos: Vector2 = cha["pos"] + (cha["fang"] as Vector2) * YU_CHA_SU_DU * delta
		cha["pos"] = pos
		cha["fei"] = float(cha["fei"]) + YU_CHA_SU_DU * delta
		if float(cha["fei"]) > YU_CHA_SHE_CHENG:
			continue
		if wan_jia != null and is_instance_valid(wan_jia) and wan_jia.zhuan_shu_pi_bi_dan_dao(pos):
			_cha_ming_zhong = true
			continue
		if wan_jia != null and is_instance_valid(wan_jia) \
				and pos.distance_to(wan_jia.global_position) <= YU_CHA_BAN_JING:
			var shang := (YU_CHA_SHANG_HAI + wan_jia.tixing * WAN_JIA_TI_XING_SHANG_HAI_BI) \
					* wan_jia.zhuan_shu_chuan_shang_hai_bei()
			wan_jia.shou_dao_yao_ji(shang, self)
			_cha_ming_zhong = true
			continue
		if _jing_sha_huo() and pos.distance_to(jing_sha.global_position) <= YU_CHA_BAN_JING * 2.0:
			jing_sha.shou_dao_yao_ji(YU_CHA_SHANG_HAI, self)
			_cha_ming_zhong = true
			continue
		huo_zhe.append(cha)
	_yu_chas = huo_zhe
	queue_redraw()


# —— 绘制（预警/范围提示） ——

func _draw() -> void:
	# 技能标记：声呐/猎手直觉/共生海葵选中船时，画一圈黄环（纯表现）
	if _gao_liang_sheng_yu > 0.0:
		draw_arc(Vector2.ZERO, chuan_ti_ban_jing() + 16.0, 0.0, TAU, 64, Color(1.0, 0.86, 0.3, 0.45), 4.0)
	if _qiang_suan_sheng_yu > 0.0:
		# 酸蚀：淡绿腐蚀环，提示 DoT 正在作用
		draw_arc(Vector2.ZERO, chuan_ti_ban_jing() + 8.0, 0.0, TAU, 64, Color(0.55, 1.0, 0.4, 0.30), 3.0)
	if _zha_dan_jin_xing:
		var dian := to_local(_zha_dan_dian)
		var jin_du := 1.0 - _zha_dan_sheng_yu / ZHA_DAN_YU_JING
		draw_circle(dian, ZHA_DAN_BAN_JING, Color(1.0, 0.45, 0.15, 0.08 + 0.12 * jin_du))
		draw_arc(dian, ZHA_DAN_BAN_JING, 0.0, TAU, 64, Color(1.0, 0.5, 0.15, 0.35 + 0.5 * jin_du), 4.0)
	if _zha_dan_bao_sheng_yu > 0.0:
		var dian := to_local(_zha_dan_dian)
		var a := _zha_dan_bao_sheng_yu / 0.35
		draw_circle(dian, ZHA_DAN_BAN_JING * (1.0 + 0.12 * (1.0 - a)), Color(1.0, 0.55, 0.1, 0.30 * a))
	if _mao_jin_xing:
		_hua_shan_xing(MAO_NEI_BAN_JING, MAO_WAI_BAN_JING, MAO_JIAO_DU, Color(1.0, 0.35, 0.25, 0.18))
	if _tan_zhao_jin_xing:
		var half := deg_to_rad(TAN_ZHAO_BAN_JIAO)
		var ji := _tan_zhao_fang.angle()
		var dian := PackedVector2Array([
			Vector2.ZERO,
			Vector2.RIGHT.rotated(ji - half) * TAN_ZHAO_CHANG,
			Vector2.RIGHT.rotated(ji + half) * TAN_ZHAO_CHANG,
		])
		draw_colored_polygon(dian, Color(1.0, 0.95, 0.55, 0.10))
		draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(ji - half) * TAN_ZHAO_CHANG, Color(1.0, 0.95, 0.55, 0.45), 2.0)
		draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(ji + half) * TAN_ZHAO_CHANG, Color(1.0, 0.95, 0.55, 0.45), 2.0)
	for cha in _yu_chas:
		var pos: Vector2 = cha["pos"]
		var fang: Vector2 = cha["fang"]
		draw_line(to_local(pos), to_local(pos - fang * 38.0), Color(0.9, 0.85, 0.6, 1.0), 6.0)


func _hua_shan_xing(nei: float, wai: float, jiao_du: float, yan_se: Color) -> void:
	# 扇形环：外弧正序 + 内弧倒序，闭合成一条带
	var ban := deg_to_rad(jiao_du) * 0.5
	var ji := _mao_fang.angle()
	var dian := PackedVector2Array()
	var fen := 20
	for i in range(fen + 1):
		var a := ji - ban + deg_to_rad(jiao_du) * float(i) / float(fen)
		dian.append(Vector2.RIGHT.rotated(a) * wai)
	for i in range(fen, -1, -1):
		var a := ji - ban + deg_to_rad(jiao_du) * float(i) / float(fen)
		dian.append(Vector2.RIGHT.rotated(a) * nei)
	draw_colored_polygon(dian, yan_se)
