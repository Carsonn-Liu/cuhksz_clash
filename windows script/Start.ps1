$taskName = "mihomo" 

Clear-DnsClientCache 

Start-ScheduledTask -TaskName $taskName 

Start-Sleep -Seconds 1 

$currentState = Get-ScheduledTask -TaskName $taskName | Select-Object -ExpandProperty State 
Write-Host "任务 '$taskName' 的当前状态是: $currentState" 

Write-Host "按 Enter 键退出..."
Read-Host