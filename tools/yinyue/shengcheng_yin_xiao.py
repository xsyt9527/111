# -*- coding: utf-8 -*-
"""
深海食纪 · 19 条 LMMS 音效生成器（LMMS 1.2.2）
依据：TASK-027 任务包；原 12 条来自开发交接_2026-11-08_待实装清单.md 的 F 节（F1~F12），
      TASK-027 全量重制音色/包络，并补齐 7 个旧键对应的 F13~F19。
做法：每条音效写一个 LMMS .mmp 工程（TripleOscillator/Kicker/SFXR/AudioFileProcessor + reverbsc），
     用 LMMS 命令行渲染，再由 Python 做必要的后处理（单声道下混、定长裁剪、去直流、淡入淡出、归一化、循环校验）。
     不在 Python 里从零合成整条音效；LMMS 始终是主体声源。

产物：
  assets/yinxiao/yin_xiao_*.wav   19 条正式音效（44100Hz / 16bit / 单声道）
  tools/yinyue/yin_xiao_*.mmp     对应的 LMMS 工程（正式产物，可复现）
临时：
  tools/yinyue/render/*.wav       LMMS 原始立体声渲染，处理完即删

用法：
  python -I tools/yinyue/shengcheng_yin_xiao.py
"""
import os
import random
import shutil
import subprocess
import sys
import wave

import numpy as np

# ---------------------------------------------------------------- 路径与常量
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
TOOL_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(ROOT, "assets", "yinxiao")
RENDER_DIR = os.path.join(TOOL_DIR, "render")

# 先用 ls/find 实测：D:\LMMS\lmms.exe 存在（LMMS 1.2.2）。保留候选便于换机复现。
LMMS_CANDIDATES = [
    r"D:\LMMS\lmms.exe",
    r"D:\LMMS\lmms.exe",
    r"D:\LMMS\lmms.exe",
    os.path.join(os.environ.get("ProgramFiles", r"C:\Program Files"), "LMMS", "lmms.exe"),
]
LMMS = next((p for p in LMMS_CANDIDATES if os.path.isfile(p)), LMMS_CANDIDATES[0])

BPM = 120                    # 120 BPM 下 1 拍 = 0.5 秒，1 小节 192 ticks = 2 秒
TICKS_PER_BAR = 192
TICKS_PER_SEC = 96.0         # 192 ticks / 2 秒
MASTER_VOL = 28              # 与现有 BGM 工程一致，留足余量防止 LMMS 内部削波
PEAK_DB = -1.5               # 成品峰值目标（要求 -3 ~ -1 dBFS）


def t(sec):
    """秒 → LMMS tick（120 BPM 下 96 ticks/秒）。"""
    return int(round(sec * TICKS_PER_SEC))


# ---------------------------------------------------------------- XML 零件
def _fmt(v):
    if isinstance(v, float):
        return ("%.4f" % v).rstrip("0").rstrip(".")
    return str(v)


def triple(wave0=0, coarse0=0, finel0=0, finer0=0, vol0=100,
           wave1=2, coarse1=0, fine1=0, vol1=0,
           wave2=0, coarse2=0, fine2=0, vol2=0, detune=0):
    """三振荡器：0=正弦 1=三角 2=锯齿 3=方波；coarse 为半音偏移，finel/finer 为音分。
    实测 LMMS 1.2.2：finel 只作用于左声道、finer 只作用于右声道；
    单声道成品若只设 finel，下混后左右两声道会差半个音程形成拍频，必须两者设同一值。"""
    attrs = {
        "vol0": vol0, "wavetype0": wave0, "coarse0": coarse0,
        "finel0": finel0, "finer0": finer0, "pan0": 0,
        "vol1": vol1, "wavetype1": wave1, "coarse1": coarse1,
        "finel1": fine1, "finer1": fine1, "pan1": 0,
        "vol2": vol2, "wavetype2": wave2, "coarse2": coarse2,
        "finel2": fine2, "finer2": fine2, "pan2": 0,
        "modalgo1": 0, "modalgo2": 0, "modalgo3": 0,
        "stphdetun0": detune, "stphdetun1": 0, "stphdetun2": 0,
        "phoffset0": 0, "phoffset1": 90, "phoffset2": 180,
        "userwavefile0": "", "userwavefile1": "", "userwavefile2": "",
    }
    inner = " ".join('%s="%s"' % (k, _fmt(v)) for k, v in attrs.items())
    return ('<instrument name="tripleoscillator"><tripleoscillator %s/>'
            '</instrument>' % inner)


def kicker(startfreq=150, endfreq=40, decay=440, noise=0.0,
           click=0.4, dist=0.8, slope=0.06):
    """Kicker 鼓合成器。decay 单位毫秒；实测 startfreq/endfreq 主要决定音色重心，
    不会像参数名暗示的那样拉出长滑音，所以滑音统一用密集音符序列做。"""
    attrs = {
        "decay_syncmode": 0, "startnote": 1, "version": 1,
        "endfreq": endfreq, "env": 0.163, "noise": noise,
        "decay_denominator": 4, "dist": dist, "endnote": 0,
        "decay_numerator": 4, "distend": dist, "gain": 1,
        "slope": slope, "decay": decay, "startfreq": startfreq, "click": click,
    }
    inner = " ".join('%s="%s"' % (k, _fmt(v)) for k, v in attrs.items())
    return '<instrument name="kicker"><kicker %s/></instrument>' % inner


