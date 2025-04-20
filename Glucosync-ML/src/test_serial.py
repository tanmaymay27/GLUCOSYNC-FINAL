import serial
print(serial.__version__)
try:
    ser = serial.Serial('COM6', 115200, timeout=1)
    print("Serial opened successfully")
    ser.close()
except serial.SerialException as e:
    print(f"Serial error: {e}")