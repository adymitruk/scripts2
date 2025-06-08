#!/bin/bash

# Exit on any error
set -e

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VOICE_INPUT_DIR="$SCRIPT_DIR/voice-input"

echo "=========================================="
echo "Voice Input Installation Script"
echo "=========================================="
echo ""
echo "This script will install:"
echo "1. Voice Input Utility (core functionality)"
echo "2. KDE Plasmoid Widget (optional)"
echo ""

# ===========================================
# SECTION 1: VOICE UTILITY INSTALLATION
# ===========================================

echo "=========================================="
echo "SECTION 1: Installing Voice Utility"
echo "=========================================="

echo "Installing required system packages..."
sudo apt-get update
sudo apt-get install -y \
    python3-pip \
    python3-venv \
    portaudio19-dev \
    python3-pyaudio \
    xclip \
    wmctrl

echo "Setting up Python virtual environment..."
python3 -m venv ~/.voice_input_env
source ~/.voice_input_env/bin/activate

echo "Installing Python packages from requirements.txt..."
pip install -r "$VOICE_INPUT_DIR/config/requirements.txt"

echo "Downloading speech recognition models..."
MODEL_DIR="$HOME/.voice_input_models"
mkdir -p "$MODEL_DIR"
cd "$MODEL_DIR"

echo "Downloading high-accuracy dictation model (2.3GB - this may take a while)..."
echo "This model is trained on Gigaspeech dataset and optimized for podcasts/conversational speech"
if [ ! -d "vosk-model-en-us-0.42-gigaspeech" ]; then
    wget https://alphacephei.com/vosk/models/vosk-model-en-us-0.42-gigaspeech.zip
    echo "Extracting dictation model..."
    unzip vosk-model-en-us-0.42-gigaspeech.zip
    rm vosk-model-en-us-0.42-gigaspeech.zip
fi

# Return to script directory
cd "$SCRIPT_DIR"

echo "Installing voice input script..."
mkdir -p ~/.local/bin
cp "$VOICE_INPUT_DIR/src/voice_input.py" ~/.local/bin/
cp "$VOICE_INPUT_DIR/src/voice_input_wrapper.sh" ~/.local/bin/
chmod +x ~/.local/bin/voice_input.py
chmod +x ~/.local/bin/voice_input_wrapper.sh

echo "Installing desktop integration..."
mkdir -p ~/.local/share/applications
cp "$VOICE_INPUT_DIR/desktop/voice-input.desktop" ~/.local/share/applications/

echo ""
echo "✅ Voice Utility installation complete!"
echo ""
echo "🎤 PROFESSIONAL DICTATION SYSTEM"
echo "Features:"
echo "• High-accuracy dictation with 5.64% word error rate"
echo "• Gigaspeech model trained on podcasts/conversational speech"
echo "• Smart punctuation and capitalization based on context"
echo "• Natural pause-based sentence detection"
echo "• Professional-grade accuracy for continuous speech"
echo ""
echo "You can now use voice input by:"
echo "• Running: ~/.local/bin/voice_input_wrapper.sh (works with all shells)"
echo "• Or search for 'Voice Input' in your application menu"
echo ""
echo "⚠️  Note: First run may take longer as the 2.3GB model loads"
echo ""

# ===========================================
# SECTION 2: PLASMOID INSTALLATION
# ===========================================

echo "=========================================="
echo "SECTION 2: KDE Plasmoid Widget (Optional)"
echo "=========================================="
echo ""
echo "The KDE Plasmoid provides a panel widget with start/stop toggle functionality."
echo ""
read -p "Would you like to install the KDE plasmoid widget? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Installing KDE plasmoid..."
    
    # Check if we're in a KDE environment
    if [ "$XDG_CURRENT_DESKTOP" = "KDE" ] || [ "$DESKTOP_SESSION" = "plasma" ]; then
        echo "✅ KDE/Plasma desktop detected"
    else
        echo "⚠️  Warning: KDE/Plasma desktop not detected. The plasmoid may not work properly."
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Plasmoid installation skipped."
            exit 0
        fi
    fi
    
    # Install plasmoid
    mkdir -p ~/.local/share/plasma/plasmoids
    cp -r "$VOICE_INPUT_DIR/plasmoid/org.adam.voiceinput" ~/.local/share/plasma/plasmoids/
    
    echo ""
    echo "✅ Plasmoid installed successfully!"
    echo ""
    echo "To add the widget to your panel:"
    echo "1. Right-click on your KDE panel"
    echo "2. Select 'Add Widgets...'"
    echo "3. Search for 'Voice Input Toggle'"
    echo "4. Drag it to your panel"
    echo ""
    echo "The widget provides:"
    echo "• One-click start/stop functionality"
    echo "• Visual status indicator (microphone icon)"
    echo "• Tooltip with current status"
    
else
    echo ""
    echo "Plasmoid installation skipped."
fi

echo ""
echo "=========================================="
echo "INSTALLATION SUMMARY"
echo "=========================================="
echo "✅ Voice Input Utility: Installed"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "✅ KDE Plasmoid Widget: Installed"
else
    echo "❌ KDE Plasmoid Widget: Skipped"
fi
echo ""
echo "📖 For detailed usage instructions, see: $VOICE_INPUT_DIR/README.md"
echo ""
echo "🎤 Ready for professional dictation!"
echo "📝 Speak naturally - optimized for conversational speech"
echo "⚡ High-accuracy recognition (5.64% WER) with smart punctuation"
echo "🎯 Model trained on podcasts and natural speech patterns"
echo "🛑 Press Ctrl+C to stop when running from terminal."
echo ""
echo "=========================================="
read -p "Would you like to view the README with usage instructions? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "=========================================="
    echo "README.md - Voice Input Usage Guide"
    echo "=========================================="
    cat "$VOICE_INPUT_DIR/README.md"
else
    echo ""
    echo "README available at: $VOICE_INPUT_DIR/README.md"
fi 