def sfxr(wave=3, attack=0.005, sustain=0.2, decay=0.12, punch=0.0,
         startfreq=0.5, minfreq=0.0, lp_cut=1.0, lp_sweep=0.0, lp_res=0.0,
         hp_cut=0.0, hp_sweep=0.0, duty=0.5, duty_sweep=0.0):
    """SFXR 芯片音源：0=正弦 1=方波 2=锯齿 3=白噪声。
    实测音高由音符 key 决定（key 每 +12 频率翻倍）；minfreq 不会产生可听滑音，故只用来定音色。"""
    attrs = {
        "attack": attack, "sustain": sustain, "punch": punch, "decay": decay,
        "startFreq": startfreq, "minFreq": minfreq,
        "lpFilCut": lp_cut, "lpFilCutSweep": lp_sweep, "lpFilReso": lp_res,
        "hpFilCut": hp_cut, "hpFilCutSweep": hp_sweep,
        "waveForm": wave, "sqrDuty": duty, "sqrSweep": duty_sweep,
        "phaserOffset": 0, "phaserSweep": 0,
    }
    inner = " ".join('%s="%s"' % (k, _fmt(v)) for k, v in attrs.items())
    return '<instrument name="sfxr"><sfxr %s/></instrument>' % inner


def afp(src, reversed_=0):
    """AudioFileProcessor：播 LMMS 内置采样；reversed_=1 倒放（用于反向吸聚/撕裂）。"""
    return ('<instrument name="audiofileprocessor"><audiofileprocessor '
            'stutter="0" interp="1" reversed="%d" looped="0" sframe="0" lframe="0" '
            'src="%s" eframe="0.9999" amp="100"/></instrument>' % (reversed_, src))


def eldata(att=0.0, dec=0.0, sustain=1.0, rel=0.1, amt=0.0, fcut=14000):
    """音量包络。amt=0 关闭包络（让 Kicker/采样自己的自然包络生效）；
    amt=1 启用 att/dec/sustain/rel（秒）。
    注：实测 elcut 的 fcut/ftype 对声音影响很小，音色选择靠波形/采样本身。"""
    def env(tag):
        return ('<%s amt="%s" att="%s" dec="%s" sustain="%s" rel="%s" hold="0" '
                'ctlenvamt="0" lspd="0.1" lspd_denominator="4" lspd_numerator="4" '
                'lshp="0" lamt="0" latt="0" pdel="0" lpdel="0" syncmode="0" '
                'userwavefile="" x100="0"/>'
                % (tag, _fmt(amt), _fmt(att), _fmt(dec), _fmt(sustain), _fmt(rel)))
    return ('<eldata fwet="0" ftype="0" fcut="%s" fres="0.5">%s%s%s</eldata>'
            % (_fmt(fcut), env("elvol"), env("elcut"), env("elres")))


def reverb(wet=0.85, size=0.8, color=0.6):
    """ReverbSC 效果链。size/color 不要拉满（实测 1.0/1.0 会让 LMMS 渲染卡死）。"""
    return ('<fxchain numofeffects="1" enabled="1">'
            '<effect name="reverbsc" on="1" wet="%s">'
            '<reverbsc input_gain="1" size="%s" color="%s" output_gain="1"/>'
            '</effect></fxchain>' % (_fmt(wet), _fmt(size), _fmt(color)))


def track(name, instrument, env, notes, vol=100, pan=0, fx=None,
          pattern_len=TICKS_PER_BAR):
    """一条乐器轨 + 铺满 2 秒的 pattern。notes 为 (pos_tick, len_tick, key, vol)。"""
    note_xml = "\n".join(
        '          <note key="%d" vol="%d" pos="%d" pan="%d" len="%d"/>'
        % (key, v, pos, 0, ln) for (pos, ln, key, v) in notes)
    fx_xml = fx or '<fxchain numofeffects="0" enabled="0"/>'
    return f"""      <track type="0" muted="0" name="{name}" solo="0">
        <instrumenttrack pitch="0" vol="{vol}" fxch="0" pan="{pan}" basenote="57" usemasterpitch="1" pitchrange="1">
          {instrument}
          {env}
          <chordcreator chord="0" chordrange="1" chord-enabled="0"/>
          <arpeggiator arp="0" arptime_numerator="1" arptime_denominator="1" arprange="1" arpmode="0" arptime="100" arpdir="0" arpgate="100" syncmode="0" arp-enabled="0"/>
          <midiport outputchannel="1" outputcontroller="0" basevelocity="127" outputprogram="1" fixedinputvelocity="-1" fixedoutputvelocity="-1" fixedoutputnote="-1" inputchannel="0" inputcontroller="0" readable="0" writable="-1"/>
          {fx_xml}
        </instrumenttrack>
        <pattern type="1" muted="0" steps="16" name="{name}" pos="0" len="{pattern_len}">
{note_xml}
        </pattern>
      </track>"""


