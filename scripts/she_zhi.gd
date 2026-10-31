extends CanvasLayer
# 设置面板（游戏内专用，挂在 Main 右上角）：暂停 / 继续 / 返回主界面并保存
# 主界面的"设置"是另一个面板（scripts/zhu_she_zhi.gd）：管音量与摇杆侧边，两者分工不同
# 打开面板即暂停全场：菜单期间世界必须冻结，否则点按钮的工夫玩家可能被咬死、饿死
# 根节点 process_mode=Always（与三选一弹窗同一套惯例）：暂停中按钮照点，
# 未暂停时右上角的"设置"入口也照点——WHEN_PAUSED 会让未暂停时点不动入口，不能那么设

var _ben_mian_zan_ting := false  # 暂停是否本面板所设：三选一弹窗先暂停时，"继续"只收面板、不解冻全场

@onready var she_zhi_an_niu: Button = $SheZhiAnNiu
@onready var mian_ban: PanelContainer = $SheZhiMianBan
@onready var zan_ting: Button = $SheZhiMianBan/MianBanLie/ZanTing
@onready var ji_xu: Button = $SheZhiMianBan/MianBanLie/JiXu
@onready var fan_hui: Button = $SheZhiMianBan/MianBanLie/FanHui


func _ready() -> void:
	mian_ban.visible = false  # 平时藏着：点"设置"才现身
	she_zhi_an_niu.pressed.connect(_on_she_zhi_an_niu)
	zan_ting.pressed.connect(_on_zan_ting_an_niu)
	ji_xu.pressed.connect(_on_ji_xu_an_niu)
	fan_hui.pressed.connect(_on_fan_hui_an_niu)


func _on_she_zhi_an_niu() -> void:
	# 打开面板即暂停：这是体验主路径，"暂停"按钮留给想明确操作一步的玩家
	YinXiang.fang(&"an_niu")
	_ben_mian_zan_ting = not get_tree().paused  # 打开前没暂停 → 这份暂停是本面板设的
	get_tree().paused = true
	mian_ban.visible = true


func _on_zan_ting_an_niu() -> void:
	# 暂停按钮：幂等——面板打开时通常已在暂停中，这里是明确的"停"语义（任务要求的独立按钮）
	YinXiang.fang(&"an_niu")
	_ben_mian_zan_ting = _ben_mian_zan_ting or not get_tree().paused
	get_tree().paused = true


func _on_ji_xu_an_niu() -> void:
	# 继续：收起面板；只有本面板设的暂停才解除——
	# 若三选一弹窗正冻结全场，解除暂停会让世界在选卡期间继续跑（鱼还在咬人），绝不能误开
	YinXiang.fang(&"an_niu")
	mian_ban.visible = false
	if _ben_mian_zan_ting:
		get_tree().paused = false
	_ben_mian_zan_ting = false


func _on_fan_hui_an_niu() -> void:
	# 返回主界面并保存：先写中途存档（此刻账本状态稳定），再解冻、切主界面
	# 写档失败（磁盘异常）也照切：回主界面总比卡死好，只是这一局没得继续
	YinXiang.fang(&"an_niu")
	CunDang.xie_zhong_tu()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ZhuJieMian.tscn")
