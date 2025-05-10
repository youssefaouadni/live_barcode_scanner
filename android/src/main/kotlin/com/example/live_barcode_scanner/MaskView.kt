package com.example.live_barcode_scanner

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RectF
import android.view.View
import androidx.core.graphics.toColorInt

@SuppressLint("ViewConstructor")
class MaskView(context: Context, private val frameRect: RectF) : View(context) {
    private val paint = Paint().apply {
        color = "#AA000000".toColorInt() // semi-transparent gray
        isAntiAlias = true
    }

    @SuppressLint("DrawAllocation")
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        // Save the current canvas layer
        val sc = canvas.saveLayer(0f, 0f, width.toFloat(), height.toFloat(), null)

        // Draw full-screen gray overlay
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)

        // Cut out the scan frame area
        val clearPaint = Paint().apply {
            xfermode = PorterDuffXfermode(PorterDuff.Mode.CLEAR)
            isAntiAlias = true
        }
        canvas.drawRoundRect(frameRect, 16f, 16f, clearPaint)

        // Restore the canvas layer
        canvas.restoreToCount(sc)
    }
}
