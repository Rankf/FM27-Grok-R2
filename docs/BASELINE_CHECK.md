# 基础资源校验记录

核对日期：2026-11-11；更新复核：2026-11-12。

为确认制作 R2 时是否误将本机补丁文件当成原版，读取了目标游戏安装记录指向的 Steam 缓存下载清单，将安装包 `originals` 中的7个基础资源与清单逐项比较。

| 项目 | 值 |
| --- | --- |
| Steam Build | 26385295 |
| Depot | 4530372 |
| Manifest | 1558728990731412600 |
| 比较方式 | 清单的文件内容 SHA-1 与基础文件实际 SHA-1 |
| 结果 | 7/7 匹配 |

完整逐文件结果见 [baseline-audit.json](baseline-audit.json)。该记录不包含用户路径或账号信息。

Steam Build 26577676 使用 Depot 4530372、Manifest 8851588544192734460。再次核对后，7 个 UI 基础资源的 Steam SHA-1 与旧基准逐项相同，结果仍为 7/7 匹配。详见 [baseline-audit-build26577676.json](baseline-audit-build26577676.json)。

这里的 SHA-1 用于与 Steam 下载清单中的字段比较；安装器使用 SHA-256 检查游戏文件，两者用途不同。

## 结论范围

- 这7份基础资源与所核对的目标 Steam 清单一致；不是仅属于制作电脑的任意修改版本。
- 已收到报错反馈的 `ui-visualtreeassets_assets_matchvisualtreeassetpreload.bundle` 也匹配该清单。
- 这不能证明反馈者使用相同 Build、同一平台或未修改的文件，也不能证明所有游戏内功能已正常运行。
- 对未知文件需要取得实际 Build ID 和 SHA-256 后再分析，不应将未知校验值直接加入白名单。
- 此次核对不包含对所有旧皮肤版本的升级测试，也未覆盖其他 Build 或平台。
