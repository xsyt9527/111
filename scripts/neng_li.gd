extends Resource
class_name NengLi
# 能力数据模具：一个 .tres = 一种鱼的能力（NPC 与玩家共用同一份定义）
# 同一份数据两处消费：玩家升级三选一拿它；NPC 用 npc_shu_zhi / npc_jian_ge 调自己的节奏

enum LeiXing { ZHU_DONG, BEI_DONG }  # 主动 / 被动

@export var bian_hao: StringName = &""  # 唯一键：账本计数、鱼种映射、技能分派都靠它
@export var ming_zi := ""  # 显示名（技能按钮/卡面大字）
@export var tu_biao: Texture2D = null  # 技能图标（Icon）；为空时 UI 回退纯文字，旧数据不用一次补齐
@export var miao_shu := ""  # 一句话说明（卡面小字）
@export var lai_yuan := ""  # 来源鱼名（只用于卡面显示，不参与逻辑）
@export var suoshu_xing_tai: StringName = &""  # 进化专属技归属的形态 id；空 = 通用/鱼种能力
@export var lei_xing := LeiXing.ZHU_DONG  # 主动（占唯一技能槽）/ 被动（可叠层）
@export var leng_que := 0.0  # 主动冷却（秒）；被动为 0
@export var chi_xu := 0.0  # 主动持续（秒）；0 = 瞬发
@export var ban_jing := 0.0  # 主动作用半径（世界像素基准）；单位由 ban_jing_shen_wei 决定，见下
@export var shu_zhi := 0.0  # 主数值：电麻量 / 反毒量 / 速度倍率 / 伤害倍率
@export var npc_shu_zhi := 0.0  # NPC 覆写主数值；0 = 回退 shu_zhi（电鳗 55 就是靠它）
@export var fu_shu_zhi := 0.0  # 副数值：冲撞的冲刺速度倍率
@export var npc_jian_ge := 0.0  # NPC 冷却（秒）：同一能力在 NPC 身上多久能用一次
@export var ceng_jia := 0.0  # 被动每层增量；主动为 0
@export var zui_da_dang := 3  # 最大档位：主动=升档上限（1 = 不可升档，装上即满）；被动=叠层上限
@export var dang_biao: Dictionary = {}  # 档位表：档号 -> {字段名: 值}；命中才覆写，缺省回退基础字段
# ---- 进化专属技扩展字段（2026-11-06，交接文档《进化专属技能被动》）----
@export var nei_bu_leng_que := 0.0  # 内部冷却（秒）：被动/触发技自己限频，0 = 无内部冷却
@export var mei_ju_ci_shu := 0  # 每局可用次数：0 = 不限（亡灵骨躯等「每局 N 次」用）
@export var lei_bie: Array[StringName] = []  # 分类标签：dian_xi/dan_dao/zhao_huan/wei_yi/yin_shen
@export var ban_jing_shen_wei := false  # true = ban_jing 以「身位」计（1 身位 = 本体贴图基准身长）
# TASK-019 单位口径：false 时 ban_jing 是世界像素基准，随玩家 scale 线性放大；
# true 时 ban_jing 是身位（×100×scale）；两者最终都在 Yu.ji_neng_ban_jing() 换算并套体长下限。
# 被动不参与这套技能范围换算，保持各自原有口径。


func shi_zhu_dong() -> bool:
	# 主动判定：UI 只给主动显示按钮，账本也按它决定占不占唯一槽
	return lei_xing == LeiXing.ZHU_DONG


func shi_zhuan_shu() -> bool:
	# 进化专属技：填了归属形态 id 就只认那一个形态，永不进通用池/成就兑换
	return suoshu_xing_tai != &""


func npc_zhi() -> float:
	# NPC 数值：有覆写用覆写，没覆写用主值——电鳗玩家 100 / NPC 55 就是这里分叉
	return npc_shu_zhi if npc_shu_zhi > 0.0 else shu_zhi


func ceng_shu_zhi(ceng: int) -> float:
	# 被动按层数结算：第 1 层就是主值，之后每层加 ceng_jia（毒棘 45 → 60 → 75）
	return shu_zhi + ceng_jia * float(maxi(0, ceng - 1))


func dang_zhi(jian: StringName, dang: int) -> float:
	# 档位取值：先查档位表覆写，没写就回退基础字段——满层/高档附加只写差异项
	# 基础字段不存在时按 0 算：档位表里可以造基础表没有的新键（如 yin_bi / zhui_jia）
	var biao: Dictionary = dang_biao.get(dang, {})
	if biao.has(jian):
		return float(biao[jian])
	var zhi = get(String(jian))
	return float(zhi) if zhi != null else 0.0
