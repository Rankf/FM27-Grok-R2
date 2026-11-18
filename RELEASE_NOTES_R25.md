# FM27 Grok R2.5 完整测试包

> 此版本存在内联样式索引迁移缺陷，可能导致固定侧栏不显示。请改用 [R2.5.1 完整修正版](https://github.com/Rankf/FM27-Grok-R2/releases/tag/r2.5.1-test)，可直接覆盖升级。

本版面向 Windows Steam Build 26620374。该更新实际修改了全部 7 个相关 UI bundle、样式 bundle 和 game_plugin.dll，不能通过增加 Hash 白名单解决。

R2.5 完成以下适配：

- 将 Grok 的固定／浮动侧栏和界面改动三方合并到新版官方对象。
- 保留新版官方新增对象、字段和样式；处理新字段 `SquashToFit`。
- 为皮肤新增托管引用重新分配无冲突编号，并验证没有重复或悬空引用。
- 保留 CA/PA 的代码结构识别；新 DLL 无需硬编码新地址即可识别。
- DLL 被临时占用时自动重试；持续占用时给出中文提示并回滚。
- 菜单 5 只显示真实 CA；菜单 6 显示 CA+PA；菜单 7 恢复相关原始显示指令。

Build 26620374 的 7 个 UI 基础资源及样式资源已与 Steam Depot Manifest 957775974696034630 核对，8/8 匹配。已完成 25 项隔离检查；文件与结构检查不等于游戏内全面实测。

完整解压并退出游戏后运行 Install.bat。旧 R2.4 不适用于 Build 26620374。

[下载完整安装包](https://github.com/Rankf/FM27-Grok-R2/releases/download/r2.5-test/FM27_Grok_26620374_R25_Test_CA_Optional.zip)
