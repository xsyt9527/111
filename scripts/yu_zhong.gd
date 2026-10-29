extends Resource
class_name YuZhong
# 鱼种数据模具：一个 .tres 文件 = 鱼种表的一行
# 代码只定结构（有哪些字段），数值全存在数据文件里——加新鱼不改代码

@export var tie_tu: Texture2D  # 这种鱼长什么样
@export var dengji := 1  # 体型等级（1~10）：同时决定 NPC 的体型，玩家需高 1 级才能整吞
@export var sudu_fanwei := Vector2(60.0, 160.0)  # 游速随机范围（像素/秒）
@export var fenzhi := 1  # 吃掉它得多少分（TASK-005 经验记账用）
