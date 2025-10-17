# Troubleshooting Guide

This guide helps resolve common issues with BirdNET-Pi Docker RTSP setup.

## 📋 Quick Diagnosis

### System Health Check
```powershell
# Check container status
docker-compose ps

# Check logs for errors
docker-compose logs --tail=50 | Select-String "ERROR|WARN"

# Test web interface
Invoke-WebRequest -Uri http://localhost:8001 -Method HEAD

# Check RTSP connectivity
docker-compose exec birdnet-pi grep "READ.*CHUNKS" /var/log/birdnet.log
```

## 🔧 Common Issues and Solutions

### 1. RTSP Connection Problems

#### Symptom: Empty Audio Files (94 bytes)
```bash
# Check for small audio files
docker-compose exec birdnet-pi find /config/BirdSongs -name "*.wav" -size -1000c
```

**Solution**: TCP transport fix (already included in Dockerfile)
```bash
# Verify TCP transport is applied
docker-compose exec birdnet-pi grep "rtsp_transport tcp" /home/pi/BirdNET-Pi/scripts/birdnet_recording.sh
```

#### Symptom: "Connection refused" errors
**Causes and Solutions**:
1. **Pi RTSP server not running**
   ```bash
   # On Pi: Check RTSP service
   ps aux | grep rtsp
   systemctl status your-rtsp-service
   ```

2. **Network connectivity issues**
   ```bash
   # Test Pi connectivity
   ping YOUR_PI_IP
   
   # Test RTSP stream directly
   ffplay rtsp://YOUR_PI_IP:8554/stream
   ```

3. **Firewall blocking RTSP port**
   ```bash
   # On Pi: Allow RTSP port
   sudo ufw allow 8554
   ```

#### Symptom: "READ 0 CHUNKS" errors
**Solution**: Restart container to apply TCP transport
```bash
docker-compose restart
```

### 2. Container Startup Issues

#### Symptom: Container exits immediately
```bash
# Check exit reason
docker-compose logs birdnet-pi

# Common causes:
# - Configuration file syntax errors
# - Port conflicts
# - Insufficient resources
```

**Solutions**:
1. **Configuration syntax error**
   ```bash
   # Validate docker-compose.yml
   docker-compose config
   
   # Check birdnet.conf for syntax errors
   docker-compose exec birdnet-pi cat /config/birdnet.conf | head -20
   ```

2. **Port conflicts**
   ```bash
   # Check if ports are already in use
   netstat -an | Select-String "8001|8000|80"
   
   # Change ports in docker-compose.yml if needed
   ```

3. **Resource constraints**
   ```bash
   # Check Docker resources
   docker system df
   docker stats
   ```

### 3. Audio Processing Issues

#### Symptom: No bird detections
```bash
# Check audio file generation
docker-compose exec birdnet-pi ls -la /config/BirdSongs/By_Date/$(date +%Y-%m-%d)/

# Check confidence levels
docker-compose logs | Select-String "CONFIDENCE"
```

**Solutions**:
1. **Lower confidence threshold**
   ```bash
   # In config/birdnet.conf
   CONFIDENCE=0.5  # Lower from 0.7
   ```

2. **Increase sensitivity**
   ```bash
   # In config/birdnet.conf
   SENSITIVITY=1.4  # Increase from 1.25
   ```

3. **Check geographic location**
   ```bash
   # Ensure LATITUDE/LONGITUDE are correct
   # Wrong location = wrong species list = no detections
   ```

#### Symptom: Too many false positives
**Solutions**:
1. **Increase confidence threshold**
   ```bash
   CONFIDENCE=0.8  # Increase from 0.7
   ```

2. **Use exclude list**
   ```bash
   # Add common false positives to config/exclude_species_list.txt
   Human
   Engine
   Dog
   ```

3. **Apply frequency filtering**
   ```bash
   BANDPASS_FMIN=300    # Remove low-frequency noise
   BANDPASS_FMAX=8000   # Focus on bird call range
   ```

### 4. Sleep/Wake Recovery Issues

#### Symptom: FileNotFoundError after sleep
```bash
# Check for race condition errors
docker-compose logs | Select-String "FileNotFoundError"
```

**Solution**: Restart container (automatic recovery included)
```bash
# Manual restart
docker-compose restart

# Check health status
docker-compose ps
```

#### Symptom: Container won't restart after sleep
**Solutions**:
1. **Check Docker Desktop status**
   - Ensure Docker Desktop is running
   - Check WSL2 backend status

2. **Manual recovery**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### 5. Web Interface Problems

#### Symptom: Cannot access http://localhost:8001
**Solutions**:
1. **Check container status**
   ```bash
   docker-compose ps
   # Should show "Up" status
   ```

2. **Check port mapping**
   ```bash
   docker-compose port birdnet-pi 8081
   # Should show 0.0.0.0:8001
   ```

3. **Wait for full startup**
   ```bash
   # Services take 30-60 seconds to fully initialize
   docker-compose logs -f | Select-String "Setup complete"
   ```

#### Symptom: Web interface loads but shows errors
**Solutions**:
1. **Check service status**
   ```bash
   docker-compose exec birdnet-pi systemctl status birdnet_analysis.service
   ```

2. **Check permissions**
   ```bash
   docker-compose exec birdnet-pi ls -la /config/
   # Should show pi:pi ownership
   ```

### 6. Audio Quality Issues

