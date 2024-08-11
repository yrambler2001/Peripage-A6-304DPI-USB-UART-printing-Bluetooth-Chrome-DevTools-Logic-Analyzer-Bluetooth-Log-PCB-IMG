import Cocoa
import IOBluetooth
import IOBluetoothUI
import Vapor

func routes(_ app: Application) throws {
    var serverWebsocket: WebSocket?
    var clientWebsocket: WebSocket?
    app.webSocket("websocket", maxFrameSize: 16_777_216) { req, ws in
        print("websocket connected")
        ws.onText { ws, text in
            print("data received in websocket: ", text)
            if text == "server" {
                print("VAPOR server")
                serverWebsocket = ws
            }
            //            if (text=="client") {
            //                print("VAPOR client")
            //                clientWebsocket = ws
            //            }
            let decoder = JSONDecoder()
            let data = Data(text.utf8)
            if let json = try? decoder.decode(JSONData.self, from: data) {
                if (json.type == "dataToPrinter") || (json.type == "dataToPrinterProcessor") {
                    print("VAPOR ", json.type, " ", json.data)
                    clientWebsocket = ws
                    serverWebsocket!.send(text)
                }
                if (json.type == "dataFromPrinter") || (json.type == "dataFromPrinterProcessor") {
                    print("VAPOR ", json.type, " ", json.data)
                    clientWebsocket!.send(text)
                }
            }
        }
    }
}
