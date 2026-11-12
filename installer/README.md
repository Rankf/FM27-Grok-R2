# 安装器源文件

R2.3 安装器必须配合完整包 bundles、originals、skins 使用；单独克隆仓库不能安装。

Build 不同只警告，相关资源及样式必须匹配。legacyGrokV2 分支仍要求对应 Steam 清单确认实际 Build 为 26385295。未知资源不放行。

恢复要求实际 Build 等于制作基准，或 FM27_Grok_InstallState.json 记录本安装器在同一 Build 见过全部匹配的干净原版资源。Build 再次变化使记录失效；没有证据时使用 Steam 验证恢复。

菜单 5 只启用真实 CA，菜单 6 启用 CA+PA，菜单 7 恢复原版 DLL。它们只支持 manifest 中完整哈希和代码特征均匹配的 Windows Steam 正式版 DLL。写入先在副本中完成并验证，再替换原文件；失败会回滚。该功能不依赖游戏内修改器，不改变存档或球员数值。

Diagnostics 报告包含警告、资源判定、canRestore 及 DLL 状态。皮肤资源写入前备份，写入失败尝试回滚。
