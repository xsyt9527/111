# TASK-005 代码评审（缺陷优先）

**结论：通过。** 无 P0/P1/P2 缺陷；4 条 P3 备忘（不阻塞，移交后续任务）。

## 评审范围

- scripts/zhang_ben.gd（新，Autoload）、scripts/jing_yan_ui.gd（新，UI）
- project.godot（[autoload] 段）、scripts/yu_npc.gd（bei_chi 两行）、scripts/yu.gd（连接 + 长大）、scenes/Main.tscn（UI 子树）

## 正确性核对

- ✅ **唯一所有者纪律**：`jing_yan`/`deng_ji` 的写入仅出现在 zhang_ben.gd 内；外部只有 `jia_jing_yan()` 入口调用与信号监听——集成合同"禁止账本外写入"满足
- ✅ **升级扣除逻辑**：`jing_yan -= yuzhi` 后再 emit，多鱼同帧连吃（一帧内多次 jia_jing_yan）每次独立判级，跨级连升正确（每次升级 emit 一次，玩家多段长大叠加正确）
- ✅ **满级封顶**：deng_ji > 6 时返回最后一档，经验条停满格不溢出不崩溃
- ✅ **判空兜底**：bei_chi 对 null yu_zhong 跳过记账只释放——白板鱼不产生经验，路径与 TASK-004 兜底设计一致
- ✅ **信号生命周期**：玩家/UI 在 `_ready` 连接账本信号；Autoload 先于场景就绪（远程树平级实测确认），无"账本未就绪"窗口；玩家不销毁、UI 随 Main 生命周期，无泄漏连接
- ✅ **project.godot 最小改动**：仅新增 [autoload] 两行，其余段落零接触（git diff 复核）
- ✅ **判定系统零接触**：`tixing > yu_npc.tixing` 比较逻辑未动；玩家 tixing 增大即扩大可猎范围，行为符合设计
- ✅ **UI 无状态**：jing_yan_ui.gd 除 @onready 引用外零自有变量，纯监听刷新

## P3 备忘（移交后续）

1. **满级后继续吃鱼经验仍累计但条不动**（jing_yan 涨、max 封顶）——第 6 课做满级处理时一并决策（停条/封顶/无尽模式）
2. **SHENG_JI_YUZHI 常量数组待数据化**——设计决策 1 明确与第 6 课强化卡一起做 .tres；届时数组元素结构可能扩为字典（阈值+强化池引用）
3. **账本重置入口缺失**（`chong_zhi()`）——第 8 课死亡重开时需要：jing_yan=0、deng_ji=1；届时玩家 tixing/UI 也要监听重置信号同步归位
4. **一帧连吃多条的 jing_yan_bian_hua 多次 emit**——UI 每次刷新一次，量小无性能问题；若第 7 课做连击反馈可考虑合并 emit

## 范围遵守

- 白名单外文件零改动；yu_qun.gd/yu_zhong.gd/main.gd/Yu.tscn/YuNpc.tscn 零接触（禁止清单全绿）
- project.godot 仅 [autoload] 一处；经验值写入未出现在账本之外
