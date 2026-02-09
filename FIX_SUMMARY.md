# 滚轮选择器闪烁跳变问题修复总结

## 问题诊断

用户在使用此滚轮选择器做时间选择器时，遇到了慢速滚动时的闪烁跳变问题，而快速滚动则正常。

### 具体现象
- 慢速拖动 55→57，滚轮会显示 55→56→57→58
- 手指未松开时，滚轮快速跳变从 58 跳回 56
- 然后再 56→57→58，接着跳回 57
- 只有一划然后立即松开，才不会出现跳变
- 快速滚动（用力一划）时正常，频繁更新但不卡顿

### 根本原因分析

#### **问题 1: 双重回调导致重复更新（iOS & Android）**

**Android - WheelPickerView.kt**
```kotlin
// 在 checkAndTriggerHaptic() 中触发一次回调
onValueChanged?.invoke(currentIndex)  // 第一次

// 在 snapToNearestItem() 中再触发一次回调
onValueChanged?.invoke(selectedIndex)  // 第二次
```

**iOS - WheelPickerView.swift**
```swift
// 在 checkAndTriggerHaptic() 中触发一次回调
onValueChange?(clampedIndex)  // 第一次

// 在 snapToNearestItem() 中再触发一次回调  
onValueChange?(selectedIndex)  // 第二次
```

**后果**: 单次滚动位置变化会导致两次 `setState`，React 重新渲染两次，加上原生代码本身的动画，造成视觉跳变。

#### **问题 2: React Props 干扰原生滚动状态（iOS）**

在 WheelPickerViewManager.swift 中：
```swift
@objc var selectedIndex: NSNumber = 0 {
    didSet {
        wheelPicker.setSelectedIndex(selectedIndex.intValue)  // 直接重置滚动位置
    }
}
```

**时序问题**:
1. 用户手指按在屏幕上，缓慢拖动
2. 原生代码计算出位置 58，触发 onValueChange 回调
3. JS 侧 setState，re-render
4. React Native 发送新的 selectedIndex props（可能是 56 或其他之前的值）
5. 原生代码立即调用 `setSelectedIndex()` 重置 scrollOffset
6. 用户继续拖动，又回到 58，重复上述过程
7. 导致反复跳变

#### **问题 3: 缺少触摸状态检查（Android）**

在 `computeScroll()` 完成时无条件调用 `snapToNearestItem()`：
```kotlin
if (scroller.isFinished) {
    isFling = false
    snapToNearestItem()  // 用户可能还在按住屏幕！
}
```

在慢速拖动中，用户可能先放开手指，但中间可能还会有多次 scroll 事件，导致 snap 逻辑被错误地触发多次。

---

## 修复方案

### **修复 1: 避免双重回调（iOS & Android）**

**核心思想**: 区分 **用户交互时的回调** 和 **动画完成时的回调**

#### Android 修复

```kotlin
// 添加触摸状态标记
private var isUserTouching = false

override fun onTouchEvent(event: MotionEvent): Boolean {
    when (event.action) {
        MotionEvent.ACTION_DOWN -> isUserTouching = true
        MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
            isUserTouching = false
            if (!isFling) {
                snapToNearestItem()  // 只在用户放开时调用
            }
        }
    }
    // ... 其他逻辑
}

// 修改 checkAndTriggerHaptic() - 仅在用户交互时触发回调
private fun checkAndTriggerHaptic() {
    if (items.isEmpty()) return
    if (!isUserTouching && !isFling) return  // 不在交互时不处理
    
    val currentIndex = (scrollOffset / itemHeight).roundToInt().coerceIn(0, items.size - 1)
    if (currentIndex != lastSelectedIndex) {
        lastSelectedIndex = currentIndex
        triggerHaptic()
        onValueChanged?.invoke(currentIndex)  // 仅此处回调
    }
}

// snapToNearestItem() 中，只有当值确实改变时才回调
private fun snapToNearestItem() {
    val targetIndex = (scrollOffset / itemHeight).roundToInt().coerceIn(0, items.size - 1)
    if (targetIndex != selectedIndex) {
        selectedIndex = targetIndex
        lastSelectedIndex = targetIndex  // 同步 lastSelectedIndex
        onValueChanged?.invoke(selectedIndex)
    }
}
```

