# TASK-022 范围提案

## 用户七项反馈
1. 小地图改黑色底，首领换色并在图例标明。
2. 「上帝视角（永久被动）」移到玩家设置-角色面板，不写在地图上。
3. 决战镜头随体型/船体加大拉远，机械船大小（不含技能范围）×0.8。
4. 修复决战向上看到背景外灰区、向下鱼到底但视角卡上面。
5. 接入 P0 进化专属被动 33 张图标。
6. 列出需要 AI 生成的特效清单。
7. 多开子代理并行。

## 文件边界
- 表现/面板：`scripts/xiao_di_tu.gd`、`scenes/Main.tscn`、`scripts/she_zhi.gd`
- 镜头/船：`scripts/main.gd`、`scripts/ji_qi_chuan.gd`
- 图标：`data/nengli/*.tres`、`assets/sucai/tubiao/*`、`assets/sucai_classic/tubiao/*`
- 测试与文档：`tests/ce_panding.gd`、`docs/*`

## 禁区
不改攻击范围/伤害数值、不改存档 schema、不新增 Autoload、不提交 `project.godot`/`build/**`/`美术资源/**`。
