extends SceneTree
# 账本纯逻辑测试（第 9 课 step-01 测试基建）
# 运行方式：Godot --headless --path . --script tests/ce_zhang_ben.gd
# --script 模式不加载 Autoload，被测账本不走全局 ZhangBen，
# 而是 load().new() 建独立实例——每个用例都从干净状态开始（测试独立性）。
# 纪律：全程禁用裸 assert()——失败会中断脚本，quit() 永不执行，进程挂死。
# 架构：等级 = 体型上限（只升不降）；当前体型 = 血量（受伤扣、吃东西回）

var passed := 0  # 通过计数（收卷用）
var failed := 0  # 失败计数（退出码的依据）
var si_wang_ci := 0  # si_wang 广播计数（死亡只报一次）
var jie_suan_ci := 0  # ju_jie_shu 广播计数（结局只写一次）
var jie_duan_ci := 0  # jie_duan_gai_bian 广播计数（阶段只切一次）
var zhuang_bei_ci := 0  # neng_li_zhuang_bei 广播计数（能力装备/叠层）
var zhuang_bei_ming: StringName = &""  # 最近一次广播的能力 id
var zhuang_bei_ceng := 0  # 最近一次广播的层数
var sheng_ji_ci := 0  # sheng_ji 广播计数（形态开局不得触发三选一）


