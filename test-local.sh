#!/bin/bash
# =============================================================================
# Local Test Script - Tests FFmpeg encoding without a real RTSP stream
# Uses a test pattern as input
# =============================================================================

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     RTSP to YouTube - Local Test Mode                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check if YouTube stream key is provided
if [ -z "$1" ]; then
    echo "Usage: ./test-local.sh YOUR_YOUTUBE_STREAM_KEY"
    echo ""
    echo "To get your stream key:"
    echo "  1. Go to https://studio.youtube.com"
    echo "  2. Click Create → Go Live"
    echo "  3. Copy the Stream Key"
    echo ""
    echo "Or, to just test FFmpeg encoding locally (no YouTube):"
    echo "  ./test-local.sh test"
    echo ""
    exit 1
fi

STREAM_KEY="$1"

if [ "$STREAM_KEY" == "test" ]; then
    echo "🧪 Running in TEST mode (encoding only, no upload)"
    echo "   This will generate a 10-second test video file"
    echo ""
    
    OUTPUT_FILE="test-output-$(date +%s).mp4"
    
    ffmpeg \
        -f lavfi -i "testsrc=size=1280x720:rate=30" \
        -f lavfi -i "sine=frequency=440:sample_rate=44100" \
        -t 10 \
        -c:v libx264 \
        -preset veryfast \
        -tune zerolatency \
        -b:v 2500k \
        -c:a aac \
        -b:a 128k \
        -f mp4 \
        "$OUTPUT_FILE"
    
    echo ""
    echo "✅ Test complete! Output saved to: $OUTPUT_FILE"
    echo "   Play it with: open $OUTPUT_FILE"
    
else
    echo "🔴 LIVE MODE - Streaming to YouTube"
    echo "   Press Ctrl+C to stop"
    echo ""
    
    YOUTUBE_RTMP_URL="rtmp://a.rtmp.youtube.com/live2/${STREAM_KEY}"
    
    ffmpeg \
        -f lavfi -i "testsrc=size=1280x720:rate=30:duration=300" \
        -f lavfi -i "sine=frequency=440:sample_rate=44100:duration=300" \
        -c:v libx264 \
        -preset veryfast \
        -tune zerolatency \
        -b:v 2500k \
        -maxrate 2500k \
        -bufsize 2500k \
        -vf "drawtext=fontsize=60:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2:text='Test Stream %{localtime}'" \
        -g 60 \
        -keyint_min 30 \
        -c:a aac \
        -b:a 128k \
        -ar 44100 \
        -f flv \
        "$YOUTUBE_RTMP_URL"
fi
