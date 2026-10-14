#import "GemState.h"
#import "IL2CPPBridge.h"

NSString *const GemStateDidChangeNotification = @"GemStateDidChangeNotification";

@interface GemState ()
@property (nonatomic, readwrite) NSInteger gems;
@property (nonatomic, readwrite) BOOL isLive;
@end

@implementation GemState

+ (instancetype)shared {
    static GemState *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [GemState new]; });
    return s;
}

- (instancetype)init {
    if ((self = [super init])) {
        _isLive = NO;
        _gems = 0;
    }
    return self;
}

- (BOOL)addGems:(NSInteger)amount {
    // Try IL2CPP first
    if ([IL2CPPBridge isReady]) {
        BOOL ok = [IL2CPPBridge addGems:amount];
        if (ok) {
            _isLive = YES;
            _gems += amount;
            return YES;
        }
    }
    
    // Not ready - just track locally
    _isLive = NO;
    _gems += amount;
    NSLog(@"[RealWarMod] IL2CPP not ready, gems tracked locally: %ld", (long)_gems);
    return NO;
}

@end
