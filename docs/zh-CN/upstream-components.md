# 上游组件

[English](../upstream-components.md) | 简体中文 | [Русский](../ru-RU/upstream-components.md)

目录可以记录 OpenBlade 所需、由厂商直接托管的组件，同时不会把它当作
Driver Store 驱动包，也不会重新发布其专有文件。这类条目使用独立的
[`OpenBlade.RazerUpstreamComponentCatalogEntry`](../../schemas/upstream-component.schema.json)
架构。

## THX V4 Native 组件

[THX V4 Native 1.1.1.0 条目](../../components/thx-v4-native/1.1.1.0/component.json)
记录了准确的厂商网址、文件大小、SHA-256、Authenticode 签名者，以及当前
Synapse 清单中列出同一文件的三个 Razer 配置。目录不包含或发布该 DLL。

OpenBlade 可以提供厂商直链下载，但在使用文件前必须同时核对记录的
SHA-256 和 Authenticode 签名。该下载只提供独立 DLL，不会安装 APO 栈或
其他 THX 组件。

这些元数据只作为来源证据，并不证明安装或兼容性。精确设备准入、目标位置
处理、运行时验证和恢复行为由 OpenBlade core 负责。添加此条目的组件检测
工作记录在
[OpenBlade 问题 #808](https://github.com/OpenBladeProject/openblade-core/issues/808)。
