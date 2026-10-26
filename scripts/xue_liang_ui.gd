extends CanvasLayer
# 血条 UI：听玩家信号刷新（第 5 课"账本信号→经验条"同款模式，所有者换成玩家）
# 玩家经 "wan_jia" group 获取——不依赖节点路径，场景结构怎么改都不怕

@onready var tiao: ProgressBar = $XueLiangTiaoBg


func _ready() -> void:
	var yu := get_tree().get_first_node_in_group("wan_jia") as Yu
	if yu == null:
		push_warning("血条找不到玩家（wan_jia 组为空）")
		return
	tiao.max_value = yu.zuida_xue
	tiao.value = yu.xue_liang
	yu.xue_liang_bian_hua.connect(_on_xue_liang_bian_hua)


func _on_xue_liang_bian_hua(dangqian: int, zuigao: int) -> void:
	tiao.max_value = zuigao
	tiao.value = dangqian
