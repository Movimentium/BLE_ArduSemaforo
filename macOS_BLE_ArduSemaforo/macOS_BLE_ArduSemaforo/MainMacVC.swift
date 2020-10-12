//
//  MainMacVC.swift
//  macOS_BLE_ArduSemaforo
//
//  Created by Miguel on 28/08/2020.
//  Copyright © 2020 Miguel Gallego Martín. All rights reserved.
//

import Cocoa

class MainMacVC: NSViewController, NSTabViewDelegate {
    @IBOutlet weak var tabVwModo: NSTabView!
    @IBOutlet weak var segColors: NSSegmentedControl!
    @IBOutlet weak var lblInfoArdu: NSTextField!
    @IBOutlet weak var lblInfo: NSTextField!

 //    @IBOutlet weak var segColors: UISegmentedControl!

    

    override func viewDidLoad() {
        super.viewDidLoad()
        tabVwModo.delegate = self
        lblInfo.stringValue = ""
        lblInfoArdu.stringValue = ""
        
    }
    @IBAction func onSegColorAction(_ sender: NSSegmentedCell) {
        print("\(self.classForCoder) \(#function) \(sender.selectedSegment)")
    }
    
    // MARK: - NSTabViewDelegate
    
    func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        print("\(self.classForCoder) \(#function)")
    }
   
}
