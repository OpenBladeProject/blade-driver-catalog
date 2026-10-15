# 在 RZ09-0581 上安装 Razer 亮度驱动程序

[English](../installing-rz09-0581.md) | 简体中文 | [Русский](../ru-RU/installing-rz09-0581.md)

以下独立安装步骤仅适用于[安装指南](installing.md)中列出的 Blade 16 RZ09-0581（`1532:02E0`）程序包。安装后，OpenBlade 可以使用 Windows 的亮度浮动面板。OpenBlade 安装程序不会安装或删除 Razer 驱动程序。驱动程序不可用时，亮度键通过 WMI 调节亮度，并显示 OpenBlade 自己的浮动面板。

<a id="package-details"></a>
## 程序包详情

| 硬件标识 | 驱动程序版本 |
| --- | --- |
| `1532:02E0` | RzDev `1.0.0.78`，RzCommon `1.0.0.76` |

Microsoft Windows SDK SignTool 已按内核模式策略验证全部五个目录签名，以及十个 INF 和 SYS 文件的目录成员关系。此程序包不适用于 RZ09-0528（`02C6`）或 Razer 外设。

<a id="install-through-synapse"></a>
## 通过 Synapse 安装

在笔记本电脑上安装并运行一次 [Razer Synapse](https://www.razer.com/synapse-4)，让它安装驱动程序栈。设置方法见 Razer 的[安装说明](https://mysupport.razer.com/app/answers/detail/a_id/1834/)。之后请先退出 Synapse，再重新启动 OpenBlade。如果要让 Synapse 继续管理其他设备，请按 [Synapse Blade Blocker 设置说明](https://github.com/OpenBladeProject/synapse-blade-blocker/blob/main/README.zh-CN.md)操作。按照[检查结果](#5-check-the-result)一节检查驱动程序状态。

<a id="1-download-the-standalone-package"></a>
## 1. 下载独立程序包

打开[驱动程序预发布版](https://github.com/OpenBladeProject/blade-driver-catalog/releases/tag/rz09-0581-1532-02e0-driver-stack-1.0.0.78-1.0.0.76)，从发布附件中下载 `Razer-02E0-Driver-Stack-1.0.0.78-1.0.0.76.zip`。源代码 ZIP 不是驱动程序包。

用[发布记录](../../releases/rz09-0581-02e0-1.0.0.78-1.0.0.76.json)核对压缩包名称和 SHA-256，用[目录清单](../../devices/rz09-0581/1532-02e0/1.0.0.78-1.0.0.76/manifest.json)核对程序包标识。把已验证的 ZIP 解压到一个新目录。下文的 `$packageRoot` 应指向该目录；目录中必须有五个程序包子目录。不要在 RZ09-0528 或其他型号上使用此程序包。

Windows 自带 PnPUtil，可把已签名程序包暂存到 Driver Store，并安装到匹配设备。Microsoft 的 [PnPUtil 命令参考](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-command-syntax)说明了 `/add-driver`、`/install`、`/subdirs` 和 `/reboot`。

此独立程序包尚未完成全新安装验证。下面的步骤只能在可以恢复的 RZ09-0581 上使用。驱动程序栈会在内置键盘和鼠标路径中安装筛选驱动、重新启动部分 USB 设备树，并且可能需要重新启动 Windows。测试时使用交流电源，连接外部 USB 键盘和鼠标，并预先确认恢复方式可用。

<a id="2-verify-the-laptop-and-package"></a>
## 2. 验证笔记本电脑和程序包

以管理员身份打开 PowerShell，安装前完成以下检查：

1. `HKLM:\HARDWARE\DESCRIPTION\System\BIOS` 报告的制造商必须是 Razer，`SystemProductName` 必须是 `Blade 16 - RZ09-0581`。
2. Windows 必须报告一个已连接的 `USB\VID_1532&PID_02E0&MI_01` 设备和一个已连接的 `USB\VID_1532&PID_02E0&MI_02` 设备。如果缺少、重复或出现不同标识，请停止。
3. ZIP 名称和 SHA-256 必须与已核对的发布证明一致。该证明还必须以仓库路径和 SHA-256 标识目录清单。解压后，每个文件都必须与 `SHA256SUMS.txt` 一致，所有 INF、CAT 和 SYS 签名必须有效，并由 Microsoft Windows Hardware Compatibility Publisher 签发。在安装了 SignTool 的验证计算机上，使用 `signtool verify /kp /c <catalog> <INF-or-SYS>` 证明目录成员关系。Microsoft 的 [SignTool 参考](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/signtool)说明了 `/c`。

<a id="3-record-the-current-drivers"></a>
## 3. 记录当前驱动程序

暂存任何文件前，在程序包和仓库之外创建日志。记录 BIOS 标识、已连接的匹配实例、`pnputil /enum-drivers /files` 的输出、当前绑定与设备栈，以及当前 `RZVIRTUAL` 和 `RZCONTROL` 树。保留原始输出，不要手写摘要。

下列辅助函数把每条 PnPUtil 命令、输出和退出代码追加到日志。先设置 `$packageRoot` 和 `$journalDirectory`。任何命令返回非零退出代码时，立即停止。结果不明确时不要重试。

```powershell
$packageRoot = Read-Host 'Full path to the extracted driver package'
$journalDirectory = Read-Host 'Full path to a new journal folder outside the package and repository'
$pnp = "$env:WINDIR\System32\pnputil.exe"
$transcript = Join-Path $journalDirectory 'pnputil-transcript.txt'
New-Item -ItemType Directory -Path $journalDirectory -ErrorAction Stop | Out-Null

function Invoke-PnpLogged {
    param([Parameter(Mandatory)][string[]]$Arguments)

    "`r`n> pnputil $($Arguments -join ' ')" |
        Out-File -LiteralPath $transcript -Append -Encoding utf8
    & $pnp @Arguments 2>&1 |
        Tee-Object -FilePath $transcript -Append
    $exitCode = $LASTEXITCODE
    "Exit code: $exitCode" |
        Out-File -LiteralPath $transcript -Append -Encoding utf8
    if ($exitCode -ne 0) {
        throw "PnPUtil failed with exit code $exitCode."
    }
}
```

<a id="4-stage-and-install-the-packages"></a>
## 4. 暂存并安装程序包

先暂存全部五个已签名程序包，不要绑定：

```powershell
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_vcon\rzdevu_02e0_vcon.inf")
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzcommonu\rzcommonu.inf")
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_dkm\rzdevu_02e0_dkm.inf")
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_kbd\rzdevu_02e0_kbd.inf")
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_mou\rzdevu_02e0_mou.inf")
```

每条命令完成后，把新报告的已发布名称和程序包标识复制到日志，并标记它是否已经存在于安装前清单中，以便回滚时识别本次测试新增的程序包。

五个程序包全部暂存成功后，按依赖顺序绑定：

```powershell
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_dkm\rzdevu_02e0_dkm.inf", '/install')
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_vcon\rzdevu_02e0_vcon.inf", '/install')
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_kbd\rzdevu_02e0_kbd.inf", '/install')
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_mou\rzdevu_02e0_mou.inf", '/install')
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzcommonu\rzcommonu.inf", '/install')
```

验证期间不要给这些命令添加 `/reboot`。如果 Windows 要求重新启动，请在日志安全保存后停止操作，再有计划地重新启动。PnPUtil 不会强制设备使用排名较低的驱动程序，因此退出代码为零不能代替安装后检查。

<a id="5-check-the-result"></a>
## 5. 检查结果

安装后，检查准确的 `RZVIRTUAL` 和 `RZCONTROL` 子项、其服务与设备栈，并确认设备管理器没有问题。重新启动 OpenBlade，打开 **About > Device information**。Razer 亮度驱动程序一行应显示 `Available · Windows OSD`。实际按下、按住再松开亮度键时，亮度必须改变，并显示 Windows 浮动面板。

<a id="roll-back-a-validation-attempt"></a>
## 回滚验证尝试

不要使用范围宽泛的设备删除、`/force` 或按设备类重新启动命令。回滚时，只能删除已保存的安装前日志能够证明由本次测试新增的已发布程序包。按以下顺序删除：RzCommon、VCon、mouse、keyboard、DKM。使用 `pnputil /delete-driver <journal-owned-oem.inf> /uninstall`；如果 Windows 报告程序包正在使用或要求重新启动，请停止。

<a id="technical-reference"></a>
## 技术参考

此步骤依据 OpenBlade 的 [Razer 亮度驱动程序指南](https://github.com/OpenBladeProject/openblade-core/blob/main/docs/zh-CN/razer-brightness-driver-package.md#native-windows-installation-path)。该指南还记录了发布一键安装程序前需要完成的检查。分发规则见[发布资源](release-assets.md)。
