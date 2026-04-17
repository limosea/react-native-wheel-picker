# @sinandsean/react-native-wheel-picker

A high-performance native wheel picker for React Native with smooth scrolling, haptic feedback, and customizable styling.

## Features

- 🚀 Native implementation for smooth scrolling with momentum
- 📱 Haptic feedback support
- 🔠 Customizable font families, colors, and sizes
- 🔄 Multi-column picker support (e.g., feet + inches)
- 🛡️ Prevents scroll event penetration to outer ScrollView
- ⚙️ Configurable callback timing (real-time vs on-release)

## Installation

```bash
npm install @sinandsean/react-native-wheel-picker
# or
yarn add @sinandsean/react-native-wheel-picker
```

### iOS

```bash
cd ios && pod install
```

### Android

No additional setup required. The library will auto-link.

## Usage

### Basic Usage

```tsx
import { WheelPicker } from "@sinandsean/react-native-wheel-picker";

function App() {
  const [selectedIndex, setSelectedIndex] = useState(0);
  const items = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"];

  return (
    <WheelPicker
      items={items}
      selectedIndex={selectedIndex}
      onValueChange={setSelectedIndex}
    />
  );
}
```

### With Unit Label

```tsx
<WheelPicker
  items={["50", "55", "60", "65", "70", "75", "80"]}
  selectedIndex={selectedIndex}
  unit="kg"
  onValueChange={setSelectedIndex}
/>
```

### Multi-Column Picker

```tsx
import { MultiColumnWheelPicker } from "@sinandsean/react-native-wheel-picker";

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

### Custom Font

```tsx
<WheelPicker
  items={items}
  selectedIndex={selectedIndex}
  fontFamily="SFProText-Semibold"
  onValueChange={setSelectedIndex}
/>
```

### Custom Selection Background

```tsx
<WheelPicker
  items={items}
  selectedIndex={selectedIndex}
  selectionBackgroundColor="#E8F0FE"
  onValueChange={setSelectedIndex}
/>
```

### Time Picker For Real-Time Updates

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
  // Calculate time difference
  return {
    hours: hoursDiff,
    minutes: minutesDiff,
    isNextMinute: false
  }
}, [selectedIndices, HOURS_BASE.length, MINUTES_BASE.length]);

<View>
  {displayTime.isNextMinute ? (
    <Text>Less Than 1 Minute</Text>
  ) : (
    <>
      <Text>
        {displayTime.hours < 10 ? `0${displayTime.hours}` : displayTime.hours}
      </Text>
      <Text>Hours</Text>
      <Text>
        {displayTime.minutes < 10 ? `0${displayTime.minutes}` : displayTime.minutes}
      </Text>
      <Text>Minutes</Text>
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

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `items` | `string[]` | `required` | Array of string items to display |
| `selectedIndex` | `number` | `required` | Currently selected index |
| `unit` | `string` | `undefined` | Optional unit label (e.g., "kg", "cm") |
| `fontFamily` | `string` | `undefined` | Custom font family name |
| `textColor` | `string` | `"#1C1C1C"` | Text color in hex format (e.g., "#FF0000") |
| `textSize` | `number` | `24` | Text size in dp (Android) / pt (iOS) |
| `selectionBackgroundColor` | `string` | `"#F7F9FF"` | Background color of the selection indicator in hex format |
| `immediateCallback` | `boolean` | `true` | Whether to trigger callback during scrolling (`true`) or only when scrolling stops (`false`) |
| `onValueChange` | `(index: number) => void` | `undefined` | Callback when selection changes |
| `style` | `ViewStyle` | `undefined` | Container style |
| `testID` | `string` | `undefined` | Test ID for e2e testing |

## Callback Timing Behavior

The `immediateCallback` prop controls when the `onValueChange` callback is triggered:

- **`immediateCallback={true}`** (default): Callback triggers continuously during scrolling
  - Provides real-time feedback
  - Good for UI updates that need to respond immediately
  - Higher frequency of events

- **`immediateCallback={false}`**: Callback only triggers when scrolling stops
  - Reduces event frequency
  - Better for expensive operations
  - Final value is always guaranteed when user releases

Note: Regardless of the `immediateCallback` setting, the final selected value is always sent when the user releases the picker.

## Styling Options

### Text Color
- Accepts hex color strings (e.g., `"#FF0000"`, `"#333"`, `"#FF6B6B"`)
- Supports both 3-digit and 6-digit hex formats
- Alpha channel is not supported in hex strings

### Text Size
- Specified in dp (Android) or pt (iOS) units
- Default size is 24
- Larger values increase readability but may affect item spacing

### Selection Background Color
- Accepts hex color strings (e.g., `"#F7F9FF"`, `"#E8F0FE"`)
- Supports 3-digit, 4-digit (with alpha), 6-digit, and 8-digit (with alpha) hex formats
- Customizes the background of the center selection indicator

### Font Family
- Use system font names or custom fonts
- Make sure custom fonts are properly registered in native projects

## Performance Tips

1. **Use `useCallback`** for `onValueChange` to prevent unnecessary re-renders
2. **Memoize large item arrays** with `useMemo` to avoid recreation
3. **Consider `immediateCallback={false}`** for expensive operations
4. **Debounce rapid changes** if needed for very large datasets

```tsx
const handleValueChange = useCallback((index: number) => {
  setSelectedIndex(index);
  // Expensive operation
}, []);

const memoizedItems = useMemo(() => {
  return generateLargeItemList();
}, []);
```

## License

MIT
