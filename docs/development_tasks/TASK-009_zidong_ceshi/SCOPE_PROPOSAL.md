# TASK-009 范围提案（SCOPE_PROPOSAL）

## 范围内

- tests/ 目录首建：四域测试 + 跑批入口，**产品代码零修改**
- 测试基建：SceneTree 运行器模式（`extends SceneTree` + `_initialize()` + `assert_eq` 失败计数 + `quit(1 if failed > 0 else 0)`——禁用裸 `assert()` 挂死陷阱）
- 账本纯逻辑测试（ce_zhang_ben.gd）：记账累加 / 跨级升级扣减 / 倍率入账 / 阈值读表——`load().new()` 独立实例化，不依赖 Autoload
- 边界测试（ce_bian_jie.gd）：满级封顶 + chong_zhi 归零——TASK-008 两条一次性探针转正
- 数据校验测试（ce_shu_ju.gd）：xiao_guo 六键白名单 + 鱼种字段完整性 + 坏卡夹具红测 + 卡片三选一不放回抽样
- 判定集成测试（ce_panding.gd + ce_panding_chang_jing.tscn）：嘴圈吃 / 伤区掉血 / 大鱼进嘴圈无事 / 同体型伤 / 贪食只放大嘴圈——探针场景模式转正
- 坏卡夹具（tests/huai_ka.tres）：**学生亲手在编辑器建**（Resource 三分工第 5 验）——放 tests/ 永不入 data/ 卡池
- 跑批入口（tests/pao_pi.bat）：import → 四域依序跑 → 任一失败总体退出码 1

## 范围外（移交后续任务）

- 为可测性修改产品代码（测试钩子/方法签名调整——升 v2 议）
- GUT/gdUnit 等测试插件（无插件纪律——手写运行器几十行够用）
- CI 平台配置（GitHub Actions 等——本地跑批即可，上线后另议）
- 游戏行为/数值任何改动（只加测试不改游戏）
- 覆盖率统计、性能基准测试
- Android 导出相关（第 10 课）

## 零触碰清单

- scripts/**（全部产品脚本）/ scenes/**（全部产品场景）/ data/**（卡池鱼种阈值表）
- project.godot（不注册 Autoload、不改主场景、不加插件）
- .agents/skills/**（只读复习资料 godot-gdscript-headless-testing）

## 白名单要点

- 新增 11 测试文件（4 测试脚本各 + .uid、集成测试场景、坏卡夹具、跑批 bat）+ 3 报告
- 修改仅文档（词汇表 md/docx、路线图、索引、审计）
- 本任务特色：**产品侧一个文件都不改**
