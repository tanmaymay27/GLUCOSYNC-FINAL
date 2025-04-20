
# GlucoSync – Non-Invasive Glucose Monitoring System

GlucoSync is a full-stack solution for real-time, non-invasive glucose monitoring. It integrates an IoT hardware prototype, a machine learning model for glucose prediction, and a Flutter app for visualization.

---

## 📁 Project Structure

```
GLUCOSYNC-FINAL-main/
├── Glucosync-ML/      # ML model & Python scripts for inference
├── glucosync/         # Flutter app for health dashboard
├── hardware/          # Arduino code for MAX30102 sensor
```

---

## 🔬 1. Glucosync-ML (Machine Learning & Inference)

**Location:** `GLUCOSYNC-FINAL-main/Glucosync-ML`

This module predicts glucose concentration from light absorbance data using a pre-trained Random Forest model.

### 🔧 Setup

Install Python dependencies:

```bash
pip install pandas scikit-learn pyserial
```

### 🚀 Run Inference

Run this script to start real-time inference:

```bash
cd Glucosync-ML/src
python inference.py
```

- The script reads data over **Serial** from the Arduino (connected MAX30102 sensor).
- It calculates glucose levels using the trained model and sends predictions back via Serial.

> Make sure the correct COM port is configured inside `inference.py`.

---

## ⚙️ 2. hardware (Arduino + MAX30102)

**Location:** `GLUCOSYNC-FINAL-main/hardware`

This contains the Arduino sketch to read IR & Red light data from the MAX30102 sensor and send it to your PC via Serial for glucose prediction.

### 🛠 Requirements

- Arduino Uno or compatible board  
- MAX30102 sensor  
- Arduino IDE  
- `MAX3010x` library (can be installed from Library Manager)

### ⬆️ Upload Instructions

1. Open the `.ino` file in Arduino IDE.
2. Connect your board via USB.
3. Select the correct board and COM port.
4. Click **Upload**.

> The code collects sensor data and sends it to the Python script in real-time.

---

## 📱 3. glucosync (Flutter App)

**Location:** `GLUCOSYNC-FINAL-main/glucosync`

A modern Flutter app to display live glucose, heart rate, SpO₂, and temperature.

### 🧪 Features

- Supabase Authentication (Login/Signup)
- Dashboard with live metrics
- User profile
- Clean UI with splash screen

### ⚙️ Run Instructions

```bash
cd glucosync
flutter pub get
flutter run
```

> You may need to configure your Supabase credentials in the project (check `lib/`).

---

## 🔁 Data Flow Summary

```
MAX30102 (IR/RED light) → Arduino Uno → Serial → inference.py (predict glucose) → Flutter App (UI)
```

---

## 📦 Dependencies

### Python
- pandas
- scikit-learn
- pyserial

### Flutter
- Flutter SDK (>=3.0)
- Supabase Flutter SDK

### Arduino
- MAX3010x library
- Arduino IDE

---

## 👨‍💻 Authors

Developed by the GlucoSync Team  
An integrated IoT + ML + App solution for affordable, non-invasive glucose monitoring.
