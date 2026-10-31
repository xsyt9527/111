# TASK-014 实现报告（IMPLEMENTATION_REPORT）

## 交付概览

能力系统已落地并通过自动化门禁：旧 5 张 buff 卡整体退役，换成 `NengLi` 数据驱动的「吃谁得谁」体系。玩家 5 个能力、NPC 侧 5 种能力消费（4 个主动行为 + 蓑鲉被动反毒）、升级三选一、右下技能按钮、被动叠层、结算能力列表全部接通。七步门禁 **382 条断言全绿**（102 / 21 / 47 / 8 / 11 / 193），Main 无头 900 帧无 ERROR。

| 指标 | 结果 |
|---|---|
| 门禁 | `tests/pao_pi.bat` 七步全绿，382 条断言 |
| 主场景无头 | 900 帧，0 ERROR |
| 能力数据 | 5 个 `NengLi` `.tres`，5 个鱼种挂载，4 个鱼种 `null` |
| 玩家能力 | 4 主动 + 1 被动；右下按钮 + 冷却条 + 被动列表 |
| NPC 能力 | 电鳐放电、蓑鲉反毒、旗鱼突进、金枪鱼冲撞、巨口鱼潜伏 |
| 旧卡退役 | 脚本 2 + 场景 1 + 数据 6 + 夹具 1 全删；账本/玩家/结算/主场景旧链清零 |
| 测试 | `ce_panding` 新增 6 组能力集成用例（6p~6u），总 193 条 |
| 范围 | 不 commit / 不 push |

## step-01 能力数据层

| 文件 | 内容 |
|---|---|
| `scripts/neng_li.gd`（新） | `class_name NengLi extends Resource`；字段 `bian_hao` / `ming_zi` / `miao_shu` / `lai_yuan` / `lei_xing` / `leng_que` / `chi_xu` / `ban_jing` / `shu_zhi` / `npc_shu_zhi` / `fu_shu_zhi` / `npc_jian_ge` / `ceng_jia`；方法 `shi_zhu_dong()` / `npc_zhi()` / `ceng_shu_zhi(ceng)` |
| `data/nengli/*.tres`（新 5 个） | 放电麻痹、毒棘护体、极速突进、蛮力冲撞、潜伏突袭；数值见下表 |
| `scripts/yu_zhong.gd` | 新增 `@export var neng_li: NengLi = null`；删除 `dian_ma` / `du_xing` |
| `data/yuzhong/*.tres` | 电鳐→放电、蓑鲉→毒棘、旗鱼→极速、金枪鱼→冲撞、巨口鱼→潜伏；蓝鱼/红鱼/剑鱼/鲸鲨保持 `null` |

| 能力 | 类型 | 冷却 | 持续 | 半径 | 主值 | NPC 覆写 | 副值 | NPC 间隔 | 每层 |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 放电麻痹 | 主动 | 6.0 | 0 | 90 | 100 | 55 | 0 | 1.5 | 0 |
| 毒棘护体 | 被动 | 0 | 0 | 0 | 45 | 0 | 0 | 0 | 15 |
| 极速突进 | 主动 | 8.0 | 0.8 | 260 | 2.0 | 0 | 0 | 6.0 | 0 |
| 蛮力冲撞 | 主动 | 9.0 | 0.45 | 240 | 2.0 | 0 | 2.2 | 7.0 | 0 |
| 潜伏突袭 | 主动 | 10.0 | 2.0 | 0 | 2.0 | 0 | 0 | 8.0 | 0 |

设计要点：`npc_zhi()` 让同一份数据在玩家和 NPC 身上取不同数值，电鳐玩家 100 / NPC 55 是唯一分叉点；`ceng_shu_zhi()` 让毒棘第 1 层 45、第 2 层 60、第 3 层 75。

## step-02 账本、三选一与弹窗

