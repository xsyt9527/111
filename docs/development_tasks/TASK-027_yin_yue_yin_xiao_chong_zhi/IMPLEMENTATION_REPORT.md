# TASK-027 实现报告

- 任务：全部音乐与音效重制：3 条 BGM 重编曲 + 19 条 SFX 统一生成
- 规格：v1；基线提交 `f27ae56`；实现日期 2026-11-15
- 状态：step-01~04 完成；22 条 WAV、接线、八步门禁（3273 断言）与 scope 检查全过；仅用户 F5 试听待参与
- 约束：本路未 commit、未 push；未改 `tests/ce_panding.gd`，未新增断言

## 一、实现总览

| Step | 内容 | 结果 |
|---|---|---|
| 01 | 12 条既有音效重写 + 7 条旧键音效补齐，`JOBS` 扩到 19 | 完成，19/19 校验通过 |
| 02 | `yin_xiang.gd` 7 个旧键 preload 改接新文件，删除 11 条旧 wav | 完成，19 键键名未改 |
| 03 | 3 条 BGM 重编曲，修复 `inst_triple` 失谐成对，补 `validate_bgm()` | 完成，3/3 校验通过 |
| 04 | 导入、八步门禁、scope、文档收尾 | 导入 0 ERROR；八步全绿 3273 断言；scope 0 violation；F5 待用户 |

## 二、分步实现

### Step 01：19 条音效统一生成（`tools/yinyue/shengcheng_yin_xiao.py`）

- `JOBS` 从 12 条扩到 19 条，新增 7 条旧键音效生成函数：`an_niu`、`chi`、`tan_chuang`、`fang_neng_li`、`shi_kong`、`sheng_li`、`shi_bai`。
- `triple()` 的第二/第三振荡器改为成对写 `finel/finer`（`finel1=finer1=fine1`），消除左右声道单边失谐在下混后形成的拍频。
- `track()` 新增 `pattern_len` 参数；`sheng_li`（2.5 秒）两条轨改用 240 ticks 的 2.5 秒 pattern，避免 2.0 秒处被硬切。
- 后处理统一：单声道下混 → 定长裁剪 → 10Hz 高通去直流 → 升余弦淡入淡出 → 峰值归一化 → 循环类尾音折回。
- `validate()` 保留并覆盖全部 19 条：`44100Hz/16bit/1ch`、时长误差 ≤0.002s、峰值 -3.0~-1.0 dBFS；循环类另查首尾差 ≤0.005 且端点 ≤0.001。
- `main()` 专项探针保留：F5 死亡静默段、F10 声呐基频、F11 四段警报主频、F1 低频 thump。

| 编号 | 键名 | 文件 | 时长 | 设计要点 |
|---|---|---|---|---:|---|
| F1 | `yao` | `yin_xiao_yao_ji.wav` | 0.300s | 咬中：短噪声脉冲 + 73Hz 低频 thump |
| F2 | `tun_xia` | `yin_xiao_tun_xia.wav` | 0.800s | 吞噬：上滑滑音 + 咕咚 |
| F3 | `sheng_ji` | `yin_xiao_sheng_ji.wav` | 1.200s | 升级三选一：大调琶音铃 |
| F4 | `shou_shang` | `yin_xiao_shou_shang.wav` | 0.600s | 被咬掉肉：撕裂噪声 + 下滑 |
| F5 | `si_wang` | `yin_xiao_si_wang.wav` | 2.000s | 死亡：下潜 → 0.95~1.35s 留白 → 回声 |
| F6 | `chong_ci` | `yin_xiao_chong_ci.wav` | 0.500s | 冲刺：白噪扫频 whoosh |
| F7 | `dian_xi` | `yin_xiao_dian_xi.wav` | 0.800s | 电系：放电/电脉冲/电麻失控 |
| F8 | `du_xi` | `yin_xiao_du_xi.wav` | 1.000s | 毒系：毒晕失控 |
| F9 | `xuan_wo` | `yin_xiao_xuan_wo.wav` | 1.500s | 漩涡释放：反向吸聚 |
| F10 | `sheng_na` | `yin_xiao_sheng_na.wav` | 1.000s | 声呐：800Hz ping + 余响 |
| F11 | `jing_bao` | `yin_xiao_jing_bao.wav` | 2.000s | 机械船预告：440/660Hz 双音警报，循环 |
| F12 | `jiao_zhi` | `yin_xiao_jiao_zhi.wav` | 0.400s | 吃鱼肉块：两下短咀嚼 |
| F13 | `an_niu` | `yin_xiao_an_niu.wav` | 0.120s | 按钮点击 |
| F14 | `chi` | `yin_xiao_chi.wav` | 0.350s | 吃植物 |
| F15 | `tan_chuang` | `yin_xiao_tan_chuang.wav` | 0.500s | 三选一弹窗弹出 |
| F16 | `fang_neng_li` | `yin_xiao_fang_neng_li.wav` | 0.400s | 主动能力释放 |
| F17 | `shi_kong` | `yin_xiao_shi_kong.wav` | 0.700s | 失控兜底 |
| F18 | `sheng_li` | `yin_xiao_sheng_li.wav` | 2.500s | 胜利结算（专用 2.5 秒 pattern） |
| F19 | `shi_bai` | `yin_xiao_shi_bai.wav` | 2.000s | 失败结算 |