#### iOS 修复

```swift
// 添加交互状态标记
private var isUserDragging: Bool = false
private var isDecelerating: Bool = false

// 修改 checkAndTriggerHaptic() - 仅在用户交互时触发回调
private func checkAndTriggerHaptic() {
    guard items.count > 0 else { return }
    if !isUserDragging && !isDecelerating { return }  // 不在交互时不处理
    
    let currentOffset = scrollView.contentOffset.y
    let currentIndex = Int(round(currentOffset / itemHeight))
    let clampedIndex = max(0, min(items.count - 1, currentIndex))

    if clampedIndex != lastSelectedIndex {
        lastSelectedIndex = clampedIndex
        feedbackGenerator.selectionChanged()
        feedbackGenerator.prepare()
        onValueChange?(clampedIndex)  // 仅此处回调
    }
}

// snapToNearestItem() 中，保证只有一次回调
private func snapToNearestItem() {
    let nearestIndex = Int(round(scrollView.contentOffset.y / itemHeight))
    let clampedIndex = max(0, min(items.count - 1, nearestIndex))

    scrollToIndex(clampedIndex, animated: true)

    if clampedIndex != selectedIndex {
        selectedIndex = clampedIndex
        lastSelectedIndex = clampedIndex
        onValueChange?(selectedIndex)  // 仅此处回调
    }
}
```

### **修复 2: 阻止 Props 在交互时干扰滚动（iOS）**

```swift
@objc public func setSelectedIndex(_ index: Int) {
    guard index >= 0 && index < items.count else { return }
    selectedIndex = index
    lastSelectedIndex = index
    
    // 关键修复: 仅在用户未交互时才更新滚动位置
    if !isUserDragging && !isDecelerating {
        scrollToIndex(index, animated: false)
    }
}
```

**原理**: 在用户正在拖动或滚动减速时，不响应外部的 `selectedIndex` props 更新，避免打断用户的交互。

### **修复 3: 完善 ScrollView Delegate（iOS）**

```swift
extension WheelPickerView: UIScrollViewDelegate {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserDragging = true
        isDecelerating = false
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isUserDragging = false
        if !decelerate {
            isDecelerating = false
            snapToNearestItem()
        } else {
            isDecelerating = true  // 开始减速动画，标记为正在进行
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isDecelerating = false
        snapToNearestItem()  // 减速完成，现在执行 snap
    }
}
```

---

## 使用建议（时间选择器最佳实践）

### ❌ 错误的做法
```typescript
const [hours, setHours] = useState(0);

<WheelPicker
  items={Array.from({length: 24}, (_, i) => String(i).padStart(2, '0'))}
  selectedIndex={hours}
  onValueChange={(index) => {
    // 直接 setState - 这会导致频繁的 re-render
    // 然后 props 更新会干扰原生滚动
    setHours(index);
  }}
/>
```

**为什么错误**: 
- `onValueChange` 每次滚动都会触发，setState 导致重新渲染
- 新的 `selectedIndex` props 被发送回原生层
- 如果用户还在拖动，会打断滚动状态

### ✅ 正确的做法

#### 方案 A: 使用 useRef 缓存，延迟同步
```typescript
const [hours, setHours] = useState(0);
const pendingHours = useRef(hours);

<WheelPicker
  items={Array.from({length: 24}, (_, i) => String(i).padStart(2, '0'))}
  selectedIndex={hours}
  onValueChange={(index) => {
    // 只更新 ref，不立即 setState
    pendingHours.current = index;
  }}
  onScrollEnd={() => {
    // 滚动完成后再更新（如果原生暴露这个事件）
    setHours(pendingHours.current);
  }}
/>
```

