# TASK-018: 局外形态解锁（三形态 + 胜利解锁 + 启动选择页）

> 引擎：Godot 4.7
> 开发策略：plan_driven
> 参与模式：guided_co_development
> 执行模式：teaching
> 任务规格版本：v1
> 审批状态：awaiting
> 交付状态：proposed
> Git 基线：a194b5b60d484de5cf7149c2c4ab5b56c12a4763
> 依据：策划案 8.3/9；`docs/CHONG_GOU_LU_XIAN.md`

## 一、任务目标

给每局一个长期理由：胜利推进局外解锁。试玩版三个形态——灯笼鱼（均衡）、电鳐（厚实 + 放电）、旗鱼（高速 + 突进）——不同初始等级、速度、嘴巴、转向与初始主动能力，直接改变下一局开局路线。启动先进入形态选择页；首胜解锁电鳐，第二胜解锁旗鱼；结算页可「再来一次」（保留形态）或「换形态」（回选择页）。

### 完成后可观察结果

- 启动游戏进入形态选择页：0 胜时灯笼鱼可选，电鳐/旗鱼显示锁定与所需胜场。
- 三个形态开局等级、体型、速度、嘴巴、转向、初始主动能力各不相同，外观正确。
- 击败机器船胜利后，结算页显示「解锁新形态：电鳐」；重启游戏进度仍在。
- 结算「再来一次」保留当前形态；「换形态」回选择页。
- `tests/pao_pi.bat` 八步全绿，输出无 `ERROR`。

## 二、五步实现

### step-01 形态数据层

`scripts/xing_tai.gd`：`Resource` + `class_name XingTai`，字段 `bian_hao` / `ming_zi` / `miao_shu` / `dong_hua` / `kai_ju_deng_ji` / `yi_dong_su_du` / `zui_ba` / `zhuan_xiang_ji_su` / `kai_ju_neng_li` / `jie_suo_sheng_li_ci_shu`。三个 `.tres` 填表；电鳐/旗鱼各做单帧 `SpriteFrames`（`"you"`）。`ce_shu_ju` 增加校验器、唯一 id、阈值、动画、初始能力、数值断言，坏夹具红测，并断言主场景与 `CunDang` Autoload。

### step-02 局外存档与解锁推导

`scripts/cun_dang.gd`（Autoload `CunDang`）：显式 `preload` 注册表、JSON 读写、版本/损坏/未知 id/未解锁回退、累计胜利解锁、当前形态选择、调试方法、`_init` 加载形态、`_ready` 读档并连 `ju_jie_shu`。新增 `tests/ce_jie_suo.gd`；`pao_pi.bat` 扩为八步。

### step-03 账本与玩家形态接入

`ZhangBen` 增加形态字段、`kai_ju_xing_tai()`（不触发升级弹窗）、`chong_zhi_bao_liu_xing_tai()`，`chong_zhi()` 清形态；`Yu.ying_yong_xing_tai()` 应用速度/嘴巴/转向/外观，`_ready()` 在 `scale` 前应用；`Main._ready()` 首帧补 `camera.zoom`。同步 `ce_zhang_ben` / `ce_bian_jie`。

### step-04 选择页、结算页与入口

`scenes/XingTaiXuanZe.tscn` + `scripts/xing_tai_xuan_ze.gd`：动态卡片、当前/已解锁/锁定三种状态、编辑器调试按钮。`JieSuan` 新增 `HuanXingTai` 与 `JieSuoTiShi`，无条件消费解锁提示，只在胜利时显示。`project.godot` 注册 `CunDang` 与主场景。`ce_panding` 增加形态应用、选择页、结算页、胜利解锁用例。

### step-05 全量验证、文档与清理

八步门禁全绿；Main 900 帧、选择页 120 帧、结算页 60 帧无头冒烟；更新 `TASK_INDEX.md`、`LEARNING_ROADMAP.md`、`CHONG_GOU_LU_XIAN.md`、`引擎词总表.md` 并重生成 docx；F5 手测；清理临时文件；回填报告。

## 三、零触碰红线

`.agents/skills/**` 只读；`tests/` 既有文件不得删除；不改 `yu_npc.gd` / `yu_qun.gd` / `zhan_dou.gd` / 鱼种表 / 能力表；不做第 4 形态、货币、难度、音效、安卓导出。

## 四、学习契约

| # | 目标 | 验证时机 |
|---|---|---|
| 1 | 复述局外存档与局内账本的分工 | orientation / step-02 |
| 2 | 解释形态为什么必须在切 Main 之前应用 | step-03 |
| 3 | 说出胜利解锁的完整时序 | step-04 / verification |
| 4 | 解释 JSON 损坏时为何只回退不覆盖 | step-02 |
| 5 | 指出选择页、结算页、Main 三个入口各自负责什么 | step-04 |
| 6 | 亲手跑一次门禁红绿（形态负速度）并解释 ERROR 筛查 | step-05 |
