# TASK-007 范围提案（SCOPE_PROPOSAL）

## 范围内

- buff 生效系统：yu.gd 监听 `ka_yi_xuan` → `match(ka.xiao_guo)` 六分支（数值全读 ka.shu_zhi，push_warning 兜底未知键）
- 睿智倍率入账本：zhang_ben.gd `jing_yan_jia_cheng` + `she_jing_yan_jia_cheng()`，`yu_npc.bei_chi` 乘算
- 磁吸双 Area2D：Yu.tscn 的 PandingQu 改名 ShangQu（判定职责不变）+ 新增 ChiQu 吸附圈（layer=1 mask=2）；yu_npc.gd `bei_xi` 被吸自追
- Tween 动画：升级平滑长大（0.3s，替换瞬间跳变）+ 吞吃脉冲（0.08s 弹大回弹）
- 程序化摆尾：sin 周期驱动 Sprite2D.rotation，幅度与体型反比
- 参数调优 + 全量回归（六课 + 六卡 + 三动画）

## 范围外（移交后续任务）

- 血量/死亡/结算/一键重开（TASK-008）
- 满级处理决策（与 TASK-005/006 P3 合并，TASK-008 决策）
- 账本重置（TASK-008 配套）
- 新增强化卡/改卡数值/稀有度（注册表模式保证加卡零代码，本课不动 data/）
- 弹窗卡片翻转动效（占位视觉够用）

## 零触碰清单

- yu_qun.gd / yu_zhong.gd / main.gd / jing_yan_ui.gd / qiang_hua_dan_chuang.gd
- QiangHuaDanChuang.tscn / YuNpc.tscn / Main.tscn / project.godot / data/**（含六张卡 .tres、阈值表）
- zhang_ben.gd 内 jia_jing_yan / xuan_ka / yi_xuan_ka / jing_yan_bian_hua / sheng_ji / ka_yi_xuan / MEI_JI_TIXING（只加不改）
- yu_npc.gd 的生成注入/出屏回收逻辑；yu.gd 的移动规则/无敌闪红结构

## 白名单要点

- 修改 3 脚本（yu.gd / yu_npc.gd / zhang_ben.gd）+ 1 场景（Yu.tscn）
- 零新增生产资源文件；新增仅 3 份报告 + 任务包自身 + 文档（词汇表 md/docx、路线图、索引、审计）
