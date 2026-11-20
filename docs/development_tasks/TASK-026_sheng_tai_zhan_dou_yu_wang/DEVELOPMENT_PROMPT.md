# TASK-026：生态精简、毒鱼耐受、咬伤经验与 NPC 鱼王成长

> 引擎：Godot 4.7
> 开发策略：plan_driven
> 参与模式：guided_co_development
> 执行模式：teaching
> 任务规格版本：v1
> 审批状态：awaiting
> 交付状态：proposed
> Git 基线：f27ae56893aed50db99ca6572659966bbca09b27

## 一、任务目标

回应用户 2026-11-14 的四项实机反馈：野外鱼种太多且后期只剩高等级鱼；前期狮子鱼毒晕过重；咬比自己大的鱼没有经验，双方缩小后形成僵局；NPC 鱼隐藏成长只涨体型，规则上永远只有鲸鲨是 Boss。

完成后，玩家在 40 秒内不会再遇到狮子鱼，后期仍能看到 1 级鱼；连续吃毒鱼时毒晕收益递减；咬大鱼能按实际掉肉获得经验并减轻同一目标的接触伤害；任意鱼种只要隐藏等级升到 10 就可能成为鱼王，雷达显示金点、不可整吞、不逃跑，残血败退给大肉与经验。

### 完成后可观察结果

- 野外抽鱼 1000 次不出现 `hong_yu`、`an_ying_jian_yu`；`_dang < 2` 时不出现 `cheng_yu`。
- `YuQun.shua_xin_zui_di()` 在 0~4 档全部返回 1，低等级鱼全期可刷。
- 连续吃毒鱼：45 / 31.5 / 18 / 13.5，停吃 8 秒后逐层消退。
- 普通咬击按目标实际掉肉 ×5 给经验；同目标 0.6 秒内接触伤害 ×0.2。
- `deng_ji_nei >= 10` 的 NPC 晋升鱼王，每房最多 2 只；雷达金点；不可整吞；不逃跑；败退给 3 块大肉与 2 倍鱼种经验；`bei_ji_bai` 信号计数为 0。

### 本任务不做

- 不新增 Autoload、不改存档 schema、不改主场景顶层结构或 `project.godot`。
- 不删除鱼种 `.tres`、图鉴、选角卡、进化树或专属技。
- 不给鱼王复用 `shi_boss`，不改鲸鲨的 15 倍咬伤、30 秒成长或 Main 提前开战逻辑。
- 不重做九图结尾演出（TASK-028）；不重制音频（TASK-027）。

## 二、当前工程状态

### 已实现并验证

- TASK-025：九宫格 9 房鱼群记录、换房保存/加载、未加载房虚拟游动与互吃、雷达九房 NPC 点；八步门禁 3087 断言全绿，机器人探针胜利 576.9 秒。
- 野外刷鱼在 `scripts/yu_qun.gd`：`_chou_yu_zhong()`、`shua_xin_zui_di()`、`shua_xin_shang_xian()`、`deng_ji_gai_lv()`。
- 玩家毒晕在 `scripts/zhang_ben.gd`：`du_yun`、`jia_du_yun()`、`geng_xin_kong_zhi()`。
- 玩家咬击在 `scripts/yu.gd`：`_chang_shi_yao_ji()`、`_yao_ji_lian_dong()`、`_on_shang_qu_entered()`。
- NPC 隐藏成长在 `scripts/yu_npc.gd`：`deng_ji_nei`、`jing_yan_nei`、`jia_jing_yan_nei()`、`_sheng_ji_yu_zhi()`。
- 雷达绘制在 `scripts/xiao_di_tu.gd`：`_hu_npc()`、`_hua_dian()`、`_hua_shou_ling()`。

### 已存在但未验证或未接通

- 鱼王身份、鱼王名额、鱼王败退与雷达金点均不存在。
- 咬击只扣目标体型、不给经验；接触伤害无同目标短减免。
- 毒抗只存在于设计文档，代码无字段与入口。

### 审计新鲜度

- audited_commit：`f27ae56893aed50db99ca6572659966bbca09b27`
- environment_checked_at：`2026-11-14T20:10:03+08:00`
- engine_executable_source：`GODOT_4_7_BIN`
- engine_version_detected：`4.7.2.stable.official.ed1daf0bf`
- audit_invalidation_triggers：刷鱼/毒晕/咬击/隐藏成长/雷达接口、存档 schema、Autoload、主场景或引擎版本变化