19 条产物统一为 44.1kHz/16bit/单声道/峰值 -1.50 dBFS。

### Step 02：键表接线与旧文件清理（`scripts/yin_xiang.gd`）

- `YIN_XIAO_BIAO` 仍是 19 键，键名一个未改；24 处 `an_niu` 调用点与其余调用点零改动。
- 7 个旧键 preload 全部改接统一生成器产物：

| 键名 | 旧文件 | 新文件 |
|---|---|---|
| `an_niu` | `assets/yinxiao/an_niu.wav` | `assets/yinxiao/yin_xiao_an_niu.wav` |
| `chi` | `assets/yinxiao/chi.wav` | `assets/yinxiao/yin_xiao_chi.wav` |
| `tan_chuang` | `assets/yinxiao/tan_chuang.wav` | `assets/yinxiao/yin_xiao_tan_chuang.wav` |
| `fang_neng_li` | `assets/yinxiao/fang_neng_li.wav` | `assets/yinxiao/yin_xiao_fang_neng_li.wav` |
| `shi_kong` | `assets/yinxiao/shi_kong.wav` | `assets/yinxiao/yin_xiao_shi_kong.wav` |
| `sheng_li` | `assets/yinxiao/sheng_li.wav` | `assets/yinxiao/yin_xiao_sheng_li.wav` |
| `shi_bai` | `assets/yinxiao/shi_bai.wav` | `assets/yinxiao/yin_xiao_shi_bai.wav` |

- 删除 11 条旧 wav 及其 `.import`：`an_niu`、`chi`、`fang_neng_li`、`sheng_ji`、`sheng_li`、`shi_bai`、`shi_kong`、`shou_shang`、`si_wang`、`tan_chuang`、`yao`。
- `BGM_QU_MU` 仍是 `shen_hai` / `tan_suo` / `jue_zhan` 三首，运行时循环标记逻辑未动。

### Step 03：3 条 BGM 重编曲（`tools/yinyue/shengcheng_yinyue.py`）

| 曲目 | 文件 | BPM | 小节 | 时长 | 峰值 | RMS |
|---|---|---:|---:|---:|---:|---:|
| 深海摇篮 | `bgm_shen_hai.wav` | 56 | 12 | 51.429s | -6.00 dBFS | -16.9 dB |
| 深海探索 | `bgm_tan_suo.wav` | 96 | 16 | 40.000s | -1.00 dBFS | -17.7 dB |
| 钢铁围猎 | `bgm_jue_zhan.wav` | 140 | 24 | 41.143s | -1.00 dBFS | -12.3 dB |

