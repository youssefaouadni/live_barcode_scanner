import Flutter
import UIKit

class BarcodeScannerViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    private weak var plugin: LiveBarcodeScannerPlugin?
    
    init(messenger: FlutterBinaryMessenger, plugin: LiveBarcodeScannerPlugin) {
        self.messenger = messenger
        self.plugin = plugin
        super.init()
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
    
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let scannerView = BarcodeScannerUIView(frame: frame, eventSink: plugin?.eventSink, arguments: args)
        plugin?.setBarcodeScannerView(scannerView)
        return scannerView
    }
}
