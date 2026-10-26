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
var jing_yan_jia_cheng := 1.0  # 经验加成倍率（睿智卡生效；bei_chi 记账时乘算）


func she_jing_yan_jia_cheng(bei: float) -> void:
	# 睿智卡唯一入口：倍率的唯一所有者仍是账本（玩家不私自存倍率）
	jing_yan_jia_cheng = bei


func jia_jing_yan(fen: int) -> void:
	# 唯一记账入口：吃鱼经验都从这进账
	# 满级封顶（设计决策 2A）：已达表尾等级（Lv.7）后经验钉在满格，不升级不发 sheng_ji
	# ——数据表有尽头，读表方必须处理表外等级；封顶是设计决策不是默认行为
	if deng_ji > sheng_ji_biao.yuzhi_zu.size():
		jing_yan = dangqian_yuzhi()  # 钉在满格（表尾阈值）
		jing_yan_bian_hua.emit(jing_yan, dangqian_yuzhi())  # 只刷条，不广播升级
		return
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


func chong_zhi() -> void:
	# 局内状态归零唯一入口（重开时用）：账本是 Autoload 常驻——谁常驻谁负责自己的复位
	# 场景侧（玩家 buff/血量/鱼群）随 Main 销毁重建自动全新，只有这里需要手动清
	jing_yan = 0
	deng_ji = 1
	yi_xuan_ka.clear()
	jing_yan_jia_cheng = 1.0


func xuan_ka(ka: QiangHuaKa) -> void:
	# 选卡唯一入口：入账 + 广播（效果第 7 课在 ka_yi_xuan 回调里生效）
	yi_xuan_ka.append(ka)
	ka_yi_xuan.emit(ka)