| 文件 | 内容 |
|---|---|
| `scripts/zhang_ben.gd` | 新增 `neng_li_zhuang_bei` 信号；`zhu_dong_neng_li`、`bei_dong_ceng`、`yi_xuan_neng_li`、`chi_yu_ji_lu`、`zui_duo_bian_hao`；`xuan_neng_li` / `dang_qian_bei_dong_ceng` / `ji_chi_yu`；`chong_zhi` 全部复位；删除旧卡字段与方法 |
| `scripts/neng_li_chou.gd`（新） | `ke_xuan_chi` 排除当前主动；`shi_fou_qiang_zhi` 50%；`chou_san_zhang` 强制项→Fisher-Yates→补满→再洗；空池返回空 |
| `scripts/neng_li_dan_chuang.gd`（新） | 监听 `sheng_ji`；暂停全场；3 张卡；卡面显示来源、主动替换提示、被动层数；连续升级排队；0 候选自动解冻 |
| `scenes/NengLiDanChuang.tscn`（新） | `CanvasLayer`，`layer=100`，`process_mode=3`（WHEN_PAUSED）；`neng_li_zu` 注册 5 个 `.tres` |
| `scenes/Main.tscn` | 旧 `QiangHuaDanChuang` 实例换成 `NengLiDanChuang` |
| `scripts/jie_suan.gd` | 结算页显示「主动：xxx」与被动层数；无能力显示兜底文案 |

获取链路：玩家吞鱼 → 消化槽 3 秒 → 消化完成先 `ZhangBen.ji_chi_yu(neng)` 再 `jia_jing_yan` → 升级信号 → 弹窗按最新食谱抽 3 个能力。这样本次升级就能看到刚吃下的鱼种。

## step-03 玩家 5 个能力与技能按钮

| 能力 | 实现 |
|---|---|
| 放电麻痹 | `_shi_fang_fang_dian` 扫 `yu_npc` 组，半径 90 内 `jia_dian_ma(100)`；满条 → 2 秒失控；玩家闪蓝 0.15 秒；冷却 6 秒 |
| 毒棘护体 | `shou_dao_yao_ji` 在无敌检查之后、扣血之前反毒；层数从账本读、数值从 `NengLi.ceng_shu_zhi` 读；咬/撞两条入口都传来源 |
| 极速突进 | `_su_du_bei_lv=2.0`、`_su_du_sheng_yu=0.8`；立即把当前速度抬到 `yidong_sudu×2`；到期回 1.0 |
| 蛮力冲撞 | 锁方向 0.45 秒，速度 ×2.2；每帧扫 `yao_qu`，伤害 = `ZhanDou.yao_ji_shang_hai(tixing,zui_ba)×2`；按 instance_id 去重；不整吞；期间屏蔽嘴圈吞/自动咬 |
| 潜伏突袭 | `yin_shen=true`、2 秒、alpha 0.45、`_qian_fu_zhun_bei=true`；下一口 ×2；咬中/受伤/到期/切主动破隐 |

`Yu.shi_fang_zhu_dong()` 是唯一释放入口：无主动、冷却中、失控、施放中都返回 `false`，成功才写 `zhu_dong_leng_que`。`_on_neng_li_zhuang_bei` 在主动替换时调用 `_qu_xiao_shi_fang()` 并把冷却归零。

`scripts/neng_li_ui.gd`（新）：右下 `JiNengAnNiu` 显示能力名；`LengQueTiao` 显示进度；`LengQueLabel` 显示「就绪/冷却 x.xs」；`BeiDongLabel` 显示「毒棘 ×2」；按钮在失控、冷却、施放中禁用；`focus_mode=NONE` 防键盘误触。

## step-04 NPC 能力与潜伏感知

| 鱼 | 行为 |
|---|---|
| 电鳐 | `_fang_dian` 改判 `bian_hao`；半径读 `ban_jing`；数值 `npc_zhi()=55`；间隔 `npc_jian_ge=1.5`；`_ready` 错峰初值同步 |
| 蓑鲉 | 被咬/被吞时对来源 `jia_du_yun(npc_zhi()=45)`；NPC 不叠层 |
| 旗鱼 | `_chang_shi_neng_li` 在距离 200px 左右启动，`_tu_jin` 0.8 秒 ×2 速，够近就咬，冷却 6 秒 |
| 大眼金枪鱼 | 150px 左右启动，`_chong_zhuang_npc` 0.45 秒 ×2.2 速，伤害 ×2，每目标一次，冷却 7 秒 |
| 巨口鱼 | `_qi_dong_yin_shen_npc` 潜伏 2 秒，下一口 ×2，冷却 8 秒；受击/失控/咬中破隐 |
| 首领 | 玩家 `yin_shen` 时清空追击计时并放弃目标 |
| 普通鱼 | `_si_kao` 与 `_xing_dong` 跳过潜伏玩家；已追击的放弃目标；突进/冲撞落空 |

所有新行为只插在普通鱼分支；Boss 走 `_boos_xing_dong`，不读 `_neng_li`。失控 `_chu_fa_yun_xuan` 统一清空突进/冲撞/潜伏并恢复 alpha。

## step-05 旧卡退役与测试同步

