import Foundation
import CoreBluetooth
import React

@objc(StepBleManager)
class StepBleManager: RCTEventEmitter, CBCentralManagerDelegate, CBPeripheralDelegate {

  // MARK: - RN module identity
  @objc override static func moduleName() -> String! { "StepBleManager" }
  override static func requiresMainQueueSetup() -> Bool { true } // CoreBluetooth prefers main thread

  // MARK: - BLE state
  private var central: CBCentralManager!
  private var peripheral: CBPeripheral?
  private var targetService: CBUUID?
  private var targetChar: CBUUID?

  private var hasListeners = false

  // MARK: - Init
  override init() {
    super.init()
    self.central = CBCentralManager(delegate: self, queue: nil)
  }

  // MARK: - Events
  override func supportedEvents() -> [String]! {
    return [
      "StepBleOnStep",
      "StepBleLog",
      "StepBleConnected",
      "StepBleDisconnected",
      "StepBleError"
    ]
  }

  override func startObserving() {
    hasListeners = true
  }

  override func stopObserving() {
    hasListeners = false
  }

  private func emit(_ name: String, _ body: Any) {
    if hasListeners {
      sendEvent(withName: name, body: body)
    }
    NSLog("[StepBle] \(name): \(body)")
  }

  // MARK: - Exported API (TurboModule methods)
  @objc(startScan:charUUID:)
  func startScan(_ serviceUUID: String, charUUID: String) {
    targetService = CBUUID(string: serviceUUID)
    targetChar = CBUUID(string: charUUID)

    guard central.state == .poweredOn else {
      emit("StepBleError", "Bluetooth is not powered on")
      return
    }

    emit("StepBleLog", "Scanning for \(serviceUUID)")
    central.scanForPeripherals(
      withServices: [targetService!],
      options: [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: false)]
    )
  }

  @objc
  func stop() {
    if central.isScanning {
      central.stopScan()
    }
    if let p = peripheral {
      central.cancelPeripheralConnection(p)
    }
  }

  // MARK: - CBCentralManagerDelegate
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    emit("StepBleLog", "Central state = \(central.state.rawValue)")
    if central.state != .poweredOn {
      emit("StepBleError", "Bluetooth not available")
    }
  }

  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String : Any],
    rssi RSSI: NSNumber
  ) {
    emit("StepBleLog", "Discovered \(peripheral.name ?? "(no name)")")
    self.peripheral = peripheral
    self.peripheral?.delegate = self
    central.stopScan()
    central.connect(peripheral, options: nil)
  }

  func centralManager(
    _ central: CBCentralManager,
    didConnect peripheral: CBPeripheral
  ) {
    emit("StepBleConnected", peripheral.identifier.uuidString)
    peripheral.discoverServices([targetService!])
  }

  func centralManager(
    _ central: CBCentralManager,
    didDisconnectPeripheral peripheral: CBPeripheral,
    error: Error?
  ) {
    emit("StepBleDisconnected", [:])
  }

  // MARK: - CBPeripheralDelegate
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    for s in peripheral.services ?? [] where s.uuid == targetService {
      peripheral.discoverCharacteristics([targetChar!], for: s)
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didDiscoverCharacteristicsFor service: CBService,
    error: Error?
  ) {
    for ch in service.characteristics ?? [] where ch.uuid == targetChar {
      emit("StepBleLog", "Subscribed to steps characteristic")
      peripheral.setNotifyValue(true, for: ch)
      peripheral.readValue(for: ch) // initial read
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateValueFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    if let e = error {
      emit("StepBleLog", "Update error: \(e.localizedDescription)")
      return
    }

    let data = characteristic.value ?? Data()
    // Firmware sends ASCII digits ("42")
    var str = String(data: data, encoding: .utf8)
    if str == nil {
      // fallback to hex
      str = data.map { String(format: "%02X", $0) }.joined()
    }
    emit("StepBleOnStep", ["value": str ?? ""])
  }
}