#### Symptom: Poor detection rates despite good audio
**Solutions**:
1. **Check audio sample rate**
   ```bash
   # Ensure 48kHz sample rate
   docker-compose exec birdnet-pi sox /path/to/recent.wav -n stat
   ```

2. **Implement PulseAudio processing**
   - Follow [Pi PulseAudio Setup Guide](PI_PULSEAUDIO_SETUP.md)
   - Use echo cancellation and noise reduction

3. **Hardware improvements**
   - Use USB audio isolator
   - Position microphone away from noise sources
   - Use directional microphone if possible

#### Symptom: Audio files too quiet/loud
**Solutions**:
1. **Adjust gain on Pi**
   ```bash
   # On Pi: Use alsamixer to adjust levels
   alsamixer
   ```

2. **Use automatic gain control**
   ```bash
   # In PulseAudio configuration
   aec_args="analog_gain_control=1 digital_gain_control=1"
   ```

### 7. Storage and Performance Issues

#### Symptom: Disk full errors
```bash
# Check disk usage
docker-compose exec birdnet-pi df -h

# Check purge settings
docker-compose exec birdnet-pi grep PURGE /config/birdnet.conf
```

**Solutions**:
1. **Enable automatic purging**
   ```bash
   FULL_DISK=purge
   PURGE_THRESHOLD=85  # Purge when 85% full
   ```

2. **Manual cleanup**
   ```bash
   # Remove old recordings
   docker-compose exec birdnet-pi find /config/BirdSongs -name "*.wav" -mtime +7 -delete
   ```

#### Symptom: High CPU usage
**Solutions**:
1. **Reduce processing threads**
   ```bash
   THREADS=2
   TFLITE_THREADS=2
   ```

2. **Increase recording length**
   ```bash
   RECORDING_LENGTH=20  # Process less frequently
   ```

## 🔍 Diagnostic Commands

### System Information
```bash
# Container info
docker-compose exec birdnet-pi uname -a
docker-compose exec birdnet-pi cat /etc/os-release

# Resource usage
docker stats birdnet-pi

# Network connectivity
docker-compose exec birdnet-pi ping -c 3 YOUR_PI_IP
```

### Audio Diagnostics
```bash
# Check audio devices
docker-compose exec birdnet-pi cat /proc/asound/cards

# Test RTSP stream
docker-compose exec birdnet-pi ffprobe rtsp://YOUR_PI_IP:8554/stream

# Check recent audio files
docker-compose exec birdnet-pi find /config/BirdSongs -name "*.wav" -mtime -1 -exec ls -lh {} \;
```

### Service Status
```bash
# Check all services
docker-compose exec birdnet-pi systemctl --no-pager list-units --type=service --state=running | grep birdnet

# Check specific service
docker-compose exec birdnet-pi systemctl status birdnet_recording.service

# Check logs
docker-compose exec birdnet-pi journalctl -u birdnet_analysis.service --no-pager -l
```

## 📊 Performance Monitoring

### Real-time Monitoring
```bash
# Monitor logs in real-time
docker-compose logs -f

# Monitor detection events
docker-compose logs -f | Select-String "DETECTED|CONFIDENCE"

# Monitor system resources
docker stats birdnet-pi
```

### Health Checks
```bash
# Check container health (if health check configured)
docker inspect birdnet-pi | Select-String '"Health"' -A 10

# Manual health verification
Invoke-WebRequest -Uri http://localhost:8001/stats -Method HEAD
```

## 🆘 Getting Help

### Information to Gather
Before seeking help, collect:

1. **System Information**
   ```bash
   # Windows version
   Get-ComputerInfo | Select WindowsProductName, WindowsVersion
   
   # Docker version
   docker --version
   docker-compose --version
   
   # Container logs
   docker-compose logs --tail=100 > logs.txt
   ```

2. **Configuration Details**
   ```bash
   # Sanitized configuration (remove sensitive info)
   docker-compose exec birdnet-pi grep -v "PWD\|PASSWORD\|KEY" /config/birdnet.conf
   
   # Docker compose config
   docker-compose config
   ```

3. **Error Messages**
   ```bash
   # Recent errors
   docker-compose logs --since=1h | Select-String "ERROR|FATAL|CRITICAL"
   ```

### Where to Get Help
1. **GitHub Issues**: [Create an issue](https://github.com/yourusername/birdnet-pi-docker/issues)
2. **Discussions**: [GitHub Discussions](https://github.com/yourusername/birdnet-pi-docker/discussions)
3. **Documentation**: Check all guides in the [docs/](../docs/) folder

### Before Opening an Issue
- [ ] Check existing issues for similar problems
- [ ] Follow troubleshooting steps above
- [ ] Collect system information and logs
- [ ] Test with minimal configuration
- [ ] Document exact steps to reproduce

## 🔄 Recovery Procedures

### Complete Reset
If all else fails:
```bash
# Stop and remove containers
docker-compose down

# Remove images (forces rebuild)
docker rmi birdnet-pi-birdnet-pi:latest

# Clean rebuild
docker-compose build --no-cache
docker-compose up -d
```

### Configuration Reset
```bash
# Backup current config
cp config/birdnet.conf config/birdnet.conf.backup

# Reset to defaults (you'll need to reconfigure)
docker-compose exec birdnet-pi cp /home/pi/BirdNET-Pi/birdnet.conf.default /config/birdnet.conf

# Restart with default config
docker-compose restart
```

Remember: Most issues are configuration-related. Double-check your RTSP stream URL and geographic coordinates first!