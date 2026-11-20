# TASK-027 验证报告

- 任务：全部音乐与音效重制：3 条 BGM 重编曲 + 19 条 SFX 统一生成
- 验证日期：2026-11-15
- 环境：Python 3 + numpy（`python -I -X utf8`）读取 WAV 做独立复核；Godot 4.7.2 headless 导入由协调者统一执行
- 结论：音频文件域 22 条 WAV 全部 PASS（格式/时长/峰值/接缝），接线键表未变；八步门禁已由主会话跑至全绿，仅 F5 试听待用户收尾

## 一、生成器内置校验

### 音效：`tools/yinyue/shengcheng_yin_xiao.py`

- `JOBS` 19 条全部渲染成功，`validate()` 逐条检查：
  - 采样率 44100Hz、单声道、16bit；
  - 时长误差 ≤0.002s；
  - 峰值 -3.0 ~ -1.0 dBFS；
  - 循环类（仅 `yin_xiao_jing_bao`）首尾差 ≤0.005 且端点 ≤0.001。
- 结果：**19/19 PASS**，实测峰值全部 -1.50 dBFS，时长误差全部 0.000s。
- 专项探针：F5 死亡静默段 0.95~1.35s RMS **-68.1 dBFS**（目标 ≤-60）；F10 声呐基频 **800.0Hz**；F11 四段警报主频 **440/660/440/660Hz**；F1 咬中低频 thump **73.3Hz**。

### BGM：`tools/yinyue/shengcheng_yinyue.py`

- `validate_bgm()` 逐首检查：44.1kHz/16bit/单声道、时长 ±0.05s、峰值目标 ±1dB、首尾 10ms 端点 ≤0.002 且接缝 ≤0.005。
- 结果：**3/3 PASS**，接缝均为 **0.000000**。

## 二、22 条 WAV 独立复核

独立 Python 脚本直接读取文件头与样本，不依赖 Godot：

| 编号 | 文件 | 格式 | 实测时长 | 期望时长 | 峰值 | RMS | 循环接缝 |
|---|---|---|---|---:|---:|---:|---:|---:|
| F1 | `yin_xiao_yao_ji.wav` | 44100/16/1 | 0.300s | 0.300s | -1.50 dBFS | -21.3 dB | — |
| F2 | `yin_xiao_tun_xia.wav` | 44100/16/1 | 0.800s | 0.800s | -1.50 dBFS | -15.2 dB | — |
| F3 | `yin_xiao_sheng_ji.wav` | 44100/16/1 | 1.200s | 1.200s | -1.50 dBFS | -18.6 dB | — |
| F4 | `yin_xiao_shou_shang.wav` | 44100/16/1 | 0.600s | 0.600s | -1.50 dBFS | -18.2 dB | — |
| F5 | `yin_xiao_si_wang.wav` | 44100/16/1 | 2.000s | 2.000s | -1.50 dBFS | -13.8 dB | — |
| F6 | `yin_xiao_chong_ci.wav` | 44100/16/1 | 0.500s | 0.500s | -1.50 dBFS | -12.4 dB | — |
| F7 | `yin_xiao_dian_xi.wav` | 44100/16/1 | 0.800s | 0.800s | -1.50 dBFS | -15.6 dB | — |
| F8 | `yin_xiao_du_xi.wav` | 44100/16/1 | 1.000s | 1.000s | -1.50 dBFS | -14.7 dB | — |
| F9 | `yin_xiao_xuan_wo.wav` | 44100/16/1 | 1.500s | 1.500s | -1.50 dBFS | -12.9 dB | — |
| F10 | `yin_xiao_sheng_na.wav` | 44100/16/1 | 1.000s | 1.000s | -1.50 dBFS | -14.1 dB | — |
| F11 | `yin_xiao_jing_bao.wav` | 44100/16/1 | 2.000s | 2.000s | -1.50 dBFS | -10.4 dB | 0.000000 |
| F12 | `yin_xiao_jiao_zhi.wav` | 44100/16/1 | 0.400s | 0.400s | -1.50 dBFS | -23.4 dB | — |
| F13 | `yin_xiao_an_niu.wav` | 44100/16/1 | 0.120s | 0.120s | -1.50 dBFS | -21.7 dB | — |
| F14 | `yin_xiao_chi.wav` | 44100/16/1 | 0.350s | 0.350s | -1.50 dBFS | -22.5 dB | — |
| F15 | `yin_xiao_tan_chuang.wav` | 44100/16/1 | 0.500s | 0.500s | -1.50 dBFS | -15.6 dB | — |
| F16 | `yin_xiao_fang_neng_li.wav` | 44100/16/1 | 0.400s | 0.400s | -1.50 dBFS | -13.0 dB | — |
| F17 | `yin_xiao_shi_kong.wav` | 44100/16/1 | 0.700s | 0.700s | -1.50 dBFS | -14.8 dB | — |
| F18 | `yin_xiao_sheng_li.wav` | 44100/16/1 | 2.500s | 2.500s | -1.50 dBFS | -17.1 dB | — |
| F19 | `yin_xiao_shi_bai.wav` | 44100/16/1 | 2.000s | 2.000s | -1.50 dBFS | -14.8 dB | — |
| BGM1 | `bgm_shen_hai.wav` | 44100/16/1 | 51.429s | 51.429s | -6.00 dBFS | -16.9 dB | 0.000000 |
| BGM2 | `bgm_tan_suo.wav` | 44100/16/1 | 40.000s | 40.000s | -1.00 dBFS | -17.7 dB | 0.000000 |
| BGM3 | `bgm_jue_zhan.wav` | 44100/16/1 | 41.143s | 41.143s | -1.00 dBFS | -12.3 dB | 0.000000 |