#### 方案 B: 使用 useCallback 与 useMemo 优化
```typescript
const [hours, setHours] = useState(0);

const onValueChange = useCallback((index: number) => {
  // 使用 functional state update 避免闭包问题
  setHours(index);
}, []);

const pickerItems = useMemo(() => 
  Array.from({length: 24}, (_, i) => String(i).padStart(2, '0')),
  []
);

<WheelPicker
  items={pickerItems}
  selectedIndex={hours}
  onValueChange={onValueChange}
/>
```

#### 方案 C: 外部控制 vs 受控（推荐）
```typescript
const [hours, setHours] = useState(0);
const [isScrolling, setIsScrolling] = useState(false);

<WheelPicker
  items={pickerItems}
  selectedIndex={isScrolling ? undefined : hours}  // 滚动时不更新
  onValueChange={setHours}
/>
```

---

## 验证修复

### 测试用例

1. **慢速拖动测试**
   - 缓慢从 0 拖动到 23
   - 观察是否有跳变、重复或回退现象
   - 应该平滑过渡，无闪烁

2. **中断拖动测试**
   - 拖动到中间（如 12），暂停但不放开
   - 继续拖动
   - 应该继续平滑滚动，无跳变

3. **快速滑动测试**
   - 用力一划，快速滚动
   - 应该有惯性，平滑减速，最终 snap 到整数位

4. **外部更新测试**（如点击按钮设置时间）
   ```typescript
   const setTimeFromButton = (hours: number) => {
     setHours(hours);  // 外部更新 selectedIndex
   };
   ```
   - 点击按钮，更新时间
   - 滚轮应该平滑滚动到新位置
   - 不应该中断用户当前的拖动

5. **多个滚轮联动测试**
   ```typescript
   <View style={styles.row}>
     <WheelPicker {...hoursProps} />
     <WheelPicker {...minutesProps} />
     <WheelPicker {...secondsProps} />
   </View>
   ```
   - 操作一个滚轮时，其他滚轮不应受影响
   - 应能独立平滑滚动

---

## 性能注意

这个修复虽然解决了逻辑问题，但对于时间选择器等频繁更新场景，建议：

1. **限制回调频率** - 如果 JS 侧处理较复杂，考虑 debounce/throttle
2. **避免在 onValueChange 中做重操作** - 保持回调轻量
3. **使用 Redux/MobX** - 避免多层级 props 穿透导致的重新渲染

示例（加入 debounce）:
```typescript
const debouncedSetHours = useCallback(
  debounce((index: number) => {
    setHours(index);
  }, 100),  // 100ms 内的多次更新合并为一次
  []
);

<WheelPicker
  selectedIndex={hours}
  onValueChange={debouncedSetHours}
/>
```

---

## 相关文件修改

- ✅ [Android WheelPickerView.kt](../android/src/main/java/com/wheelpicker/WheelPickerView.kt)
  - 添加 `isUserTouching` 状态标记
  - 修改 `onTouchEvent()` 管理触摸状态
  - 修改 `checkAndTriggerHaptic()` 仅在交互时回调
  - 修改 `snapToNearestItem()` 同步 `lastSelectedIndex`

- ✅ [iOS WheelPickerView.swift](../ios/WheelPickerView.swift)
  - 添加 `isUserDragging` 和 `isDecelerating` 状态
  - 修改 `setSelectedIndex()` 避免在交互时更新滚动
  - 修改 `checkAndTriggerHaptic()` 仅在交互时回调
  - 修改 `snapToNearestItem()` 同步 `lastSelectedIndex`
  - 完善 `UIScrollViewDelegate` 实现，添加 `scrollViewWillBeginDragging()`

- WheelPickerViewManager.kt - 无需修改（已正确实现）
- WheelPickerViewManager.swift - 无需修改（已正确实现）
