extends RefCounted
# A 核心数值初值表（2026-11-08 交接文档 A1~A15）：
# 所有可调战斗/生存参数集中在这里，后续实机调参只改本文件，不散落在各脚本。
# 用法：const SHU_ZHI := preload("res://scripts/shu_zhi.gd")，再 SHU_ZHI.XXX。
# 注意：本脚本是纯静态常量表，不进 Autoload、不依赖场景树，--script 纯逻辑测试也能读。

# ---- A1 吞噬门槛 ----
const TUN_CHI_BEI_LV := 1.1  # 体型 ≥ 对方 ×1.1 才能整吞（Yu / YuNpc 共用）

# ---- A2 普通咬击伤害 ----
const YAO_JI_SHANG_HAI_BI := 0.03  # 每口掉对方「当前体型」的 3%
const YAO_JI_ZUI_DI_SHANG_HAI := 0.01  # 每口保底伤害：防止体型趋零时咬不动

# ---- A3 咬击间隔 ----
const YAO_JI_JIAN_GE := 0.5  # 自动咬击间隔（秒）
const KUANG_BAO_JIAN_GE := 0.25  # 狂暴撕咬窗口内的咬击间隔（翻倍攻速）

# ---- A4 致命区伤害 ----
const ZHI_MING_SHANG_HAI_BEI := 3.0  # 咬中致命区 = 普通咬 ×3（一击必杀条件不变）

# ---- A5 饥饿满值/消耗 ----
const JI_E_SHANG_XIAN := 100.0  # 饥饿条上限
const JI_E_XIA_JIANG_MEI_MIAO := 0.6  # 每秒下降 0.6：全程不吃约 166 秒饿空

# ---- A6 饥饿惩罚 ----
const E_SI_TI_XING_BI := 0.005  # 归零后每秒掉「自身体型」的 0.5%
const E_SI_ZUI_DI_MEI_MIAO := 0.01  # 每秒保底扣血：指数衰减必须加绝对项才能真的饿死

# ---- A7 进食回复 ----
const TUN_YU_HUI_TI_XING_BI := 0.04  # 吞一条鱼：体型 +4%（按自身体型上限）
const ROU_HUI_TI_XING_BI := 0.015  # 鱼肉块：体型 +1.5%（按自身体型上限）
const TUN_YU_HUI_JI_E := 25.0  # 吞一条鱼：饥饿 +25
const ROU_HUI_JI_E := 8.0  # 鱼肉块：饥饿 +8

# ---- A8 消化 ----
const XIAO_HUA_SHI_CHANG := 3.0  # 消化一口 3 秒
const XIAO_HUA_JIAN_SU := 0.3  # 消化期间再咬：咬速 -30%（冷却 ×1/(1-0.3)）

# ---- A9 移动速度 ----
const JI_CHU_SU_DU := 260.0  # 基础速度 260px/s（默认主角口径，各形态可在数据表上覆写）
const MEI_JI_JIAN_SU := 0.04  # 每级体型速度 -4%
const SU_DU_ZUI_DI_BI := 0.35  # 速度惩罚下限：等级无上限，不能慢到 0
const MEI_JI_ZHUAN_XIANG_JIAN := 0.06  # 每级体型转向速率 -6%
const ZHUAN_XIANG_ZUI_DI_BI := 0.25  # 转向惩罚下限

# ---- A10 NPC 感知 ----
const NPC_GAN_ZHI_MEI_TI := 90.0  # 感知半径 = 体型 ×90px
const NPC_FAN_YING_SHI_JIAN := 0.4  # 反应延迟 0.4 秒

# ---- A11 双重加压 ----
const DA_YU_JIA_YA_QI_DIAN := 240.0  # 第 4 分钟起
const DA_YU_JIAN_GE_QI_SHI := 25.0  # 大体型刷新间隔从 25 秒
const DA_YU_JIAN_GE_MO := 15.0  # 线性收紧到 15 秒（到第 10 分钟）
const DA_YU_JIAN_GE_ZHONG_DIAN := 600.0  # 线性终点：本局总时长
const DA_YU_CHA_JI := 2  # 「大体型」定义：等级 ≥ 玩家当前等级 +2（A11 专刷用）

# ---- A12 前 2 分钟保护 ----
const BAO_HU_SHI_JIAN := 120.0  # 前 120 秒
const BAO_HU_CHA_JI := 3  # 不刷 ≥ 玩家等级 +3 的大体型

