"""
pixelfx v2 特效烘焙管线（深海食纪 TASK-031）
用法（在项目根目录）：
  python -I tools/texiao/hong_bei_texiao_v2.py --project . --pixelfx <pixelfx库目录> --manifest tools/texiao/manifest_v2.json
可选：--only key1,key2 只烘指定条目；--report 打印每条明细。

做什么：
  1. 调 pixelfx 的 node tools/render.mjs <id> --sheet --no-actor --fps N --opts JSON
  2. 用 Pillow 截帧、按类别限制画布最长边（不放大，避免假高清）、重排网格
  3. 量出所有帧的透明内容并集宽高 visible，写入 JSON 供运行时“特效宽=判定宽”换算
  4. 输出 assets/texiao_pixel/v2/<key>/texiao_<key>.png/.json
  5. 生成 scripts/te_xiao_ku_zi_yuan.gd（key → 资源路径/可见宽/帧率/循环/寿命/混合）

设计口径：
  - 单档高清：普通/小型 ≤160px，全屏 ≤256px；小图保持原尺寸，不做 NEAREST 放大。
  - 图集用网格而不是一条长横条：手机 GLES3 纹理上限常见 4096，网格宽度硬限 2048。
  - pivot 只由本脚本按 anchorMode 写死，运行时不再用 274 旧帧宽对齐。
"""
import argparse
import json
import math
import re
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image

# 画布最长边上限：small=保持小特效锐度；normal=技能主特效；full=全屏技
CAP = {"small": 128, "normal": 160, "full": 256}
# 图集单行最大像素宽：留出手机纹理安全边界（2048 而非 4096）
SHEET_MAX_W = 2048
DEFAULT_Z = 5


def read_palettes(color_js: Path) -> dict:
    """从 pixelfx 的 src/core/color.js 里解析 PAL 调色板名，避免清单里重复抄颜色。"""
    text = color_js.read_text(encoding="utf-8")
    block = re.search(r"export const PAL = \{([^}]*)\}", text, re.S)
    if not block:
        return {}
    out = {}
    for name, body in re.findall(r"(\w+):\s*\[([^\]]+)\]", block.group(1)):
        colors = re.findall(r'"#([0-9a-fA-F]{3,6})"', body)
        out[name] = ["#" + c for c in colors]
    return out


def resolve_palette(value, palettes: dict) -> list:
    """清单里 palette 可以写调色板名，也可以直接写颜色数组。"""
    if isinstance(value, list):
        colors = value
    elif isinstance(value, str):
        if value not in palettes:
            raise KeyError(f"未知调色板: {value}")
        colors = palettes[value]
    else:
        raise TypeError(f"palette 类型不对: {type(value)}")
    if len(colors) < 2:
        raise ValueError("调色板至少需要 2 个颜色")
    return colors


def pivot_of(mode: str, w: int, h: int) -> tuple:
    """锚点：center 居中（范围/爆发）；left 左中（直线/弹道，旋转绕起点）；bottom 底中（地面/光柱）。"""
    if mode == "left":
        return (0.0, h / 2.0)
    if mode == "bottom":
        return (w / 2.0, float(h))
    if mode == "top":
        return (w / 2.0, 0.0)
    return (w / 2.0, h / 2.0)


def run_render(pixelfx: Path, entry: dict, out_dir: Path, palettes: dict) -> tuple:
    """调 render.mjs 出图；返回 (源 PNG 路径, 源 JSON 路径)。"""
    fx_id = entry["id"]
    fps = int(entry.get("fps", 12))
    opts = {"palette": resolve_palette(entry["palette"], palettes)}
    opts.update(entry.get("opts", {}))
    name = fx_id.split("/")[1]
    cmd = [
        "node", "tools/render.mjs", fx_id,
        "--sheet", "--no-actor",
        "--fps", str(fps),
        "--opts", json.dumps(opts, ensure_ascii=True, separators=(",", ":")),
        "--out", str(out_dir),
    ]
    res = subprocess.run(cmd, cwd=str(pixelfx), capture_output=True, text=True, encoding="utf-8")
    if res.returncode != 0:
        raise RuntimeError(f"render 失败 {fx_id}:\n{res.stdout}\n{res.stderr}")
    base = out_dir / fx_id
    png = base / f"{name}.png"
    meta = base / f"{name}.json"
    if not png.exists() or not meta.exists():
        raise RuntimeError(f"render 没产出预期文件: {png} / {meta}\n{res.stdout}")
    return png, meta