### 当前依赖与阻塞

- 依赖 TASK-025 的九房记录与虚拟互吃；本任务直接修改 `yu_qun.gd`。
- 依赖 TASK-019/024 的伤害与统一结算入口；不得改变机械船与鲸鲨既有语义。
- 基线提交 `f27ae56893aed50db99ca6572659966bbca09b27` 已包含 TASK-022~025 全部产物，工作区干净。

## 三、功能所有权与团队集成

### 功能所有者

- owner_id：`student-01`
- owned_systems：野外鱼池、毒抗、咬伤经验、NPC 鱼王、雷达鱼王标记
- owned_scenes：无
- owned_scripts：`yu_qun.gd`、`yu_npc.gd`、`zhang_ben.gd`、`yu.gd`、`xiao_di_tu.gd`、`fen_yu.gd`
- owned_config_tables：无

### 集成合同

| 类型 | 名称/路径 | 提供方 | 使用方 | 合同 | 变更风险 |
|---|---|---|---|---|---|
| 依赖 | TASK-025 九房记录 | `YuQun` | 本任务 | 记录字段 `zhong/wei/ti/nei_deng/nei_jing_yan/node` | 不新增 `wang` 键 |
| 消费 | `_chou_yu_zhong()` | `YuQun` | 刷鱼 | 返回 `YuZhong` 或 null | 过滤不得改变注册表 |
| 消费 | `jia_du_yun(liang)` | `ZhangBen` | 毒鱼/技能 | 原签名与精确值不变 | 不在此函数内打折 |
| 消费 | `shou_dao_yao_ji(shang_hai, lai_yuan, lai_yuan)` | `YuNpc` | 玩家攻击 | 目标实际体型变化 | 经验必须在联动之后读取 |
| 提供 | `YuQun.yu_wang_shu()` | 本任务 | `YuNpc` 晋升 | 九房记录与当前实体去重计数 | 记录是唯一权威 |
| 提供 | `YuNpc.yu_wang` | 本任务 | 雷达、守卫 | `true` 表示鱼王身份 | 不复用 `shi_boss` |
| 提供 | `ZhangBen.jia_du_yun_chi_du_yu()` | 本任务 | `YuNpc.bei_chi()` | 只对进食毒鱼生效 | 非进食毒源仍走原入口 |
| 发出 | 无新增信号 | 本任务 | — | 鱼王败退不 emit `bei_ji_bai` | 误发会触发机械船 |

### 禁止的跨功能访问

- 禁止用 `get_tree().get_nodes_in_group("yu_npc")` 全表清理或统计鱼王；只能通过 `YuQun` 记录与 `yu_wang` 组读身份。
- 禁止修改 `scenes/Main.tscn`、`project.godot`、Autoload 或存档字段。
- 禁止在 `zhuan_shu_ku/*.gd` 中复制一套鱼王判定；只允许 `fen_yu.gd:_ke_chi()` 做最小排除。

## 四、学生参与与学习目标

### 学习目标

- 学生能够定位 `yu_qun.gd` 的抽样循环，解释为什么过滤应放在池内而不是删除 `.tres`。
- 学生能够打开 `ZhangBen` 相关脚本，解释毒抗窗口与层数如何影响 `du_yun`。
- 学生能够指出 `_chang_shi_yao_ji()` 中经验读取必须晚于 `_yao_ji_lian_dong()` 的位置。
- 学生能够检查鱼王晋升后的节点组与雷达金点，解释为什么不复用 `shi_boss`。
- 学生能够运行门禁并解释鱼王败退 `bei_ji_bai` 计数为 0 的意义。

### 三个必需检查点

1. **实现前定位与理解**：确认任务目的、受影响脚本、一个核心概念（池内过滤 / 状态窗口 / 按实际状态差结算 / 数据推导身份）和一个有限设计选择。
2. **实现后 Godot 检查**：打开 `res://scenes/Main.tscn`，运行 F5，观察雷达金色鱼王点、毒晕条递减、咬大鱼经验增长；或在编辑器检查 `YuQun`/`YuNpc` 脚本字段。
3. **验证与交接**：运行或解释 `tests/pao_pi.bat`、探针结果与 `INTEGRATION_HANDOFF.md` 的入口、输入、输出、依赖。

### 参与边界

