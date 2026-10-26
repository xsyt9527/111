# TASK-008 实现报告（IMPLEMENTATION_REPORT）

## 交付概览

五步全部按规格实现（v1 四步 + v2 一步）：血量系统 + 血条 UI → 满级封顶 → 死亡切换 + 结算场景 → 账本重置 + 重开闭环 → 嘴身判定圈拆分（贪食观察项落地）。肉鸽"有代价的死亡"闭环完成：三撞血尽 → 结算页展示等级与 build → 一键重开全归零。三次 P3 备忘集中兑现（P3-1 拆分 / P3-2 场景销毁清 bei_xi / P3-3 chong_zhi）。

## 分步明细

### step-01 血量系统 + 血条 UI（v1）

| 文件 | 改动 |
|---|---|
| `yu.gd` | +`zuida_xue := 3`（@export）/ `xue_liang` + `signal xue_liang_bian_hua(dangqian, zuigao)`；`_shoushang()` 扣血广播（第 3 课挂钩点兑现）；血尽 `_si_wang()` 占位 |
| `xue_liang_ui.gd`（新） | 经 `get_first_node_in_group("wan_jia")` 找玩家，听信号刷 ProgressBar——信号驱动 UI 二次复用 |
| `XueLiangTiao.tscn`（新） | CanvasLayer + ProgressBar（学生亲手 Styles 换红填充 StyleBoxFlat） |
| `Main.tscn` | +XueLiangTiao 实例节点 |

血量所有者=玩家（账本不成玩家仓库，沿第 7 课决策 2A）。

**学生真人测试抓到真 bug**：第 7 课改名 PandingQu→ShangQu 漏改 match 贪食分支 `$` 路径（自动检查不点卡的盲区）——已修复 + 探针验证。

### step-02 满级封顶（v1）

`zhang_ben.gd` `jia_jing_yan()` 表头封顶分支：`deng_ji > yuzhi_zu.size()`（Lv.7）→ 经验钉 `dangqian_yuzhi()` 满格、只发 `jing_yan_bian_hua` 不发 `sheng_ji`。下游三家听众（弹窗/长大/经验条）零改动自动静默。数据表边界处理：`dangqian_yuzhi()` 只兜了显示层，记账口才是真闸门。

### step-03 死亡切换 + 结算场景（v1）

| 文件 | 改动 |
|---|---|
| `yu.gd` | `_si_wang()` 占位 → `change_scene_to_file("res://scenes/JieSuan.tscn")`（帧末生效，碰撞回调内安全） |
| `JieSuan.tscn`（新） | CanvasLayer 根：BanDi/BiaoTi/DengJi/KaLieBiao/ChongKai |
| `jie_suan.gd`（新） | `_ready` 读账本：等级标签 + 遍历 `yi_xuan_ka` 动态填卡名（空卡占位文案）；第 6 课预埋数据首次见天日 |

Main 全树销毁（buff/bei_xi/鱼群/弹窗就地释放，CODE_REVIEW P3-2 兑现）；账本 Autoload 常驻。

### step-04 账本重置 + 重开闭环（v1）

| 文件 | 改动 |
|---|---|
| `zhang_ben.gd` | +`chong_zhi()`：jing_yan=0 / deng_ji=1 / yi_xuan_ka.clear() / jing_yan_jia_cheng=1.0（局内归零唯一入口，P3-3 兑现） |
| `jie_suan.gd` | ChongKai 接线：`pressed` → `chong_zhi()` + `change_scene_to_file` 回 Main |

自查修复：按钮连接原写在空卡分支 `return` 之后——零卡死亡按钮失灵，挪 `_ready` 首行。重开的两半：场景侧销毁重建自动全新，账本侧手动归零（谁常驻谁负责自己的复位）。

### step-05 嘴身判定圈拆分（v2，范围变更已审批）

| 文件 | 改动 |
|---|---|
| `Yu.tscn` | +ZuiQu（Area2D, mask=2, CircleShape2D_zui r=22 同心）；ShangQu/ChiQu 结构零触碰 |
| `yu.gd` | 判定入口一拆为二：`_on_zui_qu_entered` 只吃（无敌期照样吃）/ `_on_shang_qu_entered` 只伤（含同体型，沿用原规则）；贪食分支 `$ShangQu→$ZuiQu` |

贪食只放大收益不放大代价——"分行为须分 Area2D"第三次递进（按结果分）。

## 自动化检查（每步全跑）

- `--headless --import` 退出码 0 + 输出筛查零命中 ×5 步
- `--headless --fixed-fps 60 --quit-after 360` 退出码 0 + 输出筛查零命中 ×5 步
- `check_task_scope.py check`：v1 收尾 12 allowed / 0 violation；v2 5 allowed / 8 pre-existing / 0 violation
- 一次性探针 ×3（用完即删）：满级封顶（Lv.7 钉死/广播恰 6 次）、死亡重开闭环（四项归零+新实例）、嘴身拆分（四项行为）全 TONGGUO

检查纪律新补两条：① grep 管道只看输出不看命令是否真跑（引擎路径笔误假阴性教训）② 探针必带 `--quit-after` 保险（解析错误场景不自退）。

## 范围遵守

- v1 修改恰为白名单 3 文件 + 新建 4 文件；v2 范围变更走审批门（Yu.tscn 移入白名单）+ 基线重捕获（12 个 v1 路径入指纹）
- yu_npc.gd / yu_qun.gd / main.gd / 弹窗 / data/ / project.godot 零触碰
- 零新增资源文件；零实验参数（本课未邀请调参，无还原义务）
