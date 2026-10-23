# TASK-005 交接说明（INTEGRATION_HANDOFF）

## 交付物

| 类型 | 路径 | 说明 |
|---|---|---|
| 新建 | `scripts/zhang_ben.gd` | Autoload 游戏账本（经验/等级/阈值/两信号） |
| 新建 | `scripts/jing_yan_ui.gd` | 经验条 UI 脚本（听账本信号刷新） |
| 修改 | `project.godot` | [autoload] 注册 ZhangBen（首个 Autoload） |
| 修改 | `scripts/yu_npc.gd` | bei_chi() 记账一行（判空兜底鱼） |
| 修改 | `scripts/yu.gd` | 听 sheng_ji 信号长大（tixing += 0.2） |
| 修改 | `scenes/Main.tscn` | JingYanTiao(CanvasLayer) UI 子树 |

## 提供给后续任务的接口

| 接口 | 形态 | 使用者 |
|---|---|---|
| `ZhangBen` | Autoload 单例 | 全项目任意脚本按名访问 |
| `ZhangBen.jia_jing_yan(fen)` | 唯一记账入口 | TASK-008 血量/死亡可复用同款入口模式 |
| `ZhangBen.sheng_ji(xin_deng_ji)` | 信号 | TASK-006 升级三选一弹窗的触发时机 |
| `ZhangBen.MEI_JI_TIXING` | 常量 | 第 7 课强化卡若涉及体型加成在此扩展 |

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
