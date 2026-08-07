$ErrorActionPreference = 'Stop'

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$localAdb = Join-Path $scriptDir 'platform-tools\adb.exe'
$adb = $null

function Pause-And-Exit($code) {
  Write-Host ''
  Read-Host '按回车退出'
  exit $code
}

if (Test-Path -LiteralPath $localAdb) {
  $adb = $localAdb
} else {
  $cmd = Get-Command adb -ErrorAction SilentlyContinue
  if ($cmd) {
    $adb = $cmd.Source
  }
}

function Run-Adb([string[]]$arguments) {
  & $adb @arguments
  if ($LASTEXITCODE -ne 0) {
    throw "adb 命令失败：adb $($arguments -join ' ')"
  }
}

trap {
  Write-Host ''
  Write-Host '发生未预期错误：'
  Write-Host $_.Exception.Message
  Write-Host ''
  Write-Host '常见处理：重新连接手机，在手机上允许 USB 调试授权，然后重新运行本工具。'
  Pause-And-Exit 1
}

Write-Host '=== Android 蓝牙 HCI 日志一键导出 ==='
Write-Host ''

if (-not $adb) {
  Write-Host '未找到 adb.exe。'
  Write-Host '离线包处理方式：请确认本工具旁边存在 platform-tools\adb.exe。'
  Write-Host '高级处理方式：安装 Android Platform Tools，并把 adb 加入 PATH。'
  Pause-And-Exit 1
}

if (Test-Path -LiteralPath $localAdb) {
  $adbDir = Split-Path -Parent $localAdb
  $missingAdbFiles = @('AdbWinApi.dll', 'AdbWinUsbApi.dll') | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $adbDir $_))
  }
  if ($missingAdbFiles.Count -gt 0) {
    Write-Host '本地 platform-tools 不完整，缺少文件：'
    $missingAdbFiles | ForEach-Object { Write-Host "  $_" }
    Write-Host '请使用完整离线包，或重新复制完整 platform-tools 文件夹。'
    Pause-And-Exit 1
  }
}

Write-Host "使用 ADB：$adb"
Write-Host ''

Write-Host '正在检查设备连接...'
$devicesOutput = & $adb devices
if ($LASTEXITCODE -ne 0) {
  Write-Host 'adb devices 执行失败。'
  Write-Host '请重新连接手机，或更换 USB 数据线/USB 口后重试。'
  Pause-And-Exit 1
}

$deviceLines = $devicesOutput | Where-Object { $_ -match "`t" }
$readyDevices = $deviceLines | Where-Object { $_ -match "`tdevice$" }
$unauthorizedDevices = $deviceLines | Where-Object { $_ -match "`tunauthorized$" }
$offlineDevices = $deviceLines | Where-Object { $_ -match "`toffline$" }

if ($unauthorizedDevices.Count -gt 0) {
  Write-Host '检测到手机已连接，但 USB 调试尚未授权。'
  Write-Host '请解锁手机，在弹窗中允许 USB 调试授权，然后重新运行本工具。'
  $unauthorizedDevices | ForEach-Object { Write-Host $_ }
  Pause-And-Exit 1
}

if ($offlineDevices.Count -gt 0) {
  Write-Host '检测到手机已连接，但 ADB 状态为 offline。'
  Write-Host '请拔插数据线，必要时关闭再打开 USB 调试，并重新允许授权。'
  $offlineDevices | ForEach-Object { Write-Host $_ }
  Pause-And-Exit 1
}

if ($readyDevices.Count -eq 0) {
  Write-Host '没有检测到已授权的 Android 设备。'
  Write-Host '请检查：'
  Write-Host '1. 手机已开启开发者选项。'
  Write-Host '2. 手机已开启 USB 调试。'
  Write-Host '3. 手机弹出的 USB 调试授权已点允许。'
  Write-Host '4. 数据线支持数据传输，不是纯充电线。'
  Write-Host '5. 如果 Windows 完全识别不到设备，请检查 Android USB 驱动。'
  Write-Host ''
  Write-Host 'adb devices 输出：'
  $devicesOutput | ForEach-Object { Write-Host $_ }
  Pause-And-Exit 1
}

if ($readyDevices.Count -gt 1) {
  Write-Host '检测到多台已授权 Android 设备。'
  Write-Host '请只保留一台测试手机连接，然后重新运行本工具。'
  $readyDevices | ForEach-Object { Write-Host $_ }
  Pause-And-Exit 1
}

$deviceId = ($readyDevices[0] -split "`t")[0]
Write-Host "已连接设备：$deviceId"
Write-Host ''

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$exportRoot = Join-Path $scriptDir 'exports'
$exportDir = Join-Path $exportRoot "hci-$stamp"
New-Item -ItemType Directory -Force -Path $exportDir | Out-Null

