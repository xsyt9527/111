# -*- coding: utf-8 -*-
"""
深海食纪 · 自制 BGM 生成器（LMMS 1.2.2）
用途：用 LMMS 命令行渲染三首循环 BGM，并把结果做「无缝循环」后处理，写进 assets/yinxiao/。
产物：
  assets/yinxiao/bgm_shen_hai.wav  深海摇篮（主界面/选角/结算，56 BPM，12 小节 ≈ 51.4 秒）
  assets/yinxiao/bgm_tan_suo.wav   深海探索（局内，96 BPM，16 小节 = 40 秒）
  assets/yinxiao/bgm_jue_zhan.wav  钢铁围猎（机器船决战，140 BPM，24 小节 ≈ 41.1 秒）
中间产物：
  tools/yinyue/*.mmp               LMMS 工程（可复现，正式产物，别删）
  tools/yinyue/render/*.wav        LMMS 原始渲染（临时，处理后删除）
用法：python -I tools/yinyue/shengcheng_yinyue.py
"""
import os
import subprocess
import sys
import wave

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
LMMS = r"D:\LMMS\lmms.exe"
OUT_DIR = os.path.join(ROOT, "assets", "yinxiao")
RENDER_DIR = os.path.join(os.path.dirname(__file__), "render")
BARS_PER_MIN = 4.0 / 1.0  # 4/4 拍：每小节 4 拍

# ---------------------------------------------------------------- XML 零件

def _fmt(v):
    if isinstance(v, float):
        return ("%.4f" % v).rstrip("0").rstrip(".")
    return str(v)


def inst_triple(coarse0=0, wave0=2, vol0=100, coarse1=0, wave1=2, vol1=0,
                fine1=8, coarse2=-12, wave2=0, vol2=0, detune=0):
    """三振荡器：默认一层锯齿，可叠第二层锯齿微失谐 + 低八度正弦垫底。"""
    attrs = {
        "vol0": vol0, "wavetype0": wave0, "coarse0": coarse0, "finel0": 0, "finer0": 0, "pan0": 0,
        "vol1": vol1, "wavetype1": wave1, "coarse1": coarse1, "finel1": 0, "finer1": fine1, "pan1": 0,
        "vol2": vol2, "wavetype2": wave2, "coarse2": coarse2, "finel2": 0, "finer2": 0, "pan2": 0,
        "modalgo1": 0, "modalgo2": 0, "modalgo3": 0,
        "stphdetun0": detune, "stphdetun1": 0, "stphdetun2": 0,
        "phoffset0": 0, "phoffset1": 90, "phoffset2": 180,
        "userwavefile0": "", "userwavefile1": "", "userwavefile2": "",
    }
    inner = " ".join('%s="%s"' % (k, _fmt(v)) for k, v in attrs.items())
    return ('<instrument name="tripleoscillator"><tripleoscillator %s/>'
            '</instrument>' % inner)


def inst_afp(src):
    """AudioFileProcessor：播一个内置采样（鼓组走这里，音高用 key=57 保持原速）。"""
    return ('<instrument name="audiofileprocessor"><audiofileprocessor '
            'stutter="0" interp="1" reversed="0" looped="0" sframe="0" lframe="0" '
            'src="%s" eframe="0.9999" amp="100"/></instrument>' % src)