- `inst_triple` 修复：`finel1` 与 `finer1` 统一由 `fine1` 成对写入；该函数 docstring 记录 LMMS 1.2.2 单边失谐会造成单声道拍频。
- `qu_shen_hai`：和声垫 `fine1=0`、低通 900→820Hz；低音持续 `fine1=0`、低通 500→460Hz；钟琴 `fine1=0`、低通 3200→2600Hz、力度 78→76、轨音量 42→40。
- `qu_tan_suo`：军鼓低通 6000→5000Hz、轨音量 150→112；闭镲变量改名 `bi_he`，删除 `b % 4 == 3` 加花，力度 56/34→38/24、轨音量 80→56；删除整条沙锤轨；琶音低通 2600→2300Hz、轨音量 42→38；旋律低通 4200→3800Hz。
- `qu_jue_zhan` 整函数重写，六轨四层：
  - ① 低频持续：正弦根音 + 五度长音，2 小节换 Em/C/G/D，无节奏切分，轨音量 56；
  - ② 暖垫：三角三和弦长音，低通 700Hz，轨音量 26；
  - ③ 干净四拍：底鼓每拍（16~19 小节减为 1/3 拍）、军鼓 2/4 拍（不用 `snare_harsh`）、八分闭镲轻打，无拍手/吊镲/十六分镲；
  - ④ 克制铜管：8/12/16 小节块头三音（根-五度-八度），20/22 小节和弦内音上行；三角+正弦、低通 1900Hz，不用锯齿。
  - 删除：十六分锯齿推进贝斯、锯齿+方波主旋律、每小节六次切分铜管、拍手、吊镲、十六分闭镲堆叠、`snare_harsh`、C→C# 半音走向。
- 新增 `dbfs()` 与 `validate_bgm()`：格式 44.1kHz/16bit/单声道、时长 ±0.05s、峰值目标 ±1dB、首尾 10ms 电平与接缝 ≤0.005。
- `render()` 末尾自动调用 `validate_bgm()`，校验失败直接中止。

## 三、改动文件

- `tools/yinyue/shengcheng_yin_xiao.py`
- `tools/yinyue/shengcheng_yinyue.py`
- `tools/yinyue/yin_xiao_*.mmp`（12 条重写 + 7 条新增）
- `tools/yinyue/bgm_shen_hai.mmp`、`bgm_tan_suo.mmp`、`bgm_jue_zhan.mmp`
- `scripts/yin_xiang.gd`（只改 7 个旧键 preload 与注释，键名/结构未动）
- `assets/yinxiao/`：19 条 `yin_xiao_*.wav`、3 条 `bgm_*.wav`，删除 11 条旧 wav 与 `.import`

## 四、验证结果

- `shengcheng_yin_xiao.py`：19/19 job 成功；`validate()` 19/19 PASS；专项探针 F5 静默 -68.1 dBFS、F10 800.0Hz、F11 440/660/440/660Hz、F1 73.3Hz。
- `shengcheng_yinyue.py`：3 首渲染成功；`validate_bgm()` 3/3 PASS，接缝均为 0.000000。
- 独立 Python 复核 22 条 wav：格式/时长/峰值/接缝全 PASS（详见 `VERIFICATION_REPORT.md`）。
- headless `--import`：0 ERROR，22 个 `.import` 齐全。
- 八步门禁：`232 / 25 / 1422 / 8 / 20 / 144 / 1422` 全绿，0 failed，无 ERROR，合计 **3273** 断言。
- `validate_task.py`：`VALID: TASK-027 v1 (plan_driven)`；`check_task_scope.py check`：106 allowed / 73 unchanged / 0 violation。
- 文档收尾后最终复跑：scope 117 allowed / 65 unchanged / 0 violation。

## 五、兼容与回滚

- 19 个键名与 `BGM_QU_MU` 三首曲目不变，所有调用点零改动。
- `.mmp` 工程保留在 `tools/yinyue/`，可用 LMMS 重新渲染；`render/` 中间目录渲染后自动清理。
- 若 F5 认为某条音效或某首 BGM 不合适，只需改对应生成函数并重跑单条 job，不触碰接线与测试契约。
- 三首 BGM 峰值差异（主界面 -6dBFS、局内/决战 -1dBFS）是既有混音口径，不是本次引入。

## 六、待收尾

1. 用户 F5 试听：19 条音效辨识度、3 首 BGM 循环接缝、决战曲是否仍有刺耳高频或怪异走向。
2. 用户完成学习检查点（orientation / godot-inspection / verification-handoff）。
3. 主会话更新任务索引、引擎词总表、学习路线与交接文档；未 commit、未 push。

## 七、过程清理

- LMMS 中间渲染目录 `tools/yinyue/render/` 已由生成器自动删除，目录本身也已清理；`tools/yinyue/` 只保留生成器与 `.mmp` 正式产物。
- 本路未产生临时脚本或调试截图；未 commit、未 push。
