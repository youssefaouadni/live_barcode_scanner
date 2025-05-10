import UIKit
import AVFoundation
import Flutter

class BarcodeScannerUIView: NSObject, FlutterPlatformView {
    private let scannerView: UIView
    private var session: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var eventSink: FlutterEventSink?
    private let torchButton = UIButton()
    private let scanFrame: UIView
    private var scanLine: UIView?
    private var lastBarcode: String?
    private var lastDetectionTime: Date?
    private var isCameraSetupPending = false
    
    init(frame: CGRect, eventSink: FlutterEventSink?, arguments: Any?) {
        self.scannerView = UIView(frame: frame)
        self.scanFrame = UIView()
        self.eventSink = eventSink
        print("Initialized with frame: \(frame)")
        super.init()
        scannerView.addObserver(self, forKeyPath: "frame", options: [.new], context: nil)
        setupView(arguments: arguments)
    }
    
    func view() -> UIView {
        return scannerView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        scannerView.removeObserver(self, forKeyPath: "frame")
        session?.stopRunning()
        videoPreviewLayer?.removeFromSuperlayer()
        scanLine?.layer.removeAllAnimations()
        print("Deinitialized BarcodeScannerUIView")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "frame", let newFrame = change?[.newKey] as? CGRect {
            print("scannerView frame changed to: \(newFrame)")
            if !newFrame.size.equalTo(.zero) && isCameraSetupPending {
                DispatchQueue.main.async {
                    self.setupCameraAndUI()
                }
            }
        }
    }
    
    func setEventSink(_ eventSink: FlutterEventSink?) {
        DispatchQueue.main.async {
            self.eventSink = eventSink
            print("Set eventSink: \(eventSink != nil ? "Active" : "Nil")")
        }
    }
    
    func sendEvent(_ event: [String: Any]) {
        DispatchQueue.main.async {
            print("Sending event: \(event)")
            self.eventSink?(event)
        }
    }
    
    func setupView(arguments: Any?) {
        print("Setting up view with scannerView frame: \(scannerView.frame)")
        scannerView.backgroundColor = .black
        
        if scannerView.frame.size == .zero {
            print("Warning: scannerView frame is zero, deferring camera setup")
            isCameraSetupPending = true
            sendEvent([
                "type": "error",
                "code": "INVALID_FRAME",
                "message": "Scanner view has zero frame size, waiting for valid frame",
                "details": nil
            ])
            return
        }
        
        setupCameraAndUI(arguments: arguments)
    }
    
    func setupCameraAndUI(arguments: Any? = nil) {
        print("Setting up camera and UI with scannerView frame: \(scannerView.frame)")
        isCameraSetupPending = false
        
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    print("Camera permission granted")
                    self.session = AVCaptureSession()
                    
                    self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session!)
                    self.videoPreviewLayer?.frame = self.scannerView.bounds
                    self.videoPreviewLayer?.videoGravity = .resizeAspectFill
                    self.scannerView.layer.addSublayer(self.videoPreviewLayer!)
                    print("Added videoPreviewLayer with frame: \(self.videoPreviewLayer?.frame ?? CGRect.zero)")
                    
