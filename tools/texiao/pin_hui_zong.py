from PIL import Image, ImageDraw
import os, glob, re

SRC = r"D:\新游戏001\tools\texiao\jietu"
DST = r"D:\新游戏001\tools\texiao\jietu_huizong"
os.makedirs(DST, exist_ok=True)

# 按基础名分组（同一键的两次时机截图上下拼一格）
groups = {}
for f in sorted(glob.glob(os.path.join(SRC, "*.png"))):
    base = re.sub(r"__2$", "", os.path.basename(f)[:-4])
    groups.setdefault(base, []).append(f)
keys = sorted(groups)
assert keys, "没有截图"

PER = 9  # 3x3，每格上下两时机
COLS, ROWS = 3, 3
TW, LH = 400, 225  # 缩略宽，单张高（16:9）
for s in range(0, len(keys), PER):
    batch = keys[s:s + PER]
    cell_h = 22 + LH * 2
    sheet = Image.new("RGB", (COLS * TW, ROWS * cell_h), (18, 18, 24))
    d = ImageDraw.Draw(sheet)
    for i, k in enumerate(batch):
        x, y = (i % COLS) * TW, (i // COLS) * cell_h
        d.text((x + 6, y + 4), k, fill=(240, 240, 120))
        for j, f in enumerate(groups[k][:2]):
            im = Image.open(f).convert("RGB").resize((TW, LH))
            sheet.paste(im, (x, y + 22 + j * LH))
    out = os.path.join(DST, f"huizong_{s // PER + 1:02d}.png")
    sheet.save(out)
    print("ok", out)
print("sheets:", (len(keys) + PER - 1) // PER, "keys:", len(keys))
