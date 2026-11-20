#!/usr/bin/env python3
"""
Sprite Anatomy & Bounding Box Inspector for AI 2D Rig Builder.
Allows Claude to measure the exact non-transparent pixel bounding box, horizontal center,
foot baseline, and anatomical slice rows of any 2D character PNG before writing rig JSON.

Usage:
  python3 addons/ai_rig_2d/tools/inspect_sprite.py path/to/sprite.png
"""
import sys
import json
import os
from PIL import Image


def inspect_sprite(image_path: str) -> dict:
    if not os.path.exists(image_path):
        return {"error": f"File not found: {image_path}"}

    img = Image.open(image_path).convert("RGBA")
    w, h = img.size
    pixels = img.load()

    min_x, min_y = w, h
    max_x, max_y = -1, -1
    sum_x, sum_y, count = 0, 0, 0

    row_spans = {}
    for y in range(h):
        r_min_x, r_max_x = w, -1
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a > 10:
                if x < min_x: min_x = x
                if x > max_x: max_x = x
                if y < min_y: min_y = y
                if y > max_y: max_y = y
                if x < r_min_x: r_min_x = x
                if x > r_max_x: r_max_x = x
                sum_x += x
                sum_y += y
                count += 1
        if r_max_x >= r_min_x:
            row_spans[y] = (r_min_x, r_max_x)

    if count == 0:
        return {"error": "Image is completely transparent", "size": [w, h]}

    bbox_w = max_x - min_x + 1
    bbox_h = max_y - min_y + 1
    center_x = round((min_x + max_x) / 2.0)
    centroid_x = round(sum_x / count)
    centroid_y = round(sum_y / count)

    # Estimate standard humanoid/creature vertical landmarks along the non-transparent height
    head_y = round(min_y + bbox_h * 0.22)
    neck_y = round(min_y + bbox_h * 0.36)
    chest_y = round(min_y + bbox_h * 0.52)
    pelvis_y = round(min_y + bbox_h * 0.72)
    feet_y = max_y

    return {
        "file": image_path,
        "image_size": [w, h],
        "recommended_mode": "rigid_parts" if (w <= 128 and h <= 128) else "mesh_weights",
        "non_transparent_bbox": {
            "min_x": min_x,
            "min_y": min_y,
            "max_x": max_x,
            "max_y": max_y,
            "width": bbox_w,
            "height": bbox_y if False else bbox_h
        },
        "center_of_mass": [centroid_x, centroid_y],
        "suggested_bones_rest": {
            "root_pelvis": {
                "parent": None,
                "position": [center_x, pelvis_y],
                "note": "Root bone at pelvis/lower-body center"
            },
            "torso": {
                "parent": "root",
                "position": [0, chest_y - pelvis_y],
                "note": "Relative offset from root_pelvis up to chest"
            },
            "head": {
                "parent": "torso",
                "position": [0, neck_y - chest_y],
                "note": "Relative offset from chest up to neck/head pivot"
            }
        },
        "suggested_rigid_parts_slices": {
            "HeadPart_region_rect": [min_x, min_y, bbox_w, neck_y - min_y],
            "TorsoPart_region_rect": [min_x, neck_y, bbox_w, pelvis_y - neck_y],
            "LowerBodyPart_region_rect": [min_x, pelvis_y, bbox_w, max_y - pelvis_y + 1]
        }
    }


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 inspect_sprite.py <path_to_png>")
        sys.exit(1)
    report = inspect_sprite(sys.argv[1])
    print(json.dumps(report, indent=2, ensure_ascii=False))
