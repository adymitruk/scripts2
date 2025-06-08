#!/bin/bash

PIDFILE="$HOME/.voice_input.pid"
SCRIPT_PATH="$HOME/.local/bin/voice_input.py"
VENV_PATH="$HOME/.voice_input_env"

case "$1" in
    start)
        if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
            echo "Voice input is already running"
            exit 1
        fi
        
        # Check if script exists
        if [ ! -f "$SCRIPT_PATH" ]; then
            echo "Voice input script not found at $SCRIPT_PATH"
            exit 1
        fi
        
        # Check if virtual environment exists
        if [ ! -d "$VENV_PATH" ]; then
            echo "Virtual environment not found at $VENV_PATH"
            exit 1
        fi
        
        # Start voice input in background
        bash -c "source $VENV_PATH/bin/activate && nohup python3 $SCRIPT_PATH > /dev/null 2>&1 &"
        
        # Get the PID of the Python process
        sleep 1
        PID=$(pgrep -f "python3.*voice_input.py" | head -1)
        if [ -n "$PID" ]; then
            echo $PID > "$PIDFILE"
            echo "Voice input started"
        else
            echo "Failed to start voice input"
            exit 1
        fi
        ;;
    
    stop)
        if [ ! -f "$PIDFILE" ]; then
            # Try to find and kill any running voice input processes
            PIDS=$(pgrep -f "python3.*voice_input.py")
            if [ -n "$PIDS" ]; then
                echo $PIDS | xargs kill
                echo "Voice input stopped"
            else
                echo "Voice input is not running"
            fi
            exit 0
        fi
        
        PID=$(cat "$PIDFILE")
        if kill -0 "$PID" 2>/dev/null; then
            kill "$PID"
            rm -f "$PIDFILE"
            echo "Voice input stopped"
        else
            rm -f "$PIDFILE"
            # Try to find and kill any running voice input processes
            PIDS=$(pgrep -f "python3.*voice_input.py")
            if [ -n "$PIDS" ]; then
                echo $PIDS | xargs kill
                echo "Voice input stopped"
            else
                echo "Voice input was not running"
            fi
        fi
        ;;
    
    status)
        # Check if PID file exists and process is running
        if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
            echo "running"
        else
            # Also check if any voice input process is running without PID file
            if pgrep -f "python3.*voice_input.py" > /dev/null; then
                echo "running"
            else
                echo "stopped"
            fi
        fi
        ;;
    
    *)
        echo "Usage: $0 {start|stop|status}"
        exit 1
        ;;
esac 