# R2.1 安装器兼容性修订（测试版）

目标仅为 Windows Steam Build **26385295**。界面资源与 R2 相同，不含隐藏属性补丁，尚未完成游戏内全面验证。

## 修复了什么

- 修复 R2 对本项目已核对的旧 Grok v2.0 文件识别不完整的问题，包括 `ui-datacollections_assets_all.bundle`。
- 已知旧 Grok 升级须确认该安装对应的实际 Steam Build 为26385295；不再只显示目标版本号。
- 一次输出全部异常，区分缺失文件与未知内容，显示 SHA-256，并导出 Diagnostics JSON 报告。
- 改进 Steam 多库定位；只检查兼容性不要求填写用户文档目录。

未知补丁、其他 Build 或平台仍不强行覆盖。文件时间戳无法单独证明是谁覆盖了文件。原版基础资源已在完整包 originals 目录，不应跨版本手动替换。

## 下载

- **首次使用：** 先下载 [R2 完整包](https://github.com/Rankf/FM27-Grok-R2/releases/download/r2-test/FM27_Grok_26385295_R2_Test_NoHidden.zip)并解压，再应用本页的小补丁。R2.1 的界面资源完全相同，因此以小补丁形式分发。
- **已有 R2 完整目录：** 下载小补丁 `FM27_Grok_R21_Installer_Update.zip`，把 install.ps1 和 manifest.json 覆盖到 Install.bat 同级目录，然后再次选4检查。小补丁不能独立运行。

模拟目录测试已通过：旧 v2.0 固定／浮动版升级、重复安装、恢复、全部未知文件报告、缺失文件、错误 Build、无对应 Steam 清单时拒绝旧版升级、写入失败回滚。UI资源与R2逐字节一致。

如果仍失败，请提交诊断报告和旧补丁使用情况。通过安装检查不等于游戏内所有界面正常。原作者及贡献者署名保留在包内原版说明中。
