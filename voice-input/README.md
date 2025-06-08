# Voice Input for Linux

A complete voice-to-text input solution for Linux systems using offline speech recognition.

## Features

- **Offline Speech Recognition**: Uses Vosk for local speech processing
- **Direct Text Input**: Types recognized speech directly into active applications
- **KDE Widget**: Plasmoid widget for easy start/stop control
- **Desktop Integration**: Application launcher and desktop file
- **Virtual Environment**: Isolated Python dependencies

## Installation

Run the installer script from the repository root:

```bash
./install_voice_input.sh
```

This will:
1. Install required system packages
2. Create a Python virtual environment
3. Download the speech recognition model
4. Set up the voice input script
5. Create desktop integration files

## Usage

### Command Line

**For Fish Shell Users (Recommended):**
```bash
# Use the wrapper script (works with all shells)
~/.local/bin/voice_input_wrapper.sh
```

**For Bash/Zsh Users:**
```bash
# Activate the virtual environment and run
source ~/.voice_input_env/bin/activate
python3 ~/.local/bin/voice_input.py
```

### Desktop Application
- Search for "Voice Input" in your application menu
- Click to launch in a terminal

### KDE Plasmoid Widget
1. Install the plasmoid:
   ```bash
   cp -r voice-input/plasmoid/org.adam.voiceinput ~/.local/share/plasma/plasmoids/
   ```
2. Add widget to panel: Right-click panel → Add Widgets → Voice Input Toggle

## Directory Structure

```
voice-input/
├── src/                    # Source code
│   └── voice_input.py     # Main Python script
├── desktop/               # Desktop integration
│   └── voice-input.desktop
├── plasmoid/              # KDE widget
│   └── org.adam.voiceinput/
├── config/                # Configuration files
│   └── requirements.txt   # Python dependencies
└── README.md              # This file
```

## Dependencies

### System Packages
- python3-pip, python3-venv
- portaudio19-dev, python3-pyaudio
- xclip, wmctrl

### Python Packages
- vosk (speech recognition)
- sounddevice (audio capture)
- pynput, keyboard (input simulation)

## Configuration

- **Model Location**: `~/.voice_input_models/vosk-model-small-en-us-0.15`
- **Virtual Environment**: `~/.voice_input_env`
- **Script Location**: `~/.local/bin/voice_input.py`

## Troubleshooting

### Permission Issues
Make sure your user is in the `audio` group:
```bash
sudo usermod -a -G audio $USER
```

### Microphone Access
Check microphone permissions and test with:
```bash
arecord -l  # List audio devices
```

### Dependencies
If installation fails, manually install dependencies:
```bash
sudo apt-get install python3-pip python3-venv portaudio19-dev python3-pyaudio xclip wmctrl
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

GPL - See license information in the main repository. 