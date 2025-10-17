# Raspberry Pi Battery Optimization for RTSP Streaming

## Overview
When your Pi is only serving RTSP streams, you can disable many services to extend battery life significantly. This guide shows which services to stop and which to keep.

## Essential Services (Keep Running)
✅ **Must Keep for RTSP Streaming:**
```bash
# Core system services
systemctl status systemd-timesyncd    # Time synchronization
systemctl status networking           # Network connectivity
systemctl status wpa_supplicant      # WiFi connection
systemctl status ssh                 # Remote access (optional but recommended)
systemctl status rsyslog            # System logging (minimal)

# RTSP streaming services
systemctl status your-rtsp-service   # Your specific RTSP streaming software
```

## Services to Disable (High Power Savings)

### 1. **Desktop Environment & Graphics**
```bash
# Stop desktop environment (saves 200-400mA)
sudo systemctl stop lightdm
sudo systemctl disable lightdm

# Disable X11 and graphics
sudo systemctl stop display-manager
sudo systemctl disable display-manager

# Stop GPU services
sudo systemctl stop gpu-mem-split
sudo systemctl disable gpu-mem-split
```

### 2. **Audio Services**
```bash
# Stop audio services (saves 50-100mA)
sudo systemctl stop alsa-state
sudo systemctl stop pulseaudio
sudo systemctl disable alsa-state
sudo systemctl disable pulseaudio
```

### 3. **Bluetooth & Wireless**
```bash
# Disable Bluetooth completely (saves 30-50mA)
sudo systemctl stop bluetooth
sudo systemctl disable bluetooth
sudo rfkill block bluetooth

# If not using WiFi, disable it too (saves 100-150mA)
# sudo systemctl stop wpa_supplicant
# sudo rfkill block wifi
```

### 4. **USB & Hardware Services**
```bash
# Stop unnecessary USB services
sudo systemctl stop usbmount
sudo systemctl disable usbmount

# Disable hardware random number generator if not needed
sudo systemctl stop rng-tools
sudo systemctl disable rng-tools
```

### 5. **System Monitoring & Updates**
```bash
# Stop automatic updates (saves CPU cycles)
sudo systemctl stop unattended-upgrades
sudo systemctl disable unattended-upgrades

# Stop system monitoring
sudo systemctl stop rsyslog
sudo systemctl disable rsyslog

# Stop cron if no scheduled tasks needed
sudo systemctl stop cron
sudo systemctl disable cron
```

## Hardware Optimizations

### 1. **CPU Frequency Scaling**
```bash
# Set CPU governor to powersave mode
echo 'powersave' | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Make permanent by adding to /boot/config.txt:
echo 'arm_freq=600' | sudo tee -a /boot/config.txt  # Underclock CPU
echo 'gpu_mem=16' | sudo tee -a /boot/config.txt    # Minimize GPU memory
```

### 2. **Disable Hardware Features**
Add these lines to `/boot/config.txt`:
```bash
# Disable HDMI (saves ~25mA)
hdmi_blanking=1

# Disable camera LED (if using camera module)
disable_camera_led=1

# Disable audio (if not needed)
dtparam=audio=off

# Disable WiFi and Bluetooth (if using Ethernet)
dtoverlay=disable-wifi
dtoverlay=disable-bt

# Reduce GPU split (saves power)
gpu_mem=16
```

### 3. **USB Power Management**
```bash
# Disable USB ports if not needed (saves significant power)
echo '1-1' | sudo tee /sys/bus/usb/drivers/usb/unbind

# To re-enable later:
# echo '1-1' | sudo tee /sys/bus/usb/drivers/usb/bind
```

## Software Optimizations

