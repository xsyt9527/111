# TASK-009 实现报告（IMPLEMENTATION_REPORT）

## 交付概览

四步全部按规格实现，**产品代码零修改**。`tests/` 目录首建：SceneTree 运行器 ×3（账本纯逻辑 / 边界 / 数据校验）+ 场景模式集成测试 ×1（判定）+ 坏卡夹具 + 跑批门禁 `pao_pi.bat`。第 8 课安全网「一次性探针 + 真人 F5」升级为「一条命令全量回归」——四域 57 条断言（9+11+27+10）+ 双红测 + 门禁三重把关。三笔学习账清账：Resource 三分工第 5 验（学生亲手坏卡）、push_warning 再验（红测的活教材）、探针手艺转正（封顶/重开探针改造成常驻测试）。

## 分步明细

### step-01 测试基建 + 账本纯逻辑（tests/ce_zhang_ben.gd）

| 内容 | 说明 |
|---|---|
| 运行器三件套 | `extends SceneTree` + `_initialize()` 入口 / `assert_eq(实际, 期望, 标签)` 失败计数助手 / 收卷 `quit(1 if failed > 0 else 0)` |
| 测试独立性 | `--script` 模式不加载 Autoload → `load("res://scripts/zhang_ben.gd").new()` 每用例独立实例，起点永远干净 |
| 四用例 | 记账累加（2+3=5 不升级）/ 跨级升级扣减（10→Lv.2 余 2；再 20→Lv.3 余 2）/ 倍率入账（照抄 yu_npc.gd 真实姿势 `int(4×1.5)`=6）/ 阈值读表（Lv.1→8、Lv.3→35） |

资源卫生攻关：退出报 `4 resources still in use` → `--verbose` 定位为不入树实例攥着脚本引用 → 四用例各补 `free()` → 零 ERROR 零 Leaked（**谁创建谁负责 free**，谁常驻谁负责复位的资源版）。

### step-02 边界测试（tests/ce_bian_jie.gd）

| 用例 | 断言 |
|---|---|
| 满级封顶 | 分次喂 60（`jia_jing_yan()` 内是 if 不是 while，单次最多升一级——第 8 课探针隐性知识显式化）到 Lv.7；一口闷 500 → 等级钉 7、经验钉 110 满格、`sheng_ji` 恰 6 次不再发、`jing_yan_bian_hua` 仍刷条恰 1 次（前后差值断言） |
| chong_zhi 归零 | 弄脏四项（经验/等级/倍率/入账一张卡）+ 脏状态预检 Lv.2 → 复位 → 全归零；浮点倍率用 ×10 取整断言 |

### step-03 数据全键校验 + 坏卡红测 + 抽样（tests/ce_shu_ju.gd + tests/huai_ka.tres）

| 用例 | 断言 |
|---|---|
| 卡池六张 | `DirAccess.get_files_at` 遍历 data/qianghua 逐张过校验器；数量恰 6（夹具混进 data/ 即红） |
| 校验器双规矩 | ①`xiao_guo` ∈ 六键白名单（与 yu.gd match 分支一一对应）②`shu_zhi` > 0 |
| 红测 ×2 | 学生亲手坏卡（tests/huai_ka.tres：键合法、数值 -0.1）→ 「效果数值应为正数」；代码内拼错键卡（yidong_sudu2）→ 「未知效果键」 |
| 鱼种表 | 6 行逐张校验贴图/等级/分值/两个随机范围合法性 |
| 抽样性质 | 弹窗卡池 6 张互不重复全过校验（`instantiate()` 不入树读导出 ka_zu）+ 复刻复制→洗牌→取前 3 跑 200 轮：每轮恰 3 张无重复、每张卡都露过面 |

### step-04 判定集成 + 跑批门禁（tests/ce_panding.gd + ce_panding_chang_jing.tscn + pao_pi.bat）

| 用例/机制 | 说明 |
|---|---|
| 场景模式 | `--script` 不加载 Autoload 而 bei_chi 记账/玩家 _ready 连信号要 ZhangBen → 测试场景作主场景真跑物理帧 |
| 五条判定 | 小鱼进嘴圈被吃 / 大鱼进嘴圈无事 + 伤区掉血 + 无敌期不重复伤 / 同体型掉血不被吃（吃严格 >、伤 ≥）/ 贪食走真实信号链（ZhangBen.xuan_ka→ka_yi_xuan→match）只放大嘴圈 ×1.15、伤区纹丝不动 |
| 门禁三重把关 | ①任一步退出码非 0 ②输出含 ERROR（SCRIPT ERROR 假绿型）③缺 Results 收卷行（场景空跑型）→ 全绿退出码 0 可交付 / 有红退出码 1 禁止交付 |
| 门禁红测 | 故意弄坏断言（喂 2+4 期望 5）→ 跑批退出码 1 + FAIL 现形 + 「禁止交付」→ 还原复绿 |

## 自动化检查（每步全跑）

- `--headless --import` 退出码 0 + 输出筛查零命中 ×4 步
- 四域测试：`Results: 9 / 11 / 27 / 10 passed, 0 failed`，退出码全 0，零 ERROR/零 FAIL/零 Leaked
- `pao_pi.bat` 全绿路径退出码 0 + 红路径退出码 1（双向自证）
- `check_task_scope.py check`：见范围遵守

## 假绿事故记录（本课最大收获，详见 CODE_REVIEW）

三种假绿全部亲手踩到：①`bool == int` 断言内部 SCRIPT ERROR 不计入 passed/failed（step-03 + step-04 两次）②解析错误致场景空跑、退出码仍 0（step-04 `is_equal_approx` 误用为 float 方法）③退出码 0 掩盖非致命错误（第 6 课历史账）。结论固化为门禁三重把关。

## 范围遵守

- 新增恰为白名单 11 文件：4 个测试 .gd + 4 个 .uid + ce_panding_chang_jing.tscn + huai_ka.tres + pao_pi.bat
- scripts/ scenes/ data/ project.godot **零修改**（学生在编辑器中的实验改动——坏卡入真卡池、阈值表清空、场景重存——全部处置：坏卡手艺挪入 tests/huai_ka.tres 保留，产品文件备份至仓库外后还原 HEAD）
- 夹具不入 data/ 卡池；无插件、无 CI 平台
- 学生实验还原：坏卡其内容即红测夹具（手艺保留），其余实验为编辑器重存噪音与临时改动（已还原）；备份冷却后清理
