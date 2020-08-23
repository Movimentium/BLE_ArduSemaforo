//
//  SemaforoBLE.swift
//  iOS_BLE_ArduSemaforo
//
//  Created by Miguel on 23/08/2020.
//  Copyright © 2020 Miguel Gallego Martín. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol SemaforoBLEDelegate: AnyObject {
    func escaneando()
    func conectado()
    func desconectado()
}

enum ColorSemaforo {
    case rojo
    case amarillo
    case verde
    
    var dataToSend: Data {
        var car = "R"
        switch self {
        case .rojo:     car = "R"
        case .amarillo: car = "A"
        case .verde:    car = "V"
        }
        return car.data(using: String.Encoding.ascii)!
    }
}

class SemaforoBLE: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private var centralManager: CBCentralManager!
    private var periferico: CBPeripheral?
    weak var delegate: SemaforoBLEDelegate?
    
    // UUIDs del DSD TECH HM-10
    private let peripheralUUID_HM10 = CBUUID(string:"AA4D8E40-0A80-75D2-8958-A63B784A0724")
    private let serviceUUID_HM10 = CBUUID(string:"FFE0")
    private let charUUID_HM10 = CBUUID(string:"FFE1")
    private var char_HM10: CBCharacteristic?

    private var setUUIDstrs: Set<String> = []
    
    var currentColor = ColorSemaforo.rojo 
    
    func enviarColorActual() {
        guard let c = char_HM10 else {
            print("char_HM10 == nil !!")
            return
        }
        let data = currentColor.dataToSend
        if c.properties.contains(.writeWithoutResponse) {
            periferico?.writeValue(data, for: c, type: .withoutResponse)
        } else {
            periferico?.writeValue(data, for: c, type: .withResponse)
        }
    }
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("-----------------------------------------------------")
        print("\(#function)")
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            delegate?.escaneando()
            print("Scanning...")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        let strUUID = peripheral.identifier.uuidString
        
        // Print SÓLO nuevos periféricos encontrados
        if setUUIDstrs.contains(strUUID) == false {
            setUUIDstrs.insert(strUUID)
            print("rssi: \(RSSI.floatValue)")
            print("peripheral.name: \(peripheral.name ?? "SinNombre")")
            print("peripheral.identifier: \(strUUID)")
        }
        
        if peripheral.identifier.uuidString == peripheralUUID_HM10.uuidString {  //
            centralManager.stopScan()
            print(advertisementData)
            central.connect(peripheral, options: nil)
            periferico = peripheral
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("-----------------------------------------------------")
        print("\(#function)")
        print("connected to \(peripheral.name ?? "SinNombre")")
        delegate?.conectado()
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?)
    {
        print("-----------------------------------------------------")
        print("\(#function)")
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        delegate?.escaneando()
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("-----------------------------------------------------")
        print("\(#function)")
        for service in peripheral.services ?? [] {
            print("service.uuid: \(service.uuid.uuidString)")
            print("service.isPrimary: \(service.isPrimary)")
            if service.uuid == serviceUUID_HM10 {
                peripheral.discoverCharacteristics(nil, for: service)
            }
            //            else if service.uuid == serviceUUID02 {
            //                 peripheral.discoverCharacteristics(nil, for: service)
            //            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        print("-----------------------------------------------------")
        print("\(#function)")
        print("service.uuid: \(service.uuid.uuidString)")
        
        for c in service.characteristics ?? [] {
            print("-----------------------------------------------------")
            print("characteristic.uuid: \(c.uuid.uuidString)")
            debug_print(c)
            
            
            if c.uuid == charUUID_HM10 {
                char_HM10 = c
                peripheral.setNotifyValue(true, for: c)
                let data = "HOLA ARDUINO".data(using: String.Encoding.utf8)!
                if c.properties.contains(.writeWithoutResponse) {
                    peripheral.writeValue(data, for: c, type: .withoutResponse)
                } else {
                    peripheral.writeValue(data, for: c, type: .withResponse)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("-----------------------------------------------------")
        print("\(#function)")
        
    }
    
    func debug_print(_ car:CBCharacteristic) {
        print("value: \(String(describing: car.value))")
        print("descriptors: \(String(describing: car.descriptors))")
        print("properties: \(car.properties)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    {
        print("-----------------------------------------------------")
        print("\(#function)")
        // data to string
        //        let b = characteristic.value?.description
        //        print(Character(UnicodeScalar(b)))
        let data = characteristic.value!
        print(String(data: data, encoding: .ascii)!) //
        
        
    }
    
}