# ---- 濒死逃逸爆发（缺口 11 / 评审 P1：死亡螺旋唯一保底）----
const BIN_SI_TI_XING_BI := 0.15  # 当前体型 ≤ 上限 15% 触发（用上限比例，不做绝对值）
const BIN_SI_CHI_XU := 5.0  # 持续 5 秒
const BIN_SI_JIA_SU := 0.3  # 移动速度 +30%
const BIN_SI_SHANG_HAI_XI_SHU := 0.5  # 受到伤害 -50%（最终伤害乘数）
const BIN_SI_GAN_ZHI_XI_SHU := 0.5  # NPC 感知玩家 -50%
const BIN_SI_MEI_JU_CI_SHU := 1  # 每局仅 1 次
const BIN_SI_BIAN_YUAN_HOU_DU := 96.0  # 屏幕边缘暗红脉冲厚度（像素），可调

# ---- A13 机械船 ----
const CHUAN_XUE_GU_DING := 400.0  # 11-23 A13 拍板：船血固定 400（可调区间 300~500），与玩家体型脱钩
const CHUAN_XUE_MEI_TI := 40.0  # 旧公式系数：仅留档，主流程已不用（别删，老存档/工具可能还读）
const CHUAN_HU_JIA_JIAN_SHANG := 0.3  # 非致命区护甲减伤 30%

# ---- A14 NPC 互吃 ----
const NPC_HU_CHI_JIAN_GE := 20.0  # 每 20 秒全局判定一次
const NPC_HU_CHI_GAI_LV := 0.35  # 相邻 NPC 每次判定的捕食概率（体型+随机）
const NPC_HU_CHI_BAN_JING := 140.0  # "相邻"判定半径（像素）

# ---- 隐藏营养值系统（2026-11-20 设计提案·A 方案核心闭环）----
# 每条 NPC 出生 roll 一个营养值，玩家吃鱼经验 = 基础经验 × 营养值（挑着吃的核心动机）
# 注意：营养只管经验，不动体型成长/饥饿回复（两条收益线分开，防双乘算失控）
const YING_YANG_DANG_1 := Vector2(0.6, 0.9)  # 1 档（小型速生鱼种）营养区间
const YING_YANG_DANG_2 := Vector2(0.8, 1.2)  # 2 档（中型鱼种）营养区间
const YING_YANG_DANG_3 := Vector2(1.2, 1.6)  # 3 档（大型/顶级鱼种）营养区间
const YING_YANG_XIA_XIAN := 0.6  # 营养值下限兜底：不会出现「白吃」
const MAN_YANG_GE_LV := 0.03  # 满营养鱼概率 3%（提案②默认值：平均每屏 1~2 条微光鱼）
const MAN_YANG_BEI := 1.33  # 满营养鱼营养值 = 档位上限 ×1.33（≈1.6~2.1，一口顶两条半）
const MAN_YANG_CHENG_ZHANG_JIAN_GE := 20.0  # 满营养鱼静默成长节拍：每 20 秒 +0.5 级
const MAN_YANG_CHENG_ZHANG_MEI_CI := 0.5  # 每拍成长量（级）
const MAN_YANG_DENG_JI_SHANG_XIAN := 6  # 满营养鱼成长绝对上限（初始 1 级 ×6）
const MAN_YANG_DONG_JIE_SHI_JIAN := 120.0  # 开局保护：前 120 秒满营养鱼不成长（A12）
const MAN_YANG_TONG_PING_SHANG_XIAN := 1  # 同屏满营养成长鱼上限（已有 1 条时新 roll 不生效）
const GAO_YING_YANG_BI_LI := 1.0 / 3.0  # 高营养信号阈值：区间上 1/3 起体色更饱满发亮
# ---- A 方案剩余机制（2026-11-20 提案 3.2/3.6/4A）----
# 出生锁 1 级：刷新只定鱼种+营养，体型交给成长系统涌现；饵料鱼层是生态死锁防护（1 级互吃不过 1.1 门槛）
const CHU_SHENG_DENG_JI := 1  # 所有普通 NPC 出生隐藏等级/体型统一 1（鱼种 dengji 仅用于解锁进度与图鉴）
const ER_LIAO_TI_XING := 0.4  # 饵料鱼（浮游小鱼）体型：远小于 1 级 NPC，1.0>=0.4×1.1 保证吃得动
const ER_LIAO_JING_YAN := 1  # 吃一条饵料鱼给的隐藏经验（对应普通鱼 +0.2 级的成长来源，见升级表）
const HU_CHI_CHENG_ZHANG_BEI := 0.5  # A14 互吃成长：吞掉对方等级 ×0.5（提案 3.2）
# 暗池统计模拟（提案 3.6）：不存个体，只按区域登记表批量结算
const AN_CHI_JIE_SUAN_JIAN_GE := 30.0  # 暗池批量结算节拍：每 30 秒推进一次
const AN_CHI_PING_JUN_CHENG_ZHANG := 0.3  # 普通鱼每 30 秒区域平均等级 +0.3（与明池进食速率对齐）
const AN_CHI_DENG_JI_SHANG_XIAN_JI_CHU := 4  # 区域等级上限 = min(4 + 局内分钟数, 6)
const AN_CHI_DENG_JI_SHANG_XIAN_FENG := 6  # 区域等级上限封顶 6（出门不遇全图 boss）
const AN_CHI_SHOU_SUO_XI_SHU_1 := 1.2  # A11 水域收缩阶段①暗池成长率 ×1.2
const AN_CHI_SHOU_SUO_XI_SHU_2 := 1.5  # A11 水域收缩阶段②暗池成长率 ×1.5
const GAO_YING_YANG_ZHUAN_XIAN_GE_LV := 0.08  # A11 加压期高营养专线概率 3%→8%（威胁仍是长出来的）

