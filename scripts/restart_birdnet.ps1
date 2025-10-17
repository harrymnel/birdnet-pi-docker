# Quick BirdNET-Pi recovery after system sleep
# Save this as restart_birdnet.ps1 for quick recovery after sleep/wake cycles

Write-Host "🐦 BirdNET-Pi Recovery Script" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green
Write-Host ""

# Check if we're in the right directory
if (!(Test-Path "docker-compose.yml")) {
    Write-Host "❌ Error: docker-compose.yml not found!" -ForegroundColor Red
    Write-Host "Please run this script from the birdnet-pi directory" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "🔄 Restarting BirdNET-Pi after sleep/wake..." -ForegroundColor Cyan

try {
    # Restart the container
    Write-Host "Stopping container..." -ForegroundColor Yellow
    docker-compose down 2>$null
    
    Write-Host "Starting container..." -ForegroundColor Yellow  
    docker-compose up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Container restarted successfully!" -ForegroundColor Green
    } else {
        throw "Container failed to start"
    }
    
    Write-Host ""
    Write-Host "⏳ Waiting for services to initialize..." -ForegroundColor Cyan
    Start-Sleep -Seconds 30
    
    # Check container status
    Write-Host ""
    Write-Host "📊 Container Status:" -ForegroundColor Cyan
    docker-compose ps
    
    # Test web interface
    Write-Host ""
    Write-Host "🌐 Testing web interface..." -ForegroundColor Cyan
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8001" -Method HEAD -TimeoutSec 10
        Write-Host "✅ Web interface accessible (Status: $($response.StatusCode))" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Web interface not ready yet: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   Give it a few more minutes to fully initialize" -ForegroundColor Gray
    }
    
    # Check recent logs
    Write-Host ""
    Write-Host "📋 Recent logs:" -ForegroundColor Cyan
    docker-compose logs --tail=5
    
    Write-Host ""
    Write-Host "🎉 BirdNET-Pi should be ready now!" -ForegroundColor Green
    Write-Host "   Web Interface: http://localhost:8001" -ForegroundColor Gray
    Write-Host "   Live Stream: http://localhost:8000" -ForegroundColor Gray
    
} catch {
    Write-Host ""
    Write-Host "❌ Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Check Docker Desktop is running" -ForegroundColor Gray
    Write-Host "2. Verify WSL2 backend is enabled" -ForegroundColor Gray
    Write-Host "3. Check system resources (RAM, disk space)" -ForegroundColor Gray
    Write-Host "4. Run 'docker-compose logs' for detailed error messages" -ForegroundColor Gray
}

Write-Host ""
Read-Host "Press Enter to exit"