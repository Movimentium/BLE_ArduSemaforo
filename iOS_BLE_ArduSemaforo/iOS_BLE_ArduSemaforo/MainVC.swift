//
//  MainVC.swift
//  iOS_BLE_ArduSemaforo
//
//  Created by Miguel on 23/08/2020.
//  Copyright © 2020 Miguel Gallego Martín. All rights reserved.
//

import UIKit


class MainVC: UIViewController, SemaforoBLEDelegate {

    
    @IBOutlet weak var segColors: UISegmentedControl!
    @IBOutlet weak var lblInfo: UILabel!
    
    let semaforoBLE = SemaforoBLE()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        semaforoBLE.delegate = self
        lblInfo.text = nil
    }
    
    @IBAction func onSegColorsValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: semaforoBLE.currentColor = .rojo
        case 1: semaforoBLE.currentColor = .amarillo
        case 2: semaforoBLE.currentColor = .verde
        default:
            semaforoBLE.currentColor = .rojo
        }
    }
    
    @IBAction func onBtnEnviarColor() {
        semaforoBLE.enviarColorActual()
    }
    
    

    // MARK: - SemaforoBLEDelegate

    func escaneando() {
        DispatchQueue.main.async { [weak self] in
            self?.lblInfo.text = "Escaneando..."
        }
    }
    
    func conectado() {
        DispatchQueue.main.async { [weak self] in
            self?.lblInfo.text = "Conectado"
            self?.onSegColorsValueChanged((self?.segColors)!)
        }
    }
    
    func desconectado() {
        DispatchQueue.main.async { [weak self] in
            self?.lblInfo.text = "Desconectado!!!"
        }
    }

}
