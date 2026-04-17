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
    private var immediateCallback: Bool = true
    private var textColor: UIColor = UIColor(red: 28/255, green: 28/255, blue: 28/255, alpha: 1)
    private var textSize: CGFloat = 24
    private var lastLayoutWidth: CGFloat = 0

    private let feedbackGenerator = UISelectionFeedbackGenerator()

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let selectionIndicator = UIView()

    private let itemHeight: CGFloat = 48
    private let visibleItems: Int = 5

    // 可自定义的颜色
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

        if lastLayoutWidth != bounds.width {
            lastLayoutWidth = bounds.width
            updateLabels()
        } else {
            updateLabelAppearances()
        }
        scrollToIndex(selectedIndex, animated: false)
    }

    private func getFont() -> UIFont {
        if let fontFamily = fontFamily, let customFont = UIFont(name: fontFamily, size: textSize) {
            return customFont
        }
        return UIFont.systemFont(ofSize: textSize, weight: .semibold)
    }

    private func updateLabels() {
        let font = getFont()
        let padding = itemHeight * CGFloat(visibleItems / 2)
        let hasUnit = unit != nil

        // 计算需要的 label 数量（有 unit 时每项 2 个 label）
        let labelsPerItem = hasUnit ? 2 : 1
        let neededCount = items.count * labelsPerItem
        let existingSubviews = contentView.subviews

        // 移除多余 label
        if existingSubviews.count > neededCount {
            for i in stride(from: existingSubviews.count - 1, through: neededCount, by: -1) {
                existingSubviews[i].removeFromSuperview()
            }
        }

        for (index, item) in items.enumerated() {
            let yPosition = padding + CGFloat(index) * itemHeight
            let labelIndex = index * labelsPerItem

            // 复用或创建主 label
            let label: UILabel
            if labelIndex < contentView.subviews.count, let existing = contentView.subviews[labelIndex] as? UILabel {
                label = existing
            } else {
                label = UILabel()
                contentView.addSubview(label)
            }
            label.text = item
            label.font = font
            label.textColor = textColor
            label.tag = index

            if hasUnit {
                label.textAlignment = .right
                label.frame = CGRect(x: 0, y: yPosition, width: bounds.width / 2 - 12, height: itemHeight)

                let unitLabelIndex = labelIndex + 1
                let unitLabel: UILabel
                if unitLabelIndex < contentView.subviews.count, let existing = contentView.subviews[unitLabelIndex] as? UILabel {
                    unitLabel = existing
                } else {
                    unitLabel = UILabel()
                    contentView.addSubview(unitLabel)
                }
                unitLabel.text = unit
                unitLabel.textAlignment = .left
                unitLabel.font = font
                unitLabel.textColor = textColor
                unitLabel.frame = CGRect(x: bounds.width / 2 + 8, y: yPosition, width: 50, height: itemHeight)
                unitLabel.tag = 1000 + index
            } else {
                label.textAlignment = .center
                label.frame = CGRect(x: 0, y: yPosition, width: bounds.width, height: itemHeight)
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
        setNeedsLayout()
    }

    @objc public func setUnit(_ newUnit: String?) {
        unit = newUnit
        updateLabels()
    }

    @objc public func setFontFamily(_ newFontFamily: String?) {
        fontFamily = newFontFamily
        updateLabels()
    }

    @objc public func setImmediateCallback(_ immediate: Bool) {
        immediateCallback = immediate
    }

    @objc public func setTextColor(_ color: UIColor) {
        textColor = color
        updateLabels()
    }

    @objc public func setTextSize(_ size: CGFloat) {
        textSize = size
        updateLabels()
    }

    @objc public func setSelectedIndex(_ index: Int) {
        guard index >= 0 && index < items.count else { return }
        // 防重入：如果 index 未变且未交互，跳过以避免 setState 循环
        guard index != selectedIndex || isUserDragging || isDecelerating else { return }
        selectedIndex = index
        lastSelectedIndex = index
        // 仅在用户当前未拖动时才程序化滚动
        if !isUserDragging && !isDecelerating {
            scrollToIndex(index, animated: false)
        }
    }

    @objc public func setSelectionBackgroundColor(_ color: UIColor) {
        selectionBackgroundColor = color
        selectionIndicator.backgroundColor = color
    }

    private func scrollToIndex(_ index: Int, animated: Bool) {
        let offset = CGFloat(index) * itemHeight
        scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: animated)
    }

    private var isSnapping: Bool = false

    private func snapToNearestItem() {
        guard items.count > 0 else { return }
        guard !isSnapping else { return }

        let currentOffset = scrollView.contentOffset.y
        var nearestIndex = Int(round(currentOffset / itemHeight))
        nearestIndex = max(0, min(items.count - 1, nearestIndex))

        let targetOffset = CGFloat(nearestIndex) * itemHeight
        let needsAnimation = abs(targetOffset - currentOffset) > 0.5

        if needsAnimation {
            isSnapping = true
            scrollToIndex(nearestIndex, animated: true)
        }

        if nearestIndex != selectedIndex {
            selectedIndex = nearestIndex
            lastSelectedIndex = nearestIndex
            // 确保立即发出最终snap事件
            lastEventTimestamp = Date().timeIntervalSince1970
            // 松手时总是触发回调（无论immediateCallback设置）
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
                // 根据immediateCallback决定是否立即回调
                if immediateCallback {
                    onValueChange?(clampedIndex)
                }
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

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // snap 动画完成后重置标记
        isSnapping = false
        isDecelerating = false
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let maxOffset = CGFloat(max(0, items.count - 1)) * itemHeight
        let clampedTarget = max(0, min(maxOffset, targetContentOffset.pointee.y))
        targetContentOffset.pointee.y = clampedTarget
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 将整个视图区域内的触摸事件转发到 scrollView
        if bounds.contains(point) {
            return scrollView
        }
        return nil
    }
}