- 22/22 格式、时长、峰值全部符合规格。
- 4 条循环音频（F11 与三首 BGM）首尾样本均 ≤0.0001，接缝 0.000000；`assets/yinxiao/` 现有 22 个 `.wav` 与 22 个 `.import` 一一对应。

## 三、频谱复核（全曲 FFT 功率占比，DC 除外）

| 曲目 | ≤200Hz | ≥4kHz | 说明 |
|---|---:|---:|---|
| `bgm_shen_hai` | 73.9% | 0.0% | 主界面氛围，几乎无高频 |
| `bgm_tan_suo` | 59.8% | 0.8% | 局内探索，保留少量镲片/铃音 |
| `bgm_jue_zhan` | 91.2% | 0.4% | 决战曲以低频持续为主，高频只剩鼓组边沿 |

说明：以上为当前最终文件用「全曲 FFT 功率谱占比」实测。换频带边界（例如 ≤250Hz）会得到不同数字，报告中统一采用 ≤200Hz / ≥4kHz 口径，避免混用。

## 四、接线与测试契约静态检查

| 检查 | 结果 |
|---|---|
| `YIN_XIAO_BIAO` 键数 | 19 键，键名未改 |
| 7 个旧键 preload | 全部指向 `assets/yinxiao/yin_xiao_*.wav` |
| `BGM_QU_MU` | 仍 `shen_hai` / `tan_suo` / `jue_zhan` 三首 |
| `tests/ce_panding.gd` | 未改；19 键与 3 BGM 硬断言未变，未新增断言 |
| `assets/yinxiao` | 22 条 wav、22 个 `.import`；11 条旧 wav 及 `.import` 已删除 |

## 五、资源导入

由协调者统一运行 headless `--import`：**0 ERROR**，22 个 `.import` 齐全。本路未重复执行导入，避免与并行任务争用 `.godot` 缓存。

## 六、八步门禁与范围检查

主会话在最终工作区（含 TASK-028/029 测试补齐）执行 `tests/pao_pi.bat`，退出码 0，输出「全绿：可以交付」：

| 步骤 | 脚本 / 内容 | 结果 |
|---|---|---|
| 1/8 | `--import` 资源导入 | 0 ERROR，22 个 wav 对应 22 个 `.import` |
| 2/8 | `ce_zhang_ben` | 232 passed, 0 failed |
| 3/8 | `ce_bian_jie` | 25 passed, 0 failed |
| 4/8 | `ce_shu_ju` | 1422 passed, 0 failed |
| 5/8 | `ce_yao_gan` | 8 passed, 0 failed |
| 6/8 | `ce_zhan_dou` | 20 passed, 0 failed |
| 7/8 | `ce_jie_suo` | 144 passed, 0 failed |
| 8/8 | `ce_panding`（场景模式） | 1422 passed, 0 failed |

- 八步合计 **3273** 条断言（232+25+1422+8+20+144+1422）；`ce_panding` 比 TASK-026 的 1313 净增 109 条，来自 TASK-028 静态/运行时演出断言与 TASK-029 布局/攻击键断言。
- `validate_task.py`：`VALID: TASK-027 v1 (plan_driven)`。
- `check_task_scope.py check`：`SCOPE: 117 allowed, 65 unchanged pre-existing, 0 violation(s)`（大量 IGNORE 为并发工作区既有改动：addons/rigs/TASK-026~029 包内文档等；本值为文档收尾后最终复跑）。
- 唯一 WARNING 为测试自身故意传入未知音效名 `mei_you_zhe_ge_yin` 的预期告警，非导入或接线错误。

## 七、待用户 F5 试听

1. 19 条音效逐条辨识度：咬中/吞噬/升级/受伤/死亡/冲刺/电/毒/漩涡/声呐/警报/咀嚼/按钮/吃植物/弹窗/能力/失控/胜利/失败。
2. 7 个旧键调用点（含 24 处 `an_niu`）是否全部正常出声，无静音或错声。
3. 三首 BGM 的循环接缝：局内长时间游玩、机械船降临前后反复切曲是否听得出接缝。
4. 决战曲重点：是否仍有刺耳高频、镲片堆叠或怪异半音走向；低频压迫与干净四拍是否符合预期。
5. 主界面曲比局内曲低 6dB 的既有混音口径是否仍合适。

以上均为无头环境无法替代的听感项；本报告不伪造 F5 结果。
