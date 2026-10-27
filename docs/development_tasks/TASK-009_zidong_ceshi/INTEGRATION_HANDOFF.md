# TASK-009 交接说明（INTEGRATION_HANDOFF）

> 状态：ready（交付完成）

## 交付物

`tests/` 目录首建，11 个新文件（产品代码零修改）：

| 文件 | 作用 |
|---|---|
| `tests/ce_zhang_ben.gd`（+.uid） | 账本纯逻辑 9 断言：累加/升级扣减/倍率/读表 |
| `tests/ce_bian_jie.gd`（+.uid） | 边界 11 断言：满级封顶（探针转正）+ chong_zhi 归零 |
| `tests/ce_shu_ju.gd`（+.uid） | 数据 27 断言：六键白名单 + 双红测 + 鱼种表 + 抽样性质 |
| `tests/ce_panding.gd`（+.uid）+ `tests/ce_panding_chang_jing.tscn` | 判定集成 10 断言（场景模式，真物理帧） |
| `tests/huai_ka.tres` | 坏卡夹具（学生亲手建）：键合法数值为负，红测专用 |
| `tests/pao_pi.bat` | 跑批门禁：import + 四域依序 + 三重把关 |

## 提供给后续任务的接口

- **回归门禁**：`tests/pao_pi.bat`——第 10 课导出前及以后每次交付前必跑；退出码 0 才可交付
- **测试骨架模板**：新功能测试照抄四文件结构（extends SceneTree + `_initialize` + assert_eq 记账员 + `quit(退出码)` + 不入树实例 free()）
- **全键校验自动守护**：加第 7 张卡/新鱼种无需改测试——DirAccess 遍历自动覆盖；拼错键当场红
- **坏卡夹具模式**：红测夹具放 tests/、永不入 data/；校验规则随设计变（如 v2 允许诅咒卡 → shu_zhi 改为值域）
- **红绿体验规范**：新测试写完全绿后，必须弄红一次验证门禁真的会拦

## 场景树（交付后）

产品场景树**零变化**（Main/Yu/YuNpc/QiangHuaDanChuang/JieSuan 均未动）。`tests/` 独立目录：四测试脚本 + 一集成测试场景（根 Node2D "CePandingChangJing"，运行时自建玩家与测试鱼）+ 夹具 + bat。

## 已知限制 / 后续任务注意

- **覆盖边界**：纯逻辑全覆盖；判定行为集成覆盖；UI/动画（tween/摆尾/弹窗真实接线）无自动化——真人 F5 仍必要
- **抽样用例为算法复刻**：未直接调用 `_on_sheng_ji` 真实接线（候选改进见 CODE_REVIEW P3-2）
- **门禁依赖引擎绝对路径**：`pao_pi.bat` 内 `D:\001\Godot_v4.7.2-stable_win64.exe`，换机器需改两行
- **测试执行时间**：四域约 20 秒（无头），可接受；若将来变慢再议并行
- **v2 议题备查**：允许负面效果卡（诅咒卡）需改校验规则 shu_zhi 为正 → 值域（-1, 1) 且 ≠ 0；乘法公式 1.0+x 已天然兼容
- **遗留观察项**：push_warning vs error 复述未复考（第 10 课开场清账）

## 集成检查清单

- [x] 任务包通过 validate_task.py（v1 生成/审批）
- [x] headless 导入 0 错误（输出筛查）
- [x] 四域测试各自退出码 0 + Results 全 passed（9/11/27/10）
- [x] pao_pi.bat 全绿退出码 0 + 红路径退出码 1（双向自证）
- [x] 学生 godot-inspection 完成（含亲手建夹具——三分工第 5 验）
- [x] 学生 verification-handoff 完成（跑批全绿 + 红绿体验 + F5 全量回归）
- [x] LEARNING_ROADMAP / TASK_INDEX / 引擎词总表（md + docx）已更新
