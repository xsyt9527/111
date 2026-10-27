# TASK-009 验证报告（VERIFICATION_REPORT）

## 自动化验证

| 检查 | 结果 |
|---|---|
| 引擎版本 | 4.7.2.stable.official.ed1daf0bf（本机 `D:\001\`，AGENTS.md 认证路径） |
| headless --import（每步） | 退出码 0 + 输出筛查零命中 ×4 步 |
| 账本纯逻辑 ce_zhang_ben | `Results: 9 passed, 0 failed`，退出码 0 |
| 边界 ce_bian_jie | `Results: 11 passed, 0 failed`，退出码 0 |
| 数据校验 ce_shu_ju | `Results: 27 passed, 0 failed`，退出码 0，双红测命中 |
| 判定集成 ce_panding（场景模式） | `Results: 10 passed, 0 failed`，退出码 0 |
| pao_pi.bat 全绿路径 | 五步依序 + 「全绿：可以交付」+ 退出码 0 |
| pao_pi.bat 红路径（门禁自测） | 弄坏断言 → 退出码 1 + FAIL 现形 + 「有红：禁止交付」→ 还原复绿 |
| validate_task.py | VALID（审批登记 / in_progress / 待回填 INVALID→回填 VALID 各阶段） |
| check_task_scope.py check | 0 violation（11 白名单文件 + 文档；产品文件零变化） |

## 假绿验证矩阵（本课核心认知物证）

| 假绿形态 | 现场 | 退出码 | 谁抓住 |
|---|---|---|---|
| 断言内部类型错误（`bool == int`） | step-03 `assert_eq(BAI_MING_DAN.has(...), 1)`；step-04 `is_instance_valid(...)` 直塞 | 0（错误） | 输出筛查 grep SCRIPT ERROR |
| 解析错误场景空跑 | step-04 `is_equal_approx` 误用为 float 方法 → 脚本加载失败 → 场景空转 | 0（错误） | 输出筛查 ERROR + 缺 Results 行 |
| 退出码 0 掩盖非致命错误 | 第 6 课历史账（Node not found 不点卡盲区） | 0（错误） | 真人 F5 + 输出筛查 |

→ 结论固化为 `pao_pi.bat` 三重把门：退出码 + ERROR 筛查 + Results 收卷行。

## 学生手动验证（各检查点，2026-10-26）

| # | 项目 | 结果 |
|---|---|---|
| 1 | step-01 通读 ce_zhang_ben.gd + 亲手跑命令见 9 passed + F5 零影响 | ✅ |
| 2 | step-02 亲手跑 11 passed + 测试独立性两轮补测后复述通过 | ✅ |
| 3 | step-03 亲手跑 27 passed + 双红测命中；坏卡亲手建（三分工第 5 验）；红测价值复述通过 | ✅ |
| 4 | step-04 亲手跑 pao_pi.bat 全绿 + 红绿体验（改 3→4 红、复原绿）+ F5 完整一局全量回归 | ✅ |
| 5 | 退出码门禁语言复述通过（"过了也能知道，不过也能知道"） | ✅ |

## 学生实验处置记录

- 学生自发在编辑器建 `data/qianghua/huai_ka.tres`（键 yidong_sudu 合法、shu_zhi=-0.1）并加入真卡池实验 + 重存四个产品文件 + 清空阈值表 yuzhi_zu 行
- 处置：坏卡挪入 `tests/huai_ka.tres`（手艺保留，成为红测夹具）；四处产品文件备份至仓库外（`/tmp/task009_beifen/`）后还原 HEAD；阈值表回 `[8, 20, 35, 55, 80, 110]`（当时未崩：脚本默认值恰与表相同）
- 收尾复核：`git status` 确认产品目录零变化，tests/ 恰 11 文件 + 三报告 + 文档

## 已知边缘（记录不阻塞）

- 抽样用例为**算法复刻**（复制→洗牌→取前 3）而非直接调用弹窗真实接线——`_on_sheng_ji` 依赖 Autoload + 节点接线，`--script` 模式够不着；真实接线由 F5 真人兜底（step-04 场景模式可后续扩展）
- UI/动画（tween 长大/吞吃脉冲/摆尾）无自动化断言——显示层靠人眼，验证边界已写入交接说明
- push_warning vs error 复述首答半对（"报红无法运行"），补课后未单独复考——记遗留观察项（第 10 课开场可再验）
