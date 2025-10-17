# Custom BirdNET-Pi with RTSP TCP Transport Fix
FROM ghcr.io/alexbelgium/birdnet-pi-amd64:latest

# Apply the RTSP TCP transport fix to the recording script
RUN sed -i 's/-vn -thread_queue_size 512 \$TIMEOUT_PARAM -i \${i}/-vn -thread_queue_size 512 -rtsp_transport tcp \$TIMEOUT_PARAM -i \${i}/g' /home/pi/BirdNET-Pi/scripts/birdnet_recording.sh

# Apply the RTSP TCP transport fix to the livestream script
RUN sed -i 's/-ac \${CHANNELS} -i \${SELECTED_RSTP_STREAM}/-ac \${CHANNELS} -rtsp_transport tcp -i \${SELECTED_RSTP_STREAM}/g' /home/pi/BirdNET-Pi/scripts/livestream.sh

# Create a startup script to ensure services start in proper order after sleep/wake
RUN echo '#!/bin/bash\n\
# Wait for system to stabilize after sleep/wake\n\
sleep 2\n\
\n\
# Clear any stale temporary files\n\
find /tmp/StreamData -name "*.wav" -mmin +1 -delete 2>/dev/null || true\n\
\n\
# Restart services in proper order\n\
systemctl restart birdnet_recording.service\n\
sleep 1\n\
systemctl restart birdnet_analysis.service\n\
' > /usr/local/bin/post_wake_cleanup.sh && chmod +x /usr/local/bin/post_wake_cleanup.sh

# Verify both fixes were applied
RUN grep "rtsp_transport tcp" /home/pi/BirdNET-Pi/scripts/birdnet_recording.sh || (echo "ERROR: Recording TCP transport fix not applied!" && exit 1)
RUN grep "rtsp_transport tcp" /home/pi/BirdNET-Pi/scripts/livestream.sh || (echo "ERROR: Livestream TCP transport fix not applied!" && exit 1)

# Add a label to track our customization
LABEL description="BirdNET-Pi with RTSP TCP Transport Fix"
LABEL version="1.0"