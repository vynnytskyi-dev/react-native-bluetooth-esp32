#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ===== Board / sensor setup =====
#define SDA_PIN 6          // XIAO ESP32-C3 I2C SDA
#define SCL_PIN 7          // XIAO ESP32-C3 I2C SCL
#define MPU_ADDR 0x68      // MPU6050 I2C address

// ===== Button (external) =====
#define BUTTON_PIN 2               // Connect button between GPIO2 and GND
#define RESET_LONG_MS 1000         // Long-press duration to trigger reset

// ===== BLE UUIDs =====
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define STEP_DATA_CHAR_UUID "beefcafe-36e1-4688-b7f5-00000000000b"

// ===== BLE objects =====
BLECharacteristic* stepChar = nullptr;
BLEServer* server = nullptr;

// ===== Accelerometer and step detection =====
int16_t ax, ay, az;
int stepCount = 0;
float prevMag = 0.0f;

// ===== Anti double-counting =====
unsigned long lastStepMs = 0;
const uint16_t REFRACT_MS = 350;   // Minimum time between steps (ms)
bool armed = false;                // "armed" flag for step detection state

// Thresholds (tune as needed)
const float ARM_UP_G    = 1.15f;   // Arm when magnitude > this (start of a step)
const float PEAK_MIN_G  = 1.45f;   // Peak must exceed this to count
const float PEAK_DROP_G = 0.12f;   // Must drop at least this much to confirm a step

// ===== Button state =====
bool btnPrevDown = false;
unsigned long btnDownAt = 0;

// ---------- MPU6050 helpers ----------
static inline void mpuWake() {
  // Wake up the MPU6050 (disable sleep mode)
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x6B);
  Wire.write(0x00);
  Wire.endTransmission(true);
}

static inline bool readAccel() {
  // Read raw accelerometer data (6 bytes)
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x3B);
  if (Wire.endTransmission(false) != 0) return false;
  if (Wire.requestFrom(MPU_ADDR, (uint8_t)6, true) != 6) return false;

  ax = (Wire.read() << 8) | Wire.read();
  ay = (Wire.read() << 8) | Wire.read();
  az = (Wire.read() << 8) | Wire.read();
  return true;
}

// ---------- BLE helpers ----------
void bleInit() {
  BLEDevice::init("Step-Sense");   // BLE device name
  server = BLEDevice::createServer();

  BLEService* svc = server->createService(SERVICE_UUID);
  stepChar = svc->createCharacteristic(
    STEP_DATA_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  stepChar->addDescriptor(new BLE2902()); // enable notifications (CCCD)
  svc->start();

  auto adv = BLEDevice::getAdvertising();
  adv->addServiceUUID(SERVICE_UUID);
  adv->setScanResponse(true);
  BLEDevice::startAdvertising();
}

void bleSendSteps() {
  if (server && server->getConnectedCount() > 0 && stepChar) {
    String s = String(stepCount);          // ASCII for easy parsing on iOS
    stepChar->setValue(s.c_str());
    stepChar->notify();
  }
}

// ---------- Setup ----------
void setup() {
  Serial.begin(115200);

  // I2C + sensor
  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setClock(400000);
  mpuWake();

  // BLE
  bleInit();

  // Button
  pinMode(BUTTON_PIN, INPUT_PULLUP);  // Button to GND
}

// ---------- Loop ----------
void loop() {
  // --- Button long-press reset (active-low) ---
  bool down = (digitalRead(BUTTON_PIN) == LOW);
  unsigned long now = millis();

  if (down && !btnPrevDown) {
    // just pressed
    btnDownAt = now;
  }
  if (!down && btnPrevDown) {
    // just released
    if (now - btnDownAt >= RESET_LONG_MS) {
      stepCount = 0;
      bleSendSteps();                 // push 0 to clients if connected
      Serial.println("Steps reset (long press)");
    }
  }
  btnPrevDown = down;

  // --- Read accelerometer & detect steps ---
  if (readAccel()) {
    // Convert to 'g' units
    float x = ax / 16384.0f;
    float y = ay / 16384.0f;
    float z = az / 16384.0f;
    float mag = sqrtf(x*x + y*y + z*z);

    // 1) Arm when magnitude rises above ARM_UP_G
    if (!armed && mag > ARM_UP_G) {
      armed = true;
    }

    // 2) Count step on a valid peak with refractory guard
    if (armed
        && prevMag > mag + PEAK_DROP_G
        && prevMag > PEAK_MIN_G
        && (now - lastStepMs) > REFRACT_MS) {

      stepCount++;
      lastStepMs = now;
      armed = false;  // disarm until next rise

      bleSendSteps();
      Serial.printf("Step: %d\n", stepCount);
    }

    prevMag = mag;
  }

  delay(20); // ~50 Hz sampling rate
}