# Windows 11 Docker Desktop Sleep/Wake Optimization Guide

## Docker Desktop Settings
1. **Open Docker Desktop Settings**
2. **General Tab:**
   - ✅ Enable "Start Docker Desktop when you log in"
   - ✅ Enable "Use Docker Compose V2"

3. **Resources Tab:**
   - **Memory:** Increase to at least 4GB for BirdNET-Pi
   - **CPU:** Allow at least 2 cores
   - **Disk Image Location:** Use SSD if available

## Windows Power Settings
1. **Open Windows Settings > System > Power**
2. **Screen and Sleep:**
   - Set "When plugged in, turn off my screen after": 30 minutes or more
   - Set "When plugged in, put my device to sleep after": Never (or 4+ hours)

3. **Additional Power Settings:**
   - Open "Additional power settings"
   - Select "High performance" power plan
   - Click "Change plan settings"
   - Set "Turn off the display": 30 minutes
   - Set "Put the computer to sleep": Never

## Network Adapter Settings (Prevents RTSP disconnection)
1. **Open Device Manager**
2. **Expand "Network adapters"**
3. **Right-click your primary network adapter**
4. **Select "Properties" > "Power Management" tab**
5. **Uncheck:** "Allow the computer to turn off this device to save power"

## Docker Desktop WSL2 Backend (Recommended)
1. **Docker Desktop Settings > General**
2. **Enable:** "Use the WSL 2 based engine"
3. **Install WSL2 Ubuntu if needed:**
   ```powershell
   wsl --install -d Ubuntu
   ```

## PowerShell Script for Quick Recovery
Save this as `restart_birdnet.ps1` for quick recovery after sleep:
```powershell
# Quick BirdNET-Pi recovery after system sleep
Write-Host "Restarting BirdNET-Pi after sleep/wake..."
Set-Location "C:\Users\LenovoUser\birdnet-pi"
docker-compose restart
Write-Host "Waiting for services to initialize..."
Start-Sleep -Seconds 30
docker-compose logs --tail=5
Write-Host "BirdNET-Pi should be ready now!"
```

## Automatic Recovery Task (Advanced)
Create a Windows Task Scheduler task that runs on system wake:
- **Trigger:** On workstation unlock
- **Action:** Run `docker-compose restart` in your birdnet-pi folder
- **Conditions:** Only if network is available

## Verification Commands
After implementing these changes, test with:
```powershell
# Check container health
docker-compose ps

# Verify web interface
Invoke-WebRequest -Uri http://localhost:8001 -Method HEAD

# Check recent logs
docker-compose logs --tail=10
```