package com.example.live_barcode_scanner

import android.content.Context
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class BarcodeScannerViewFactory(
    private val lifecycleOwner: LifecycleOwner,
    private val onViewCreated: (BarcodeScannerView) -> Unit
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, id: Int, args: Any?): PlatformView {
        val view = BarcodeScannerView(context, lifecycleOwner )
        onViewCreated(view)
        return view
    }
}
