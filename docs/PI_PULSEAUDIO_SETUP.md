# PulseAudio Implementation on Raspberry Pi (RTSP Source)

## Overview
Since your Pi is the RTSP stream source, implement audio processing there for optimal results.

## Installation on Raspberry Pi

### 1. Install PulseAudio and Modules
```bash
# On your Raspberry Pi (SSH in)
sudo apt update
sudo apt install pulseaudio pulseaudio-module-echo-cancel
sudo apt install pulseaudio-utils alsa-utils
```

### 2. Configure PulseAudio System-Wide
Create `/etc/pulse/system.pa`:
```bash
#!/usr/bin/pulseaudio -nF
#
# System-wide PulseAudio configuration for BirdNET RTSP streaming

# Load the native protocol module
load-module module-native-protocol-unix auth-anonymous=1 socket=/tmp/pulse-socket

# Load ALSA modules for your USB microphone
load-module module-alsa-source device=hw:1,0 source_name=raw_microphone

# Echo cancellation and noise reduction
load-module module-echo-cancel \
    aec_method=webrtc \
    aec_args="analog_gain_control=0 digital_gain_control=1 noise_suppression=1 voice_detection=1" \
    source_name=processed_microphone \
    source_master=raw_microphone \
    sink_name=null_sink \
    sink_master=auto_null.monitor

# Set the processed microphone as default
set-default-source processed_microphone

# Virtual null sink (since we don't need audio output)
load-module module-null-sink sink_name=dummy_output
```

### 3. Create PulseAudio Service
Create `/etc/systemd/system/pulseaudio-system.service`:
```bash
[Unit]
Description=PulseAudio System Service
After=sound.target

[Service]
Type=notify
ExecStart=/usr/bin/pulseaudio --system --realtime --disallow-exit --no-cpu-limit --log-target=journal
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5
TimeoutSec=20

[Install]
WantedBy=multi-user.target
```

### 4. Configure Your RTSP Streaming Script
Modify your Pi's RTSP streaming command to use the processed audio:

**For FFmpeg-based streaming:**
```bash
#!/bin/bash
# Enhanced RTSP streaming with processed audio

# Use PulseAudio processed source
ffmpeg -f pulse -i processed_microphone \
       -f v4l2 -i /dev/video0 \
       -c:a aac -b:a 128k -ar 48000 \
       -c:v h264_v4l2m2m -b:v 1000k \
       -f rtsp rtsp://0.0.0.0:8554/your_stream_path
```

**For GStreamer-based streaming:**
```bash
#!/bin/bash
# GStreamer with PulseAudio processing

gst-launch-1.0 \
    pulsesrc device=processed_microphone ! \
    audioconvert ! audioresample ! \
    voaacenc bitrate=128000 ! aacparse ! \
    mpegtsmux name=mux ! \
    rtspclientsink location=rtsp://0.0.0.0:8554/your_stream_path \
    v4l2src device=/dev/video0 ! \
    video/x-raw,width=640,height=480,framerate=25/1 ! \
    v4l2h264enc ! h264parse ! mux.
```

### 5. Enable and Start Services
```bash
# Enable PulseAudio system service
sudo systemctl enable pulseaudio-system.service
sudo systemctl start pulseaudio-system.service

# Check status
sudo systemctl status pulseaudio-system.service
pulseaudio --check -v
```

## Verification and Testing

### 1. Test Audio Processing
```bash
# List PulseAudio sources
pactl list sources short

# Should show something like:
# processed_microphone    module-echo-cancel.c    s16le 1ch 48000Hz

# Test recording with processed audio
parecord --device=processed_microphone test_processed.wav
```

### 2. Monitor Processing Quality
```bash
# Real-time audio level monitoring
pactl subscribe
```

### 3. Compare Before/After
```bash
# Record raw audio
parecord --device=raw_microphone test_raw.wav

# Record processed audio  
parecord --device=processed_microphone test_processed.wav

# Generate spectrograms to compare
sox test_raw.wav -n spectrogram -o raw_spectrogram.png
sox test_processed.wav -n spectrogram -o processed_spectrogram.png
```

## Advanced Configuration Options

### 1. Fine-tune Echo Cancellation Parameters
Edit the module-echo-cancel line in `/etc/pulse/system.pa`:
```bash
load-module module-echo-cancel \
    aec_method=webrtc \
    aec_args="analog_gain_control=0 digital_gain_control=1 experimental_agc=1 noise_suppression=1 high_pass_filter=1 voice_detection=1 extended_filter=1 delay_agnostic=1" \
    source_name=processed_microphone \
    source_master=raw_microphone
```

### 2. Add Additional Processing Modules
```bash
# Automatic gain control
load-module module-remap-source \
    source_name=agc_microphone \
    master=processed_microphone \
    remix=no

# Low-frequency noise filter (optional)
load-module module-ladspa-sink \
    sink_name=filtered_sink \
    plugin=highpass \
    label=highpass \
    control=200  # 200Hz high-pass filter
```

## Performance Optimization

### 1. CPU Usage Optimization
Add to `/etc/pulse/daemon.conf`:
```bash
# Optimize for low-power Pi
default-sample-format = s16le
default-sample-rate = 48000
alternate-sample-rate = 44100
default-sample-channels = 1
default-channel-map = mono

# Reduce CPU usage
enable-remixing = no
enable-lfe-remixing = no
high-priority = yes
nice-level = -11
realtime-scheduling = yes
realtime-priority = 9

# Buffer settings for Pi
default-fragments = 4
default-fragment-size-msec = 25
```

### 2. Memory Usage
```bash
# Limit memory usage
default-sample-rate = 48000  # Match your requirements exactly
avoid-resampling = yes       # Prevent unnecessary resampling
```

## Troubleshooting

### 1. Check PulseAudio Status
```bash
# Verify PulseAudio is running
pulseaudio --check -v

# Check loaded modules
pactl list modules | grep echo-cancel

# Test microphone access
arecord -l  # Should show your USB mic
pactl list sources short  # Should show processed_microphone
```

### 2. RTSP Stream Verification
```bash
# Test RTSP stream from another device
ffplay rtsp://PI_IP_ADDRESS:8554/your_stream_path

# Check audio in stream
ffprobe rtsp://PI_IP_ADDRESS:8554/your_stream_path
```

### 3. Audio Processing Verification
```bash
# Monitor real-time audio levels
pactl list sources | grep -A 10 processed_microphone

# Check for dropouts or errors
journalctl -u pulseaudio-system.service -f
```

## Integration with Your Current Setup

Your current flow:
```
[USB Mic] → [Pi] → [RTSP Stream] → [Windows Docker] → [BirdNET-Pi]
```

Enhanced flow:
```
[USB Mic] → [Pi + PulseAudio Processing] → [Clean RTSP Stream] → [Windows Docker] → [BirdNET-Pi]
```

## Benefits of Pi-Side Processing

1. **Cleaner Source**: Processing happens before any compression
2. **Lower Latency**: No additional processing delay in Docker
3. **Better Quality**: Avoid processing already-compressed audio
4. **Resource Efficiency**: Use Pi's CPU for audio, Docker for analysis
5. **Easier Debugging**: Direct hardware access and control

## Alternative: Docker Processing (Not Recommended)

If you still want to process in Docker (less optimal):
- More complex setup with audio forwarding
- Potential quality loss from double-processing
- Higher latency
- More difficult to troubleshoot

The Pi-side approach is definitely the way to go for your setup!