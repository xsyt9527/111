# TASK-006: 升级三选一（强化卡注册表 + 升级暂停 + 不放回抽样 + 三选一弹窗）

> 引擎：Godot 4.7
> 开发策略：plan_driven
> 参与模式：guided_co_development
> 执行模式：teaching
> 任务规格版本：v1
> 审批状态：awaiting
> 交付状态：proposed
> Git 基线：26b6a84411dc2d80f7bf6e7076580fe55cd5f93a

## 一、任务目标

升级时**暂停游戏弹出三选一强化卡**：QiangHuaKa Resource 模具 + 6 张强化卡 .tres（复用第 4 课注册表模式）；升级阈值从 zhang_ben.gd 常量**数据化为 .tres**（兑现 TASK-005 P3 备忘）；弹窗（CanvasLayer + process_mode=WHEN_PAUSED）监听 sheng_ji 信号，`duplicate → shuffle → slice` 不放回抽样 3 张；点选后 `ZhangBen.xuan_ka()` 入账（已选卡列表 + ka_yi_xuan 信号）、恢复暂停。完成后：**升级 → 冻结 → 三选一 → 点选继续**——肉鸽循环的核心节拍器上线。强化效果本身第 7 课才生效（本课选卡只记录）。

### 完成后可观察结果

- F5：攒够经验升级瞬间**全场定格**（玩家/鱼群/生成全部停），弹出 3 张互不相同的卡
- 点一张卡：立即恢复游动；远程树 ZhangBen 的 Yi Xuan Ka 列表追加该卡
- 两次升级两次弹窗，抽到的卡组合随机不同
- 完整回归：移动/生成/回收/判定/无敌/涨条/长大全部无退化

### 本任务不做

- 强化效果生效（第 7 课：xiao_guo/shu_zhi 只存不用，任何脚本不得消费）
- 磁吸双 Area2D（学生第 3 课提案，第 7 课实现）
- 卡片翻转/弹窗动效（第 7 课 Tween 统一调优）
- 血量/死亡/结算（TASK-008）；账本重置（TASK-008 配套）

## 二、当前工程状态

### 已实现并验证（TASK-001~005）

- 玩家移动、数据驱动鱼群、大吃小判定 + 无敌、Autoload 账本 + 记账 + 长大 + 经验条
- **sheng_ji 信号已有两家听众**（yu.gd 长大、jing_yan_ui.gd 跳级）——弹窗将是第三家
- **SHENG_JI_YUZHI 常量待数据化**（TASK-005 P3 备忘指名本课兑现）
- **SHENG_JI_YUZHI 数值保持 [8,20,35,55,80,110] 不变**——等值切换，行为零变化

### 审计新鲜度

- audited_commit：26b6a84411dc2d80f7bf6e7076580fe55cd5f93a（工作区干净）
- environment_checked_at：2026-10-23T02:40:00Z
- engine_executable_source：common_path（`D:\001\Godot_v4.7.2-stable_win64.exe`）
- engine_version_detected：4.7.2

### 当前依赖与阻塞

- 依赖 TASK-004（注册表模式）、TASK-005（账本 + sheng_ji 信号）；无阻塞

## 三、功能所有权与团队集成

### 功能所有者

- owner_id：student-01
- 新建：`scripts/qiang_hua_ka.gd`、`scripts/sheng_ji_biao.gd`、`scripts/qiang_hua_dan_chuang.gd`、`scenes/QiangHuaDanChuang.tscn`、`data/qianghua/*.tres × 6`、`data/shengji/sheng_ji_biao.tres`
- 修改 2 文件：`scripts/zhang_ben.gd`（阈值读表 + xuan_ka 接口）、`scenes/Main.tscn`（实例化弹窗）
- **零修改**：`yu.gd`、`jing_yan_ui.gd`、`yu_npc.gd`、`yu_qun.gd`、`yu_zhong.gd`、`main.gd`、`Yu.tscn`、`YuNpc.tscn`、`project.godot`

### 集成合同