func _initialize() -> void:
	# ---- 用例 1：记账累加（不跨阈值，只加不升）----
	var zb: Node = load("res://scripts/zhang_ben.gd").new()  # load() 返回 Variant，必须显式类型标注
	zb.jia_jing_yan(2)
	zb.jia_jing_yan(1)
	assert_eq(zb.jing_yan, 3, "记账累加：2+1 应为 3")
	assert_eq(zb.deng_ji, 0, "开局 Lv.0，未跨阈值 4 不应升级")
	zb.free()  # 不入树的实例用完即弃，避免退出时报资源占用

	# ---- 用例 1b：调试「测试升级」每次恰好一级（清余量，不连升）----
	var zb_dbg: Node = load("res://scripts/zhang_ben.gd").new()
	zb_dbg.jing_yan = 7  # 故意留余量：调试按钮应清掉它，而不是 7+阈值一次连升
	zb_dbg.tiao_shi_sheng_yi_ji()
	assert_eq(zb_dbg.deng_ji, 1, "测试升级：Lv.0 → Lv.1")
	assert_eq(zb_dbg.jing_yan, 0, "测试升级清空本级余量")
	zb_dbg.tiao_shi_sheng_yi_ji()
	assert_eq(zb_dbg.deng_ji, 2, "测试升级：再点一次 → Lv.2")
	assert_eq(zb_dbg.jing_yan, 0, "第二次测试升级仍只升一级")
	zb_dbg.free()

	# ---- 用例 2：跨级升级扣减（余量带入下一级）----
	var zb2: Node = load("res://scripts/zhang_ben.gd").new()
	zb2.jia_jing_yan(13)  # Lv.0 阈值 10：13-10=3，余量带入 Lv.1
	assert_eq(zb2.deng_ji, 1, "灌 13 过阈值 10 应升到 Lv.1")
	assert_eq(zb2.jing_yan, 3, "升级应扣掉已用阈值（13-10=3）")
	zb2.jia_jing_yan(11)  # 3+11=14 过 Lv.1 阈值 12：14-12=2
	assert_eq(zb2.deng_ji, 2, "余 3 再灌 11 过阈值 12 应升到 Lv.2")
	assert_eq(zb2.jing_yan, 2, "扣减后余量 14-12=2")
	assert_float(zb2.dang_qian_ti_xing, 3.0, "升级回满血：Lv.2 上限 = 2+1 = 3.0")
	zb2.free()  # 不入树的实例用完即弃，避免退出时报资源占用

	# ---- 用例 3：能力账本（主动多槽共存 / 被动叠层 / 食谱计数 / 平局 / 复位）----
	var zb3: Node = load("res://scripts/zhang_ben.gd").new()
	var fang_dian: NengLi = load("res://data/nengli/fang_dian_ma_bi.tres")
	var du_ji: NengLi = load("res://data/nengli/du_ji_hu_ti.tres")
	var ji_su: NengLi = load("res://data/nengli/ji_su_tu_jin.tres")
	assert_eq(1 if fang_dian != null and du_ji != null and ji_su != null else 0, 1,
			"能力资源应能加载（账本用例的前置）")
	zhuang_bei_ci = 0
	zb3.neng_li_zhuang_bei.connect(_shu_neng_li)
	zb3.xuan_neng_li(fang_dian)  # 第一个主动
	assert_eq(1 if zb3.zhu_dong_zu.size() == 1 and zb3.zhu_dong_zu[0] == fang_dian else 0, 1,
			"选主动：进入主动组（多槽）")
	assert_eq(zhuang_bei_ci, 1, "主动装备应广播 neng_li_zhuang_bei 一次")
	assert_string(String(zhuang_bei_ming), "fang_dian_ma_bi", "广播里的能力 id 应为放电麻痹")
	assert_eq(zhuang_bei_ceng, 1, "主动广播层数固定为 1")
	zb3.xuan_neng_li(ji_su)  # 第二个主动：共存（多槽不替换）
	assert_eq(zb3.zhu_dong_zu.size(), 2, "再选主动：与第一个共存（唯一槽已退役）")
	assert_eq(1 if zb3.zhuang_lei(&"fang_dian_ma_bi") else 0, 1, "旧主动还在组里：不残留应消失")
	assert_eq(1 if zb3.zhuang_lei(&"ji_su_tu_jin") else 0, 1, "新主动也在组里")
	assert_eq(zhuang_bei_ci, 2, "再装备也应广播（每入槽一次）")
	assert_eq(zb3.yi_xuan_neng_li.size(), 2, "本局获得历史应记 2 次")
	zb3.xuan_neng_li(du_ji)  # 被动第 1 层
	assert_eq(zb3.dang_qian_bei_dong_ceng(&"du_ji_hu_ti"), 1, "被动第一次选：1 层")
	assert_eq(zhuang_bei_ceng, 1, "被动广播层数 1")
	zb3.xuan_neng_li(du_ji)  # 被动第 2 层
	assert_eq(zb3.dang_qian_bei_dong_ceng(&"du_ji_hu_ti"), 2, "被动再选：叠到 2 层")
	assert_eq(zhuang_bei_ceng, 2, "被动广播层数 2")
	assert_eq(zb3.dang_qian_bei_dong_ceng(&"ji_su_tu_jin"), 0, "没选过的被动层数为 0")
	assert_eq(zb3.yi_xuan_neng_li.size(), 4, "历史共 4 次选择（2 主动 + 2 被动）")
	# 防重复入槽：已装备的主动再选一次按无操作处理（不广播、不进历史、不涨槽数）
	zb3.xuan_neng_li(fang_dian)
	assert_eq(zb3.zhu_dong_zu.size(), 2, "重复装备同 id 主动：槽数不涨")
	assert_eq(zhuang_bei_ci, 4, "重复装备不广播")
	assert_eq(zb3.yi_xuan_neng_li.size(), 4, "重复装备不进历史")
	assert_eq(1 if zb3.zhao_zhu_dong(&"fang_dian_ma_bi") == fang_dian else 0, 1,
			"zhao_zhu_dong 按id反查：装备着的能查到")
	assert_eq(1 if zb3.zhao_zhu_dong(&"du_ji_hu_ti") == null else 0, 1,
			"zhao_zhu_dong 查不在组的 id 返回 null")
	# 食谱计数：只有消化完成才记；平局保留先到者
	zb3.ji_chi_yu(du_ji)
	assert_eq(int(zb3.chi_yu_ji_lu.get(&"du_ji_hu_ti", 0)), 1, "吃一条蓑鲉：食谱记 1")
	assert_string(String(zb3.zui_duo_bian_hao), "du_ji_hu_ti", "第一条被吃的鱼成为最常吃")
	zb3.ji_chi_yu(fang_dian)
	assert_string(String(zb3.zui_duo_bian_hao), "du_ji_hu_ti", "平局 1:1 保留先到者")
	zb3.ji_chi_yu(du_ji)
	assert_eq(int(zb3.chi_yu_ji_lu.get(&"du_ji_hu_ti", 0)), 2, "再吃一条蓑鲉：记 2")
	zb3.ji_chi_yu(fang_dian)
	assert_string(String(zb3.zui_duo_bian_hao), "du_ji_hu_ti", "2:2 仍是平局：最常吃不换人")
	zb3.ji_chi_yu(null)  # 没能力鱼不计数
	assert_eq(zb3.chi_yu_ji_lu.size(), 2, "空能力不进食谱")
	# 复位：能力容器全空
	zb3.chong_zhi()
	assert_eq(1 if zb3.zhu_dong_zu.is_empty() else 0, 1, "复位后主动组清空")
	assert_eq(zb3.bei_dong_ceng.size(), 0, "复位后被层数清空")
	assert_eq(zb3.yi_xuan_neng_li.size(), 0, "复位后获得历史清空")
	assert_eq(zb3.chi_yu_ji_lu.size(), 0, "复位后食谱清空")
	assert_string(String(zb3.zui_duo_bian_hao), "", "复位后最常吃 id 清空")
	zb3.free()  # 不入树的实例用完即弃，避免退出时报资源占用

	# ---- 用例 4：阈值曲线（10 × 1.2^等级，等级无上限也算得出）----
	var zb4: Node = load("res://scripts/zhang_ben.gd").new()
	assert_eq(zb4.dangqian_yuzhi(), 10, "Lv.0 阈值 = 10 × 1.2^0 = 10")
	zb4.deng_ji = 1  # 直接设等级，单测曲线这一件事
	assert_eq(zb4.dangqian_yuzhi(), 12, "Lv.1 阈值 = 10 × 1.2 = 12")
	zb4.deng_ji = 7
	assert_eq(zb4.dangqian_yuzhi(), 36, "Lv.7 阈值 ≈ 35.8，向上取整 36")
	zb4.deng_ji = 9
	assert_eq(zb4.dangqian_yuzhi(), 52, "Lv.9 阈值 ≈ 51.6 → 52：越过旧上限仍有值")
	zb4.deng_ji = 20
	assert_eq(zb4.dangqian_yuzhi(), 384, "Lv.20 阈值 ≈ 383.4 → 384：固定表早就不够，曲线继续算")
	zb4.free()  # 不入树的实例用完即弃，避免退出时报资源占用

	# ---- 用例 5：体型上限 = 等级 + 1 ----
	var zb5: Node = load("res://scripts/zhang_ben.gd").new()
	assert_float(zb5.ti_xing_shang_xian(), 1.0, "Lv.0 上限 = 基础 1.0（0 级也要能玩）")
	assert_float(zb5.dang_qian_ti_xing, 1.0, "开局满血")
	zb5.deng_ji = 8
	assert_float(zb5.ti_xing_shang_xian(), 9.0, "满级 Lv.8 上限 = 8+1 = 9.0")
	zb5.free()

	# ---- 用例 6：受伤扣当前体型（血量），不动等级上限 ----
	var zb6: Node = load("res://scripts/zhang_ben.gd").new()
	zb6.si_wang.connect(_shu_si_wang)
	zb6.shou_shang()  # Lv.0 血量 1.0 - 1.0 = 0
	assert_float(zb6.dang_qian_ti_xing, 0.0, "Lv.0 挨一次扣 1.0 → 血量归零")
	assert_eq(zb6.deng_ji, 0, "受伤只扣血量，等级上限不动")
	assert_eq(si_wang_ci, 1, "血量归零应广播 si_wang 一次")
	zb6.shou_shang()  # 已死再挨打
	assert_eq(si_wang_ci, 1, "已归零后不重复广播 si_wang")
	assert_eq(int(zb6.dang_qian_ti_xing * 10.0), 0, "已归零后也不会扣成负数")
	zb6.free()

	# ---- 用例 7：回血（吃东西回，封顶在上限）----
	var zb7: Node = load("res://scripts/zhang_ben.gd").new()
	zb7.deng_ji = 5
	zb7.dang_qian_ti_xing = 6.0
	zb7.shou_shang()  # 6.0 - 1.0 = 5.0
	assert_float(zb7.dang_qian_ti_xing, 5.0, "Lv.5 受伤扣 1.0：6.0 → 5.0")
	assert_eq(zb7.deng_ji, 5, "受伤不降级")
	zb7.hui_ti_xing(0.25)  # 吃食物
	assert_float(zb7.dang_qian_ti_xing, 5.25, "吃食物回 0.25：5.0 → 5.25")
	zb7.hui_ti_xing(99.0)  # 灌一大口
	assert_float(zb7.dang_qian_ti_xing, 6.0, "回血封顶在当前等级上限（5+1=6.0）")
	zb7.free()

	# ---- 用例 8：饥饿下降与回饥饿（封顶 100）----
	var zb8: Node = load("res://scripts/zhang_ben.gd").new()
	assert_float(zb8.ji_e, 100.0, "开局饥饿满格 100")
	zb8.xia_jiang_ji_e(2.0)
	assert_float(zb8.ji_e, 90.0, "饥饿每秒降 5.0：2 秒后 90")
	zb8.hui_ji_e(10.0)
	assert_float(zb8.ji_e, 100.0, "吃一口回 10，封顶 100")
	zb8.ji_e = 50.0
	zb8.hui_ji_e(10.0)
	assert_float(zb8.ji_e, 60.0, "半饱吃一口：50 → 60")
	zb8.free()

	# ---- 用例 9：饥饿归零 → 每秒扣 0.1 当前体型，扣到 0 广播死亡 ----
	var zb9: Node = load("res://scripts/zhang_ben.gd").new()
	si_wang_ci = 0
	zb9.si_wang.connect(_shu_si_wang)
	zb9.ji_e = 0.0
	zb9.xia_jiang_ji_e(0.5)
	assert_float(zb9.dang_qian_ti_xing, 1.0, "归零不足 1 秒：先不扣体型")
	zb9.xia_jiang_ji_e(0.5)
	assert_float(zb9.dang_qian_ti_xing, 0.9, "归零满 1 秒：扣 0.1 当前体型")
	assert_eq(zb9.deng_ji, 0, "饿死也不掉等级")
	zb9.hui_ji_e(10.0)  # 吃一口，脱离饥饿
	zb9.ji_e = 0.0  # 再饿回去：计时器应已清零
	zb9.xia_jiang_ji_e(0.5)
	assert_float(zb9.dang_qian_ti_xing, 0.9, "吃东西后饿死计时重新攒：0.5 秒不扣")
	zb9.xia_jiang_ji_e(0.5)
	assert_float(zb9.dang_qian_ti_xing, 0.8, "重新攒满 1 秒才扣")
	zb9.dang_qian_ti_xing = 0.1  # 只剩最后一丝
	zb9.xia_jiang_ji_e(1.0)
	assert_float(zb9.dang_qian_ti_xing, 0.0, "饥饿扣到 0：死亡")
	assert_eq(si_wang_ci, 1, "饿死应广播 si_wang 一次")
	assert_eq(1 if not zb9.sheng_cun_zhong else 0, 1, "死亡后饥饿时钟停止")
	zb9.xia_jiang_ji_e(5.0)
	assert_float(zb9.dang_qian_ti_xing, 0.0, "死后不再扣体型")
	zb9.free()

	# ---- 用例 10：吃鱼回饥饿的档位（路人鱼 10 / 普通 8 / 鲸鲨 30）----
	var zb10: Node = load("res://scripts/zhang_ben.gd").new()
	assert_float(zb10.chi_yu_hui_ji_e(1), 10.0, "路人鱼（1 级）回 10 饥饿")
	assert_float(zb10.chi_yu_hui_ji_e(5), 8.0, "普通鱼回 8 饥饿")
	assert_float(zb10.chi_yu_hui_ji_e(10), 30.0, "鲸鲨回 30 饥饿")
	zb10.free()

	# ---- 用例 11：体型→像素曲线（等级无上限：高等级不能再线性放大）----
	var zb11: Node = load("res://scripts/zhang_ben.gd").new()
	assert_float(zb11.ti_xing_dao_chi_du(1.0), 0.32, "Lv.0（体型 1）显示缩放仍是 0.32")
	assert_eq(1 if zb11.ti_xing_dao_chi_du(9.0) < 9.0 * 0.32 else 0, 1, "高等级显示增长必须小于线性（否则 8 级撑爆屏幕）")
	assert_eq(1 if zb11.ti_xing_dao_chi_du(9.0) > zb11.ti_xing_dao_chi_du(8.0) else 0, 1, "曲线仍单调：体型越大看起来越大")
	zb11.free()

	# ---- 用例 12：局内时钟与阶段切换（480 秒人类战）----
	var zb12: Node = load("res://scripts/zhang_ben.gd").new()
	jie_duan_ci = 0
	zb12.jie_duan_gai_bian.connect(_shu_jie_duan)
	assert_float(zb12.sheng_yu_shi_jian(), 600.0, "开局剩余 600 秒")
	zb12.zou_ju_shi_jian(479.9)
	assert_eq(zb12.jie_duan, 0, "479.9 秒仍在正常生态期")
	assert_float(zb12.ju_nei_shi_jian, 479.9, "时钟按 delta 累加")
	zb12.zou_ju_shi_jian(0.2)
	assert_eq(zb12.jie_duan, 1, "跨过 480 秒进入人类战")
	assert_eq(jie_duan_ci, 1, "阶段切换广播一次")
	assert_float(zb12.sheng_yu_shi_jian(), 119.9, "剩余时间同步减少")
	zb12.zou_ju_shi_jian(1.0)
	assert_eq(jie_duan_ci, 1, "同一阶段不重复广播")
	zb12.free()

	# ---- 用例 13：10 分钟强制判负，结局只写一次 ----
	var zb13: Node = load("res://scripts/zhang_ben.gd").new()
	jie_suan_ci = 0
	zb13.ju_jie_shu.connect(_shu_jie_suan)
	zb13.zou_ju_shi_jian(599.9)
	assert_eq(zb13.jie_ju, 0, "599.9 秒仍未定胜负")
	assert_eq(jie_suan_ci, 0, "未到 600 秒不结算")
	zb13.zou_ju_shi_jian(0.2)
	assert_eq(zb13.jie_ju, 2, "到 600 秒判负（SHI_BAI）")
	assert_eq(jie_suan_ci, 1, "结算广播一次")
	assert_eq(1 if not zb13.sheng_cun_zhong else 0, 1, "结算后停表")
	zb13.zou_ju_shi_jian(10.0)
	zb13.ding_jie_suan(1)  # 想在失败后再写胜利：不许
	assert_eq(jie_suan_ci, 1, "结局只写一次：超时后不再被改写")
	assert_eq(zb13.jie_ju, 2, "失败仍是失败")
	zb13.free()

	# ---- 用例 14：鲸鲨提前开战（8 分钟前 + Lv.5）----
	var zb14: Node = load("res://scripts/zhang_ben.gd").new()
	jie_duan_ci = 0
	zb14.jie_duan_gai_bian.connect(_shu_jie_duan)
	zb14.ju_nei_shi_jian = 300.0
	zb14.deng_ji = 4
	assert_eq(int(zb14.ti_qian_kai_zhan()), 0, "Lv.4 不够格：船不提前来")
	assert_eq(zb14.jie_duan, 0, "没开战，阶段不变")
	zb14.deng_ji = 5
	assert_eq(int(zb14.ti_qian_kai_zhan()), 1, "Lv.5 + 8 分钟内：提前开战")
	assert_eq(zb14.jie_duan, 1, "阶段切到人类战")
	assert_eq(jie_duan_ci, 1, "提前开战只广播一次")
	assert_eq(int(zb14.ti_qian_kai_zhan()), 0, "已经开战，不能再触发")
	zb14.free()

	var zb14b: Node = load("res://scripts/zhang_ben.gd").new()
	zb14b.deng_ji = 9
	zb14b.ju_nei_shi_jian = 500.0
	assert_eq(int(zb14b.ti_qian_kai_zhan()), 0, "过了 8 分钟：船本来就要来了，不算提前")
	zb14b.free()

	# ---- 用例 15：死亡写结局；重开全面复位 ----
	var zb15: Node = load("res://scripts/zhang_ben.gd").new()
	jie_suan_ci = 0
	si_wang_ci = 0
	zb15.ju_jie_shu.connect(_shu_jie_suan)
	zb15.shou_shang()
	assert_eq(zb15.jie_ju, 3, "血量归零：结局记为死亡（SI_WANG）")
	assert_eq(zb15.jie_duan, 2, "死亡即结束阶段")
	assert_eq(jie_suan_ci, 0, "死亡走 si_wang，不重复发 ju_jie_shu")
	zb15.zou_ju_shi_jian(700.0)
	assert_eq(zb15.jie_ju, 3, "死后再走表也改写不了结局")
	zb15.chong_zhi()
	assert_eq(zb15.jie_ju, 0, "重开清空结局")
	assert_eq(zb15.jie_duan, 0, "重开回到正常生态期")
	assert_float(zb15.ju_nei_shi_jian, 0.0, "重开时钟归零")
	assert_eq(1 if zb15.sheng_cun_zhong else 0, 1, "重开复活")
	zb15.free()

	# ---- 用例 16：mm:ss 格式化（HUD 与结算页共用）----
	var zb16: Node = load("res://scripts/zhang_ben.gd").new()
	assert_string(zb16.ge_shi_shi_jian(600.0), "10:00", "600 秒 = 10:00")
	assert_string(zb16.ge_shi_shi_jian(65.0), "01:05", "65 秒补零 = 01:05")
	assert_string(zb16.ge_shi_shi_jian(0.0), "00:00", "0 秒 = 00:00")
	assert_string(zb16.ge_shi_shi_jian(-5.0), "00:00", "负数夹到 00:00")
	zb16.free()

	# ---- 用例 17：形态装配（等级/体型/初始主动/幂等/再来一次）----
	var zb17: Node = load("res://scripts/zhang_ben.gd").new()
	var dian_yu: XingTai = load("res://data/xingtai/lv_yu.tres")  # 可玩电鳗（旧 dian_yao 仅历史数据）
	var lan_yu: XingTai = load("res://data/xingtai/lan_yu.tres")
	var qi_yu: XingTai = load("res://data/xingtai/qi_yu.tres")
	assert_eq(1 if dian_yu != null and lan_yu != null and qi_yu != null else 0, 1,
			"形态资源应能加载（账本形态用例的前置）")
	sheng_ji_ci = 0
	zhuang_bei_ci = 0
	zb17.sheng_ji.connect(_shu_sheng_ji)
	zb17.neng_li_zhuang_bei.connect(_shu_neng_li)
	assert_eq(int(zb17.kai_ju_xing_tai(dian_yu)), 1, "开局装电鳗应成功")
	assert_eq(zb17.deng_ji, 1, "电鳗开局 Lv.1")
	assert_eq(zb17.jing_yan, 0, "形态开局经验归零")
	assert_float(zb17.dang_qian_ti_xing, 2.0, "电鳗开局体型 = 1+1 = 2.0（填满）")
	assert_eq(1 if zb17.dang_qian_xing_tai == dian_yu else 0, 1, "账本记下本局形态")
	assert_eq(1 if zb17.xing_tai_yi_ying_yong else 0, 1, "形态已应用标记置位")
	assert_eq(zhuang_bei_ci, 1, "初始主动装备应广播一次")
	assert_eq(zb17.zhu_dong_zu.size(), 1, "电鳗自带放电麻痹：入主动组")
	assert_string(String(zb17.zhu_dong_zu[0].bian_hao), "fang_dian_ma_bi", "初始主动是放电麻痹")
	assert_eq(zb17.yi_xuan_neng_li.size(), 1, "初始主动应进本局历史")
	assert_eq(sheng_ji_ci, 0, "形态开局不得触发 sheng_ji（否则开局弹三选一）")
	assert_eq(int(zb17.kai_ju_xing_tai(qi_yu)), 0, "同一局重复装形态返回 false")
	assert_eq(zb17.deng_ji, 1, "幂等：第二形态不覆盖开局等级")
	assert_eq(zhuang_bei_ci, 1, "幂等：初始能力不重复叠层")
	# “再来一次”：保留形态、其余复位
	zb17.deng_ji = 6
	zb17.jing_yan = 42
	zb17.dang_qian_ti_xing = 3.0
	zb17.chong_zhi_bao_liu_xing_tai()
	assert_eq(1 if zb17.dang_qian_xing_tai == dian_yu else 0, 1, "再来一次保留电鳗")
	assert_eq(zb17.deng_ji, 1, "再来一次回到形态开局等级")
	assert_eq(zb17.jing_yan, 0, "再来一次经验归零")
	assert_float(zb17.dang_qian_ti_xing, 2.0, "再来一次体型重新填满")
	assert_eq(zb17.yi_xuan_neng_li.size(), 1, "再来一次重新装初始主动")
	assert_eq(zb17.zhu_dong_zu.size(), 1, "再来一次仍是 1 个主动")
	assert_string(String(zb17.zhu_dong_zu[0].bian_hao), "fang_dian_ma_bi", "再来一次仍是放电麻痹")
	# 纯复位必须清形态（chong_zhi 仍是纯复位入口）
	zb17.chong_zhi()
	assert_eq(1 if zb17.dang_qian_xing_tai == null else 0, 1, "chong_zhi 清空形态引用")
	assert_eq(1 if not zb17.xing_tai_yi_ying_yong else 0, 1, "chong_zhi 清空形态应用标记")
	assert_eq(zb17.deng_ji, 0, "chong_zhi 回默认等级")
	assert_float(zb17.dang_qian_ti_xing, 1.0, "chong_zhi 回默认体型")
	# 钻光鱼：无初始能力
	assert_eq(int(zb17.kai_ju_xing_tai(lan_yu)), 1, "开局装钻光鱼应成功")
	assert_eq(zb17.deng_ji, 1, "钻光鱼开局 Lv.1")
	assert_eq(1 if zb17.zhu_dong_zu.is_empty() else 0, 1, "钻光鱼没有初始主动")
	assert_eq(zb17.yi_xuan_neng_li.size(), 0, "没有初始能力就不进历史")
	assert_eq(int(zb17.kai_ju_xing_tai(null)), 0, "空形态拒绝装配")
	zb17.free()

	# ---- 用例 18：档位系统（主动升档/满档幂等、被动满层、覆写读数、chong_zhi 清档）----
	var zb18: Node = load("res://scripts/zhang_ben.gd").new()
	var xuan_wo: NengLi = load("res://data/nengli/xuan_wo.tres")  # 主动，3 档上限
	var si_lie: NengLi = load("res://data/nengli/si_lie_chi.tres")  # 被动线性叠层：2.0 + 0.5/层
	var du_xian: NengLi = load("res://data/nengli/du_xian.tres")  # 被动覆写曲线：20/25 → 满层直接 45
	assert_eq(1 if xuan_wo != null and si_lie != null and du_xian != null else 0, 1,
			"新能力资源应能加载（档位用例的前置）")
	assert_eq(xuan_wo.zui_da_dang, 3, "漩涡上限 3 档（新能力默认档位）")
	zhuang_bei_ci = 0
	zb18.neng_li_zhuang_bei.connect(_shu_neng_li)
	# 主动：选 1 次 = 1 档；再选 = 升档（多槽化之后重复选的语义从"无操作"改为"升档"）
	zb18.xuan_neng_li(xuan_wo)
	assert_eq(zb18.dang_qian_zhu_dong_dang(&"xuan_wo"), 1, "主动第一次选：1 档")
	assert_eq(zhuang_bei_ceng, 1, "主动 1 档广播档号 1")
	zb18.xuan_neng_li(xuan_wo)
	assert_eq(zb18.dang_qian_zhu_dong_dang(&"xuan_wo"), 2, "主动再选：升到 2 档")
	assert_eq(zhuang_bei_ceng, 2, "升档广播档号 2")
	zb18.xuan_neng_li(xuan_wo)
	assert_eq(zb18.dang_qian_zhu_dong_dang(&"xuan_wo"), 3, "第三次选：3 档")
	assert_eq(zb18.zhu_dong_zu.size(), 1, "升档不涨槽数：漩涡始终只占一个槽")
	assert_eq(zb18.yi_xuan_neng_li.size(), 3, "每次升档都进历史（结算页能看到 ×3）")
	# 满档幂等：第 4 次选 = 无操作（不广播、不进历史、档位不动）
	zb18.xuan_neng_li(xuan_wo)
	assert_eq(zb18.dang_qian_zhu_dong_dang(&"xuan_wo"), 3, "满档后再选：档位不动")
	assert_eq(zhuang_bei_ci, 3, "满档再选不广播")
	assert_eq(zb18.yi_xuan_neng_li.size(), 3, "满档再选不进历史")
	# 被动线性叠层与满层幂等：撕裂齿 2.0 + 0.5/层，3 层封顶
	zb18.xuan_neng_li(si_lie)
	assert_eq(zb18.dang_qian_bei_dong_ceng(&"si_lie_chi"), 1, "被动第一次选：1 层")
	assert_float(zb18.bei_dong_zhi(&"si_lie_chi"), 2.0, "撕裂齿 1 层主值 2.0")
	zb18.xuan_neng_li(si_lie)
	zb18.xuan_neng_li(si_lie)
	assert_float(zb18.bei_dong_zhi(&"si_lie_chi"), 3.0, "撕裂齿 3 层 = 2.0 + 0.5×2")
	zb18.xuan_neng_li(si_lie)
	assert_eq(zb18.dang_qian_bei_dong_ceng(&"si_lie_chi"), 3, "满层后再选：层数不动")
	# 被动覆写曲线：毒腺 20/25 走线性，满层直接取 dang_biao 的 45（不是 30+15）
	zb18.xuan_neng_li(du_xian)
	zb18.xuan_neng_li(du_xian)
	assert_float(zb18.bei_dong_zhi(&"du_xian"), 25.0, "毒腺 2 层走线性：20+5=25")
	assert_float(zb18.bei_dong_fu_jia(&"du_xian", &"shu_zhi"), 0.0, "未满层时附加读数为 0")
	zb18.xuan_neng_li(du_xian)
	assert_float(zb18.bei_dong_zhi(&"du_xian"), 45.0, "毒腺满层质变：直接取 dang_biao 覆写 45")
	# 复位清档
	zb18.chong_zhi()
	assert_eq(zb18.zhu_dong_dang.size(), 0, "复位后主动档位表清空")
	assert_eq(zb18.dang_qian_zhu_dong_dang(&"xuan_wo"), 0, "复位后档位读数归 0")
	assert_eq(zb18.dang_qian_bei_dong_ceng(&"du_xian"), 0, "复位后层数读数归 0")
	zb18.free()

	# ---- 用例 19：被动改写账本曲线（饥饿耐受降速/满层回饥饿加成、贪食回复改恢复系数）----
	var zb19: Node = load("res://scripts/zhang_ben.gd").new()
	var nai_shou: NengLi = load("res://data/nengli/ji_e_nai_shou.tres")  # 0.1/层，满层附加 hui_de_bei 1.2
	var tan_shi: NengLi = load("res://data/nengli/tan_shi_hui_fu.tres")  # 0.15/层，满层附加 xi_shu 1.3
	zb19.xia_jiang_ji_e(2.0)
	assert_float(zb19.ji_e, 90.0, "基线：无被动 2 秒降 10（5.0/秒）")
	# 饥饿耐受 1 层：降速 ×0.9
	zb19.xuan_neng_li(nai_shou)
	zb19.ji_e = 100.0
	zb19.xia_jiang_ji_e(2.0)
	assert_float(zb19.ji_e, 91.0, "饥饿耐受 1 层：降速 ×0.9，2 秒只降 9")
	# 满层 3 层：降速 ×0.7；满层附加：吃食回饥饿 ×1.2
	zb19.xuan_neng_li(nai_shou)
	zb19.xuan_neng_li(nai_shou)
	zb19.ji_e = 100.0
	zb19.xia_jiang_ji_e(2.0)
	assert_float(zb19.ji_e, 93.0, "饥饿耐受满层：降速 ×0.7，2 秒只降 7")
	zb19.ji_e = 50.0
	zb19.hui_ji_e(10.0)
	assert_float(zb19.ji_e, 62.0, "满层耐受附加：回 10 饥饿 ×1.2 = 12（50 → 62）")
	# 贪食回复 1 层：恢复量 +15%
	zb19.xuan_neng_li(tan_shi)
	assert_float(zb19.chi_wu_hui_ti_xing(1.5), 1.15, "贪食 1 层：1.5÷1.5×1.15 = 1.15")
	# 贪食满层质变：恢复系数 1.5 → 1.3，再吃一次共 ×1.45 —— 1.3 体型恰好回 1.45
	zb19.xuan_neng_li(tan_shi)
	zb19.xuan_neng_li(tan_shi)
	assert_float(zb19.chi_wu_hui_ti_xing(1.3), 1.45, "贪食满层：系数换 1.3 且 ×1.45（1.3 体型回 1.45）")
	zb19.free()

	# ---- 用例 20：中途存档往返（写入 → 读取 → 载回 → 清除）----
	var zb20: Node = load("res://scripts/zhang_ben.gd").new()
	var cd20: Node = load("res://scripts/cun_dang.gd").new()  # --script 模式无 Autoload：new 独立实例注入
	var zt_lu_jing := "user://ce_zhang_ben_zhongtu_%d.json" % OS.get_process_id()
	cd20.zhong_tu_lu_jing = zt_lu_jing  # 与真实存档隔离：测试只碰临时路径
	cd20.qing_chu_zhong_tu()
	assert_eq(1 if not cd20.you_zhong_tu() else 0, 1, "清档后不应有中途存档")
	assert_eq(1 if cd20.du_zhong_tu().is_empty() else 0, 1, "没档时读取应返回空字典")
	# 摆一局"打了一半"的状态：电鳗 Lv.1 起步 → 灌经验升 Lv.2 → 掉血掉饥饿走时间 → 装能力记食谱
	var cd_dian_yu: XingTai = load("res://data/xingtai/lv_yu.tres")
	var cd_xuan_wo: NengLi = load("res://data/nengli/xuan_wo.tres")
	var cd_du_xian: NengLi = load("res://data/nengli/du_xian.tres")
	assert_eq(1 if zb20.kai_ju_xing_tai(cd_dian_yu) else 0, 1, "装配电鳗形态")
	zb20.jia_jing_yan(15)  # Lv.1 阈值 12：15-12=3 → 升 Lv.2 余 3
	assert_eq(zb20.deng_ji, 2, "前置：应升到 Lv.2")
	zb20.shou_shang(1.0)  # 掉 1 点血：Lv.2 上限 3.0 → 2.0
	zb20.ji_e = 55.5
	zb20.ju_nei_shi_jian = 233.0
	zb20.xuan_neng_li(cd_xuan_wo)
	zb20.xuan_neng_li(cd_xuan_wo)  # 漩涡升到 2 档
	zb20.xuan_neng_li(cd_du_xian)  # 毒腺 1 层
	zb20.ji_chi_yu(cd_xuan_wo)  # 食谱：漩涡鱼吃 1 条
	# 写入 → 读取
	assert_eq(1 if cd20.xie_zhong_tu(zb20) else 0, 1, "写入中途存档应成功")
	assert_eq(1 if cd20.you_zhong_tu() else 0, 1, "写入后应存在中途存档")
	var du_hui: Dictionary = cd20.du_zhong_tu()
	assert_eq(1 if not du_hui.is_empty() else 0, 1, "读取应返回非空字典")
	assert_string(String(du_hui.get("xing_tai", "")), "lv_yu", "存档形态 id 应为电鳗")
	assert_eq(int(du_hui.get("deng_ji", -1)), 2, "存档等级应为 2")
	# 清空账本 → 载回 → 逐字段核对
	zb20.chong_zhi()
	assert_eq(zb20.deng_ji, 0, "前置：复位后回 Lv.0")
	assert_eq(1 if zb20.zai_ru_zhong_tu(du_hui, cd_dian_yu) else 0, 1, "载入中途存档应成功")
	assert_eq(zb20.deng_ji, 2, "载入：等级恢复 Lv.2")
	assert_eq(zb20.jing_yan, 3, "载入：本级经验恢复 3")
	assert_float(zb20.dang_qian_ti_xing, 2.0, "载入：当前体型（血量）恢复 2.0")
	assert_float(zb20.ji_e, 55.5, "载入：饥饿恢复 55.5")
	assert_float(zb20.ju_nei_shi_jian, 233.0, "载入：局内时钟恢复 233")
	assert_eq(zb20.dang_qian_zhu_dong_dang(&"xuan_wo"), 2, "载入：漩涡档位恢复 2")
	assert_eq(zb20.dang_qian_bei_dong_ceng(&"du_xian"), 1, "载入：毒腺层数恢复 1")
	assert_eq(1 if zb20.zhuang_lei(&"xuan_wo") else 0, 1, "载入：主动组里有漩涡")
	assert_eq(zb20.yi_xuan_neng_li.size(), 4, "载入：获得历史恢复 4 条（初始放电 + 漩涡×2 + 毒腺）")
	assert_eq(int(zb20.chi_yu_ji_lu.get(&"xuan_wo", 0)), 1, "载入：食谱计数恢复 1")
	assert_string(String(zb20.zui_duo_bian_hao), "xuan_wo", "载入：最常吃从食谱推导回漩涡")
	assert_eq(1 if zb20.xing_tai_yi_ying_yong else 0, 1, "载入：幂等保护应置位（不许再走开局装配）")
	assert_eq(int(zb20.jie_ju), 0, "载入：结局回到未定")
	# 进化往返：Lv.6 进化 → 存档带 jin_hua → 复位 → 读档恢复形态与倍率
	zb20.deng_ji = 6
	var jin_hua_shou = JinHuaKu.wan_jia_fen_zhi(&"lv_yu")[0]
	assert_eq(1 if zb20.jin_hua_wei(jin_hua_shou) else 0, 1, "前置：Lv.6 可进化（电鳗东方分支）")
	assert_eq(1 if cd20.xie_zhong_tu(zb20) else 0, 1, "进化后写中途档应成功")
	var du_hui_jin: Dictionary = cd20.du_zhong_tu()
	assert_string(String(du_hui_jin.get("jin_hua", "")), "lei_yuan_ming_she",
			"存档应记录进化形态 id")
	zb20.chong_zhi()
	assert_eq(1 if zb20.dang_qian_jin_hua == null else 0, 1, "前置：复位后进化清空")
	assert_eq(1 if zb20.zai_ru_zhong_tu(du_hui_jin, cd_dian_yu) else 0, 1, "载入进化档应成功")
	assert_string(String(zb20.dang_qian_jin_hua.bian_hao), "lei_yuan_ming_she",
			"读档恢复进化形态")
	assert_float(zb20.jin_hua_ti_xing_bei, 1.5, "读档恢复进化倍率 1.5")
	assert_float(zb20.ti_xing_shang_xian(), (float(zb20.deng_ji) + zb20.JI_CHU_TI_XING) * 1.5,
			"读档后体型上限按进化倍率算（先恢复倍率再算上限）")
	# 结局已定 / 死亡的局面拒绝写中途档（写档前置守门）
	zb20.ding_jie_suan(1)  # 胜利：与 CunDang.JIE_JU_SHENG_LI 对齐
	assert_eq(1 if not cd20.xie_zhong_tu(zb20) else 0, 1, "结局已定应拒绝写中途档")
	# 清除：往返链路最后一环
	cd20.qing_chu_zhong_tu()
	assert_eq(1 if not cd20.you_zhong_tu() else 0, 1, "清除后不应有中途存档")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(zt_lu_jing))  # 保险：幂等删除临时档
	zb20.free()  # 不入树实例用完即弃
	cd20.free()

	# ---- 用例 21：进化专属技归属校验（策划案 v0.21 独占规则）----
	var zb21: Node = load("res://scripts/zhang_ben.gd").new()
	var zhuan := NengLi.new()
	zhuan.bian_hao = &"ce_zhuan_shu"
	zhuan.lei_xing = NengLi.LeiXing.ZHU_DONG
	zhuan.zui_da_dang = 1
	zhuan.suoshu_xing_tai = &"lei_yuan_ming_she"
	assert_eq(1 if zhuan.shi_zhuan_shu() else 0, 1, "填了归属形态即视为专属技")
	assert_eq(1 if not zb21.neng_li_ke_yong(zhuan) else 0, 1, "未进化时专属技不可用")
	zb21.xuan_neng_li(zhuan)
	assert_eq(1 if not zb21.zhuang_lei(&"ce_zhuan_shu") else 0, 1, "归属不符时装备入口应拒绝")
	zb21.dang_qian_jin_hua = JinHuaKu.zhao(&"lei_yuan_ming_she")
	assert_eq(1 if zb21.neng_li_ke_yong(zhuan) else 0, 1, "进化成对应形态后专属技可用")
	zb21.xuan_neng_li(zhuan)
	assert_eq(1 if zb21.zhuang_lei(&"ce_zhuan_shu") else 0, 1, "归属匹配后装备入口放行")
	var pu_tong := NengLi.new()
	pu_tong.bian_hao = &"ce_pu_tong"
	pu_tong.zui_da_dang = 1
	assert_eq(1 if zb21.neng_li_ke_yong(pu_tong) else 0, 1, "无归属的普通能力始终可用")
	zb21.free()

	# ---- 收卷：退出码是唯一门禁语言 ----
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func assert_eq(shi_ji, qi_wang: int, biao_qian: String) -> void:
	# 记账员：失败只记账不爆炸——对比裸 assert() 的挂死陷阱
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %d，实际 %d）" % [biao_qian, qi_wang, shi_ji])


