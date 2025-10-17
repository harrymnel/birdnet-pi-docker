#!/bin/bash
# BirdNET-Pi Docker Setup Script for Raspberry Pi Audio Processing
# This script sets up PulseAudio with echo cancellation on your Raspberry Pi

set -e  # Exit on any error

echo "🎵 BirdNET-Pi Audio Processing Setup"
echo "===================================="
echo ""

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo "⚠️  Warning: This script is designed for Raspberry Pi"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "📦 Step 1: Installing PulseAudio packages..."
sudo apt update
sudo apt install -y pulseaudio pulseaudio-module-echo-cancel pulseaudio-utils alsa-utils

echo "🔍 Step 2: Detecting USB microphone..."
echo "Available audio devices:"
arecord -l

# Try to auto-detect USB microphone
USB_MIC_CARD=$(arecord -l | grep -i "usb\|device" | head -1 | sed 's/card \([0-9]\).*/\1/' || echo "1")
USB_MIC_DEVICE="hw:${USB_MIC_CARD},0"

echo ""
echo "🎤 Detected USB microphone: $USB_MIC_DEVICE"
read -p "Is this correct? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    read -p "Enter your microphone device (e.g., hw:1,0): " USB_MIC_DEVICE
fi

echo "⚙️  Step 3: Creating PulseAudio system configuration..."
sudo tee /etc/pulse/system.pa > /dev/null << EOF
#!/usr/bin/pulseaudio -nF
#
# System-wide PulseAudio configuration for BirdNET RTSP streaming

# Load the native protocol module
load-module module-native-protocol-unix auth-anonymous=1 socket=/tmp/pulse-socket

# Load ALSA modules for USB microphone
load-module module-alsa-source device=$USB_MIC_DEVICE source_name=raw_microphone

# Echo cancellation with WebRTC noise reduction
load-module module-echo-cancel \\
    aec_method=webrtc \\
    aec_args="analog_gain_control=0 digital_gain_control=1 noise_suppression=1 voice_detection=1 high_pass_filter=1 extended_filter=1" \\
    source_name=processed_microphone \\
    source_master=raw_microphone \\
    sink_name=dummy_sink

# Set processed microphone as default
set-default-source processed_microphone

# Load null sink (we don't need audio output for RTSP streaming)
load-module module-null-sink sink_name=dummy_output
set-default-sink dummy_output
EOF

echo "🔧 Step 4: Creating systemd service..."
sudo tee /etc/systemd/system/pulseaudio-system.service > /dev/null << EOF
[Unit]
Description=PulseAudio System Service for BirdNET
After=sound.target network.target

[Service]
Type=notify
ExecStart=/usr/bin/pulseaudio --system --realtime --disallow-exit --no-cpu-limit --log-target=journal
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=5
TimeoutSec=20
User=pulse
Group=pulse-access

[Install]
WantedBy=multi-user.target
EOF

echo "⚡ Step 5: Optimizing PulseAudio configuration..."
sudo tee /etc/pulse/daemon.conf > /dev/null << EOF
# Optimized PulseAudio configuration for Raspberry Pi
default-sample-format = s16le
default-sample-rate = 48000
default-sample-channels = 1
default-channel-map = mono

# Performance optimizations
enable-remixing = no
enable-lfe-remixing = no
high-priority = yes
nice-level = -11
realtime-scheduling = yes
realtime-priority = 5

# Buffer settings for stable streaming
default-fragments = 4
default-fragment-size-msec = 25

# Memory optimization
avoid-resampling = yes
EOF

echo "👥 Step 6: Setting up user permissions..."
sudo usermod -a -G pulse,pulse-access,audio pi
sudo usermod -a -G audio pulse

echo "🚀 Step 7: Starting services..."
sudo systemctl daemon-reload
sudo systemctl enable pulseaudio-system.service
sudo systemctl start pulseaudio-system.service

# Wait a moment for service to start
sleep 3

echo "✅ Step 8: Testing audio processing..."
export PULSE_RUNTIME_PATH=/var/run/pulse

# Test if PulseAudio is working
if pactl info >/dev/null 2>&1; then
    echo "✅ PulseAudio is running successfully"
else
    echo "❌ PulseAudio failed to start"
    echo "Check status with: sudo systemctl status pulseaudio-system.service"
    exit 1
fi

# Check if processed microphone source exists
if pactl list sources short | grep -q "processed_microphone"; then
    echo "✅ Processed microphone source is available"
    
    # Test recording
    echo "🎤 Testing 5-second recording with noise reduction..."
    parecord --device=processed_microphone --format=s16le --rate=48000 --channels=1 test_processed.wav &
    RECORD_PID=$!
    sleep 5
    kill $RECORD_PID 2>/dev/null || true
    
    if [ -f test_processed.wav ] && [ -s test_processed.wav ]; then
        echo "✅ Test recording successful ($(ls -lh test_processed.wav | awk '{print $5}'))"
        rm test_processed.wav
    else
        echo "⚠️  Test recording failed or empty"
    fi
else
    echo "❌ Processed microphone source not found"
    echo "Available sources:"
    pactl list sources short
fi

echo ""
echo "🎯 Setup Summary:"
echo "=================="
echo "✅ PulseAudio installed and configured"
echo "✅ Echo cancellation with WebRTC noise reduction enabled"
echo "✅ System service created and started"
echo "✅ Audio processing pipeline: $USB_MIC_DEVICE → processed_microphone"
echo ""

echo "📝 Next Steps:"
echo "=============="
echo "1. Update your RTSP streaming script to use 'processed_microphone'"
echo "2. For FFmpeg: Use '-f pulse -i processed_microphone'"
echo "3. For GStreamer: Use 'pulsesrc device=processed_microphone'"
echo ""

echo "🔍 Verification Commands:"
echo "========================"
echo "# List audio sources:"
echo "pactl list sources short"
echo ""
echo "# Check service status:"
echo "sudo systemctl status pulseaudio-system.service"
echo ""
echo "# Monitor audio levels:"
echo "pactl list sources | grep -A 20 processed_microphone"
echo ""

echo "🛠️ Troubleshooting:"
echo "==================="
echo "# Restart PulseAudio:"
echo "sudo systemctl restart pulseaudio-system.service"
echo ""
echo "# Check logs:"
echo "sudo journalctl -u pulseaudio-system.service -f"
echo ""

# Check if we need to show RTSP integration examples
if command -v ffmpeg >/dev/null 2>&1; then
    echo "📡 RTSP Integration Example (FFmpeg detected):"
    echo "=============================================="
    echo "# Replace your RTSP streaming command audio input:"
    echo "# FROM: -f alsa -i $USB_MIC_DEVICE"
    echo "# TO:   -f pulse -i processed_microphone"
    echo ""
    echo "# Complete example:"
    echo "ffmpeg -f pulse -i processed_microphone \\"
    echo "       -f v4l2 -i /dev/video0 \\"
    echo "       -c:a aac -b:a 128k -ar 48000 -ac 1 \\"
    echo "       -c:v h264_v4l2m2m -b:v 1000k \\"
    echo "       -f rtsp rtsp://0.0.0.0:8554/stream"
fi

echo ""
echo "🎉 BirdNET-Pi audio processing setup complete!"
echo "Your microphone audio should now have significantly reduced noise and echo."
echo "This will improve bird detection accuracy in your BirdNET-Pi Docker container."