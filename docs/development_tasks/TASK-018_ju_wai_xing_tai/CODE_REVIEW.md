# TASK-018 代码评审（CODE_REVIEW）

> 状态：自评审完成。按 P1 / P2 / P3 分级；本任务无 P1 / P2 阻塞项。未 commit / 未 push。

## 评审范围

- 新增：`scripts/xing_tai.gd`、`scripts/cun_dang.gd`、`scripts/xing_tai_xuan_ze.gd`、`scenes/XingTaiXuanZe.tscn`、`data/xingtai/*.tres`、`data/donghua/*_1zhen.tres`、`tests/ce_jie_suo.gd`、`tests/huai_xing_tai.tres`。
- 修改：`scripts/zhang_ben.gd`、`scripts/yu.gd`、`scripts/main.gd`、`scripts/jie_suan.gd`、`scripts/yu_npc.gd`、`scenes/JieSuan.tscn`、`project.godot`、`tests/ce_zhang_ben.gd`、`tests/ce_bian_jie.gd`、`tests/ce_shu_ju.gd`、`tests/ce_panding.gd`、`tests/pao_pi.bat`。

## P1 / P2

**无。**

重点核对项均通过：

- 存档损坏路径：`JSON.new().parse()` 失败静默回退；版本不符/非 Dictionary/未知形态/未解锁形态/非法胜场均只回退内存默认值，不写文件。
- Autoload 顺序：`CunDang` 注册在 `ZhangBen` 之后；`_ready()` 动态取节点并判空，`--script` 模式不编译依赖 Autoload。
- 初始能力幂等：`xing_tai_yi_ying_yong` 保证一局只装配一次；`chong_zhi()` 清字段并解锁，`chong_zhi_bao_liu_xing_tai()` 先存引用再复位。
- 选卡按钮绑定：`Callable.bind(xing_tai)` 每卡独立；锁定卡 `disabled=true`，回调仍二次校验 `CunDang.xuan_ze()`。
- 结算按钮流程：`ChongKai` 保留形态，`HuanXingTai` 复位后回选择页；`_xie_jie_suo()` 无条件消费提示，仅胜利显示。
- 测试隔离：`ce_jie_suo` 全部临时路径，结束删除；`ce_panding` 临时改 `CunDang.lu_jing` 并恢复默认，正式存档只读；死亡用例仍最后。
- 开局顺序：形态在 `change_scene_to_file(Main)` 之前写入账本，`Yu._ready()` 顶部应用；`Main._ready()` 首帧补 `camera.zoom`。

## P3 备忘

1. **TASK-014 遗留旧场景（已清理）**：`scenes/QiangHuaDanChuang.tscn` 已删除。它曾引用已删除的 `qiang_hua_dan_chuang.gd`、`qiang_hua_ka.gd` 与 `data/qianghua/*.tres`，导致 `--import` 报 `ERROR`；删除后 `--import` 与冒烟均为 0 `ERROR`。
2. **`xuan_ze()` 的返回值与保存结果未分离**：写档失败只 `push_warning`，`xuan_ze()` 仍返回 true。当前设计是「存档失败不阻断开局」，可接受；若未来要提示玩家存档失败，可再引入 `bao_cun()` 返回值上抛。
3. **胜场上限**：`sheng_li_ci_shu` 不封顶，长期存档会一直增长。当前无副作用（解锁比较是 `>=`），暂不处理。
4. **选择页卡片为纯代码布局**：卡片尺寸/间距硬编码在 `xing_tai_xuan_ze.gd`；将来形态数量变化时需改为换行容器或分页。首版 3 形态固定，可接受。
5. **`JieSuan._xie_neng_li()` 直接追加 Label**：若未来同一结算页实例被复用并重复 `_ready()`，会叠标签；当前每次切场景新建实例，不触发。可留作后续 UI 复用时的检查点。
6. **`YuNpc` 离树保护只覆盖视口读取**：`_process()` 在 `is_inside_tree()` 为假时整帧跳过，`_shi_jiao_fan_wei()` 返回空 `Rect2`。这修复了死亡切场景时的报错；若未来有别的节点在离树后仍被手动调 `_process()`，同样应加 guard。

## 过程教训

- **`--script` 模式不加载 Autoload**：跨局脚本不能用全局名直接引用 `ZhangBen`；要么动态 `get_node_or_null`，要么本地常量对齐。否则测试先红在编译期。
- **`JSON.parse_string` 不是门禁友好 API**：坏输入会直接打 `ERROR`；需要静默回退时用 `JSON.new().parse()`。
- **编辑器缓存也是构建产物**：TASK-014 退役脚本后 `.godot/editor` 仍引用旧文件，会污染 `--import`。清理缓存是合法修复，但根因是旧场景未删；不能每次靠删缓存掩盖。
- **断言数会超出估算**：形态数值是玩法承诺，逐项锁死后总断言从预估 470~490 涨到 540；报告写实际值，不改测试凑计划。

## 好的部分

- 局外/局内职责切得干净：`CunDang` 不碰等级/经验，`ZhangBen.chong_zhi()` 保持纯复位，测试无需大规模改写。
- 存档失败策略统一：加载失败不覆盖、保存失败只警告；玩家存档被视为资产。
- 解锁提示是瞬时内存状态，结算页无条件消费，死亡/失败不会串局。
- 形态接入点选在 `Yu._ready()` 顶部，绕开父节点 `_ready()` 顺序问题；`Main` 首帧镜头补一行，避免 Lv.1 电鳐镜头跳变。
- 测试隔离到位：临时存档路径、临时 `lu_jing`、裸实例、场景实例 `queue_free`，没有污染正式 `user://` 存档。
