import Foundation
import CoreBluetooth
import React

/**
 * StepBleManager - React Native Bluetooth Low Energy module for ESP32 step counter communication
 * 
 * This class implements a React Native TurboModule that handles BLE communication
 * with ESP32 devices that broadcast step count data. It follows the central role
 * in BLE communication, scanning for peripherals and subscribing to step data.
 */
@objc(StepBleManager)
class StepBleManager: RCTEventEmitter, CBCentralManagerDelegate, CBPeripheralDelegate {

  // MARK: - React Native Module Identity
  /// Returns the module name that will be used in JavaScript/TypeScript
  @objc override static func moduleName() -> String! { "StepBleManager" }
  
  /// Indicates that this module requires main queue setup for proper CoreBluetooth operation
  /// CoreBluetooth delegates must run on the main thread for reliable operation
  override static func requiresMainQueueSetup() -> Bool { true }

  // MARK: - Bluetooth Low Energy State Management
  /// Central manager instance that handles BLE scanning and connection management
  private var central: CBCentralManager!
  
  /// Currently connected peripheral device (ESP32 step counter)
  private var peripheral: CBPeripheral?
  
  /// Target service UUID to scan for (defined by ESP32 firmware)
  private var targetService: CBUUID?
  
  /// Target characteristic UUID to subscribe to for step data
  private var targetChar: CBUUID?

  /// Flag to track if React Native has active event listeners
  /// Used to optimize event emission and prevent unnecessary processing
  private var hasListeners = false

  // MARK: - Initialization
  /// Initializes the StepBleManager with a CBCentralManager instance
  /// The central manager is configured to use this class as its delegate
  override init() {
    super.init()
    // Initialize central manager with self as delegate, using default queue (main queue)
    self.central = CBCentralManager(delegate: self, queue: nil)
  }

  // MARK: - React Native Event System
  /// Defines the list of events that this module can emit to React Native
  /// These events correspond to different BLE states and data updates
  override func supportedEvents() -> [String]! {
    return [
      "StepBleOnStep",      // Emitted when step count data is received from ESP32
      "StepBleLog",         // General logging events for debugging
      "StepBleConnected",   // Emitted when successfully connected to ESP32 device
      "StepBleDisconnected", // Emitted when connection to ESP32 is lost
      "StepBleError"        // Emitted when BLE errors occur
    ]
  }

  /// Called by React Native when JavaScript starts listening to events
  /// Enables event emission to prevent unnecessary processing when no listeners exist
  override func startObserving() {
    hasListeners = true
  }

  /// Called by React Native when JavaScript stops listening to events
  /// Disables event emission to optimize performance
  override func stopObserving() {
    hasListeners = false
  }

  /// Internal helper method to emit events to React Native and log to console
  /// - Parameters:
  ///   - name: Event name that matches one of the supported events
  ///   - body: Event payload data to send to React Native
  private func emit(_ name: String, _ body: Any) {
    // Only send events if React Native has active listeners
    if hasListeners {
      sendEvent(withName: name, body: body)
    }
    // Always log to console for debugging purposes
    NSLog("[StepBle] \(name): \(body)")
  }

