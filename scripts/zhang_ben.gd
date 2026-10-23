extends Node
# 游戏账本（Autoload 全局单例）：经验与等级的唯一所有者
# 先于一切场景就绪、切场景不销毁；任意脚本直接按名访问 ZhangBen

signal jing_yan_bian_hua(jing_yan: int, yuzhi: int)  # 经验变动：UI 刷新进度条
signal sheng_ji(xin_deng_ji: int)                    # 升级：玩家长大、（第 6 课）弹三选一

const SHENG_JI_YUZHI := [8, 20, 35, 55, 80, 110]  # 每级所需经验（第 6 课数据化）
const MEI_JI_TIXING := 0.2  # 每级体型增幅（只给玩家读）

var jing_yan := 0  # 当前经验（本级的，升级时扣掉已用部分）
var deng_ji := 1   # 当前等级


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
	# 满级后封顶：经验条停在最后一级阈值
	if deng_ji > SHENG_JI_YUZHI.size():
		return SHENG_JI_YUZHI[-1]
	return SHENG_JI_YUZHI[deng_ji - 1]
