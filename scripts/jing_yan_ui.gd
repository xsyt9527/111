extends CanvasLayer
# 经验条 UI：只管听账本信号刷新显示，不存任何状态

@onready var jindutiao: ProgressBar = $JingYanTiaoBg
@onready var dengji_label: Label = $DengJiLabel


func _ready() -> void:
	# 初始显示 + 连接账本两个信号（各一次）
	_shuaxin(ZhangBen.jing_yan, ZhangBen.dangqian_yuzhi(), ZhangBen.deng_ji)
	ZhangBen.jing_yan_bian_hua.connect(_on_jing_yan_bian_hua)
	ZhangBen.sheng_ji.connect(_on_sheng_ji)


func _on_jing_yan_bian_hua(jing_yan: int, yuzhi: int) -> void:
	# 经验变动：进度条跟随（max 换挡 + 当前值刷新）
	jindutiao.max_value = yuzhi
	jindutiao.value = jing_yan


func _on_sheng_ji(xin_deng_ji: int) -> void:
	# 升级：等级数字跳变（经验条清零由下一次 jing_yan_bian_hua 顺带完成）
	# 等级只升不降——受伤扣的是当前体型（血量），等级上限不动
	dengji_label.text = "Lv.%d" % xin_deng_ji


func _shuaxin(jing_yan: int, yuzhi: int, deng_ji: int) -> void:
	# 开局先画一次，避免 0 分时进度条空白、等级不显示
	jindutiao.max_value = yuzhi
	jindutiao.value = jing_yan
	dengji_label.text = "Lv.%d" % deng_ji
