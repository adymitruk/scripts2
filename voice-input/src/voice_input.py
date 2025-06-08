#!/usr/bin/env python3

import os
import queue
import sounddevice as sd
import vosk
import sys
import json
import threading
import signal
import time
from pynput.keyboard import Key, Controller
import subprocess

# Initialize keyboard controller
keyboard_controller = Controller()

# Audio parameters
SAMPLE_RATE = 16000
CHANNELS = 1
MAIN_MODEL_PATH = f"{os.path.expanduser('~')}/.voice_input_models/vosk-model-en-us-0.42-gigaspeech"

# Initialize models
print("Loading high-accuracy speech recognition model...")
if not os.path.exists(MAIN_MODEL_PATH):
    print(f"Error: Main model not found at {MAIN_MODEL_PATH}")
    print("Please run the installer script first.")
    sys.exit(1)

model = vosk.Model(MAIN_MODEL_PATH)

q = queue.Queue()
text_buffer = []
last_output_time = time.time()
OUTPUT_DELAY = 2.0  # Wait 2 seconds after last speech before outputting with punctuation

# Global flag for stopping
should_stop = False

def signal_handler(signum, frame):
    global should_stop
    print("\nStopping voice input...")
    should_stop = True
    sys.exit(0)

def callback(indata, frames, time, status):
    if status:
        print(status)
    q.put(bytes(indata))

def add_smart_punctuation(text):
    """Add basic punctuation based on text content and patterns"""
    if not text.strip():
        return text
    
    # Capitalize first letter
    text = text.strip()
    if text:
        text = text[0].upper() + text[1:]
    
    # Add question mark for questions
    question_words = ['what', 'when', 'where', 'who', 'why', 'how', 'which', 'whose', 'whom']
    if any(text.lower().startswith(word) for word in question_words):
        return text + "?"
    
    # Add exclamation for certain phrases
    exclamation_words = ['wow', 'amazing', 'incredible', 'stop', 'help', 'yes', 'no']
    if any(word in text.lower() for word in exclamation_words):
        return text + "!"
    
    # Default to period
    return text + "."

def process_buffer():
    """Process accumulated text buffer with basic punctuation and output it"""
    global text_buffer, last_output_time
    
    if not text_buffer:
        return
    
    # Join all text in buffer
    raw_text = " ".join(text_buffer).strip()
    if not raw_text:
        text_buffer = []
        return
    
    try:
        # Apply basic punctuation
        print(f"Raw text: {raw_text}")
        processed_text = add_smart_punctuation(raw_text)
        print(f"Processed: {processed_text}")
        
        # Type the processed text
        keyboard_controller.type(processed_text + " ")
        
    except Exception as e:
        # Fallback: just output the raw text with basic capitalization
        print(f"Processing failed: {e}")
        capitalized_text = raw_text.capitalize()
        keyboard_controller.type(capitalized_text + ". ")
    
    # Clear buffer
    text_buffer = []

def monitor_buffer():
    """Monitor buffer and output text after delay"""
    global text_buffer, last_output_time, should_stop
    
    while not should_stop:
        try:
            current_time = time.time()
            if text_buffer and (current_time - last_output_time) > OUTPUT_DELAY:
                process_buffer()
            time.sleep(0.1)
        except Exception as e:
            print(f"Buffer monitor error: {e}")

def process_audio():
    global should_stop, text_buffer, last_output_time
    try:
        with sd.RawInputStream(
            samplerate=SAMPLE_RATE, 
            channels=CHANNELS, 
            dtype='int16', 
            blocksize=8000, 
            callback=callback
        ):
            print("\n🎤 Advanced Voice Input Active!")
            print("• Speak naturally - model trained on podcasts and conversational speech")
            print("• Natural pauses will trigger automatic punctuation")
            print("• 5.64% word error rate - professional accuracy")
            print("• Press Ctrl+C to stop")
            print("=" * 60)
            
            rec = vosk.KaldiRecognizer(model, SAMPLE_RATE)
            
            while not should_stop:
                try:
                    data = q.get(timeout=0.1)
                    if rec.AcceptWaveform(data):
                        result = json.loads(rec.Result())
                        if result.get("text", "").strip():
                            text = result['text'].strip()
                            print(f"➤ Heard: {text}")
                            text_buffer.append(text)
                            last_output_time = time.time()
                    else:
                        # Partial result - could be used for real-time feedback
                        partial = json.loads(rec.PartialResult())
                        if partial.get("partial", "").strip():
                            # Update last activity time even for partial results
                            last_output_time = time.time()
                            
                except queue.Empty:
                    continue
                except Exception as e:
                    print(f"Recognition error: {e}")
                    continue
                    
    except Exception as e:
        print(f"Audio error: {e}")

def main():
    global should_stop
    
    # Set up signal handler for Ctrl+C
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        print("🎙️  Professional Voice Input with Dictation Support")
        print("=" * 60)
        print("Loading high-accuracy Gigaspeech model...")
        print("This model is optimized for podcasts and natural speech patterns")
        print("=" * 60)
        
        # Start buffer monitor in a separate thread
        buffer_thread = threading.Thread(target=monitor_buffer)
        buffer_thread.daemon = True
        buffer_thread.start()
        
        # Start audio processing in a separate thread
        audio_thread = threading.Thread(target=process_audio)
        audio_thread.daemon = True
        audio_thread.start()

        # Keep the main thread alive
        while not should_stop:
            try:
                time.sleep(0.1)
            except KeyboardInterrupt:
                signal_handler(signal.SIGINT, None)
                
    except KeyboardInterrupt:
        signal_handler(signal.SIGINT, None)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
    finally:
        # Process any remaining text in buffer before exiting
        if text_buffer:
            print("Processing remaining text...")
            process_buffer()

if __name__ == "__main__":
    main() 