def eldata(fcut=14000, ftype=0, fres=0.5, att=0.0, dec=0.0, sustain=1.0,
           rel=0.2, hold=0.0, env_amt=0.0, syncmode=0):
    """滤波器 + 音量包络。env_amt=0 表示音量包络关闭（鼓/短音用）。"""
    vol = ('<elvol amt="%s" att="%s" dec="%s" sustain="%s" rel="%s" hold="%s" '
           'ctlenvamt="0" lspd="0.1" lspd_denominator="4" lspd_numerator="4" '
           'lshp="0" lamt="0" latt="0" pdel="0" lpdel="0" syncmode="%d" '
           'userwavefile="" x100="0"/>'
           % (_fmt(env_amt), _fmt(att), _fmt(dec), _fmt(sustain), _fmt(rel),
              _fmt(hold), syncmode))
    cut = ('<elcut amt="0" att="0" dec="0.5" sustain="0.5" rel="0.1" hold="0.5" '
           'ctlenvamt="0" lspd="0.1" lspd_denominator="4" lspd_numerator="4" '
           'lshp="0" lamt="0" latt="0" pdel="0" lpdel="0" syncmode="0" '
           'userwavefile="" x100="0"/>')
    res = ('<elres amt="0" att="0" dec="0.5" sustain="0.5" rel="0.1" hold="0.5" '
           'ctlenvamt="0" lspd="0.1" lspd_denominator="4" lspd_numerator="4" '
           'lshp="0" lamt="0" latt="0" pdel="0" lpdel="0" syncmode="0" '
           'userwavefile="" x100="0"/>')
    return ('<eldata fwet="0" ftype="%d" fcut="%s" fres="%s">%s%s%s</eldata>'
            % (ftype, _fmt(fcut), _fmt(fres), vol, cut, res))


def inst_track(name, instrument, eld, vol, pan, total_len, notes, steps=16):
    """一条乐器轨 + 一个铺满整曲的 pattern。notes 为 (pos, len, key, vol, pan) 元组列表。

    音高换算：LMMS 的 key 编号比 MIDI 记法高 12（key 84 实测 2093Hz = C7），
    所以旋律/和声统一降 12 再写进工程；鼓组走 AudioFileProcessor，key=57 保持采样原速，不降。
    """
    yi_gao = 0 if "audiofileprocessor" in instrument else -12
    note_xml = "\n".join(
        '          <note key="%d" vol="%d" pos="%d" pan="%d" len="%d"/>'
        % (k + yi_gao, v, p, pa, ln) for (p, ln, k, v, pa) in notes)
    return f"""      <track type="0" muted="0" name="{name}" solo="0">
        <instrumenttrack pitch="0" vol="{vol}" fxch="0" pan="{pan}" basenote="57" usemasterpitch="1" pitchrange="1">
          {instrument}
          {eld}
          <chordcreator chord="0" chordrange="1" chord-enabled="0"/>
          <arpeggiator arp="0" arptime_numerator="1" arptime_denominator="1" arprange="1" arpmode="0" arptime="100" arpdir="0" arpgate="100" syncmode="0" arp-enabled="0"/>
          <midiport outputchannel="1" outputcontroller="0" basevelocity="127" outputprogram="1" fixedinputvelocity="-1" fixedoutputvelocity="-1" fixedoutputnote="-1" inputchannel="0" inputcontroller="0" readable="0" writable="-1"/>
          <fxchain numofeffects="0" enabled="0"/>
        </instrumenttrack>
        <pattern type="1" muted="0" steps="{steps}" name="{name}" pos="0" len="{total_len}">
{note_xml}
        </pattern>
      </track>"""