def song(tracks):
    body = "\n".join(tracks)
    return f"""<?xml version="1.0"?>
<!DOCTYPE lmms-project>
<lmms-project type="song" version="1.0" creator="LMMS" creatorversion="1.2.0">
  <head timesig_numerator="4" timesig_denominator="4" bpm="{BPM}" mastervol="{MASTER_VOL}" masterpitch="0"/>
  <song>
    <trackcontainer type="song" visible="1" width="900" height="600" x="0" y="0" maximized="0" minimized="0">
{body}
    </trackcontainer>
    <fxmixer visible="1" width="647" height="332" x="0" y="0" maximized="0" minimized="0">
      <fxchannel num="0" muted="0" volume="1" name="Master" soloed="0">
        <fxchain numofeffects="0" enabled="0"/>
      </fxchannel>
    </fxmixer>
  </song>
</lmms-project>
"""


# ---------------------------------------------------------------- 记谱工具
def nt(pos_sec, len_sec, key, vol=100):
    """单音符：秒 → tick 的便捷写法。"""
    return (t(pos_sec), max(1, t(len_sec)), int(key), int(vol))


def gliss(pos_sec, dur_sec, key0, key1, step_tick=2, note_len_tick=3,
          curve=1.0, vol=100):
    """密集音符滑音：每 step_tick 打一个短音符，音高从 key0 线性/指数过渡到 key1。
    实测 2 tick 间隔 + 3 tick 长度能让相邻音重叠，听感是连续滑音而不是一串台阶。"""
    start = t(pos_sec)
    n = max(2, int(round(dur_sec * TICKS_PER_SEC / step_tick)) + 1)
    notes = []
    for i in range(n):
        u = i / (n - 1)
        key = int(round(key0 + (key1 - key0) * (u ** curve)))
        notes.append((start + i * step_tick, note_len_tick, key, vol))
    return notes


# ---------------------------------------------------------------- F1~F19 声音设计
# 2026-11-15 全量重制：用户反馈原音效/音乐「怪怪的」，主因是高频锯齿、镲片堆叠、
# 半音堆砌与 SFXR 白噪过亮。新版统一改成「正弦/三角为主 + 低通噪声点缀」，
# 保留每条音效的语义与原时长，峰值仍由 postprocess/validate 统一管到 -1.5 dBFS。


def qu_yao_ji():
    """F1 每次咬中：低频 thump + 柔软咬合脉冲，短促不刺耳。"""
    return [
        track("咬合软脉冲", afp("drums/snare_short01.ogg"),
              eldata(amt=1.0, att=0.002, dec=0.04, sustain=0.0, rel=0.02),
              [nt(0.0, 0.03, 57, 70)], vol=65),
        track("低频 thump", kicker(startfreq=160, endfreq=45, decay=160,
                                  noise=0.02, click=0.15, dist=0.6),
              eldata(amt=0.0), [nt(0.0, 0.22, 57, 100)], vol=100),
        track("啵", triple(wave0=0, vol0=100, wave1=1, coarse1=12, vol1=10),
              eldata(amt=1.0, att=0.002, dec=0.06, sustain=0.0, rel=0.02),
              [nt(0.0, 0.05, 45, 100)], vol=45),
    ], 0.3, dict(fade_in=0.002, fade_out=0.025)


def qu_tun_xia():
    """F2 吞噬成功：正弦上滑 + 低频咕咚，圆润满足。"""
    return [
        track("上滑", triple(wave0=0, vol0=100, wave1=1, coarse1=12, vol1=14),
              eldata(amt=1.0, att=0.006, dec=0.08, sustain=0.8, rel=0.03),
              gliss(0.0, 0.42, 45, 64, step_tick=2, note_len_tick=3), vol=80),
        track("咕咚", kicker(startfreq=120, endfreq=45, decay=300,
                             noise=0.03, click=0.2, dist=0.6),
              eldata(amt=0.0), [nt(0.42, 0.32, 57, 100)], vol=95),
        track("低频垫", triple(wave0=0, vol0=100),
              eldata(amt=1.0, att=0.01, dec=0.35, sustain=0.0, rel=0.05),
              [nt(0.42, 0.30, 33, 100)], vol=45),
    ], 0.8, dict(fade_in=0.003, fade_out=0.04)


def qu_sheng_ji():
    """F3 升级三选一弹出：三角琶音铃 C-E-G-C，明亮但不尖。"""
    notes = [nt(0.000, 0.55, 60, 100),
             nt(0.160, 0.55, 64, 100),
             nt(0.320, 0.55, 67, 100),
             nt(0.480, 0.62, 72, 100)]
    return [
        track("大调琶音铃", triple(wave0=1, vol0=100,
                                wave1=0, coarse1=0, vol1=24,
                                wave2=1, coarse2=12, vol2=10),
              eldata(amt=1.0, att=0.004, dec=0.42, sustain=0.02, rel=0.30),
              notes, vol=82),
    ], 1.2, dict(fade_in=0.003, fade_out=0.06)


def qu_shou_shang():
    """F4 玩家被咬掉肉：柔和撕裂 + 三角下滑，痛感但不刺耳。"""
    return [
        track("撕裂", afp("effects/scratch01.ogg"),
              eldata(amt=1.0, att=0.001, dec=0.14, sustain=0.0, rel=0.06),
              [nt(0.0, 0.16, 57, 100)], vol=72),
        track("下滑", triple(wave0=1, vol0=100, wave1=0, coarse1=-12, vol1=18),
              eldata(amt=1.0, att=0.006, dec=0.10, sustain=0.6, rel=0.04),
              gliss(0.02, 0.32, 72, 45, step_tick=2, note_len_tick=3), vol=72),
        track("闷响", kicker(startfreq=140, endfreq=45, decay=180,
                             noise=0.02, click=0.15, dist=0.6),
              eldata(amt=0.0), [nt(0.02, 0.20, 57, 100)], vol=85),
    ], 0.6, dict(fade_in=0.002, fade_out=0.03)


