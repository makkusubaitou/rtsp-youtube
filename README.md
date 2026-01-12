# RTSP to YouTube Live Stream Relay

A lightweight script for Raspberry Pi that captures an RTSP stream (like from an IP camera) and relays it to YouTube Live.

## Features

- 🚀 **Auto-starts on boot** via systemd
- 🔄 **Auto-reconnects** if stream drops
- 📊 **Configurable quality** settings
- 📝 **Logging** for troubleshooting
- 🔒 **Security hardened** systemd service

## Requirements

- Raspberry Pi (tested on Pi 3B+, Pi 4)
- Raspbian/Raspberry Pi OS
- Network access to your RTSP camera
- YouTube account with live streaming enabled

## Quick Start

### 1. Copy files to your Raspberry Pi

```bash
scp -r ./* pi@raspberrypi.local:~/rtsp-youtube/
```

### 2. SSH into your Pi and run the installer

```bash
ssh pi@raspberrypi.local
cd ~/rtsp-youtube
sudo ./install.sh
```

### 3. Configure your stream

```bash
sudo nano /etc/rtsp-youtube/config.env
```

Set these required values:
- `RTSP_URL` - Your camera's RTSP stream URL
- `YOUTUBE_STREAM_KEY` - From YouTube Studio → Go Live → Stream Key

### 4. Test manually first

```bash
sudo /usr/local/bin/stream-to-youtube.sh
```

Watch for errors. Once it's working, press `Ctrl+C` to stop.

### 5. Enable auto-start

```bash
sudo systemctl enable rtsp-youtube
sudo systemctl start rtsp-youtube
```

## Finding Your RTSP URL

Common RTSP URL formats by manufacturer:

| Brand | URL Format |
|-------|------------|
| Hikvision | `rtsp://admin:password@IP:554/Streaming/Channels/101` |
| Dahua | `rtsp://admin:password@IP:554/cam/realmonitor?channel=1&subtype=0` |
| Reolink | `rtsp://admin:password@IP:554/h264Preview_01_main` |
| Amcrest | `rtsp://admin:password@IP:554/cam/realmonitor?channel=1&subtype=0` |
| Generic | `rtsp://user:pass@IP:554/stream1` |

**Tip:** Use VLC to test your RTSP URL first: `Media → Open Network Stream`

## Getting Your YouTube Stream Key

1. Go to [YouTube Studio](https://studio.youtube.com)
2. Click **Create** → **Go Live**
3. Set up your stream details
4. Copy the **Stream Key** (keep this secret!)

## Configuration Options

Edit `/etc/rtsp-youtube/config.env`:

| Variable | Default | Description |
|----------|---------|-------------|
| `RTSP_URL` | *required* | Your camera's RTSP URL |
| `YOUTUBE_STREAM_KEY` | *required* | YouTube stream key |
| `VIDEO_BITRATE` | `2500k` | Video bitrate (1500-4000k for 720p) |
| `AUDIO_BITRATE` | `128k` | Audio bitrate |
| `FRAMERATE` | `30` | Output frame rate |
| `RESOLUTION` | `1280x720` | Output resolution |
| `RECONNECT_DELAY` | `5` | Seconds between reconnect attempts |
| `MAX_RETRIES` | `0` | Max retries (0 = infinite) |

### Recommended Settings by Pi Model

| Model | Resolution | Bitrate | Notes |
|-------|------------|---------|-------|
| Pi 4 | 1920x1080 | 4000k | Can handle 1080p |
| Pi 3B+ | 1280x720 | 2500k | Comfortable at 720p |
| Pi 3 | 854x480 | 1500k | Stick to 480p |
| Pi Zero | 640x360 | 800k | May struggle |

## Service Management

```bash
# Check status
sudo systemctl status rtsp-youtube

# Start/stop/restart
sudo systemctl start rtsp-youtube
sudo systemctl stop rtsp-youtube
sudo systemctl restart rtsp-youtube

# View live logs
sudo journalctl -u rtsp-youtube -f

# View recent logs
sudo journalctl -u rtsp-youtube --since "1 hour ago"

# Disable auto-start
sudo systemctl disable rtsp-youtube
```

## Troubleshooting

### Stream won't connect

1. **Test RTSP URL with VLC first**
2. Check camera is on the same network
3. Verify credentials in the URL
4. Try TCP transport: Some cameras need this (already enabled in script)

### YouTube says "No data"

1. Check your stream key is correct
2. Ensure YouTube Live is "scheduled" or waiting for stream
3. Check FFmpeg output in logs: `sudo journalctl -u rtsp-youtube -f`

### High CPU / overheating

1. Lower the resolution in config
2. Lower the frame rate to 15 or 24
3. Add a heatsink/fan to your Pi
4. Use `-preset ultrafast` instead of `veryfast` (edit script)

### Stream keeps reconnecting

1. Check your network stability
2. Increase `RECONNECT_DELAY` in config
3. Check if your camera has a stream timeout setting

## Files

| Path | Description |
|------|-------------|
| `/usr/local/bin/stream-to-youtube.sh` | Main streaming script |
| `/etc/rtsp-youtube/config.env` | Configuration file |
| `/etc/systemd/system/rtsp-youtube.service` | Systemd service |
| `/var/log/rtsp-youtube/stream.log` | Log file |

## Uninstall

```bash
sudo ./uninstall.sh
```

## License

MIT License - Do whatever you want with it!
