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

## 审核全部受支持型号

[`catalog/applicability.json`](../../catalog/applicability.json) 记录 OpenBlade
全部七个型号，以及每个目录条目对每个型号的审核结论。`Applicable` 表示来源
支持其适用范围；`NotEstablished` 表示证据不足，并不表示不兼容。这些状态不
授予安装或运行时设备控制权限。

2026-10-19 的审核确认 RZ09-0530、RZ09-0528 和 RZ09-0581 的清单包含
THX V4 Native 1.1.1.0；RZ09-0328、RZ09-0482、RZ09-0483 和 RZ09-0484
的已审核清单没有 THX native 资源。现有证据不支持通用 THX 包的说法。
两个驱动栈仍分别限定到各自 PID；相同的 RzCommon 文件和通用子设备匹配项
不代表整个驱动栈通用。

core 新增或更改型号时，必须审核全部驱动栈和组件，更新此记录中固定的 core
版本、型号列表和每条审核结论，再更新组件 `applicableProfiles` 及 core 测试
中的固定副本，并运行两个仓库的测试。新目录条目也必须覆盖所有型号。
core 的型号覆盖检查应在审核与副本更新完成前失败；目录测试会拒绝缺失的
审核结论及适用范围不一致的条目。

## THX 音频驱动组件

[THX 驱动目录](thx-audio-stacks.md)覆盖全部七个受支持型号：准确的 rznb11 和 rznb12 驱动、三个 2023 THX 型号被阻止的旧版 2.6.5 组件候选，以及仅支持 Dolby 的 RZ09-0328。旧版候选缺少准确的 OEM 子设备枚举和型号调音，不能安装；rznb12 仍缺少基础安装程序。
