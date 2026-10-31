extends Resource
class_name XingTai
# 玩家形态数据模具：一个 .tres = 一种开局形态
# 只描述「下一局怎么开局」；解锁进度与当前选择由 CunDang 管，局内数值由 ZhangBen 管

@export var bian_hao: StringName = &""  # 唯一键：存档、选择页、测试都靠它
@export var ming_zi := ""  # 显示名（选择页卡片大字）
@export var miao_shu := ""  # 一句话说明（选择页卡片小字）
@export var dong_hua: SpriteFrames = null  # 必须含 "you" 动画；4 帧游动动画
@export var tie_tu: Texture2D = null  # 选择页静态侧视预览（3 视图）；为空时退回动画首帧
@export var kai_ju_deng_ji := 0  # 开局等级（同时决定开局体型/血量上限）
@export var yi_dong_su_du := 300.0  # 初始移动速度（像素/秒）
@export var zui_ba := 1.0  # 初始嘴巴系数（咬击伤害倍率）
@export var zhuan_xiang_ji_su := 7.0  # 初始转向基准速率（弧度/秒）
@export var kai_ju_neng_li: NengLi = null  # 开局自带主动能力；null = 无
@export var jie_suo_sheng_li_ci_shu := 0  # 累计胜利达到几次解锁
