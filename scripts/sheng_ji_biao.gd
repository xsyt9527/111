extends Resource
class_name ShengJiBiao
# 升级曲线：等级无上限，阈值 = 基础 × 增长率^等级（改这张 .tres 即调曲线，零代码）
# 固定数组表在高等级必然要用完；换成两个参数，等级再高也算得出来

@export var ji_chu := 10.0  # Lv.0 → Lv.1 所需经验
@export var zeng_zhang := 1.2  # 每级阈值倍率：10、12、14、17……
