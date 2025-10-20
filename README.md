# BirdNET-Pi Docker with RTSP Support

[![Docker](https://img.shields.io/badge/Docker-Supported-blue.svg)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![BirdNET](https://img.shields.io/badge/BirdNET-v2.4-orange.svg)](https://birdnet.cornell.edu/)
[![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi-Compatible-red.svg)](https://www.raspberrypi.org/)

A containerized BirdNET-Pi installation optimized for Windows 11 Docker Desktop, featuring RTSP stream support with TCP transport fixes and advanced audio processing capabilities.

## 🎯 Features

- **🐦 Automated Bird Detection**: Real-time bird species identification using BirdNET AI
- **📡 RTSP Stream Support**: Direct integration with Raspberry Pi camera/microphone streams
- **🔧 TCP Transport Fix**: Permanent solution for RTSP connection reliability
- **🎵 Advanced Audio Processing**: PulseAudio echo cancellation and noise reduction
- **🖥️ Windows 11 Optimized**: Specifically configured for Docker Desktop on Windows
- **🔄 Sleep/Wake Resilient**: Automatic recovery from system sleep cycles
- **📊 Live Streaming**: Icecast audio streaming for real-time monitoring
- **🌐 Web Interface**: Comprehensive dashboard for monitoring and configuration

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [System Requirements](#-system-requirements)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Audio Processing](#-audio-processing)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## 🚀 Quick Start

1. **Clone this repository**:
   ```powershell
   git clone https://github.com/harrymnel/birdnet-pi-docker.git
   cd birdnet-pi-docker
   ```

2. **Configure your RTSP stream**:
   ```bash
   # Edit config/birdnet.conf
   RTSP_STREAM=rtsp://YOUR_PI_IP:8554/your_stream_path
   LATITUDE=your_latitude
   LONGITUDE=your_longitude
   ```

3. **Start the container**:
   ```powershell
   docker-compose up -d
   ```

4. **Access the web interface**:
   - Main Interface: http://localhost:8001
   - Live Stream: http://localhost:8000

## 💻 System Requirements

### Windows Host
- **OS**: Windows 11 (Windows 10 also supported)
- **Docker**: Docker Desktop with WSL2 backend
- **Memory**: Minimum 8GB RAM (16GB recommended)
- **Storage**: 20GB+ free space for recordings

### Raspberry Pi (RTSP Source)
- **Model**: Raspberry Pi 3B+ or newer
- **OS**: Raspberry Pi OS (Bullseye or newer)
- **Camera**: USB camera or Pi Camera module
- **Microphone**: USB microphone (recommended with isolator)
- **Network**: Stable WiFi or Ethernet connection

## 🔧 Installation

### Step 1: Prepare Your Raspberry Pi

1. **Set up RTSP streaming** on your Pi:
   ```bash
   # Install required packages
   sudo apt update
   sudo apt install ffmpeg

   # Start RTSP stream (example)
   ffmpeg -f v4l2 -i /dev/video0 -f alsa -i hw:1,0 \
          -c:v h264_v4l2m2m -c:a aac \
          -f rtsp rtsp://0.0.0.0:8554/stream
   ```

2. **Optional: Set up audio processing** (see [Audio Processing Guide](docs/PI_PULSEAUDIO_SETUP.md))

### Step 2: Configure Windows Docker Environment

1. **Install Docker Desktop**:
   - Download from [docker.com](https://www.docker.com/products/docker-desktop/)
   - Enable WSL2 backend
   - Allocate at least 4GB RAM to Docker

2. **Clone and configure this repository**:
   ```powershell
   git clone https://github.com/harrymnel/birdnet-pi-docker.git
   cd birdnet-pi-docker
   
   # Copy example configuration
   copy config\birdnet.conf.example config\birdnet.conf
   ```

3. **Edit configuration**:
   ```bash
   # Essential settings in config/birdnet.conf
   RTSP_STREAM=rtsp://192.168.1.100:8554/stream  # Your Pi's IP
   LATITUDE=-33.9249                              # Your location
   LONGITUDE=18.4241                              # Your location
   CONFIDENCE=0.7                                 # Detection threshold
   ```

### Step 3: Build and Run

```powershell
# Build the custom container with RTSP fixes
docker-compose build

# Start the service
docker-compose up -d

# Check logs
docker-compose logs -f
```

## ⚙️ Configuration

### Essential Settings

| Parameter | Description | Example |
|-----------|-------------|---------|
| `RTSP_STREAM` | RTSP stream URL from your Pi | `rtsp://192.168.1.100:8554/stream` |
| `LATITUDE` | Your geographic latitude | `-33.9249` |
| `LONGITUDE` | Your geographic longitude | `18.4241` |
| `CONFIDENCE` | Detection confidence threshold | `0.7` |
| `SENSITIVITY` | Analysis sensitivity | `1.25` |

### Advanced Configuration

For detailed configuration options, see:
- [Configuration Guide](docs/CONFIGURATION.md)
- [Audio Processing Setup](docs/PI_PULSEAUDIO_SETUP.md)
- [Windows Optimization](docs/WINDOWS_OPTIMIZATION.md)

## 🎵 Audio Processing

This repository includes advanced audio processing capabilities:

### Features
- **Echo Cancellation**: PulseAudio WebRTC-based noise reduction
- **Frequency Filtering**: Optimized for bird call frequency ranges (150Hz-15kHz)
- **Dynamic Range Compression**: Logarithmic amplification for better sensitivity
- **Species Correction**: Post-processing rules for common misidentifications

### Setup
1. **On Raspberry Pi** (recommended):
   ```bash
   # SSH to your Pi and run:
   curl -sSL https://raw.githubusercontent.com/harrymnel/birdnet-pi-docker/main/scripts/setup_pi_audio.sh | bash
   ```

2. **Verify audio processing**:
   ```bash
   pactl list sources short
   # Should show 'processed_microphone'
   ```

See [Audio Processing Guide](docs/ADVANCED_AUDIO_PROCESSING.md) for detailed setup.

## 🔧 Troubleshooting

### Common Issues

#### RTSP Connection Problems
```powershell
# Check RTSP stream accessibility
ffplay rtsp://YOUR_PI_IP:8554/stream

# If connection fails, the TCP transport fix should resolve it
docker-compose logs | Select-String "READ.*CHUNKS"
```

#### Container Won't Start
```powershell
# Check Docker resources
docker system df

# Verify configuration
docker-compose config

# Check logs
docker-compose logs birdnet-pi
```

#### Sleep/Wake Issues
The container includes automatic recovery from Windows sleep cycles. If issues persist:
```powershell
# Manual restart after sleep
docker-compose restart

# Check container health
docker-compose ps
```

### Getting Help

1. Check the [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
2. Review container logs: `docker-compose logs -f`
3. Open an [issue](https://github.com/harrymnel/birdnet-pi-docker/issues)

## 🛠️ Development

### Project Structure
```
birdnet-pi-docker/
├── docker-compose.yml          # Container orchestration
├── Dockerfile                  # Custom image with RTSP fixes
├── config/                     # BirdNET-Pi configuration
│   ├── birdnet.conf           # Main configuration file
│   ├── BirdSongs/             # Recorded bird data
│   └── species_lists/         # Species include/exclude lists
├── docs/                      # Documentation
│   ├── CONFIGURATION.md       # Detailed configuration guide
│   ├── TROUBLESHOOTING.md     # Common issues and solutions
│   └── AUDIO_PROCESSING.md    # Audio enhancement setup
├── scripts/                   # Utility scripts
└── ssl/                       # SSL certificates (optional)
```

### Custom Modifications

The `Dockerfile` includes permanent fixes for RTSP TCP transport:
- **Recording script fix**: Ensures reliable audio capture
- **Livestream script fix**: Enables stable live streaming
- **Health monitoring**: Automatic container recovery
- **Cleanup utilities**: Post-sleep system recovery

### Building from Source

```powershell
# Clone and build
git clone https://github.com/harrymnel/birdnet-pi-docker.git
cd birdnet-pi-docker
docker-compose build --no-cache

# Run with custom configuration
docker-compose up -d
```

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Areas for Contribution
- 🐛 Bug fixes and stability improvements
- 🎵 Audio processing enhancements
- 📖 Documentation improvements
- 🧪 Testing on different hardware configurations
- 🌐 Additional language support

## 📈 Performance

### Expected Detection Rates
- **Urban environments**: 15-30 species per day
- **Suburban areas**: 25-50 species per day  
- **Rural/natural areas**: 40-80+ species per day

### System Resources
- **CPU Usage**: 15-30% (depends on audio processing)
- **Memory**: 2-4GB RAM
- **Storage**: ~100MB per day (varies by activity)
- **Network**: ~50KB/s average RTSP bandwidth

## 🙏 Acknowledgments

- **BirdNET Team** at Cornell Lab of Ornithology for the AI model
- **alexbelgium** for the original BirdNET-Pi Docker container
- **Community contributors** for RTSP fixes and optimizations

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Projects

- [BirdNET-Analyzer](https://github.com/kahst/BirdNET-Analyzer) - Original BirdNET implementation
- [BirdNET-Pi](https://github.com/mcguirepr89/BirdNET-Pi) - Raspberry Pi native installation
- [BirdNET-Go](https://github.com/tphakala/birdnet-go) - Go implementation of BirdNET

---

**🐦 Happy Bird Watching! 🐦**

For support, please check the [documentation](docs/) or open an [issue](https://github.com/harrymnel/birdnet-pi-docker/issues).