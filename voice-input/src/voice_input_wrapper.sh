#!/bin/bash

# Voice Input Wrapper Script
# This script handles virtual environment activation for all shell types

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Activate the virtual environment
echo "Activating Python virtual environment..."
source ~/.voice_input_env/bin/activate

# Run the Python voice input script
echo "Starting voice input system..."
python3 "$SCRIPT_DIR/voice_input.py" 