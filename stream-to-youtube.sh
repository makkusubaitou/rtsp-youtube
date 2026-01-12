#!/bin/bash
# =============================================================================
# RTSP to YouTube Live Stream Relay
# For Raspberry Pi - Auto-starts on boot via systemd
# =============================================================================

set -e

# Load configuration
CONFIG_FILE="/etc/rtsp-youtube/config.env"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Error: Config file not found at $CONFIG_FILE"
    echo "Please run: sudo ./install.sh"
    exit 1
fi

# Validate required variables
if [ -z "$RTSP_URL" ] || [ -z "$YOUTUBE_STREAM_KEY" ]; then
    echo "Error: RTSP_URL and YOUTUBE_STREAM_KEY must be set in $CONFIG_FILE"
    exit 1
fi

# YouTube RTMP ingest URL
YOUTUBE_RTMP_URL="rtmp://a.rtmp.youtube.com/live2/${YOUTUBE_STREAM_KEY}"

# Default values if not set in config
VIDEO_BITRATE="${VIDEO_BITRATE:-2500k}"
AUDIO_BITRATE="${AUDIO_BITRATE:-128k}"
FRAMERATE="${FRAMERATE:-30}"
RESOLUTION="${RESOLUTION:-1280x720}"
RECONNECT_DELAY="${RECONNECT_DELAY:-5}"
MAX_RETRIES="${MAX_RETRIES:-0}"  # 0 = infinite retries

# Logging
LOG_DIR="/var/log/rtsp-youtube"
mkdir -p "$LOG_DIR" 2>/dev/null || true
LOG_FILE="$LOG_DIR/stream.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

cleanup() {
    log "Shutting down stream..."
    kill $FFMPEG_PID 2>/dev/null || true
    exit 0
}

trap cleanup SIGTERM SIGINT

log "=========================================="
log "Starting RTSP to YouTube Stream Relay"
log "=========================================="
log "RTSP Source: $RTSP_URL"
log "Resolution: $RESOLUTION @ ${FRAMERATE}fps"
log "Video Bitrate: $VIDEO_BITRATE"
log "Audio Bitrate: $AUDIO_BITRATE"
log "=========================================="

retry_count=0

while true; do
    log "Attempting to connect to RTSP stream..."
    
    # FFmpeg command for RTSP to YouTube
    # -rtsp_transport tcp: Use TCP for more reliable RTSP connection
    # -re: Read input at native frame rate (important for live streaming)
    # -c:v libx264: Re-encode video with H.264 (YouTube compatible)
    # -preset veryfast: Good balance of speed and quality for Pi
    # -tune zerolatency: Optimize for low-latency streaming
    # -c:a aac: Re-encode audio to AAC (YouTube compatible)
    # -f flv: Output format for RTMP
    
    ffmpeg \
        -rtsp_transport tcp \
        -i "$RTSP_URL" \
        -c:v libx264 \
        -preset veryfast \
        -tune zerolatency \
        -b:v "$VIDEO_BITRATE" \
        -maxrate "$VIDEO_BITRATE" \
        -bufsize "$(echo $VIDEO_BITRATE | sed 's/k//')k" \
        -vf "scale=$RESOLUTION:force_original_aspect_ratio=decrease,pad=$RESOLUTION:(ow-iw)/2:(oh-ih)/2" \
        -r "$FRAMERATE" \
        -g $((FRAMERATE * 2)) \
        -keyint_min "$FRAMERATE" \
        -sc_threshold 0 \
        -c:a aac \
        -b:a "$AUDIO_BITRATE" \
        -ar 44100 \
        -f flv \
        "$YOUTUBE_RTMP_URL" 2>&1 | tee -a "$LOG_FILE" &
    
    FFMPEG_PID=$!
    
    log "FFmpeg started with PID: $FFMPEG_PID"
    
    # Wait for FFmpeg to finish (or crash)
    wait $FFMPEG_PID
    EXIT_CODE=$?
    
    log "FFmpeg exited with code: $EXIT_CODE"
    
    # Check retry limit
    retry_count=$((retry_count + 1))
    if [ "$MAX_RETRIES" -gt 0 ] && [ "$retry_count" -ge "$MAX_RETRIES" ]; then
        log "Max retries ($MAX_RETRIES) reached. Exiting."
        exit 1
    fi
    
    log "Reconnecting in $RECONNECT_DELAY seconds... (attempt $retry_count)"
    sleep "$RECONNECT_DELAY"
done
