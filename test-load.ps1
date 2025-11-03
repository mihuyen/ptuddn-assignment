#!/usr/bin/env powershell
# Script test load - gửi request liên tục để tạo metrics

param(
    [int]$Duration = 60,  # Thời gian test (giây)
    [int]$Interval = 1    # Khoảng cách giữa request (giây)
)

$url = "http://localhost:8080/"
$startTime = Get-Date
$endTime = $startTime.AddSeconds($Duration)
$requestCount = 0
$successCount = 0
$errorCount = 0

Write-Host "🚀 Bắt đầu load test - $Duration giây" -ForegroundColor Green
Write-Host "URL: $url" -ForegroundColor Cyan
Write-Host "Interval: $Interval giây" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔄 Đang gửi requests..." -ForegroundColor Yellow

while ((Get-Date) -lt $endTime) {
    try {
        $response = Invoke-WebRequest -Uri $url -TimeoutSec 5 -ErrorAction Stop
        $successCount++
        Write-Host "✓ Request $($requestCount + 1): OK (${$response.StatusCode})" -ForegroundColor Green
    }
    catch {
        $errorCount++
        Write-Host "✗ Request $($requestCount + 1): ERROR" -ForegroundColor Red
    }
    
    $requestCount++
    Start-Sleep -Seconds $Interval
}

$elapsed = (Get-Date) - $startTime

Write-Host ""
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host "📊 KẾT QUẢ LOAD TEST" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host "Tổng requests: $requestCount" -ForegroundColor White
Write-Host "Thành công: $successCount" -ForegroundColor Green
Write-Host "Lỗi: $errorCount" -ForegroundColor Red
Write-Host "Thời gian: $([math]::Round($elapsed.TotalSeconds, 2)) giây" -ForegroundColor White
Write-Host "Rate: $([math]::Round($requestCount / $elapsed.TotalSeconds, 2)) req/sec" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 Kiểm tra Grafana dashboard:" -ForegroundColor Yellow
Write-Host "   http://localhost:3000" -ForegroundColor Cyan
Write-Host ""
