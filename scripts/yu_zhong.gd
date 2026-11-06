extends Resource
class_name YuZhong
# 鱼种数据模具：一个 .tres 文件 = 鱼种表的一行
# 代码只定结构（有哪些字段），数值全存在数据文件里——加新鱼不改代码

@export var tie_tu: Texture2D  # 这种鱼的静态侧视贴图（3 视图里取的最宽那张）：红光层与兜底显示用
@export var dong_hua: SpriteFrames = null  # 4 帧游动动画（必须含 "you"）：NPC 用 AnimatedSprite2D 播放
@export var gong_ji_dong_hua: SpriteFrames = null  # 4 帧咬击动画（含 "gong"）：咬中时临时替换游动帧，播完切回
@export var dengji := 1  # 体型等级（1~10）：同时决定 NPC 的体型，玩家需高 1 级才能整吞
@export var sudu_fanwei := Vector2(60.0, 160.0)  # 游速随机范围（像素/秒）
@export var fenzhi := 1  # 吃掉它得多少分（TASK-005 经验记账用）
@export var zui_ba := 1.0  # 嘴巴系数：咬击伤害 =（0.15×体型+0.05）×嘴巴；决定“咬小大鱼”的快慢
@export var gan_zhi := 260.0  # 感知半径（像素）：发现猎物的距离，有的远有的近
@export var fan_ying_shi_jian := 0.8  # 反应时间（秒）：被偷袭身体后要懵多久才转头（0 = 立即反应；正面咬嘴不吃这项）
@export var gong_ji_yu_wang := true  # 攻击欲望：路人鱼设 false，其余鱼主动索敌（策划案 8.5）
@export var neng_li: NengLi = null  # 鱼种能力：吃掉它后，升级三选一里可能出现（TASK-014）
@export var shi_boss := false  # 首领：不参与普通鱼群刷新，被咬到残血才算击败（鲸鲨，TASK-017）
