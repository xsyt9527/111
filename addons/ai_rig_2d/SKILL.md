---
name: godot-2d-rig-animator
description: Generate and validate natural 2D skeletal animations in Godot 4.x using the AI 2D Rig Builder (`addons/ai_rig_2d`) plugin. Use whenever creating, editing, or debugging 2D character rigs, bone hierarchies, sprite slicing, or FK keyframe animations (idle, run, attack, hit, swim) for pixel art or high-res portraits.
---
# Godot 2D Rig Animator

Create anatomically natural, non-detached 2D skeletal animations in Godot 4.x using the declarative `addons/ai_rig_2d` JSON pipeline.

## When to Use

- Creating a new `.json` rig definition in `res://rigs/` for a 2D sprite or portrait
- Authoring or fixing FK animations (`idle`, `walk`, `run`, `attack`, `hit_shake`, `swim`) that look stiff, detached, or jittery
- Configuring pixel-art safe (`rigid_parts`) vs. high-resolution mesh (`mesh_weights`) deformation

## Why AI Keyframes Usually Look Weird (and How to Prevent It)

1. **Absolute vs. Relative Coordinate Trap**: In Godot, a child `Bone2D`'s `position` is relative to its parent bone. If a child bone's rest position is `[0, -14]` and an animation keyframe sets `"v": [0, 0]`, the child bone collapses onto its parent's origin (detaching the head into the chest). **Always use relative delta keys (`"dp": [dx, dy]`, `"drot_deg": d_angle`, `"dscale": [mx, my]`) in animation tracks** instead of absolute `"v"` values.
2. **Blind Coordinate Guessing**: Never guess where a character's head, torso, or feet are located in pixel space. Always inspect the PNG bounding box first using `addons/ai_rig_2d/tools/inspect_sprite.py`.
3. **Pixel-Art Rotation Shearing**: Rotating a 64x64 pixel-art part by small angles (like `3.5` degrees) under `Nearest` filtering produces severe staircase shearing and breaks 1px dark outlines. On pixel art (`<= 128x128`), drive `idle`, `walk`, and `hit` animations primarily with integer-pixel translations (`"dp": [0, 1]`, `"dp": [-1, 0]`) and `"interpolation": "nearest"`.
4. **In-Phase Robotic Motion**: Moving torso, head, hair, and weapons to their peak at the exact same timestamp `t` looks mechanical. Stagger child bones (head, scarf, hair, weapon) by 1 time step (`0.1s` to `0.15s` delay) behind the parent torso to create natural follow-through and overlapping action.
5. **Part Offset Misalignment**: In `rigid_parts` mode, omit `offset` inside `parts` items so `rig_builder.gd` (v1.1+) automatically computes `offset = region_rect.position - bone_global_rest_pos`. This guarantees the sliced region stays at its exact original pixel location in the rest pose.

## Step-by-Step Workflow

### Step 1: Measure the Sprite Before Writing Any JSON

Run the bundled sprite inspector on the target PNG to get exact non-transparent bounding boxes, center of mass, and landmark Y coordinates:

```bash
python3 addons/ai_rig_2d/tools/inspect_sprite.py assets/sprites/<character>.png
```

Use the returned `suggested_bones_rest` and `suggested_rigid_parts_slices` as your starting coordinates. Never hardcode `[32, 32]` without checking the actual non-transparent bounding box.

### Step 2: Choose the Correct Render Mode