| 工作项 | AI 主导内容 | 学生参与内容 | 客观证据 |
|---|---|---|---|
| 鱼池过滤 | 常量、抽样循环、测试 | 指出抽样循环位置并解释过滤与删文件差异 | `project_navigation`、`concept_explanation` |
| 毒抗 | 字段、入口、衰减、测试 | 在 F5 连吃两条狮子鱼并读毒晕条 | `editor_operation`、`result_interpretation` |
| 咬伤经验 | 结算顺序、小数池、减免 | 指出经验读取位置并解释为什么不能提前 | `concept_explanation` |
| 鱼王 | 晋升、守卫、败退、雷达 | 雷达金点与鱼王残血败退目检 | `scene_tree_inspection`、`test_execution` |
| 收尾 | 门禁、探针、报告 | 解释探针基线对比结论 | `test_execution`、`result_interpretation` |

### 防卡住与恢复规则

- 学生第一次表示不知道或不会操作时，AI 立即演示最小完整步骤，再让学生复述原理或检查一个明确结果；仍无法识别时由 AI 说明正确观察、记录待巩固概念并继续已批准活动，不重复追问。
- AI 演示最多记录为 `introduced`；只有学生实际复述、识别、应用或诊断后才提高理解等级。
- Godot 编辑器不可用时，改为检查指定 `.gd`、`.tscn`、测试输出或截图，并记录真实证据类型。

## 五、行为合同与数据流

### 行为合同

- 前置条件：游戏已开局，`YuQun` 已初始化九房记录；玩家 `ZhangBen` 存活。
- 输入：野外抽鱼档位 `_dang`；玩家吃毒鱼；玩家普通咬击；NPC 获得隐藏经验；NPC 受到伤害。
- 状态转换：
  - 抽鱼：过滤退池鱼种 → 档位 2 以下过滤狮子鱼 → 按原等级概率抽样。
  - 毒抗：层数 0/1/2/3 → 倍率 1.0/0.7/0.4/0.3 → 原 `jia_du_yun`。
  - 咬击：记录咬前体型 → 全部结算 → 读取最终体型 → 掉肉 ×5 进小数池。
  - 鱼王：`deng_ji_nei` 9→10 且名额未满 → 晋升；`tixing<=2.0` → 败退。
- 输出：毒晕条数值；经验条增长；雷达金点；鱼王体型与节点组。
- 失败、取消与重试：名额满时停在 9 级并保留经验；目标已到 0.5 时掉肉为 0，不再给经验；非毒鱼进食不做毒抗。
- 边界情况：机械船不给咬伤经验；鱼王败退不 emit `bei_ji_bai`；换房恢复不再重复 +2；虚拟互吃晋升受名额限制。

### 数据流

    野外抽鱼: _dang -> TUI_CHU_PAI_CHI/DU_YU_ZUI_DI_DANG 过滤 -> deng_ji_gai_lv 抽样 -> YuZhong
    毒鱼进食: YuNpc.bei_chi -> Yu.chi_du_yu -> ZhangBen.jia_du_yun_chi_du_yu -> du_yun/层数
    普通咬击: _chang_shi_yao_ji -> shou_dao_yao_ji -> _yao_ji_lian_dong -> 读最终 tixing -> 小数池 -> ZhangBen.jia_jing_yan
    接触伤害: _on_shang_qu_entered -> yu_npc == _yao_ji_mian_shang_mu 且计时>0 -> ×0.2 -> _shoushang
    鱼王: jia_jing_yan_nei -> 等级 10 + yu_wang_shu()<2 -> yu_wang=true -> 记录回写/雷达金点
    败退: shou_dao_yao_ji/tixing<=2.0 -> diao_rou(3) + ZhangBen 2*fenzhi -> si_le/淡出（不 emit bei_ji_bai）

## 六、场景节点树与加载

- architecture_change：false
- entry_scene：`res://scenes/Main.tscn`
- lifecycle_rationale：`YuQun`、`YuNpc`、`ZhangBen`、`Yu`、`XiaoDiTu` 仍保持既有节点与 Autoload 结构；本任务只新增字段、规则分支、运行时组与私有方法，不新增/删除主场景节点，不改加载顺序与存档。

## 七、文件范围

### 允许修改的现有文件

