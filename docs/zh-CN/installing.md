# 为 Blade 安装 Razer 驱动程序

[English](../installing.md) | 简体中文 | [Русский](../ru-RU/installing.md)

先核对型号。以下两款 Blade 16 使用不同的 Razer 驱动程序包，不能混用。

| Blade 型号 | 内置 Razer 设备 | 驱动程序下载 |
| --- | --- | --- |
| 2026，RZ09-0581 | `1532:02E0` | [2026 驱动程序预发布版](https://github.com/OpenBladeProject/blade-driver-catalog/releases/tag/rz09-0581-1532-02e0-driver-stack-1.0.0.78-1.0.0.76) |
| 2025，RZ09-0528 | `1532:02C6` | [2025 驱动程序预发布版](https://github.com/OpenBladeProject/blade-driver-catalog/releases/tag/rz09-0528-1532-02c6-driver-stack-1.0.0.78-1.0.0.76) |

可以在 PowerShell 中查看 Windows 报告的型号：

```powershell
(Get-ItemProperty 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS').SystemProductName
```

如果型号与表中任何一行都不一致，不要使用这两个下载包。

<a id="install-through-razer-synapse"></a>
## 通过 Razer Synapse 安装

在 Blade 上安装 [Razer Synapse](https://www.razer.com/synapse-4) 并运行一次。Synapse 会为连接的笔记本电脑安装对应的 Razer 驱动程序栈。设置方法见 Razer 的[安装说明](https://mysupport.razer.com/app/answers/detail/a_id/1834/)。重新启动 OpenBlade 前先退出 Synapse。

OpenBlade 安装程序不会安装或删除 Razer 驱动程序。驱动程序不可用时，OpenBlade 会通过 WMI 调节亮度，并显示自己的浮动面板。

<a id="use-a-catalog-download"></a>
## 使用目录中的下载包

请从对应型号的发布页面下载 ZIP。GitHub 上的源代码 ZIP 不是驱动程序包。[2026 记录](../../releases/rz09-0581-02e0-1.0.0.78-1.0.0.76.json)或[2025 记录](../../releases/rz09-0528-02c6-1.0.0.78-1.0.0.76.json)列出了预期文件名和 SHA-256。解压前先用该哈希核对下载的 ZIP。

```powershell
Get-FileHash -LiteralPath 'path-to-the-driver-zip' -Algorithm SHA256
```

对于 2026 型号，核对笔记本电脑和压缩包后，按照[独立程序包安装步骤](installing-rz09-0581.md)操作。2025 目录还没有经过验证的独立安装步骤；该型号请使用 Synapse。

<a id="check-the-result"></a>
## 检查结果

两款型号都需要 OpenBlade 0.24.3 或更高版本才能使用原生 Windows 亮度。安装后，在设备管理器中检查内置 Razer 设备是否存在问题，然后重新启动 OpenBlade 并测试亮度键。**About > Device information** 中的 Razer 亮度驱动程序应显示 `Available · Windows OSD`，按亮度键时应显示 Windows 亮度浮动面板。每台笔记本电脑都必须使用与其型号匹配的驱动程序栈。
