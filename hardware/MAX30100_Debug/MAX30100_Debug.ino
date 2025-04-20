#include <Wire.h>
#include "MAX30105.h"

MAX30105 particleSensor;

// Absorbance Variables
float A = 0, diff;
uint16_t irBuffer[25];  // 25 samples, 50 bytes total
uint32_t un_ir_mean;
float irmax = 0.0, irmin = 999999.0;

void setup() {
  Serial.begin(115200);
  Serial.println("Initializing...");

  Wire.begin();

  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30102 not found. Check wiring!");
    while (1);
  }
  Serial.println("Sensor initialized. Place finger on sensor.");
  particleSensor.setup(60, 4, 2, 100, 411, 4096);  // Adjusted settings
  particleSensor.setPulseAmplitudeRed(0x5);
  particleSensor.setPulseAmplitudeIR(0x5);
  particleSensor.setPulseAmplitudeGreen(0);
}

void loop() {
  // Collect IR data
  for (byte i = 0; i < 25; i++) {
    while (!particleSensor.available()) particleSensor.check();
    irBuffer[i] = particleSensor.getIR();
    particleSensor.nextSample();
  }

  // Calculate Absorbance
  un_ir_mean = 0;
  for (byte i = 0; i < 25; i++) {
    un_ir_mean += irBuffer[i];
  }
  un_ir_mean /= 25;

  if (un_ir_mean > irmax) irmax = un_ir_mean;
  if (un_ir_mean < irmin) irmin = un_ir_mean;

  diff = (irmax - irmin);
  if (diff > 1.0) {
    A = log((float)un_ir_mean / diff);
  } else {
    A = 0.0;
  }

  // Send data to Python (keeping format with empty fields)
  Serial.print("DATA,,");
  Serial.print(A, 4);
  Serial.println();

  // Receive glucose prediction from Python
  if (Serial.available()) {
    char buffer[10];
    int len = Serial.readBytesUntil('\n', buffer, 9);
    if (len > 0) {
      buffer[len] = '\0';
      Serial.print("Absorbance=");
      Serial.print(A, 4);
      Serial.print(", Glucose=");
      Serial.println(buffer);
    }
  }

  delay(1000);  // Delay for responsiveness
}

// this is my final code but i want to display heart rate and spo2 also add that part in code plz