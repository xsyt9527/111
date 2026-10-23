# TASK-006 代码评审（缺陷优先）

**结论：通过。** 无 P0/P1/P2 缺陷；4 条 P3 备忘（不阻塞，移交后续任务）。

## 评审范围

- scripts/qiang_hua_ka.gd、sheng_ji_biao.gd、qiang_hua_dan_chuang.gd（均新）
- data/qianghua/*.tres × 6、data/shengji/sheng_ji_biao.tres（新）
- scenes/QiangHuaDanChuang.tscn（新）、scenes/Main.tscn（实例化）
- scripts/zhang_ben.gd（阈值读表 + xuan_ka 接口两处）

## 正确性核对

- ✅ **唯一所有者纪律**：yi_xuan_ka 只在 zhang_ben.gd 内写入（xuan_ka 入口）；效果字段零消费（forbidden 边界守住）
- ✅ **暂停闭环**：paused=true 只在 _on_sheng_ji、paused=false 只在 _on_ka_dian，一开一合对称；弹窗 process_mode=3 保证冻结中可点击（探针 + 学生 F5 双验证）
- ✅ **抽样正确性**：duplicate 保护原表（连抽两次注册表仍 6 张）、shuffle 保证随机（学生实测两次组合不同）、slice(0,3) 无重复；注册表不足 3 张时 slice 自动截断不越界
- ✅ **信号生命周期**：弹窗 _ready 连 sheng_ji 一次、三按钮 pressed 各一次；实例常驻复用（visible 开关）无重复连接堆积——多次升级由全链路探针验证（两轮均正常）
- ✅ **等值切换**：sheng_ji_biao.tres 与旧常量逐项一致；dangqian_yuzhi() 读表路径两处（size/[-1]/[deng_ji-1]）全覆盖
- ✅ **零触碰清单**：yu.gd/jing_yan_ui.gd/yu_npc.gd/yu_qun.gd/yu_zhong.gd/main.gd/Yu.tscn/YuNpc.tscn/project.godot 无改动（scope check 佐证）
- ✅ **修复引入问题**：Node not found 修复后 $ 路径与场景节点树逐层核对一致（KaPianZu/Ka1/KaZhong1/MingCheng）

## P3 备忘（移交后续）

1. **xuan_guo 字符串无编译期校验**——.tres 里 xiao_guo 拼错第 7 课 switch 匹配不上、静默失效；第 7 课做效果映射时加 push_warning 兜底 + 第 9 课测试断言
2. **升级瞬间 sheng_ji 三家回调顺序**依赖连接顺序（玩家先连先长大、弹窗后连后弹出）——当前无顺序敏感逻辑；若第 7 课加入依赖升级前状态的 buff 需注意
3. **弹窗视觉是占位级**（PanelContainer 原生样式）——第 7 课 Tween 课时统一调优，可加卡片翻转入场
4. **满级后再升级**：dangqian_yuzhi 封顶但 sheng_ji 仍会发（deng_ji 继续涨）——弹窗满级后照常弹；第 7 课或第 8 课统一决策满级表现（与 TASK-005 P3 项合并跟踪）

## 范围遵守

- 白名单 20 文件全绿、0 违例；zhang_ben.gd 仅两处修改（读表 + xuan_ka），jia_jing_yan/旧信号/MEI_JI_TIXING 未动
- 强化效果零消费（第 7 课范围的边界守住）