| 类型 | 名称 | 提供方 | 使用方 | 合同 |
|---|---|---|---|---|
| 信号消费 | `ZhangBen.sheng_ji` | 账本（TASK-005） | 弹窗 | 第三家听众：连接即触发弹出，账本零改动 |
| 方法 | `ZhangBen.xuan_ka(ka)` | 账本（本课新增） | 弹窗按钮 | 已选卡唯一入账入口 |
| 信号预埋 | `ZhangBen.ka_yi_xuan(ka)` | 账本（本课新增） | （第 7 课强化系统） | 本课 emit 无消费者——接口先行的账本模式 |
| 数据 | `QiangHuaKa`（ming_zi/miao_shu/xiao_guo/shu_zhi） | 模具 + 6 张 .tres | 弹窗展示 / 第 7 课生效 | xiao_guo/shu_zhi 本课只存不用 |
| 数据 | `ShengJiBiao.yuzhi_zu` | .tres | zhang_ben.gd | 改表即调升级曲线，零代码 |

- **禁止**：任何脚本消费 xiao_guo/shu_zhi 做实际强化（第 7 课范围）
- **禁止**：已选卡列表/yi_xuan_ka 出现在账本之外；同一批三卡重复（不放回被破坏）

## 四、学生参与与学习目标

### 学习目标

1. 复述 Resource 三分工（第 4 课遗留抽查），指出 QiangHuaKa 与 YuZhong 结构同构
2. 解释 get_tree().paused 为何一行冻结全场、弹窗为何必须 process_mode=WHEN_PAUSED 才可点击
3. 说出不放回抽样三步（duplicate→shuffle→slice）及每步必要性
4. 跟踪选择数据流：按钮 → xuan_ka(ka) → yi_xuan_ka 追加 + ka_yi_xuan 信号（第 7 课消费）

### 检查点安排

| 检查点 | 时机 | 学生动作 | 证据类型 |
|---|---|---|---|
| orientation | step-01 前 | 复述两项抽查（Resource 三分工 / 账本为何不挂 Main 下）+ 两个设计决策 | project_navigation, concept_explanation |
| godot-inspection | step-03 后 | 双击 .tres 看卡数据、检查器看 process_mode、改阈值表实验后**当场还原** | editor_operation, configuration_inspection |
| verification-handoff | step-04 后 | F5 亲测四条：冻结弹出/三卡不重/点选恢复/全量回归 | result_interpretation, test_execution |

## 五、文件级实现规格

### 5.1 scripts/qiang_hua_ka.gd（新建：强化卡模具）

```gdscript
extends Resource
class_name QiangHuaKa
# 强化卡数据模具：一张 .tres = 强化卡池里的一张卡（与 YuZhong 同构，注册表模式复用）

@export var ming_zi := ""  # 卡名（按钮大字，如"迅捷"）
@export var miao_shu := ""  # 描述（按钮小字，如"游速 +15%"）
@export var xiao_guo := ""  # 效果类型键（第 7 课 switch 生效用，本课只存）
@export var shu_zhi := 0.0  # 效果数值（如 0.15 = +15%，本课只存）
```

### 5.2 data/qianghua/*.tres × 6（新建：卡池）

| 卡名 | 文件 | xiao_guo | shu_zhi | miao_shu |
|---|---|---|---|---|
| 迅捷 | xun_jie.tres | yidong_sudu | 0.15 | 游速 +15% |
| 催肥 | cui_fei.tres | mei_ji_tixing | 0.05 | 每级体型增幅 +0.05 |
| 磁吸 | ci_xi.tres | ci_xi_fanwei | 0.4 | 小鱼吸附范围 +40% |
| 贪食 | tan_shi.tres | tun_shi_fanwei | 0.15 | 吞噬判定圈 +15% |
| 活力 | huo_li.tres | wudi_shi_chang | 0.5 | 受伤无敌时长 +50% |
| 睿智 | rui_zhi.tres | jing_yan_jia_cheng | 0.25 | 经验获取 +25% |

（磁吸 = 学生第 3 课自己提案的卡；效果全部第 7 课生效，本课只入账）

