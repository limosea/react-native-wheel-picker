package com.wheelpicker

import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.events.Event
import com.facebook.react.uimanager.events.RCTEventEmitter

class WheelPickerEvent(viewId: Int, private val index: Int) : Event<WheelPickerEvent>(viewId) {
    override fun getEventName(): String {
        return "onValueChange"
    }

    override fun canCoalesce(): Boolean {
        return false
    }

    override fun dispatch(rctEventEmitter: RCTEventEmitter) {
        val event = Arguments.createMap().apply {
            putInt("index", index)
        }
        rctEventEmitter.receiveEvent(viewTag, eventName, event)
    }
}
