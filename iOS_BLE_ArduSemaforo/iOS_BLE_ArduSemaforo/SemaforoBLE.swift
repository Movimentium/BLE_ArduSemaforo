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
    func mensajeRecivido(_ msg:String)
    func strMilisegundos(strMiliSecs:String, paraColor color:ColorSemaforo)
}

enum ModoSemaforo {
    case manual
    case automatico
    case test
    
    var dataToSend: Data {
        var str = "."
        switch self {
        case .manual:     str = ".MODO_MANUAL"
        case .automatico: str = ".MODO_AUTO"
        case .test:       str = ".MODO_TEST"
        }
        return str.data(using: String.Encoding.ascii)!
    }
}

enum ColorSemaforo: Int {
    case rojo = 0
    case amarillo = 1
    case verde = 2
    
    var dataToSend: Data {
        var str = "."
        switch self {
        case .rojo:     str = ".R"
        case .amarillo: str = ".A"
        case .verde:    str = ".V"
        }
        return str.data(using: String.Encoding.ascii)!
    }
}

class SemaforoBLE: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var currentColor = ColorSemaforo.rojo
    var modo = ModoSemaforo.manual
    
    var arrTiempoColor:[Float] = Array(repeating: 1, count: 3)
    
    private(set) var isConectado = false
    weak var delegate: SemaforoBLEDelegate?
    
    // UUIDs del DSD TECH HM-10
    private let peripheralUUID_HM10 = CBUUID(string:"AA4D8E40-0A80-75D2-8958-A63B784A0724")
    private let serviceUUID_HM10 = CBUUID(string:"FFE0")
    private let charUUID_HM10 = CBUUID(string:"FFE1")
    private var char_HM10: CBCharacteristic?

    private var setUUIDstrs: Set<String> = []
    
    private var centralManager: CBCentralManager!
    private var periferico: CBPeripheral?
    
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
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
    
    func enviarModoActual() {
        guard let c = char_HM10 else {
            print("char_HM10 == nil !!")
            return
        }
        let data = modo.dataToSend
        if c.properties.contains(.writeWithoutResponse) {
            periferico?.writeValue(data, for: c, type: .withoutResponse)
        } else {
            periferico?.writeValue(data, for: c, type: .withResponse)
        }
    }
    
    func enviarTiempoParaColor(_ color:ColorSemaforo) {
        print("\(#function) t: \(arrTiempoColor[color.rawValue])")
        guard let c = char_HM10 else {
            print("char_HM10 == nil !!")
            return
        }
        let v = arrTiempoColor[color.rawValue]
        let strMiliSegs = strMilisegundosPara(valor: v)
        delegate?.strMilisegundos(strMiliSecs: strMiliSegs, paraColor: color)
        var strToSend = "";
        switch color {
        case .rojo:      strToSend = ".TIME_R\(strMiliSegs)"
        case .amarillo:  strToSend = ".TIME_A\(strMiliSegs)"
        case .verde:     strToSend = ".TIME_V\(strMiliSegs)"
        }
        print("\(#function) strToSend: \(strToSend)")
        let data = strToSend.data(using: String.Encoding.ascii)!
        if c.properties.contains(.writeWithoutResponse) {
            periferico?.writeValue(data, for: c, type: .withoutResponse)
        } else {
            periferico?.writeValue(data, for: c, type: .withResponse)
        }
    }
    
    // MARK: - TODO Optimizar
    private func strMilisegundosPara(valor:Float) -> String {
        // 0...4  Float
        let v = valor * 1000;
        if v < 800 {         return "0250"
        } else if v < 1000 {  return "0500"
        } else if v < 1500 {  return "1000"
        } else if v < 2000 {  return "1500"
        } else if v < 2500 {  return "2000"
        } else if v < 3000 {  return "2500"
        } else if v < 3500 {  return "3000"
        } else if v < 3700 {  return "3500"
        } else {              return "4000"
        }
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
        isConectado = true
        delegate?.conectado()
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?)
    {
        print("-----------------------------------------------------")
        print("\(#function)")
        isConectado = false
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
//                let data = "HOLA ARDUINO".data(using: String.Encoding.utf8)!
//                if c.properties.contains(.writeWithoutResponse) {
//                    peripheral.writeValue(data, for: c, type: .withoutResponse)
//                } else {
//                    peripheral.writeValue(data, for: c, type: .withResponse)
//                }
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
        let mensaje = String(data: data, encoding: .ascii)!
        print(mensaje)
        delegate?.mensajeRecivido(mensaje)
        
    }
    
}
