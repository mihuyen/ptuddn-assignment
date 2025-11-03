#!/usr/bin/env powershell
<#
JMeter-like Load Test Script - Tăng CPU > 80% để trigger alert
Chạy requests liên tục với concurrency cao
#>

param(
    [int]$Duration = 60,           # Thời gian test (giây)
    [int]$Threads = 50,             # Số parallel requests
    [int]$RequestsPerSecond = 100   # Requests per second
)

$url = "http://localhost:8080/"
$startTime = Get-Date
$endTime = $startTime.AddSeconds($Duration)

Write-Host "🔥 JMeter-like Load Test" -ForegroundColor Red
Write-Host "Duration: $Duration seconds" -ForegroundColor Cyan
Write-Host "Threads: $Threads" -ForegroundColor Cyan
Write-Host "Target RPS: $RequestsPerSecond" -ForegroundColor Cyan
Write-Host "Expected: CPU should spike to > 80%" -ForegroundColor Yellow
Write-Host ""

$requestCount = 0
$successCount = 0
$errorCount = 0

# Tạo job pools cho parallel requests
$pool = [System.Collections.Generic.Queue[object]]::new()

while ((Get-Date) -lt $endTime) {
    # Thêm $Threads requests đồng thời
    for ($i = 0; $i -lt $Threads; $i++) {
        $job = Start-Job -ScriptBlock {
            param($url, $reqId)
            try {
                $response = Invoke-WebRequest -Uri $url -TimeoutSec 5 -UseBasicParsing
                return @{ success = $true; statusCode = $response.StatusCode; id = $reqId }
            }
            catch {
                return @{ success = $false; error = $_.Exception.Message; id = $reqId }
            }
        } -ArgumentList $url, $requestCount
        
        $pool.Enqueue($job)
        $requestCount++
    }
    
    # Chờ một chút trước batch tiếp theo
    Start-Sleep -Milliseconds (1000 / $RequestsPerSecond * $Threads)
}

Write-Host "Chờ tất cả requests hoàn thành..."
$completedJobs = Get-Job | Wait-Job

foreach ($job in $completedJobs) {
    $result = Receive-Job -Job $job
    if ($result.success) {
        $successCount++
    } else {
        $errorCount++
    }
    Remove-Job -Job $job
}

$elapsed = (Get-Date) - $startTime

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "📊 LOAD TEST RESULTS" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "Total Requests: $requestCount" -ForegroundColor White
Write-Host "Successful: $successCount ✅" -ForegroundColor Green
Write-Host "Failed: $errorCount ❌" -ForegroundColor Red
Write-Host "Duration: $([math]::Round($elapsed.TotalSeconds, 2)) seconds" -ForegroundColor White
Write-Host "RPS: $([math]::Round($requestCount / $elapsed.TotalSeconds, 2))" -ForegroundColor Cyan
Write-Host "Success Rate: $([math]::Round($successCount / $requestCount * 100, 2))%" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""
Write-Host "📈 Monitor CPU in Grafana:" -ForegroundColor Yellow
Write-Host "   http://localhost:3000" -ForegroundColor Cyan
Write-Host "🚨 Check Alerts in AlertManager:" -ForegroundColor Yellow
Write-Host "   http://localhost:9093" -ForegroundColor Cyan
