# TASK-006 交接说明（INTEGRATION_HANDOFF）

## 交付物

| 类型 | 路径 | 说明 |
|---|---|---|
| 新建 | `scripts/qiang_hua_ka.gd` | 强化卡模具（ming_zi/miao_shu/xiao_guo/shu_zhi） |
| 新建 | `scripts/sheng_ji_biao.gd` | 阈值表模具（yuzhi_zu） |
| 新建 | `data/qianghua/*.tres` × 6 | 卡池：迅捷/催肥/磁吸/贪食/活力/睿智 |
| 新建 | `data/shengji/sheng_ji_biao.tres` | 阈值 [8,20,35,55,80,110]（常量数据化，等值） |
| 新建 | `scenes/QiangHuaDanChuang.tscn` | 三选一弹窗（CanvasLayer, process_mode=3, 默认隐藏） |
| 新建 | `scripts/qiang_hua_dan_chuang.gd` | 弹窗逻辑：升级冻结→抽样→显示→选择→恢复 |
| 修改 | `scripts/zhang_ben.gd` | 阈值读表（常量退役）+ yi_xuan_ka + xuan_ka() + ka_yi_xuan 信号 |
| 修改 | `scenes/Main.tscn` | 实例化弹窗（visible=false 常驻复用） |

## 提供给后续任务的接口

| 接口 | 形态 | 使用者 |
|---|---|---|
| `ZhangBen.ka_yi_xuan(ka: QiangHuaKa)` | 信号 | **第 7 课强化生效系统连接此信号**：回调里按 ka.xiao_guo 应用 ka.shu_zhi |
| `ZhangBen.yi_xuan_ka` | Array[QiangHuaKa] | 第 8 课结算页展示本局 build；第 9 课测试断言 |
| `QiangHuaKa.xiao_guo / shu_zhi` | 数据字段 | 第 7 课消费（效果键见下方对照表） |
| `ShengJiBiao.yuzhi_zu` | 阈值表 .tres | 策划调升级曲线零代码 |
| 注册表三连模式 | 模具+.tres+数组 | 已两次实战（鱼种/强化卡），后续表驱动功能照抄 |

**效果键对照表（第 7 课 switch 用）**：`yidong_sudu`(0.15 游速)、`mei_ji_tixing`(0.05 每级体型增幅)、`ci_xi_fanwei`(0.4 磁吸范围)、`tun_shi_fanwei`(0.15 吞噬判定圈)、`wudi_shi_chang`(0.5 无敌时长)、`jing_yan_jia_cheng`(0.25 经验加成)

## 场景树（交付后）

```
root
├─ ZhangBen (zhang_ben.gd, Autoload)  ← 阈值读表 + yi_xuan_ka + ka_yi_xuan（TASK-006 改）
└─ Main (Node2D)
   ├─ Haodi / Yu / JingYanTiao        ← 零改动
   ├─ QiangHuaDanChuang (实例, visible=false, process_mode=3)  ← TASK-006
   │  ├─ BanDi (ColorRect 全屏遮罩)
   │  ├─ BiaoTi (Label "选一张强化！")
   │  └─ KaPianZu (HBoxContainer)
   │     ├─ Ka1 → KaZhong1 → MingCheng(Button) + MiaoShu(Label)
   │     ├─ Ka2 → KaZhong2 → MingCheng + MiaoShu
   │     └─ Ka3 → KaZhong3 → MingCheng + MiaoShu
   └─ YuQun                             ← 零改动（暂停时 Timer 自动停）
```

## 已知限制 / 后续任务注意

1. **xiao_guo 字符串无编译期校验**——第 7 课效果映射加 push_warning 兜底
2. **满级后 sheng_ji 仍发、弹窗照常弹**——与 TASK-005 P3 满级项合并决策
3. **弹窗视觉占位级**——第 7 课 Tween 统一调优
4. **磁吸卡 = 学生第 3 课提案**——第 7 课实现双 Area2D（ChiQu 大圈吸附 + ShangQu 小圈判定），届时复述"分行为须分 Area2D"

## 集成检查清单

- [x] 任务包通过 validate_task.py（v1）
- [x] headless 导入 0 错误（输出筛查）
- [x] headless --fixed-fps 60 --quit-after 360 零错误（输出筛查，检查方式已升级）
- [x] 全链路探针 TONGGUO（两轮闭环，探针已删）
- [x] check_task_scope.py 无违例（20 allowed, 0 violation）
- [x] 学生 godot-inspection 完成（发现 Node not found + 中间态识别准确 + 实验当场还原）
- [x] 学生 verification-handoff 完成（四条全过）
- [x] LEARNING_ROADMAP / TASK_INDEX / 引擎词总表（md + docx）已更新
