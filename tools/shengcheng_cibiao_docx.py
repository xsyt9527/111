# -*- coding: utf-8 -*-
# tools/shengcheng_cibiao_docx.py
# 从 docs/引擎词总表.md 生成 Godot引擎词总表.docx
# 用法：python tools/shengcheng_cibiao_docx.py
# 每课更新完 docs/引擎词总表.md 后运行一次（或双击根目录"更新引擎词文档.bat"）

import re
import sys
from datetime import datetime
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.shared import Pt, RGBColor, Cm

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

XIANGMU_GEN = Path(__file__).resolve().parent.parent  # 项目根目录
YUAN_WENJIAN = XIANGMU_GEN / "docs" / "引擎词总表.md"   # 词表源文件
SHUCHU = XIANGMU_GEN / "Godot引擎词总表.docx"          # 输出文档

ZITI = "微软雅黑"


def she_ziti(run, zihao=None, jiacu=None, yanse=None):
    """统一设置中英文字体（中文需设 eastAsia）"""
    run.font.name = ZITI
    run._element.get_or_add_rPr().get_or_add_rFonts().set(qn("w:eastAsia"), ZITI)
    if zihao is not None:
        run.font.size = Pt(zihao)
    if jiacu is not None:
        run.font.bold = jiacu
    if yanse is not None:
        run.font.color.rgb = RGBColor(*yanse)


def tianjia_biaoti(doc, wenben, jibie):
    """添加标题并统一字体"""
    biaoti = doc.add_heading(wenben, level=jibie)
    zihao = {0: 20, 1: 16, 2: 13.5, 3: 12}.get(jibie, 12)
    for run in biaoti.runs:
        she_ziti(run, zihao=zihao, jiacu=True, yanse=(11, 61, 102))
    return biaoti


def tianjia_duanluo(doc, wenben, yinyong=False, liebiao=False):
    """添加正文段落，支持简单的 **加粗** 行内标记"""
    duan = doc.add_paragraph(style="List Bullet" if liebiao else None)
    if yinyong:
        duan.paragraph_format.left_indent = Cm(0.6)
        duan.paragraph_format.space_before = Pt(2)
    bufen = re.split(r"(\*\*.+?\*\*)", wenben)
    for pian in bufen:
        if not pian:
            continue
        if pian.startswith("**") and pian.endswith("**"):
            run = duan.add_run(pian[2:-2])
            she_ziti(run, zihao=10.5, jiacu=True)
        else:
            run = duan.add_run(pian)
            she_ziti(run, zihao=10.5)


def tianjia_biaoge(doc, touhang, shuju):
    """添加带表头样式的表格"""
    biaoge = doc.add_table(rows=1, cols=len(touhang))
    biaoge.style = "Table Grid"
    biaoge.alignment = 1  # 居中
    for i, wenben in enumerate(touhang):
        cell = biaoge.rows[0].cells[i]
        cell.text = ""
        run = cell.paragraphs[0].add_run(wenben)
        she_ziti(run, zihao=10.5, jiacu=True, yanse=(255, 255, 255))
        # 表头底色：深蓝
        shd = cell._tc.get_or_add_tcPr().makeelement(
            qn("w:shd"), {qn("w:val"): "clear", qn("w:fill"): "0B3D66"}
        )
        cell._tc.get_or_add_tcPr().append(shd)
    for hang in shuju:
        cells = biaoge.add_row().cells
        for i in range(min(len(hang), len(touhang))):
            cells[i].text = ""
            run = cells[i].paragraphs[0].add_run(hang[i])
            she_ziti(run, zihao=10.5)
    doc.add_paragraph()  # 表后留白


def shifou_fenxing(line):
    """判断表格分隔行 |---|:--:|"""
    return bool(re.fullmatch(r"\|[\s:|-]+\|?", line.strip()))


def shifou_biaoge(line):
    return line.strip().startswith("|") and line.strip().endswith("|")


def jiexi_yuanwenjian():
    """解析 markdown：返回 (标题行, [('biaoti', 级别, 文本) / ('duanluo', ...) / ('biaoge', 表头, 数据)])"""
    yuansu = []
    lines = YUAN_WENJIAN.read_text(encoding="utf-8").splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        if not stripped:
            i += 1
            continue
        # 表格块
        if shifou_biaoge(stripped):
            hang = []
            while i < len(lines) and shifou_biaoge(lines[i].strip()):
                hang.append(lines[i].strip())
                i += 1
            if len(hang) >= 2 and shifou_fenxing(hang[1]):
                touhang = [c.strip() for c in hang[0].strip("|").split("|")]
                shuju = [
                    [c.strip() for c in h.strip("|").split("|")]
                    for h in hang[2:]
                ]
                yuansu.append(("biaoge", touhang, shuju))
            continue
        # 标题
        m = re.match(r"^(#{1,3})\s+(.*)$", stripped)
        if m:
            yuansu.append(("biaoti", len(m.group(1)), m.group(2).strip()))
            i += 1
            continue
        # 引用与列表
        if stripped.startswith(">"):
            yuansu.append(("duanluo", stripped.lstrip("> "), True, False))
        elif stripped.startswith(("- ", "* ")):
            yuansu.append(("duanluo", stripped[2:], False, True))
        else:
            yuansu.append(("duanluo", stripped, False, False))
        i += 1
    return yuansu


def shengcheng():
    if not YUAN_WENJIAN.exists():
        print(f"找不到源文件：{YUAN_WENJIAN}")
        return 1
    yuansu = jiexi_yuanwenjian()
    doc = Document()

    # 封面标题
    tianjia_biaoti(doc, "深海食纪 · Godot 引擎词总表", 0)
    fu = doc.add_paragraph()
    fu.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = fu.add_run(
        f"Godot 4.7.2　|　生成时间：{datetime.now().strftime('%Y-%m-%d %H:%M')}\n"
        "按文件分类 · 随每课更新 · 建议配合编辑器实践复习"
    )
    she_ziti(run, zihao=10.5, yanse=(90, 90, 90))
    doc.add_paragraph()

    for yuansu_item in yuansu:
        if yuansu_item[0] == "biaoti":
            _, jibie, wenben = yuansu_item
            if jibie == 1 and wenben.startswith("深海食纪"):
                continue  # 跳过 md 里的一级标题（封面已用）
            tianjia_biaoti(doc, wenben, max(1, jibie - 1))
        elif yuansu_item[0] == "biaoge":
            _, touhang, shuju = yuansu_item
            tianjia_biaoge(doc, touhang, shuju)
        else:
            _, wenben, yinyong, liebiao = yuansu_item
            tianjia_duanluo(doc, wenben, yinyong=yinyong, liebiao=liebiao)

    # 结尾提示
    doc.add_paragraph()
    jiewei = doc.add_paragraph()
    jiewei.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = jiewei.add_run("—— 写得出 = 真学会了 ——")
    she_ziti(run, zihao=11, jiacu=True, yanse=(11, 61, 102))

    doc.save(SHUCHU)
    print(f"已生成：{SHUCHU}")
    print(f"词表章节数：{sum(1 for x in yuansu if x[0] == 'biaoti')}，表格数：{sum(1 for x in yuansu if x[0] == 'biaoge')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(shengcheng())
