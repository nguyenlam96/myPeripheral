//
//  ViewController.swift
//  myPeripheral
//
//  Created by Nguyen Lam on 1/29/19.
//  Copyright © 2019 Nguyen Lam. All rights reserved.
//

import Cocoa
import CoreBluetooth

class PheripheralVC: NSViewController {
    
    // MARK: - IBOutlet:
    @IBOutlet weak var messageLabel: NSTextField!
    @IBOutlet weak var advertiseButtonOutlet: NSButton!
    @IBOutlet weak var stopButtonOutlet: NSButton!
    @IBOutlet weak var messageTextField: NSTextField!
    @IBOutlet weak var successLabel: NSTextField!
    @IBOutlet weak var connectStateLabel: NSTextField!
    
    // MARK: - ViewLifeCycle:
    override func viewWillAppear() {
        NotificationCenter.default.addObserver(self, selector: #selector(didConnectedToCentral), name: NSNotification.Name(rawValue: NotificationName.didConnectedWithCentral.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceivedMessage(notification:)), name: NSNotification.Name(NotificationName.receiveMessage.rawValue), object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.connectStateLabel.stringValue = ""
        self.stopButtonOutlet.isHidden = true
        self.messageLabel.stringValue = ""
        self.successLabel.stringValue = ""
        self.advertiseButtonOutlet.title = "Start Advertise"
        
    }

    override var representedObject: Any? {
        didSet {
            
        }
    }
    // MARK: - Notifications handler :
    @objc func didConnectedToCentral() {
        LogUtils.LogTrace(type: .startFunc)
        self.connectStateLabel.stringValue = "connected"
        self.stopAdvertise()
        LogUtils.LogTrace(type: .endFunc)
    }
    
    @objc func didReceivedMessage(notification: Notification) {
        LogUtils.LogTrace(type: .startFunc)
        if let message = notification.userInfo?["message"] as? String {
            messageLabel.stringValue = message
        } else {
            LogUtils.LogDebug(type: .error, message: "Message is nil")
        }
        LogUtils.LogTrace(type: .endFunc)
    }
    // MARK: - IBActions :
    @IBAction func startAdvertiseButtonpressed(_ sender: NSButton) {
        
        LogUtils.LogTrace(type: .startFunc)
        if PeriperalManager.shared.isPeripheralManagerReady() {
            self.stopButtonOutlet.isHidden = false
            self.advertiseButtonOutlet.title = "Advertising..."
            _ = PeriperalManager.shared.startAdvertise()
            LogUtils.LogTrace(type: .endFunc)
        } else {
            LogUtils.LogDebug(type: .error, message: "Bluetooth isn't on")
            LogUtils.LogTrace(type: .endFunc)
        }
        
    }
    
    @IBAction func sendButtonPressed(_ sender: NSButton) {
        LogUtils.LogTrace(type: .startFunc)
        let textData = messageTextField.stringValue.data(using: String.Encoding.utf8)
        let result = PeriperalManager.shared.writeCharacteristic(value: textData)
        if result == true {
            self.successLabel.stringValue = "send success"
        } else {
            self.successLabel.stringValue = "send fail"
        }
        LogUtils.LogTrace(type: .endFunc)
        
    }
    
    
    @IBAction func stopAdvertiseButtonPressed(_ sender: NSButton) {
        LogUtils.LogTrace(type: .startFunc)
        
        self.stopAdvertise()

        LogUtils.LogTrace(type: .endFunc)

    }
    // MARK: - Private funcs :
    private func stopAdvertise() {
        let isAdvertising = PeriperalManager.shared.peripheralManager?.isAdvertising
        
        if isAdvertising! {
            _ = PeriperalManager.shared.stopAdvertise()
            self.stopButtonOutlet.isHidden = true
            self.advertiseButtonOutlet.title = "Start Advertise"
        } else {
            LogUtils.LogDebug(type: .warning, message: "The PeripheralManager is not advertising")
        }
    }
    

}

