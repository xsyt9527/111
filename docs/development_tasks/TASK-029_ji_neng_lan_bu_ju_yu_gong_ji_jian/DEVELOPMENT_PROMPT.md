# TASK-029 开发提示：主动技能栏自适应布局与手动攻击键

## 开工前置

1. 确认 `TASK_STATE.json` 的 `approval_status=approved`（用户已批准 v1）。
2. 运行 `python -I .agents/skills/godot-guided-feature-workflow/scripts/check_task_scope.py capture` 记录实现基线。
3. 顺序依赖：TASK-026 → TASK-027 → TASK-028 → TASK-029 串行，**等 TASK-028 完成后再开工本包**（三包串行原因见主计划：共用 `tests/ce_panding.gd`、共用 scope baseline、共用 `.godot` 导入缓存）。
4. 先读 `scripts/neng_li_ui.gd` 全文与 `scripts/yu.gd` 的 `_chang_shi_yao_ji` / `_yao_ji_mu_biao` / `_process` 自动咬段，再动手。

## step-01 技能栏自适应布局

目标：任意 `zhu_dong_zu` 数量都不溢出 1280×720。

- 在 `neng_li_ui.gd` 顶部新增布局常量：
  ```gdscript
  const MEI_LIE_ZUI_DUO := 5          # 每列最多 5 个
  const ZUI_DUO_LIE := 4              # 最多 4 列
  const YOU_YUAN := 1250.0            # 右侧按钮组右缘
  const ZUO_YUAN := 30.0             # 摇杆换右手侧后的左缘
  const DI_BU_Y := 680.0              # 按钮组下缘
  ```
- 新增纯函数（**不读写节点、不依赖 `self` 状态**，供测试直接调用）：
  ```gdscript
  func ji_neng_bu_ju(shu: int, shi_kou: Vector2) -> Array[Dictionary]
  ```
  返回 `[{"wei_zhi": Vector2, "chi_cun": Vector2}, ...]`，第 i 项对应第 i 个主动按钮。规则：
  - `lie_shu := clampi(ceili(float(shu) / MEI_LIE_ZUI_DUO), 1, ZUI_DUO_LIE)`；`mei_lie := ceili(float(shu) / lie_shu)`。
  - 行高：`mei_lie <= 1` → 间距 72 / 按钮高 64；`mei_lie <= 3` → 间距 60 / 高 52；否则间距 52 / 高 44。
  - 按钮宽：`lie_shu == 1 or 2` → 210；`3` → 168；`4` → 132。
  - 第 0 个在右下：`x = YOU_YUAN - kuan`，`y = DI_BU_Y - gao`；同列向上走 `i % mei_lie`，换列向左走 `ceili((i+1)/mei_lie)-1` 个列宽 + 间距 8。
  - `yao_gan_ce == "you"` 时 x 镜像到左：`x = ZUO_YUAN + lie - (YOU_YUAN - x - kuan)`。
- `_tong_bu_an_niu(shu)` 改为调用纯函数后摆放；缓存 `_shang_ci_shu` 与 `_shang_ci_ce`，数量/侧没变直接 return，避免每帧重建。
- `_ready` 里 `BeiDongLabel` 的 x 跟随 `yao_gan_ce` 的逻辑保留，改为引用同一组常量。
- 长按判定（`AN_XIA_FAN_WEI`）与冷却变暗按按钮实际 `size` 计算，不写死 210×64。

**必须避免**：把布局逻辑塞进 `_process` 每帧重排；按钮 `pressed` 绑定不能因重建丢信号；重建时先 `queue_free` 旧按钮并 `add_child` 新按钮，注意不要在同帧重复 `queue_free` 同一节点。

## step-02 手动攻击键

- `Yu` 新增公开入口：
  ```gdscript
  func yao_ji_shou_dong() -> bool:
      if _yao_ji_leng_que > 0.0: return false
      if _chong_zhuang_sheng_yu > 0.0: return false
      if ZhangBen != null and ZhangBen.kong_zhi > 0.0: return false
      return _chang_shi_yao_ji()   # 内部已有目标判定与冷却设置
  ```
  若 `_chang_shi_yao_ji()` 现状返回 void，则改为返回 bool：空挥 `return false`、咬中 `return true`；调用它的自动咬与测试兼容旧行为（忽略返回值即可）。
