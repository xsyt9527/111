extends Node
# 测试替身：只实现 CunDang.ying_yong_yong_jiu 需要的三件套（鸭子类型）
# 为什么不用真 ZhangBen：--script 模式不加载 Autoload，账本脚本在编译期就找不到 YinXiang

var zhu_dong: Array[StringName] = []
var bei_dong: Dictionary = {}


func zhuang_lei(bian_hao: StringName) -> bool:
	return zhu_dong.has(bian_hao)


func dang_qian_bei_dong_ceng(bian_hao: StringName) -> int:
	return int(bei_dong.get(bian_hao, 0))


func xuan_neng_li(neng: NengLi) -> void:
	if neng == null:
		return
	if neng.shi_zhu_dong():
		if not zhu_dong.has(neng.bian_hao):
			zhu_dong.append(neng.bian_hao)
	else:
		bei_dong[neng.bian_hao] = dang_qian_bei_dong_ceng(neng.bian_hao) + 1
