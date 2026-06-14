# ============================================================
#  MT4 技术指标 — 自动安装脚本
#  将全套无未来函数指标安装到 MetaTrader 4 软件中
# ============================================================
#  使用方法:
#    .\install_to_mt4.ps1              # 自动检测 MT4 并交互安装
#    .\install_to_mt4.ps1 -Force       # 跳过确认，静默安装
#    .\install_to_mt4.ps1 -MT4Path "D:\MT4数据"  # 指定目标路径
# ============================================================

param(
    [string]$MT4Path = "",     # 手动指定 MT4 数据目录
    [switch]$Force = $false    # 跳过确认
)

$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "MT4 技术指标安装"

# ────────────────────────────────────────────
#  1. 定位项目根目录
# ────────────────────────────────────────────
$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# 验证项目完整性
$RequiredDirs = @("Include", "Trend", "Oscillators", "Volume", "BillWilliams", "Custom", "Templates")
$MissingDirs = @()
foreach ($dir in $RequiredDirs) {
    if (-not (Test-Path (Join-Path $ScriptDir $dir))) {
        $MissingDirs += $dir
    }
}
if ($MissingDirs.Count -gt 0) {
    Write-Host "[错误] 项目目录不完整，缺少: $($MissingDirs -join ', ')" -ForegroundColor Red
    Write-Host "[提示] 请将此脚本放在项目根目录 (MT4技术指标\) 下运行" -ForegroundColor Yellow
    exit 1
}

# 统计文件数量
$MQ4Count = 0
$MQHCount = 0
foreach ($dir in ($RequiredDirs | Where-Object { $_ -ne "Include" })) {
    $MQ4Count += (Get-ChildItem (Join-Path $ScriptDir $dir) -Filter "*.mq4" -File).Count
}
$MQHCount = (Get-ChildItem (Join-Path $ScriptDir "Include") -Filter "*.mqh" -File).Count

# ────────────────────────────────────────────
#  2. 横幅
# ────────────────────────────────────────────
Write-Host @"

============================================
   MT4 技术指标 — 自动安装脚本
   无未来函数 · 信号永不重绘
============================================

"@ -ForegroundColor Cyan

Write-Host "项目目录  : $ScriptDir" -ForegroundColor Gray
Write-Host "指标文件  : $MQ4Count 个 .mq4 (5 个分类目录)" -ForegroundColor Gray
Write-Host "头文件    : $MQHCount 个 .mqh (Include\)" -ForegroundColor Gray
Write-Host ""

# ────────────────────────────────────────────
#  3. 检测 MT4 数据目录
# ────────────────────────────────────────────
function Test-IsMT4DataPath {
    param([string]$Path)
    return (Test-Path (Join-Path $Path "MQL4\Indicators"))
}

function Get-MT4DataPaths {
    $found = [System.Collections.ArrayList]::new()

    # 方法 1: 扫描 %APPDATA%\MetaQuotes\Terminal\ (最可靠)
    $appdataTerminal = Join-Path $env:APPDATA "MetaQuotes\Terminal"
    if (Test-Path $appdataTerminal) {
        $instances = Get-ChildItem $appdataTerminal -Directory -ErrorAction SilentlyContinue
        foreach ($inst in $instances) {
            $indicatorsPath = Join-Path $inst.FullName "MQL4\Indicators"
            if (Test-Path $indicatorsPath) {
                [void]$found.Add($inst.FullName)
            }
        }
    }

    # 方法 2: 注册表 (安装版 MT4 可能存有路径信息)
    $regPaths = @(
        "HKCU:\Software\MetaQuotes\MetaTrader 4",
        "HKLM:\SOFTWARE\MetaQuotes\MetaTrader 4",
        "HKLM:\SOFTWARE\WOW6432Node\MetaQuotes\MetaTrader 4"
    )
    foreach ($regPath in $regPaths) {
        try {
            $regData = Get-ItemProperty $regPath -ErrorAction SilentlyContinue
            if ($regData -and $regData.InstallPath) {
                $dataPath = $regData.InstallPath
                if (Test-IsMT4DataPath $dataPath) {
                    [void]$found.Add($dataPath)
                }
            }
        }
        catch { }
    }

    # 方法 3: 常见安装路径 (便携版)
    $commonPaths = @(
        "C:\Program Files\MetaTrader 4",
        "C:\Program Files (x86)\MetaTrader 4",
        "C:\MetaTrader 4",
        "D:\MetaTrader 4",
        "D:\Program Files\MetaTrader 4"
    )
    foreach ($p in $commonPaths) {
        if ((Test-IsMT4DataPath $p) -and ($p -notin $found)) {
            [void]$found.Add($p)
        }
    }

    return $found | Select-Object -Unique
}

# ── 确定目标路径 ──
$TargetPath = ""