- **For Pixel Art (`<= 128x128`, e.g., 64x64 character sprites)**:
  - Set `"pixel_art_mode": true`, `"integer_pixel_snap": true`, `"nearest_neighbor": true`, and `"deform_mode": "rigid_parts"`.
  - Define `parts` with `region_rect: [x, y, w, h]` and **omit `offset`** (let the builder auto-align each part to the bone's rest position).
  - Set animation `"interpolation": "nearest"`.

- **For High-Resolution Portraits (`>= 256x256`)**:
  - Set `"pixel_art_mode": false`, `"integer_pixel_snap": false`, `"nearest_neighbor": false`, and `"deform_mode": "mesh_weights"`.
  - Set `provider.grid_size` to `[12, 16]` (or proportional to aspect ratio) and `weights.mode` to `"auto_envelope"`.
  - Set animation `"interpolation": "cubic"`.

### Step 3: Author Animations Using Relative Deltas (`dp`, `drot_deg`, `dscale`) and Phase Lag

Always write keyframes using relative deltas from the bone's rest pose, and ensure the first (`t = 0.0`) and last (`t = length`) keyframes match on looping animations:

#### Recipe A: Pixel-Art Breathing & Follow-Through Idle (`length: 0.8`, `interpolation: "nearest"`)
- `torso` (`position`): `t=0.0 -> "dp": [0, 0]`, `t=0.4 -> "dp": [0, 1]`, `t=0.8 -> "dp": [0, 0]`
- `head` (`position`, delayed by 0.1s-0.2s): `t=0.0 -> "dp": [0, 0]`, `t=0.2 -> "dp": [0, 0]`, `t=0.6 -> "dp": [0, 1]`, `t=0.8 -> "dp": [0, 0]`
- `scarf` / `hair` (`position`): `t=0.0 -> "dp": [0, 0]`, `t=0.4 -> "dp": [-1, 1]`, `t=0.8 -> "dp": [0, 0]`

#### Recipe B: High-Res Portrait Breathing & Secondary Sway (`length: 2.0`, `interpolation: "cubic"`)
- `chest` (`position` & `scale`): `t=0.0 -> "dp": [0, 0], "dscale": [1.0, 1.0]`, `t=1.0 -> "dp": [0, -3.5], "dscale": [1.015, 1.01]`, `t=2.0 -> "dp": [0, 0], "dscale": [1.0, 1.0]`
- `head` (`rotation_deg`, phase-lagged): `t=0.0 -> "drot_deg": 0.0`, `t=1.2 -> "drot_deg": -2.0`, `t=2.0 -> "drot_deg": 0.0`
- `hair_back` / `ribbon` (`rotation_deg`, phase-lagged): `t=0.0 -> "drot_deg": 0.0`, `t=1.3 -> "drot_deg": 6.5`, `t=2.0 -> "drot_deg": 0.0`

#### Recipe C: Crisp Damped Hit Shake (`length: 0.3`, `loop: false`, `interpolation: "nearest"`)
- `root` (`position`):
  - `t=0.00 -> "dp": [0, 0]`
  - `t=0.05 -> "dp": [-4, 0]`
  - `t=0.10 -> "dp": [3, -1]`
  - `t=0.15 -> "dp": [-2, 0]`
  - `t=0.20 -> "dp": [1, 0]`
  - `t=0.30 -> "dp": [0, 0]`

#### Recipe D: Horizontal Swimming / Wave Propagation (`length: 1.0`, `loop: true`)
- Propagate a sine-like wave from anterior to posterior bones (`head -> spine_mid -> tail_base -> tail_tip`) with a `0.15s` phase delay per segment so the wave travels backward smoothly instead of bending all segments in unison.

### Step 4: Validate and Check Sanity Warnings via Headless CLI

Run the Godot headless validator after every edit:

```bash
godot --headless --path . -s addons/ai_rig_2d/validate_rig.gd -- res://rigs/<character>.json --build
```

Inspect both `errors` and `warnings` in the JSON report between `=== AI_RIG_CLI_REPORT_BEGIN ===` and `=== AI_RIG_CLI_REPORT_END ===`:

- Fix any `SANITY_WARN` (bone moving too far from rest or collapsing to `[0, 0]`).
- Fix any `PIXEL_ART_WARN` (using small non-90-degree rotations in `pixel_art_mode`).
- Fix any `LOOP_WARN` (mismatched start and end keyframe values on a looping animation).

## Gotchas

- Never use `"v": [0, 0]` on a child bone's position track thinking `[0, 0]` means "no movement". Use `"dp": [0, 0]` instead.
- Do not overlap `region_rect` slices in `rigid_parts` mode unless the parts are intentionally layered with distinct `z_index` values and clean background cutaways; otherwise duplicate pixels will ghost when a part moves.
- Keep `dp` amplitude within `1` to `2` pixels for 64x64 pixel-art `idle` animations; a 5-pixel offset on a 64x64 sprite equals nearly 10% of the character's entire body height and looks like a violent convulsion.
