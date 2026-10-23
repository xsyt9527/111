extends Resource
class_name QiangHuaKa
# 强化卡数据模具：一张 .tres = 卡池里的一张卡（与 YuZhong 同构，注册表模式复用）
# 效果字段（xiao_guo/shu_zhi）本课只存不用——第 7 课强化系统消费

@export var ming_zi := ""  # 卡名（按钮大字，如"迅捷"）
@export var miao_shu := ""  # 描述（按钮小字，如"游速 +15%"）
@export var xiao_guo := ""  # 效果类型键（第 7 课 switch 生效用）
@export var shu_zhi := 0.0  # 效果数值（如 0.15 = +15%）