def load_frames(src_png: Path, src_json: Path, max_frames: int) -> list:
    """按 Aseprite JSON 的 frame 矩形裁出每一帧（网格图集），截到 max_frames。"""
    data = json.loads(src_json.read_text(encoding="utf-8"))
    frames = data.get("frames", [])
    if not frames:
        raise ValueError(f"JSON 没有 frames: {src_json}")
    sheet = Image.open(src_png).convert("RGBA")
    out = []
    for item in frames[:max_frames]:
        rect = item.get("frame", {})
        x, y, w, h = int(rect["x"]), int(rect["y"]), int(rect["w"]), int(rect["h"])
        out.append(sheet.crop((x, y, x + w, y + h)))
    return out


def union_bbox(frames: list) -> tuple:
    """所有帧 alpha 非零区域的并集；全透明时退化为整帧。"""
    left = top = 10 ** 9
    right = bottom = -1
    for frame in frames:
        box = frame.getchannel("A").getbbox()
        if not box:
            continue
        left = min(left, box[0])
        top = min(top, box[1])
        right = max(right, box[2])
        bottom = max(bottom, box[3])
    if right <= left or bottom <= top:
        w, h = frames[0].size
        return 0, 0, w, h
    return left, top, right - left, bottom - top


def bake_entry(entry: dict, project: Path, pixelfx: Path, tmp_root: Path, palettes: dict) -> dict:
    key = entry["key"]
    fx_id = entry["id"]
    fps = int(entry.get("fps", 12))
    max_sec = float(entry.get("max_shi_chang", 1.0))
    loop = bool(entry.get("loop", False))
    blend = entry.get("blend", "normal")
    z = int(entry.get("z", DEFAULT_Z))
    anchor = entry.get("pivot", "center")
    cap = CAP.get(entry.get("lei", "normal"), 160)

    tmp = tmp_root / key
    if tmp.exists():
        shutil.rmtree(tmp)
    src_png, src_json = run_render(pixelfx, entry, tmp, palettes)

    # 截帧：一次性特效保留收尾帧；循环特效按时间截，避免把整段 10 秒环境动画烘进来
    max_frames = max(1, int(round(max_sec * fps)) + (0 if loop else 1))
    frames = load_frames(src_png, src_json, max_frames)

    # 单档高清：只缩小、不放大；小图保持原尺寸，运行时靠节点缩放
    w, h = frames[0].size
    longest = max(w, h)
    scale = min(1.0, cap / float(longest)) if longest > cap else 1.0
    fw = max(1, int(round(w * scale)))
    fh = max(1, int(round(h * scale)))
    if (fw, fh) != (w, h):
        frames = [f.resize((fw, fh), Image.NEAREST) for f in frames]

    bx, by, vw, vh = union_bbox(frames)

    # 网格排布：宽 ≤ 2048，手机纹理安全
    cols = max(1, min(len(frames), SHEET_MAX_W // fw))
    rows = int(math.ceil(len(frames) / cols))
    sheet = Image.new("RGBA", (cols * fw, rows * fh), (0, 0, 0, 0))
    frame_records = []
    for i, frame in enumerate(frames):
        x = (i % cols) * fw
        y = (i // cols) * fh
        sheet.paste(frame, (x, y))
        frame_records.append({
            "filename": f"{key} {i}",
            "frame": {"x": x, "y": y, "w": fw, "h": fh},
            "rotated": False,
            "trimmed": False,
            "spriteSourceSize": {"x": 0, "y": 0, "w": fw, "h": fh},
            "sourceSize": {"w": fw, "h": fh},
            "duration": int(round(1000.0 / fps)),
        })

    px, py = pivot_of(anchor, fw, fh)
    lifetime = max_sec if loop else 0.0
    image_name = f"texiao_{key}.png"
    out_dir = project / "assets" / "texiao_pixel" / "v2" / key
    out_dir.mkdir(parents=True, exist_ok=True)
    png_path = out_dir / image_name
    json_path = out_dir / f"texiao_{key}.json"
    sheet.save(png_path, "PNG", optimize=True)

    data = {
        "frames": frame_records,
        "meta": {
            "app": "https://github.com/patch-gg/pixelfx",
            "version": "1",
            "image": image_name,
            "format": "RGBA8888",
            "size": {"w": sheet.width, "h": sheet.height},
            "scale": "1",
            "frameTags": [{"name": "bao", "from": 0, "to": len(frames) - 1, "direction": "forward"}],
            "pixelfx": {
                "id": fx_id,
                "name": key,
                "fps": fps,
                "loop": loop,
                "frames": len(frames),
                "frameSize": [fw, fh],
                "pivot": [px, py],
                "columns": cols,
                "visible": [vw, vh],
                "fit": "native",
                "lifetime": lifetime,
                "blend": blend,
                "zIndex": z,
                "anchorMode": anchor,
            },
        },
    }
    json_path.write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding="utf-8")
    shutil.rmtree(tmp, ignore_errors=True)

    return {
        "key": key,
        "id": fx_id,
        "lu": f"res://assets/texiao_pixel/v2/{key}/texiao_{key}.json",
        "kuan": vw,
        "gao": vh,
        "zhen_kuan": fw,
        "zhen_gao": fh,
        "fps": fps,
        "xun_huan": loop,
        "chi_xu": lifetime,
        "die_jia": blend == "add",
        "z": z,
        "frames": len(frames),
        "bytes": png_path.stat().st_size + json_path.stat().st_size,
    }


def write_zi_yuan(project: Path, records: list) -> None:
    """生成 GDScript 常量表：启动时不用扫目录，也不担心 JSON 被导出过滤掉后找不到清单。"""
    lines = [
        "extends RefCounted",
        "class_name TeXiaoKuZiYuan",
        "# 本文件由 tools/texiao/hong_bei_texiao_v2.py 自动生成：不要手改，改清单后重跑烘焙。",
        "# 字段：lu=JSON 精确路径；kuan/gao=不透明内容并集宽高；zhen_kuan/gao=画布帧尺寸；",
        "# xun_huan=循环；chi_xu=循环特效寿命；die_jia=叠加混合；z=层级。",
        "const ZI_YUAN := {",
    ]
    for r in records:
        lines.append(
            '\t"%s": {"lu": "%s", "kuan": %.1f, "gao": %.1f, "zhen_kuan": %.1f, '
            '"zhen_gao": %.1f, "fps": %.1f, "xun_huan": %s, "chi_xu": %.2f, '
            '"die_jia": %s, "z": %d},'
            % (
                r["key"], r["lu"], r["kuan"], r["gao"], r["zhen_kuan"], r["zhen_gao"],
                r["fps"], "true" if r["xun_huan"] else "false", r["chi_xu"],
                "true" if r["die_jia"] else "false", r["z"],
            )
        )
    lines.append("}")
    (project / "scripts" / "te_xiao_ku_zi_yuan.gd").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    # Windows 终端默认 GBK：中文进度会乱码，这里固定成 UTF-8 输出
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", default=".")
    ap.add_argument("--pixelfx", required=True)
    ap.add_argument("--manifest", default="tools/texiao/manifest_v2.json")
    ap.add_argument("--only", default="")
    ap.add_argument("--report", action="store_true")
    args = ap.parse_args()

    project = Path(args.project).resolve()
    pixelfx = Path(args.pixelfx).resolve()
    manifest = (project / args.manifest).resolve()
    entries = json.loads(manifest.read_text(encoding="utf-8"))
    if not isinstance(entries, list):
        raise TypeError("manifest_v2.json 顶层应为数组")
    only = {s.strip() for s in args.only.split(",") if s.strip()}
    if only:
        entries = [e for e in entries if e["key"] in only]
    if not entries:
        print("清单为空或被 --only 过滤空", file=sys.stderr)
        return 1

    palettes = read_palettes(pixelfx / "src" / "core" / "color.js")
    tmp_root = project / "tools" / "texiao" / ".out"
    tmp_root.mkdir(parents=True, exist_ok=True)

    records = []
    total = 0
    for i, entry in enumerate(entries, 1):
        try:
            rec = bake_entry(entry, project, pixelfx, tmp_root, palettes)
        except Exception as exc:
            print(f"[{i}/{len(entries)}] 失败 {entry.get('key')}: {exc}", file=sys.stderr)
            return 1
        records.append(rec)
        total += rec["bytes"]
        if args.report:
            print(f"[{i}/{len(entries)}] {rec['key']:<18} {rec['id']:<30} "
                  f"{rec['frames']:>2}帧 {rec['zhen_kuan']}x{rec['zhen_gao']} "
                  f"可见{rec['kuan']}x{rec['gao']} {rec['bytes'] // 1024}KB")
        else:
            print(f"[{i}/{len(entries)}] {rec['key']} ok")

    shutil.rmtree(tmp_root, ignore_errors=True)
    write_zi_yuan(project, records)
    print(f"\n完成 {len(records)} 套，PNG+JSON 合计 {total / (1024 * 1024):.2f} MB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
