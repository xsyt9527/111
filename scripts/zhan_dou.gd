extends RefCounted
class_name ZhanDou
# 战斗数值唯一出口（策划案 8.1 / 8.4）：咬击伤害、致命区判定
# 玩家咬 NPC、NPC 咬玩家、NPC 咬 NPC 全走这两个函数——改数值只改这里
# 2026-11-08：A2 改为「掉对方当前体型 3%/口」；A4 致命区 ×3；一击必杀条件不变

const SHU_ZHI := preload("res://scripts/shu_zhi.gd")
const ZHI_MING_BEI_LV := 1.0  # 致命区一击必杀：攻击者体型 ≥ 被攻击者（策划案 8.1 原文）
# 旧公式只保留给「拿不到防御方体型」的调用方（机器船/测试兜底），船战节奏沿用旧口径
const JIU_SHANG_HAI_XI_SHU := 0.15
const JIU_SHANG_HAI_JI_CHU := 0.05


static func yao_ji_shang_hai(gong_ji_ti_xing: float, shou_ji_ti_xing := 0.0,
		zui_ba := 1.0) -> float:
	# A2：每口掉对方「当前体型」的 3%；zui_ba 是攻击者嘴巴系数
	# 第二参缺省 0：老调用方没传防御方体型时按攻击者体型估算（同体型近似等价）
	var dui_fang := shou_ji_ti_xing
	if dui_fang <= 0.0:
		dui_fang = gong_ji_ti_xing
	return maxf(SHU_ZHI.YAO_JI_ZUI_DI_SHANG_HAI,
			dui_fang * SHU_ZHI.YAO_JI_SHANG_HAI_BI * maxf(zui_ba, 0.0))


static func zhi_ming_shang_hai(gong_ji_ti_xing: float, shou_ji_ti_xing: float,
		zui_ba := 1.0) -> float:
	# A4：咬中致命区 = 普通咬 ×3；一击必杀另走 zhi_ming_ke_sha（条件不变）
	return yao_ji_shang_hai(gong_ji_ti_xing, shou_ji_ti_xing, zui_ba) * SHU_ZHI.ZHI_MING_SHANG_HAI_BEI


static func jiu_yao_ji_shang_hai(gong_ji_ti_xing: float, zui_ba := 1.0) -> float:
	# 旧公式：只给拿不到防御方体型的对象用（机器船血量/节奏按旧口径平衡）
	return (JIU_SHANG_HAI_XI_SHU * gong_ji_ti_xing + JIU_SHANG_HAI_JI_CHU) * maxf(zui_ba, 0.0)


static func zhi_ming_ke_sha(gong_ji_ti_xing: float, shou_ji_ti_xing: float) -> bool:
	# 致命区：攻击者体型 ≥ 被攻击者即可一击必杀（同级咬头也致命）
	return gong_ji_ti_xing >= shou_ji_ti_xing * ZHI_MING_BEI_LV