### 5.3 scripts/sheng_ji_biao.gd + data/shengji/sheng_ji_biao.tres（新建：阈值表）

```gdscript
extends Resource
class_name ShengJiBiao
# 升级阈值表：改这张表即调升级曲线，零代码（TASK-005 常量数据化兑现）

@export var yuzhi_zu: Array[int] = [8, 20, 35, 55, 80, 110]  # 每级所需经验
```

zhang_ben.gd 切换：删 `const SHENG_JI_YUZHI`，加 `var sheng_ji_biao := preload("res://data/shengji/sheng_ji_biao.tres")`；`dangqian_yuzhi()` 里 `SHENG_JI_YUZHI` 全部改读 `sheng_ji_biao.yuzhi_zu`。数值等值，行为零变化。

### 5.4 scenes/QiangHuaDanChuang.tscn + scripts/qiang_hua_dan_chuang.gd（新建：弹窗）

场景结构（根节点 Inspector：**Process Mode = When Paused(3)**、visible 默认 false）：

```
QiangHuaDanChuang (CanvasLayer, qiang_hua_dan_chuang.gd, process_mode=3)
├─ BanDi (ColorRect)          全屏半透明黑遮罩（约 1280×720, a≈0.6）
├─ BiaoTi (Label)             "选一张强化！"（居中大字）
└─ KaPianZu (HBoxContainer)   居中横排
   ├─ Ka1 (PanelContainer) → MingCheng1 (Button) + MiaoShu1 (Label)
   ├─ Ka2 (PanelContainer) → MingCheng2 (Button) + MiaoShu2 (Label)
   └─ Ka3 (PanelContainer) → MingCheng3 (Button) + MiaoShu3 (Label)
```

```gdscript
extends CanvasLayer
# 三选一弹窗：听账本升级信号 → 冻结全场 → 抽 3 张卡 → 点选入账 → 恢复
# process_mode=WHEN_PAUSED：全场暂停时唯我独醒（否则按钮点不动）

@export var ka_zu: Array[QiangHuaKa] = []  # 卡池注册表（场景里拖入 6 张 .tres）

var dang_qian_san_zhang: Array[QiangHuaKa] = []  # 本次抽出的 3 张（按钮回调对应）

@onready var ming_cheng: Array = [$KaPianZu/Ka1/MingCheng1, $KaPianZu/Ka2/MingCheng2, $KaPianZu/Ka3/MingCheng3]
@onready var miao_shu: Array = [$KaPianZu/Ka1/MiaoShu1, $KaPianZu/Ka2/MiaoShu2, $KaPianZu/Ka3/MiaoShu3]
@onready var ka_an_niu: Array = [$KaPianZu/Ka1/MingCheng1, $KaPianZu/Ka2/MingCheng2, $KaPianZu/Ka3/MingCheng3]


func _ready() -> void:
	visible = false  # 平时藏着，升级才现身
	ZhangBen.sheng_ji.connect(_on_sheng_ji)  # sheng_ji 第三家听众
	for i in ka_an_niu.size():
		ka_an_niu[i].pressed.connect(_on_ka_dian.bind(i))


func _on_sheng_ji(_xin_deng_ji: int) -> void:
	# 升级了：冻结全场 → 不放回抽 3 张 → 填按钮 → 现身
	get_tree().paused = true
	var dai_chou := ka_zu.duplicate()  # 复制一份，原注册表不动
	dai_chou.shuffle()                 # 洗牌（随机性来源）
	dang_qian_san_zhang = dai_chou.slice(0, 3)  # 取前 3 张：不放回、无重复
	for i in dang_qian_san_zhang.size():
		ming_cheng[i].text = dang_qian_san_zhang[i].ming_zi
		miao_shu[i].text = dang_qian_san_zhang[i].miao_shu
	visible = true


func _on_ka_dian(i: int) -> void:
	# 点了第 i 张卡：入账 → 解冻 → 藏起来
	ZhangBen.xuan_ka(dang_qian_san_zhang[i])
	get_tree().paused = false
	visible = false
```

Main.tscn 追加一个实例节点：`QiangHuaDanChuang (QiangHuaDanChuang.tscn 实例)`。

