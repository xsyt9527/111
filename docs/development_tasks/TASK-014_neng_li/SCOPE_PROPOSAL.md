# TASK-014 范围提案（SCOPE_PROPOSAL）

## 任务目标

把「升级抽 5 张旧 buff 卡」换成「吃谁得谁」的鱼类能力系统：

- 每种鱼的能力只有一份 `NengLi` 定义，玩家与 NPC 共用。
- 玩家升级时三选一获得能力；主动能力占唯一槽，被动能力可叠层。
- 主动能力由屏幕右下角按钮释放，按钮显示名称与冷却。
- 旧 5 张强化卡整体退役，不做兼容垫片。

## 范围内

### 数据层

- 新增 `scripts/neng_li.gd`（`class_name NengLi extends Resource`）与 `data/nengli/` 5 个 `.tres`。
- `YuZhong` 新增 `neng_li: NengLi`；5 个鱼种挂能力，4 个鱼种保持 `null`。
- 删除 `YuZhong.dian_ma` / `du_xing`，能力数值不再双源。

### 账本与获取

- `ZhangBen` 增加：主动槽、被动层数字典、本局获得历史、食谱计数、最常吃 id、`neng_li_zhuang_bei` 广播。
- `NengLiChou`：排除当前主动；50% 概率强制加入本局最常吃的能力；Fisher-Yates + 注入 RNG；不足 3 个返回全部；0 个返回空。
- `NengLiDanChuang`：暂停三选一、卡面说明、连续升级排队、0 候选自动解冻。
- 玩家消化完成时才调用 `ji_chi_yu`，保证「吞下不等于吃到手」。

### 玩家侧

- 首版 5 个能力：放电麻痹（主动）、毒棘护体（被动）、极速突进（主动）、蛮力冲撞（主动）、潜伏突袭（主动）。
- `NengLiUI`：右下技能按钮、冷却条、就绪文字、被动层数列表。
- 切换主动时清理极速/冲撞/潜伏中间状态，冷却归零。

### NPC 侧

- 电鳐/蓑鲉改读 `NengLi`（NPC 数值 55/45）。
- 旗鱼突进、金枪鱼冲撞、巨口鱼潜伏。
- 普通鱼索敌与首领追击跳过潜伏中的玩家。

### 退役

- `QiangHuaKa`、`QiangHuaDanChuang`、`data/qianghua/` 5 张卡、催肥卡、旧坏卡夹具全部删除。
- `ZhangBen` 旧卡账本、`Yu` 旧卡 match、`JieSuan` 旧卡读取、`Main.tscn` 旧弹窗实例全部删除。
- `tests/` 旧卡断言替换为能力断言。

## 范围外

- 长矛穿刺（剑鱼）、拟态隐身（桶眼鱼）。
- 技能升级、技能图标、局外解锁。
- TASK-016 地图逐格封锁。
- 音效、难度两档。
- 修改 `.agents/skills/**`（只读）。

## 零触碰 / 兼容约束

- `JiQiChuan` 的单参 `shou_dao_yao_ji(伤害)` 必须继续可用：`Yu.shou_dao_yao_ji` 的来源与部位参数必须有默认值。
- 放电玩家主值 100、NPC 覆写 55；不能把两者合并成一个数，否则电鳐节奏会被破坏。
- 冲撞期间必须屏蔽嘴圈整吞与自动咬；冲撞结束下一帧恢复。
- 潜伏只影响索敌，不影响碰撞、咬击与技能命中。

## 执行中范围变更

| 变更 | 原因 | 性质 |
|---|---|---|
| 旧卡系统整体删除，而不是仅隐藏 | 用户拍板「全部退役」；脚本删除后保留 `.tres` 只会变成坏引用 | 已批准目标内的必要收尾 |
| `tests/pao_pi.bat` 第 7 步 `--quit-after 360 → 720` | 新增能力用例等待物理帧变多，360 帧会在收卷前退出 | 测试基建同步，不扩大产品范围 |
| `YuNpc` 新增 6 处 `is_instance_valid` 守卫 | Main 无头运行暴露 stale 引用 `SCRIPT ERROR`，属能力感知代码引入的回归 | 缺陷修复，不扩大范围 |
| `tests/huai_neng_li.tres` 替代 `tests/huai_ka.tres` | 旧卡退役后红测夹具必须换成能力夹具 | 测试夹具替换 |

## 白名单要点

- 新增：`NengLi` / `NengLiChou` / `NengLiDanChuang` / `NengLiUI`、5 个能力资源、新弹窗场景、坏能力夹具、任务包 10 文件。
- 修改：账本、玩家、NPC、鱼种、结算、Main 场景、4 个测试文件、门禁脚本。
- 删除：旧卡脚本/场景/数据/夹具（清单见 `TASK_MANIFEST.json` 的 `retired_files`）。
- 不 commit / 不 push。
