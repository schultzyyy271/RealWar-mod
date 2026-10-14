#import "GemState.h"
#import "IL2CPPBridge.h"

NSString *const GemStateDidChangeNotification = @"GemStateDidChangeNotification";
static NSString *const kGemsDefaultsKey = @"RealWarMod.gems.fallback";

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
        [self refresh];
    }
    return self;
}

- (void)refresh {
    int64_t live = [IL2CPPBridge currentGems];
    if (live >= 0) {
        _isLive = YES;
        _gems = (NSInteger)live;
    } else {
        _isLive = NO;
        _gems = [NSUserDefaults.standardUserDefaults integerForKey:kGemsDefaultsKey];
    }
}

- (BOOL)setGems:(NSInteger)gems {
    gems = MAX(gems, 0);
    
    if ([IL2CPPBridge isReady]) {
        BOOL ok = [IL2CPPBridge setGems:gems];
        if (ok) {
            _isLive = YES;
            _gems = gems;
            [self postNotification];
            return YES;
        }
    }
    
    // Fallback to local storage
    _isLive = NO;
    _gems = gems;
    [NSUserDefaults.standardUserDefaults setInteger:gems forKey:kGemsDefaultsKey];
    [self postNotification];
    return YES;
}

- (BOOL)addGems:(NSInteger)amount {
    if ([IL2CPPBridge isReady]) {
        BOOL ok = [IL2CPPBridge addGems:amount];
        if (ok) {
            [self refresh];
            [self postNotification];
            return YES;
        }
    }
    
    // Fallback to local storage
    return [self setGems:self.gems + amount];
}

- (void)postNotification {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:GemStateDidChangeNotification object:self];
}

@end