def qu_si_wang():
    """F5 玩家死亡：正弦下潜 → 静默半秒 → 单音混响，留白。"""
    return [
        track("下潜", triple(wave0=0, vol0=100, wave1=1, vol1=10),
              eldata(amt=1.0, att=0.01, dec=0.30, sustain=0.7, rel=0.05),
              gliss(0.0, 0.80, 45, 26, step_tick=2, note_len_tick=3), vol=75),
        track("下潜重击", kicker(startfreq=190, endfreq=40, decay=480,
                                noise=0.02, click=0.2, dist=0.65),
              eldata(amt=0.0), [nt(0.0, 0.50, 57, 100)], vol=88),
        track("收尾闷响", kicker(startfreq=90, endfreq=35, decay=220,
                                noise=0.01, click=0.1, dist=0.65),
              eldata(amt=0.0), [nt(0.68, 0.26, 57, 90)], vol=82),
        track("死亡回声", triple(wave0=0, vol0=100),
              eldata(amt=1.0, att=0.002, dec=0.25, sustain=0.0, rel=0.12),
              [nt(1.42, 0.10, 45, 100)], vol=80,
              fx=reverb(wet=0.78, size=0.80, color=0.60)),
    ], 2.0, dict(fade_in=0.003, fade_out=0.05)


def qu_chong_ci():
    """F6 鱼雷冲刺：低通噪声 whoosh + 正弦下滑，去掉高通尖叫。"""
    return [
        track("whoosh 主体", afp("effects/filter_sweep01.ogg"),
              eldata(amt=1.0, att=0.04, dec=0.0, sustain=1.0, rel=0.10),
              [nt(0.0, 0.42, 57, 100)], vol=75),
        track("下滑", triple(wave0=0, vol0=100, wave1=1, vol1=20),
              eldata(amt=1.0, att=0.02, dec=0.15, sustain=0.35, rel=0.04),
              gliss(0.0, 0.40, 69, 50, step_tick=2, note_len_tick=8), vol=52),
    ], 0.5, dict(fade_in=0.02, fade_out=0.06)


def qu_dian_xi():
    """F7 电系技能：正弦/三角颗粒 + 柔和扫频，不用锯齿。"""
    rng = random.Random(77)
    grains = []
    for i in range(12):
        pos = 0.02 + i * 0.052 + rng.uniform(-0.010, 0.010)
        key = rng.randint(55, 72)
        wave = 1 if i % 2 == 0 else 0
        vol = rng.randint(40, 70)
        grains.append((nt(max(0.0, pos), 0.025, key, vol), wave))
    grain_tracks = []
    for wave in (0, 1):
        notes = [g[0] for g in grains if g[1] == wave]
        grain_tracks.append(
            track("电颗粒%d" % wave,
                  triple(wave0=wave, vol0=100, wave1=0, vol1=12),
                  eldata(amt=1.0, att=0.002, dec=0.05, sustain=0.0, rel=0.02),
                  sorted(notes), vol=58))
    return [
        track("柔和扫频", triple(wave0=0, vol0=100, wave1=1, coarse1=12, vol1=18),
              eldata(amt=1.0, att=0.004, dec=0.10, sustain=0.6, rel=0.03),
              gliss(0.0, 0.46, 72, 48, step_tick=2, note_len_tick=3), vol=55),
        track("电刺1", afp("drums/zap01.ogg"),
              eldata(amt=1.0, att=0.001, dec=0.04, sustain=0.0, rel=0.02),
              [nt(0.00, 0.04, 57, 60)], vol=40),
        track("电刺2", afp("drums/zap03.ogg"),
              eldata(amt=1.0, att=0.001, dec=0.04, sustain=0.0, rel=0.02),
              [nt(0.26, 0.04, 57, 55)], vol=38),
    ] + grain_tracks, 0.8, dict(fade_in=0.002, fade_out=0.03)


def qu_du_xi():
    """F8 毒系触发：正弦气泡串 + 低沉破裂，黏腻但不吵。"""
    rng = random.Random(311)
    bubble_notes = []
    for i in range(10):
        pos = 0.02 + i * 0.068 + rng.uniform(-0.008, 0.008)
        key = 45 + i * 2 + rng.randint(0, 1)
        bubble_notes.append(nt(max(0.0, pos), 0.035, key, 90 + rng.randint(0, 10)))
    return [
        track("气泡串", triple(wave0=0, vol0=100, wave1=1, coarse1=12, vol1=8),
              eldata(amt=1.0, att=0.004, dec=0.10, sustain=0.0, rel=0.05),
              bubble_notes, vol=82),
        track("破裂", kicker(startfreq=240, endfreq=70, decay=120,
                             noise=0.12, click=0.25, dist=0.6),
              eldata(amt=0.0), [nt(0.78, 0.14, 57, 100)], vol=62),
        track("黏腻低频", triple(wave0=0, vol0=100),
              eldata(amt=1.0, att=0.02, dec=0.5, sustain=0.15, rel=0.10),
              [nt(0.02, 0.60, 33, 100)], vol=35),
    ], 1.0, dict(fade_in=0.003, fade_out=0.04)