                    if self.startCameraSession() {
                        let scanFrameSize = (arguments as? [String: Any])?["scanFrameSize"] as? CGFloat ?? 300
                        self.scanFrame.frame = CGRect(
                            x: (self.scannerView.frame.size.width - scanFrameSize) / 2,
                            y: (self.scannerView.frame.size.height - scanFrameSize) / 2,
                            width: scanFrameSize,
                            height: scanFrameSize
                        )
                        self.scanFrame.layer.borderColor = UIColor.green.cgColor
                        self.scanFrame.layer.borderWidth = 2
                        self.scanFrame.isUserInteractionEnabled = false
                        self.scannerView.addSubview(self.scanFrame)
                        print("Added scanFrame with frame: \(self.scanFrame.frame)")
                        
                        self.scanLine = UIView()
                        self.scanLine?.frame = CGRect(x: 0, y: 0, width: scanFrameSize, height: 2)
                        self.scanLine?.backgroundColor = .green
                        self.scanLine?.isHidden = false
                        self.scanFrame.addSubview(self.scanLine!)
                        print("Added scanLine with frame: \(self.scanLine?.frame ?? CGRect.zero)")
                        
                        self.torchButton.frame = CGRect(x: self.scannerView.frame.size.width - 60, y: 30, width: 50, height: 50)
                        self.torchButton.setImage(UIImage(systemName: "bolt.slash"), for: .normal)
                        self.torchButton.addTarget(self, action: #selector(self.toggleTorch), for: .touchUpInside)
                        self.scannerView.addSubview(self.torchButton)
                        print("Added torchButton with frame: \(self.torchButton.frame)")
                        
                        self.scannerView.setNeedsLayout()
                        self.scannerView.layoutIfNeeded()
                        print("Forced layout update for scannerView")
                        
                        self.startScanLineAnimation()
                    }
                } else {
                    print("Camera permission denied")
                    self.sendEvent([
                        "type": "error",
                        "code": PluginError.permissionDenied.code,
                        "message": PluginError.permissionDenied.message,
                        "details": PluginError.permissionDenied.details
                    ])
                }
            }
        }
    }
    
    internal func startCameraSession() -> Bool {
        print("Starting camera session")
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("No back wide-angle camera available")
            sendEvent([
                "type": "error",
                "code": PluginError.noCamera.code,
                "message": "No back wide-angle camera available",
                "details": nil
            ])
            return false
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session?.canAddInput(input) ?? false {
                session?.addInput(input)
                print("Added camera input for device: \(device.localizedName)")
            } else {
                print("Failed to add camera input")
                sendEvent([
                    "type": "error",
                    "code": PluginError.inputError.code,
                    "message": PluginError.inputError.message,
                    "details": nil
                ])
                return false
            }
        } catch {
            print("Error setting up camera input: \(error.localizedDescription)")
            sendEvent([
                "type": "error",
                "code": "INPUT_ERROR",
                "message": "Failed to set up camera input: \(error.localizedDescription)",
                "details": nil
            ])
            return false
        }
        
        let output = AVCaptureMetadataOutput()
        if session?.canAddOutput(output) ?? false {
            session?.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = output.availableMetadataObjectTypes
            print("Added metadata output with types: \(output.metadataObjectTypes)")
        } else {
            print("Failed to add metadata output")
            sendEvent([
                "type": "error",
                "code": PluginError.outputError.code,
                "message": PluginError.outputError.message,
                "details": nil
            ])
            return false
        }
        
        session?.startRunning()
        print("Started AVCaptureSession")
        let isRunning = session?.isRunning ?? false
        print("Session running status: \(isRunning)")
        if !isRunning {
            print("Warning: AVCaptureSession is not running")
            sendEvent([
                "type": "error",
                "code": "SESSION_NOT_RUNNING",
                "message": "Failed to start camera session",
                "details": nil
            ])
            return false
        }
        
        return true
    }
    
    internal func startScanLineAnimation() {
        guard let scanLine = scanLine else {
            print("Scan line is nil, cannot start animation")
            sendEvent([
                "type": "error",
                "code": "ANIMATION_ERROR",
                "message": "Failed to start scan line animation: scan line is nil",
                "details": nil
            ])
            return
        }
        print("Starting scan line animation for frame: \(scanLine.frame)")
        let scanLineAnimation = CABasicAnimation(keyPath: "position.y")
        scanLineAnimation.fromValue = 0
        scanLineAnimation.toValue = scanFrame.frame.size.height
        scanLineAnimation.duration = 2.0
        scanLineAnimation.repeatCount = .infinity
        scanLineAnimation.autoreverses = true
        scanLine.layer.add(scanLineAnimation, forKey: "scanLine")
    }
    
    @objc internal func toggleTorch() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back), device.hasTorch else {
            print("No torch available")
            return
        }
        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
                torchButton.setImage(UIImage(systemName: "bolt.slash"), for: .normal)
            } else {
                try device.setTorchModeOn(level: 1.0)
                torchButton.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
            }
            device.unlockForConfiguration()
            print("Toggled torch to: \(device.torchMode == .on ? "On" : "Off")")
        } catch {
            print("Error toggling torch: \(error)")
        }
    }
    
    func stopScanning() {
        session?.stopRunning()
        print("Stopped AVCaptureSession")
    }
    
    func pauseScanning() {
        session?.stopRunning()
        print("Paused AVCaptureSession")
    }
    
    func resumeScanning() {
        session?.startRunning()
        print("Resumed AVCaptureSession")
    }
    
    func setZoom(zoomFactor: Float) {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("No camera device for zoom")
            return
        }
        do {
            try device.lockForConfiguration()
            let maxZoomFactor = device.activeFormat.videoMaxZoomFactor
            let zoom = min(maxZoomFactor, CGFloat(zoomFactor))
            device.videoZoomFactor = zoom
            device.unlockForConfiguration()
            print("Set zoom factor to: \(zoom)")
        } catch {
            print("Error setting zoom: \(error)")
        }
    }
    
    func layoutSubviews() {
        videoPreviewLayer?.frame = scannerView.bounds
        print("Updated videoPreviewLayer frame: \(videoPreviewLayer?.frame ?? CGRect.zero)")
        if let connection = videoPreviewLayer?.connection, connection.isVideoOrientationSupported {
            switch UIDevice.current.orientation {
            case .portrait:
                connection.videoOrientation = .portrait
            case .landscapeRight:
                connection.videoOrientation = .landscapeLeft
            case .landscapeLeft:
                connection.videoOrientation = .landscapeRight
            case .portraitUpsideDown:
                connection.videoOrientation = .portraitUpsideDown
            default:
                connection.videoOrientation = .portrait
            }
            print("Set video orientation for device orientation: \(UIDevice.current.orientation.rawValue)")
        }
    }
}

extension BarcodeScannerUIView: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else { return }
            let now = Date()
            if stringValue == lastBarcode, let lastTime = lastDetectionTime, now.timeIntervalSince(lastTime) < 1.0 {
                return
            }
            lastBarcode = stringValue
            lastDetectionTime = now
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            sendEvent([
                "type": "barcode",
                "value": stringValue
            ])
            print("Detected barcode: \(stringValue)")
        }
    }
}