def song_xml(bpm, total_len, tracks):
    body = "\n".join(tracks)
    return f"""<?xml version="1.0"?>
<!DOCTYPE lmms-project>
<lmms-project type="song" version="1.0" creator="LMMS" creatorversion="1.2.0">
  <head timesig_numerator="4" timesig_denominator="4" bpm="{bpm}" mastervol="28" masterpitch="0"/>
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
TICKS = 192        # 每小节 4/4
S16 = 12           # 一个十六分音符


def n(bar, s, ln, key, vol=90, pan=0):
    """bar 从 0 起；s/ln 以十六分音符为单位（一小节 16 个）。"""
    return (int(bar * TICKS + s * S16), int(ln * S16), int(key), int(vol), int(pan))


# ---------------------------------------------------------------- 曲 1：深海摇篮
def qu_shen_hai():
    # 2026-11-08 改版：主界面反馈「太吵、怪怪的」。
    # 病根：①钟琴在 C5~D6 高音区连奏 13 颗还带回声，2~8kHz 能量过半；
    #       ②每 2 小节一下心跳底鼓，静态页面里像杂音；
    #       ③和声垫/低音只写 23.7 个十六分（约 1.5 小节），每组 3 小节的后半段其实是断的，
    #         靠钟琴填缝 → 听起来一块一块、接不上。
    # 改法：只留「和声垫 + 低音持续 + 低频稀疏钟声」三层；垫子铺满整组 3 小节并交叉淡出；
    #       钟琴降到 A3~E4、正弦为主、无回声；删心跳鼓；速度 60→56，更慢更松。
    bpm = 56
    bars = 12
    total = bars * TICKS
    tracks = []

    # 和声：Am / F / C / G，各 3 小节；开放式低音区排列，不叠高音
    chords = [
        (0, [45, 52, 57]),
        (3, [41, 48, 53]),
        (6, [48, 55, 60]),
        (9, [43, 50, 55]),
    ]
    # 铺底和声：整组 3 小节长音（释放段盖到下一组，交叉淡出，不留气口）
    pad = []
    for b0, keys in chords:
        for i, k in enumerate(keys):
            pad.append(n(b0, 0, 48, k, 88 if i == 0 else 74, -10 if i % 2 else 10))
    tracks.append(inst_track(
        "和声垫", inst_triple(coarse0=0, wave0=1, vol0=100, vol1=0, coarse2=0, wave2=0, vol2=34),
        eldata(fcut=900, fres=0.3, att=2.4, dec=0.8, sustain=0.9, rel=1.8, env_amt=1.0),
        vol=42, pan=0, total_len=total, notes=pad))

    # 低音持续：纯正弦，跟着和弦根音走，也是整组 3 小节
    drone = []
    for b0, root in [(0, 33), (3, 29), (6, 36), (9, 31)]:
        drone.append(n(b0, 0, 48, root, 96))
        drone.append(n(b0, 0, 48, root + 12, 28))
    tracks.append(inst_track(
        "低音持续", inst_triple(coarse0=0, wave0=0, vol0=100, vol1=0, wave1=1, vol2=0),
        eldata(fcut=500, fres=0.2, att=1.4, dec=0.5, sustain=0.92, rel=0.8, env_amt=1.0),
        vol=38, pan=0, total_len=total, notes=drone))

    # 钟琴：每个和弦只落 1~2 颗 A3~E4 柔音，无回声；正弦为主，只带一点泛音
    bells = [
        (1, 6, 10, 64),   # Am → E4
        (2, 8, 8, 57),    # Am → A3
        (4, 4, 10, 60),   # F  → C4
        (5, 8, 8, 53),    # F  → F3
        (7, 8, 8, 55),    # C  → G3
        (8, 6, 10, 64),   # C  → E4
        (10, 4, 10, 62),  # G  → D4
        (11, 8, 8, 59),   # G  → B3
    ]
    bn = []
    for i, (b, s, ln, k) in enumerate(bells):
        bn.append(n(b, s, ln, k, 78, -12 if i % 2 else 12))
    tracks.append(inst_track(
        "钟琴", inst_triple(coarse0=0, wave0=0, vol0=100, coarse1=0, wave1=1, vol1=6,
                            coarse2=12, wave2=0, vol2=10),
        eldata(fcut=3200, fres=0.2, att=0.02, dec=1.5, sustain=0.05, rel=3.0, env_amt=1.0),
        vol=42, pan=0, total_len=total, notes=bn))

    return bpm, total, tracks


# ---------------------------------------------------------------- 曲 2：深海探索
def qu_tan_suo():
    bpm = 96
    bars = 16
    total = bars * TICKS
    tracks = []

    # 每 2 小节一个和弦：Dm / Bb / F / C，两轮
    prog = [
        dict(root=38, fifth=45, pad=[50, 53, 57, 62], arp=[62, 65, 69, 74]),
        dict(root=34, fifth=41, pad=[46, 50, 53, 58], arp=[58, 62, 65, 70]),
        dict(root=41, fifth=48, pad=[53, 57, 60, 65], arp=[53, 57, 60, 65]),
        dict(root=36, fifth=43, pad=[48, 52, 55, 60], arp=[55, 60, 64, 67]),
    ]

    bass = []
    for blk in range(8):
        ch = prog[blk % 4]
        for half in range(2):
            b = blk * 2 + half
            r = ch["root"]
            for (s, ln, k, v) in [(0, 2, r, 100), (3, 1, r, 62), (6, 2, r + 12, 78),
                                  (8, 2, r, 92), (11, 1, r, 58), (14, 1, ch["fifth"], 72)]:
                bass.append(n(b, s, ln, k, v))
    tracks.append(inst_track(
        "贝斯", inst_triple(coarse0=-12, wave0=0, vol0=100, vol1=58, wave1=1, fine1=3),
        eldata(fcut=620, fres=0.3, att=0.006, dec=0.25, sustain=0.7, rel=0.12, env_amt=1.0),
        vol=74, pan=0, total_len=total, notes=bass))

    # 八分音符琶音：轻快、留空
    arp = []
    for blk in range(8):
        ch = prog[blk % 4]
        seq = ch["arp"]
        for half in range(2):
            b = blk * 2 + half
            order = [0, 1, 2, 3, 2, 1, 0, 2] if half == 0 else [1, 2, 3, 2, 1, 0, 1, 2]
            for i, idx in enumerate(order):
                v = 76 if i % 2 == 0 else 48
                arp.append(n(b, i * 2, 1.7, seq[idx], v, -24 if i % 2 else 24))
    tracks.append(inst_track(
        "琶音", inst_triple(coarse0=0, wave0=1, vol0=100, vol1=34, wave1=0, fine1=7),
        eldata(fcut=2600, fres=0.35, att=0.003, dec=0.42, sustain=0.05, rel=0.5, env_amt=1.0),
        vol=42, pan=0, total_len=total, notes=arp))

    # 和声垫
    pad = []
    for blk in range(8):
        ch = prog[blk % 4]
        for k in ch["pad"]:
            pad.append(n(blk * 2, 0, 15.6, k, 62))
    tracks.append(inst_track(
        "和声垫", inst_triple(wave0=1, vol0=100, vol1=0, fine1=9, coarse2=0, wave2=0, vol2=52),
        eldata(fcut=850, fres=0.3, att=0.7, dec=0.5, sustain=0.8, rel=1.4, env_amt=1.0),
        vol=22, pan=0, total_len=total, notes=pad))

    # 鼓组
    kick = []
    for b in range(bars):
        for s in (0, 8):
            kick.append(n(b, s, 1.4, 57, 100))
        if b % 4 == 3:
            kick.append(n(b, 14, 1.0, 57, 64))
    tracks.append(inst_track(
        "底鼓", inst_afp("drums/kick_soft01.ogg"), eldata(fcut=400, fres=0.2),
        vol=72, pan=0, total_len=total, notes=kick))

    snare = [n(b, s, 1.2, 57, 92) for b in range(bars) for s in (4, 12)]
    for b in (7, 15):
        snare += [n(b, 13, 1, 57, 54), n(b, 14, 1, 57, 68), n(b, 15, 1, 57, 86)]
    tracks.append(inst_track(
        "军鼓", inst_afp("drums/snare01.ogg"), eldata(fcut=6000, fres=0.2),
        vol=150, pan=10, total_len=total, notes=snare))

    hat = []
    for b in range(bars):
        for s in range(0, 16, 2):
            hat.append(n(b, s, 0.8, 57, 56 if s % 4 == 0 else 34, -16))
        if b % 4 == 3:
            hat.append(n(b, 14, 0.8, 57, 48, -16))
    tracks.append(inst_track(
        "闭镲", inst_afp("drums/hihat_closed01.ogg"), eldata(fcut=9000, fres=0.2),
        vol=80, pan=-16, total_len=total, notes=hat))

    shaker = [n(b, s, 0.6, 57, 34 if s % 4 else 44, 20)
              for b in range(bars) for s in range(0, 16, 2)]
    tracks.append(inst_track(
        "沙锤", inst_afp("drums/shaker01.ogg"), eldata(fcut=8000, fres=0.2),
        vol=64, pan=20, total_len=total, notes=shaker))

    # 后半段旋律
    lead = []
    mel = [
        (8, [(0, 4, 69), (4, 4, 74), (8, 6, 77), (14, 2, 76)]),
        (9, [(0, 6, 74), (8, 4, 72), (12, 4, 69)]),
        (10, [(0, 4, 70), (4, 4, 74), (8, 8, 77)]),
        (11, [(0, 4, 76), (4, 4, 72), (8, 8, 74)]),
        (12, [(0, 4, 69), (4, 4, 74), (8, 6, 77), (14, 2, 79)]),
        (13, [(0, 6, 77), (8, 4, 74), (12, 4, 72)]),
        (14, [(0, 4, 70), (4, 4, 74), (8, 4, 77), (12, 4, 79)]),
        (15, [(0, 8, 74), (8, 8, 69)]),
    ]
    for b, items in mel:
        for (s, ln, k) in items:
            lead.append(n(b, s, ln, k, 86, 8))
            lead.append(n(b, s, ln, k - 12, 42, -8))  # 低八度加厚
    tracks.append(inst_track(
        "旋律", inst_triple(wave0=1, vol0=100, vol1=34, wave1=0, fine1=5),
        eldata(fcut=4200, fres=0.25, att=0.02, dec=0.5, sustain=0.62, rel=0.7, env_amt=1.0),
        vol=46, pan=8, total_len=total, notes=lead))

    return bpm, total, tracks


# ---------------------------------------------------------------- 曲 3：钢铁围猎
def qu_jue_zhan():
    bpm = 140
    bars = 24
    total = bars * TICKS
    tracks = []

    # Em / C / G / D，每 2 小节换一次
    prog = [
        dict(root=40, chord=[52, 55, 59], pad=[40, 47]),
        dict(root=36, chord=[48, 52, 55], pad=[36, 43]),
        dict(root=43, chord=[50, 55, 59], pad=[43, 50]),
        dict(root=38, chord=[50, 54, 57], pad=[38, 45]),
    ]

    # 十六分音符推进贝斯
    bass = []
    for b in range(bars):
        ch = prog[(b // 2) % 4]
        r = ch["root"]
        pattern = [0, 0, 12, 0, 0, 0, 12, 0, 0, 0, 12, 0, 7, 7, 12, 12]
        for i, off in enumerate(pattern):
            v = 100 if i % 4 == 0 else 74
            if b in (16, 17, 18, 19):
                if i % 2:
                    continue
                v = 66
            bass.append(n(b, i, 0.9, r + off, v))
    tracks.append(inst_track(
        "驱动贝斯", inst_triple(coarse0=-12, wave0=2, vol0=100, vol1=38, wave1=0, fine1=2),
        eldata(fcut=900, fres=0.3, att=0.002, dec=0.14, sustain=0.55, rel=0.08, env_amt=1.0),
        vol=80, pan=0, total_len=total, notes=bass))

    # 铜管柱式和弦：切分重音
    stabs = []
    for b in range(bars):
        ch = prog[(b // 2) % 4]
        hits = [(0, 2, 92), (3, 1, 58), (6, 2, 76), (10, 1, 54), (12, 2, 84), (15, 1, 66)]
        if b in (16, 17, 18, 19):
            hits = [(0, 4, 74), (8, 4, 62)]
        for (s, ln, v) in hits:
            for k in ch["chord"]:
                stabs.append(n(b, s, ln, k, v, -10))
    tracks.append(inst_track(
        "铜管", inst_triple(wave0=2, vol0=100, vol1=62, wave1=3, fine1=12, coarse2=-12, wave2=2, vol2=40),
        eldata(fcut=2400, fres=0.45, att=0.008, dec=0.2, sustain=0.5, rel=0.18, env_amt=1.0),
        vol=44, pan=6, total_len=total, notes=stabs))

    # 弦乐式持续垫：制造压迫感
    pad = []
    for blk in range(12):
        ch = prog[blk % 4]
        for k in ch["pad"]:
            pad.append(n(blk * 2, 0, 15.7, k, 72))
    tracks.append(inst_track(
        "压迫垫", inst_triple(wave0=1, vol0=100, vol1=0, fine1=14, coarse2=0, wave2=0, vol2=60),
        eldata(fcut=700, fres=0.4, att=0.9, dec=0.6, sustain=0.85, rel=1.2, env_amt=1.0),
        vol=38, pan=0, total_len=total, notes=pad))

    # 鼓组
    kick = []
    for b in range(bars):
        if 16 <= b <= 19:
            kick += [n(b, 0, 1.4, 57, 100), n(b, 8, 1.4, 57, 92)]
        else:
            kick += [n(b, s, 1.4, 57, 100) for s in (0, 4, 8, 12)]
            if b % 2:
                kick.append(n(b, 14, 1.0, 57, 62))
    tracks.append(inst_track(
        "底鼓", inst_afp("drums/kick_hard01.ogg"), eldata(fcut=500, fres=0.2),
        vol=88, pan=0, total_len=total, notes=kick))

    snare = []
    for b in range(bars):
        if 16 <= b <= 19:
            snare += [n(b, 8, 1.2, 57, 80)]
        else:
            snare += [n(b, s, 1.2, 57, 96) for s in (4, 12)]
    for b in (7, 15, 23):
        snare += [n(b, 13, 1, 57, 62), n(b, 14, 1, 57, 78), n(b, 15, 1, 57, 96)]
    tracks.append(inst_track(
        "军鼓", inst_afp("drums/snare_harsh01.ogg"), eldata(fcut=7000, fres=0.2),
        vol=118, pan=8, total_len=total, notes=snare))

    clap = [n(b, s, 1.0, 57, 74, -8) for b in range(bars) if not (16 <= b <= 19)
            for s in (4, 12)]
    tracks.append(inst_track(
        "拍手", inst_afp("drums/clap01.ogg"), eldata(fcut=8000, fres=0.2),
        vol=90, pan=-8, total_len=total, notes=clap))

    hat = []
    for b in range(bars):
        for s in range(0, 16):
            if 16 <= b <= 19 and s % 2:
                continue
            hat.append(n(b, s, 0.5, 57, 66 if s % 4 == 0 else 36, 18))
        if b % 4 == 0:
            hat.append(n(b, 14, 0.7, 57, 58, 18))
    tracks.append(inst_track(
        "十六分镲", inst_afp("drums/hihat_closed03.ogg"), eldata(fcut=10000, fres=0.2),
        vol=64, pan=18, total_len=total, notes=hat))

    crash = [n(b, 0, 8, 57, 90, -20) for b in (0, 8, 16, 20)]
    tracks.append(inst_track(
        "吊镲", inst_afp("drums/crash01.ogg"), eldata(fcut=12000, fres=0.2),
        vol=34, pan=-20, total_len=total, notes=crash))

    # 第二段主旋律（8~15 小节）+ 结尾拔高
    lead = []
    mel = [
        (8, [(0, 2, 71), (2, 2, 76), (4, 2, 79), (6, 4, 78), (12, 2, 74)]),
        (9, [(0, 4, 76), (6, 2, 74), (8, 4, 71), (14, 2, 67)]),
        (10, [(0, 2, 72), (2, 2, 76), (4, 4, 79), (10, 2, 81), (12, 2, 79)]),
        (11, [(0, 4, 79), (6, 2, 74), (8, 6, 71)]),
        (12, [(0, 2, 71), (2, 2, 76), (4, 2, 79), (6, 4, 83), (12, 2, 81)]),
        (13, [(0, 4, 79), (6, 2, 78), (8, 4, 76), (14, 2, 74)]),
        (14, [(0, 2, 72), (2, 2, 76), (4, 2, 79), (6, 2, 81), (8, 6, 83)]),
        (15, [(0, 4, 81), (4, 4, 79), (8, 8, 76)]),
    ]
    for b, items in mel:
        for (s, ln, k) in items:
            lead.append(n(b, s, ln, k, 88, -6))
            lead.append(n(b, s, ln, k - 12, 40, 6))
    # 20~23 结尾句：上行到 B5 收住，方便循环回开头
    for (b, s, ln, k) in [(20, 0, 2, 76), (20, 2, 2, 79), (20, 4, 4, 83),
                          (21, 0, 2, 81), (21, 2, 2, 83), (21, 4, 4, 86),
                          (22, 0, 4, 83), (22, 4, 4, 81), (22, 8, 6, 79),
                          (23, 0, 4, 78), (23, 4, 4, 79), (23, 8, 8, 83)]:
        lead.append(n(b, s, ln, k, 90, -6))
        lead.append(n(b, s, ln, k - 12, 40, 6))
    tracks.append(inst_track(
        "主旋律", inst_triple(wave0=2, vol0=100, vol1=48, wave1=3, fine1=9,
                              coarse2=12, wave2=0, vol2=16),
        eldata(fcut=3800, fres=0.4, att=0.012, dec=0.3, sustain=0.66, rel=0.25, env_amt=1.0),
        vol=52, pan=-6, total_len=total, notes=lead))

    return bpm, total, tracks


# 每首的归一化峰值：主界面曲刻意压低（用户反馈太吵），局内/决战保持满一些
PEAK_DB = {"bgm_shen_hai": -6.0}


# ---------------------------------------------------------------- 渲染与后处理
def render(name, bpm, total, tracks):
    os.makedirs(RENDER_DIR, exist_ok=True)
    os.makedirs(OUT_DIR, exist_ok=True)
    mmp = os.path.join(os.path.dirname(__file__), name + ".mmp")
    raw = os.path.join(RENDER_DIR, name + ".wav")
    with open(mmp, "w", encoding="utf-8") as f:
        f.write(song_xml(bpm, total, tracks))
    print("[LMMS] 渲染", name, "…")
    r = subprocess.run([LMMS, "render", mmp, "-f", "wav", "-o", raw,
                        "-s", "44100", "-x", "2"],
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    if r.returncode != 0 or not os.path.exists(raw):
        print(r.stdout[-2000:])
        print(r.stderr[-2000:])
        raise SystemExit("渲染失败：" + name)
    loop_wav(raw, os.path.join(OUT_DIR, name + ".wav"), bpm, total,
             PEAK_DB.get(name, -1.0))
    os.remove(raw)


def loop_wav(src, dst, bpm, total_ticks, peak_db=-1.0):
    """取整段循环长度，把超出部分的尾音折回开头，再按 peak_db 归一化单声道。"""
    with wave.open(src, "rb") as w:
        sr = w.getframerate()
        ch = w.getnchannels()
        sw = w.getsampwidth()
        data = w.readframes(w.getnframes())
    assert sw == 2, "只处理 16bit"
    x = np.frombuffer(data, dtype="<i2").astype(np.float64)
    x = x.reshape(-1, ch).mean(axis=1)

    sec_per_tick = 60.0 / bpm / 48.0   # 192 ticks = 4 拍
    loop_len = int(round(total_ticks * sec_per_tick * sr))
    loop_len = min(loop_len, len(x))
    head = x[:loop_len].copy()
    tail = x[loop_len:]
    if len(tail) > 0:
        m = min(len(tail), loop_len)
        head[:m] += tail[:m]
    peak = float(np.max(np.abs(head))) or 1.0
    gain = 10 ** (peak_db / 20.0)
    head *= gain * 32767.0 / peak   # 先归一化到浮点满幅，再转 int16
    # 首尾 5 ms 微淡入/淡出，避免直流硬切
    fade = int(sr * 0.005)
    if fade > 1:
        head[:fade] *= np.linspace(0.0, 1.0, fade)
        head[-fade:] *= np.linspace(1.0, 0.0, fade)
    out = np.clip(head, -32768, 32767).astype("<i2")
    with wave.open(dst, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(out.tobytes())
    print("  → %s  %.2f 秒  %.2f MB  峰值 %.1f dBFS"
          % (os.path.basename(dst), loop_len / sr,
             os.path.getsize(dst) / 1048576.0, peak_db))


def main():
    jobs = [
        ("bgm_shen_hai", qu_shen_hai),
        ("bgm_tan_suo", qu_tan_suo),
        ("bgm_jue_zhan", qu_jue_zhan),
    ]
    for name, fn in jobs:
        bpm, total, tracks = fn()
        render(name, bpm, total, tracks)
    print("全部完成。")


if __name__ == "__main__":
    sys.exit(main())
