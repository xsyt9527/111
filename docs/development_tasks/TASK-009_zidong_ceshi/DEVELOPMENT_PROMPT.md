# TASK-009: 无头自动测试（tests/ 首建：运行器 + 四域测试 + 跑批入口）

> 引擎：Godot 4.7
> 开发策略：plan_driven
> 参与模式：guided_co_development
> 执行模式：teaching
> 任务规格版本：v1
> 审批状态：awaiting
> 交付状态：proposed
> Git 基线：c3f5fed776bf6c9aaa98cdae013f7e1d90d4fbf2
> 复习技能：godot-gdscript-headless-testing（只读）

## 一、任务目标

八课建成了完整闭环的肉鸽机器，但安全网全靠"我跑一次性探针 + 学生真人 F5"——探针用完即删，回归全凭手点。本课把手工验证**固化成可重复资产**：`tests/` 目录首建，一条命令跑全部测试、失败退出码非零、坏数据当场现形。**产品代码零修改**——只加测试不改游戏。

同时是三笔学习账的清账日：
- **Resource 三分工第 5 验**：学生亲手在编辑器建坏卡夹具 huai_ka.tres（.gd 模具/.tres 数据/检查器填表入口）
- **push_warning vs error 再验**：orientation 复述（第 7 课课后题纠正项）
- **探针手艺转正**：TASK-008 的封顶/重开探针脚本改造成常驻测试

### 完成后可观察结果

- `tests/pao_pi.bat` 一条命令：import → 四域测试依序跑 → `Results: N passed, 0 failed` ×4 → 总体退出码 0
- 故意改坏任何断言或夹具 → 再跑 → FAIL 行现形 + 退出码 1（门禁语义）
- data/ 卡池将来加第 7 张卡：全键校验自动守护——拼错 xiao_guo 当场被抓

## 二、四步实现

### step-01 测试基建 + 账本纯逻辑测试

`tests/ce_zhang_ben.gd`（extends SceneTree）：`_initialize()` 入口 + `assert_eq(actual, expected, label)` 失败计数助手 + passed/failed 计数 + `quit(1 if failed > 0 else 0)`。被测对象 `load("res://scripts/zhang_ben.gd").new()` 独立实例化。用例：记账累加、跨级升级扣减、倍率入账、阈值读表。

**关键纪律：禁用裸 `assert()`**——失败会停在 `quit()` 前，进程永不退出（挂死陷阱）。

### step-02 边界测试（探针转正一）

`tests/ce_bian_jie.gd`：满级封顶（灌 400 到 Lv.7 → 再灌 500 等级不动、广播恰 6 次）+ chong_zhi 归零（弄脏四项 → 归零断言）。全程独立实例，无 Main 无 Autoload。

### step-03 数据全键校验 + 坏卡夹具 + 抽样

`tests/ce_shu_ju.gd`：DirAccess 遍历 data/qianghua/*.tres 逐张校验 xiao_guo ∈ 六键白名单；鱼种表字段校验；**红测**——学生亲手建的 tests/huai_ka.tres 坏卡必须被校验器抓到 FAIL（校验器自己也要被测）；卡片抽样（三选一不放回，每次 3 张互不重复）。

### step-04 判定集成测试 + 跑批入口 + 全量回归

`tests/ce_panding.gd` + `ce_panding_chang_jing.tscn`（探针场景模式转正——`--script` 不加载 Autoload，集成测试走场景）：嘴圈吃/伤区掉血/大鱼进嘴圈无事/同体型伤/贪食只放大嘴圈。`tests/pao_pi.bat`：import → 四域依序 → 任一失败退出码 1。全量回归 F5。

## 三、零触碰红线

产品侧（scripts/ scenes/ data/ project.godot）一个文件都不改。为可测性想改产品代码？停下，升 v2 议。测试夹具永不入 data/ 卡池。无插件无 CI 平台。

## 四、学习契约

| # | 目标 | 验证时机 |
|---|---|---|
| 1 | 复述 Resource 三分工（第 5 验清账） | step-03 亲手建夹具时 |
| 2 | 复述 push_warning vs error | orientation 抽查 |
| 3 | 解释裸 assert() 为何挂死、assert_eq 为何不 | orientation/step-01 |
| 4 | 说出退出码为什么是门禁语言 | step-04 红绿体验 |
| 5 | 解释测试独立性（自带复位不依赖顺序） | step-02 |
| 6 | 说出红测价值（校验器须被坏数据验证） | step-03 |