| 路径 | 修改原因 | 所有者 | 是否共享文件 |
|---|---|---|---|
| `scripts/yu_qun.gd` | 池过滤、低等级全期刷、鱼王统计、虚拟晋升守卫 | student-01 | 是（TASK-025） |
| `scripts/yu_npc.gd` | 鱼王身份/晋升/规则/败退、毒鱼抗性调用 | student-01 | 是（TASK-019/024） |
| `scripts/zhang_ben.gd` | 毒抗字段、入口、独立衰减 | student-01 | 是（TASK-008） |
| `scripts/yu.gd` | 咬伤经验、接触减免、鱼王守卫 | student-01 | 是（TASK-019/024） |
| `scripts/xiao_di_tu.gd` | 雷达鱼王金点 | student-01 | 是（TASK-023） |
| `scripts/zhuan_shu_ku/fen_yu.gd` | `_ke_chi()` 排除鱼王 | student-01 | 是 |
| `tests/ce_panding.gd` | 改旧断言、新增用例 | student-01 | 是 |
| `docs/TASK_INDEX.md` 等 | 任务与词表收尾 | student-01 | 是 |

### 允许新增的文件

| 路径 | 职责 | 调用方 |
|---|---|---|
| `docs/development_tasks/TASK-026_.../IMPLEMENTATION_REPORT.md` | 实现报告 | 团队 |
| `docs/development_tasks/TASK-026_.../VERIFICATION_REPORT.md` | 验证报告 | 团队 |
| `docs/development_tasks/TASK-026_.../CODE_REVIEW.md` | 缺陷优先审查 | 团队 |
| `tests/_tmp_yu_wang_probe.gd/.tscn/.uid` | 临时机器人探针，跑完删除 | 验证 |

### 禁止修改的系统

- 新增 Autoload、存档 schema、`project.godot`、`scenes/Main.tscn` 顶层结构。
- 鱼种 `.tres`、图鉴、选角、进化树、专属技内容。
- 鲸鲨 `shi_boss` 规则与 `bei_ji_bai` 语义。
- 九图结尾演出、音频资源。

## 八、分步实现

### Step 1：野外鱼池精简、狮子鱼延后与低等级全期可刷

**目标行为**：`_chou_yu_zhong()` 永不返回 `hong_yu`/`an_ying_jian_yu`；`_dang<2` 不返回 `cheng_yu`；`shua_xin_zui_di(dang)` 恒 1。

**核心概念**：池内过滤——刷鱼池是运行时抽样集合，不是鱼种注册表。误用时的可观察失败是删掉 `.tres` 后选角页/图鉴/进化树加载失败。

**涉及文件**：`scripts/yu_qun.gd`、`tests/ce_panding.gd`。

**AI 实现内容**：新增 `TUI_CHU_PAI_CHI`、`DU_YU_ZUI_DI_DANG`；在 `_chou_yu_zhong()` 的 `mei_ji_shu` 统计循环与抽样循环同时跳过退池鱼种与前期狮子鱼；`shua_xin_zui_di()` 改为恒 1，删除 `SHUA_XIN_ZUI_DI_FENG_DING` 或改为注释说明；改写 `shua_xin_zui_di` 与 `biao_1[1]` 旧断言；新增 1000 次抽样与档位门用例。

**学生参与点**：检查点 `orientation`；打开 `scripts/yu_qun.gd` 的 `_chou_yu_zhong()`，指出两处需要过滤的循环，并解释为什么不能直接删除 `.tres`。

**设计选择**：A. 过滤放在 `_chou_yu_zhong()` 两个循环内（推荐，注册表完整）；B. 从 `yu_zhong_zu` 中移除退池鱼种（会导致选角/图鉴/进化树缺项，不推荐）。

**自动验证**：`tests/ce_panding.gd` 断言 1000 次无退池鱼种、档位门、`shua_xin_zui_di` 全 1。

**Godot 检查**：headless `--import` 0 ERROR；F5 前 40 秒观察无狮子鱼、后期仍见 1 级蓝鱼。

**验证含义**：证明野外抽样集合被收敛，不证明前期节奏一定更好；节奏需 F5/探针。

**记录要求**：更新 `TASK_STATE.json` step-01、`LEARNING_STATE.json` 概念与证据、`LEARNING_RECORD.md`。

**通过条件**：上述断言全绿，旧 `biao_8` 档位断言同步更新且无假绿。

### Step 2：毒鱼连吃递减耐受

**目标行为**：连吃毒鱼 45 → 31.5 → 18 → 13.5；停吃 8 秒后每 2 秒退层；非进食毒源不变。

