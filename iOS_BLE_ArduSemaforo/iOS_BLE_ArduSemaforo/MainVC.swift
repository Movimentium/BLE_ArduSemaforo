//
//  MainVC.swift
//  iOS_BLE_ArduSemaforo
//
//  Created by Miguel on 23/08/2020.
//  Copyright © 2020 Miguel Gallego Martín. All rights reserved.
//

import UIKit


class MainVC: UIViewController, SemaforoBLEDelegate {
  

    

    @IBOutlet weak var segModo: UISegmentedControl!
    @IBOutlet weak var segColors: UISegmentedControl!
    
    @IBOutlet weak var lblInfo: UILabel!
    @IBOutlet weak var lblInfoArdu: UILabel!
    @IBOutlet weak var lblR: UILabel!
    @IBOutlet weak var lblA: UILabel!
    @IBOutlet weak var lblV: UILabel!
    @IBOutlet var arrLblsColors: [UILabel]!
    
    @IBOutlet weak var sliderRojo: UISlider!
    @IBOutlet weak var sliderAmarillo: UISlider!
    @IBOutlet weak var sliderVerde: UISlider!

    
    
    let semaforoBLE = SemaforoBLE()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        semaforoBLE.delegate = self
        lblInfo.text = nil
        lblInfoArdu.text = nil
        arrLblsColors.forEach { $0.text = "4000 ms" }
    }
    
    @IBAction func onSegModoValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: semaforoBLE.modo = .manual
        case 1: semaforoBLE.modo = .automatico
        case 2: semaforoBLE.modo = .test
        default:
            semaforoBLE.modo = .manual
        }
        semaforoBLE.enviarModoActual()
    }
    
    @IBAction func onSegColorsValueChanged(_ sender: UISegmentedControl) {
        if semaforoBLE.modo != .manual {
            return
        }
        switch sender.selectedSegmentIndex {
        case 0: semaforoBLE.currentColor = .rojo
        case 1: semaforoBLE.currentColor = .amarillo
        case 2: semaforoBLE.currentColor = .verde
        default:
            semaforoBLE.currentColor = .rojo
        }
        semaforoBLE.enviarColorActual()
    }
    
    @IBAction func onBtnEnviarTest() {
        //semaforoBLE.
    }
    
  
    @IBAction func onSliderColorValueChanged(_ sender: UISlider) {
        let v = sender.value
        switch sender {
        case sliderRojo:
            semaforoBLE.arrTiempoColor[ColorSemaforo.rojo.rawValue] = v
            semaforoBLE.enviarTiempoParaColor(.rojo)
        case sliderAmarillo:
            semaforoBLE.arrTiempoColor[ColorSemaforo.amarillo.rawValue] = v
            semaforoBLE.enviarTiempoParaColor(.amarillo)
        case sliderVerde:
            semaforoBLE.arrTiempoColor[ColorSemaforo.verde.rawValue] = v
            semaforoBLE.enviarTiempoParaColor(.verde)
        default: break
        }
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
            // Por defecto: Modo == Manual, Color == Rojo
            self?.onSegModoValueChanged((self?.segModo)!)
            self?.onSegColorsValueChanged((self?.segColors)!)
        }
    }
    
    func desconectado() {
        DispatchQueue.main.async { [weak self] in
            self?.lblInfo.text = "Desconectado!!!"
        }
    }

    func mensajeRecivido(_ msg: String) {
        DispatchQueue.main.async { [weak self] in
            self?.lblInfoArdu.text = msg
        }
    }
    
    func strMilisegundos(strMiliSecs: String, paraColor color: ColorSemaforo) {
        DispatchQueue.main.async { [weak self] in
            self?.arrLblsColors[color.rawValue].text = "\(strMiliSecs) ms" 
        }
    }
      
}
