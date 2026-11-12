> 最新完整版本：[R2.4](https://github.com/Rankf/FM27-Grok-R2/releases/tag/r2.4-test)。以下为历史版本说明。

# R2.1 安装器兼容性修订（测试版）

**现已提供完整安装包：** [FM27_Grok_26385295_R21_Test_NoHidden.zip](https://github.com/Rankf/FM27-Grok-R2/releases/download/r2.1-test/FM27_Grok_26385295_R21_Test_NoHidden.zip)。首次使用或升级都直接下载这一份，完整解压后运行 `Install.bat`。

目标仅为 Windows Steam Build **26385295**。界面资源与 R2 相同，不含隐藏属性补丁，尚未完成游戏内全面验证。

## 修复了什么

- 修复 R2 对本项目已核对的旧 Grok v2.0 文件识别不完整的问题，包括 `ui-datacollections_assets_all.bundle`。
- 已知旧 Grok 升级须确认该安装对应的实际 Steam Build 为26385295；不再只显示目标版本号。
- 一次输出全部异常，区分缺失文件与未知内容，显示 SHA-256，并导出 Diagnostics JSON 报告。
- 改进 Steam 多库定位；只检查兼容性不要求填写用户文档目录。

未知补丁、其他 Build 或平台仍不强行覆盖。文件时间戳无法单独证明是谁覆盖了文件。原版基础资源已在完整包 originals 目录，不应跨版本手动替换。

## 下载

- 推荐下载 `FM27_Grok_26385295_R21_Test_NoHidden.zip` 完整包，包含安装、备份与恢复所需资源，无需拼装旧版本。
- 完整包的校验文件为 `SHA256SUMS_R21_FULL.txt`；与此前制作并测试的本地完整包逐字节一致。
- 原安装器小补丁保留供历史使用；其校验文件 `SHA256SUMS_R21.txt` 不适用于完整包。

模拟目录测试已通过：旧 v2.0 固定／浮动版升级、重复安装、恢复、全部未知文件报告、缺失文件、错误 Build、无对应 Steam 清单时拒绝旧版升级、写入失败回滚。UI资源与R2逐字节一致。

如果仍失败，请提交诊断报告和旧补丁使用情况。通过安装检查不等于游戏内所有界面正常。原作者及贡献者署名保留在包内原版说明中。