**核心概念**：状态窗口与递减层数——同一事件短时间重复时收益递减。误用时的可观察失败是把 `jia_du_yun` 直接打折，导致现有 45/55/60 精确断言全红。

**涉及文件**：`scripts/zhang_ben.gd`、`scripts/yu.gd`、`scripts/yu_npc.gd`、`tests/ce_panding.gd`。

**AI 实现内容**：新增 `du_kang`、`_du_kang_ceng`、`_du_kang_shi_jian`、`_du_kang_tui_ji`；新增 `jia_du_yun_chi_du_yu()`（先按 1.0/0.7/0.4/0.3 打折，再层数+1、窗口归零）；新增 `_geng_xin_du_kang(delta)`，放在 `_process` 失控判断之前；`Yu.chi_du_yu()` 委托；`YuNpc.bei_chi()` 毒鱼分支优先调用 `chi_zhe.chi_du_yu()`，否则回退原 `jia_du_yun()`；`chong_zhi()` 清零。

**学生参与点**：检查点 `orientation`/F5 目检；连吃两条狮子鱼，读毒晕条数值变化。

**设计选择**：A. 新入口 `jia_du_yun_chi_du_yu()`（推荐，保留原精确断言）；B. 给 `jia_du_yun` 加第二参数（会破坏 45/55/60 断言，不推荐）。

**自动验证**：45/31.5/18/13.5、第 5 条 13.5、8 秒退层、重新吃刷新、`jia_du_yun(45)` 仍 45、`chong_zhi()` 清零。

**Godot 检查**：F5 连续吃毒鱼不再两条即失控。

**验证含义**：证明进食毒源的递减，不证明被咬/毒腺等非进食毒源被削弱（它们按设计不变）。

**记录要求**：同 Step 1 对应字段。

**通过条件**：新增毒抗断言全绿，既有毒晕精确断言未改。

### Step 3：咬大鱼按掉肉给经验与同目标接触减免

**目标行为**：普通咬击按实际掉肉 ×5 给经验；同一目标 0.6 秒接触伤害 ×0.2。

**核心概念**：按实际状态差结算——以结算后的真实掉肉为依据，而不是按命中次数。误用时的可观察失败是在 `_yao_ji_lian_dong()` 之前读取体型，撕裂齿等额外掉肉漏算。

**涉及文件**：`scripts/yu.gd`、`tests/ce_panding.gd`。

**AI 实现内容**：新增 `YAO_SHANG_JING_YAN_MEI_TI=5.0`、`YAO_JI_MIAN_SHANG_SHI_JIAN=0.6`、`YAO_JI_MIAN_SHANG_JIAN_MIAN=0.8`；新增 `_yao_shang_jing_yan`、`_yao_ji_mian_shang_mu`、`_yao_ji_mian_shang_ji_shi`；在 `_chang_shi_yao_ji()` 全部结算后读取最终 `tixing`，`sun_shi=max(0,mu_ti_xing-tixing)`，累加 `sun_shi*5`，满 1 转 `ZhangBen.jia_jing_yan(int)`；机械船跳过；整吞/致命区分支提前 return；`_on_shang_qu_entered()` 对同目标且计时>0 乘 0.2；`_process` 递减计时。

**学生参与点**：检查点 `orientation`；打开 `_chang_shi_yao_ji()`，指出经验读取位置必须在 `_yao_ji_lian_dong()` 之后。

**设计选择**：A. 按实际掉肉给经验（推荐，天然防刷）；B. 按固定命中次数给经验（会在目标 0.5 后无限刷，不推荐）。

**自动验证**：掉 1 点给 5、小数池、0.5 后 0、机械船 0、同目标 0.6 秒 ×0.2、换目标/超时恢复、整吞经验不变；用例边界显式 `ZhangBen.jing_yan=0`。

**Godot 检查**：F5 咬大鱼经验条增长，双方缩小僵局缓解。

**验证含义**：证明咬伤经验来源与减免窗口，不证明整体升级速度合适；系数需探针/F5。

**记录要求**：同 Step 1。

**通过条件**：新增断言全绿，整吞消化断言不变。

### Step 4：NPC 隐藏等级晋升鱼王与名额控制

**目标行为**：`deng_ji_nei>=10` 晋升，每房最多 2 只，第 3 只停在 9 并保留经验；换房恢复不重复加 2。

