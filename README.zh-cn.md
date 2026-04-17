# @limosea/react-native-wheel-picker

[English](./README.md) | [中文](./README.zh-cn.md)

一个高性能的 React Native 原生滚轮选择器，支持流畅滚动、触觉反馈和自定义样式。

本库是 [react-native-wheel-picker](https://github.com/sinandsean/react-native-wheel-picker) 的分支，进行了一些改进，主要增加了实时回调功能和样式自定义。

## 特性

- 🚀 原生实现，支持带惯性的流畅滚动
- 📱 支持触觉反馈
- 🔠 可自定义字体、颜色和大小
- 🔄 支持多列选择器（例如：英尺 + 英寸）
- 🛡️ 防止滚动事件穿透到外部 ScrollView
- ⚙️ 可配置回调时机（实时 vs 释放时）

## 安装

```bash
npm install @limosea/react-native-wheel-picker
# 或
yarn add @limosea/react-native-wheel-picker
```

### iOS

```bash
cd ios && pod install
```

### Android

无需额外配置，库会自动链接。

## 使用

### 基本用法

```tsx
import { WheelPicker } from "@limosea/react-native-wheel-picker";

function App() {
  const [selectedIndex, setSelectedIndex] = useState(0);
  const items = ["项目 1", "项目 2", "项目 3", "项目 4", "项目 5"];

  return (
    <WheelPicker
      items={items}
      selectedIndex={selectedIndex}
      onValueChange={setSelectedIndex}
    />
  );
}
```

### 带单位标签

```tsx
<WheelPicker
  items={["50", "55", "60", "65", "70", "75", "80"]}
  selectedIndex={selectedIndex}
  unit="kg"
  onValueChange={setSelectedIndex}
/>
```

### 多列选择器

```tsx
import { MultiColumnWheelPicker } from "@limosea/react-native-wheel-picker";

function HeightPicker() {
  const [feet, setFeet] = useState(5);
  const [inches, setInches] = useState(6);

  return (
    <MultiColumnWheelPicker
      columns={[
        {
          values: ["4", "5", "6", "7"],
          unit: "ft",
          selectedIndex: feet - 4,
          onSelect: (index) => setFeet(index + 4),
        },
        {
          values: [
            "0",
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            "10",
            "11",
          ],
          unit: "in",
          selectedIndex: inches,
          onSelect: setInches,
        },
      ]}
    />
  );
}
```

### 自定义字体

```tsx
<WheelPicker
  items={items}
  selectedIndex={selectedIndex}
  fontFamily="SFProText-Semibold"
  onValueChange={setSelectedIndex}
/>
```

### 自定义选中背景

```tsx
<WheelPicker
  items={items}
  selectedIndex={selectedIndex}
  selectionBackgroundColor="#E8F0FE"
  onValueChange={setSelectedIndex}
/>
```

### 实时更新的时间选择器

```tsx
const HOURS_BASE = Array.from({ length: 24 }, (_, i) => i.toString().padStart(2, '0'));
const MINUTES_BASE = Array.from({ length: 60 }, (_, i) => i.toString().padStart(2, '0'));

const INFINITE_HOURS = Array(45).fill(HOURS_BASE).flat();
const INFINITE_MINUTES = Array(45).fill(MINUTES_BASE).flat();

const INITIAL_HOUR_INDEX = HOURS_BASE.length * 15;
const INITIAL_MINUTE_INDEX = MINUTES_BASE.length * 15;

const [selectedIndices, setSelectedIndices] = React.useState(() => {
  return {
    hour: INITIAL_HOUR_INDEX + now.getHours(),
    minute: INITIAL_MINUTE_INDEX + now.getMinutes()
  };
});

const displayTime = React.useMemo(() => {
  // 在此计算时间差
  return {
    hours: hoursDiff,
    minutes: minutesDiff,
    isNextMinute: false
  }
}, [selectedIndices, HOURS_BASE.length, MINUTES_BASE.length]);

<View>
  {displayTime.isNextMinute ? (
    <Text>少于 1 分钟</Text>
  ) : (
    <>
      <Text>
        {displayTime.hours < 10 ? `0${displayTime.hours}` : displayTime.hours}
      </Text>
      <Text>小时</Text>
      <Text>
        {displayTime.minutes < 10 ? `0${displayTime.minutes}` : displayTime.minutes}
      </Text>
      <Text>分钟</Text>
    </>
  )}
</View>

<MultiColumnWheelPicker
  style={{ width: '100%', height: 160 }}
  fontFamily='Alibaba_PuHuiTi_2.0_105_Heavy_105_Heavy'
  columns={[
    {
      values: INFINITE_HOURS,
      selectedIndex: selectedIndices.hour,
      onSelect: (index) => {
        setSelectedIndices(prev => ({
          ...prev,
          hour: index
        }));
      }
    },
    {
      values: INFINITE_MINUTES,
      selectedIndex: selectedIndices.minute,
      onSelect: (index) => {
        setSelectedIndices(prev => ({
          ...prev,
          minute: index
      }));
      }
    }
  ]}
/>
```

## 属性

| 属性                       | 类型                      | 默认值      | 描述                                                                |
| -------------------------- | ------------------------- | ----------- | ------------------------------------------------------------------- |
| `items`                    | `string[]`                | `必填`      | 要显示的字符串项数组                                                |
| `selectedIndex`            | `number`                  | `必填`      | 当前选中的索引                                                      |
| `unit`                     | `string`                  | `undefined` | 可选的单位标签（如 "kg"、"cm"）                                     |
| `fontFamily`               | `string`                  | `undefined` | 自定义字体名称                                                      |
| `textColor`                | `string`                  | `"#1C1C1C"` | 文本颜色，十六进制格式（如 "#FF0000"）                              |
| `textSize`                 | `number`                  | `24`        | 文本大小，单位为 dp（Android）/ pt（iOS）                           |
| `selectionBackgroundColor` | `string`                  | `"#F7F9FF"` | 选中指示器的背景颜色，十六进制格式                                  |
| `immediateCallback`        | `boolean`                 | `true`      | 是否在滚动过程中触发回调（`true`）还是仅在滚动停止时触发（`false`） |
| `onValueChange`            | `(index: number) => void` | `undefined` | 选中值改变时的回调                                                  |
| `style`                    | `ViewStyle`               | `undefined` | 容器样式                                                            |
| `testID`                   | `string`                  | `undefined` | 用于端到端测试的测试 ID                                             |

## 回调时机行为

`immediateCallback` 属性控制 `onValueChange` 回调的触发时机：

- **`immediateCallback={true}`**（默认）：滚动过程中持续触发回调
  - 提供实时反馈
  - 适用于需要立即响应的 UI 更新
  - 事件频率较高

- **`immediateCallback={false}`**：仅在滚动停止时触发回调
  - 减少事件频率
  - 适用于耗时操作
  - 用户释放时保证获得最终值

注意：无论 `immediateCallback` 设置如何，用户释放选择器时始终会发送最终选中的值。

## 样式选项

### 文本颜色

- 接受十六进制颜色字符串（如 `"#FF0000"`、`"#333"`、`"#FF6B6B"`）
- 支持 3 位和 6 位十六进制格式
- 十六进制字符串不支持透明度通道

### 文本大小

- 单位为 dp（Android）或 pt（iOS）
- 默认大小为 24
- 较大的值可提高可读性，但可能影响项目间距

### 选中背景颜色

- 接受十六进制颜色字符串（如 `"#F7F9FF"`、`"#E8F0FE"`）
- 支持 3 位、4 位（带透明度）、6 位和 8 位（带透明度）十六进制格式
- 自定义中心选中指示器的背景

### 字体

- 使用系统字体名称或自定义字体
- 确保自定义字体已在原生项目中正确注册

## 性能建议

1. **使用 `useCallback`** 包装 `onValueChange` 以防止不必要的重新渲染
2. **使用 `useMemo` 缓存大数组** 以避免重复创建
3. **对于耗时操作考虑使用 `immediateCallback={false}`**
4. **对于非常大的数据集，如需要可对快速变化进行防抖处理**

```tsx
const handleValueChange = useCallback((index: number) => {
  setSelectedIndex(index);
  // 耗时操作
}, []);

const memoizedItems = useMemo(() => {
  return generateLargeItemList();
}, []);
```

## 许可证

MIT
