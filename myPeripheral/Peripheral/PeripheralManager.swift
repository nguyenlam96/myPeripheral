//
//  PeripheralManager.swift
//  myPeripheral
//
//  Created by Nguyen Lam on 1/29/19.
//  Copyright © 2019 Nguyen Lam. All rights reserved.
//

import Foundation
import CoreBluetooth


class PeriperalManager: NSObject {
    
    // MARK: - Properties:
    static let shared = PeriperalManager()
    var peripheralManager : CBPeripheralManager!
    var receiveMessageDataCharacteristic: CBMutableCharacteristic!
    var sendMessageDataCharacteristic: CBMutableCharacteristic!
    var messagerService: CBMutableService!
    var updatedData: Data?
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    
    }
    
    // MARK: - Setup When ViewDidLoad:
    func setupService() {
        messagerService = CBMutableService(type: CBUUID(string: messengerServiceUUIDs.serviceUUID.rawValue), primary: true)
        receiveMessageDataCharacteristic = CBMutableCharacteristic(type: CBUUID(string: messengerServiceUUIDs.receiveMessageDataCharacteristicUUID.rawValue), properties: [.write, .read], value: nil, permissions: [.writeable, .readable])
        sendMessageDataCharacteristic = CBMutableCharacteristic(type: CBUUID(string: messengerServiceUUIDs.sendMessageDataCharacteristicUUID.rawValue), properties: [.write, .read, .notify], value: nil, permissions: [.writeable, .readable])
        
        messagerService.characteristics = []
        messagerService.characteristics?.append((sendMessageDataCharacteristic)!)
        messagerService.characteristics?.append((receiveMessageDataCharacteristic)!)
        print("Added services: \(String(describing: messagerService))")
        peripheralManager!.add(messagerService!)
    }
    
    
    // MARK: - PeripheralManager funcs:
    func isPeripheralManagerReady() -> Bool {

        LogUtils.LogTrace(type: .startFunc)

        guard self.peripheralManager?.state == .poweredOn else {
            LogUtils.LogTrace(type: .endFunc)
            return false
        }

        LogUtils.LogTrace(type: .endFunc)
        return true
    }

    
    func startAdvertise() -> Bool {
        LogUtils.LogTrace(type: .startFunc)
        guard self.peripheralManager?.isAdvertising == false else {
            LogUtils.LogDebug(type: .error, message: "already advertising")
            LogUtils.LogTrace(type: .endFunc)
            return false
        }
        self.peripheralManager!.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [messagerService!.uuid], CBAdvertisementDataLocalNameKey: "myPeripheral"])
//        self.peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [messagerService!.uuid] ])
        LogUtils.LogTrace(type: .endFunc)
        return true
    }
    
    func stopAdvertise() -> Bool {
        LogUtils.LogTrace(type: .startFunc)
        self.peripheralManager?.stopAdvertising()
        LogUtils.LogTrace(type: .endFunc)
        return true
    }
    
    func writeCharacteristic(value: Data?) -> Bool {
        LogUtils.LogTrace(type: .startFunc)
        guard let value = value else {
            print("Datra value is nil")
            LogUtils.LogTrace(type: .endFunc)
            return false
        }
        self.sendMessageDataCharacteristic.value = value
        self.updatedData = self.sendMessageDataCharacteristic.value
        let result = self.peripheralManager.updateValue(updatedData!, for: self.sendMessageDataCharacteristic, onSubscribedCentrals: nil) // nil mean all subcribedCentral will be update
        return result
    }
    
    // MARK: - Helper Functions:
    
    
}

