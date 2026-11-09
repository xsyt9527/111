extends Resource
class_name XingTai
# 玩家形态数据模具：一个 .tres = 一种开局形态
# 只描述「下一局怎么开局」；解锁进度与当前选择由 CunDang 管，局内数值由 ZhangBen 管

@export var bian_hao: StringName = &""  # 唯一键：存档、选择页、测试都靠它
@export var ming_zi := ""  # 显示名（选择页卡片大字）
@export var miao_shu := ""  # 一句话说明（选择页卡片小字）
@export var ji_yu_bian_hao: StringName = &""  # 所属鱼种 id（对应 JinHua 分组）；空 = 与 bian_hao 相同
@export var pai_xu := 100  # 选择页排序：小在前；玩家 0、首领最大
@export var dong_hua: SpriteFrames = null  # 必须含 "you" 动画；4 帧游动动画
@export var tie_tu: Texture2D = null  # 选择页静态侧视预览（3 视图）；为空时退回动画首帧
@export var kai_ju_deng_ji := 0  # 开局等级（同时决定开局体型/血量上限）
@export var yi_dong_su_du := 300.0  # 初始移动速度（像素/秒）
@export var zui_ba := 1.0  # 初始嘴巴系数（咬击伤害倍率）
@export var zhuan_xiang_ji_su := 7.0  # 初始转向基准速率（弧度/秒）
@export var kai_ju_neng_li: NengLi = null  # 开局自带主动能力；null = 无
@export var jie_suo_sheng_li_ci_shu := 0  # 旧字段：累计胜利达到几次解锁（保留给旧数据/测试；D 起改用 jie_suo_fang_shi）
@export var jie_suo_fang_shi := "mian"  # D 解锁方式：mian=默认免费 / guang_gao=广告 / cheng_jiu=累计成就值 / tong_guan=累计通关（胜场）
@export var jie_suo_can_shu := 0  # 该方式的门槛数值：广告位暂不用；成就=累计成就值；通关=累计通关次数


func yu_zhong_bian_hao() -> StringName:
	# 当前形态归属的鱼种：决定 Lv.6 进化用哪一组三分支；旧数据没填则把自己当鱼种
	return ji_yu_bian_hao if ji_yu_bian_hao != &"" else bian_hao
