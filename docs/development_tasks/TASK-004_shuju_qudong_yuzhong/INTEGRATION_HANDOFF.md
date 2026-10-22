# TASK-004 交接说明（INTEGRATION_HANDOFF）

## 交付物

| 类型 | 路径 | 说明 |
|---|---|---|
| 新建 | `scripts/yu_zhong.gd` | 鱼种数据模具（Resource 类，五字段） |
| 新建 | `data/yuzhong/*.tres` × 6 | 鱼种数据文件（蓝/红/绿/橙/棕/粉） |
| 修改 | `scripts/yu_npc.gd` | 外观/体型来源改为 yu_zhong 注入（游动/回收/bei_chi 不动） |
| 修改 | `scripts/yu_qun.gd` | 生成时抽鱼种并注入（间隔/上限/边缘逻辑不动） |
| 修改 | `scenes/YuNpc.tscn` | 清掉贴图数组与 ext_resource |
| 修改 | `scenes/Main.tscn` | YuQun 拖入 6 个鱼种表 |

## 提供给后续任务的接口

| 接口 | 形态 | 使用者 |
|---|---|---|
| `YuZhong` | Resource 类（tie_tu/dengji/tixing_fanwei/sudu_fanwei/fenzhi） | 所有数据消费方 |
| `YuNpc.yu_zhong` | 属性（生成器注入） | TASK-005 记账时查该鱼 fenzhi/dengji |
| `YuZhong.fenzhi` | int 数据字段（本课只存不读） | TASK-005 经验系统 |
| 注册表模式 | 模具 + .tres + Array[YuZhong] | 第 6 课强化卡可直接复用 |

（以下内容实现后补全）

## 场景树（交付后）

（待实现）

## 已知限制 / 后续任务注意

（待实现）

## 集成检查清单

- [ ] 任务包通过 validate_task.py（v1）
- [ ] headless 导入退出码 0
- [ ] headless --fixed-fps 60 --quit-after 360 退出码 0
- [ ] check_task_scope.py 无违例
- [ ] 学生 verification-handoff 完成
- [ ] LEARNING_ROADMAP / TASK_INDEX / 引擎词总表（md + docx）已更新
