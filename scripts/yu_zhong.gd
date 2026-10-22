extends Resource
class_name YuZhong
# 鱼种数据模具：一个 .tres 文件 = 鱼种表的一行
# 代码只定结构（有哪些字段），数值全存在数据文件里——加新鱼不改代码

@export var tie_tu: Texture2D  # 这种鱼长什么样
@export var dengji := 1  # 鱼种等级（第 5 课成长/难度参考）
@export var tixing_fanwei := Vector2(0.6, 1.6)  # 体型系数随机范围
@export var sudu_fanwei := Vector2(60.0, 160.0)  # 游速随机范围（像素/秒）
@export var fenzhi := 1  # 吃掉它得多少分（TASK-005 经验记账用）