def qu_xuan_wo():
    """F9 漩涡释放：反向噪声 + 正弦上旋，吸聚感柔和。"""
    return [
        track("反向噪声", afp("drums/crash01.ogg", reversed_=1),
              eldata(amt=0.0), [nt(0.0, 0.95, 57, 100)], vol=52),
        track("上旋", triple(wave0=0, vol0=100, wave1=1, vol1=12),
              eldata(amt=1.0, att=0.01, dec=0.25, sustain=0.5, rel=0.08),
              gliss(0.08, 1.20, 33, 69, step_tick=2, note_len_tick=4,
                    curve=1.35), vol=48),
        track("反向 whoosh", afp("effects/warp02.ogg", reversed_=1),
              eldata(amt=1.0, att=0.05, dec=0.0, sustain=1.0, rel=0.20),
              [nt(0.0, 1.20, 55, 100)], vol=55),
    ], 1.5, dict(fade_in=0.01, fade_out=0.12)


def qu_sheng_na():
    """F10 声呐脉冲：正弦 ping（key 67 ≈ 784Hz）+ 长衰减混响。"""
    return [
        track("声呐", triple(wave0=0, finel0=35, finer0=35, vol0=100),
              eldata(amt=1.0, att=0.002, dec=0.15, sustain=0.0, rel=0.06),
              [nt(0.0, 0.08, 67, 100)], vol=90,
              fx=reverb(wet=0.85, size=0.80, color=0.60)),
    ], 1.0, dict(fade_in=0.002, fade_out=0.03)


def qu_jing_bao():
    """F11 机械船入场预告：三角双音 A4/E5（纯五度）交替，干净警报；2 秒循环。"""
    tones = [nt(0.0, 0.46, 57, 100), nt(0.5, 0.46, 64, 100),
             nt(1.0, 0.46, 57, 100), nt(1.5, 0.46, 64, 100)]
    metal = [nt(0.0, 0.02, 57, 45), nt(0.5, 0.02, 64, 45),
             nt(1.0, 0.02, 57, 45), nt(1.5, 0.02, 64, 45)]
    return [
        track("警报双音", triple(wave0=1, vol0=100,
                                wave1=0, coarse1=12, vol1=12),
              eldata(amt=1.0, att=0.004, dec=0.05, sustain=0.72, rel=0.02),
              tones, vol=80),
        track("金属敲击", afp("misc/metalish_dong01.ogg"),
              eldata(amt=1.0, att=0.001, dec=0.06, sustain=0.0, rel=0.03),
              metal, vol=24),
    ], 2.0, dict(fade_in=0.004, fade_out=0.004, loop=True)


def qu_jiao_zhi():
    """F12 吃鱼肉块：两下短咀嚼，音高随机 ±6%。"""
    rng = random.Random(20261108)
    k1 = rng.choice([56, 57, 58])
    k2 = rng.choice([k for k in (56, 57, 58) if k != k1])
    return [
        track("咀嚼噪声", afp("drums/snare_short01.ogg"),
              eldata(amt=1.0, att=0.001, dec=0.04, sustain=0.0, rel=0.02),
              [nt(0.0, 0.03, k1, 85), nt(0.198, 0.03, k2, 85)], vol=82),
        track("咀嚼闷响", afp("drums/tom_hi01.ogg"),
              eldata(amt=1.0, att=0.002, dec=0.10, sustain=0.0, rel=0.05),
              [nt(0.0, 0.06, k1, 100), nt(0.198, 0.06, k2, 100)], vol=62),
    ], 0.4, dict(fade_in=0.002, fade_out=0.025, note_pitch=(k1, k2))


# ---------------------------------------------------------------- 旧键补齐（F13~F19）
def qu_an_niu():
    """F13 按钮点击：短正弦 blip，圆润干脆。"""
    return [
        track("按钮 blip", triple(wave0=0, vol0=100, wave1=1, coarse1=12, vol1=16),
              eldata(amt=1.0, att=0.001, dec=0.04, sustain=0.0, rel=0.02),
              [nt(0.0, 0.06, 64, 100)], vol=80),
        track("低八度", triple(wave0=0, vol0=100),
              eldata(amt=1.0, att=0.002, dec=0.05, sustain=0.0, rel=0.02),
              [nt(0.0, 0.05, 52, 100)], vol=28),
    ], 0.12, dict(fade_in=0.001, fade_out=0.012)


def qu_chi():
    """F14 吃植物：柔和两下咀嚼 + 短低音，与鱼肉块区分更轻。"""
    return [
        track("植物咀嚼", afp("drums/tom_hi01.ogg"),
              eldata(amt=1.0, att=0.003, dec=0.08, sustain=0.0, rel=0.04),
              [nt(0.0, 0.06, 57, 100), nt(0.16, 0.06, 57, 80)], vol=58),
        track("植物低音", triple(wave0=0, vol0=100, wave1=1, vol1=10),
              eldata(amt=1.0, att=0.004, dec=0.10, sustain=0.0, rel=0.04),
              [nt(0.0, 0.10, 45, 100)], vol=35),
    ], 0.35, dict(fade_in=0.002, fade_out=0.025)


