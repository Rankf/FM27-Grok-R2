# FM27 Grok R2.5.3 完整测试包

本版面向 Windows Steam Build 26620374，修复 R2.5.2 安装并通过 CRC 后，战术板球员头像依旧不显示的问题。

实际进入战术页后，`Player.log` 出现了 2,024 条 `Accessing invalid property`。根因是 R2.5.1 只迁移了元素的规则编号，没有迁移规则内部 `StyleValueHandle`：例如 `TacticsPositionCombined` 的新版样式数组只有 16 个尺寸值和 5 个枚举字符串，皮肤规则却仍引用旧索引 16–18 和 6。Unity 克隆头像卡片时读取越界，相关布局没有正常生成。

R2.5.3 完成以下修复：

- 按实际值重新定位每条皮肤规则内部的浮点、尺寸、颜色、字符串、资源和缩放图像句柄。
- 固定／浮动两套共扫描 14,698 张内联样式表、186,896 个受支持句柄，越界为 0。
- 两张早期 R2/R2.4 基础包中已经损坏、且父界面树未被皮肤修改的独立样式表恢复为 Build 26620374 官方版本。
- 保留 R2.5.2 的 Addressables CRC 修复；固定／浮动各自使用匹配的 `catalog.bin`。
- 安装器受控识别 R2.5.2 的旧 bundle 与旧目录，可以直接覆盖升级，无需先执行 Steam 验证。
- 保留 CA／CA+PA 可选显示、操作前备份、菜单 3 恢复和失败回滚。

20 项安装器回归流程全部通过，包括已发布 R2.5.2 固定／浮动版原地升级。2026-11-18 在 Build 26620374、固定侧栏 2560×1440 下实际进入同一存档战术页复验，球员头像恢复显示，`Player.log` 中 CRC 与 `Accessing invalid property` 均为 0。

完整解压并完全退出游戏后运行 `Install.bat`，选择菜单 1（固定侧栏）或菜单 2（浮动侧栏）。

[下载 R2.5.3 完整安装包](https://github.com/Rankf/FM27-Grok-R2/releases/download/r2.5.3-test/FM27_Grok_26620374_R253_Test_CA_Optional.zip)
