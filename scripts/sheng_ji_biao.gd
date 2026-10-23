extends Resource
class_name ShengJiBiao
# 升级阈值表：改这张 .tres 即调升级曲线，零代码（TASK-005 常量数据化兑现）

@export var yuzhi_zu: Array[int] = [8, 20, 35, 55, 80, 110]  # 每级所需经验
