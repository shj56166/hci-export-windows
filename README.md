# HCI Export for Windows

[中文](#中文) | [English](#english)

## 中文

一个用于 Windows 的小工具：通过 ADB 导出 Android `bugreport`，检查其中是否包含蓝牙 HCI 日志（通常为 `btsnoop_hci.log`）。适合把测试设备的蓝牙诊断日志交给开发或分析人员。

适用于支持 Android 蓝牙 HCI 日志和 ADB `bugreport` 的设备。

### 使用前准备

1. 解压本项目。项目已包含 Android SDK Platform-Tools 和 `adb.exe`，无需安装 Android Studio 或单独配置 ADB。
2. 在手机上开启开发者选项、USB 调试和“启用蓝牙 HCI 信息收集日志”（系统名称可能略有不同）。
3. 用支持数据传输的 USB 线连接手机，并在手机上允许 USB 调试授权。

### 导出步骤

1. 在手机上完成需要记录的蓝牙操作。
2. 双击 `run-export.cmd`。
3. 根据屏幕提示操作，导出时保持手机解锁且不要断开 USB。
4. 完成后，将项目根目录新生成的 `HCI日志-时间戳.zip` 发给分析人员。

导出文件还会保存在 `exports/` 下。这些文件可能含有设备信息和系统日志，请仅在获得设备使用者同意后分享，且不要提交到 GitHub。

### 常见问题

- **未发现设备或设备未授权**：检查 USB 调试、手机授权提示和数据线；运行 `adb devices` 可查看状态。
- **显示 offline**：重新插拔数据线，必要时关闭再开启 USB 调试。
- **没有 HCI 日志**：开启 HCI 日志后，关闭再打开蓝牙，重新完成测试流程再导出。
- **多台设备已连接**：请只保留一台目标设备。

## English

A small Windows utility that exports an Android `bugreport` through ADB and checks whether it contains a Bluetooth HCI log, usually `btsnoop_hci.log`. It is intended for collecting Bluetooth diagnostics from a test device.

It works with Android devices that support Bluetooth HCI logging and ADB `bugreport`.

### Before you start

1. Extract this project. It already includes Android SDK Platform-Tools and `adb.exe`; Android Studio and a separate ADB installation are not required.
2. On the phone, enable Developer options, USB debugging, and Bluetooth HCI logging.
3. Connect the phone with a data-capable USB cable and accept the USB debugging prompt.

### Export a log

1. Reproduce the Bluetooth activity you want to capture on the phone.
2. Double-click `run-export.cmd`.
3. Follow the prompts. Keep the phone unlocked and connected while the export runs.
4. Send the newly created `HCI日志-timestamp.zip` from the project root to the person analyzing the log.

The source `bugreport` and note are also stored under `exports/`. They can contain device details and system logs. Obtain consent before sharing them and never commit them to GitHub.

### Troubleshooting

- **No authorized device**: verify USB debugging, accept the phone prompt, and use a data-capable cable. Run `adb devices` to inspect the state.
- **Device is offline**: reconnect the cable and, if needed, toggle USB debugging.
- **No HCI log was found**: enable HCI logging, restart Bluetooth, reproduce the issue, then export again.
- **More than one device**: disconnect all but the target device.

## Project scope and license

This repository includes the launcher, PowerShell script, and Android SDK Platform-Tools required for offline use. It intentionally excludes generated logs.

The project source code is released under the [MIT License](LICENSE). See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for the separately distributed tools used by this project.

`Android` and `ADB` are trademarks of their respective owners. Their use here is descriptive only and does not imply endorsement.
