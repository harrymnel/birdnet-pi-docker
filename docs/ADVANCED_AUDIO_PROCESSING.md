# BirdNET-Pi Advanced Audio Processing Configuration

## PulseAudio Noise Reduction Setup

### 1. Install Required Modules
```bash
sudo apt update
sudo apt install pulseaudio-module-echo-cancel
sudo apt install pulseaudio-utils
```

### 2. Configure PulseAudio Echo Cancellation
Edit `/etc/pulse/default.pa`:
```bash
# Add at the end of the file:
load-module module-echo-cancel aec_method=webrtc source_name=birdnet_clean sink_name=birdnet_sink
load-module module-remap-source source_name=birdnet_processed master=birdnet_clean channels=1
set-default-source birdnet_processed
```

### 3. Advanced Noise Gate Configuration
Create `/etc/asound.conf`:
```bash
pcm.birdnet_input {
    type plug
    slave {
        pcm "pulse"
    }
    # Apply noise gate and filtering
    rate_converter "samplerate_best"
}

# Noise gate setup
pcm.noisegate {
    type plug
    slave {
        pcm "hw:1,0"  # Your USB mic
        format S16_LE
        rate 48000
        channels 1
    }
    # Low-level noise suppression
    route_policy copy
}
```

## SOX Real-time Audio Processing

### 1. Install SOX with Effects
```bash
sudo apt install sox libsox-fmt-all
```

### 2. Create Audio Processing Chain
Script for `/usr/local/bin/birdnet_audio_processor.sh`:
```bash
#!/bin/bash
# Advanced audio processing for BirdNET-Pi

# Input from microphone, process, output to virtual device
sox -t alsa hw:1,0 -t alsa hw:Loopback,0,0 \
    highpass 150 \          # Remove low-frequency noise (based on model training)
    lowpass 15000 \         # Remove high-frequency noise (model limit)
    noisered noise.prof 0.2 \  # Noise reduction profile
    compand 0.02,0.05 -60,-60,-30,-15,-20,-10,-5,-8,-2,-8 0 -90 0.1 \  # Dynamic range compression
    gain -n -3              # Normalize and slight reduction to prevent clipping
```

### 3. Create Noise Profile
Generate a noise profile for your environment:
```bash
# Record 10 seconds of ambient noise (no birds)
arecord -D hw:1,0 -f S16_LE -r 48000 -c 1 -d 10 ambient_noise.wav

# Generate noise profile
sox ambient_noise.wav -n noiseprof noise.prof

# Move profile to system location
sudo cp noise.prof /usr/local/share/
```

## Frequency Response Optimization

### Based on BirdNET Model Training (0-15kHz)
```bash
# Optimal frequency filters for BirdNET
# Most bird calls are between 1kHz-8kHz with harmonics up to 15kHz

# Conservative approach (preserves more detail)
sox input.wav output.wav highpass 100 lowpass 15000

# Aggressive approach (focuses on core bird frequencies)
sox input.wav output.wav highpass 300 lowpass 8000 gain 3dB

# Species-specific optimization examples:
# Raptors (low frequency calls): highpass 150 lowpass 4000
# Songbirds (higher frequency): highpass 800 lowpass 12000
# Owls (very low): highpass 100 lowpass 2000
```

## Dynamic Range Processing

### Logarithmic Amplification (as requested)
```bash
# Create logarithmic amplifier effect
sox input.wav output.wav compand 0.1,0.3 -90,-90,-70,-25,-60,-20,-40,-10,-20,-7 0 -90 0.1

# Explanation:
# - Compresses loud sounds less than quiet sounds
# - Brings up quiet bird calls without amplifying loud noise linearly
# - Prevents clipping on sudden loud sounds
```

## BirdNET-Pi Integration

### 1. Modify birdnet.conf for Audio Processing
```bash
# In your birdnet.conf, ensure these settings:
RECORDING_LENGTH=15        # Standard length
EXTRACTION_LENGTH=3        # For processing chunks
CHANNELS=1                 # Mono processing is often cleaner
SAMPLE_RATE=48000         # High quality
```

