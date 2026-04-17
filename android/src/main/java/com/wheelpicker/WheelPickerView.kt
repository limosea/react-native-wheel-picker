package com.wheelpicker

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.AttributeSet
import android.Manifest
import android.content.pm.PackageManager
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import android.widget.OverScroller
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

class WheelPickerView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    private var items: List<String> = emptyList()
    private var selectedIndex: Int = 0
    private var lastSelectedIndex: Int = 0

    private val itemHeight = 48 * resources.displayMetrics.density
    private val visibleItems = 5
    private val centerY get() = height / 2f

    private var scrollOffset = 0f
    private val scroller = OverScroller(context)
    private var isFling = false
    private var isUserTouching = false

    private var fontFamily: String? = null
    private var immediateCallback: Boolean = true
    private var textColor: Int = Color.parseColor("#1C1C1C")
    private var textSize: Float = 24f

    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textSize = 24 * resources.displayMetrics.density
        color = Color.parseColor("#1C1C1C")
        textAlign = Paint.Align.CENTER
    }

    private val unitPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textSize = 24 * resources.displayMetrics.density
        color = Color.parseColor("#1C1C1C")
        textAlign = Paint.Align.LEFT
    }

    private val selectionPaint = Paint().apply {
        color = Color.parseColor("#F7F9FF")
        style = Paint.Style.FILL
    }

    private var unit: String? = null
    private var onValueChanged: ((Int) -> Unit)? = null

    // 复用的 RectF 以避免在 onDraw 中每帧分配
    private val selectionRect = RectF()

    private val vibrator: Vibrator by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }

    private val gestureDetector = GestureDetector(context, object : GestureDetector.SimpleOnGestureListener() {
        override fun onDown(e: MotionEvent): Boolean {
            if (!scroller.isFinished) {
                scroller.abortAnimation()
                isFling = false
            }
            // 请求父视图不要拦截触摸事件
            parent?.requestDisallowInterceptTouchEvent(true)
            return true
        }

        override fun onScroll(e1: MotionEvent?, e2: MotionEvent, distanceX: Float, distanceY: Float): Boolean {
            scrollOffset += distanceY
            clampScrollOffset()
            checkAndTriggerHaptic()
            invalidate()
            return true
        }

        override fun onFling(e1: MotionEvent?, e2: MotionEvent, velocityX: Float, velocityY: Float): Boolean {
            isFling = true
            scroller.fling(
                0, scrollOffset.toInt(),
                0, -velocityY.toInt(),
                0, 0,
                Int.MIN_VALUE, Int.MAX_VALUE
            )
            postInvalidateOnAnimation()
            return true
        }
    })

    private fun loadTypeface(fontName: String): Typeface? {
        return try {
            val otfPath = "fonts/$fontName.otf"
            val ttfPath = "fonts/$fontName.ttf"
            try {
                Typeface.createFromAsset(context.assets, otfPath)
            } catch (e: Exception) {
                Typeface.createFromAsset(context.assets, ttfPath)
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun applyTypeface() {
        val typeface = fontFamily?.let { loadTypeface(it) }
        textPaint.typeface = typeface
        unitPaint.typeface = typeface
    }

    private fun updateTextSize() {
        val scaledTextSize = textSize * resources.displayMetrics.density
        textPaint.textSize = scaledTextSize
        unitPaint.textSize = scaledTextSize
    }

    private fun updateTextColor() {
        textPaint.color = textColor
        unitPaint.color = textColor
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val desiredHeight = (itemHeight * visibleItems).toInt()
        val width = MeasureSpec.getSize(widthMeasureSpec)
        setMeasuredDimension(width, desiredHeight)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        val cornerRadius = 16 * resources.displayMetrics.density
        val selectionTop = centerY - itemHeight / 2
        selectionRect.set(
            28 * resources.displayMetrics.density,
            selectionTop,
            width - 28 * resources.displayMetrics.density,
            selectionTop + itemHeight
        )
        canvas.drawRoundRect(selectionRect, cornerRadius, cornerRadius, selectionPaint)

        val centerIndex = (scrollOffset / itemHeight).roundToInt()
        val startIndex = max(0, centerIndex - visibleItems)
        val endIndex = min(items.size - 1, centerIndex + visibleItems)

        for (i in startIndex..endIndex) {
            val itemCenterY = centerY - scrollOffset + i * itemHeight
            val distanceFromCenter = abs(itemCenterY - centerY) / itemHeight

            val opacity = when {
                distanceFromCenter < 0.5f -> 1f
                distanceFromCenter < 1.5f -> 0.4f
                else -> 0.2f
            }
            val scale = 1f - (distanceFromCenter * 0.05f).coerceIn(0f, 0.1f)

            textPaint.alpha = (opacity * 255).toInt()
            unitPaint.alpha = (opacity * 255).toInt()

            val textY = itemCenterY + (textPaint.textSize / 3)

            canvas.save()
            canvas.scale(scale, scale, width / 2f, itemCenterY)

            val valueX = if (unit != null) width / 2f - 20 * resources.displayMetrics.density else width / 2f
            canvas.drawText(items[i], valueX, textY, textPaint)

            unit?.let {
                val unitX = width / 2f + 8 * resources.displayMetrics.density
                canvas.drawText(it, unitX, textY, unitPaint)
            }

            canvas.restore()
        }
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        // 先让 GestureDetector 处理事件（可能触发 onFling 设置 isFling=true）
        val handled = gestureDetector.onTouchEvent(event)

        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                isUserTouching = true
                // 请求父视图不要拦截触摸事件
                parent?.requestDisallowInterceptTouchEvent(true)
            }
            MotionEvent.ACTION_MOVE -> {
                // 持续请求父视图不要拦截触摸事件
                parent?.requestDisallowInterceptTouchEvent(true)
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                isUserTouching = false
                // 释放时允许父视图重新拦截事件
                parent?.requestDisallowInterceptTouchEvent(false)

                if (!isFling) {
                    snapToNearestItem()
                }
            }
        }
        // 确保消费所有触摸事件以防止穿透
        return handled || super.onTouchEvent(event)
    }

    override fun computeScroll() {
        if (scroller.computeScrollOffset()) {
            scrollOffset = scroller.currY.toFloat()
            clampScrollOffset()
            checkAndTriggerHaptic()
            postInvalidateOnAnimation()

            if (scroller.isFinished) {
                isFling = false
                // 用户触摸时不触发snap
                if (!isUserTouching) {
                    snapToNearestItem()
                }
            }
        }
    }

    private fun clampScrollOffset() {
        val maxScroll = (items.size - 1) * itemHeight
        scrollOffset = scrollOffset.coerceIn(0f, maxScroll)
    }
    
    private var lastEventTimestamp: Long = 0L
    private val MIN_EVENT_INTERVAL_MS: Long = 16L

    private fun checkAndTriggerHaptic() {
        if (items.isEmpty()) return
        // 仅在用户交互期间触发触觉反馈和回调，不在snap动画期间
        if (!isUserTouching && !isFling) return

        val currentIndex = (scrollOffset / itemHeight).roundToInt().coerceIn(0, items.size - 1)
        val now = System.currentTimeMillis()
        if (currentIndex != lastSelectedIndex) {
            // 限制事件频率至约60fps以减少JS桥接开销
            if (now - lastEventTimestamp >= MIN_EVENT_INTERVAL_MS) {
                lastSelectedIndex = currentIndex
                lastEventTimestamp = now
                triggerHaptic()
                // 根据immediateCallback决定是否立即回调
                if (immediateCallback) {
                    onValueChanged?.invoke(currentIndex)
                }
            }
        }
    }

    private fun triggerHaptic() {
        if (context.checkSelfPermission(Manifest.permission.VIBRATE) != PackageManager.PERMISSION_GRANTED) return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                vibrator.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_TICK))
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                @Suppress("DEPRECATION")
                vibrator.vibrate(VibrationEffect.createOneShot(10, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(10)
            }
        } catch (_: Exception) {
            // 静默失败，触觉反馈不影响核心功能
        }
    }

    private fun snapToNearestItem() {
        if (items.isEmpty()) return

        // 如果用户仍在触摸，则不触发程序化snap
        if (isUserTouching) return

        // 中止任何现有动画以避免重叠滚动导致跳跃
        if (!scroller.isFinished) {
            scroller.abortAnimation()
        }

        val targetIndex = (scrollOffset / itemHeight).roundToInt().coerceIn(0, items.size - 1)
        val targetOffset = targetIndex * itemHeight

        // 如果已在目标位置，则无需开始滚动
        if (kotlin.math.abs(targetOffset - scrollOffset) < 1f) {
            if (targetIndex != selectedIndex) {
                selectedIndex = targetIndex
                lastSelectedIndex = targetIndex
                lastEventTimestamp = System.currentTimeMillis()
                // 松手时总是触发回调（无论immediateCallback设置）
                onValueChanged?.invoke(selectedIndex)
            }
            return
        }

        scroller.startScroll(
            0, scrollOffset.toInt(),
            0, (targetOffset - scrollOffset).toInt(),
            200
        )

        if (targetIndex != selectedIndex) {
            selectedIndex = targetIndex
            lastSelectedIndex = targetIndex
            // 确保立即发出最终snap事件
            lastEventTimestamp = System.currentTimeMillis()
            // 松手时总是触发回调（无论immediateCallback设置）
            onValueChanged?.invoke(selectedIndex)
        }

        invalidate()
    }

    fun setItems(newItems: List<String>) {
        items = newItems
        invalidate()
    }

    fun setUnit(newUnit: String?) {
        unit = newUnit
        invalidate()
    }

    fun setSelectedIndex(index: Int) {
        if (index in items.indices) {
            // 防重入：如果 index 未变且未交互，跳过以避免 setState 循环
            if (index == selectedIndex && !isUserTouching && !isFling) return
            selectedIndex = index
            lastSelectedIndex = index
            // 仅在未交互时更新scrollOffset以避免中断用户操作
            if (!isUserTouching && !isFling) {
                scrollOffset = index * itemHeight
            }
            invalidate()
        }
    }

    fun setImmediateCallback(immediate: Boolean) {
        immediateCallback = immediate
    }

    fun setTextColor(color: String) {
        try {
            textColor = Color.parseColor(color)
            updateTextColor()
            invalidate()
        } catch (e: IllegalArgumentException) {
            // 如果解析失败，使用默认颜色
            textColor = Color.parseColor("#1C1C1C")
            updateTextColor()
            invalidate()
        }
    }

    fun setTextSize(size: Float) {
        textSize = size
        updateTextSize()
        invalidate()
    }

    fun setOnValueChangedListener(listener: (Int) -> Unit) {
        onValueChanged = listener
    }

    fun setFontFamily(family: String?) {
        fontFamily = family
        applyTypeface()
        invalidate()
    }

    fun setSelectionBackgroundColor(color: Int) {
        selectionPaint.color = color
        invalidate()
    }
}