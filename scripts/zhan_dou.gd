extends RefCounted
class_name ZhanDou
# 战斗数值唯一出口（策划案 8.1 / 8.4）：咬击伤害、致命区判定
# 玩家咬 NPC、NPC 咬玩家、NPC 咬 NPC 全走这两个函数——改数值只改这里

const ZHI_MING_BEI_LV := 1.0  # 致命区：攻击者体型 ≥ 被攻击者（策划案 8.1 原文）
const SHANG_HAI_XI_SHU := 0.15  # 咬击伤害 =（0.15 × 攻击者体型 + 0.05）× 嘴巴系数
const SHANG_HAI_JI_CHU := 0.05


static func yao_ji_shang_hai(gong_ji_ti_xing: float, zui_ba := 1.0) -> float:
	# 咬一口掉多少体型：体型决定基础伤害，鱼种/玩家的“嘴巴”系数决定咬得多快
	return (SHANG_HAI_XI_SHU * gong_ji_ti_xing + SHANG_HAI_JI_CHU) * maxf(zui_ba, 0.0)


static func zhi_ming_ke_sha(gong_ji_ti_xing: float, shou_ji_ti_xing: float) -> bool:
	# 致命区：攻击者体型 ≥ 被攻击者即可一击必杀（同级咬头也致命）
	return gong_ji_ti_xing >= shou_ji_ti_xing * ZHI_MING_BEI_LV