- `NengLiUI` 新增 `_gong_ji_an_niu: Button`，在 `_ready` 与重启/换边时创建：
  - `size = Vector2(96, 96)`，`position = gong_ji_an_niu_wei_zhi(shi_kou, yao_gan_ce)`（默认右缘 1250、下缘 680；换边镜像到左缘 30）。
  - 圆形 `StyleBoxFlat`（`corner_radius_* = 48`），文本「咬」；`pressed` 调 `Main.player.yao_ji_shou_dong()`（按现有玩家引用方式取节点）。
  - 每帧（或 0.1 秒节流）刷新：冷却 >0 显示「咬 %.1fs」并 `modulate = Color(0.7,0.7,0.7)`；就绪显示「咬」并 `modulate = Color.WHITE`。
  - 技能组布局把攻击键占位让出：`ji_neng_bu_ju` 的右缘在攻击按钮存在时为 `1250 - 96 - 8 = 1146`（通过参数传入右缘，保持纯函数可测）。
- 演出期间：`NengLiUI` 整层被隐藏时按钮随之隐藏，无需额外逻辑；不要在 `main.gd` 加特判。
- 触摸：`Button` 默认响应触摸；确认不放在摇杆 `AN_XIA_FAN_WEI` 范围内（拇指区重叠由 F5 评估）。

## step-03 测试与文档

- `tests/ce_panding.gd` 新增用例（放在既有 UI 段附近）：
  1. `ji_neng_bu_ju` 对 `shu = 0/1/5/6/10/11/20` 的列数与每列行数。
  2. 上述每个数量下所有矩形 `x/y >= 0`、`x+w <= 1280`、`y+h <= 720`，矩形对两两不相交（20 个时也成立）。
  3. 换边镜像：`yao_gan_ce == "you"` 时全部 x 落在左半屏。
  4. `yu.yao_ji_shou_dong()` 冷却中返回 false；空挥返回 false 且 `_yao_ji_leng_que` 仍为 0；造一条同房小鱼在咬合范围，返回 true 且 `_yao_ji_leng_que > 0`。
  5. `kong_zhi > 0` 与 `_chong_zhuang_sheng_yu > 0` 时返回 false。
- 断言边界：每条用例开始显式 `ZhangBen.jing_yan = 0`、`_yao_ji_leng_que = 0.0`，避免跨用例串味。
- 收尾门禁：
  ```
  python -I .agents/skills/godot-guided-feature-workflow/scripts/validate_task.py docs/development_tasks/TASK-029_ji_neng_lan_bu_ju_yu_gong_ji_jian
  python -I .agents/skills/godot-guided-feature-workflow/scripts/check_task_scope.py check
  MSYS_NO_PATHCONV=1 "D:\001\Godot_v4.7.2-stable_win64.exe" --headless --path "D:\新游戏001" --import
  MSYS_NO_PATHCONV=1 cmd.exe /c "tests\pao_pi.bat"
  ```
- 文档：`TASK_INDEX.md` 状态更新、`引擎词总表.md` + docx 加新词、`LEARNING_ROADMAP.md` 勾掉本课；写 `IMPLEMENTATION_REPORT.md` / `VERIFICATION_REPORT.md` / `CODE_REVIEW.md`。
- 不 commit/push。

## 词表（本课新词）

| 拼音 | 引擎词 | 含义 |
|---|---|---|
| `ji_neng_bu_ju` | layout function | 输入数量与视口，输出位置尺寸的纯函数 |
| `wei_zhi` / `chi_cun` | position / size | 节点左上角坐标 / 矩形尺寸 |
| `mei_lie` | rows per column | 每列排几个 |
| `lie_shu` | column count | 排几列 |
| `jing_xiang` | mirror | 换边时 x 坐标左右翻转 |
| `yao_ji_shou_dong` | manual attack | 手动咬击入口 |
| `tong_yi_leng_que` | shared cooldown | 手动/自动共用同一冷却 |
| `dai_ma_sheng_cheng` | code-generated UI | 按钮由脚本创建，不写进场景文件 |
| `StyleBoxFlat` | StyleBoxFlat | 用圆角半径为 48 画圆形按钮 |
