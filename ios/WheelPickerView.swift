import UIKit

@objc public class WheelPickerView: UIView {

    private var items: [String] = []
    private var selectedIndex: Int = 0
    private var unit: String?
    private var fontFamily: String?
    private var lastSelectedIndex: Int = 0
    private var isUserDragging: Bool = false
    private var isDecelerating: Bool = false
    private var lastEventTimestamp: TimeInterval = 0
    private let MIN_EVENT_INTERVAL_MS: TimeInterval = 0.016 // ~16ms

    private let feedbackGenerator = UISelectionFeedbackGenerator()

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let selectionIndicator = UIView()

    private let itemHeight: CGFloat = 48
    private let visibleItems: Int = 5

    // 可自定义的颜色
    private var textColor: UIColor = UIColor(red: 28/255, green: 28/255, blue: 28/255, alpha: 1)
    private var selectionBackgroundColor: UIColor = UIColor(red: 247/255, green: 249/255, blue: 255/255, alpha: 1)

    @objc public var onValueChange: ((_ index: Int) -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear

        selectionIndicator.backgroundColor = selectionBackgroundColor
        selectionIndicator.layer.cornerRadius = 16
        addSubview(selectionIndicator)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.decelerationRate = .normal
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = true
        // 关键修改：禁用嵌套滚动以防止事件穿透
        scrollView.canCancelContentTouches = true
        scrollView.delaysContentTouches = true
        addSubview(scrollView)

        scrollView.addSubview(contentView)

        feedbackGenerator.prepare()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let totalHeight = itemHeight * CGFloat(visibleItems)
        let yOffset = (bounds.height - totalHeight) / 2

        scrollView.frame = CGRect(x: 0, y: yOffset, width: bounds.width, height: totalHeight)

        let padding = itemHeight * CGFloat(visibleItems / 2)
        let contentHeight = CGFloat(items.count) * itemHeight + padding * 2
        contentView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: contentHeight)
        scrollView.contentSize = contentView.bounds.size

        let indicatorY = yOffset + itemHeight * CGFloat(visibleItems / 2)
        selectionIndicator.frame = CGRect(x: 28, y: indicatorY, width: bounds.width - 56, height: itemHeight)

        scrollView.contentInset = .zero

