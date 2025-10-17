# Configuration Guide

This guide covers all configuration options for BirdNET-Pi Docker with RTSP support.

## 📋 Table of Contents

- [Quick Configuration](#-quick-configuration)
- [Core Settings](#-core-settings)
- [Audio Configuration](#-audio-configuration)
- [Detection Parameters](#-detection-parameters)
- [Species Management](#-species-management)
- [Advanced Settings](#-advanced-settings)
- [Environment Variables](#-environment-variables)

## 🚀 Quick Configuration

### Minimal Setup
Edit `config/birdnet.conf` with these essential settings:

```bash
# Geographic Location (REQUIRED)
LATITUDE=-33.9249         # Your latitude
LONGITUDE=18.4241         # Your longitude

# RTSP Stream (REQUIRED)
RTSP_STREAM=rtsp://192.168.1.100:8554/stream

# Basic Detection Settings
CONFIDENCE=0.7            # Detection confidence threshold (0.0-1.0)
SENSITIVITY=1.25          # Analysis sensitivity
RECORDING_LENGTH=15       # Audio chunk length in seconds
```

### Docker Environment Variables
In `docker-compose.yml`:

```yaml
environment:
  - TZ=Africa/Johannesburg              # Your timezone
  - BIRDSONGS_FOLDER=/config/BirdSongs  # Storage location
  - LIVESTREAM_BOOT_ENABLED=true        # Enable live streaming
```

## ⚙️ Core Settings

### Geographic Configuration
```bash
# Location Settings (Critical for Species Accuracy)
LATITUDE=-33.9249                    # Decimal degrees (-90 to 90)
LONGITUDE=18.4241                    # Decimal degrees (-180 to 180)
TIMEZONE=Africa/Johannesburg         # System timezone
LOCALE=en                           # Language setting
```

**Why location matters**: BirdNET uses geographic location to filter species lists, significantly improving accuracy by excluding birds not found in your region.

### Audio Input Configuration
```bash
# RTSP Stream Configuration
RTSP_STREAM=rtsp://192.168.1.100:8554/stream
RTSP_STREAM_TO_LIVESTREAM=0         # Stream index (usually 0)
CHANNELS=1                          # Mono (1) or Stereo (2)
SAMPLE_RATE=48000                   # Audio sample rate (Hz)

# Recording Settings
RECORDING_LENGTH=15                  # Chunk length in seconds
EXTRACTION_LENGTH=3                  # Analysis segment length
OVERLAP=0.0                         # Overlap between segments (0.0-2.9)
```

## 🎵 Audio Configuration

### Detection Thresholds
```bash
# Primary Detection Parameters
CONFIDENCE=0.7                      # Minimum confidence (0.0-1.0)
SENSITIVITY=1.25                    # Analysis sensitivity (0.5-1.5)
SF_THRESH=0.03                      # Sigmoid threshold (0.001-0.1)

# Advanced Audio Processing
BANDPASS_FMIN=0                     # High-pass filter frequency (Hz)
BANDPASS_FMAX=15000                 # Low-pass filter frequency (Hz)
```

### Recommended Settings by Environment

#### Urban Environment (High Noise)
```bash
CONFIDENCE=0.8                      # Higher threshold for noise
SENSITIVITY=1.0                     # Lower sensitivity
SF_THRESH=0.05                      # Higher sigmoid threshold
BANDPASS_FMIN=300                   # Filter low-frequency noise
```

#### Quiet Rural Environment
```bash
CONFIDENCE=0.6                      # Lower threshold for quiet birds
SENSITIVITY=1.4                     # Higher sensitivity
SF_THRESH=0.02                      # Lower sigmoid threshold
BANDPASS_FMIN=150                   # Preserve low-frequency calls
```

#### Night Recording (Owls)
```bash
CONFIDENCE=0.7                      # Standard threshold
SENSITIVITY=1.3                     # Higher sensitivity
BANDPASS_FMIN=100                   # Preserve very low frequencies
BANDPASS_FMAX=4000                  # Focus on owl call range
```

## 🎯 Detection Parameters

### Model Configuration
```bash
# BirdNET Model Settings
MODEL=BirdNET_GLOBAL_6K_V2.4_Model_FP16    # Model version
THREADS=4                                    # CPU threads for analysis
TFLITE_THREADS=4                            # TensorFlow Lite threads
```

### Analysis Timing
```bash
# When to Analyze
DAWN=05:30                          # Dawn start time
DUSK=20:30                          # Dusk end time
FULL_DISK=purge                     # Action when disk full
PURGE_THRESHOLD=95                  # Disk usage % to trigger purge
```

### Privacy and Filtering
```bash
# Privacy Settings
PRIVACY_THRESHOLD=60                # Skip analysis if human detected
HUMAN_THRESHOLD=0.5                 # Human detection sensitivity

# Quality Filters
SAVE_AUDIO=true                     # Save detected audio clips
MIN_QUALITY=0.1                     # Minimum audio quality score
```

## 🐦 Species Management

### Species Lists Location
```bash
# Files in config/ directory:
include_species_list.txt            # Only detect these species
exclude_species_list.txt            # Never detect these species
whitelist_species_list.txt          # Priority species (always save)
confirmed_species_list.txt          # Manually confirmed detections
```

### Include Species Example
```bash
# config/include_species_list.txt
# One species per line, use scientific names
Turdus merula
Passer domesticus
Corvus corone
Falco tinnunculus
```

### Exclude Species Example
```bash
# config/exclude_species_list.txt
# Common false positives in your area
Human
Engine
Dog
Domestic Cat
```

### Species Correction Rules
```bash
# Custom species mapping for systematic errors
# Format: WRONG_SPECIES_CORRECT_SPECIES
SPECIES_MAPPING='{
  "Falco subbuteo": "Falco tinnunculus",
  "Common_false_positive": "Likely_correct_species"
}'
```

## 🔧 Advanced Settings

### Database Configuration
```bash
# Database Settings
DB_PWD=birdnet                      # Database password
SQLITE_CONFIRM_UPDATES=true         # Confirm before updates
BACKUP_RETENTION=30                 # Days to keep backups
```

### Web Interface
```bash
# Web UI Configuration
CADDY_PWD=birdnet                   # Web interface password
BASIC_AUTH=false                    # Enable/disable authentication
WEB_PORT=8081                       # Internal web server port
```

### External Services
```bash
# BirdWeather Integration
BIRDWEATHER_ID=your_station_id      # Your BirdWeather station ID

# Apprise Notifications
APPRISE_ENABLED=false               # Enable notifications
APPRISE_NEW_SPECIES=true            # Notify on new species

# Image Services
FLICKR_API_KEY=your_api_key         # Flickr API for bird images
CUSTOM_IMAGE=false                  # Use custom images
```

### Storage and Performance
```bash
# Storage Settings
RECS_DIR=/config/BirdSongs          # Recording storage location
LOGS_DIR=/config/logs               # Log file location
BACKUP_DIR=/config/backups          # Backup location

# Performance Tuning
WORKER_THREADS=2                    # Analysis worker threads
BATCH_SIZE=1                        # Processing batch size
MEMORY_LIMIT=2048                   # Memory limit in MB
```

## 🌐 Environment Variables

### Docker Compose Variables
```yaml
# In docker-compose.yml environment section:
environment:
  - TZ=Africa/Johannesburg                    # System timezone
  - BIRDSONGS_FOLDER=/config/BirdSongs       # Data folder
  - LIVESTREAM_BOOT_ENABLED=true             # Enable livestream
  - Use_tphakala_model_v2=false              # Model version
  - ssl=false                                # SSL configuration
```

### System Environment Variables
```bash
# Set in host system for container access
RTSP_USERNAME=username              # RTSP authentication
RTSP_PASSWORD=password              # RTSP authentication
MQTT_BROKER=192.168.1.100          # MQTT broker IP
MQTT_USERNAME=mqtt_user            # MQTT authentication
MQTT_PASSWORD=mqtt_pass            # MQTT authentication
```

## 🔍 Configuration Validation

### Check Configuration
```bash
# Validate configuration syntax
docker-compose config

# Test RTSP connection
ffprobe rtsp://YOUR_PI_IP:8554/stream

# Check audio processing
docker-compose exec birdnet-pi grep "READ.*CHUNKS" /var/log/birdnet.log
```

### Common Configuration Issues

#### RTSP Connection Problems
```bash
# Ensure TCP transport is enabled (fixed in Dockerfile)
# Check network connectivity
ping YOUR_PI_IP

# Verify RTSP stream
ffplay rtsp://YOUR_PI_IP:8554/stream
```

#### Geographic Location Errors
```bash
# Validate coordinates
# Latitude: -90 to +90 (South to North)
# Longitude: -180 to +180 (West to East)
# Use decimal degrees, not degrees/minutes/seconds
```

#### Audio Quality Issues
```bash
# Check audio file sizes (should be >1KB)
docker-compose exec birdnet-pi ls -la /config/BirdSongs/By_Date/$(date +%Y-%m-%d)/

# Monitor detection confidence
docker-compose logs | grep "CONFIDENCE"
```

## 📊 Performance Optimization

### Resource Usage Optimization
```bash
# Low-power settings
THREADS=2                           # Reduce CPU threads
TFLITE_THREADS=2                   # Reduce TF threads
RECORDING_LENGTH=10                 # Shorter chunks
BATCH_SIZE=1                       # Single file processing
```

### High-accuracy settings
```bash
# Maximum accuracy (higher resource usage)
THREADS=8                          # Use all CPU cores
OVERLAP=1.0                        # Maximum overlap
SENSITIVITY=1.4                    # Highest sensitivity
EXTRACTION_LENGTH=3                # Standard segment length
```

## 🛠️ Troubleshooting Configuration

### Configuration File Issues
1. **Backup before changes**: `cp config/birdnet.conf config/birdnet.conf.backup`
2. **Use Unix line endings**: Avoid Windows CRLF line endings
3. **No spaces around equals**: Use `SETTING=value` not `SETTING = value`
4. **Quote special characters**: Use quotes for values with spaces or special chars

### Testing Changes
```bash
# Restart container after configuration changes
docker-compose restart

# Monitor logs for configuration errors
docker-compose logs -f | grep -i error

# Validate specific settings
docker-compose exec birdnet-pi cat /home/pi/BirdNET-Pi/birdnet.conf | grep RTSP_STREAM
```

For more specific configuration scenarios, see:
- [Audio Processing Guide](ADVANCED_AUDIO_PROCESSING.md)
- [Pi Setup Guide](PI_PULSEAUDIO_SETUP.md)
- [Windows Optimization](WINDOWS_OPTIMIZATION.md)