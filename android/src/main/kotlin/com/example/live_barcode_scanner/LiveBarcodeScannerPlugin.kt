package com.example.live_barcode_scanner

import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class LiveBarcodeScannerPlugin : FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    ActivityAware {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var barcodeScannerView: BarcodeScannerView? = null
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var pluginBinding: FlutterPlugin.FlutterPluginBinding
    private var activityBinding: ActivityPluginBinding? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        pluginBinding = binding

        methodChannel = MethodChannel(binding.binaryMessenger, "live_barcode_scanner")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "live_barcode_scanner/events")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startScan" -> {
                barcodeScannerView?.startScanning()
                result.success(null)
            }

            "stopScan" -> {
                barcodeScannerView?.stopScanning()
                result.success(null)
            }

            "toggleTorch" -> {
                barcodeScannerView?.toggleTorch()
                result.success(null)
            }

            "setZoom" -> {
                val zoom = call.argument<Double>("zoom") ?: 1.0
                barcodeScannerView?.setZoom(zoom.toFloat())
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        barcodeScannerView?.setEventSink(eventSink)
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        barcodeScannerView = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        val lifecycleOwner = binding.activity
        if (lifecycleOwner is LifecycleOwner) {

            pluginBinding.platformViewRegistry.registerViewFactory(
                "live_barcode_scanner_view",
                BarcodeScannerViewFactory(
                    lifecycleOwner,
                ) { view ->
                    barcodeScannerView = view
                }
            )

        } else {
            throw IllegalStateException("The activity does not implement LifecycleOwner. Make sure you're using a FlutterActivity or FragmentActivity.")
        }

    }


    override fun onDetachedFromActivity() {
        activityBinding = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

}