**核心概念**：由数据推导身份——鱼王不是新鱼种，而是记录隐藏等级达到阈值后的运行时身份。误用时的可观察失败是给记录新增 `wang` 键后，九房记录字段断言与旧存档迁移全部失衡。

**涉及文件**：`scripts/yu_npc.gd`、`scripts/yu_qun.gd`、`tests/ce_panding.gd`。

**AI 实现内容**：新增 `YU_WANG_QI_YONG`、`YU_WANG_DENG_JI=10`、`YU_WANG_MEI_FANG_SHANG_XIAN=2`、`YU_WANG_TI_XING_JIA=2.0`；`YuNpc` 新增 `yu_wang`；`jia_jing_yan_nei()` 在 9→10 前检查 `YuQun.yu_wang_shu()`，名额满 `break` 保留经验；晋升设置身份、+2 体型、`gan_zhi`、`_ying_she_ti_xing()`、加入 `yu_wang` 组、开 `BossPengZhuangQu.monitoring`、隐藏红光、回写当前房记录；`_ready` 末尾 `_geng_xin_yu_wang()` 按 `deng_ji_nei>=10` 恢复身份但不加 2；`YuQun.yu_wang_shu()` 九房记录去重统计；虚拟互吃 9→10 同样检查名额并 +2。

**学生参与点**：检查点 `godot-inspection`；F5 雷达看金点，编辑器检查鱼王节点 `BossPengZhuangQu.monitoring` 与组。

**设计选择**：A. 记录 `nei_deng>=10` 推导身份（推荐，不动记录 schema）；B. 记录新增 `wang` 键（会破字段断言，不推荐）。

**自动验证**：晋升 +2、推挤层、组计数、上限 2、第 3 只停 9、名额释放再晋升、换房恢复不加 2、虚拟记录跨 10 +2。

**Godot 检查**：F5 金点、鱼王体型明显大于同种。

**验证含义**：证明身份与名额逻辑，不证明鱼王行为观感；行为在 Step 5 验证。

**记录要求**：同 Step 1。

**通过条件**：新增鱼王晋升/名额断言全绿，九房记录字段断言未改。

### Step 5：鱼王战斗规则、败退与雷达金点

**目标行为**：鱼王不可整吞、不逃跑、可继续成长；残血给 3 块大肉 + 2 倍鱼种经验后静默消失；`bei_ji_bai` 计数 0；雷达记录/实体去重金点。

**核心概念**：身份守卫与信号语义隔离——同一套伤害入口按 `yu_wang` 分支扩展规则，但绝不借用鲸鲨的 `bei_ji_bai`。误用时的可观察失败是鱼王败退 emit `bei_ji_bai`，Main 误判鲸鲨/机械船提前开战。

**涉及文件**：`scripts/yu_npc.gd`、`scripts/yu.gd`、`scripts/yu_qun.gd`、`scripts/xiao_di_tu.gd`、`scripts/zhuan_shu_ku/fen_yu.gd`、`tests/ce_panding.gd`。

**AI 实现内容**：`bei_chi()`、`_chi_diao()`、`_tun_diao()`、`_chi_zui_bian()`、致命区分支、`_yao_ji` 吞噬扫描、`fen_yu._ke_chi()`、虚拟互吃全部加鱼王守卫；`_ji_zhang_chou_hen()` 对鱼王不设逃跑；`shou_dao_yao_ji()` 残血分支调 `_yu_wang_bai_tui()`，否则走不逃跑分支；`_yu_wang_bai_tui()` 先 `diao_rou(3,1.0)`、给 2 倍 `fenzhi`、再 `si_le=true`/淡出/`queue_free`，不调 `_bei_ji_bai()`；`_jian_cha_yu_wang_bai_tui()` 统一在所有扣体型入口后检查；`_process` 对 `shi_boss or yu_wang` 调 `_tui_kai_zhou_wei()`；`_geng_xin_hong_guang()` 对鱼王隐藏；`_feng_xi_bei()` 允许鱼王吃洋流；雷达记录 `nei_deng>=10` 画金点、实体普通循环跳过鱼王、首领循环改为 `shi_boss or yu_wang`、记录已画当前房鱼王时实体不重复画。

**学生参与点**：检查点 `verification-handoff`；跑鱼王用例，解释 `bei_ji_bai` 计数为 0 的意义。

**设计选择**：A. 独立 `yu_wang` + 统一守卫（推荐，鲸鲨语义不受影响）；B. 复用 `shi_boss`（会触发 15 倍咬伤/30 秒成长/提前开战，不推荐）。