def qu_tan_chuang():
    """F15 升级弹窗弹出：两声上行三角铃，轻柔提示。"""
    return [
        track("弹窗铃", triple(wave0=1, vol0=100, wave1=0, vol1=20),
              eldata(amt=1.0, att=0.003, dec=0.30, sustain=0.02, rel=0.18),
              [nt(0.0, 0.30, 64, 95), nt(0.12, 0.30, 67, 100)], vol=75),
    ], 0.5, dict(fade_in=0.002, fade_out=0.04)


def qu_fang_neng_li():
    """F16 主动能力释放（通用兜底）：干净的上行扫频。"""
    return [
        track("上行扫频", triple(wave0=0, vol0=100, wave1=1, coarse1=12, vol1=16),
              eldata(amt=1.0, att=0.004, dec=0.10, sustain=0.55, rel=0.04),
              gliss(0.0, 0.26, 55, 67, step_tick=2, note_len_tick=3), vol=70),
        track("气口", afp("effects/filter_sweep01.ogg"),
              eldata(amt=1.0, att=0.02, dec=0.10, sustain=0.0, rel=0.05),
              [nt(0.0, 0.10, 57, 60)], vol=14),
    ], 0.4, dict(fade_in=0.002, fade_out=0.03)


def qu_shi_kong():
    """F17 失控兜底（来源未知）：三角下滑 + 低频晃动，不安但不刺耳。"""
    return [
        track("下滑", triple(wave0=1, vol0=100, wave1=0, vol1=14),
              eldata(amt=1.0, att=0.008, dec=0.18, sustain=0.5, rel=0.05),
              gliss(0.0, 0.42, 60, 40, step_tick=2, note_len_tick=3), vol=65),
        track("低频晃动", triple(wave0=0, vol0=100),
              eldata(amt=1.0, att=0.01, dec=0.30, sustain=0.25, rel=0.08),
              [nt(0.0, 0.22, 33, 100), nt(0.24, 0.22, 36, 80)], vol=40),
        track("闷噪", afp("drums/tom_hi01.ogg"),
              eldata(amt=1.0, att=0.005, dec=0.12, sustain=0.0, rel=0.05),
              [nt(0.0, 0.10, 57, 70)], vol=22),
    ], 0.7, dict(fade_in=0.003, fade_out=0.05)


def qu_sheng_li():
    """F18 胜利结算：上行大调琶音 + 混响长尾，明亮收束。"""
    return [
        track("胜利琶音", triple(wave0=1, vol0=100, wave1=0, vol1=22,
                            wave2=1, coarse2=12, vol2=8),
              eldata(amt=1.0, att=0.004, dec=0.45, sustain=0.04, rel=0.5),
              [nt(0.00, 0.50, 60, 100), nt(0.18, 0.50, 64, 100),
               nt(0.36, 0.50, 67, 100), nt(0.54, 0.55, 72, 100),
               nt(0.72, 0.80, 76, 100)], vol=78,
              fx=reverb(wet=0.70, size=0.80, color=0.55), pattern_len=240),
        track("低音收束", triple(wave0=0, vol0=100),
              eldata(amt=1.0, att=0.01, dec=0.60, sustain=0.30, rel=0.5),
              [nt(0.54, 0.60, 48, 100)], vol=30, pattern_len=240),
    ], 2.5, dict(fade_in=0.003, fade_out=0.20)


def qu_shi_bai():
    """F19 失败结算：下行小调琶音 + 低频垫，低沉但不惊悚。"""
    return [
        track("失败琶音", triple(wave0=1, vol0=100, wave1=0, vol1=18),
              eldata(amt=1.0, att=0.006, dec=0.40, sustain=0.05, rel=0.4),
              [nt(0.00, 0.45, 57, 100), nt(0.22, 0.45, 53, 100),
               nt(0.44, 0.45, 50, 100), nt(0.66, 0.55, 45, 100)], vol=72,
              fx=reverb(wet=0.75, size=0.80, color=0.60)),
        track("低频垫", triple(wave0=0, vol0=100),
              eldata(amt=1.0, att=0.02, dec=0.80, sustain=0.20, rel=0.5),
              [nt(0.0, 0.90, 33, 100)], vol=34),
    ], 2.0, dict(fade_in=0.003, fade_out=0.15)


JOBS = [
    ("yin_xiao_yao_ji", qu_yao_ji),
    ("yin_xiao_tun_xia", qu_tun_xia),
    ("yin_xiao_sheng_ji", qu_sheng_ji),
    ("yin_xiao_shou_shang", qu_shou_shang),
    ("yin_xiao_si_wang", qu_si_wang),
    ("yin_xiao_chong_ci", qu_chong_ci),
    ("yin_xiao_dian_xi", qu_dian_xi),
    ("yin_xiao_du_xi", qu_du_xi),
    ("yin_xiao_xuan_wo", qu_xuan_wo),
    ("yin_xiao_sheng_na", qu_sheng_na),
    ("yin_xiao_jing_bao", qu_jing_bao),
    ("yin_xiao_jiao_zhi", qu_jiao_zhi),
    ("yin_xiao_an_niu", qu_an_niu),
    ("yin_xiao_chi", qu_chi),
    ("yin_xiao_tan_chuang", qu_tan_chuang),
    ("yin_xiao_fang_neng_li", qu_fang_neng_li),
    ("yin_xiao_shi_kong", qu_shi_kong),
    ("yin_xiao_sheng_li", qu_sheng_li),
    ("yin_xiao_shi_bai", qu_shi_bai),
]


