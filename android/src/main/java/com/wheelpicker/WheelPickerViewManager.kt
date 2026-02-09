package com.wheelpicker

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.events.RCTEventEmitter
import com.facebook.react.uimanager.UIManagerModule
import com.facebook.react.uimanager.events.EventDispatcher
import com.facebook.react.uimanager.events.Event

@ReactModule(name = WheelPickerViewManager.REACT_CLASS)
class WheelPickerViewManager : SimpleViewManager<WheelPickerView>() {

    companion object {
        const val REACT_CLASS = "WheelPickerView"
    }

    override fun getName(): String = REACT_CLASS

    override fun createViewInstance(context: ThemedReactContext): WheelPickerView {
        return WheelPickerView(context).apply {
            setOnValueChangedListener { index ->
                // Dispatch event through UIManager's EventDispatcher for lower latency
                val uiManager = context.getNativeModule(UIManagerModule::class.java)
                uiManager?.let {
                    it.eventDispatcher.dispatchEvent(WheelPickerEvent(id, index))
                }
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

    override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> {
        return mapOf(
            "onValueChange" to mapOf("registrationName" to "onValueChange")
        )
    }
}
