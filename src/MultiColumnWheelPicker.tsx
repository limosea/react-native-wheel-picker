import React from 'react';
import { View, StyleSheet, type ViewStyle, type StyleProp } from 'react-native';
import { WheelPicker } from './WheelPicker';

export interface WheelColumn {
  /**
   * Array of string values for this column
   */
  values: string[];

  /**
   * Optional unit label for this column
   */
  unit?: string;

  /**
   * Currently selected index for this column
   */
  selectedIndex: number;

  /**
   * Callback when this column's value changes
   */
  onSelect: (index: number) => void;

  /**
   * Optional width for this column (flex value)
   * @default 1
   */
  width?: number;
}

export interface MultiColumnWheelPickerProps {
  /**
   * Array of column configurations
   */
  columns: WheelColumn[];

  /**
   * Custom font family for all columns
   */
  fontFamily?: string;

  /**
   * Text color for all picker items
   * @default "#1C1C1C"
   */
  textColor?: string;

  /**
   * Text size for all picker items in sp/dp
   * @default 24
   */
  textSize?: number;

  /**
   * Whether to trigger callback immediately during scrolling or only when scrolling stops
   * @default true (immediate callback during scrolling)
   */
  immediateCallback?: boolean;

  /**
   * Style for the picker container
   */
  style?: StyleProp<ViewStyle>;

  /**
   * Test ID for e2e testing
   */
  testID?: string;
}

const PICKER_HEIGHT = 240;

export function MultiColumnWheelPicker({
  columns,
  fontFamily,
  textColor,
  textSize,
  immediateCallback = true,
  style,
  testID,
}: MultiColumnWheelPickerProps): React.ReactElement {
  return (
    <View style={[styles.container, style]} testID={testID}>
      {columns.map((column, index) => (
        <View
          key={index}
          style={[styles.column, { flex: column.width ?? 1 }]}
        >
          <WheelPicker
            items={column.values}
            selectedIndex={column.selectedIndex}
            unit={column.unit}
            fontFamily={fontFamily}
            textColor={textColor}
            textSize={textSize}
            immediateCallback={immediateCallback}
            onValueChange={column.onSelect}
            style={styles.picker}
          />
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    height: PICKER_HEIGHT,
  },
  column: {
    flex: 1,
  },
  picker: {
    flex: 1,
  },
});

export default MultiColumnWheelPicker;