# Blade 驱动程序目录

[English](README.md) | 简体中文 | [Русский](README.ru-RU.md)

查找与你的 Blade 型号匹配的 Razer 驱动程序包。每个条目都注明驱动包的来源设备，并说明如何核对文件。

OpenBlade 是独立于 Razer 的项目。这里保留的原始签名驱动文件未经修改。

<a id="blade-models"></a>
## Blade 型号

请核对笔记本电脑的型号，再选择对应的驱动。

| 型号 | 驱动程序详情 | 下载 |
| --- | --- | --- |
| Blade 16 (2026)，RZ09-0581 | [Razer 02E0 驱动程序栈](devices/rz09-0581/1532-02e0/1.0.0.78-1.0.0.76/manifest.json) | [预发布版下载](https://github.com/OpenBladeProject/blade-driver-catalog/releases/tag/rz09-0581-1532-02e0-driver-stack-1.0.0.78-1.0.0.76) |
| Blade 16 (2025)，RZ09-0528 | [Razer 02C6 驱动程序栈](devices/rz09-0528/1532-02c6/1.0.0.78-1.0.0.76/manifest.json) | [预发布版下载](https://github.com/OpenBladeProject/blade-driver-catalog/releases/tag/rz09-0528-1532-02c6-driver-stack-1.0.0.78-1.0.0.76) |

请按照与你的型号对应的[安装指南](docs/zh-CN/installing.md)操作。

<a id="upstream-components"></a>
## 上游组件

OpenBlade 可以直接使用 Razer 提供的部分独立组件，而无需重新发布这些文件。
[上游组件目录](docs/zh-CN/upstream-components.md)记录了准确的适用型号、哈希、
签名者信息和厂商下载链接。

<a id="add-your-blade"></a>
## 添加你的 Blade

目录中没有你的型号？[驱动程序导出指南](docs/zh-CN/exporting.md)说明如何收集已安装的驱动程序包。提交型号和文件详情时，请使用[证据模板](templates/driver-stack-evidence.template.json)。提交内容中不得包含驱动程序文件或个人设备详情。

[发布资源和仓库边界](docs/zh-CN/release-assets.md)说明我们如何提供驱动程序下载。

<a id="license"></a>
## 许可证

本仓库中的文字和工具使用 [Apache License 2.0](LICENSE)。Razer 驱动程序文件归 Razer 所有。详情见 [NOTICE](NOTICE) 和 [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)。

<a id="run-the-checks"></a>
## 运行检查

在 Windows 上运行：

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -NoProfile -NonInteractive -ExecutionPolicy Bypass `
    -File .\tests\Run-All.ps1
```
