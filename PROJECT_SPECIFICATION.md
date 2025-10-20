# Project Specification: React Native Bluetooth ESP32 Step Counter

## Project Overview

This project is a complete step counting system consisting of:

- **ESP32 device** with MPU6050 accelerometer and Bluetooth Low Energy (BLE)
- **React Native application** for iOS/Android with native BLE integration
- **TurboModule architecture** for high-performance communication between JavaScript and native code

## System Architecture

### 1. Hardware Component (ESP32)

**Platform:** XIAO ESP32-C3
**Sensor:** MPU6050 (6-axis accelerometer/gyroscope)
**Communication:** Bluetooth Low Energy (BLE)

#### Technical Specifications:

- **I2C pins:** SDA=6, SCL=7
- **Reset button:** GPIO2 (pull-up to GND)
- **BLE Service UUID:** `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- **Characteristic UUID:** `beefcafe-36e1-4688-b7f5-00000000000b`

#### Step Detection Algorithm:

1. **Data Collection:** Reading accelerometer at 50Hz frequency
2. **Magnitude Calculation:** `sqrt(x² + y² + z²)`
3. **Step Detection:**
   - Arm when magnitude rises above 1.15g
   - Count step on peak > 1.45g with drop > 0.12g
   - Double-count protection (350ms refractory period)

#### Functionality:

- Automatic BLE connection
- Real-time step count transmission
- Counter reset with long button press (1+ second)
- Serial logging for debugging

### 2. Mobile Application (React Native)

**Platform:** Expo SDK 54
**Architecture:** New Architecture (TurboModules)
**Minimum Versions:** iOS 13+, Android API 21+

#### Technology Stack:

- **React Native:** 0.81.4
- **Expo Router:** 6.0.11 (file-based routing)
- **TypeScript:** 5.9.2
- **TurboModules:** Native BLE integration

#### Key Dependencies:

```json
{
  "expo": "~54.0.13",
  "react-native": "0.81.4",
  "react-native-worklets": "0.5.1",
  "@expo/vector-icons": "^15.0.2",
  "expo-haptics": "~15.0.7"
}
```

### 3. Native Integration (iOS)

**Language:** Swift + Objective-C
**Framework:** CoreBluetooth
**Architecture:** TurboModule + RCTEventEmitter

#### Classes and Methods:

**StepBleManager.swift:**

- `startScan(serviceUUID:charUUID:)` - Start BLE scanning
- `stop()` - Stop scanning and disconnect
- `centralManagerDidUpdateState` - Handle Bluetooth state
- `didDiscover` - Handle discovered devices
- `didConnect/didDisconnect` - Manage connections
- `didUpdateValueFor` - Handle characteristic data

#### Events:

- `StepBleOnStep` - Receive new step count
- `StepBleLog` - Debug logging
- `StepBleConnected` - Device connected
- `StepBleDisconnected` - Device disconnected
- `StepBleError` - BLE errors

### 4. JavaScript API

**File:** `native/StepBleClient.ts`

#### Exported Functions:

```typescript
// BLE Management
start(service: string, charUUID: string): void
stop(): void

// Event Subscriptions
onStep(callback: (steps: number) => void): () => void
onLog(callback: (message: string) => void): () => void
```

#### TurboModule Specification:

```typescript
interface Spec extends TurboModule {
  startScan(serviceUUID: string, charUUID: string): void;
  stop(): void;
}
```

## Functional Requirements

### Core Functionality:

1. **ESP32 Connection:** Automatic scanning and connection
2. **Step Display:** Real-time counter updates
3. **Connection Management:** Start/Stop BLE buttons
4. **Logging:** Display last 8 log messages
5. **Counter Reset:** Long button press on ESP32

### UI/UX Requirements:

- **Minimalist Design:** Large step counter (92px)
- **Responsive Layout:** SafeAreaView for different devices
- **Logging:** Compact list of recent messages
- **Control Buttons:** Start BLE / Stop

## Technical Requirements

### Performance:

- **Update Frequency:** 50Hz on ESP32, real-time on mobile
- **TurboModules:** Using new architecture for maximum performance
- **Memory Management:** Automatic listener cleanup on unmount

### Security:

- **Bluetooth Permissions:** Proper permissions in Info.plist
- **Error Handling:** BLE and network error handling
- **Data Validation:** Received data correctness validation

### Compatibility:

- **iOS:** 13.0+ (CoreBluetooth support)
- **Android:** API 21+ (BLE support)
- **ESP32:** ESP32-C3 with BLE support

## Project Structure

```
react-native-bluetooth-esp32/
├── app/                          # Expo Router application
│   ├── _layout.tsx              # Root layout
│   └── index.tsx                 # Main screen
├── native/                       # Native integration
│   ├── specs/
│   │   └── NativeStepBle.ts      # TurboModule specification
│   └── StepBleClient.ts          # JavaScript API
├── ios/modules/StepBle/          # iOS native module
│   ├── StepBleManager.swift      # Main BLE manager
│   └── StepBleManager.m          # Objective-C bridge
├── arduino/                      # ESP32 code
│   └── step.ino                  # Arduino sketch
└── assets/                       # Application resources
```

## Configuration and Setup

### ESP32 Configuration:

- **I2C Frequency:** 400kHz
- **BLE Name:** "Step-Sense"
- **Sampling Rate:** 50Hz (20ms delay)
- **Thresholds:** Configurable step detection parameters

### Mobile Application:

- **Bundle ID:** com.expo.reactnativebluetoothesp32
- **Bluetooth Permissions:** NSBluetoothAlwaysUsageDescription
- **New Architecture:** Enabled for TurboModules

## Deployment and Build

### ESP32:

1. Install Arduino IDE with ESP32 support
2. Install libraries: BLEDevice, Wire
3. Upload code to XIAO ESP32-C3
4. Connect MPU6050 and button

### Mobile Application:

```bash
# Install dependencies
npm install

# Run on iOS
npx expo run:ios

# Run on Android
npx expo run:android

# Development build
npx expo start
```

## Testing and Debugging

### ESP32:

- **Serial Monitor:** 115200 baud for logging
- **LED Indicators:** BLE connection status
- **Test Button:** Counter reset

### Mobile Application:

- **Console Logs:** Detailed BLE operation logging
- **Error Handling:** Error display in UI
- **State Management:** React hooks for state management

## Future Enhancements

### Potential Features:

1. **Data Persistence:** Local step count storage
2. **Statistics:** Charts and analytics
3. **Settings:** Custom detection thresholds
4. **Multi-device:** Multiple ESP32 support
5. **Cloud Sync:** Cloud service synchronization

### Technical Improvements:

1. **Android Support:** Full Android implementation
2. **Background Mode:** Background operation
3. **Battery Optimization:** Battery consumption optimization
4. **Error Recovery:** Automatic connection recovery

---

**Specification Version:** 1.0.0  
**Creation Date:** 2024  
**Author:** Nazar  
**Status:** In Development