# ---- G 专属技 T1（2026-11-08）：能力表没写的节奏/概率细项统一收口 ----
# 电鳗组
const LEI_BAO_LUO_LEI_JIAN_GE := 0.8  # 雷暴召唤：每 0.8 秒随机落雷 1 道
const LEI_BAO_LUO_LEI_BAN_JING := 100.0  # 单道落雷判定半径（像素 ≈ 1 身位）
const LEI_BAO_DIAN_MA := 35.0  # 每道雷的电麻积累
const JIU_TOU_DIAN_WANG_KUAN := 40.0  # 九头电网：射线判定半宽（像素）
const JIU_TOU_DIAN_WANG_DIAN_MA := 50.0  # 穿越电网的电麻积累
# 剑鱼组
const ZUAN_TU_JI_TUI := 1.5  # 螺旋钻突：每目标击退距离（身位）
const ZUAN_TU_ZUI_DUO := 4  # 最多串 4 条
const ZUAN_TU_DI_SAN_JIAN := 0.2  # 第 3 条起每条伤害 -20%
const JU_DU_TU_CI_JU_LI := 1.6  # 剧毒突刺：命中距离（身位）
const JU_DU_TU_CI_BEI_LV := 2.0  # 剧毒突刺：双倍掉肉
const KONG_JIAN_KUAN := 1.0  # 空间裂缝：刃宽（身位）
# 旗鱼组
const YOU_LING_QI_SHE_JIAN_GE := 0.4  # 幽灵齐射：三发间隔（秒）
const YOU_LING_QI_SHE_SHU := 3  # 齐射发数
const YOU_LING_QI_SHE_SHAN_JIAO := 30.0  # 扇形半角（度）
const YOU_LING_QI_SHE_JI_TUI := 1.0  # 击退距离（身位）
const PO_KONG_FU_CHONG_YUE_SHUI := 2.0  # 破空俯冲：跃水时长（秒）
const PO_KONG_FU_CHONG_DING_ZHU := 0.5  # 落点硬直（秒）
# 蓑鲉组
const KONG_QUE_HUAN_YING_SHU := 2  # 孔雀幻影：幻影个数
const SHI_HUA_QIAN_YAO := 0.6  # 石化之瞳：施法前摇（秒）
const SHI_HUA_SHOU_SHANG_BEI := 1.25  # 石化期间受玩家伤害倍率
const JI_GUAN_FAN_JIA_BEI := 0.4  # 棘冠反甲：反伤比例
const JI_GUAN_FAN_JIA_DU := 25.0  # 棘冠反甲：每次反弹附加毒晕
const JIN_SHEN_JI_MA_MIAO := 1.0  # 近身即麻：结算节拍（秒）
const SHE_FA_PEN_DU_BEI := 30.0  # 蛇发喷毒：受击反喷毒晕
const GONG_SHENG_HAI_KUI_JIAN_GE := 4.0  # 共生海葵：自动放毒雾间隔
const GONG_SHENG_HAI_KUI_MEI_MIAO := 0.1  # 共生海葵：每秒掉肉量
const GONG_SHENG_HAI_KUI_SHI_CHANG := 3.0  # 共生海葵：毒雾持续
const MING_LEI_LIN_JI_LEI_BEI := 0.25  # 鸣雷鳞：电麻积累 +25%（范围 +30% 走能力表主值）
const JU_DU_TU_CI_BAN_JIAO := 30.0  # 剧毒突刺：前方锥形半角（度）
const SHI_HUA_BAN_JIAO := 30.0  # 石化之瞳：前方扇形半角（度，总 60°）
const KONG_QUE_HUAN_YING_BAN_JING := 1.2  # 孔雀幻影：NPC 咬到幻影的判定半径（身位）