func assert_float(shi_ji: float, qi_wang: float, biao_qian: String) -> void:
	# 血量是 float：浮点比较走 is_equal_approx，别拿 == 赌二进制精度
	if is_equal_approx(shi_ji, qi_wang):
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %.2f，实际 %.2f）" % [biao_qian, qi_wang, shi_ji])


func assert_string(shi_ji: String, qi_wang: String, biao_qian: String) -> void:
	# 文本断言：时间格式必须一字不差（补零错了 HUD 一眼能看出来）
	if shi_ji == qi_wang:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s（期望 %s，实际 %s）" % [biao_qian, qi_wang, shi_ji])


func _shu_si_wang() -> void:
	# si_wang 接收器：只数次数，不碰被测对象
	si_wang_ci += 1


func _shu_jie_suan(jie_guo: int) -> void:
	# ju_jie_shu 接收器：只数次数
	jie_suan_ci += 1


func _shu_jie_duan(xin_jie_duan: int) -> void:
	# jie_duan_gai_bian 接收器：只数次数
	jie_duan_ci += 1


func _shu_neng_li(neng: NengLi, ceng: int) -> void:
	# neng_li_zhuang_bei 接收器：记下最近一次广播的能力与层数
	zhuang_bei_ci += 1
	zhuang_bei_ming = neng.bian_hao if neng != null else &""
	zhuang_bei_ceng = ceng


func _shu_sheng_ji(_xin_deng_ji: int) -> void:
	# sheng_ji 接收器：形态开局不允许触发升级弹窗
	sheng_ji_ci += 1
