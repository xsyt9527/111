# 解析 v2 JSON 图集：逐帧统计不透明像素数（判断内容集中在哪几帧、单帧视觉尺寸）
from PIL import Image
import os, sys, json

V2 = r"D:\新游戏001\assets\texiao_pixel\v2"
for key in sys.argv[1:]:
    d = os.path.join(V2, key)
    js = os.path.join(d, f"texiao_{key}.json")
    meta = json.load(open(js, encoding="utf-8"))
    frames = meta.get("frames", meta)
    tex_name = None
    if isinstance(frames, dict):
        items = list(frames.items())
        tex_name = meta.get("meta", {}).get("image")
    else:  # 数组格式
        items = [(f["filename"], f) for f in frames]
        tex_name = meta.get("meta", {}).get("image")
    img = Image.open(os.path.join(d, tex_name or "texiao_%s.png" % key)).convert("RGBA")
    print(f"== {key}  atlas={img.size}  frames={len(items)}")
    for name, f in items:
        fr = f.get("frame", f)
        box = (fr["x"], fr["y"], fr["x"] + fr["w"], fr["y"] + fr["h"])
        crop = img.crop(box)
        px = [q for q in crop.getdata() if q[3] > 40]
        if px:
            xs = [i % fr["w"] for i, q in enumerate(crop.getdata()) if q[3] > 40]
            ys = [i // fr["w"] for i, q in enumerate(crop.getdata()) if q[3] > 40]
            w = max(xs) - min(xs) + 1
            h = max(ys) - min(ys) + 1
            print(f"  {name:24s} {len(px):6d}px  内容 {w}x{h}")
        else:
            print(f"  {name:24s} 空")
