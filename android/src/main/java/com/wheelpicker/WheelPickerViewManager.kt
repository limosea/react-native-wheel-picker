package com.wheelpicker

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.events.RCTEventEmitter
import android.graphics.Color

@ReactModule(name = WheelPickerViewManager.REACT_CLASS)
class WheelPickerViewManager : SimpleViewManager<WheelPickerView>() {

    companion object {
        const val REACT_CLASS = "WheelPickerView"
    }

    override fun getName(): String = REACT_CLASS

    override fun createViewInstance(context: ThemedReactContext): WheelPickerView {
        return WheelPickerView(context).apply {
            setOnValueChangedListener { index ->
                // Dispatch event directly via RCTEventEmitter for real-time callbacks
                val eventEmitter = context.getJSModule(RCTEventEmitter::class.java)
                val event = Arguments.createMap().apply { putInt("index", index) }
                eventEmitter?.receiveEvent(id, "onValueChange", event)
            }
        }
    }

    @ReactProp(name = "items")
    fun setItems(view: WheelPickerView, items: ReadableArray?) {
        items?.let {
            val itemList = mutableListOf<String>()
            for (i in 0 until it.size()) {
                itemList.add(it.getString(i) ?: "")
            }
            view.setItems(itemList)
        }
    }

    @ReactProp(name = "selectedIndex")
    fun setSelectedIndex(view: WheelPickerView, index: Int) {
        view.setSelectedIndex(index)
    }

    @ReactProp(name = "unit")
    fun setUnit(view: WheelPickerView, unit: String?) {
        view.setUnit(unit)
    }

    @ReactProp(name = "fontFamily")
    fun setFontFamily(view: WheelPickerView, fontFamily: String?) {
        view.setFontFamily(fontFamily)
    }

    @ReactProp(name = "immediateCallback")
    fun setImmediateCallback(view: WheelPickerView, immediateCallback: Boolean) {
        view.setImmediateCallback(immediateCallback)
    }

    @ReactProp(name = "textColor")
    fun setTextColor(view: WheelPickerView, color: String?) {
        color?.let { view.setTextColor(it) }
    }

    @ReactProp(name = "textSize")
    fun setTextSize(view: WheelPickerView, size: Float) {
        view.setTextSize(size)
    }

    @ReactProp(name = "selectionBackgroundColor")
    fun setSelectionBackgroundColor(view: WheelPickerView, color: String?) {
        color?.let {
            try {
                view.setSelectionBackgroundColor(Color.parseColor(it))
            } catch (_: IllegalArgumentException) {}
        }
    }

    override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> {
        return mapOf(
            "onValueChange" to mapOf("registrationName" to "onValueChange")
        )
    }
}