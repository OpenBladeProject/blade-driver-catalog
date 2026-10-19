# THX 音频驱动组件

目录分别记录两套现代 THX 驱动和独立的旧版 2.6.5 证据。OpenBlade 必须根据准确的笔记本型号和音频硬件 ID 选择驱动。共用客户端或通用软件组件不能证明整套驱动通用。

| 型号 | 音频范围 | 安装状态 |
| --- | --- | --- |
| RZ09-0581 | [rznb12 4.2.41.2499](../../components/thx-rznb12/4.2.41.2499/stack.json)，配置版本 4.2.37.1846 | 已阻止：缺少基础 APO 安装程序。 |
| RZ09-0528 | [rznb11 4.2.29.1159](../../components/thx-rznb11/4.2.29.1159/stack.json)，配置版本 4.2.37.1845 | 有来源依据的全新安装候选；实机安装验证仍未完成。 |
| RZ09-0484 | [旧版 THX 2.6.5 证据](../../components/thx-legacy/2.6.5.0/stack.json) | 无法全新安装：已找到匹配该型号的 Realtek 编解码器驱动包，但仍缺少 OEM 子设备枚举配置和该型号的音频调校数据。 |
| RZ09-0483 | [旧版 THX 2.6.5 证据](../../components/thx-legacy/2.6.5.0/stack.json) | 无法全新安装：已找到匹配该型号的 Realtek 编解码器驱动包，但仍缺少 OEM 子设备枚举配置和该型号的音频调校数据。 |
| RZ09-0482 | [旧版 THX 2.6.5 证据](../../components/thx-legacy/2.6.5.0/stack.json) | 无法全新安装：已找到匹配该型号的 Realtek 编解码器驱动包，但仍缺少 OEM 子设备枚举配置和该型号的音频调校数据。 |
| RZ09-0530 | [rznb11 4.2.29.1159](../../components/thx-rznb11/4.2.29.1159/stack.json)，配置版本 4.2.37.1845 | 有来源依据的全新安装候选；实机安装验证仍未完成。 |
| RZ09-0328 | [准确型号规格](https://mysupport.razer.com/app/answers/detail/a_id/3641/)标明 Dolby Atmos | 不适用 THX。 |

每个现代条目记录原始下载链接、文件大小、SHA-256、数字签名，以及驱动文件和固定配置文件的校验值。目录只保存元数据，文件由 Razer 直接提供。

电脑还需要安装与硬件匹配的 Realtek 基础音频驱动；THX 安装包不包含该驱动。Razer 建议通过 [Windows 更新或系统恢复](https://mysupport.razer.com/app/answers/detail/a_id/3985)恢复音频驱动。rznb11 不能替代 rznb12。

旧版条目固定了 RZ09-0482、RZ09-0483 和 RZ09-0484 的准确 Realtek 编解码器 ID 和基础驱动包，以及四个已签名的 Windows 11 THX 2.6.5 组件 CAB：服务、HSA、配置和 APO。这些 THX 包只公开通用 `SWC\VEN_THX` ID，配置也是 `generic-config-fallback-V2`。目前没有准确的 OEM 子设备枚举和型号调音层，因此它们只是组件候选，并不是完整或可安装的驱动栈。

这些条目不表示可以覆盖或修复已有的 THX 驱动。安装程序返回成功也不能证明所有组件都已正确安装，OpenBlade 仍需独立检查驱动包、签名目录、配置和运行中的服务。用户设置和预设不属于固定配置校验的范围。

完整的来源证据和安装限制见[英文说明](../thx-audio-stacks.md)。新增型号时，必须更新[适用性记录](../../catalog/applicability.json)。