删除清单：

- `scripts/qiang_hua_ka.gd` + `.uid`
- `scripts/qiang_hua_dan_chuang.gd` + `.uid`
- `scenes/QiangHuaDanChuang.tscn`
- `data/qianghua/` 5 张卡（迅捷/贪食/活力/睿智/磁吸）
- `data/qianghua_tuiyi/cui_fei.tres`
- `tests/huai_ka.tres`（换为 `tests/huai_neng_li.tres`）
- `ZhangBen` 的 `ka_yi_xuan` / `yi_xuan_ka` / `jing_yan_jia_cheng` / `she_jing_yan_jia_cheng` / `xuan_ka`
- `Yu` 的 `_on_ka_yi_xuan` 与 match 分支
- `JieSuan` 的 `yi_xuan_ka` 读取、`Main.tscn` 旧弹窗实例

测试同步：

- `ce_zhang_ben`：用例 3 改为能力装备/替换/叠层/广播/食谱/平局/复位；总数 102。
- `ce_bian_jie`：脏状态改主动/被动/能力食谱，复位断言能力容器全空；总数 21。
- `ce_shu_ju`：5 个能力校验、鱼种映射、坏能力双红测、200 轮抽样、50% 命中率；总数 47。
- `ce_panding`：新增 6p~6u 六组集成用例；总数 193。
- `pao_pi.bat` 第 7 步 `--quit-after 360 → 720`，避免新增用例等待物理帧导致收卷前退出。

## 过程中修掉的问题

| 问题 | 根因 | 修复 |
|---|---|---|
| 放电测试靶鱼被吞 | 靶鱼放在 70px，进入嘴圈 ZuiQu 55×缩放；物理帧触发 `_on_zui_qu_entered` | 改 1 级靶鱼、放 80px（嘴圈外/放电半径内），等两个物理帧 |
| 冲撞伤害断言为 0 | `_chong_zhuang` 手动瞬移后同帧读 `get_overlapping_areas()`，Area2D 重叠列表未刷新 | 测试先位移、等物理帧、再调结算；去重检查同样等待 |
| 巨口鱼下一口期望值错 | 巨口鱼 `zui_ba=1.5`，3 级伤害 0.75，×2=1.5，玩家 5.0→3.5 而非 4.0 | 期望值改为 `ZhanDou.yao_ji_shang_hai(3.0, ju_kou.zui_ba)*2` 动态算 |
| 门禁第 7 步缺 Results | 新增用例等待帧多，`--quit-after 360` 提前退出 | 改 720 |
| Main 高频 freed instance ERROR | NPC 新代码直接 `_mu_biao is Yu`，目标已释放 | 6 处 `is_instance_valid()` 守卫 |
| 旧卡场景仍在盘上 | 旧卡删除后 Godot 编辑器重存 `QiangHuaDanChuang.tscn`（补 `uid` / `unique_id`），文件仍在且引用已删脚本/数据 | 交付前最终扫描发现并删除；重新 `--import` 与七步门禁复跑均无坏引用 |

## 关键设计决策

1. **一份定义两处消费**：`NengLi` 同时服务玩家与 NPC；`npc_shu_zhi` / `npc_jian_ge` 只做覆写，不复制数据。
2. **能力是数据不是类**：加新鱼能力只需加 `.tres` + 鱼种引用，效果分派仍集中在 `match bian_hao`。
3. **账本是能力唯一所有者**：玩家和 UI 都读 `ZhangBen`，不各自存一份槽位。
4. **三选一纯函数 + 注入 RNG**：测试可复现，弹窗可 `randomize()`，互不污染。
5. **主动唯一槽 + 被动叠层**：符合「主动 1 个、被动可叠」的 build 目标；切换主动必须清中间状态。
6. **潜伏只改感知**：不改碰撞、不改咬击；破隐三种时机明确。
7. **旧卡五层退役**：脚本/场景/数据/账本/测试一起删，grep 无残留。

## 遗留（不阻塞本任务）

- 剑鱼长矛穿刺、桶眼鱼拟态隐身未做。
- 技能升级、技能图标、局外解锁未做。
- 放电不命中机器船（`JiQiChuan` 不在 `yu_npc` 组）；是否让玩家用电打船留待后续平衡。
- NPC 潜伏只有半透明表现，其他 NPC 仍能看见它；若要做「NPC 互相潜伏」需扩展感知。
- 冲撞用 Area2D 重叠查询，极端掉帧时可能穿过小鱼；后续可换形状投射。