### 2. Custom Audio Input Script
Replace the default audio input in BirdNET-Pi:
```bash
# Create /home/pi/custom_audio_input.sh
#!/bin/bash
# Process audio through SOX before BirdNET analysis

INPUT_DEVICE="hw:1,0"
OUTPUT_FILE="$1"

sox -t alsa $INPUT_DEVICE "$OUTPUT_FILE" \
    trim 0 15 \
    highpass 150 \
    lowpass 15000 \
    noisered /usr/local/share/noise.prof 0.15 \
    compand 0.02,0.05 -60,-60,-30,-15,-20,-10,-5,-8,-2,-8 0 -90 0.1 \
    gain -n -1
```

## Species-Specific False Positive Handling

### 1. Create Conversion Rules (Like Your Falco Example)
Add to birdnet.conf or create custom script:
```bash
# Species confusion mapping
# Format: "wrong_species:correct_species:confidence_adjustment"
SPECIES_CORRECTIONS=(
    "Falco subbuteo:Falco tinnunculus:-0.1"
    "Common_false_positive:Likely_correct_species:0.0"
)
```

### 2. Confidence Threshold Adjustment
```bash
# Lower confidence for problematic species
# Higher confidence for reliable detections
SPECIES_CONFIDENCE_MAP=(
    "Falco subbuteo:0.85"     # Require higher confidence
    "Common_Blackbird:0.6"    # Allow lower confidence  
    "Corvus_corone:0.75"      # Medium confidence
)
```

## Testing and Validation

### 1. Audio Quality Testing Script
```bash
#!/bin/bash
# Test audio processing chain quality

echo "Testing audio processing pipeline..."

# Test 1: Raw recording
arecord -D hw:1,0 -f S16_LE -r 48000 -c 1 -d 30 test_raw.wav

# Test 2: Processed audio
sox -t alsa hw:1,0 test_processed.wav trim 0 30 \
    highpass 150 lowpass 15000 \
    noisered /usr/local/share/noise.prof 0.2 \
    compand 0.02,0.05 -60,-60,-30,-15,-20,-10,-5,-8,-2,-8 0 -90 0.1

# Test 3: BirdNET analysis comparison
/home/pi/BirdNET-Pi/scripts/analyze_audio.py test_raw.wav > results_raw.txt
/home/pi/BirdNET-Pi/scripts/analyze_audio.py test_processed.wav > results_processed.txt

echo "Compare results_raw.txt vs results_processed.txt"
```

### 2. Spectrogram Analysis
```bash
# Generate spectrograms to visualize improvements
sox test_raw.wav -n spectrogram -o raw_spectrogram.png
sox test_processed.wav -n spectrogram -o processed_spectrogram.png
```

## Performance Monitoring

### 1. Detection Rate Tracking
```bash
# Monitor detection improvements
grep "DETECTED" /var/log/birdnet.log | wc -l  # Before processing
grep "DETECTED" /var/log/birdnet_processed.log | wc -l  # After processing
```

### 2. False Positive Rate
```bash
# Track species corrections over time
grep "CORRECTED" /var/log/birdnet.log | sort | uniq -c
```

## Expected Improvements

Based on the discussion and techniques:

| **Technique** | **Detection Increase** | **Noise Reduction** | **Complexity** |
|---------------|----------------------|-------------------|----------------|
| PulseAudio Echo Cancel | 15-25% | High | Low |
| SOX Processing Chain | 10-30% | Very High | Medium |
| Logarithmic Compression | 20-40% (quiet sources) | Medium | Medium |
| Species Correction Rules | N/A (accuracy) | N/A | Low |
| Frequency Filtering | 5-15% | High | Low |

The key insight from the discussion is that **noise cancellation works best for close sources**, while **minimal processing preserves sensitivity for distant calls**. You might want to implement **adaptive processing** based on signal strength!