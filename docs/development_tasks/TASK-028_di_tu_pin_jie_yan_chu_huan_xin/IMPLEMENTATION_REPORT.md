# TASK-028 实现报告

- 任务：九图拼合结尾演出重做：慢推镜、左上角起逐张拼合、打字机与冷蓝船影
- 规格：v1（approved）；基线提交 `f27ae56`；实现日期 2026-11-15
- 状态：源码视觉与测试断言完成；八步门禁 3273 断言全绿、scope 0 violation、验证器 VALID；F5 目检待用户确认
- 约束：本轮未 commit、未 push；`tests/ce_panding.gd` 断言由主会话补齐并真实运行，`--import` / `pao_pi.bat` / `check_task_scope.py` 已在收尾阶段跑完

## 一、实现总览

| Step | 内容 | 结果 |
|---|---|---|
| 01 | 黑边合拢到 92px、九格按左上角起行优先显影、波纹与接缝金线 | 完成 |
| 02 | 玩家格金框、镜头轻推与区域名/水位小字打字机、回全图留白 | 完成 |
| 03 | 4 帧动态船体压入、冷蓝背光与全图压暗、舱灯闪烁；删除红闪/震屏/震惊气泡 | 完成 |
| 04 | 演出期间隐藏气泡层与设置按钮、ESC 跳过、单次 `jie_shu` 收尾 | 源码完成；6zf 断言已加入并全绿；门禁 3273 断言 |

## 二、修改文件与函数清单

### `scripts/di_tu_pin_jie_yan_chu.gd`（整文件重写，约 620 行）

保留的静态纯函数契约（签名与语义不变）：

- `quan_tu_zoom(ping_mu)` / `ge_zi_qu(pian)` / `ge_zi_zhong_xin(pian)` / `wan_jia_pian(shijie_wei)`
- `fei_ru_qi_dian(pian)`：保留但仅作静态契约，运行时不调用；`FEI_RU_JU_LI = 1100.0` 不变
- `WAN_JIA_JU_JIAO = 0.88`、`YAN_CHU_SHI_CHANG = 7.3`、`GE_SHU = 9`、地图尺寸常量不变
- `pin_jie_shun_xu(_wan_jia_pian_hao)`：返回值改为 `[0,1,2,3,4,5,6,7,8]`（左上角起行优先），与玩家格无关

新增/改写的函数：

