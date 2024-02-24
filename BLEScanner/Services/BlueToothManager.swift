import CoreBluetooth

class BlueToothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    
    static let shared = BlueToothManager()
       
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    var centralManager: CBCentralManager!
    var discoveredPeripheral: CBPeripheral?
    var characteristic: CBCharacteristic?
    var batteryLevelCharacteristic: CBCharacteristic?
    var batteryChargingStatusCharacteristic: CBCharacteristic?

    
    @Published var batteryLevel: Int = 0
    @Published var isBatteryCharging: Bool = false

    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Обнаружено устройство, попытка подключения
        self.discoveredPeripheral = peripheral
        self.centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Подключение успешно, начало поиска сервисов
        peripheral.delegate = self
        peripheral.discoverServices(nil) // Можете указать UUID сервисов, если они известны
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            print("Обнаружен сервис: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            print("Обнаружена характеристика: \(characteristic.uuid) для сервиса: \(service.uuid)")
            self.characteristic = characteristic
            
            if characteristic.uuid == CBUUID(string: "2A19") {
                self.batteryLevelCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
                
            } else if characteristic.uuid == CBUUID(string: "2A1A") {
                self.batteryChargingStatusCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    func sendData(_ data: Data) {
        guard let characteristic = self.characteristic else {
            print("Характеристика для отправки данных не найдена.")
            return
        }
        
        guard let discoveredPeripheral = self.discoveredPeripheral else {
            print("Периферийное устройство не подключено.")
            return
        }
        
        if characteristic.properties.contains(.write) {
            discoveredPeripheral.writeValue(data, for: characteristic, type: .withResponse)
            
        } else if characteristic.properties.contains(.writeWithoutResponse) {
            discoveredPeripheral.writeValue(data, for: characteristic, type: .withoutResponse)
            
        } else {
            print("Характеристика не поддерживает запись.")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let batteryLevelCharacteristic = self.batteryLevelCharacteristic,
           characteristic == batteryLevelCharacteristic {
            if let data = characteristic.value {
                let byteArray = [UInt8](data)
                self.batteryLevel = Int(byteArray[0])
            }
            
        } else if let batteryChargingStatusCharacteristic = self.batteryChargingStatusCharacteristic,
                  characteristic == batteryChargingStatusCharacteristic {
            if let data = characteristic.value {
                let byteArray = [UInt8](data)
                self.isBatteryCharging = byteArray[0] == 2
            }
        }
    }
    
    func readBatteryLevel() {
        guard let peripheral = discoveredPeripheral, let characteristic = batteryLevelCharacteristic else { return }
        peripheral.readValue(for: characteristic)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.discoveredPeripheral = nil
    }
}
