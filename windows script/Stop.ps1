# 要操作的任务和进程名
$taskName = "mihomo"
$processName = "mihomo"

# 1. 停止计划任务
Write-Host "正在停止计划任务: $taskName ..."
Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

# 2. 停止关联的进程 (作为双重保险)
Write-Host "正在停止进程: $processName ..."
Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue

# 3. 短暂等待以确保状态更新
Start-Sleep -Seconds 1

# 4. 验证任务状态
$currentState = Get-ScheduledTask -TaskName $taskName | Select-Object -ExpandProperty State
Write-Host "任务 '$taskName' 的当前状态是: $currentState"

# 5. 清理DNS缓存 (这是你脚本里原有的步骤)
Clear-DnsClientCache
Write-Host "DNS 缓存已清理。"

Write-Host "按 Enter 键退出..."
Read-Host