if ($MT4Path -ne "") {
    # 用户通过参数指定了路径
    $MT4Path = $MT4Path.Trim('"').TrimEnd('\')
    if (Test-IsMT4DataPath $MT4Path) {
        $TargetPath = $MT4Path
        Write-Host "[指定] 使用用户指定的 MT4 数据目录" -ForegroundColor Gray
    }
    else {
        Write-Host "[错误] 指定路径下未找到 MQL4\Indicators\: $MT4Path" -ForegroundColor Red
        Write-Host "[提示] 请确认路径是否为 MT4 数据目录 (包含 MQL4 子目录)" -ForegroundColor Yellow
        exit 1
    }
}
else {
    Write-Host "正在检测 MT4 数据目录..." -ForegroundColor Yellow
    $foundPaths = @(Get-MT4DataPaths)

    if ($foundPaths.Count -eq 0) {
        Write-Host "[未找到] 自动检测未发现 MT4 数据目录" -ForegroundColor Red
        Write-Host ""
        Write-Host "请手动输入 MT4 数据目录路径:" -ForegroundColor Yellow
        Write-Host "  (在 MT4 菜单中: 文件 → 打开数据文件夹，复制路径即可)" -ForegroundColor Gray
        Write-Host "  (或者按 Ctrl+C 退出，使用 -MT4Path 参数重新运行)" -ForegroundColor Gray
        $manualPath = Read-Host "路径"
        $manualPath = $manualPath.Trim('"').TrimEnd('\')
        if (Test-IsMT4DataPath $manualPath) {
            $TargetPath = $manualPath
        }
        else {
            Write-Host "[错误] 路径无效，请确认后重试" -ForegroundColor Red
            exit 1
        }
    }
    elseif ($foundPaths.Count -eq 1) {
        $TargetPath = $foundPaths[0]
        Write-Host "[检测] 找到 1 个 MT4 实例" -ForegroundColor Green
    }
    else {
        Write-Host "[检测] 找到 $($foundPaths.Count) 个 MT4 实例:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $foundPaths.Count; $i++) {
            Write-Host "  [$($i+1)] $($foundPaths[$i])"
        }
        if (-not $Force) {
            Write-Host ""
            $choice = Read-Host "请选择序号 (1-$($foundPaths.Count))，默认 1"
            $idx = if ([int]::TryParse($choice, [ref]$null)) { [int]$choice - 1 } else { 0 }
            if ($idx -lt 0 -or $idx -ge $foundPaths.Count) { $idx = 0 }
            $TargetPath = $foundPaths[$idx]
        }
        else {
            $TargetPath = $foundPaths[0]
            Write-Host "[自动] 使用第一个实例" -ForegroundColor Gray
        }
    }
}

Write-Host "目标目录  : $TargetPath" -ForegroundColor Cyan
Write-Host ""

# ────────────────────────────────────────────
#  4. 安全检查: MT4 是否正在运行
# ────────────────────────────────────────────
$mt4Processes = Get-Process -Name "terminal", "metaeditor" -ErrorAction SilentlyContinue
if ($mt4Processes) {
    Write-Host "⚠ 警告: 检测到 MT4 相关进程正在运行:" -ForegroundColor Yellow
    foreach ($proc in $mt4Processes) {
        Write-Host "  - $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Gray
    }
    Write-Host "建议先关闭 MT4 再继续安装，否则文件可能被锁定。" -ForegroundColor Yellow
    Write-Host ""
    if (-not $Force) {
        $proceed = Read-Host "是否继续? (y/N)"
        if ($proceed -notmatch '^[yY]') {
            Write-Host "已取消安装。" -ForegroundColor Gray
            exit 0
        }
    }
}

# ────────────────────────────────────────────
#  5. 显示安装计划并确认
# ────────────────────────────────────────────
$TargetIndicators = Join-Path $TargetPath "MQL4\Indicators\MT4技术指标"
$TargetInclude1  = Join-Path $TargetIndicators "Include"      # 相对路径用
$TargetInclude2  = Join-Path $TargetPath "MQL4\Include"       # 全局可见

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
Write-Host "  安装计划" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
Write-Host "  指标文件 → MQL4\Indicators\MT4技术指标\" -ForegroundColor White
Write-Host "    ├─ Trend\           (25 个)" -ForegroundColor Gray
Write-Host "    ├─ Oscillators\     (20 个)" -ForegroundColor Gray
Write-Host "    ├─ Volume\          (10 个)" -ForegroundColor Gray
Write-Host "    ├─ BillWilliams\    (5 个)" -ForegroundColor Gray
Write-Host "    ├─ Custom\          (140 个)" -ForegroundColor Gray
Write-Host "    └─ Templates\       (1 个)" -ForegroundColor Gray
Write-Host "  头文件   → MQL4\Include\ (全局)" -ForegroundColor White
Write-Host "           + MQL4\Indicators\MT4技术指标\Include\ (相对路径)" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
Write-Host ""

if (-not $Force) {
    $confirm = Read-Host "确认安装? (Y/n)"
    if ($confirm -match '^[nN]') {
        Write-Host "已取消安装。" -ForegroundColor Gray
        exit 0
    }
}

# ────────────────────────────────────────────
#  6. 执行安装
# ────────────────────────────────────────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
Write-Host "  正在安装..." -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
Write-Host ""

$TotalSteps = $RequiredDirs.Count + 1  # 6 indicator dirs + Include dir + global Include
$Step = 0
$CopyErrors = @()

# ── 6a. 创建目标根目录 ──
try {
    New-Item -ItemType Directory -Force -Path $TargetIndicators -ErrorAction Stop | Out-Null
}
catch {
    Write-Host "[错误] 无法创建目标目录: $TargetIndicators" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Red
    exit 1
}

# ── 6b. 复制各分类目录到 MT4技术指标\ ──
$CategoryDirs = $RequiredDirs | Where-Object { $_ -ne "Include" }

foreach ($category in $CategoryDirs) {
    $Step++
    $sourceDir = Join-Path $ScriptDir $category
    $destDir = Join-Path $TargetIndicators $category
    $fileCount = (Get-ChildItem $sourceDir -Filter "*.mq4" -File).Count

    Write-Host "  [$Step/$($RequiredDirs.Count)] $category\" -NoNewline -ForegroundColor White
    Write-Host " ($fileCount 个文件) " -NoNewline -ForegroundColor Gray

    try {
        # 确保目标目录存在
        New-Item -ItemType Directory -Force -Path $destDir -ErrorAction Stop | Out-Null
        # 复制 .mq4 文件 (覆盖同名)
        Copy-Item "$sourceDir\*.mq4" -Destination $destDir -Force -ErrorAction Stop
        Write-Host "✓" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ 失败" -ForegroundColor Red
        $CopyErrors += "$category : $_"
    }
}

# ── 6c. 复制 Include\ 到 MT4技术指标\Include\ (相对路径用) ──
$Step++
$includeSource = Join-Path $ScriptDir "Include"
$includeDest1  = Join-Path $TargetIndicators "Include"

Write-Host "  [$Step/$($RequiredDirs.Count + 1)] Include\ → MT4技术指标\Include\ (相对路径用)" -NoNewline -ForegroundColor White
Write-Host " ($MQHCount 个文件) " -NoNewline -ForegroundColor Gray

try {
    New-Item -ItemType Directory -Force -Path $includeDest1 -ErrorAction Stop | Out-Null
    Copy-Item "$includeSource\*.mqh" -Destination $includeDest1 -Force -ErrorAction Stop
    Write-Host "✓" -ForegroundColor Green
}
catch {
    Write-Host "✗ 失败" -ForegroundColor Red
    $CopyErrors += "Include→MT4技术指标\Include : $_"
}

# ── 6d. 复制 Include\ 到 MQL4\Include\ (全局可见) ──
Write-Host "       Include\ → MQL4\Include\ (全局可见)" -NoNewline -ForegroundColor White
Write-Host " ($MQHCount 个文件) " -NoNewline -ForegroundColor Gray

try {
    New-Item -ItemType Directory -Force -Path $TargetInclude2 -ErrorAction Stop | Out-Null
    Copy-Item "$includeSource\*.mqh" -Destination $TargetInclude2 -Force -ErrorAction Stop
    Write-Host "✓" -ForegroundColor Green
}
catch {
    Write-Host "✗ 失败" -ForegroundColor Red
    $CopyErrors += "Include→MQL4\Include : $_"
}

# ────────────────────────────────────────────
#  7. 结果报告
# ────────────────────────────────────────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan

if ($CopyErrors.Count -eq 0) {
    Write-Host "  安装成功!" -ForegroundColor Green
}
else {
    Write-Host "  安装完成，但有 $($CopyErrors.Count) 个错误:" -ForegroundColor Yellow
    foreach ($err in $CopyErrors) {
        Write-Host "    - $err" -ForegroundColor Red
    }
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  安装位置: $TargetIndicators" -ForegroundColor Cyan
Write-Host ""
Write-Host "  下一步:" -ForegroundColor Yellow
Write-Host "    1. 重启 MT4 (或右键导航器 → 刷新)" -ForegroundColor White
Write-Host "    2. 导航器 → 自定义指标 → MT4技术指标" -ForegroundColor White
Write-Host "    3. 将 *_Safe 指标拖放到图表上使用" -ForegroundColor White
Write-Host ""

# ────────────────────────────────────────────
#  8. 可选: 提示编译
# ────────────────────────────────────────────
Write-Host "  💡 提示:" -ForegroundColor DarkYellow
Write-Host "    首次使用时建议在 MT4 的 MetaEditor (F4) 中编译一次指标，" -ForegroundColor Gray
Write-Host "    确保 .mqh 头文件路径正确识别。编译方法:" -ForegroundColor Gray
Write-Host "    工具 → MetaQuotes Language Editor → 打开 .mq4 文件 → F7 编译" -ForegroundColor Gray
Write-Host ""

# 暂停，让用户看到结果
if (-not $Force) {
    Write-Host "按任意键退出..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
