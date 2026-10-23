extends Node
# 游戏账本（Autoload 全局单例）：经验与等级的唯一所有者
# 先于一切场景就绪、切场景不销毁；任意脚本直接按名访问 ZhangBen

signal jing_yan_bian_hua(jing_yan: int, yuzhi: int)  # 经验变动：UI 刷新进度条
signal sheng_ji(xin_deng_ji: int)                    # 升级：玩家长大、弹窗弹卡
signal ka_yi_xuan(ka: QiangHuaKa)                    # 选卡完成：第 7 课强化系统连接生效

const MEI_JI_TIXING := 0.2  # 每级体型增幅（只给玩家读）
var sheng_ji_biao := preload("res://data/shengji/sheng_ji_biao.tres")  # 升级阈值表（改表零代码调曲线，TASK-005 P3 兑现）

var jing_yan := 0  # 当前经验（本级的，升级时扣掉已用部分）
var deng_ji := 1   # 当前等级
var yi_xuan_ka: Array[QiangHuaKa] = []  # 本局已选强化卡（效果第 7 课生效）


func jia_jing_yan(fen: int) -> void:
	# 唯一记账入口：吃鱼经验都从这进账
	jing_yan += fen
	var yuzhi := dangqian_yuzhi()
	if jing_yan >= yuzhi:
		jing_yan -= yuzhi
		deng_ji += 1
		sheng_ji.emit(deng_ji)
	jing_yan_bian_hua.emit(jing_yan, dangqian_yuzhi())


func dangqian_yuzhi() -> int:
	# 满级后封顶：经验条停在最后一级阈值（阈值读表：sheng_ji_biao.tres）
	var yuzhi_zu := sheng_ji_biao.yuzhi_zu
	if deng_ji > yuzhi_zu.size():
		return yuzhi_zu[-1]
	return yuzhi_zu[deng_ji - 1]


func xuan_ka(ka: QiangHuaKa) -> void:
	# 选卡唯一入口：入账 + 广播（效果第 7 课在 ka_yi_xuan 回调里生效）
	yi_xuan_ka.append(ka)
	ka_yi_xuan.emit(ka)
