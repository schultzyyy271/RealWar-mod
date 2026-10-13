#import "GemState.h"

NSString *const GemStateDidChangeNotification = @"GemStateDidChangeNotification";

@interface GemState ()
@property (nonatomic, readwrite) NSInteger gems;
@end

@implementation GemState

+ (instancetype)shared {
    static GemState *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [GemState new]; });
    return s;
}

#if GEM_DEBUG_UI
- (void)set_gemsAmountBigIntegerObservedValue {
    self.gems = 99999;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:GemStateDidChangeNotification object:self];
}
#endif

@end
