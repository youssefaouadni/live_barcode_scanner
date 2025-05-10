import Flutter
import UIKit

public class LiveBarcodeScannerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    var eventSink: FlutterEventSink?
    private var barcodeScannerView: BarcodeScannerUIView?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: "live_barcode_scanner", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "live_barcode_scanner/events", binaryMessenger: registrar.messenger())
        
        let instance = LiveBarcodeScannerPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
        
        let factory = BarcodeScannerViewFactory(messenger: registrar.messenger(), plugin: instance)
        registrar.register(factory, withId: "live_barcode_scanner_view")
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startScan":
            barcodeScannerView?.setupView(arguments: call.arguments)
            result(nil)
        case "stopScan":
            barcodeScannerView?.stopScanning()
            result(nil)
        case "pauseScan":
            barcodeScannerView?.pauseScanning()
            result(nil)
        case "resumeScan":
            barcodeScannerView?.resumeScanning()
            result(nil)
        case "toggleTorch":
            barcodeScannerView?.toggleTorch()
            result(nil)
        case "setZoom":
            if let args = call.arguments as? [String: Any], let zoomFactor = args["zoomFactor"] as? Float {
                barcodeScannerView?.setZoom(zoomFactor: zoomFactor)
                result(nil)
            } else {
                result(PluginError.invalidArgument)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        barcodeScannerView?.setEventSink(events)
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        barcodeScannerView?.setEventSink(nil)
        return nil
    }
    
    func setBarcodeScannerView(_ view: BarcodeScannerUIView) {
        self.barcodeScannerView = view
        view.setEventSink(eventSink)
    }
}

struct PluginError {
    static let permissionDenied = FlutterError(code: "PERMISSION_DENIED", message: "Camera access denied", details: nil)
    static let noCamera = FlutterError(code: "NO_CAMERA", message: "No camera available", details: nil)
    static let inputError = FlutterError(code: "INPUT_ERROR", message: "Failed to set up camera input", details: nil)
    static let outputError = FlutterError(code: "OUTPUT_ERROR", message: "Failed to add metadata output", details: nil)
    static let invalidArgument = FlutterError(code: "INVALID_ARGUMENT", message: "Invalid or missing arguments", details: nil)
}
