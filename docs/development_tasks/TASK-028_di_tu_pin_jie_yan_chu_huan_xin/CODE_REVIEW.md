# TASK-028 代码审查

- 审查范围：九图拼合结尾演出的源码、`Main` 集成、测试断言与任务文档
- 审查日期：2026-11-15
- 结论：通过；时间轴、跳过与单次收尾契约成立，八步门禁 3273 断言全绿、scope 0 violation；F5 目检待用户

## 一、演出脚本 `scripts/di_tu_pin_jie_yan_chu.gd`

- **顺序契约**：`pin_jie_shun_xu(_wan_jia_pian_hao)` 忽略玩家格，恒返回 `[0..8]`；九格按左上起行优先显影，玩家格不再固定最后。旧静态函数 `fei_ru_qi_dian` 保留签名与常量，运行时不调用，避免破坏既有纯函数断言。
- **显影而非飞入**：`_jian_di_tu()` 把九块 `Sprite2D` 直接放在 `ge_zi_zhong_xin(pian)`，初始 `scale=1`、`alpha=0`；`_tie_xian_ying()` 到点后才经 `_she_wei_zhi`/`_she_suo_fang` 拨到上方 20px 与 0.96，再缓回。起点延迟设置避免了负延迟 tween 或首帧闪现，也符合“从上方落下 18~24px”的任务口径。
- **波纹与接缝**：每块一圈 `Line2D` 波纹（12→220 淡出），四条内部接缝金线分段亮到 0.55；玩家格金框单独一条 alpha tween。几何由 `ge_zi_qu`/`ge_zi_zhong_xin` 推导，不写死九套坐标。
- **镜头分段**：0→1.6s 全图、2.5s 推近玩家 0.88、3.6s 回全图、6.6s 收回目标 zoom。所有相机 tween 都登记在 `_bu_zu`，跳过时统一 kill，不会在节点释放后继续写相机。
- **船体与冷蓝**：`_jian_ren_lei()` 优先用 `CHUAN_4ZHEN` 的 `AnimatedSprite2D`（`dong`、4×、暗色剪影、z=-1），静态贴图兜底；冷蓝 `(0.58,0.74,0.92)` 与全图压暗各 0.12，均在黑边/文字之下。旧红闪 `_hong_guang`、震屏 `_zhen_dong`、震惊气泡 `_process`/`_zhen_jing` 全部删除，没有残留字段或节点。
- **收尾单次**：`_jie_shu_yan_chu()` 入口先查 `_jie_shu_le`，置位后 kill 全部 tween、清空 `_bu_zu`、防御性还原玩家 `position/rotation` 与相机 `offset`，再 `jie_shu.emit()` 一次并 `queue_free()`。自然 7.3 秒、跳过按钮、ESC 三条路径共用该入口，`Main` 因此只会生成一条船。
- **输入**：`_unhandled_input` 只认 `ui_cancel`，收尾后直接 return，不会重复吃输入；跳过按钮与 ESC 走同一 `_tiao_guo()`。

## 二、`scripts/main.gd` 集成

- 演出前记录 `QiPaoCeng` 与 `SheZhi` 的 `visible` 原值再隐藏，结束后按原值恢复；只改可见性，不重建节点，避免设置按钮/气泡层在演出层上穿帮。
- `_yan_chu_qian_qi_pao_ke_jian` / `_yan_chu_qian_she_zhi_ke_jian` 是普通成员，节点缺失时保持默认 false，恢复逻辑有 `get_node_or_null` 保护。
- 原有锁输入、10 秒无敌、藏背景/鱼群/植物/鲸鲨、生成船、取景、横幅的时序未改，TASK-028 的改动面收敛在可见性与演出节点本身。

## 三、测试审查

- 用例 6zf 覆盖：源码不再调用 `fei_ru_qi_dian`、无 `_process`/`_zhen_dong`/`_tie_fei_xing`、`_ding_shi(7.3, _jie_shu_yan_chu)` 存在；九格顺序与全部分镜常量精确值；`_jian_di_tu()` 后 9 块 region/初始位置/scale/alpha、9 波纹、4 接缝、金框初始 alpha；`_jian_ren_lei()` 的四帧船体/4×/两枚舱灯；ESC + 跳过 + 重复收尾只 emit 一次并自毁；`main.gd` 两个可见性记录字段存在。
- 断言既有静态契约也有运行时实例化，能抓住“论文档与实现不一致”的回归；不断言具体 tween 中间帧，避免帧率相关脆测。
- `ce_panding` 1422 passed / 0 failed；全门禁 3273 断言全绿，0 ERROR。

## 四、范围、风险与结论

- 产品代码只改 `scripts/di_tu_pin_jie_yan_chu.gd`、`scripts/main.gd`；`tests/ce_panding.gd` 属本包允许的测试文件。未改 `Main.tscn`、`project.godot`、027 音频或其他包产品代码。
- 风险 1：演出依赖绝对时间轴，低帧率设备上回调可能轻微晚到，但所有回调都有 `_jie_shu_le` 守卫，最坏是晚一帧，不会重复 emit。
- 风险 2：气泡落点 `Vector2(REN_LEI_LUO_DIAN.x, 900.0)` 为世界坐标，是否在最终镜头内需 F5 目检确认；自动化只验证调用一次，不验证观感。
- 风险 3：`Main` 的可见性恢复依赖 `jie_shu` 信号；若场景中途被销毁，恢复不会发生，但场景切换本身会重建 HUD，属可接受边界。
- `validate_task.py` VALID；`check_task_scope.py check` 13 allowed / 167 unchanged / 0 violation；未 commit、未 push。
- 文档收尾后最终复跑：scope 23 allowed / 159 unchanged / 0 violation。
- 同意交付；F5 目检项按 `VERIFICATION_REPORT.md` 第四节执行，结果未伪造。
