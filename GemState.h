#import <Foundation/Foundation.h>

extern NSString *const GemStateDidChangeNotification;

@interface GemState : NSObject
@property (nonatomic, readonly) NSInteger gems;
+ (instancetype)shared;

#if GEM_DEBUG_UI
/// Local mock-only debug setter. Does not touch any other app's state.
- (void)set_gemsAmountBigIntegerObservedValue;
#endif
@end
