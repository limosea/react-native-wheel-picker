#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(WheelPickerViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(items, NSArray)
RCT_EXPORT_VIEW_PROPERTY(selectedIndex, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(unit, NSString)
RCT_EXPORT_VIEW_PROPERTY(fontFamily, NSString)
RCT_EXPORT_VIEW_PROPERTY(immediateCallback, BOOL)
RCT_EXPORT_VIEW_PROPERTY(textColor, NSString)
RCT_EXPORT_VIEW_PROPERTY(textSize, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(selectionBackgroundColor, NSString)
RCT_EXPORT_VIEW_PROPERTY(onValueChange, RCTDirectEventBlock)

@end
