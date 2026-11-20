# 诊断：检查指定 key 的烘焙图集每帧不透明像素数与平均色，判断是源图空还是运行时不显示
from PIL import Image
import os, sys, json

ROOT = r"D:\新游戏001\assets\texiao_pixel\v2"
MANIFEST = r"D:\新游戏001\tools\texiao\manifest_v2.json"

keys = sys.argv[1:] if len(sys.argv) > 1 else None
meta = {}
with open(MANIFEST, encoding="utf-8") as f:
    data = json.load(f)
for e in (data["entries"] if isinstance(data, dict) else data):
    meta[e["key"]] = e

for key in (keys or sorted(meta)):
    d = os.path.join(ROOT, key)
    if not os.path.isdir(d):
        print(f"{key:18s} NO DIR")
        continue
    pngs = sorted(p for p in os.listdir(d) if p.endswith(".png") and "sheet" not in p) or \
           sorted(p for p in os.listdir(d) if p.endswith(".png"))
    if not pngs:
        print(f"{key:18s} EMPTY DIR")
        continue
    line = []
    for p in pngs[:6]:
        im = Image.open(os.path.join(d, p)).convert("RGBA")
        px = [q for q in im.getdata() if q[3] > 40]
        if px:
            r = sum(q[0] for q in px) // len(px)
            g = sum(q[1] for q in px) // len(px)
            b = sum(q[2] for q in px) // len(px)
            line.append(f"{p[:-4]}:{len(px)}px({r},{g},{b})")
        else:
            line.append(f"{p[:-4]}:0px")
    print(f"{key:18s} frames={len(pngs)} " + " | ".join(line))