  // MARK: - Public API Methods (Exported to React Native)
  /// Starts scanning for ESP32 devices with the specified service and characteristic UUIDs
  /// This method is called from React Native to initiate BLE scanning
  /// - Parameters:
  ///   - serviceUUID: The service UUID that ESP32 devices advertise (e.g., "12345678-1234-1234-1234-123456789ABC")
  ///   - charUUID: The characteristic UUID that contains step count data
  @objc(startScan:charUUID:)
  func startScan(_ serviceUUID: String, charUUID: String) {
    // Convert string UUIDs to CBUUID objects for CoreBluetooth
    targetService = CBUUID(string: serviceUUID)
    targetChar = CBUUID(string: charUUID)

    // Verify that Bluetooth is powered on before attempting to scan
    guard central.state == .poweredOn else {
      emit("StepBleError", "Bluetooth is not powered on")
      return
    }

    emit("StepBleLog", "Scanning for \(serviceUUID)")
    // Start scanning for peripherals advertising the target service
    // AllowDuplicatesKey is set to false to avoid duplicate discovery events
    central.scanForPeripherals(
      withServices: [targetService!],
      options: [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: false)]
    )
  }

  /// Stops all BLE operations including scanning and disconnects from any connected peripheral
  /// This method is called from React Native to clean up BLE resources
  @objc
  func stop() {
    // Stop scanning if currently active
    if central.isScanning {
      central.stopScan()
    }
    // Disconnect from peripheral if connected
    if let p = peripheral {
      central.cancelPeripheralConnection(p)
    }
  }

  // MARK: - CBCentralManagerDelegate Methods
  /// Called when the central manager's state changes (e.g., Bluetooth power on/off)
  /// This is a required delegate method for CBCentralManagerDelegate
  /// - Parameter central: The central manager whose state changed
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    emit("StepBleLog", "Central state = \(central.state.rawValue)")
    // Check if Bluetooth is not powered on and emit error if so
    if central.state != .poweredOn {
      emit("StepBleError", "Bluetooth not available")
    }
  }

  /// Called when a peripheral is discovered during scanning
  /// This method handles the discovery of ESP32 devices and initiates connection
  /// - Parameters:
  ///   - central: The central manager that discovered the peripheral
  ///   - peripheral: The discovered peripheral device (ESP32)
  ///   - advertisementData: Advertisement data from the peripheral
  ///   - RSSI: Signal strength indicator
  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String : Any],
    rssi RSSI: NSNumber
  ) {
    emit("StepBleLog", "Discovered \(peripheral.name ?? "(no name)")")
    // Store reference to discovered peripheral and set this class as its delegate
    self.peripheral = peripheral
    self.peripheral?.delegate = self
    // Stop scanning since we found our target device
    central.stopScan()
    // Initiate connection to the discovered peripheral
    central.connect(peripheral, options: nil)
  }

  /// Called when a connection to a peripheral is successfully established
  /// This method triggers service discovery to find the step counter service
  /// - Parameters:
  ///   - central: The central manager that established the connection
  ///   - peripheral: The peripheral that was connected
  func centralManager(
    _ central: CBCentralManager,
    didConnect peripheral: CBPeripheral
  ) {
    emit("StepBleConnected", peripheral.identifier.uuidString)
    // Start discovering services on the connected peripheral
    // Only discover the target service we're interested in
    peripheral.discoverServices([targetService!])
  }

  /// Called when a peripheral disconnects (either intentionally or due to error)
  /// This method handles cleanup when the ESP32 device disconnects
  /// - Parameters:
  ///   - central: The central manager that handled the disconnection
  ///   - peripheral: The peripheral that disconnected
  ///   - error: Optional error information if disconnection was unexpected
  func centralManager(
    _ central: CBCentralManager,
    didDisconnectPeripheral peripheral: CBPeripheral,
    error: Error?
  ) {
    emit("StepBleDisconnected", [:])
  }

  // MARK: - CBPeripheralDelegate Methods
  /// Called when services are discovered on the connected peripheral
  /// This method finds the target service and initiates characteristic discovery
  /// - Parameters:
  ///   - peripheral: The peripheral whose services were discovered
  ///   - error: Optional error if service discovery failed
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    // Iterate through discovered services to find our target service
    for s in peripheral.services ?? [] where s.uuid == targetService {
      // Discover characteristics for the target service
      // Only discover the specific characteristic we need for step data
      peripheral.discoverCharacteristics([targetChar!], for: s)
    }
  }

  /// Called when characteristics are discovered for a service
  /// This method subscribes to notifications for the step count characteristic
  /// - Parameters:
  ///   - peripheral: The peripheral whose characteristics were discovered
  ///   - service: The service whose characteristics were discovered
  ///   - error: Optional error if characteristic discovery failed
  func peripheral(
    _ peripheral: CBPeripheral,
    didDiscoverCharacteristicsFor service: CBService,
    error: Error?
  ) {
    // Iterate through discovered characteristics to find our target characteristic
    for ch in service.characteristics ?? [] where ch.uuid == targetChar {
      emit("StepBleLog", "Subscribed to steps characteristic")
      // Enable notifications for this characteristic to receive updates
      peripheral.setNotifyValue(true, for: ch)
      // Perform initial read to get current step count value
      peripheral.readValue(for: ch)
    }
  }

  /// Called when a characteristic's value is updated (either by notification or read)
  /// This is the main method that processes step count data from the ESP32
  /// - Parameters:
  ///   - peripheral: The peripheral that sent the update
  ///   - characteristic: The characteristic whose value was updated
  ///   - error: Optional error if the update failed
  func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateValueFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    // Check for errors first and log them
    if let e = error {
      emit("StepBleLog", "Update error: \(e.localizedDescription)")
      return
    }

    // Extract data from the characteristic
    let data = characteristic.value ?? Data()
    
    // ESP32 firmware sends step count as ASCII digits (e.g., "42" for 42 steps)
    var str = String(data: data, encoding: .utf8)
    
    // Fallback to hexadecimal representation if UTF-8 decoding fails
    if str == nil {
      // Convert each byte to two-digit hexadecimal string and join them
      str = data.map { String(format: "%02X", $0) }.joined()
    }
    
    // Emit the step count data to React Native
    emit("StepBleOnStep", ["value": str ?? ""])
  }
}