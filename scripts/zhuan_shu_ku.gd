extends RefCounted
# 进化专属技模块分派（2026-11-09）：6 鱼种 × 3 分支 ×（1 主动 + 1 被动）= 36 条
# 分工原则：一个鱼种一个模块（scripts/zhuan_shu_ku/<yu_zhong>.gd），模块只碰自己的技能与数据，
# 不再把几十条新技能全塞进 yu.gd 的 match / _geng_xin_zhuan_shu——多人并行也不会抢同一个文件。
# 契约见 docs/专属技模块_开发契约.md；框架只做分派，数值/状态/召唤物全在模块里。

const MO_KU := [
	preload("res://scripts/zhuan_shu_ku/zong_yu.gd"),
	preload("res://scripts/zhuan_shu_ku/ye_deng_long_yu.gd"),
	preload("res://scripts/zhuan_shu_ku/fen_yu.gd"),
	preload("res://scripts/zhuan_shu_ku/ju_kou_yu.gd"),
	preload("res://scripts/zhuan_shu_ku/hong_yu.gd"),
	preload("res://scripts/zhuan_shu_ku/lan_yu.gd"),
]  # 固定清单：导出后资源路径会 remap，DirAccess 列目录不可靠


static func shi_fang(yu, neng: NengLi, dang: int) -> bool:
	# 主动释放：找到归属模块就交给它。成功才回 true——冷却/音效/虚影仍由 Yu.shi_fang_zhu_dong 统一收口
	for mo in MO_KU:
		if mo.call(&"guan_zhu_dong", neng.bian_hao):
			return bool(mo.call(&"shi_fang", yu, neng, dang))
	return false


static func _yi_zhuang(bian_hao: StringName, zhu_dong: bool) -> bool:
	# 装备判定：只有玩家真正装着的技能才参与每帧更新/事件/倍率查询。
	# 不能只看「资源存在」——全库技能资源永远存在，不判装备就会让 6 个鱼种的
	# 专属主动/被动同时生效（跨形态串味）。主动看主动槽，被动看叠层。
	if zhu_dong:
		return ZhangBen.zhuang_lei(bian_hao)
	return ZhangBen.dang_qian_bei_dong_ceng(bian_hao) > 0


static func geng_xin(yu, delta: float) -> void:
	# 每帧：对「已装备」的每个专属主动/被动都调一次；模块自己用 meta / 内部冷却管状态
	for mo in MO_KU:
		for bian in mo.call(&"zhu_dong_ids"):
			var zhu_dong: NengLi = ZhangBen.zhao_zhu_dong(bian)
			if zhu_dong != null and _yi_zhuang(bian, true):
				mo.call(&"geng_xin", yu, zhu_dong, delta)
		for bian in mo.call(&"bei_dong_ids"):
			var bei_dong: NengLi = ZhangBen.zhao_bei_dong(bian)
			if bei_dong != null and _yi_zhuang(bian, false):
				mo.call(&"geng_xin", yu, bei_dong, delta)


static func shi_jian(yu, jian: StringName, shu_ju: Dictionary = {}) -> bool:
	# 事件钩子：任一模块返回 true = 事件被吃掉（主流程立刻 return，例如闪避免伤）
	for mo in MO_KU:
		for bian in mo.call(&"zhu_dong_ids"):
			var zhu_dong: NengLi = ZhangBen.zhao_zhu_dong(bian)
			if zhu_dong != null and _yi_zhuang(bian, true) \
					and bool(mo.call(&"shi_jian", yu, zhu_dong, jian, shu_ju)):
				return true
		for bian in mo.call(&"bei_dong_ids"):
			var bei_dong: NengLi = ZhangBen.zhao_bei_dong(bian)
			if bei_dong != null and _yi_zhuang(bian, false) \
					and bool(mo.call(&"shi_jian", yu, bei_dong, jian, shu_ju)):
				return true
	return false


static func wen(yu, jian: StringName, shu_ju: Dictionary = {}) -> float:
	# 数值查询：所有已装备专属技的倍率连乘；一个都没装 = 1.0（主流程数值完全不变）
	var bei := 1.0
	for mo in MO_KU:
		for bian in mo.call(&"zhu_dong_ids"):
			var zhu_dong: NengLi = ZhangBen.zhao_zhu_dong(bian)
			if zhu_dong != null and _yi_zhuang(bian, true):
				bei *= float(mo.call(&"wen", yu, zhu_dong, jian, shu_ju))
		for bian in mo.call(&"bei_dong_ids"):
			var bei_dong: NengLi = ZhangBen.zhao_bei_dong(bian)
			if bei_dong != null and _yi_zhuang(bian, false):
				bei *= float(mo.call(&"wen", yu, bei_dong, jian, shu_ju))
	return bei
