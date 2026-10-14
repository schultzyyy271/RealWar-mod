#import <UIKit/UIKit.h>

/// Floating edge button that adds +1 gem per tap
@interface GemOverlay : UIButton
+ (void)installIfNeeded;
@end

/// Passthrough view controller for overlay window
@interface GemOverlayVC : UIViewController
@end

/// View that passes touches through to views behind it
@interface GemPassthroughView : UIView
@end
