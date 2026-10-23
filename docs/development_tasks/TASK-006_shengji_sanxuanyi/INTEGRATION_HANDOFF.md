# TASK-006 交接说明（INTEGRATION_HANDOFF）

## 交付物

| 类型 | 路径 | 说明 |
|---|---|---|
| 新建 | `scripts/qiang_hua_ka.gd` | 强化卡数据模具（ming_zi/miao_shu/xiao_guo/shu_zhi） |
| 新建 | `scripts/sheng_ji_biao.gd` | 升级阈值表模具（yuzhi_zu） |
| 新建 | `data/qianghua/*.tres` × 6 | 卡池：迅捷/催肥/磁吸/贪食/活力/睿智 |
| 新建 | `data/shengji/sheng_ji_biao.tres` | 阈值表 [8,20,35,55,80,110]（常量数据化） |
| 新建 | `scenes/QiangHuaDanChuang.tscn` | 三选一弹窗场景（CanvasLayer, process_mode=3, 默认隐藏） |
| 新建 | `scripts/qiang_hua_dan_chuang.gd` | 弹窗逻辑：升级冻结→抽样→显示→选择→恢复 |
| 修改 | `scripts/zhang_ben.gd` | 阈值读表（常量退役）+ yi_xuan_ka 账 + xuan_ka() + ka_yi_xuan 信号 |
| 修改 | `scenes/Main.tscn` | 实例化弹窗（visible=false 常驻） |

## 提供给后续任务的接口

| 接口 | 形态 | 使用者 |
|---|---|---|
| `ZhangBen.ka_yi_xuan(ka: QiangHuaKa)` | 信号 | **第 7 课强化生效系统连接此信号**：回调里 switch(ka.xiao_guo) 应用 ka.shu_zhi |
| `ZhangBen.yi_xuan_ka` | Array[QiangHuaKa] | 第 8 课结算页展示本局 build；第 9 课测试断言 |
| `QiangHuaKa.xiao_guo / shu_zhi` | 数据字段（本课只存不用） | 第 7 课消费 |
| `ShengJiBiao.yuzhi_zu` | 阈值表 .tres | 策划调升级曲线零代码 |
| 注册表三连模式（第二次实战） | 模具+.tres+数组 | 后续所有"表驱动"功能照抄 |

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
