import Foundation
import CoreBluetooth
import React

@objc(StepBleManager)
class StepBleManager: RCTEventEmitter, CBCentralManagerDelegate, CBPeripheralDelegate {

  private var central: CBCentralManager!
  private var peripheral: CBPeripheral?
  private var targetService: CBUUID?
  private var targetChar: CBUUID?

  private var hasListeners = false

  override init() {
    super.init()
    self.central = CBCentralManager(delegate: self, queue: nil)
  }

  // MARK: - React
  override static func requiresMainQueueSetup() -> Bool { true }

  override func supportedEvents() -> [String]! {
    return ["StepBleOnStep", "StepBleLog", "StepBleConnected", "StepBleDisconnected", "StepBleError"]
  }

  override func startObserving() { hasListeners = true }
  override func stopObserving() { hasListeners = false }

  private func log(_ msg: String) {
    if hasListeners { sendEvent(withName: "StepBleLog", body: msg) }
    NSLog("[StepBle] %@", msg)
  }

  // MARK: - Exposed methods

  /// Start scan by service UUID (string)
  @objc(startScan:charUUID:)
  func startScan(serviceUUID: String, charUUID: String) {
    targetService = CBUUID(string: serviceUUID)
    targetChar = CBUUID(string: charUUID)

    guard central.state == .poweredOn else {
      log("Central not powered on yet")
      return
    }
    log("Scanning for \(serviceUUID)")
    central.scanForPeripherals(withServices: [targetService!], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
  }

  @objc(stop)
  func stop() {
    if central.isScanning { central.stopScan() }
    if let p = peripheral { central.cancelPeripheralConnection(p) }
  }

  // MARK: - CBCentralManagerDelegate

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    log("Central state = \(central.state.rawValue)")
    if central.state != .poweredOn {
      if hasListeners { sendEvent(withName: "StepBleError", body: "Bluetooth is not available") }
    }
  }

  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                      advertisementData: [String : Any], rssi RSSI: NSNumber) {
    log("Discovered \(peripheral.name ?? "(no name)")")
    self.peripheral = peripheral
    self.peripheral?.delegate = self
    central.stopScan()
    central.connect(peripheral, options: nil)
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    log("Connected to \(peripheral.name ?? "?")")
    if hasListeners { sendEvent(withName: "StepBleConnected", body: peripheral.identifier.uuidString) }
    peripheral.discoverServices([targetService!])
  }

  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    log("Disconnected")
    if hasListeners { sendEvent(withName: "StepBleDisconnected", body: [:]) }
  }

  // MARK: - CBPeripheralDelegate

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    for s in peripheral.services ?? [] where s.uuid == targetService {
      peripheral.discoverCharacteristics([targetChar!], for: s)
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    for ch in service.characteristics ?? [] where ch.uuid == targetChar {
      peripheral.setNotifyValue(true, for: ch)
      log("Subscribed to steps characteristic")
      // Also try read once
      peripheral.readValue(for: ch)
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    guard error == nil else { log("Update error \(error!)"); return }
    if let data = characteristic.value, let str = String(data: data, encoding: .utf8) {
      if hasListeners { sendEvent(withName: "StepBleOnStep", body: ["value": str]) }
    }
  }
}