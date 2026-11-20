# 待用 · 像素特效试玩包（2026-11-17）

这里是**选项 2**：把游戏里仍在用的 12 套旧 4 帧特效，用 `pixelfx` 重新渲染成像素版，供实玩一局后决定用不用。
开关已经默认打开（`scripts/te_xiao.gd` 的 `SHI_YONG_DAI_YONG_XIANG_SU := true`），所以现在进游戏看到的就是像素版。

- 若判定「好用」→ 保留本目录，长期走像素版；后续可再清理旧的 `data/donghua/*_4zhen.tres`。
- 若判定「不好用」→ 把开关改成 `false`，立刻回到旧 4 帧；本目录按用户要求保留备查，不删。

另外**选项 1**（手动攻击命中火花）不在这里，已作为正式资源永久接入：
`assets/texiao_pixel/shou_dong_ming_zhong/shou_dong_ming_zhong.png/.json`。

## 文件与映射

每套 = 一张横向图集 PNG + 一份 Aseprite JSON（同名的 `.png` / `.json`），动画名统一 `bao`，帧率 30 fps。

| 旧特效（文件名） | 旧用途 | pixelfx id | 调色板 | 帧数 | 帧尺寸 | pivot | 试玩截断 | 混合 |
|---|---|---|---:|---:|---:|---:|---:|---|
| `dian_texiao` | 放电圈（电鳗 / 九头电网等） | `scifi/emp-blast` | electric 蓝白 | 97 | 152×116 | (76,84) | 0.55s | 普通 |
| `du_texiao` | 中毒酸雾 | `nature/poison-cloud` | poison 黄绿 | 120 | 256×100 | (128,86) | 0.85s | 普通 |
| `xuan_wo` | 漩涡吸卷 | `water/whirlpool` | water 青蓝 | 90 | 128×84 | (64,42) | 1.0s | 普通 |
| `yu_lei` | 鱼雷冲刺水花 | `water/splash` | water 青蓝 | 76 | 176×100 | (88,78) | 0.6s | 普通 |
| `kuang_bao` | 狂暴撕咬开启 | `arcane/mana-burst` | ember 橙红 | 55 | 208×150 | (104,124) | 0.85s | 普通 |
| `ni_liu` | 逆流闪避残影 | `transitions/pixel-dissolve` | arcane 紫 | 67 | 320×180 | 左上（按居中放） | 0.7s | 普通 |
| `ying_lin` | 硬鳞反击触发 | `impacts/parry` | gold 金白 | 31 | 200×112 | (100,96) | 0.8s | 普通 |
| `dian_gan` | 电感受器预警 | `lightning/zap-hit` | electric 蓝白 | 28 | 144×112 | (76,56) | 0.6s | 普通 |
| `ying_ke` | 硬壳护体 | `pickups/collect-burst` | ice 冰蓝 | 42 | 112×108 | (56,94) | 0.9s | 叠加 ADD |
| `dian_mai` | 电脉冲（九头电网仍用） | `arcane/mana-burst` | electric 蓝白 | 55 | 208×150 | (104,124) | 0.9s | 叠加 ADD |
| `you_er` | 诱饵气泡吐出 / 咬破 | `water/bubbles` | water 青蓝 | 120 | 104×112 | (52,104) | 0.9s | 叠加 ADD |
| `xue_xing` | 血腥狂热血雾 | `fire/fire-tornado` | blood 暗红 | 60 | 120×152 | (60,136) | 1.0s | 叠加 ADD |

手动命中（选项 1，正式）：

| 文件 | 用途 | pixelfx id | 调色板 | 帧数 | 帧尺寸 | pivot | 截断 |
|---|---|---|---:|---:|---:|---:|---:|
| `shou_dong_ming_zhong` | 手动攻击键命中火花 | `impacts/hit-spark` | gold 金白 | 16 | 136×80 | (44,64) | 0.55s |

## 接入方式（改哪里）

- 加载器：`scripts/xiang_su_te_xiao.gd`（`XiangSuTeXiao`）。按特效名查找：
  先 `res://assets/texiao_pixel/<名>/<名>.json`，再 `res://assets/待用/<名>.json`；读 JSON → 用 PNG 建 `SpriteFrames`，动画名 `bao`。
- 播放：`scripts/te_xiao.gd` 的 `_sheng_chu_xiang_su()`。
  - 最近邻过滤 `TEXTURE_FILTER_NEAREST`，深海背景下不糊边。
  - 按 JSON 的 `pivot` 设 `offset`，让「特效原点」落在目标位置；`pivot=(0,0)` 的全屏类按帧中心放。
  - 屏幕足迹对齐旧版：节点缩放 = 调用方倍率 × `274 / 像素帧宽`。
  - 一次性特效播完即销毁；循环特效 / 长特效按上表「试玩截断」秒数淡出 0.15 秒收尾。
- 回退：`scripts/te_xiao.gd` 顶部 `SHI_YONG_DAI_YONG_XIANG_SU`。`true`=像素版，`false`=旧 4 帧。
  手动命中（`TeXiao.shou_dong_yao_zhong`）不受该开关影响，始终走像素版。
- 资源缺失时静默回退旧特效，不报错、不影响战斗。

## 追问：为什么有的颜色和旧版不一样？

像素版统一按语义调色：电=蓝白、毒=黄绿、水=青蓝、狂暴=橙红、血=暗红、反击/命中=金白、闪避=紫。
如果某个特效颜色/时长想再调，改 `te_xiao.gd` 里对应的 `shi_chang`，或在 `pixelfx` 里换 `palette` 重新导出同名文件即可，加载器不用动。

## 试玩判定步骤

1. 启动 F5，按正常流程玩一局；重点看：
   - 放电（电鳗 / 技能）、中毒、漩涡、冲刺水花、狂暴、闪避、硬鳞反击、电感受器、硬壳护体、电脉冲、诱饵气泡、血腥狂热。
   - 打机械船时右下角攻击键出现；手动咬一口看金色命中火花。
2. 记下「好用 / 不好用」，以及具体哪套太亮、太长、太小、位置偏了。
3. 判定后按上面的「回退」或「长期保留」处理；若部分采用，也可以只把个别 `SHI_YONG_DAI_YONG_XIANG_SU` 分支改成逐套开关（参数已集中在一个函数里）。

## 生成方式（备查）

在 `C:\Users\苏\.claude\skills\pixelfx` 下：

```bash
node tools/render.mjs scifi/emp-blast --sheet --opts '{"palette":["#0a0f2e","#172a78","#2550d0","#3f8cff","#7cc8ff","#c8f0ff","#ffffff"]}'
```

其余套同理，id 与 palette 见上表；导出后把 `records/<分类>/<名>/<名>.png/.json` 复制成本目录的 `<旧特效名>.png/.json`。