**自动验证**：各吞噬入口拒绝鱼王、不逃跑、继续成长、败退奖励、`bei_ji_bai` 0、雷达去重金点、不触发机械船提前生成。

**Godot 检查**：F5 鱼王残血败退、金点消失、机械船仍按原时间出现。

**验证含义**：证明鱼王规则与信号隔离，不证明鱼王难度手感；需探针/F5。

**记录要求**：同 Step 1。

**通过条件**：新增鱼王战斗/败退/雷达断言全绿，鲸鲨既有断言不变。

### Step 6：测试改写、探针、门禁与文档收尾

**目标行为**：全量验证通过，文档与索引更新，临时探针删除。

**核心概念**：回归基线——用同一机器人探针比较改动前后的难度与稳定性。

**涉及文件**：`tests/ce_panding.gd`、`docs/TASK_INDEX.md`、`docs/引擎词总表.md`、`LEARNING_ROADMAP.md`、`Godot引擎词总表.docx`。

**AI 实现内容**：跑 `MSYS_NO_PATHCONV=1 cmd.exe /c "tests\\pao_pi.bat"` 八步门禁；跑 `validate_task.py`、`check_task_scope.py check`；生成临时探针并对比 TASK-025 基线（576.9 秒、Lv.19、峰值 30.0、换房 34 次、船 517.4 秒/1140HP）；写三份报告；更新任务索引与词表；删除探针。

**学生参与点**：检查点 `verification-handoff`；解释探针结果的时长/等级/鱼王数量与基线差异。

**设计选择**：A. 探针不合格先调鱼王阈值/上限/咬伤系数再复跑（推荐）；B. 直接交付（风险高，不推荐）。

**自动验证**：八步全绿、VALID、0 violation、0 ERROR、探针 `RESULT=SHENG_LI`。

**Godot 检查**：F5 完整一局或用户验收。

**验证含义**：证明回归门禁与机器人可通关，不证明真人体感；用户 F5 为最终口径。

**记录要求**：完成 `TASK_STATE.json`、`LEARNING_STATE.json`、`LEARNING_RECORD.md`、`IMPLEMENTATION_REPORT.md`、`VERIFICATION_REPORT.md`、`CODE_REVIEW.md`、`INTEGRATION_HANDOFF.md`。

**通过条件**：全部必需检查通过；未 commit/push。

## 九、完整验证

### 工程与配置

- GDScript 解析、资源路径、UID、节点路径、信号、Autoload、稳定 ID 无新增；`project.godot` 不改。

### 自动化与 Godot 4.7

- `"$GODOT_BIN" --version` 必须显示 4.7.x；headless `--import` 0 ERROR；`tests/pao_pi.bat` 八步全绿。

### 场景生命周期

- 鱼王晋升/败退后节点释放、组计数、雷达去重；换房恢复不重复加 2；连续晋升不超过每房 2 只。

### Git 范围

- `check_task_scope.py capture` 开工前；`check` 完工后 0 violation。

### 学习证据

- 三个检查点；功能完成而学习未发生则 `learning_status=participation_pending`，不夸大为 demonstrated。

### 集成交接

- `INTEGRATION_HANDOFF.md` 与实际接口一致；在最新基线重跑检查。

## 十、停止条件

- 需要修改范围外文件或新增 Autoload/存档字段。
- 需要复用 `shi_boss` 或让鱼王 emit `bei_ji_bai`。
- 公开接口、主场景或共享配置发生未登记变更。
- 现有毒晕 45/55/60、鲸鲨 `shi_boss`、九房记录字段断言必须改语义才能通过。
- 机器人探针无法稳定胜利且调整阈值后仍失败。

记录证据、更新状态并停止，不得以临时兼容代码绕过。

## 十一、完成与交接定义

- 所有验收行为有测试或 F5 证据。
- 八步门禁、validate、scope、import 全过；缺失必需检查时 `verification_blocked`。
- 代码审查无未解决范围内 P0/P1/P2。
- 最终差异只含允许文件。
- `LEARNING_STATE.json` 不夸大参与。
- `INTEGRATION_HANDOFF.md` 写清入口、输入、输出、依赖、禁止访问、验证与限制。

## 十二、审批

任何能明确表达“同意 TASK-026 v1 进入开发”的用户文本都有效。记录原文、时间与规格版本。建议表达：`确认 TASK-026 v1 进入开发`。
