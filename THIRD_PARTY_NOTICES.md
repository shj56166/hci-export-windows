# Third-party tools / 第三方工具说明

## Android SDK Platform-Tools (ADB)

This project invokes `adb`, supplied by **Android SDK Platform-Tools**. The complete upstream `platform-tools` directory is bundled so the tool can run after extraction without a separate ADB installation.

- Official download: <https://developer.android.com/tools/releases/platform-tools>
- Upstream package observed while preparing this project: `37.0.0`
- License notices: the upstream package includes `NOTICE.txt`, including Apache License 2.0 notices and other third-party notices.

The bundled files retain the upstream `NOTICE.txt`. Comply with Google's terms and the notices supplied with that package. The separate MIT license for this repository does not change the license of Android SDK Platform-Tools.

---

本项目通过 **Android SDK Platform-Tools** 提供的 `adb` 工作。仓库已包含完整的上游 `platform-tools` 目录，因此解压后无需另行安装或配置 ADB。

- 官方下载：<https://developer.android.com/tools/releases/platform-tools>
- 整理本项目时发现的上游版本：`37.0.0`
- 许可证说明：上游安装包包含 `NOTICE.txt`，其中含 Apache License 2.0 及其他第三方声明。

随附文件保留上游 `NOTICE.txt`。请遵守 Google 条款及安装包中的许可证声明。本仓库的 MIT 许可证不适用于 Android SDK Platform-Tools。
