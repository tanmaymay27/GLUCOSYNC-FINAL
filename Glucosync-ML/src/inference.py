import serial
import joblib
import numpy as np
import os
import time
import random
from supabase import create_client, Client
from datetime import datetime, timezone, timedelta  # Correct imports

# Verify pyserial
try:
    print(f"pyserial version: {serial.__version__}")
except AttributeError:
    raise SystemExit("❌ pyserial not installed or conflicted. Run 'pip install pyserial' and check for 'serial.py' in directory.")

# Supabase configuration
SUPABASE_URL = "Replace with your Supabase project URL"  # Replace with your Supabase project URL
SUPABASE_KEY = "Replace with your Supabase Anon Key"  # Replace with your Supabase anon public key

# Initialize Supabase client
try:
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    print("✅ Supabase client initialized successfully.")
except Exception as e:
    raise SystemExit(f"❌ Failed to initialize Supabase client: {e}")

# Model loading
model_path = 'rf_glucose_model.pkl'
if not os.path.exists(model_path):
    raise FileNotFoundError(f"The model file '{model_path}' was not found in the current directory: {os.getcwd()}")

best_model = joblib.load(model_path)
print("✅ Model loaded successfully.")

def predict_glucose(absorbance_value):
    value = np.array([[absorbance_value]])
    predicted_glucose = best_model.predict(value)[0]
    return predicted_glucose

# Serial connection
try:
    ser = serial.Serial('COM6', 115200, timeout=1)
    ser.reset_input_buffer()
    print("✅ Serial connection established.")
except serial.SerialException as e:
    raise SystemExit(f"❌ Failed to connect to the serial port: {e}")

print("Listening for Arduino data...")
while True:
    try:
        if ser.in_waiting > 0:
            line = ser.readline().decode('utf-8', errors='ignore').strip()
            print(f"Received: {line}")  # Debug: Show all incoming data

            if not line.startswith("DATA"):
                continue

            data = line.split(",")[1:]  # Skip "DATA"
            print(f"Parsed: {data}")  # Debug: Show parsed data

            # Extract absorbance
            try:
                absorbance = abs(float(data[-1]))  # Take the last value
                glucose = predict_glucose(absorbance)
                print(f"abs: {absorbance:.4f}, glucose: {glucose:.0f} mg/dl")

                # Generate random HR (72-92) and SpO2 (91-98)
                hr = random.randint(72, 92)
                spo2 = random.randint(91, 98)

                # Create IST timestamp
                ist_offset = timedelta(hours=5, minutes=30)
                ist_time = datetime.now(timezone(ist_offset)).isoformat()

                # Send to Supabase
                data_to_insert = {
                    "absorbance": absorbance,
                    "glucose": int(round(glucose)),
                    "created_at": ist_time,
                    "hr": hr,  # Add heart rate
                    "spo2": spo2  # Add SpO2
                }
                response = supabase.table("glucose_readings").insert(data_to_insert).execute()
                print(f"✅ Data sent to Supabase: {data_to_insert}")

                # Send glucose back to Arduino
                ser.write(f"{glucose:.2f}\n".encode('utf-8'))
            except (ValueError, IndexError) as e:
                print(f"Invalid or incomplete data: {e}. Skipping...")
                continue
            except Exception as e:
                print(f"⚠️ Supabase or other error: {e}. Continuing...")
                continue
    except KeyboardInterrupt:
        print("\n🚪 Exiting...")
        ser.close()
        break
    except Exception as e:
        print(f"⚠️ An unexpected error occurred: {e}")
        time.sleep(1)  # Prevent tight loop on errors
