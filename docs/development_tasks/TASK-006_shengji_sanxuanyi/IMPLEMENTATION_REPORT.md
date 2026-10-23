# TASK-006 实现报告

## 概要

四步全部实现并通过检查：QiangHuaKa 强化卡模具 + 6 张卡 .tres（注册表模式复用）→ 升级阈值常量数据化（ShengJiBiao.tres，等值切换）→ 弹窗场景骨架（CanvasLayer + process_mode=WHEN_PAUSED）→ 升级触发（冻结 + 不放回抽样 3 张）→ 选卡入账（xuan_ka + ka_yi_xuan 信号预埋）。**肉鸽核心节拍器上线：升级 → 冻结 → 三选一 → 点选继续。**

## 分步交付

| Step | 内容 | 文件 | 检查 |
|---|---|---|---|
| 01 | 数据层 | qiang_hua_ka.gd、sheng_ji_biao.gd（各+.uid）、7 张 .tres、zhang_ben.gd | import 0 错、360 帧 0 错（等值切换零行为变化） |
| 02 | 弹窗骨架 | QiangHuaDanChuang.tscn、qiang_hua_dan_chuang.gd（+.uid）、Main.tscn | import 0 错、360 帧 0 错 |
| 03 | 升级触发 | qiang_hua_dan_chuang.gd | 探针 TONGGUO（修复路径 bug 后，见过程记录） |
| 04 | 选卡入账 | zhang_ben.gd、qiang_hua_dan_chuang.gd | 全链路探针 TONGGUO + scope 20 allowed 0 violation |

## 卡池交付值

| 卡名 | 文件 | xiao_guo | shu_zhi | 备注 |
|---|---|---|---|---|
| 迅捷 | xun_jie.tres | yidong_sudu | 0.15 | |
| 催肥 | cui_fei.tres | mei_ji_tixing | 0.05 | 改的是升级增幅 |
| 磁吸 | ci_xi.tres | ci_xi_fanwei | 0.4 | 学生第 3 课提案，第 7 课双 Area2D |
| 贪食 | tan_shi.tres | tun_shi_fanwei | 0.15 | |
| 活力 | huo_li.tres | wudi_shi_chang | 0.5 | |
| 睿智 | rui_zhi.tres | jing_yan_jia_cheng | 0.25 | |

效果字段全部只存不用（第 7 课消费）——本课选择只入账。

## 设计决策（学生选定，均为推荐项）

1. 强化卡走注册表模式（加卡零代码）
2. 暂停用引擎级 get_tree().paused + WHEN_PAUSED（新系统自动继承冻结）

## 过程记录

- **Node not found 事故与修复**：step-03 后学生 F5 反馈报错。一次性探针场景（正常启动 + 强制升级，避开 --script 不加载 Autoload 与 _init 中 add_child 时机两个坑）复现：`Node not found: "KaPianZu/Ka1/MingCheng"`——脚本 `$` 路径少算场景里的 KaZhong(VBoxContainer) 层。补全三层路径后探针 TONGGUO。
- **自动化盲区暴露（学生功劳）**：此前 360 帧检查将输出丢弃 /dev/null 只看退出码，而 Node not found 是非致命错误、退出码照样 0——学生当了真人测试员才暴露。**检查方式永久升级：所有运行检查输出经 error/not found 筛查**。
- **阈值数据化等值验证**：sheng_ji_biao.tres 与旧常量数值完全一致 [8,20,35,55,80,110]，dangqian_yuzhi() 改读表，行为零变化。
- **学生实验还原纪律**：阈值表实验后当场还原（git diff 复核无残留）——第 5 课遗留待巩固项销账。

## 行为变化清单

- 升级瞬间全场冻结（玩家/鱼群/Timer 全停），弹出 3 张互不相同的强化卡
- 点选任一张：入账（yi_xuan_ka 追加 + ka_yi_xuan 信号）、解冻、弹窗隐藏
- 二次升级可重复触发（visible 开关复用同一实例，无重复连接）
- 升级阈值来源从常量变 .tres（数值不变）；加新卡 = 新建 .tres + 拖进注册表，零代码
- 六课全量行为（移动/生成/回收/判定/无敌/涨条/长大）无退化（学生实测确认）
