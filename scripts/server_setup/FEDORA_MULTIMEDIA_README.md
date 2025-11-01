# Fedora Multimedia Installation Scripts

This directory contains scripts for automating multimedia package installation on Fedora Linux systems.

## Available Scripts

### 1. install_fedora_multimedia.sh
**Standard Version** - Production-ready script with essential features

```bash
sudo ./install_fedora_multimedia.sh
```

**Features:**
- Clean, professional error handling
- Color-coded output for clarity
- Pre-flight system checks
- User confirmation before installation
- Comprehensive logging

**Use when:** You need a reliable, straightforward installation script for system setup.

---

### 2. install_fedora_multimedia_gist.sh
**Enhanced Gist Version** - Feature-rich script optimized for GitHub Gists

```bash
sudo ./install_fedora_multimedia_gist.sh
```

**Features:**
- All features from the standard version, plus:
- Extended documentation and comments
- Emoji indicators for better visual scanning
- Detailed package information during installation
- Enhanced summary with next steps and troubleshooting
- Disk space checking
- More comprehensive error messages
- Beautiful ASCII art header

**Use when:** You want maximum detail, documentation, and visual appeal (perfect for sharing as a gist).

---

## What Gets Installed

Both scripts install the same packages:

1. **Multimedia Group Packages**
   - Audio/video codecs (MP3, AAC, H.264, etc.)
   - Multimedia libraries and frameworks
   - Basic playback utilities

2. **Full FFmpeg**
   - Replaces `ffmpeg-free` with complete FFmpeg
   - Enables support for all common media formats
   - Includes H.264, H.265, AAC, and other proprietary codecs

3. **GStreamer Components**
   - Required for GNOME Videos (Totem)
   - Supports Rhythmbox, Sound Juicer, and other GNOME apps
   - Excludes problematic PackageKit plugin

4. **Sound and Video Utilities**
   - Additional audio/video tools
   - CD/DVD utilities
   - Recording and editing software

## Command Breakdown

```bash
# Step 1: Install multimedia group (codecs and libraries)
sudo dnf group install multimedia

# Step 2: Switch to full FFmpeg (complete format support)
sudo dnf swap 'ffmpeg-free' 'ffmpeg' --allowerasing

# Step 3: Upgrade multimedia and install GStreamer components
sudo dnf upgrade @multimedia \
    --setopt="install_weak_deps=False" \
    --exclude=PackageKit-gstreamer-plugin

# Step 4: Install sound and video utilities
sudo dnf group install sound-and-video
```

### Why These Commands?

- `--allowerasing`: Allows removal of conflicting packages (ffmpeg-free)
- `--setopt="install_weak_deps=False"`: Keeps installation lean by skipping optional dependencies
- `--exclude=PackageKit-gstreamer-plugin`: Avoids conflicts with package managers

## Requirements

- **Operating System**: Fedora Linux (38+)
- **Privileges**: sudo/root access
- **Internet**: Active connection required
- **Disk Space**: ~500MB for packages
- **Time**: 5-15 minutes depending on connection speed

## Safety Features

Both scripts include:
- ✅ Root privilege verification
- ✅ Operating system detection (Fedora only)
- ✅ Internet connectivity check
- ✅ Error handling with meaningful messages
- ✅ User confirmation before making changes
- ✅ Step-by-step progress indicators

## After Installation

### Test Your Setup

```bash
# Check FFmpeg version
ffmpeg -version

# Test video playback (requires a video file)
ffplay your_video.mp4

# Check installed packages
dnf group info multimedia
dnf group info sound-and-video
```

### Recommended Additional Software

```bash
# VLC Media Player (most formats)
sudo dnf install vlc

# MPV (lightweight, powerful)
sudo dnf install mpv

# Celluloid (modern GTK interface for MPV)
sudo dnf install celluloid

# DVD playback support
sudo dnf install libdvdcss

# Blu-ray support
sudo dnf install libbluray
```

## Troubleshooting

### Issue: Package conflicts
**Solution:** Update your system first
```bash
sudo dnf update
```

### Issue: Network timeout
**Solution:** Check your internet and retry
```bash
ping -c 3 fedoraproject.org
```

### Issue: Low disk space
**Solution:** Free up space or specify a different cache
```bash
sudo dnf clean all
```

### Issue: Video still won't play
**Solution:** Try these steps:
1. Restart the application
2. Log out and back in
3. Install VLC as a fallback player
4. Check codec requirements: `dnf provides '*/codec-name'`

## Contributing

If you encounter issues or have improvements:
1. Test thoroughly on a Fedora system
2. Run shellcheck to validate bash syntax
3. Maintain the error handling patterns
4. Update documentation accordingly

## Version History

- **v1.0** (2025-11-01)
  - Initial release
  - Two variants: standard and gist-optimized
  - Comprehensive error handling
  - Full documentation

## License

MIT License - Feel free to use, modify, and share.

## Additional Resources

- [Fedora Multimedia Guide](https://docs.fedoraproject.org/en-US/quick-docs/assembly_installing-plugins-for-playing-movies-and-music/)
- [RPM Fusion Setup](https://rpmfusion.org/Configuration)
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)
- [GStreamer Documentation](https://gstreamer.freedesktop.org/documentation/)
