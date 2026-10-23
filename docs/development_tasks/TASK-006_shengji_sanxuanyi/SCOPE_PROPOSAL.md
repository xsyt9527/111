# TASK-006 范围提案（SCOPE_PROPOSAL）

## 范围内

- 强化卡数据层：QiangHuaKa 模具 + 6 张 .tres + 弹窗内 Array[QiangHuaKa] 注册表（复用第 4 课模式）
- 升级阈值数据化：ShengJiBiao 模具 + .tres + zhang_ben.gd 常量退役读表（等值切换，兑现 TASK-005 P3 备忘）
- 三选一弹窗：QiangHuaDanChuang.tscn（CanvasLayer + 遮罩 + 标题 + 三卡按钮，process_mode=WHEN_PAUSED）+ Main 实例化
- 升级触发链：连接 sheng_ji → get_tree().paused 冻结 → duplicate/shuffle/slice 不放回抽 3 张 → 填按钮显示
- 选择入账：ZhangBen.xuan_ka(ka)（yi_xuan_ka 追加 + ka_yi_xuan 信号预埋）→ 解冻隐藏

## 范围外（移交后续任务）

- 强化效果生效（第 7 课：xiao_guo/shu_zhi 消费、磁吸双 Area2D、催肥改 MEI_JI_TIXING）
- 卡牌翻转/弹窗动效（第 7 课 Tween）
- 血量/死亡/结算（TASK-008）
- 卡池扩充/稀有度/卡池解锁（后续迭代，注册表模式保证加卡零代码）

## 零触碰清单

- yu.gd / jing_yan_ui.gd / yu_npc.gd / yu_qun.gd / yu_zhong.gd / main.gd / Yu.tscn / YuNpc.tscn / project.godot
- zhang_ben.gd 内 jia_jing_yan / jing_yan_bian_hua / sheng_ji / MEI_JI_TIXING（只加不改）

## 白名单要点

- 新增 3 脚本（各 + .uid）、1 场景、7 张 .tres、3 报告
- 修改 zhang_ben.gd、Main.tscn + 文档（词汇表 md/docx、路线图、索引、审计）