### 1. **Reduce Logging**
```bash
# Minimize logging to reduce SD card writes and CPU usage
sudo systemctl stop systemd-journald
sudo systemctl disable systemd-journald

# Or configure minimal logging
sudo mkdir -p /etc/systemd/journald.conf.d/
echo '[Journal]' | sudo tee /etc/systemd/journald.conf.d/00-journal-size.conf
echo 'SystemMaxUse=50M' | sudo tee -a /etc/systemd/journald.conf.d/00-journal-size.conf
```

### 2. **Optimize RTSP Streaming Software**
Depending on your RTSP software, optimize settings:

**For FFmpeg-based streaming:**
```bash
# Use hardware acceleration if available
ffmpeg -f v4l2 -framerate 15 -video_size 640x480 -i /dev/video0 \
       -c:v h264_v4l2m2m -b:v 500k \  # Hardware encoding, lower bitrate
       -f rtsp rtsp://localhost:8554/stream
```

**For GStreamer:**
```bash
# Lower resolution and frame rate
gst-launch-1.0 v4l2src device=/dev/video0 \
    ! video/x-raw,width=640,height=480,framerate=15/1 \
    ! v4l2h264enc extra-controls="controls,video_bitrate=500000" \
    ! rtspclientsink location=rtsp://localhost:8554/stream
```

## Battery Monitoring Script
Create `/home/pi/battery_monitor.sh`:
```bash
#!/bin/bash
while true; do
    # Monitor system load and temperature
    TEMP=$(vcgencmd measure_temp | cut -d'=' -f2)
    LOAD=$(uptime | awk '{print $10}')
    
    echo "$(date): Temp=$TEMP Load=$LOAD"
    
    # Log to file every 5 minutes
    sleep 300
done
```

## Power Consumption Estimates

| Component | Normal Usage | Optimized Usage | Savings |
|-----------|--------------|-----------------|---------|
| Desktop Environment | 400mA | 0mA | 400mA |
| WiFi | 150mA | 150mA | 0mA* |
| Bluetooth | 50mA | 0mA | 50mA |
| USB Ports | 100mA | 0mA** | 100mA |
| Audio | 80mA | 0mA | 80mA |
| HDMI | 25mA | 0mA | 25mA |
| **Total Base** | **~800mA** | **~150mA*** | **~650mA** |

*Keep WiFi for RTSP streaming  
**Only if no USB devices needed  
***Plus RTSP streaming overhead (~50-100mA)

## Implementation Script
Create `/home/pi/optimize_for_battery.sh`:
```bash
#!/bin/bash
echo "Optimizing Raspberry Pi for battery life..."

# Disable services
services_to_disable=(
    "lightdm"
    "bluetooth" 
    "alsa-state"
    "pulseaudio"
    "unattended-upgrades"
    "cron"
)

for service in "${services_to_disable[@]}"; do
    sudo systemctl stop "$service" 2>/dev/null
    sudo systemctl disable "$service" 2>/dev/null
    echo "Disabled: $service"
done

# Hardware optimizations
echo 'powersave' | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
sudo rfkill block bluetooth

# Add boot config optimizations
sudo cp /boot/config.txt /boot/config.txt.backup
cat << EOF | sudo tee -a /boot/config.txt

# Battery optimization settings
hdmi_blanking=1
disable_camera_led=1
dtparam=audio=off
gpu_mem=16
arm_freq=600
EOF

echo "Battery optimizations applied!"
echo "Reboot required for boot config changes."
echo "Estimated power savings: ~650mA (65% reduction)"
```

## Reverting Changes
If you need to restore services:
```bash
# Re-enable critical services
sudo systemctl enable lightdm ssh networking

# Restore boot config
sudo cp /boot/config.txt.backup /boot/config.txt

# Reboot
sudo reboot
```

## Expected Battery Life Improvement
- **Before optimization**: ~4-6 hours (typical Pi setup)  
- **After optimization**: ~12-18 hours (RTSP streaming only)
- **With larger battery pack**: 24+ hours possible

Remember to test your RTSP stream functionality after applying these optimizations to ensure everything still works as expected!