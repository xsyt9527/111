extends Resource
class_name JinHua
# 进化形态数据模具：一个 .tres = 一种进化分支（11 鱼种 × 3 分支 = 33 份）
# 只描述「进化成什么」；局内何时进化/数值怎么乘由 ZhangBen 管，图鉴只读这里

enum FenZhi { DONG_FANG, XI_FANG, YI_HUA }  # 分支语义：东方神话（神话演出）/ 西方神话（霸体压制）/ 能力异化（机制改写）

@export var bian_hao: StringName = &""  # 唯一键：存档、图鉴、测试都靠它
@export var ming_zi := ""  # 进化形态名（图鉴卡大字 / 进化弹窗大字）
@export var ji_yu_bian_hao: StringName = &""  # 所属基础鱼种 id（与 data/yuzhong 文件名一致）：图鉴按它分组
@export var ji_yu_ming := ""  # 基础鱼种显示名（卡面小字：这是谁的进化）
@export var fen_zhi := FenZhi.DONG_FANG  # 三分支之一
@export var miao_shu := ""  # 形态设定（策划案第十章原文）
@export var tie_tu: Texture2D = null  # 进化形态静态侧视贴图（图鉴卡 + 游泳帧到位前的游戏内外观）
@export var dong_hua: SpriteFrames = null  # 4 帧游泳动画（含 "you"）；为空 = 用 tie_tu 单帧兜底
@export var gong_ji_dong_hua: SpriteFrames = null  # 4 帧攻击动画（含 "gong"）；待美术补帧后填
@export var wan_jia_ke_yong := false  # 试玩版只有玩家凹凸蜗牛鱼 3 分支可选；NPC 分支只进图鉴
@export var shu_zhi_bei := 1.5  # 进化基础倍率：所有数值 ×1.5（策划案 8.6 拍板）
@export var zhuan_shu_zhu_dong: NengLi = null  # 专属主动技（内容待定：留槽位，填表即用，不进升级池）
@export var zhuan_shu_bei_dong: NengLi = null  # 专属被动（内容待定：同上）


func fen_zhi_ming() -> String:
	# 分支中文名：图鉴/弹窗/测试共用一份，避免三处各写一套字符串
	match fen_zhi:
		FenZhi.DONG_FANG:
			return "东方神话"
		FenZhi.XI_FANG:
			return "西方神话"
		_:
			return "能力异化"


func fen_zhi_se() -> Color:
	# 分支配色（UI 文字/描边）：东方金 / 西方紫 / 异化青——弹窗、图鉴共用一份
	match fen_zhi:
		FenZhi.DONG_FANG:
			return Color(1.0, 0.82, 0.45)
		FenZhi.XI_FANG:
			return Color(0.85, 0.72, 1.0)
		_:
			return Color(0.55, 0.95, 1.0)


func fen_zhi_guang_se() -> Color:
	# 全屏光效色（进化演出）：比文字色更饱和/带透明度，白闪之后铺满屏再淡出
	match fen_zhi:
		FenZhi.DONG_FANG:
			return Color(1.0, 0.72, 0.2, 0.5)
		FenZhi.XI_FANG:
			return Color(0.55, 0.28, 0.85, 0.5)
		_:
			return Color(0.35, 0.9, 1.0, 0.5)
