# React Native Bluetooth ESP32 Step Counter

A complete step counting system consisting of an ESP32 device with MPU6050 accelerometer and a React Native mobile application with native Bluetooth Low Energy (BLE) integration.

## 📋 Project Documentation

For detailed technical specifications, architecture overview, and implementation details, see:
**[PROJECT_SPECIFICATION.md](./PROJECT_SPECIFICATION.md)**

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- Expo CLI
- Arduino IDE with ESP32 support
- XIAO ESP32-C3 board
- MPU6050 accelerometer sensor

### Hardware Setup

1. **Connect MPU6050 to ESP32:**

   - VCC → 3.3V
   - GND → GND
   - SDA → GPIO6
   - SCL → GPIO7

2. **Connect Reset Button:**

   - One terminal → GPIO2
   - Other terminal → GND

3. **Upload Arduino Code:**
   ```bash
   # Open arduino/step.ino in Arduino IDE
   # Install required libraries: BLEDevice, Wire
   # Upload to XIAO ESP32-C3
   ```

### Mobile Application Setup

1. **Install Dependencies:**

   ```bash
   npm install
   ```

2. **Start Development Server:**

   ```bash
   npx expo start
   ```

3. **Run on Device:**

   ```bash
   # iOS
   npx expo run:ios

   # Android
   npx expo run:android
   ```

## 🏗️ Architecture

- **ESP32 (Arduino):** Step detection using MPU6050 accelerometer
- **React Native:** Cross-platform mobile application
- **TurboModules:** High-performance native BLE integration
- **CoreBluetooth:** iOS Bluetooth Low Energy framework

## 📱 Features

- ✅ Real-time step counting
- ✅ Bluetooth Low Energy communication
- ✅ Automatic device discovery and connection
- ✅ Step counter reset functionality
- ✅ Debug logging and error handling
- ✅ Modern React Native architecture

## 🔧 Configuration

### ESP32 Settings

- **BLE Service UUID:** `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- **Characteristic UUID:** `beefcafe-36e1-4688-b7f5-00000000000b`
- **Sampling Rate:** 50Hz
- **Device Name:** "Step-Sense"

### Mobile App Settings

- **Bundle ID:** com.expo.reactnativebluetoothesp32
- **Minimum iOS:** 13.0+
- **Minimum Android:** API 21+

## 🛠️ Development

### Project Structure

```
├── app/                    # Expo Router application
├── native/                 # Native integration layer
├── ios/modules/StepBle/    # iOS BLE implementation
├── arduino/               # ESP32 Arduino code
└── assets/                # Application resources
```

### Key Technologies

- **React Native 0.81.4** with New Architecture
- **Expo SDK 54** with Expo Router
- **TypeScript** for type safety
- **TurboModules** for native performance
- **CoreBluetooth** for iOS BLE

## 📖 Learn More

- [Expo Documentation](https://docs.expo.dev/)
- [React Native New Architecture](https://reactnative.dev/docs/the-new-architecture/landing-page)
- [CoreBluetooth Framework](https://developer.apple.com/documentation/corebluetooth)
- [ESP32 BLE Arduino](https://github.com/espressif/arduino-esp32)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on both iOS and Android
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.
