//
//  AppDelegate.swift
//  peripage-cocoa-vapor-swift
//
//  Created by yrambler2001 on 06.08.2024.
//

import Cocoa
import Foundation
import IOBluetooth
import IOBluetoothUI
import Logging
import NIOCore
import NIOPosix
import Vapor

struct MessageJSONData: Codable {
    var type: String
    var data: String
}
struct JSONData: Codable {
    var data: String
    var type: String
}

func sendJSON(webSocketClient: WebSocketClient, data: String, type: String) {
    let encoder = JSONEncoder()
    let processedData = JSONData(data: data, type: type)
    do {
        let data = try encoder.encode(processedData)
        let json = String(decoding: data, as: UTF8.self)
        webSocketClient.send(message: json)
    } catch {
        print(error.localizedDescription)
    }
    
}

func decodeJSON<T: Decodable>(_ type: T.Type, data: String) -> T {
    let decoder = JSONDecoder()
    let data = Data(data.utf8)
    let json = try? decoder.decode(T.self, from: data)
    return json!
}

class WebSocketClient {
    typealias StringVoidFunction = (String) -> Void
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession = URLSession(configuration: .default)
    private var processor: StringVoidFunction
    init(processor: @escaping StringVoidFunction) {
        self.processor = processor
    }
    
    func connect(to url: URL) {
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Start receiving messages
        receiveMessage()
    }
    