| 函数 | 职责 |
|---|---|
| `bo_fang(...)` | 注入玩家/相机/区域名/目标 zoom，依次建地图、船、UI、启动时间轴 |
| `_jian_di_tu()` | 深海底色底板；九块 `Sprite2D`（初始 `position=ge_zi_zhong_xin(pian)`、`scale=1`、`alpha=0`、`region_rect=ge_zi_qu(pian)`）；九圈波纹 `Line2D`；四条接缝金线；玩家格金框 |
| `_yuan_huan_dian(ban_jing)` | 32 段圆环点阵，给波纹 `Line2D` 用 |
| `_jian_ren_lei()` | 4 帧 `AnimatedSprite2D`（`ji_qi_chuan_4zhen.tres`、动画 `&"dong"`、4× 缩放、暗色剪影、z=-1）；两枚红色舱灯 `ColorRect`（`self_modulate` 闪 2 次）；静态贴图兜底分支 |
| `_jian_ui()` | CanvasLayer 100：压暗层、冷蓝层、上下黑边、标题、区域名、水位小字、跳过按钮 |
| `_xin_biao_qian(...)` | 统一创建带描边的演出文字 |
| `_kai_shi()` | 黑边 0.5 秒到 92px；相机 1.6 秒到全图中心；跳过按钮 0.6 秒出现；九格按 `[0..8]` 每 0.15 秒错峰显影；金线 1.2 秒起分段亮到 0.55；注册绝对时间轴节点 |
| `_tie_xian_ying(...)` | 单块显影：到点才把位置拨到上方 20px、缩放拨到 0.96，再 alpha 0→1、scale 0.96→1、位置落回最终中心；波纹扩散淡出 |
| `_she_wei_zhi(jing, wei_zhi)` | Tween 回调：显影到点才设置位置起点 |
| `_she_suo_fang(jing, bi_li)` | Tween 回调：显影到点才设置缩放起点 |
| `_ju_jiao_wan_jia()` | 2.5 秒：`sheng_ji` 音效、玩家格金框亮起、相机 0.6 秒推近玩家 zoom 0.88、区域名与「第 1 天 · 水位线 −12m」打字机 |
| `_hui_quan_tu()` | 3.6 秒：相机 0.6 秒回全图、区域名/小字淡出留白 |
| `_kai_shi_ren_lei()` | 4.5 秒：`jing_bao` + 决战曲；船体 1.4 秒压入到 `REN_LEI_LUO_DIAN`；冷蓝到 0.12、压暗到 0.12（各 0.8 秒）；标题 0.05 秒/字打字机 |
| `_ting_zhu()` | 5.9 秒：两枚舱灯各闪 2 次；落点一次 `TE_XIAO.you_er_qi_pao` 气泡 |
| `_shou_wei()` | 6.6 秒：跳过按钮淡出、黑边展开、船/九图/冷蓝/压暗/标题/金线/金框淡出、相机 0.65 秒收回玩家目标 zoom |
| `_tiao_guo()` | 跳过按钮与 ESC 的共同入口，转 `_jie_shu_yan_chu()` |
| `_unhandled_input(event)` | `ui_cancel`（ESC）跳过；收尾后不再吃输入 |
| `_jie_shu_yan_chu()` | 唯一收尾入口：一次性守卫、kill 全部 tween、还原玩家姿态与相机 offset、`jie_shu.emit()` 一次、`queue_free()` |
| `_zuo_tween()` / `_ding_shi(...)` | 统一登记 tween / 绝对时间轴调度 |

删除的旧实现：

- `_tie_fei_xing()`（飞入 + `BACK` 回弹）
- `_zhen_dong()` 与震屏调用（`ZHEN_DONG_FU` 常量保留兼容，不再使用）
- `_process()` 与震惊气泡跟随（`_zhen_jing` / `_zhen_jing_wen` / `_zhen_jing_ke_jian` 全部删除）
- 红闪 `_hong_guang` 全屏 `ColorRect` 与 `_kai_shi_ren_lei` 中的红色闪光
- 玩家上浮 −90px 与 `rotation −0.35` 翘头；玩家在演出中不再移动/旋转（收尾仅防御性还原）

### `scripts/main.gd`（+18 行，两处）

- 新增成员：`_yan_chu_qian_qi_pao_ke_jian`、`_yan_chu_qian_she_zhi_ke_jian`（记录演出前可见性）。
- `_bo_fang_ren_lei_yan_chu()`：在 `_qie_huan_hud(false)` 之后记录并隐藏 `$QiPaoCeng`（Node2D）与 `$SheZhi`（CanvasLayer，含设置按钮）。
- `_on_ren_lei_yan_chu_jie_shu()`：在 `_qie_huan_hud(true)` 之后按记录还原两个节点。
- 其余流程时序（锁输入、无敌、藏背景、生成船、取景、横幅）未改动。

## 三、7.3 秒时间轴

