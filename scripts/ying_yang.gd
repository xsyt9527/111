extends RefCounted
class_name YingYang
# 隐藏营养值系统·纯逻辑层（2026-11-20 设计提案·A 方案核心闭环）
# 职责：营养值 roll、满营养判定、经验乘算、满营养成长上限——全部是纯函数，不碰节点/时间/随机源注入。
# 用法：const YING_YANG := preload("res://scripts/ying_yang.gd")，再 YING_YANG.xxx()。
# 口径来自 shu_zhi.gd 常量表；随机源以参数注入（randf 由调用方给），便于无头测试喂固定值。
# 重要：营养只影响「经验」，不进体型成长与饥饿回复——两条收益线分开，防双乘算失控。

const SHU_ZHI := preload("res://scripts/shu_zhi.gd")


static func qu_jian(dang: int) -> Vector2:
	# 鱼种营养档 → 营养区间：1/2/3 档，越级夹到边界档（数据配置错也不崩）
	match clampi(dang, 1, 3):
		2:
			return SHU_ZHI.YING_YANG_DANG_2
		3:
			return SHU_ZHI.YING_YANG_DANG_3
		_:
			return SHU_ZHI.YING_YANG_DANG_1


static func roll_ying_yang(dang: int, suiji: float) -> float:
	# 刷新时一次 roll：在区间内按随机数线性取值（suiji ∈ [0,1]）
	# 下限再兜一层 SHU_ZHI.YING_YANG_XIA_XIAN，杜绝 0 或负数的「白吃」
	var qu := qu_jian(dang)
	var zhi := lerpf(qu.x, qu.y, clampf(suiji, 0.0, 1.0))
	return maxf(zhi, SHU_ZHI.YING_YANG_XIA_XIAN)


static func shi_man_yang(suiji: float) -> bool:
	# 满营养判定：全局统一概率（默认 3%），与鱼种档无关
	return suiji < SHU_ZHI.MAN_YANG_GE_LV


static func man_yang_ying_yang(dang: int) -> float:
	# 满营养鱼的营养值 = 该档上限 ×1.33（≈1.6~2.1，一口顶两条半）
	return qu_jian(dang).y * SHU_ZHI.MAN_YANG_BEI


static func jing_yan_cheng_shu(jichu_fen: int, ying_yang: float) -> int:
	# 玩家吃鱼经验 = 基础经验 × 对方营养值（提案 3.3 唯一乘算点）
	# 四舍五入后至少 1 点（基础经验 >0 时），避免 floor 把小鱼吃成 0
	if jichu_fen <= 0:
		return 0
	return maxi(1, int(round(float(jichu_fen) * maxf(ying_yang, SHU_ZHI.YING_YANG_XIA_XIAN))))


static func shi_gao_ying_yang(dang: int, ying_yang: float) -> bool:
	# 半隐藏信号·高营养档：营养值落在区间上 1/3 → 体色更饱满发亮
	var qu := qu_jian(dang)
	var yu_zhi := lerpf(qu.x, qu.y, 1.0 - SHU_ZHI.GAO_YING_YANG_BI_LI)
	return ying_yang >= yu_zhi


static func man_yang_cheng_zhang_shang_xian(wan_jia_deng_ji: int) -> int:
	# 满营养鱼成长上限 = min(玩家当前等级 + 4, 绝对上限 6)
	# 玩家等级越高威胁可以越大，但封顶 6 级杜绝超模鱼
	return mini(wan_jia_deng_ji + 4, SHU_ZHI.MAN_YANG_DENG_JI_SHANG_XIAN)


static func ke_cheng_zhang(dang_qian_deng: int, wan_jia_deng_ji: int,
		ju_nei_shi_jian: float) -> bool:
	# 满营养鱼本拍是否可成长：开局 120 秒冻结 + 未到成长上限
	if ju_nei_shi_jian < SHU_ZHI.MAN_YANG_DONG_JIE_SHI_JIAN:
		return false
	return float(dang_qian_deng) < float(man_yang_cheng_zhang_shang_xian(wan_jia_deng_ji))


# ===== A 方案剩余机制纯函数（提案 3.2/3.6/4A）=====

static func chu_sheng_deng_ji(shi_boss: bool) -> int:
	# 出生锁 1 级：普通 NPC 全部 1 级出生；首领（鲸鲨 shi_boss）保留鱼种等级（A13 不变）
	# 鱼种 dengji 此后只用于「解锁进度 + 图鉴」，不再是出生体型
	return SHU_ZHI.CHU_SHENG_DENG_JI if not shi_boss else -1  # -1 = 调用方保留鱼种原等级


static func man_yang_tong_ping_ke_sheng(xian_you_man_yang_shu: int) -> bool:
	# 同屏满营养唯一：已有满营养成长鱼 ≥ 上限时，新 roll 不生效（提案 3.2）
	return xian_you_man_yang_shu < SHU_ZHI.MAN_YANG_TONG_PING_SHANG_XIAN


static func gai_lv_man_yang(jia_ping_qi: bool) -> float:
	# A11 加压期高营养 roll 概率：3% 起步，加压期抬到 8%（提案 4A）
	return SHU_ZHI.GAO_YING_YANG_ZHUAN_XIAN_GE_LV if jia_ping_qi else SHU_ZHI.MAN_YANG_GE_LV


static func hu_chi_cheng_zhang_lian(dui_fang_deng_ji: int) -> float:
	# A14 互吃成长：吞掉对方等级 ×0.5（提案 3.2）
	return maxf(0.0, float(dui_fang_deng_ji)) * SHU_ZHI.HU_CHI_CHENG_ZHANG_BEI


static func an_chi_deng_ji_shang_xian(ju_nei_miao: float) -> int:
	# 暗池区域等级上限 = min(4 + 局内分钟数, 6)；随时间走，不挂玩家等级（提案 3.6）
	var fen_zhong := maxf(0.0, ju_nei_miao) / 60.0
	return mini(SHU_ZHI.AN_CHI_DENG_JI_SHANG_XIAN_JI_CHU + int(floor(fen_zhong)),
			SHU_ZHI.AN_CHI_DENG_JI_SHANG_XIAN_FENG)


static func an_chi_cheng_zhang_liang(suo_duan: int) -> float:
	# 暗池每 30 秒平均等级增量：普通 +0.3；A11 水域收缩阶段 ×1.2 / ×1.5（提案 3.6）
	var xi_shu := 1.0
	match clampi(suo_duan, 0, 2):
		1:
			xi_shu = SHU_ZHI.AN_CHI_SHOU_SUO_XI_SHU_1
		2:
			xi_shu = SHU_ZHI.AN_CHI_SHOU_SUO_XI_SHU_2
	return SHU_ZHI.AN_CHI_PING_JUN_CHENG_ZHANG * xi_shu
