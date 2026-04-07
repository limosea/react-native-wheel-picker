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

    override func constantsToExport() -> [AnyHashable : Any]! {
        return [:]
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

        if cString.count != 6 && cString.count != 8 {
            return UIColor(red: 28/255, green: 28/255, blue: 28/255, alpha: 1)
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        if cString.count == 6 {
            return UIColor(
                red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                alpha: 1.0
            )
        } else {
            return UIColor(
                red: CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0,
                green: CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0,
                blue: CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0,
                alpha: CGFloat(rgbValue & 0x000000FF) / 255.0
            )
        }
    }
}