        updateLabels()
        scrollToIndex(selectedIndex, animated: false)
    }

    private func getFont() -> UIFont {
        if let fontFamily = fontFamily, let customFont = UIFont(name: fontFamily, size: 24) {
            return customFont
        }
        return UIFont.systemFont(ofSize: 24, weight: .semibold)
    }

    private func updateLabels() {
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let font = getFont()
        let padding = itemHeight * CGFloat(visibleItems / 2)

        for (index, item) in items.enumerated() {
            let label = UILabel()
            label.text = item
            label.textAlignment = .center
            label.font = font
            label.textColor = textColor
            let yPosition = padding + CGFloat(index) * itemHeight
            label.frame = CGRect(x: 0, y: yPosition, width: bounds.width, height: itemHeight)
            label.tag = index
            contentView.addSubview(label)

            if let unit = unit {
                let unitLabel = UILabel()
                unitLabel.text = unit
                unitLabel.textAlignment = .left
                unitLabel.font = font
                unitLabel.textColor = textColor
                unitLabel.frame = CGRect(x: bounds.width / 2 + 8, y: yPosition, width: 50, height: itemHeight)
                unitLabel.tag = 1000 + index
                contentView.addSubview(unitLabel)

                label.frame = CGRect(x: 0, y: yPosition, width: bounds.width / 2 - 12, height: itemHeight)
                label.textAlignment = .right
            }
        }

        updateLabelAppearances()
    }

    private func updateLabelAppearances() {
        let centerY = scrollView.contentOffset.y + scrollView.bounds.height / 2

        for subview in contentView.subviews {
            guard let label = subview as? UILabel else { continue }

            let labelCenterY = label.frame.midY
            let distance = abs(labelCenterY - centerY) / itemHeight

            let opacity: CGFloat
            let scale: CGFloat

            if distance < 0.5 {
                opacity = 1.0
                scale = 1.0
            } else if distance < 1.5 {
                opacity = 0.4
                scale = 0.95
            } else {
                opacity = 0.2
                scale = 0.9
            }

            label.alpha = opacity
            label.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    @objc public func setItems(_ newItems: [String]) {
        items = newItems
        updateLabels()
    }

    @objc public func setUnit(_ newUnit: String?) {
        unit = newUnit
        updateLabels()
    }

    @objc public func setFontFamily(_ newFontFamily: String?) {
        fontFamily = newFontFamily
        updateLabels()
    }

    @objc public func setSelectedIndex(_ index: Int) {
        guard index >= 0 && index < items.count else { return }
        selectedIndex = index
        lastSelectedIndex = index
        // 仅在用户当前未拖动时才程序化滚动
        if !isUserDragging && !isDecelerating {
            scrollToIndex(index, animated: false)
        }
    }

    @objc public func setTextColor(_ color: UIColor) {
        textColor = color
        updateLabels()
    }

    @objc public func setSelectionBackgroundColor(_ color: UIColor) {
        selectionBackgroundColor = color
        selectionIndicator.backgroundColor = color
    }

    private func scrollToIndex(_ index: Int, animated: Bool) {
        let offset = CGFloat(index) * itemHeight
        scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: animated)
    }

    private func snapToNearestItem() {
        guard items.count > 0 else { return }

        let currentOffset = scrollView.contentOffset.y
        var nearestIndex = Int(round(currentOffset / itemHeight))
        nearestIndex = max(0, min(items.count - 1, nearestIndex))

        scrollToIndex(nearestIndex, animated: true)

        if nearestIndex != selectedIndex {
            selectedIndex = nearestIndex
            lastSelectedIndex = nearestIndex
            // 确保立即发出最终snap事件
            lastEventTimestamp = Date().timeIntervalSince1970
            onValueChange?(selectedIndex)
        }
    }

    private func checkAndTriggerHaptic() {
        guard items.count > 0 else { return }
        // 仅在用户交互期间触发触觉反馈，不在程序化滚动期间
        if !isUserDragging && !isDecelerating { return }

        let currentOffset = scrollView.contentOffset.y
        let currentIndex = Int(round(currentOffset / itemHeight))
        let clampedIndex = max(0, min(items.count - 1, currentIndex))
        let now = Date().timeIntervalSince1970

        if clampedIndex != lastSelectedIndex {
            // 限制事件频率至约60fps以减少JS桥接开销
            if now - lastEventTimestamp >= MIN_EVENT_INTERVAL_MS {
                lastSelectedIndex = clampedIndex
                lastEventTimestamp = now
                feedbackGenerator.selectionChanged()
                feedbackGenerator.prepare()
                // 仅在用户交互期间触发回调
                onValueChange?(clampedIndex)
            }
        }
    }
}

extension WheelPickerView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateLabelAppearances()
        checkAndTriggerHaptic()
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserDragging = true
        isDecelerating = false
        // 关键修改：拖动开始时通知父视图不要拦截触摸事件
        superview?.superview?.gestureRecognizers?.forEach { recognizer in
            if let panGesture = recognizer as? UIPanGestureRecognizer {
                panGesture.delaysTouchesBegan = true
            }
        }
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isUserDragging = false
        if !decelerate {
            isDecelerating = false
            snapToNearestItem()
        } else {
            isDecelerating = true
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isDecelerating = false
        snapToNearestItem()
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let maxOffset = CGFloat(max(0, items.count - 1)) * itemHeight
        let clampedTarget = max(0, min(maxOffset, targetContentOffset.pointee.y))
        targetContentOffset.pointee.y = clampedTarget
    }
    
    // 关键修改：添加触摸处理方法以更好地控制事件流
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        // 确保触摸事件被正确处理
        if hitView == scrollView || hitView?.isDescendant(of: scrollView) == true {
            return hitView
        }
        return nil
    }
    
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // 确保整个视图区域都能接收触摸事件
        return bounds.contains(point)
    }
}