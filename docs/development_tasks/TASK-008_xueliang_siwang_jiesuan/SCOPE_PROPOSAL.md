# TASK-008 范围提案（SCOPE_PROPOSAL）

## 范围内

- 玩家血量系统：`zuida_xue`(3) / `xue_liang` / `xue_liang_bian_hua` 信号 / `_shoushang()` 接入扣血 / `_si_wang()` 死亡入口（第 3 课挂钩点 + P3-1 观察项配套）
- 血条 UI：XueLiangTiao.tscn + xue_liang_ui.gd（信号驱动 UI 模式二次复用，玩家经 "wan_jia" group 获取）+ Main 实例化
- 满级封顶：zhang_ben.gd jia_jing_yan() 表尾分支（TASK-005/006/007 三次 P3 合并决策落地）
- 结算场景：JieSuan.tscn（等级 + yi_xuan_ka build 列表 + 重开按钮）+ jie_suan.gd（独立场景，切换目标）
- 死亡-重开闭环：change_scene_to_file 双向切换 + ZhangBen.chong_zhi() 归零（P3-3 兑现；P3-2 bei_xi 随场景销毁自然解决）

## 范围外（移交后续任务）

- 嘴/身判定圈拆分（贪食副作用——观察项，学生改主意=范围变更升 v2）
- 死因统计/游戏时长/最高纪录/本局吃鱼数（结算页扩展，后续迭代）
- 血量规则改动（回血卡/护盾/伤害递增等——迭代内容）
- 局外永久解锁/元进度/存档（明确不做：纯局内肉鸽）
- 测试代码（tests/ 第 9 课建）
- Android 导出相关（第 10 课）

## 零触碰清单

- yu_npc.gd / yu_qun.gd / yu_zhong.gd / main.gd / jing_yan_ui.gd / qiang_hua_dan_chuang.gd
- QiangHuaDanChuang.tscn / Yu.tscn / YuNpc.tscn / project.godot（主场景仍 Main）/ data/**
- zhang_ben.gd 内既有方法与信号的语义（jia_jing_yan/xuan_ka/she_jing_yan_jia_cheng/dangqian_yuzhi 只加不改）
- yu.gd 内移动/判定/buff match/磁吸/动画结构

## 白名单要点

- 新增 4 生产文件（2 脚本各 + .uid、2 场景）+ 3 报告
- 修改 yu.gd / zhang_ben.gd / Main.tscn + 文档（词汇表 md/docx、路线图、索引、审计）