# ---------------------------------------------------------------- 渲染与后处理
def render_mmp(name, tracks):
    """写 .mmp 并调用 LMMS 渲染 44.1kHz WAV。"""
    mmp = os.path.join(TOOL_DIR, name + ".mmp")
    raw = os.path.join(RENDER_DIR, name + ".wav")
    os.makedirs(RENDER_DIR, exist_ok=True)
    with open(mmp, "w", encoding="utf-8") as f:
        f.write(song(tracks))
    cmd = [LMMS, "render", mmp, "-f", "wav", "-o", raw,
           "-s", "44100", "-x", "2"]
    print("[LMMS] %s" % name)
    try:
        r = subprocess.run(cmd, capture_output=True, text=True,
                           encoding="utf-8", errors="replace", timeout=120)
    except subprocess.TimeoutExpired:
        raise SystemExit("LMMS 渲染超时：%s" % name)
    if r.returncode != 0 or not os.path.isfile(raw):
        print((r.stdout or "")[-1500:])
        print((r.stderr or "")[-1500:])
        raise SystemExit("LMMS 渲染失败：%s" % name)
    return raw, cmd


def read_mono(path):
    """读 WAV，立体声按通道平均下混为单声道 float64。"""
    with wave.open(path, "rb") as w:
        sr = w.getframerate()
        ch = w.getnchannels()
        sw = w.getsampwidth()
        n = w.getnframes()
        data = w.readframes(n)
    assert sw == 2, "LMMS 渲染必须是 16bit"
    x = np.frombuffer(data, dtype="<i2").astype(np.float64)
    x = x.reshape(-1, ch).mean(axis=1) / 32768.0
    return x, sr


def smooth_fade(x, sr, fade_in, fade_out):
    """升余弦淡入淡出，避免硬切爆音。"""
    fi = min(len(x), int(round(fade_in * sr)))
    fo = min(len(x), int(round(fade_out * sr)))
    if fi > 1:
        w = 0.5 - 0.5 * np.cos(np.linspace(0.0, np.pi, fi))
        x[:fi] *= w
    if fo > 1:
        w = 0.5 + 0.5 * np.cos(np.linspace(0.0, np.pi, fo))
        x[-fo:] *= w
    return x


def dc_block(x, sr, cutoff=10.0):
    """一阶高通去直流（截止 10Hz）：压掉 LMMS 低频音源留下的恒定偏置和超低频漂移，
    对 40Hz 以上的 thump/滑音影响可忽略（10Hz 处仅 -3dB，80Hz 处约 -0.07dB）。"""
    r = 1.0 - 2.0 * np.pi * cutoff / sr
    y = np.empty_like(x)
    px = 0.0
    py = 0.0
    for i, v in enumerate(x):
        py = float(v) - px + r * py
        y[i] = py
        px = float(v)
    return y


def normalize(x, peak_db=PEAK_DB):
    """去直流 + 峰值归一化到指定 dBFS。"""
    x = x - float(np.mean(x))
    peak = float(np.max(np.abs(x))) or 1.0
    x = x * (10 ** (peak_db / 20.0) / peak)
    return x


