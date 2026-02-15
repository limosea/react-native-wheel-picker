# @sinandsean/react-native-wheel-picker

A high-performance native wheel picker for React Native with smooth scrolling, haptic feedback, and customizable styling.

## Features

- Native implementation for both iOS and Android
- Smooth scroll with momentum and snap-to-item
- Haptic feedback on item change
- Customizable font family
- Optional unit labels (e.g., "kg", "cm")
- Multi-column picker support
- TypeScript support
- **Enhanced scroll event handling** - Prevents scroll event penetration to outer ScrollView components

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

## Props

| Prop | Type | Required | Description |
|------|------|----------|-------------|
| `items` | `string[]` | Yes | Array of string items to display |
| `selectedIndex` | `number` | Yes | Index of the currently selected item |
| `unit` | `string` | No | Optional unit label (e.g., "kg", "cm") |
| `fontFamily` | `string` | No | Custom font family name |
| `onValueChange` | `(index: number) => void` | No | Callback when selection changes |
| `style` | `StyleProp<ViewStyle>` | No | Container style |
| `testID` | `string` | No | Test ID for e2e testing |

## Performance Notes

For optimal performance with frequent updates (like time pickers):

1. Use `useCallback` for `onValueChange` handler
2. Memoize item arrays with `useMemo`
3. Consider debouncing rapid updates if needed

Example:
```tsx
const [hours, setHours] = useState(0);

const onValueChange = useCallback((index: number) => {
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

## License

MIT
