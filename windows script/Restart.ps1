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

# 5. 清理 DNS 缓存
Clear-DnsClientCache
Write-Host "DNS 缓存已清理。"

# 6. 开启任务提示
Write-Host "正在启动计划任务: $taskName ..."
Start-ScheduledTask -TaskName $taskName 

# 7. 等待并验证
Start-Sleep -Seconds 1 
$currentState = Get-ScheduledTask -TaskName $taskName | Select-Object -ExpandProperty State 
Write-Host "任务 '$taskName' 的当前状态是: $currentState" 

# 8. 完成提示
Write-Host "操作已完成。按 Enter 键退出..."
Read-Host