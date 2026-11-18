# FM27 Grok R2.5.2 完整测试包

本版面向 Windows Steam Build 26620374，修复战术板球员头像、侧栏及其他 Grok 界面元素仍不显示的问题。

根因已由 FM 的 `Player.log` 确认：R2.5／R2.5.1 的 UI bundle 内容已经修改，但游戏的 Addressables `catalog.bin` 仍记录官方原版 CRC。Unity 对解压后的 bundle 内容重新计算 CRC 后发现不一致，记录 `CRC Mismatch` 并拒绝加载整包。因此文件 SHA-256、资源树和皮肤选择即使都正确，游戏运行时仍看不到其中的头像与侧栏。

R2.5.2 完成以下修复：

- 按 Unity 实际使用的“解压内容 CRC-32”计算固定／浮动两组资源的 CRC。
- 为两种侧栏分别生成匹配的 `catalog.bin`，同步 7 个修改包的 CRC 和实际大小。
- 安装器将目录文件纳入兼容检查、包内校验、操作前备份、变体切换、菜单 3 恢复及失败回滚。
- 遇到未知或被其他补丁修改的目录文件时停止，不会盲目覆盖。
- 保留 R2.5.1 的内联样式索引修复、Build 兼容策略、CA／CA+PA 可选显示和 DLL 占用重试。

18 项安装器回归流程全部通过。2026-11-18 在 Build 26620374 上实际启动 FM 至主窗口复验，原先 6 条 `CRC Mismatch / Will not load AssetBundle` 全部消失，`StyleSheet.CheckAccess / invalid property` 也未再出现。战术页等具体页面仍建议用户进入存档人工检查。

完整解压并完全退出游戏后运行 `Install.bat`，选择菜单 1（固定侧栏）或菜单 2（浮动侧栏）。已安装 R2.5／R2.5.1 的用户可直接覆盖升级，不需要先验证游戏文件。

[下载 R2.5.2 完整安装包](https://github.com/Rankf/FM27-Grok-R2/releases/download/r2.5.2-test/FM27_Grok_26620374_R252_Test_CA_Optional.zip)
