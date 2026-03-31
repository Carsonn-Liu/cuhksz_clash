# 是否强制更新（忽略版本对比）
$Force = $false

# GitHub 最新稳定版接口
$ReleaseUrl = "https://api.github.com/repos/MetaCubeX/mihomo/releases/latest"

# ==========================================
# 修改点 1：工作目录改为脚本所在目录
# ==========================================
if ($PSScriptRoot) {
    $WorkPath = $PSScriptRoot
} else {
    # 兼容在命令行直接粘贴运行的情况
    $WorkPath = Get-Location
}

$ExePath  = Join-Path $WorkPath 'mihomo.exe'

# 进程名与计划任务名
$ProcessName = "mihomo"
$TaskName    = "mihomo"

# GitHub API 需要 User-Agent
$Headers = @{ "User-Agent" = "PowerShell" }

# TLS 设置
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
} catch {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

# 确保工作目录存在（虽然后续操作就在本目录，但以防万一）
if (-not (Test-Path $WorkPath)) {
    New-Item -ItemType Directory -Force -Path $WorkPath | Out-Null
}

function Get-NormalizedVersion {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $m = [regex]::Match($Text, '(?<ver>\d+(?:\.\d+){1,3})')
    if ($m.Success) {
        try { return [version]$m.Groups['ver'].Value } catch { return $null }
    }
    return $null
}

function Get-InstalledMihomoVersion {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }

    try {
        $out = & $Path -v 2>&1 | Out-String
        $ver = Get-NormalizedVersion $out
        if ($ver) { return $ver }
    } catch { }

    try {
        $fi = Get-Item $Path -ErrorAction SilentlyContinue
        $metaVer = $fi.VersionInfo.ProductVersion
        $ver = Get-NormalizedVersion $metaVer
        if ($ver) { return $ver }
    } catch { }

    return $null
}

Write-Host "工作目录: $WorkPath"

# 获取最新发布信息
try {
    Write-Host "正在检查更新..."
    $Assets = Invoke-RestMethod -Uri $ReleaseUrl -Method Get -Headers $Headers
} catch {
    Write-Error "检查更新失败，请检查网络连接或 GitHub API 状态。"
    Read-Host "按回车键退出..."
    exit
}

$LatestTag = $Assets.tag_name
$LatestVersion = Get-NormalizedVersion ($LatestTag -replace '^[vV]', '')

$InstalledVersion = Get-InstalledMihomoVersion -Path $ExePath

Write-Host "Latest tag: $LatestTag (parsed: $LatestVersion)"
if ($InstalledVersion) {
    Write-Host "Installed version: $InstalledVersion"
} else {
    Write-Host "Installed version: not found"
}

# 资产筛选：Windows amd64 zip
$WinAsset = $Assets.assets | Where-Object { $_.name -like "mihomo-windows-amd64*zip" } | Select-Object -First 1
if (-not $WinAsset) {
    Write-Error "未找到 Windows amd64 的 zip 资产，请检查发布页面。"
    Read-Host "按回车键退出..."
    exit
}

$DownloadUrl = $WinAsset.browser_download_url
$ZipName = $WinAsset.name
$ZipPath = Join-Path $WorkPath $ZipName

# 版本对比
$ShouldUpdate = $true
if (-not $Force -and $InstalledVersion -and $LatestVersion) {
    if ($InstalledVersion -ge $LatestVersion) {
        $ShouldUpdate = $false
    }
}

# ==========================================
# 修改点 2：不更新时暂停，防止窗口闪退
# ==========================================
if (-not $ShouldUpdate) {
    Write-Host "已是最新版本（或更高），跳过下载与重启。"
    Read-Host "按回车键退出..."
    return
}

Write-Host "准备更新到最新版本：$LatestTag"
Write-Host "Downloading $DownloadUrl"

try {
    # 注意：ghproxy 后面通常直接接完整 URL
    Invoke-WebRequest -OutFile $ZipPath -Uri ("https://ghproxy.net/" + $DownloadUrl) -Headers $Headers -TimeoutSec 60
} catch {
    Write-Error "下载失败: $($_.Exception.Message)"
    Read-Host "按回车键退出..."
    exit
}

# 停止正在运行的 mihomo
Stop-Process -Name $ProcessName -Force -ErrorAction SilentlyContinue

# 清 DNS（可选）
try { Clear-DnsClientCache } catch { }

# 解压覆盖
try {
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $WorkPath -Force
} catch {
    Write-Error "解压失败: $($_.Exception.Message)"
    Read-Host "按回车键退出..."
    exit
}

# 自动查找解压出来的 EXE 文件并重命名覆盖
# 逻辑：查找当前目录下所有exe，排除 mihomo.exe (旧文件)，选第一个
# 注意：如果解压出来直接就是 mihomo.exe 且覆盖了，这里可能会找不到新文件，或者把其他工具误判。
# 针对 mihomo release 结构，通常解压出来是 mihomo-windows-amd64-xxx.exe
$ExeFile = Get-ChildItem -Path $WorkPath -Filter "*.exe" -Recurse | Where-Object { $_.Name -ne "mihomo.exe" } | Select-Object -First 1

if ($ExeFile) {
    Write-Host "找到解压的 EXE 文件：$($ExeFile.Name)，替换 mihomo.exe"

    $targetExe = Join-Path $WorkPath "mihomo.exe"

    # 删除旧文件（如果存在）
    if (Test-Path $targetExe) {
        Remove-Item $targetExe -Force
    }

    # 重命名新文件
    Rename-Item -Path $ExeFile.FullName -NewName "mihomo.exe" -Force
} else {
    # 如果没找到其他 exe，有可能是 zip 里直接就是 mihomo.exe 且已被 Expand-Archive 覆盖
    # 或者是子目录结构问题。这里做一个简单检查
    if (Test-Path (Join-Path $WorkPath "mihomo.exe")) {
        Write-Warning "未找到更名文件，但存在 mihomo.exe，假设已由解压直接覆盖。"
    } else {
        Write-Warning "未在解压目录中找到更新的 EXE 文件！"
    }
}

# 删除下载的 zip 文件
if (Test-Path $ZipPath) {
    Remove-Item -LiteralPath $ZipPath -Force
    Write-Host "已删除下载的压缩包: $ZipName"
}

# 启动计划任务
try {
    Start-ScheduledTask -TaskName $TaskName
    Start-Sleep -Seconds 3
    $state = (Get-ScheduledTask -TaskName $TaskName).State
    Write-Host "State of ${TaskName}: ${state}"
    if ($state -eq "Running") {
        Write-Host "${TaskName} successfully started."
    } else {
        Write-Host "Run ${TaskName} failed."
    }
} catch {
    Write-Warning "启动计划任务 '${TaskName}' 失败：$($_.Exception.Message)"
    Write-Host "尝试直接启动进程..."
    try { Start-Process -FilePath $ExePath -WorkingDirectory $WorkPath } catch {}
}

# 提示版本变化
$NewInstalledVersion = Get-InstalledMihomoVersion -Path $ExePath
Write-Host "更新完成：$InstalledVersion → $NewInstalledVersion"

# ==========================================
# 修改点 3：脚本结束前暂停
# ==========================================
Read-Host "按回车键退出..."