def postprocess(raw, dst, target_sec, fade_in, fade_out, loop=False):
    """裁剪到目标长度、去直流、淡入淡出、归一化，写单声道 16bit WAV。"""
    x, sr = read_mono(raw)
    n = int(round(target_sec * sr))
    if len(x) < n:
        x = np.pad(x, (0, n - len(x)))
    x = x[:n].copy()
    # F5 的“静默半秒”里 LMMS 会残留约 -30dBFS 的直流偏置，先高通压掉再归一化。
    x = dc_block(x, sr, cutoff=10.0)
    if loop:
        # 循环类同样裁到循环长度；尾音已设计在循环点前收干，不再折回，避免叠音。
        pass
    x = smooth_fade(x, sr, fade_in, fade_out)
    x = normalize(x)
    out = np.clip(np.rint(x * 32767.0), -32768, 32767).astype("<i2")
    with wave.open(dst, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(out.tobytes())
    return x, sr


def dbfs(v):
    return 20.0 * np.log10(max(1e-12, float(v)))


def validate(path, expected_sec, loop=False):
    """用 wave 模块复核格式、时长、峰值；循环类额外检查首尾跳变。"""
    with wave.open(path, "rb") as w:
        sr = w.getframerate()
        ch = w.getnchannels()
        sw = w.getsampwidth()
        n = w.getnframes()
        data = w.readframes(n)
    x = np.frombuffer(data, dtype="<i2").astype(np.float64) / 32768.0
    dur = n / sr
    peak = float(np.max(np.abs(x))) if len(x) else 0.0
    rms = float(np.sqrt(np.mean(x ** 2))) if len(x) else 0.0
    ok_fmt = (sr == 44100 and ch == 1 and sw == 2)
    ok_dur = abs(dur - expected_sec) <= 0.002
    ok_peak = peak < 1.0 and -3.0 <= dbfs(peak) <= -1.0
    ok_loop = True
    print("  校验 %-26s %s  %dHz/%dbit/%dch  %.3fs  峰值 %.2f dBFS  RMS %.1f dB  %s"
          % (os.path.basename(path), "OK" if (ok_fmt and ok_dur and ok_peak) else "FAIL",
             sr, sw * 8, ch, dur, dbfs(peak), dbfs(rms),
             "格式/时长/峰值" if (ok_fmt and ok_dur) else "格式或时长异常"))
    print("    首样本 %.1f  末样本 %.1f  首尾差 %.1f" %
          (x[0], x[-1], abs(x[0] - x[-1])))
    if loop:
        # 循环接缝只看首尾样本差与两端的电平；不要用文件内部相邻跳变作阈值
        # （F11 是方波，陡边本身就有接近满幅的正常跳变）。
        edge = int(0.02 * sr)
        seam = abs(float(x[0]) - float(x[-1]))
        head_rms = float(np.sqrt(np.mean(x[:edge] ** 2)))
        tail_rms = float(np.sqrt(np.mean(x[-edge:] ** 2)))
        ok_loop = seam <= 0.005 and abs(float(x[0])) <= 0.001 and abs(float(x[-1])) <= 0.001
        print("    循环接缝: 首尾差 %.5f（满幅=1.0）  首20ms RMS %.1f dB  末20ms RMS %.1f dB  %s"
              % (seam, dbfs(head_rms), dbfs(tail_rms),
                 "无缝" if ok_loop else "有跳变"))
    if not (ok_fmt and ok_dur and ok_peak and ok_loop):
        raise SystemExit("校验未通过：%s" % os.path.basename(path))
    return dict(sr=sr, ch=ch, sw=sw, dur=dur, peak_db=dbfs(peak),
                rms_db=dbfs(rms), size=os.path.getsize(path))


def main():
    if not os.path.isfile(LMMS):
        raise SystemExit("找不到 LMMS 可执行文件：%s" % LMMS)
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(RENDER_DIR, exist_ok=True)
    print("LMMS: %s" % LMMS)
    print("产物目录: %s" % OUT_DIR)
    results = []
    for name, builder in JOBS:
        tracks, target_sec, opts = builder()
        raw, cmd = render_mmp(name, tracks)
        dst = os.path.join(OUT_DIR, name + ".wav")
        x, sr = postprocess(raw, dst, target_sec, opts.get("fade_in", 0.003),
                            opts.get("fade_out", 0.03), loop=opts.get("loop", False))
        os.remove(raw)
        # 附加检查：F5 静默半秒电平、F10 基频应为 800Hz、F11 四个 0.5s 窗口交替 440/466Hz。
        if name == "yin_xiao_si_wang":
            seg = x[int(0.95 * sr):int(1.35 * sr)]
            silence_db = dbfs(float(np.sqrt(np.mean(seg ** 2))))
            print("  死亡静默段 0.95-1.35s RMS: %.1f dBFS（目标 ≤ -60）" % silence_db)
            if silence_db > -60.0:
                raise SystemExit("F5 静默段电平过高：%.1f dBFS" % silence_db)
        if name == "yin_xiao_sheng_na":
            # 0.01~0.30s 覆盖 ping 本体与混响前段；取 0.3s 窗口才能分辨 800Hz。
            seg = x[int(0.01 * sr):int(0.30 * sr)]
            sp = np.abs(np.fft.rfft(seg * np.hanning(len(seg))))
            f = np.fft.rfftfreq(len(seg), 1.0 / sr)
            m = (f >= 300) & (f <= 1500)
            print("  声呐基频峰值: %.1f Hz（目标 800Hz）" % f[m][np.argmax(sp[m])])
        if name == "yin_xiao_jing_bao":
            peaks = []
            for i in range(4):
                seg = x[i * sr // 2:(i + 1) * sr // 2]
                sp = np.abs(np.fft.rfft(seg * np.hanning(len(seg))))
                f = np.fft.rfftfreq(len(seg), 1.0 / sr)
                m = (f >= 300) & (f <= 700)
                peaks.append(f[m][np.argmax(sp[m])])
            print("  警报四段主频: " + ", ".join("%.1f" % p for p in peaks) + " Hz")
        if name == "yin_xiao_yao_ji":
            seg = x[:int(0.15 * sr)]
            sp = np.abs(np.fft.rfft(seg * np.hanning(len(seg))))
            f = np.fft.rfftfreq(len(seg), 1.0 / sr)
            m = (f >= 40) & (f <= 200)
            print("  低频 thump 峰值: %.1f Hz" % f[m][np.argmax(sp[m])])
        if opts.get("note_pitch"):
            print("  咀嚼随机音高 key: %s（±1 半音 ≈ ±6%%）"
                  % (opts["note_pitch"],))
        st = validate(dst, target_sec, loop=opts.get("loop", False))
        st["name"] = name + ".wav"
        st["cmd"] = " ".join('"%s"' % c if " " in c else c for c in cmd)
        results.append(st)
        print("  → %s  %.2f KB  %.3f 秒" %
              (os.path.basename(dst), st["size"] / 1024.0, st["dur"]))
    shutil.rmtree(RENDER_DIR, ignore_errors=True)
    print("\n全部完成：%d 条音效。" % len(results))
    print("命令模板: %s render <mmp> -f wav -o <out.wav> -s 44100 -x 2" % LMMS)


if __name__ == "__main__":
    sys.exit(main())
