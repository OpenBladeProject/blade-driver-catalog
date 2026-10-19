# Upstream components

English | [简体中文](zh-CN/upstream-components.md) | [Русский](ru-RU/upstream-components.md)

The catalog can record a vendor-hosted component that OpenBlade needs without
turning it into a Driver Store package or republishing the proprietary file.
These entries use the separate
[`OpenBlade.RazerUpstreamComponentCatalogEntry`](../schemas/upstream-component.schema.json)
schema.

## THX V4 Native component

The [THX V4 Native 1.1.1.0 entry](../components/thx-v4-native/1.1.1.0/component.json)
records the exact vendor URL, file size, SHA-256, Authenticode signer, and the
three exact Razer profiles whose current Synapse manifests name the same file.
The catalog does not contain or publish the DLL.

OpenBlade may offer the vendor URL as a direct download. It must verify both
the recorded SHA-256 and Authenticode signature before using the file. The
download provides only the standalone DLL; it does not install an APO stack or
other THX components.

The metadata is source evidence, not an installation or compatibility claim.
OpenBlade core owns exact-device admission, destination handling, runtime
validation, and recovery behavior. See
[OpenBlade issue #808](https://github.com/OpenBladeProject/openblade-core/issues/808),
which motivated the component-detection work and this entry.
