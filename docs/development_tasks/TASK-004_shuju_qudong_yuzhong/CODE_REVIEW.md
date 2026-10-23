# TASK-004 代码评审（缺陷优先）

**结论：通过。** 无 P0/P1/P2 缺陷；4 条 P3 备忘（不阻塞，移交后续任务）。

## 评审范围

- scripts/yu_zhong.gd（新）、data/yuzhong/*.tres × 6（新）
- scripts/yu_npc.gd（_ready 数据来源切换）、scripts/yu_qun.gd（注册表抽取）
- scenes/YuNpc.tscn（清数组）、scenes/Main.tscn（注册表拖入）

## 正确性核对

- ✅ 注入顺序：`yu_zhong` 与 `sudu` 均在 `add_child()` 前赋值，`_ready` 消费——与 TASK-002 的注入约定一致
- ✅ 兜底分支：`yu_zhong == null` / `tie_tu == null` / `yu_zhong_zu` 为空三条路径都不崩（探针与运行验证覆盖）
- ✅ 判定系统零接触：`Yu.tixing` 比较逻辑、`bei_chi()`、`_shoushang()` 未动；NPC `tixing` 仍为运行时随机值，仅范围来源变更
- ✅ 数据一致性：6 个 .tres 数值与规格表逐项一致；`.tres → script uid → .uid 文件` 三层引用链一致
- ✅ 无泄漏：无新信号连接、无新计时器；被吃 NPC 随 `queue_free` 释放其 `yu_zhong` 引用

## P3 备忘（移交后续）

1. **fenzhi/dengji 暂无消费者**（设计使然）——TASK-005 经验系统在 `bei_chi()` 入口读取 `yu_zhong.fenzhi` 记账；届时可按 dengji 做难度曲线（限制高等级鱼早期出场）
2. **检查器清空注册表会退化为"白板鱼"**（无贴图、sudu=100、体型 0.6~1.6）——兜底可接受，不做警告 UI；第 9 课测试课可加断言
3. **.tscn 手工维护注意**：类型化数组的序列化格式由编辑器决定（本任务中 `Array[YuZhong]` 手写被编辑器重写为 `Array[ExtResource(...)]`）——以后手工编辑场景文件后应开编辑器保存一次让其规范化
4. **`YuZhong.tixing_fanwei` 默认值 (0.6,1.6) 与兜底字面量重复**——若后续调整默认体型，两处要同步（可接受的小重复，换取兜底独立性）

## 范围遵守

- 白名单外文件零改动；`yu.gd`/`Yu.tscn`/`main.gd`/`project.godot` 零接触
- fenzhi 无任何代码读取（属数据存储，不构成 TASK-005 的越界实现）
