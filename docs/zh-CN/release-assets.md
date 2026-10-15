<a id="release-assets-and-repository-boundaries"></a>

# 发布附件与仓库边界

[English](../release-assets.md) | 简体中文 | [Русский](../ru-RU/release-assets.md)

<a id="what-belongs-in-git"></a>

## Git 中可包含的内容

Git 只包含元数据和工具。
INF、CAT、SYS、PNF、ZIP 及其他专有包文件均被忽略，绝不能提交。
完整设备身份和本地清单也必须保存在仓库之外。

收集期间创建的私密证据归档绝不能成为发布附件。
其中包含完整设备身份、本地清单和其他机器特定证据。
私密收集流程和脱敏清单允许包含的字段见[导出指南](exporting.md)。

<a id="publishing-a-package-archive"></a>

## 发布包归档

发布归档前，请阅读 [THIRD-PARTY-NOTICES.md](../../THIRD-PARTY-NOTICES.md)。
书面授权必须涵盖精确文件、版本、受众和交付方式。

只有型号专用导出器和目录清单经过审核后，才可将纯包归档附到版本发布。
导出器必须只复制已准入文件、验证其固定哈希和签名者身份、
移除私密清单和机器本地别名，并包含必需的第三方声明。

项目所有者报告，已取得 Razer US Ltd 的书面授权，覆盖两份预发布的文件、受众和交付方式。
本目录不声称该授权文件已获独立审核。
Apache-2.0 仅适用于仓库原创内容，不授予 Razer 包字节或专有发布附件的任何权利。

<a id="prerelease-records"></a>

## 预发布记录

[2026 款 Blade 16](../../releases/rz09-0581-02e0-1.0.0.78-1.0.0.76.json)
和 [2025 款 Blade 16](../../releases/rz09-0528-02c6-1.0.0.78-1.0.0.76.json)
经核查的记录，将各目录清单与发布附件绑定。
两者均记录导出器版本和脚本哈希。

发布受众的任何变化，都要求在已记录授权范围内另行作出分发决定。

2026 包记录的导出器提交通过 2026 年 8 月 15 日合并的
[OpenBlade 核心 PR #163](https://github.com/OpenBladeProject/openblade-core/pull/163)
可从核心 `main` 到达。其 Git blob 和 SHA-256 匹配所记录脚本。
记录保留原始导出版本，状态为 `MergedCommit`。
2025 包使用[目录 PR #15](https://github.com/OpenBladeProject/blade-driver-catalog/pull/15)
中合并的型号专用导出器。

<a id="openblade-repository-responsibilities"></a>

## OpenBlade 各仓库的职责

- [`openblade-core`](https://github.com/OpenBladeProject/openblade-core/blob/main/README.zh-CN.md)
  负责运行时准入、精确设备检查、回退行为和经验证的安装策略。
- [`openblade-captures`](https://github.com/OpenBladeProject/openblade-captures/blob/main/README.zh-CN.md)
  负责协议采集和硬件行为证据。
- 本仓库负责驱动包清单、只读导出说明、脱敏清单，以及所记录授权覆盖的发布附件。

OpenBlade 核心接受运行时或安装结论前，审核者必须确认包拓扑。
物理验证、驱动宿主重启、系统重启、睡眠、全新安装、回滚和生产准入仍是独立检查。