// MARK: - PeripheralManager Delegate :
extension PeriperalManager: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        LogUtils.LogTrace(type: .startFunc)
        var statusMessage = ""
        switch peripheral.state {
        case .poweredOn:
            statusMessage = "Bluetooth Status: Turned On"
            self.setupService()
        case .poweredOff:
            statusMessage = "Bluetooth Status: Turned Off"
        case .resetting:
            statusMessage = "Bluetooth Status: Resetting"
        case .unauthorized:
            statusMessage = "Bluetooth Status: Not Authorized"
        case .unsupported:
            statusMessage = "Bluetooth Status: Not Supported"
        default:
            statusMessage = "Bluetooth Status: Unknown"
            break
        }
        
        print(statusMessage)
        
        LogUtils.LogTrace(type: .endFunc)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        LogUtils.LogTrace(type: .startFunc)
        // ensure there's no error
        guard error == nil else {
            LogUtils.LogDebug(type: .error, message: error!.localizedDescription)
            LogUtils.LogTrace(type: .endFunc)
            return
        }
        // add success
        print("Add services success")
        LogUtils.LogTrace(type: .endFunc)
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        LogUtils.LogTrace(type: .startFunc)
        guard error == nil else {
            LogUtils.LogDebug(type: .error, message: error!.localizedDescription)
            LogUtils.LogTrace(type: .endFunc)
            return
        }
        // print out services and characteristic:
        LogUtils.LogTrace(type: .startFunc)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        LogUtils.LogTrace(type: .startFunc)
        // ensure characteristic is matched
        guard (request.characteristic.uuid == receiveMessageDataCharacteristic!.uuid) else {
            LogUtils.LogDebug(type: .error, message: "Characteristic UUID doesn't match")
            LogUtils.LogTrace(type: .endFunc)
            return
        }
        // ensure index is validate
        if request.offset > receiveMessageDataCharacteristic!.value!.count { // invalid
            LogUtils.LogDebug(type: .error, message: "invalid offset for messageContentCharacteristic")
            peripheralManager?.respond(to: request, withResult: CBATTError.Code.invalidOffset)
            LogUtils.LogTrace(type: .endFunc)
            return
        }
        
        // if everything's ok, assign value of characteristic for value of request
        let range = Range( NSRange(location: request.offset, length: receiveMessageDataCharacteristic!.value!.count - request.offset) )
        request.value = receiveMessageDataCharacteristic!.value!.subdata(in: range!)
        // respond to central:
        peripheralManager?.respond(to: request, withResult: CBATTError.Code.success)
        LogUtils.LogTrace(type: .endFunc)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        
        LogUtils.LogTrace(type: .startFunc)
        // ensure characteristic is matched
        var writeMessageRequest: CBATTRequest?
        for request in requests {
            if request.characteristic.uuid == receiveMessageDataCharacteristic!.uuid {
                writeMessageRequest = request
                break
            }
        }
        
        guard writeMessageRequest != nil else {
            LogUtils.LogDebug(type: .error, message: "Can't find write request match characteristicUUID")
            return
        }
        // ensure index is validate
//        if writeMessageRequest!.offset > messageDataCharacteristic!.value!.count { // invalid
//            LogUtils.LogDebug(type: .error, message: "invalid offset for messageContentCharacteristic")
//            peripheralManager?.respond(to: writeMessageRequest!, withResult: CBATTError.Code.invalidOffset)
//            LogUtils.LogTrace(type: .endFunc)
//            return
//        }
        // write:
        receiveMessageDataCharacteristic!.value = writeMessageRequest!.value
        // respond to central:
        peripheralManager?.respond(to: writeMessageRequest!, withResult: CBATTError.Code.success)
        let message = String(data: writeMessageRequest!.value!, encoding: String.Encoding.utf8)
        if message == nil {
            LogUtils.LogDebug(type: .warning, message: "message is nil")
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationName.receiveMessage.rawValue), object: nil, userInfo: ["message": message ?? "hello"])
        //        peripheralManager?.respond(to: requests.first!, withResult: CBATTError.Code.success)
        LogUtils.LogTrace(type: .endFunc)
        
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        LogUtils.LogTrace(type: .startFunc)
        print("central: \(central) didSubscribe to charactersitic: \(characteristic)")
        LogUtils.LogTrace(type: .endFunc)
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // Summary: Invoked when a local peripheral device is again ready to send characteristic value updates.
        self.peripheralManager.updateValue(self.updatedData!, for: self.sendMessageDataCharacteristic, onSubscribedCentrals: nil)
    }
    
    
}



