import Foundation
import React
import UIKit

@objc(WheelPickerViewManager)
class WheelPickerViewManager: RCTViewManager {

    override func view() -> UIView! {
        return WheelPickerViewWrapper()
    }

    override static func requiresMainQueueSetup() -> Bool {
        return true
    }

}

@objc(WheelPickerViewWrapper)
class WheelPickerViewWrapper: UIView {

    private let wheelPicker = WheelPickerView()

    @objc var items: [String] = [] {
        didSet {
            wheelPicker.setItems(items)
        }
    }

    @objc var selectedIndex: NSNumber = 0 {
        didSet {
            wheelPicker.setSelectedIndex(selectedIndex.intValue)
        }
    }

    @objc var unit: String? {
        didSet {
            wheelPicker.setUnit(unit)
        }
    }

    @objc var fontFamily: String? {
        didSet {
            wheelPicker.setFontFamily(fontFamily)
        }
    }

    @objc var immediateCallback: Bool = true {
        didSet {
            wheelPicker.setImmediateCallback(immediateCallback)
        }
    }

    @objc var textColor: NSString? {
        didSet {
            if let colorString = textColor as String? {
                wheelPicker.setTextColor(hexStringToUIColor(hex: colorString))
            }
        }
    }

    @objc var textSize: NSNumber = 24 {
        didSet {
            wheelPicker.setTextSize(CGFloat(textSize.floatValue))
        }
    }

    @objc var selectionBackgroundColor: NSString? {
        didSet {
            if let colorString = selectionBackgroundColor as String? {
                wheelPicker.setSelectionBackgroundColor(hexStringToUIColor(hex: colorString))
            }
        }
    }

    @objc var onValueChange: RCTDirectEventBlock?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        addSubview(wheelPicker)

        wheelPicker.onValueChange = { [weak self] index in
            self?.onValueChange?(["index": index])
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        wheelPicker.frame = bounds
    }

    private func hexStringToUIColor(hex: String) -> UIColor {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        let defaultColor = UIColor(red: 28/255, green: 28/255, blue: 28/255, alpha: 1)

        let alpha: CGFloat
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat

        switch cString.count {
        case 3:
            let chars = Array(cString)
            guard
                let r = Int(String([chars[0], chars[0]]), radix: 16),
                let g = Int(String([chars[1], chars[1]]), radix: 16),
                let b = Int(String([chars[2], chars[2]]), radix: 16)
            else {
                return defaultColor
            }
            alpha = 1.0
            red = CGFloat(r) / 255.0
            green = CGFloat(g) / 255.0
            blue = CGFloat(b) / 255.0
        case 4:
            let chars = Array(cString)
            guard
                let a = Int(String([chars[0], chars[0]]), radix: 16),
                let r = Int(String([chars[1], chars[1]]), radix: 16),
                let g = Int(String([chars[2], chars[2]]), radix: 16),
                let b = Int(String([chars[3], chars[3]]), radix: 16)
            else {
                return defaultColor
            }
            alpha = CGFloat(a) / 255.0
            red = CGFloat(r) / 255.0
            green = CGFloat(g) / 255.0
            blue = CGFloat(b) / 255.0
        case 6:
            guard let value = Int(cString, radix: 16) else {
                return defaultColor
            }
            alpha = 1.0
            red = CGFloat((value >> 16) & 0xFF) / 255.0
            green = CGFloat((value >> 8) & 0xFF) / 255.0
            blue = CGFloat(value & 0xFF) / 255.0
        case 8:
            guard let value = Int(cString, radix: 16) else {
                return defaultColor
            }
            alpha = CGFloat((value >> 24) & 0xFF) / 255.0
            red = CGFloat((value >> 16) & 0xFF) / 255.0
            green = CGFloat((value >> 8) & 0xFF) / 255.0
            blue = CGFloat(value & 0xFF) / 255.0
        default:
            return UIColor(red: 28/255, green: 28/255, blue: 28/255, alpha: 1)
        }

        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}