### 5.5 scripts/zhang_ben.gd（修改两处）

```gdscript
# 1) 阈值数据化：常量退役，读表（数值不变）
var sheng_ji_biao := preload("res://data/shengji/sheng_ji_biao.tres")
# dangqian_yuzhi() 内 SHENG_JI_YUZHI → sheng_ji_biao.yuzhi_zu（两处）

# 2) 选卡入账（追加在文件后部）
signal ka_yi_xuan(ka: QiangHuaKa)  # 选卡完成：第 7 课强化系统连接此信号生效
var yi_xuan_ka: Array[QiangHuaKa] = []  # 本局已选强化卡（唯一所有者仍是账本）


func xuan_ka(ka: QiangHuaKa) -> void:
	# 选卡唯一入口：入账 + 广播（效果第 7 课在信号回调里生效）
	yi_xuan_ka.append(ka)
	ka_yi_xuan.emit(ka)
```

## 六、分步实现顺序

1. **step-01**：数据层——两个模具 + 7 张 .tres + zhang_ben.gd 阈值读表（F5 行为零变化）
2. **step-02**：弹窗骨架——场景搭建 + Main 实例化 + 注册表拖入（默认隐藏，F5 零变化）
3. **step-03**：升级触发——连接 sheng_ji、暂停、抽样、填按钮、显示（F5 可见冻结+弹卡）
4. **step-04**：选择入账——xuan_ka 接口 + 按钮回调 + 解冻隐藏（F5 完整闭环）

每步跑 `--headless --import` + `--fixed-fps 60 --quit-after 360`。

## 七、验证计划

### 自动化

- `"$GODOT_BIN" --version` 输出 4.7.x
- `"$GODOT_BIN" --headless --path . --import` 退出码 0（每步）
- `"$GODOT_BIN" --headless --path . --fixed-fps 60 --quit-after 360` 退出码 0
- `PYTHONUTF8=1 python .../check_task_scope.py check docs/development_tasks/TASK-006_shengji_sanxuanyi` 无违例

### 手动（学生主导）

- 升级瞬间全场冻结、弹 3 张互不相同的卡
- 点选后立即恢复游动；远程树 Yi Xuan Ka 追加
- 两次升级两次弹窗、卡组合不同
- 全量回归：移动/生成/回收/判定/无敌/涨条/长大

## 八、故障排查提示

| 现象 | 优先检查 |
|---|---|
| 升级冻结但按钮点不动 | 弹窗根节点 Process Mode 是否 = When Paused（默认 Pausable 会跟着冻结） |
| 冻结后游戏再也恢复不了 | _on_ka_dian 是否先 xuan_ka 再 paused=false；按钮 pressed 是否连接成功 |
| 三张卡有重复 | 是否直接对 ka_zu pick_random 三次（放回了）；应 duplicate→shuffle→slice |
| 连抽两次卡组合完全一样 | 是否 shuffle 前没 duplicate（对原表 shuffle 无害但表被洗乱）；slice 是否写死旧数组 |
| 卡文本空白 | .tres 的 ming_zi/miao_shu 是否填了；注册表数组是否拖入 6 张 |
| 升级阈值感受变了 | sheng_ji_biao.tres 数值是否 [8,20,35,55,80,110]；dangqian_yuzhi 两处是否都换读表 |
| 改表不生效 | preload 是编译期加载——改 .tres 后需重新运行 F5 |

## 九、范围边界

- 白名单以 `TASK_MANIFEST.json` 为准；未登记文件一律不改
- zhang_ben.gd 只允许两处修改（阈值读表 + xuan_ka 接口），jia_jing_yan/旧信号/MEI_JI_TIXING 零碰
- 新增生产文件：3 个脚本（各 + .uid）、1 个场景、7 张 .tres；修改 2 个生产文件 + 文档

## 十、审批

等待用户明确回复「确认 TASK-006 v1 进入开发」后：捕获实现基线 → orientation 检查点（含两项复述抽查 + 两个设计决策）→ 开始 step-01。
