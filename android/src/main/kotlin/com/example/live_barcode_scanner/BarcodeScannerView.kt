
package com.example.live_barcode_scanner

import android.animation.ObjectAnimator
import android.annotation.SuppressLint
import android.content.Context
import android.graphics.RectF
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewTreeObserver
import android.view.animation.LinearInterpolator
import android.widget.FrameLayout
import androidx.appcompat.widget.AppCompatImageButton
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.platform.PlatformView
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import androidx.camera.core.Camera

class BarcodeScannerView(
    private val context: Context,
    private val lifecycleOwner: LifecycleOwner,
) : PlatformView {

    private val rootLayout = FrameLayout(context)
    private val cameraPreview = PreviewView(context).apply {
        implementationMode = PreviewView.ImplementationMode.COMPATIBLE
        layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        )
        isClickable = false
        isFocusable = false
    }
    private val overlayLayout = FrameLayout(context)
    private val torchButton = AppCompatImageButton(context).apply {
        setImageResource(R.drawable.baseline_flash_off_24)
        setOnClickListener { toggleTorch() }
    }

    private val frameSize = 600
    private val scanFrame = FrameLayout(context).apply {
        layoutParams = FrameLayout.LayoutParams(frameSize, frameSize, Gravity.CENTER).apply {
            topMargin = 100
        }
        background = ContextCompat.getDrawable(context, R.drawable.scan_frame_border)
    }
    private val scanLine = ScanLineView(context)

    private var camera: Camera? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private val cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()

    private var isScanning = false
    private var eventSink: EventChannel.EventSink? = null

    init {
        rootLayout.addView(cameraPreview)
        rootLayout.addView(overlayLayout, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ))

        val torchParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT,
            Gravity.END or Gravity.TOP
        ).apply {
            topMargin = 40
            marginEnd = 40
        }
        overlayLayout.addView(torchButton, torchParams)

        scanFrame.addView(scanLine)
        overlayLayout.addView(scanFrame)

        scanFrame.viewTreeObserver.addOnGlobalLayoutListener(
            object : ViewTreeObserver.OnGlobalLayoutListener {
                override fun onGlobalLayout() {
                    scanFrame.viewTreeObserver.removeOnGlobalLayoutListener(this)
                    val location = IntArray(2)
                    scanFrame.getLocationOnScreen(location)
                    val left = location[0].toFloat()
                    val top = location[1].toFloat()
                    val right = left + scanFrame.width
                    val bottom = top + scanFrame.height

                    val frameRect = RectF(left, top, right, bottom)
                    val maskView = MaskView(context, frameRect)
                    overlayLayout.addView(maskView, 0)
                }
            }
        )
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraProviderFuture.addListener({
            cameraProvider = cameraProviderFuture.get()

            val preview = Preview.Builder().build().also {
                it.surfaceProvider = cameraPreview.surfaceProvider
            }

            val barcodeScanner = BarcodeScanning.getClient()
            val analysis = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()

            analysis.setAnalyzer(cameraExecutor) { imageProxy ->
                val mediaImage = imageProxy.image
                if (mediaImage != null) {
                    val inputImage = InputImage.fromMediaImage(
                        mediaImage, imageProxy.imageInfo.rotationDegrees
                    )
                    barcodeScanner.process(inputImage)
                        .addOnSuccessListener { barcodes ->
                            barcodes.firstOrNull()?.rawValue?.let { value ->
                                Log.d("BarcodeScanner", "Detected barcode: $value")
                                eventSink?.success(value)
                            }
                        }
                        .addOnFailureListener {
                            Log.e("BarcodeScanner", "Barcode scan failed", it)
                        }
                        .addOnCompleteListener {
                            imageProxy.close()
                        }
                } else {
                    imageProxy.close()
                }
            }

            try {
                cameraProvider?.unbindAll()
                camera = cameraProvider?.bindToLifecycle(
                    lifecycleOwner,
                    CameraSelector.DEFAULT_BACK_CAMERA,
                    preview,
                    analysis
                )
                isScanning = true

                camera?.cameraInfo?.torchState?.observe(lifecycleOwner) { state ->
                    val isTorchOn = state == TorchState.ON
                    torchButton.setImageResource(
                        if (isTorchOn)
                            R.drawable.baseline_flash_on_24
                        else
                            R.drawable.baseline_flash_off_24
                    )
                }

                torchButton.bringToFront()

            } catch (e: Exception) {
                Log.e("BarcodeScanner", "Camera use case binding failed", e)
            }

        }, ContextCompat.getMainExecutor(context))
    }

    fun startScanning() {
        if (!isScanning) {
            Log.d("BarcodeScanner", "Starting camera for scanning")
            cameraPreview.visibility = View.VISIBLE
            startCamera()
            animateScanLine()
        } else {
            Log.d("BarcodeScanner", "Already scanning")
        }
    }

    private fun animateScanLine() {
        scanLine.post {
            ObjectAnimator.ofFloat(
                scanLine, "translationY",
                0f, scanFrame.height.toFloat() - scanLine.height
            ).apply {
                duration = 2000
                repeatMode = ObjectAnimator.REVERSE
                repeatCount = ObjectAnimator.INFINITE
                interpolator = LinearInterpolator()
                start()
            }
        }
    }

    fun stopScanning() {
        Log.d("BarcodeScanner", "Stopping camera")
        cameraProvider?.unbindAll()
        isScanning = false

        // Hide camera preview when stopped
        cameraPreview.post {
            cameraPreview.visibility = View.GONE
        }
    }


    fun toggleTorch() {
        camera?.let {
            val torchState = it.cameraInfo.torchState.value
            it.cameraControl.enableTorch(torchState != TorchState.ON)
        }
    }

    fun setZoom(zoom: Float) {
        camera?.cameraControl?.setZoomRatio(zoom)
    }

    override fun getView(): View = rootLayout

    override fun dispose() {
        stopScanning()
        cameraExecutor.shutdown()
    }
}


