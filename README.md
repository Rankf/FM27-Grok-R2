# FM27 Grok R2.2 测试适配包

游戏更新不一定导致皮肤失效。R2.2 改为检查相关资源，不再仅因 Steam Build 不同而拒绝安装。

- Build 与制作基准 26385295 不同时先警告；相关资源全部匹配已识别状态，且样式一致，就允许安装。
- 未知、缺失或不匹配的资源仍停止操作，不提供跳过全部检查的强制覆盖。
- 旧 Grok v2.0 升级仍要求实际 Steam Build 为 26385295。
- 菜单 3 恢复还需确认实际 Build 为制作基准，或本安装器曾在同一 Build 下记录全部干净原版资源与本包一致。游戏再次更新后，旧记录失效。无法确认时使用 Steam 验证游戏文件完整性恢复当前官方资源。
- 菜单 4 只检查，输出警告、资源状态和是否可恢复，并生成 Diagnostics JSON 报告。

这是完整包，包含安装器、两种侧栏、皮肤和原版资源。无需先安装 R2 或 R2.1，也无需另打补丁。完整解压、退出游戏后运行 Install.bat：1 固定侧栏，2 浮动侧栏，3 卸载恢复，4 只检查。安装完成后重启游戏并选择 FM27_grok。

不含隐藏属性补丁，不修改游戏 DLL 或存档。界面资源与 R2 相同；原皮肤的隐藏按钮或列可能仍可见。

15 项隔离目录模拟测试通过，包括新版号下资源一致的安装／切换／恢复、旧恢复记录失效、未知资源拦截和写入失败回滚。模拟新版号不等于实际未来更新已验证；本包仍未完成游戏内全面测试。

原皮肤由 Kwon（권순태）制作，其他贡献者及许可见包内原版_README.txt。本项目为非官方适配。

## 下载与校验

[下载 R2.2 完整安装包](https://github.com/Rankf/FM27-Grok-R2/releases/download/r2.2-test/FM27_Grok_26385295_R22_Test_NoHidden.zip)。不要下载 GitHub 自动生成的 Source code ZIP。校验值见 [SHA256SUMS_R22_FULL.txt](SHA256SUMS_R22_FULL.txt)。

自动查找 Steam 安装目录；失败时输入包含 fm_Data 的目录。用户目录应为包含 games／skins 的实际文档目录，支持重定向文档目录。每次写入前备份；检查不会改动游戏文件。

校验失败不等于游戏损坏。先保存 Diagnostics 报告，核对实际 Build 和此前补丁；Steam 验证只能恢复当前官方资源，不能保证恢复为本包制作基准。不要仅凭文件时间戳判断来源，也不要手动添加未知哈希。

安装器源码见 [installer](installer)，模拟测试结果见 [r22-installer-tests.json](docs/r22-installer-tests.json)，基础资源来源核对见 [BASELINE_CHECK.md](docs/BASELINE_CHECK.md)。Xbox／Game Pass 等其他平台未验证。

## R2 界面修正

原皮肤将 `XGTableTile_8x4` 资源改造成浮动侧栏。首个测试适配包误保留了原版表格，导致侧栏展开后出现 XG TABLE。R2 恢复了完整侧栏，并迁移正式版新增字段。

已检查侧栏 24 个菜单项、208 个托管引用、展开按钮的目标资源与内联样式引用。

## 验证与限制

- 资源封装与读回校验通过。
- 在模拟目录中测试了安装、重复安装、侧栏切换、卸载、未知资源拒绝和写入失败后的回滚。
- 安装器保持游戏 DLL 原样。
- 2026-11-11：7 个基础资源与目标 Build 对应的本机 Steam 缓存下载清单逐项核对通过；这不是其他平台或后续版本的兼容认证。
- **上述检查不等于游戏内实测。** 需要检查侧栏、球员及职员页、俱乐部历史、战术、比赛和存档载入。
- 战术角色详细／简化说明及比赛 `OverviewHeader` 保留正式版对象，与原皮肤可能存在差异。
- 未移植旧安装器的韩文字体加粗、主菜单背景和自定义背景开关。

每次操作前会在游戏目录的 `FM27_Grok_26385295_Backups` 中保存相关文件。游戏更新后先运行菜单 4；资源匹配可继续安装，但不代表游戏内已经实测。恢复需通过独立检查；不要手动跨版本写回旧资源。

## 反馈

请在 [Issues](https://github.com/Rankf/FM27-Grok-R2/issues) 中提供：

- 游戏平台及**实际 Steam Build ID**，不是安装器标题显示的数字。
- 安装包版本、选择的菜单项，以及完整报错文件名和文字。
- 之前安装过的皮肤／比赛界面补丁，是否已验证游戏完整性。
- 校验失败时，提供对应文件的 **SHA-256**。
- R2.2 用户优先附上 `Diagnostics/compatibility_*.json` 报告，其中已包含上述版本和资源信息。
- 如果安装成功但显示异常，提供侧栏类型、游戏分辨率、Windows 缩放比例、复现步骤及截图。

**查 Build ID：** 在该游戏所属 Steam 库的 `steamapps/appmanifest_4530370.acf` 中，用记事本查找 `"buildid"`，只需提供这一行。

**查报错文件 SHA-256：** 打开 PowerShell，将下面路径改成自己的实际游戏目录后执行。这条命令只读取文件，不修改游戏。

```powershell
$game = 'D:\SteamLibrary\steamapps\common\Football Manager 27'
Get-FileHash -LiteralPath "$game\fm_Data\StreamingAssets\aa\StandaloneWindows64\ui-visualtreeassets_assets_matchvisualtreeassetpreload.bundle" -Algorithm SHA256 | Format-List Hash
```

如果报错的是其他文件，请相应替换文件名。不要提交完整存档或账号凭据。

## 原作者与署名

原皮肤由 Kwon（권순태）制作，其他贡献者详见安装包内 `原版_README.txt`。本项目是非官方适配，不代表原作者或游戏开发商。第三方资源的权利与许可仍归各自权利人；本仓库不为这些资源另行授予开源许可。