$driveRoot = [System.IO.Path]::GetPathRoot($exportDir)
$driveName = ($driveRoot -replace '[:\\]', '')
$driveInfo = Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue
if ($driveInfo -and $driveInfo.Free -lt 1GB) {
  Write-Host '电脑磁盘空间不足，无法稳定导出 bugreport。'
  Write-Host '请保证本工具所在磁盘至少剩余 1 GB 空间。'
  Write-Host ("当前剩余空间：{0:N0} MB" -f ($driveInfo.Free / 1MB))
  Pause-And-Exit 1
}

$bugreportPath = Join-Path $exportDir 'bugreport.zip'
$notePath = Join-Path $exportDir 'export-note.txt'
$finalPackagePath = Join-Path $scriptDir "HCI日志-$stamp.zip"

Write-Host '请先完成蓝牙测试流程，例如：'
Write-Host '1. 打开 App 或小程序。'
Write-Host '2. 连接控制器或 BMS。'
Write-Host '3. 停留在目标页面，并按测试要求操作车辆。'
Write-Host '4. 断开连接或结束测试。'
Write-Host ''
Read-Host '完成后按回车开始导出 bugreport'

Write-Host ''
Write-Host '正在导出 bugreport，可能需要 2 到 5 分钟...'
try {
  Run-Adb @('bugreport', $bugreportPath)
} catch {
  Write-Host ''
  Write-Host 'bugreport 导出失败。'
  Write-Host $_.Exception.Message
  Write-Host ''
  Write-Host '常见处理：'
  Write-Host '1. 导出期间保持手机解锁。'
  Write-Host '2. 重新连接 USB，并重新允许 USB 调试授权。'
  Write-Host '3. 确认电脑磁盘空间充足。'
  Write-Host '4. 如果使用无线调试，请确认手机和电脑在同一网络且连接稳定。'
  Pause-And-Exit 1
}

$actualZip = Get-ChildItem -LiteralPath $exportDir -Filter '*.zip' -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $actualZip) {
  Write-Host '导出命令结束，但没有找到 zip 文件。'
  Pause-And-Exit 1
}

Write-Host ''
Write-Host "导出文件：$($actualZip.FullName)"

$snoopMatches = @()
try {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $archive = [System.IO.Compression.ZipFile]::OpenRead($actualZip.FullName)
  try {
    $snoopMatches = @(
      $archive.Entries |
        Where-Object { $_.FullName -match 'btsnoop_hci\.log$|bluetooth.*snoop|snoop.*\.log$' } |
        Select-Object -ExpandProperty FullName
    )
  } finally {
    $archive.Dispose()
  }
} catch {
  Write-Host "检查 zip 内容失败：$($_.Exception.Message)"
}

$note = @()
$note += 'Android 蓝牙 HCI 日志导出说明'
$note += ''
$note += "导出时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$note += "设备 ID：$deviceId"
$note += "Bugreport：$($actualZip.Name)"
$note += ''

if ($snoopMatches.Count -gt 0) {
  Write-Host ''
  Write-Host '已在 bugreport 中找到疑似 HCI 日志：'
  $snoopMatches | ForEach-Object { Write-Host $_ }
  $note += '已找到疑似 HCI 日志：'
  $note += $snoopMatches
  $exportSucceeded = $true
} else {
  Write-Host ''
  Write-Host '没有在 bugreport 中找到 btsnoop_hci.log。'
  Write-Host '导出已完成，但缺少 BLE 分析需要的 HCI 日志。'
  Write-Host '请在手机上开启“蓝牙 HCI 信息收集日志”，重启蓝牙，重新完成测试流程后再导出。'
  $note += '没有在 bugreport 中找到 btsnoop_hci.log。'
  $note += '请开启蓝牙 HCI 日志，重启蓝牙，重新完成测试流程后再导出。'
  $exportSucceeded = $false
}

$note += ''
$note += '请把本工具生成的 HCI日志-时间戳.zip 发回分析。'
Set-Content -LiteralPath $notePath -Value $note -Encoding UTF8

Write-Host ''
Write-Host "说明文件：$notePath"
Write-Host ''

if (Test-Path -LiteralPath $finalPackagePath) {
  Remove-Item -LiteralPath $finalPackagePath -Force
}

try {
  Compress-Archive -LiteralPath $exportDir -DestinationPath $finalPackagePath -Force
  Write-Host "已打包：$finalPackagePath"
} catch {
  Write-Host "打包 HCI 日志 zip 失败：$($_.Exception.Message)"
  Write-Host '请改为发送上面导出目录中的 bugreport.zip 和 export-note.txt。'
  Pause-And-Exit 1
}

if ($exportSucceeded) {
  Write-Host '完成。请把上面的 HCI日志 zip 文件发回。'
  Pause-And-Exit 0
}

Write-Host '由于没有找到 HCI 日志，需要重新导出。'
Write-Host '当前生成的 HCI日志 zip 已保留，但通常不能用于 BLE 协议分析。'
Pause-And-Exit 2
