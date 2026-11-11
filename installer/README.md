# 安装器源文件

R2.2 安装器必须配合完整包 bundles、originals、skins 使用；单独克隆仓库不能安装。

Build 不同只警告，相关资源及样式必须匹配。legacyGrokV2 分支仍要求对应 Steam 清单确认实际 Build 为 26385295。未知资源不放行。

恢复要求实际 Build 等于制作基准，或 FM27_Grok_InstallState.json 记录本安装器在同一 Build 见过全部匹配的干净原版资源。Build 再次变化使记录失效；没有证据时使用 Steam 验证恢复。

Diagnostics 报告包含警告、资源判定与 canRestore。安装前备份，写入失败尝试回滚。不修改 DLL 或存档。