    func send(message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Error sending message: \(error)")
            }
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Error receiving message: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received text: \(text)")
                    self?.processor(text)
                case .data(let data):
                    print("Received data: \(data)")
                @unknown default:
                    fatalError()
                }
                
                // Continue receiving messages
                self?.receiveMessage()
            }
        }
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate, IOBluetoothRFCOMMChannelDelegate {
    @IBOutlet var window: NSWindow!
    var webSocketClient: WebSocketClient?
    
    var mRFCOMMChannel: IOBluetoothRFCOMMChannel?
    
    @IBOutlet var textView: NSTextView!
    
    @IBOutlet var txtvw: NSTextView!
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        DispatchQueue.global(qos: .background).async {
            Task {
                do {
                    try await vaporMain()
                } catch {
                    print(error)
                }
            }
        }
        
        let url = URL(string: "ws://127.0.0.1:8080/websocket")!
        
        webSocketClient = WebSocketClient(processor: self.processMessage)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.webSocketClient?.connect(to: url)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.webSocketClient?.send(message: "server")
            }
        }
    }
    
    @IBAction func discover(sender: AnyObject) {
        let deviceSelector = IOBluetoothDeviceSelectorController.deviceSelector()
        let sppServiceUUID = IOBluetoothSDPUUID.uuid32(
            kBluetoothSDPUUID16ServiceClassSerialPort.rawValue)
        
        if deviceSelector == nil {
            self.log(text: "Error - unable to allocate IOBluetoothDeviceSelectorController")
            return
        }
        
        deviceSelector?.addAllowedUUID(sppServiceUUID)
        
        if deviceSelector?.runModal() != Int32(kIOBluetoothUISuccess) {
            self.log(text: "User has cancelled the device selection")
            return
        }
        
        let deviceArray = deviceSelector?.getResults()
        
        if (deviceArray == nil) || (deviceArray?.count == 0) {
            self.log(text: "Error - no selected device.")
            return
        }
        
        let device: IOBluetoothDevice = deviceArray?[0] as! IOBluetoothDevice
        
        let sppServiceRecord = device.getServiceRecord(for: sppServiceUUID)
        
        if sppServiceRecord == nil {
            self.log(text: "Error - no spp service in selected device.")
            return
        }
        
        var rfcommChannelID: BluetoothRFCOMMChannelID = 0
        
        if sppServiceRecord?.getRFCOMMChannelID(&rfcommChannelID) != kIOReturnSuccess {
            self.log(text: "Error")
            return
        }
        
        if device.openRFCOMMChannelAsync(
            &mRFCOMMChannel, withChannelID: rfcommChannelID, delegate: self) != kIOReturnSuccess
        {
            self.log(text: "Error")
            return
        }
        
    }
    
    func log(text: String?) {
        if text != nil {
            print(text!)
        } else {
            print("Empty message")
        }
    }
    func processMessage(message: String) {
        print("processing message: ", message)
        
        let json = decodeJSON(JSONData.self, data: message)
        if json.type == "dataToPrinter" {
            print("sent ", json.data)
            let data = decodeJSON([MessageJSONData].self, data: json.data)
            
            self.sendMessages(messageData: data)
        }
        if (json.type == "dataToPrinterProcessor") && (json.data == "info") {
            sendJSON(
                webSocketClient: webSocketClient!,
                data:
                    "mRFCOMMChannel.getID: \(String(describing: mRFCOMMChannel?.getID())), mRFCOMMChannel.getMTU: \(String(describing: mRFCOMMChannel?.getMTU())), mRFCOMMChannel.isOpen: \(String(describing: mRFCOMMChannel?.isOpen())), mRFCOMMChannel.getDevice: \(String(describing: mRFCOMMChannel?.getDevice())), mRFCOMMChannel.isTransmissionPaused: \(String(describing: mRFCOMMChannel?.isTransmissionPaused()))",
                type: "dataFromPrinterProcessor")
            
        }
    }
    
    func sendMessages(messageData: [MessageJSONData]) {
        sendJSON(
            webSocketClient: webSocketClient!, data: "sending", type: "dataFromPrinterProcessor")
        for i in 0..<messageData.count {
            let currentEntry = messageData[i]
            
            if currentEntry.type == "wait" {
                let nanoSeconds = (UInt32(currentEntry.data)!)*1000
                self.log(text: "sleeping start \(NSDate().timeIntervalSince1970) ms:\(nanoSeconds/1000)")
                usleep(nanoSeconds)


                self.log(text: "sleeping end \(NSDate().timeIntervalSince1970) ms:\(nanoSeconds/1000)")
            } else if currentEntry.type == "send" {
                
                let data1 = stringToBytes(currentEntry.data)
                
                let length = data1!.count
                let abc: [UInt8] = data1!
                
                let count = abc.count
                let pointer = UnsafeMutableRawPointer.allocate(
                    byteCount: count, alignment: MemoryLayout<UInt8>.alignment)
                
                pointer.copyMemory(from: abc, byteCount: count)
                
                //                for i in 0..<count {
                //                    let value = pointer.load(fromByteOffset: i, as: UInt8.self)
                //                    print("Value at index \(i): \(value)")
                //                }
                
                self.log(text: "sending \(NSDate().timeIntervalSince1970) \(currentEntry.data)")
                mRFCOMMChannel?.writeSync(pointer, length: UInt16(length))
                self.log(text: "sent \(NSDate().timeIntervalSince1970) \(currentEntry.data)")
            }
        }
        sendJSON(webSocketClient: webSocketClient!, data: "sent", type: "dataFromPrinterProcessor")
    }
    
    func rfcommChannelOpenComplete(
        _ rfcommChannel: IOBluetoothRFCOMMChannel!, status error: IOReturn
    ) {
        if error != kIOReturnSuccess {
            self.log(text: "Error - Failed to open the RFCOMM channel")
        } else {
            self.log(text: "Connected")
        }
    }
    
    func rfcommChannelData(
        _ rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutableRawPointer,
        length dataLength: Int
    ) {
        let message = String(
            bytesNoCopy: dataPointer, length: Int(dataLength),
            encoding: String.Encoding(rawValue: NSUTF8StringEncoding), freeWhenDone: false)
        
        sendJSON(webSocketClient: webSocketClient!, data: message!, type: "dataFromPrinter")
        
        self.log(text: message)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

func stringToBytes(_ string: String) -> [UInt8]? {
    let length = string.count
    if length & 1 != 0 {
        return nil
    }
    var bytes = [UInt8]()
    bytes.reserveCapacity(length / 2)
    var index = string.startIndex
    for _ in 0..<length / 2 {
        let nextIndex = string.index(index, offsetBy: 2)
        if let b = UInt8(string[index..<nextIndex], radix: 16) {
            bytes.append(b)
        } else {
            return nil
        }
        index = nextIndex
    }
    return bytes
}