| 时间（秒） | 行为 |
|---|---|
| 0.0~1.6 | 上下黑边 0.5 秒合拢到 92px；相机 1.6 秒 `SINE/IN_OUT` 到全图中心 |
| 0.5~2.5 | 九格按 `pin_jie_shun_xu=[0..8]` 每 0.15 秒错峰显影：初始在最终中心、`scale=1`、`alpha=0`；到点拨 0.96 与上方 20px，随后 alpha 0→1、`scale 0.96→1`、0.35 秒落回中心；每块一圈波纹（半径 12→220 淡出） |
| 1.2~2.2 | 四条接缝金线分段亮到 0.55 |
| 2.5~3.6 | 玩家格金框亮起；相机 0.6 秒推近玩家 zoom 0.88；区域名 + 水位小字打字机 |
| 3.6~4.5 | 相机 0.6 秒回全图、文字淡出、留白 |
| 4.5~5.9 | `jing_bao` + 决战曲；4 帧船体 1.4 秒从画面上缘压入；冷蓝 `Color(0.58,0.74,0.92)` → 0.12；全图压暗 → 0.12；标题「人类机器船降临」0.05 秒/字 |
| 5.9~6.6 | 停驻；两枚红色舱灯各闪 2 次；落点一次可控气泡 |
| 6.6~7.3 | 黑边展开、九图/船/冷蓝/文字淡出、相机 0.65 秒收回玩家；7.3 秒 `_jie_shu_yan_chu()` |
| 跳过 | 跳过按钮 0.6 秒出现；按钮/ESC 均走同一收尾入口 |

## 四、关键契约

- `pin_jie_shun_xu(...)` 恒返回 `[0,1,2,3,4,5,6,7,8]`：左上→右上→第二行→右下，玩家格按所在序号出现，不再固定最后。
- `jie_shu` 单次保证：`_jie_shu_le` 守卫在 `_jie_shu_yan_chu()` 入口直接 return；自然结束、跳过按钮、ESC 三条路径共用该入口；入口内先 kill 全部登记 tween，再 `emit` 一次并 `queue_free()`。`Main` 因此只会收到一次信号、只生成一条船。
- 所有 tween 走 `_zuo_tween()` 登记；`_ding_shi()` 用绝对时间轴回调，跳过时统一 kill，不会在收尾后改已释放节点。
- 静态纯函数契约保留：`quan_tu_zoom` / `ge_zi_qu` / `ge_zi_zhong_xin` / `wan_jia_pian` / `fei_ru_qi_dian` 签名与返回值不变；`fei_ru_qi_dian` 运行时不调用，注释标明「兼容静态契约」。
- 冷蓝背光由 CanvasLayer 全屏 `ColorRect` 实现（`Color(0.58,0.74,0.92)`，最高 alpha 0.12）；全图压暗为独立全屏黑 `ColorRect`（最高 alpha 0.12）；两者都在黑边/文字之下。

## 五、编译自测

- 方法：临时 `extends SceneTree` 脚本，在 autoload 注册后 `load("res://scripts/di_tu_pin_jie_yan_chu.gd")`，检查 `can_instantiate()` 并 `new()`；临时文件跑完即删。
- 结果：`LOAD_YANCHU=true CAN_INSTANTIATE=true NEW_NODE=true`。
- 期间 `--check-only --script` 对 `main.gd` 只到第 85 行 `ZhangBen`（Autoload 标识符）即停，属单脚本模式限制；同时 027 音频处于旧 wav 已删、新 wav 未生成的中间态，`yin_xiang.gd` 的 7 个 `preload` 全部报 "no resource loaders"，`zhang_ben.gd` / `main.gd` 整链编译不可用。主会话已确认 027 音频生成完成且 `--import` 0 ERROR，`main.gd` 的运行时编译由统一门禁覆盖。
- 主会话已跑：`--import`、`tests/pao_pi.bat`、`check_task_scope.py`、`validate_task.py`；数字见第六节。

## 六、待收尾

- `tests/ce_panding.gd`：主会话已把断言清单落到用例 6zf，`ce_panding` 1313→1422，全绿。
- 八步门禁：232 / 25 / 1422 / 8 / 20 / 144 / 1422 全绿，合计 3273 断言；`validate_task.py` VALID；scope 13 allowed / 167 unchanged / 0 violation。
- 文档收尾后最终复跑：scope 23 allowed / 159 unchanged / 0 violation。
- F5 目检：九格拼合顺序、波纹/金线观感、玩家格金框与打字机、4 帧船体压入、冷蓝与压暗、舱灯与气泡、ESC/按钮跳过、结束后只生成一条船；待用户确认，未伪造结果。
- 本轮未 commit、未 push。
